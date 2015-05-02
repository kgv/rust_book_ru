% Условная компиляция

В Rust есть специальный атрибут, `#[cfg]`, который позволяет компилировать код в
зависимости от флагов переданых компилятору. Он имеет две формы:

```rust
#[cfg(foo)]
# fn foo() {}

#[cfg(bar = "baz")]
# fn bar() {}
```

Он также имеет несколько помощников:

```rust
#[cfg(any(unix, windows))]
# fn foo() {}

#[cfg(all(unix, target_pointer_width = "32"))]
# fn bar() {}

#[cfg(not(foo))]
# fn not_foo() {}
```

Которые могут быть как угодно вложены:

```rust
#[cfg(any(not(unix), all(target_os="macos", target_arch = "powerpc")))]
# fn foo() {}
```

Что же касается того, как включить или отключить эти флаги: если вы используете
Cargo, то они устанавливаются в [разделе `[features]`][features] вашего
`Cargo.toml`:

[features]: http://doc.crates.io/manifest.html#the-[features]-section

```toml
[features]
# no features by default
default = []

# The “secure-password” feature depends on the bcrypt package.
secure-password = ["bcrypt"]
```

Если вы сделаете это, то Cargo передаст флаг в `rustc`:

```text
--cfg feature="${feature_name}"
```

Совокупность этих `cfg` флагов будет определять, какие из них будут активны, и,
следовательно, какой код будет скомпилирован. Давайте рассмотрим такой код:

```rust
#[cfg(feature = "foo")]
mod foo {
}
```

Если скомпилировать его с помощью `cargo build --features "foo"`, то будет
передан флаг `--cfg feature="foo"` в `rustc` и выход будет содержать модуль `mod
foo`. Если скомпилировать его с помощью обычной команды `cargo build`, то
никаких дополнительных флагов передано не будет, и поэтому, модуль `mod foo` не
будет существовать.

# cfg_attr

Вы также можете установить другой атрибут в зависимости от переменной `cfg` с
помощью атрибута `cfg_attr`:

```rust
#[cfg_attr(a, b)]
# fn foo() {}
```

Этот код будет равносилен атрибуту `#[b]`, если в атрибуте `cfg` установлен флаг
`a`, или "без атрибута" в противном случае.

# cfg!

[Расширение синтаксиса][Compilerplugins] `cfg!` позволяет использовать данные
виды флагов и в другом месте в коде:

```rust
if cfg!(target_os = "macos") || cfg!(target_os = "ios") {
    println!("Think Different!");
}
```

[compilerplugins]: compiler-plugins.html

Они будут заменены на `true` или `false` во время компиляции, в зависимости от
настройки конфигурации.
