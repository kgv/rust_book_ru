% Интерфейс внешних функций (Foreign Function Interface)

# Введение

Это руководство будет использовать [snappy](https://github.com/google/snappy),
библиотеку упаковки/распаковки данных, в качестве примера для написания привязок
к внешнему коду. Rust в настоящее время не в состоянии делать вызовы напрямую из
библиотеки C++, но snappy включает в себя интерфейс C (документирован в
[`snappy-c.h`](https://github.com/google/snappy/blob/master/snappy-c.h)).

The following is a minimal example of calling a foreign function which will
compile if snappy is installed:

Ниже приведен минимальный пример вызова внешней функции, который будет
скомпилирован, при условии, что библиотека snappy установлена:

```no_run
# #![feature(libc)]
extern crate libc;
use libc::size_t;

#[link(name = "snappy")]
extern {
    fn snappy_max_compressed_length(source_length: size_t) -> size_t;
}

fn main() {
    let x = unsafe { snappy_max_compressed_length(100) };
    println!("max compressed length of a 100 byte buffer: {}", x);
}
```

Блок `extern` содержит список сигнатур функций из внешней библиотеки, в данном
случае для платформы C ABI. Атрибут `#[link(...)]` используется для указания
линкеру линковать с библиотекой snappy, поэтому символы будут разрешены.

Предполагается, что внешние функции могут быть небезопасными, поэтому их вызовы
должны быть обёрнуты в блок `unsafe {}` как обещание компилятору, что все
содержимое внутри этого блока в действительности безопасно. C библиотеки часто
предоставляют интерфейсы, которые не являются поточно-безопасным. И почти любая
функция, которая принимает в качестве аргумента указатель, не может быть
валидной для всех возможных входных значений, поскольку указатель может быть
висячим, и сырые указатели выходят за пределы безопасной модели памяти в Rust.

When declaring the argument types to a foreign function, the Rust compiler can
not check if the declaration is correct, so specifying it correctly is part of
keeping the binding correct at runtime.

При объявлении типов аргументов для внешней функции, компилятор Rust не может
проверить, является ли данное объявление правильным, поэтому проверка
правильности является частью сохранения привязки правильно во время выполнения.

Блок `extern` может быть распространён на весь snappy API:

```no_run
# #![feature(libc)]
extern crate libc;
use libc::{c_int, size_t};

#[link(name = "snappy")]
extern {
    fn snappy_compress(input: *const u8,
                       input_length: size_t,
                       compressed: *mut u8,
                       compressed_length: *mut size_t) -> c_int;
    fn snappy_uncompress(compressed: *const u8,
                         compressed_length: size_t,
                         uncompressed: *mut u8,
                         uncompressed_length: *mut size_t) -> c_int;
    fn snappy_max_compressed_length(source_length: size_t) -> size_t;
    fn snappy_uncompressed_length(compressed: *const u8,
                                  compressed_length: size_t,
                                  result: *mut size_t) -> c_int;
    fn snappy_validate_compressed_buffer(compressed: *const u8,
                                         compressed_length: size_t) -> c_int;
}
# fn main() {}
```

# Создание безопасного интерфейса

Сырой C API необходимо обернуть, чтобы обеспечить безопасность памяти, чтобы
была возможность использовать концепции более высокого уровня, такие как
векторы. Библиотека может выборочно открывать только безопасный, высокоуровневый
интерфейс и скрывать небезопасные внутренние детали.

Обёртывание функций, которые принимают в качестве входных параметров буферы,
включает в себя использование модуля `slice::raw` для управления векторами Rust
как указателями на память. Векторы Rust представляют собой гарантированно
непрерывный блок памяти. Длина - это количество элементов, которое в настоящее
время содержится в векторе, а мощность - общее количество выделенной памяти в
элементах. Длина меньше или равна мощности.

```
# #![feature(libc)]
# extern crate libc;
# use libc::{c_int, size_t};
# unsafe fn snappy_validate_compressed_buffer(_: *const u8, _: size_t) -> c_int { 0 }
# fn main() {}
pub fn validate_compressed_buffer(src: &[u8]) -> bool {
    unsafe {
        snappy_validate_compressed_buffer(src.as_ptr(), src.len() as size_t) == 0
    }
}
```

The `validate_compressed_buffer` wrapper above makes use of an `unsafe` block, but it makes the
guarantee that calling it is safe for all inputs by leaving off `unsafe` from the function
signature.

Обертка `validate_compressed_buffer` использует блок `unsafe`, но это
гарантирует, что ее вызов будет безопасен для всех входных данных, вследствие
удаления модификатора `unsafe` из сигнатуры функции.

Функции `snappy_compress` и `snappy_uncompress` являются более сложными, так как
должен быть выделен буфер для хранения возвращаемых данных.

The `snappy_max_compressed_length` function can be used to allocate a vector with the maximum
required capacity to hold the compressed output. The vector can then be passed to the
`snappy_compress` function as an output parameter. An output parameter is also passed to retrieve
the true length after compression for setting the length.

Функция `snappy_max_compressed_length` может быть использована для выделения
вектора максимальной мощности, требуемой для хранения упакованных выходных
данных. Этот вектор может затем быть передан в функцию `snappy_compress` в
качестве выходного параметра. Выходной параметр также передается, чтобы получить
истинную длину после сжатия для установки длины.

```
# #![feature(libc)]
# extern crate libc;
# use libc::{size_t, c_int};
# unsafe fn snappy_compress(a: *const u8, b: size_t, c: *mut u8,
#                           d: *mut size_t) -> c_int { 0 }
# unsafe fn snappy_max_compressed_length(a: size_t) -> size_t { a }
# fn main() {}
pub fn compress(src: &[u8]) -> Vec<u8> {
    unsafe {
        let srclen = src.len() as size_t;
        let psrc = src.as_ptr();

        let mut dstlen = snappy_max_compressed_length(srclen);
        let mut dst = Vec::with_capacity(dstlen as usize);
        let pdst = dst.as_mut_ptr();

        snappy_compress(psrc, srclen, pdst, &mut dstlen);
        dst.set_len(dstlen as usize);
        dst
    }
}
```

Распаковка аналогична, потому что snappy хранит размер неупакованных данных как
часть формата сжатия, и `snappy_uncompressed_length` будет получить точный размер
необходимого буфера.

```
# #![feature(libc)]
# extern crate libc;
# use libc::{size_t, c_int};
# unsafe fn snappy_uncompress(compressed: *const u8,
#                             compressed_length: size_t,
#                             uncompressed: *mut u8,
#                             uncompressed_length: *mut size_t) -> c_int { 0 }
# unsafe fn snappy_uncompressed_length(compressed: *const u8,
#                                      compressed_length: size_t,
#                                      result: *mut size_t) -> c_int { 0 }
# fn main() {}
pub fn uncompress(src: &[u8]) -> Option<Vec<u8>> {
    unsafe {
        let srclen = src.len() as size_t;
        let psrc = src.as_ptr();

        let mut dstlen: size_t = 0;
        snappy_uncompressed_length(psrc, srclen, &mut dstlen);

        let mut dst = Vec::with_capacity(dstlen as usize);
        let pdst = dst.as_mut_ptr();

        if snappy_uncompress(psrc, srclen, pdst, &mut dstlen) == 0 {
            dst.set_len(dstlen as usize);
            Some(dst)
        } else {
            None // SNAPPY_INVALID_INPUT
        }
    }
}
```

Для справки, примеры, используемые здесь, также доступны в библиотеке на
[GitHub](https://github.com/thestinger/rust-snappy).

# Деструкторы

Внешние библиотеки часто передают право собственности на ресурсы в вызовающий
код. Когда это происходит, мы должны использовать деструкторы Rust, чтобы
обеспечить безопасность и гарантировать освобождение этих ресурсов (особенно в
случае паники).

Чтобы получить более подробную информацию о деструкторах, смотрите
[Drop trait](../std/ops/trait.Drop.html).

# Обратные вызовы Rust функций из C кода

Некоторые внешние библиотеки требуют использование обратных вызовов для передачи
вызывающей стороне отчета о своем текущем состоянии или промежуточных данных. Во
внешнюю библиотеку можно передавать функции, которые были определены в Rust. При
создании функции обратного вызова, которую можно вызывать из C кода, необходимо
указать для нее спецификатор `extern`, за котороым следует правильное соглашение
о вызове.

Затем функция обратного вызова может быть передана в библиотеку C через
регистрационный вызов, а затем вызывается оттуда.

Простой пример:

Rust код:

```no_run
extern fn callback(a: i32) {
    println!("I'm called from C with value {0}", a);
}

#[link(name = "extlib")]
extern {
   fn register_callback(cb: extern fn(i32)) -> i32;
   fn trigger_callback();
}

fn main() {
    unsafe {
        register_callback(callback);
        trigger_callback(); // Triggers the callback
    }
}
```

C код:

```c
typedef void (*rust_callback)(int32_t);
rust_callback cb;

int32_t register_callback(rust_callback callback) {
    cb = callback;
    return 1;
}

void trigger_callback() {
  cb(7); // Will call callback(7) in Rust
}
```

В этом примере функция `main()` в Rust вызовет функцию `trigger_callback()` в C,
которая, в свою очередь, выполнит обратный вызов функции `callback()` в Rust.

## Обратные вызовы, адресованные объектам Rust (Targeting callbacks to Rust objects)

Предыдущий пример показал, как глобальная функция может быть вызвана из C кода.
Однако зачастую желательно, чтобы обратный вызов был адресован специальному
объекту в Rust. Это может быть объект, который представляет собой обертку для
соответствующего объекта C.

Такое поведение может быть достигнуто путем передачи небезопасного указателя на
объект в библиотеку C. После чего библиотека C сможет включать указатель на
объект Rust при обратном вызове. Это позволит получить небезопасный доступ к
ссылке на объект Rust в обратном вызове.

Rust код:

```no_run
#[repr(C)]
struct RustObject {
    a: i32,
    // other members
}

extern "C" fn callback(target: *mut RustObject, a: i32) {
    println!("I'm called from C with value {0}", a);
    unsafe {
        // Update the value in RustObject with the value received from the callback
        (*target).a = a;
    }
}

#[link(name = "extlib")]
extern {
   fn register_callback(target: *mut RustObject,
                        cb: extern fn(*mut RustObject, i32)) -> i32;
   fn trigger_callback();
}

fn main() {
    // Create the object that will be referenced in the callback
    let mut rust_object = Box::new(RustObject { a: 5 });

    unsafe {
        register_callback(&mut *rust_object, callback);
        trigger_callback();
    }
}
```

C код:

```c
typedef void (*rust_callback)(void*, int32_t);
void* cb_target;
rust_callback cb;

int32_t register_callback(void* callback_target, rust_callback callback) {
    cb_target = callback_target;
    cb = callback;
    return 1;
}

void trigger_callback() {
  cb(cb_target, 7); // Will call callback(&rustObject, 7) in Rust
}
```

## Асинхронные обратные вызовы

В ранее приведенных примерах обратные вызовы выполняются как непосредственная
реакция на вызов функции внешней C библиотеки. Для выполнения обратного вызова
контроль над текущим потоком переключался из Rust в C, а затем снова в Rust, но,
в конце концов, обратный вызов выполнялся в том же потоке, из которого была
вызвана функция, инициировавшая обратный вызов.

Things get more complicated when the external library spawns its own threads
and invokes callbacks from there.
In these cases access to Rust data structures inside the callbacks is
especially unsafe and proper synchronization mechanisms must be used.
Besides classical synchronization mechanisms like mutexes, one possibility in
Rust is to use channels (in `std::comm`) to forward data from the C thread
that invoked the callback into a Rust thread.

Все становится более сложным, когда внешняя библиотека порождает свои
собственные потоки и осуществляет обратные вызовы из них. В этих случаях доступ
к структурам данных Rust внутри обратных вызовов особенно небезопасен, и поэтому
должны быть использованы соответствующие механизмы синхронизации. Помимо
классических механизмов синхронизации, таких как мьютексы, в Rust есть еще одна
возможность: использовать каналы (в `std::comm` (`std::sync::mpsc::channel`)),
чтобы направить данные из потока C, который выполнял обратный вызов в потоке
Rust.

Если асинхронный обратный вызов адресован конкретному объекту в адресном
пространстве Rust, то необходимо потребовать, чтобы обратные вызовы больше не
выполнялись библиотекой C после удаления этого Rust объекта. Это может быть
достигнуто путем отмены регистрации обратного вызова в деструкторе объекта и
проектирования библиотеки таким образом, чтобы гарантировалось, что после отмены
регистрации обратного вызова он больше не будет выполняться.

# Линковка

Атрибут `link` для блоков `extern` обеспечивает основу для указания rustc, как
он будет линковать нативные библиотеки. На сегодняшний день есть две
общепринятых формы записи атрибута `link`:

* `#[link(name = "foo")]`
* `#[link(name = "foo", kind = "bar")]`

In both of these cases, `foo` is the name of the native library that we're
linking to, and in the second case `bar` is the type of native library that the
compiler is linking to. There are currently three known types of native
libraries:

В обоих этих случаях `foo` - это имя нативной библиотеки, которую мы линкуем, и
во втором случае `bar` - это тип нативной библиотеки, которую компилятор
линкует. В настоящее время известны три типа нативных библиотек:

* Динамические - `#[link(name = "readline")]`
* Статические - `#[link(name = "my_build_dependency", kind = "static")]`
* Фреймворки - `#[link(name = "CoreFoundation", kind = "framework")]`

Обратите внимание, что фреймворки доступны только для OSX.

The different `kind` values are meant to differentiate how the native library
participates in linkage. From a linkage perspective, the rust compiler creates
two flavors of artifacts: partial (rlib/staticlib) and final (dylib/binary).
Native dynamic libraries and frameworks are propagated to the final artifact
boundary, while static libraries are not propagated at all.
Различные значения `kind` предназначены для дифференцирования нативных библиотек
по способу участия в линковке. С точки зрения линковки, компилятор Rust создает
две разновидности артефактов: промежуточный (rlib/staticlib) и конечный
(dylib/binary). Нативные динамические библиотеки и фреймворки распространяются
на конечные артефакты, а статические библиотеки не распространяются на все.

Вот несколько примеров того, как эта модель может быть использована:

* Нативная зависимость при сборке. Иногда написанный на Rust код необходимо
  состыковать с некоторым кодом на C/C++, но распранение C/C++ кода в формате
  библиотеки накладывает дополнительные трудности. В этом случае, код будут
  упакован в `libfoo.a`, а затем контейнер Rust должен будет объявить
  зависимость с помощью `#[link(name = "foo", kind = "static")]`.

  Независимо от типа выхода (промежуточный или конечный) для контейнера,
  нативная статическая библиотека будет включена на выходе, что означает, что
  нет необходимости в распранении этой нативной статической библиотеки отдельно.

  Нормальная динамическая зависимость. Общие системные библиотеки (такие, как
  `readline`) доступны на большом количестве систем, и часто можно найти
  статическую копию этих библиотек. Когда такая зависимость была включена в
  контейнер Rust, промежуточные цели (например, rlibs) не будут линковать
  библиотеку, но когда rlib входит в конечную цель (например, исполняемый файл),
  нативная библиотека будет прилинкована.

На OSX, фреймворки ведут себя с той же семантикой, что и динамические
библиотеки.

# Небезопасные блоки

Некоторые операции, такие как разыменование небезопасных указателей или вызов
функций, которые были отмечены как небезопасные, разрешено только внутри
небезопасных блоков. Небезопасных блоки изолируют опасносные ситуации и дают
гарантии компилятору, что опасности не вытекут за пределы блока.

Unsafe functions, on the other hand, advertise it to the world. An unsafe function is written like
this:

Небезопасные функции, с другой стороны, делают сильный акцент на этом.
Небезопасная функция записывается в виде:

```
unsafe fn kaboom(ptr: *const i32) -> i32 { *ptr }
```

Эта функция может быть вызвана только из блока `unsafe` или из другой функции
`unsafe`.

# Доступ к внешним глобальным переменным

Внешние API довольно часто экспортируют глобальные переменные, которые могут
быть использованы, например, для отслеживание глобального состояния. Для того,
чтобы получить доступ к этим переменным, нужно объявить их в блоке `extern`,
используя ключевое слово `static`:

```no_run
# #![feature(libc)]
extern crate libc;

#[link(name = "readline")]
extern {
    static rl_readline_version: libc::c_int;
}

fn main() {
    println!("You have readline version {} installed.",
             rl_readline_version as i32);
}
```

Кроме того, возможно вам потребуется изменить глобальное состояние,
предоставленное внешним интерфейсом. Для этого при объявлении статических
переменных может быть добавлен модификатор `mut`, чтобы была возможность
изменять их.

```no_run
# #![feature(libc)]
extern crate libc;

use std::ffi::CString;
use std::ptr;

#[link(name = "readline")]
extern {
    static mut rl_prompt: *const libc::c_char;
}

fn main() {
    let prompt = CString::new("[my-awesome-shell] $").unwrap();
    unsafe {
        rl_prompt = prompt.as_ptr();

        println!("{:?}", rl_prompt);

        rl_prompt = ptr::null();
    }
}
```

Обратите внимание, что любое взаимодействие с `static mut` небезопасно, как
чтение, так и запись. Работа с изменяемым глобальным состоянием требует
значительно большей осторожности.

# Соглашение о вызове внешних функций

Большинство внешнего кода предоставляет C ABI (Двоичный Интерфейс Приложений). И
Rust при вызове внешних функций по умолчанию использует C соглашение о вызове
для данной платформы. Но некоторые внешние функции, в первую очередь Windows
API, используют другое соглашение о вызове. Rust обеспечивает способ указать
компилятору, какое именно соглашение использовать:

```
# #![feature(libc)]
extern crate libc;

#[cfg(all(target_os = "win32", target_arch = "x86"))]
#[link(name = "kernel32")]
#[allow(non_snake_case)]
extern "stdcall" {
    fn SetEnvironmentVariableA(n: *const u8, v: *const u8) -> libc::c_int;
}
# fn main() { }
```

Это указание относится ко всему блоку `extern`. Список поддерживаемых ABI
ограничивается следующими:

* `stdcall`
* `aapcs`
* `cdecl`
* `fastcall`
* `Rust`
* `rust-intrinsic`
* `system`
* `C`
* `win64`

Большинство ABI в этом списке не требуют пояснений, но ABI `system` может
показаться немного странным. Он выбирает такое ABI, которое подходит (уместно)
для взаимодействия с целевыми библиотеками. Например, на платформе win32 с
архитектурой x86, это означает, что будет использован `stdcall` ABI. Однако, на
windows x86_64 используется `C` соглашение о вызовах, поэтому в этом случае
будет использован `C` ABI. Это означает, что в нашем предыдущем примере мы могли
бы использовать `extern "system" { ... }`, чтобы определить блок для всех
windows систем, а не только для x86.

# Взаимодействие с внешним кодом

Rust гарантирует, что cхема расположения для `struct` совместима с
представлением платформы в C, только в том случае, если к ней применяется
атрибут `#[repr(C)]`. Атрибут `#[repr(C, packed)]` может быть использован для
схемы расположения частей структуры без выравнивания (заполнения). Атрибут
`#[repr(C)]` также может быть применен и к перечислениям.

Rust's owned boxes (`Box<T>`) use non-nullable pointers as handles which point
to the contained object. However, they should not be manually created because
they are managed by internal allocators. References can safely be assumed to be
non-nullable pointers directly to the type.  However, breaking the borrow
checking or mutability rules is not guaranteed to be safe, so prefer using raw
pointers (`*`) if that's needed because the compiler can't make as many
assumptions about them.
Боксы с правом владения в Rust (`Box<T>`) используют ненулевые (non-nullable)
указатели как ручки, которые указывают на содержащийся в них объект. Тем не
менее, они не должны быть созданы вручную, так как они находятся под управлением
внутренних средств выделения памяти. Ссылки можно смело считать ненулевыми
указателями непосредствено на тип. Однако нарушение проверка одолжить или правил
изменчивости не гарантирует безопасность, поэтому предпочитают использовать
сырые указатели (`*`), если это необходимо, потому что компилятор не может
сделать так много предположений о них.

Векторы и строки совместно используют одну и ту же базовую cхему расположения
памяти и утилиты, доступные в модулях `vec` и `str`, для работы с C API. Тем не
менее, строки не завершаются нулевым байтом, `\0`. Если вам нужна строка,
завершающаяся нулевым байтом для совместимости с C, вы должны использовать тип
`CString` из модуля `std::ffi`.

The standard library includes type aliases and function definitions for the C
standard library in the `libc` module, and Rust links against `libc` and `libm`
by default.
Стандартная библиотека включает в себя псевдонимы типов и определения функций
для стандартной библиотеки C в модуле `libc`, и Rust линкует `libc` и `libm` по
умолчанию.

# Оптимизация небезопасных указателей (The "nullable pointer optimization")

Certain types are defined to not be `null`. This includes references (`&T`,
`&mut T`), boxes (`Box<T>`), and function pointers (`extern "abi" fn()`).
When interfacing with C, pointers that might be null are often used.
As a special case, a generic `enum` that contains exactly two variants, one of
which contains no data and the other containing a single field, is eligible
for the "nullable pointer optimization". When such an enum is instantiated
with one of the non-nullable types, it is represented as a single pointer,
and the non-data variant is represented as the null pointer. So
`Option<extern "C" fn(c_int) -> c_int>` is how one represents a nullable
function pointer using the C ABI.
Некоторые типы по определению не могут быть `null`. Они включают в себя ссылки
(`&T`, `&mut T`), боксы (`Box<T>`), указатели на функции (`extern "abi" fn()`).
Указатели же, которые могут быть `null`, часто используются при взаимодействии с
С. Как частный случай, в общем `enum`, который содержит ровно два варианта, один
из которых не содержит данных, а другой содержит одно поле, имеет право на
"оптимизацию ненулируемого указателя". При таких перечисление экземпляра с
одним из ненулируемых типов, он представлен в виде одного указателя, и вариант
без данных представляется как пустой указатель. Так `Option<extern "C" fn(c_int)
-> c_int>` как один представляет собой указатель обнуляемого функции с
использованием C ABI.

# Вызов Rust кода из C кода

Вы можете скомпилировать Rust код таким образом, чтобы он мог быть вызван из C
кода. Это довольно легко, но требует нескольких вещей:

```
#[no_mangle]
pub extern fn hello_rust() -> *const u8 {
    "Hello, world!\0".as_ptr()
}
# fn main() {}
```

`extern` указывает, что эта функцию придерживается C соглашения о вызове, как
описано выше в разделе "[Соглашение о вызове внешних функций](ffi.html#foreign-calling-conventions)".
Атрибут `no_mangle` выключает модификацию имени, применяемую в Rust, для того
чтобы было легче линковать.
