% Пользовательские менеджеры памяти

Выделение памяти — это не самая простая задача, и Rust обычно заботится об этом
сам, но часто нужно тонко управлять выделением памяти. Компилятор и стандартная
библиотека в настоящее время позволяют глобально переключить используемый
во время компиляции менеджер. Описание сейчас находится в [RFC 1183][rfc], но
здесь мы рассмотрим как сделать ваш собственный менеджер.

[rfc]: https://github.com/rust-lang/rfcs/blob/master/text/1183-swap-out-jemalloc.md

# Стандартный менеджер памяти

В настоящее время компилятор содержит два стандартных менеджера: `alloc_system`
и `alloc_jemalloc` (однако у некоторых платформ отсутствует jemalloc).
Эти менеджеры стандартны для контейнеров Rust и содержат реализацию подпрограмм
для выделения и освобождения памяти. Стандартная библиотека не компилируется
специально для использования только одного из них. Компилятор будет решать какой
менеджер использовать во время компиляции в зависимости от типа производимых
выходных артефактов.

По умолчанию исполняемые файлы сгенерированные компилятором будут использовать
`alloc_jemalloc` (там где возможно). В таком случае компилятор "контролирует
весь мир", в том смысле что у него есть власть над окончательной компоновкой.

Однако динамические и статические библиотеки по умолчанию будут использовать
`alloc_system`. Здесь Rust обычно в роли гостя в другом приложении или вообще в
другом мире, где он не может авторитетно решать какой менеджер использовать.
В результате он возвращается назад к стандартным API (таких как `malloc` и
`free`), для получения и освобождения памяти.

# Переключение менеджеров памяти

Несмотря на то что в большинстве случаев нам подойдет стандартный выбор
компилятора, часто бывает необходимо настроить определенные аспекты. Для того
чтобы переопределить решение компилятора о том, какой именно менеджер
использовать, достаточно просто скомпоновать с желаемым менеджером:

```rust,no_run
#![feature(alloc_system)]

extern crate alloc_system;

fn main() {
    let a = Box::new(4); // выделение памяти с помощью системного менеджера
    println!("{}", a);
}
```

В этом примере сгенерированный исполняемый файл будет скомпонован с системным
менеджером, вместо менеджера по умолчанию — jemalloc. И наоборот, чтобы
сгенерировать динамическую библиотеку, которая использует jemalloc по умолчанию
нужно написать:

```rust,ignore
#![feature(alloc_jemalloc)]
#![crate_type = "dylib"]

extern crate alloc_jemalloc;

pub fn foo() {
    let a = Box::new(4); // выделение памяти с помощью jemalloc
    println!("{}", a);
}
# fn main() {}
```

# Writing a custom allocator

Sometimes even the choices of jemalloc vs the system allocator aren't enough and
an entirely new custom allocator is required. In this you'll write your own
crate which implements the allocator API (e.g. the same as `alloc_system` or
`alloc_jemalloc`). As an example, let's take a look at a simplified and
annotated version of `alloc_system`

```rust,no_run
# // only needed for rustdoc --test down below
# #![feature(lang_items)]
// The compiler needs to be instructed that this crate is an allocator in order
// to realize that when this is linked in another allocator like jemalloc should
// not be linked in
#![feature(allocator)]
#![allocator]

// Allocators are not allowed to depend on the standard library which in turn
// requires an allocator in order to avoid circular dependencies. This crate,
// however, can use all of libcore.
#![feature(no_std)]
#![no_std]

// Let's give a unique name to our custom allocator
#![crate_name = "my_allocator"]
#![crate_type = "rlib"]

// Our system allocator will use the in-tree libc crate for FFI bindings. Note
// that currently the external (crates.io) libc cannot be used because it links
// to the standard library (e.g. `#![no_std]` isn't stable yet), so that's why
// this specifically requires the in-tree version.
#![feature(libc)]
extern crate libc;

// Listed below are the five allocation functions currently required by custom
// allocators. Their signatures and symbol names are not currently typechecked
// by the compiler, but this is a future extension and are required to match
// what is found below.
//
// Note that the standard `malloc` and `realloc` functions do not provide a way
// to communicate alignment so this implementation would need to be improved
// with respect to alignment in that aspect.

#[no_mangle]
pub extern fn __rust_allocate(size: usize, _align: usize) -> *mut u8 {
    unsafe { libc::malloc(size as libc::size_t) as *mut u8 }
}

#[no_mangle]
pub extern fn __rust_deallocate(ptr: *mut u8, _old_size: usize, _align: usize) {
    unsafe { libc::free(ptr as *mut libc::c_void) }
}

#[no_mangle]
pub extern fn __rust_reallocate(ptr: *mut u8, _old_size: usize, size: usize,
                                _align: usize) -> *mut u8 {
    unsafe {
        libc::realloc(ptr as *mut libc::c_void, size as libc::size_t) as *mut u8
    }
}

#[no_mangle]
pub extern fn __rust_reallocate_inplace(_ptr: *mut u8, old_size: usize,
                                        _size: usize, _align: usize) -> usize {
    old_size // this api is not supported by libc
}

#[no_mangle]
pub extern fn __rust_usable_size(size: usize, _align: usize) -> usize {
    size
}

# // just needed to get rustdoc to test this
# fn main() {}
# #[lang = "panic_fmt"] fn panic_fmt() {}
# #[lang = "eh_personality"] fn eh_personality() {}
# #[lang = "eh_unwind_resume"] extern fn eh_unwind_resume() {}
# #[no_mangle] pub extern fn rust_eh_register_frames () {}
# #[no_mangle] pub extern fn rust_eh_unregister_frames () {}
```

After we compile this crate, it can be used as follows:

```rust,ignore
extern crate my_allocator;

fn main() {
    let a = Box::new(8); // allocates memory via our custom allocator crate
    println!("{}", a);
}
```

# Custom allocator limitations

There are a few restrictions when working with custom allocators which may cause
compiler errors:

* Any one artifact may only be linked to at most one allocator. Binaries,
  dylibs, and staticlibs must link to exactly one allocator, and if none have
  been explicitly chosen the compiler will choose one. On the other hand rlibs
  do not need to link to an allocator (but still can).

* A consumer of an allocator is tagged with `#![needs_allocator]` (e.g. the
  `liballoc` crate currently) and an `#[allocator]` crate cannot transitively
  depend on a crate which needs an allocator (e.g. circular dependencies are not
  allowed). This basically means that allocators must restrict themselves to
  libcore currently.
