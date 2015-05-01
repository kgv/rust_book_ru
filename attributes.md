% Атрибуты

В Rust объявления могут быть аннотированы с помощью ‘атрибутов‘. Они выглядят
так:

```rust
#[test]
# fn foo() {}
```

или так:

```rust
# mod foo {
#![test]
# }
```

The difference between the two is the `!`, which changes what the attribute
applies to:

Разница между ними состоит в символе `!`, который изменяет цель, к которой
применяется атрибут:

```rust,ignore
#[foo]
struct Foo;

mod bar {
    #![bar]
}
```

The `#[foo]` attribute applies to the next item, which is the `struct`
declaration. The `#![bar]` attribute applies to the item enclosing it, which is
the `mod` declaration. Otherwise, they’re the same. Both change the meaning of
the item they’re attached to somehow.

Атрибут `#[foo]` относится к следующему за ним элементу, который является
объявлением `struct`. Атрибут `#![bar]` относится к элементу охватывающему его,
который является объявлением `mod`. В остальном они одинаковы. Оба каким-то
образом изменяют значение элемента, к которому они прикрепленны.

Например, рассмотрим такую функцию:

```rust
#[test]
fn check() {
    assert_eq!(2, 1 + 1);
}
```

Фунуция помечена как `#[test]`. Это означает, что она особенная: эта функция
будет выполняться при запуске [тестов][tests]. При компиляции, как правило, она
не будет включена. Теперь эта функция является функцией тестирования.

[tests]: testing.html

Атрибуты также могут иметь дополнительные данные:

```rust
#[inline(always)]
fn super_fast_fn() {
# }
```

Или даже ключи и значения:

```rust
#[cfg(target_os = "macos")]
mod macos_only {
# }
```

Rust attributes are used for a number of different things. There is a full list
of attributes [in the reference][reference]. Currently, you are not allowed to
create your own attributes, the Rust compiler defines them.

Атрибуты в Rust используются для ряда различных вещей. Вот [ссылка][reference]
на полный список атрибутов. В настоящее время вы не можете создавать свои
собственные атрибуты, компилятор Rust определяет их.

[reference]: ../reference.html#attributes
