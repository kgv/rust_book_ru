% Трейты

Вы помните, ключевое слово `impl`, используемое для вызова функции с синтаксисом
метода?

```{rust}
# #![feature(core)]
struct Circle {
    x: f64,
    y: f64,
    radius: f64,
}

impl Circle {
    fn area(&self) -> f64 {
        std::f64::consts::PI * (self.radius * self.radius)
    }
}
```

Трейты схожи, за исключением того, что мы определяем трейт, содержащий лишь
сигнатуру метода, а затем реализуем этот трейт для нужной структуры. Например,
как показано ниже:

```{rust}
# #![feature(core)]
struct Circle {
    x: f64,
    y: f64,
    radius: f64,
}

trait HasArea {
    fn area(&self) -> f64;
}

impl HasArea for Circle {
    fn area(&self) -> f64 {
        std::f64::consts::PI * (self.radius * self.radius)
    }
}
```

Как вы можете видеть, блок `trait` очень похож на блок `impl`. Различие состоит
лишь в том, что тело метода не определяется, а определяется только его
сигнатура. Когда мы реализуем трейт, мы используем `impl Trait for Item`, а не
просто `impl Item`.

Так что же в этом такого грандиозного? Помните ошибку, которую мы получали для
нашей дженерик функции `inverse`?

```text
error: binary operation `==` cannot be applied to type `T`
```

Мы можем использовать трейты для ограничения дженериков. Рассмотрим похожую
функцию, которая также не компилируется, и выводит ошибку:

```{rust,ignore}
fn print_area<T>(shape: T) {
    println!("This shape has an area of {}", shape.area());
}
```

Rust выводит:

```text
error: type `T` does not implement any method in scope named `area`
```

Поскольку `T` может быть любого типа, мы не можем быть уверены, что он реализует
метод `area`. Но мы можем добавить **ограничение по трейту** к нашему дженерику
`T`, гарантируя, что он будет соответствовать требованиям:

```{rust}
# trait HasArea {
#     fn area(&self) -> f64;
# }
fn print_area<T: HasArea>(shape: T) {
    println!("This shape has an area of {}", shape.area());
}
```

Синтаксис `<T: HasArea>` означает **любой тип, реализующий трейт `HasArea`**.
Так как трейты определяют сигнатуры типов функций, мы можем быть уверены, что
любой тип, который реализует `HasArea` будет иметь метод `.area()`.

Вот расширенный пример того, как это работает:

```{rust}
# #![feature(core)]
trait HasArea {
    fn area(&self) -> f64;
}

struct Circle {
    x: f64,
    y: f64,
    radius: f64,
}

impl HasArea for Circle {
    fn area(&self) -> f64 {
        std::f64::consts::PI * (self.radius * self.radius)
    }
}

struct Square {
    x: f64,
    y: f64,
    side: f64,
}

impl HasArea for Square {
    fn area(&self) -> f64 {
        self.side * self.side
    }
}

fn print_area<T: HasArea>(shape: T) {
    println!("This shape has an area of {}", shape.area());
}

fn main() {
    let c = Circle {
        x: 0.0f64,
        y: 0.0f64,
        radius: 1.0f64,
    };

    let s = Square {
        x: 0.0f64,
        y: 0.0f64,
        side: 1.0f64,
    };

    print_area(c);
    print_area(s);
}
```

Ниже показан вывод программы:

```text
This shape has an area of 3.141593
This shape has an area of 1
```

Как вы можете видеть, теперь `print_area` не только является дженериком, но и
гарантирует, что будет получен корректный тип. Если же мы передадим некорректный
тип:

```{rust,ignore}
print_area(5);
```

Мы получим ошибку времени компиляции:

```text
error: failed to find an implementation of trait main::HasArea for int
```

До сих пор мы добавляли реализации трейтов лишь для структур, но реализовать
трейт возможно для любого типа. Технически, мы _могли бы_ реализовать `HasArea`
для `i32`:

```{rust}
trait HasArea {
    fn area(&self) -> f64;
}

impl HasArea for i32 {
    fn area(&self) -> f64 {
        println!("this is silly");

        *self as f64
    }
}

5.area();
```

Хотя технически это возможно, но реализация методов для таких примитивных типов
считается плохим стилем программирования.

Такой подход может показаться неконтролируемым, однако есть два ограничения,
связанные с реализацией трейтов, которые мешают коду выйти из-под контроля. Во-
первых, трейты должны быть объявлены используемыми, с помощью ключевого слова
`use`, в той области видимости, где вы хотите использовать методы этих трейтов.
Так, например, следующий код не будет работать:

```{rust,ignore}
mod shapes {
    use std::f64::consts;

    trait HasArea {
        fn area(&self) -> f64;
    }

    struct Circle {
        x: f64,
        y: f64,
        radius: f64,
    }

    impl HasArea for Circle {
        fn area(&self) -> f64 {
            consts::PI * (self.radius * self.radius)
        }
    }
}

fn main() {
    let c = shapes::Circle {
        x: 0.0f64,
        y: 0.0f64,
        radius: 1.0f64,
    };

    println!("{}", c.area());
}
```

Теперь, когда мы переместили структуры и трейты в свой собственный модуль, мы
получаем следующую ошибку:

```text
error: type `shapes::Circle` does not implement any method in scope named `area`
```

Если мы добавим строку с `use` над функцией `main` и сделаем нужные элементы
публичными, все будет в порядке:

```{rust}
# #![feature(core)]
mod shapes {
    use std::f64::consts;

    pub trait HasArea {
        fn area(&self) -> f64;
    }

    pub struct Circle {
        pub x: f64,
        pub y: f64,
        pub radius: f64,
    }

    impl HasArea for Circle {
        fn area(&self) -> f64 {
            consts::PI * (self.radius * self.radius)
        }
    }
}

use shapes::HasArea;

fn main() {
    let c = shapes::Circle {
        x: 0.0f64,
        y: 0.0f64,
        radius: 1.0f64,
    };

    println!("{}", c.area());
}
```

Это означает, что даже если кто-то сделает что-то плохое, как например добавит
методы к `int`, на наш код это не окажет влияния, если вы не объявите `use` для
этого трейта.

Вот еще одно ограничение, связанное с реализацией трейтов. Либо трейт, либо тип,
для которого вы пишете `impl`, должны находиться в вашем крейте. Таким образом,
мы могли бы реализовать трейт `HasArea` для `i32`, потому что `HasArea`
находится в нашем крейте. Но если бы мы попытались реализовать трейт `Float`,
предоставляемый самим Rust, для `i32`, мы не смогли бы этого сделать, потому что
оба: трейт и тип отсутствуют в нашем крейте.

Последнее, что нужно сказать о трейтах: дженерик функции с ограничением по
трейтам используют *мономорфизацию* (*mono*: один, *morph*: форма), поэтому они
диспетчеризуются статически. Что это значит? Посмотрите главу [Статическая и
динамическая диспетчеризация](static-and-dynamic-dispatch.html), чтобы получить
больше информации.

## Множественные привязки к трейтам

Вы уже видели как можно ограничить обобщенный параметр типа определенным
трейтом:

```rust
fn foo<T: Clone>(x: T) {
    x.clone();
}
```

Если вам нужно более одной привязки, то вы можете использовать `+`:

```rust
use std::fmt::Debug;

fn foo<T: Clone + Debug>(x: T) {
    x.clone();
    println!("{:?}", x);
}
```

Теперь тип `T` должен реализовавать как трейт `Clone`, так и трейт `Debug`.

## Утверждение where

Написание функций с несколькими дженерик типами и небольшим количеством
ограничений по трейтам выглядит не так уж плохо, но, с увеличением количества
зависимостей, синтаксис получается более неуклюжим:

```
use std::fmt::Debug;

fn foo<T: Clone, K: Clone + Debug>(x: T, y: K) {
    x.clone();
    y.clone();
    println!("{:?}", y);
}
```

Имя функции находится слева, а список параметров - далеко справа. Привязки
загромождают место.

Rust имеет решение на этот счет, и оно называется 'утверждение `where`':

```
use std::fmt::Debug;

fn foo<T: Clone, K: Clone + Debug>(x: T, y: K) {
    x.clone();
    y.clone();
    println!("{:?}", y);
}

fn bar<T, K>(x: T, y: K) where T: Clone, K: Clone + Debug {
    x.clone();
    y.clone();
    println!("{:?}", y);
}

fn main() {
    foo("Hello", "world");
    bar("Hello", "workd");
}
```

`foo()` использует синтаксис, показанный ранее, а `bar()` использует утверждение
`where`. Все, что нам нужно сделать, это убрать ограничения при определении
типов параметров, а затем добавить `where` после списка параметров. Для более
длинного списка, могут быть добавлены пробельные символы:

```
use std::fmt::Debug;

fn bar<T, K>(x: T, y: K)
    where T: Clone,
          K: Clone + Debug {

    x.clone();
    y.clone();
    println!("{:?}", y);
}
```

Такая гибкость может добавить ясности в сложных ситуациях.

`where` является более мощным инструментом, чем просто синтаксис. Например:

```
trait ConvertTo<Output> {
    fn convert(&self) -> Output;
}

impl ConvertTo<i64> for i32 {
    fn convert(&self) -> i64 { *self as i64 }
}

// can be called with T == i32
fn normal<T: ConvertTo<i64>>(x: &T) -> i64 {
    x.convert()
}

// can be called with T == i64
fn inverse<T>() -> T
        // this is using ConvertTo as if it were "ConvertFrom<i32>"
        where i32: ConvertTo<T> {
    1i32.convert()
}
```

Этот код демонстрирует дополнительные преимущества использования утверждения
`where`: оно позволяет задавать ограничение, где с левой стороны располагается
произвольный тип (в данном случае `i32`), а не только простой параметр типа (как
например `T`).

## Наш пример `inverse`

Вернемся к разделу [Дженерики](generics.html), мы пытались написать такой код:

```{rust,ignore}
fn inverse<T>(x: T) -> Result<T, String> {
    if x == 0.0 { return Err("x cannot be zero!".to_string()); }

    Ok(1.0 / x)
}
```

Если мы попытаемся скомпилировать его, мы получим такую ошибку:

```text
error: binary operation `==` cannot be applied to type `T`
```

Все потому, что тип `T` является слишком общим: мы не можем знать наверняка, что
любой случайный `T` можно сравнивать. Для конкретизации мы можем ограничить его
трейтом. Хотя этот код и не будет работать, но попробуйте сделать следующее:

```{rust,ignore}
fn inverse<T: PartialEq>(x: T) -> Result<T, String> {
    if x == 0.0 { return Err("x cannot be zero!".to_string()); }

    Ok(1.0 / x)
}
```

Вы получите ошибку:

```text
error: mismatched types:
 expected `T`,
    found `_`
(expected type parameter,
    found floating-point variable)
```

Как уже было сказано, этот код не будет работать. Это потому, что наш `T`
реализует `PartialEq`, который принимает на вход другой `T`, но, вместо этого,
мы передаем переменную с плавающей точкой. Нам нужно другое ограничение. С
помощью `Float` можно исправить ошибку:

```
# #![feature(std_misc)]
use std::num::Float;

fn inverse<T: Float>(x: T) -> Result<T, String> {
    if x == Float::zero() { return Err("x cannot be zero!".to_string()) }

    let one: T = Float::one();
    Ok(one / x)
}
```

Нам следует заменить `0.0` и `1.0` соответствующими методами из трейта `Float`.
И `f32`, и `f64` реализуют трейт `Float`, так что наша функция будет работать
просто отлично:

```
# #![feature(std_misc)]
# use std::num::Float;
# fn inverse<T: Float>(x: T) -> Result<T, String> {
#     if x == Float::zero() { return Err("x cannot be zero!".to_string()) }
#     let one: T = Float::one();
#     Ok(one / x)
# }
println!("the inverse of {} is {:?}", 2.0f32, inverse(2.0f32));
println!("the inverse of {} is {:?}", 2.0f64, inverse(2.0f64));

println!("the inverse of {} is {:?}", 0.0f32, inverse(0.0f32));
println!("the inverse of {} is {:?}", 0.0f64, inverse(0.0f64));
```

## Методы по умолчанию

Есть еще одна особенность трейтов, которую мы должны охватывать: методы по
умолчанию. Проще всего это показать на примере:

```rust
trait Foo {
    fn bar(&self);

    fn baz(&self) { println!("We called baz."); }
}
```

При реализации трейта `Foo` необходимо реализовать метод `bar()`, но нет
необходимости в реализации метода `baz()`. Это поведение будет реализовано по
умолчанию. По желанию, можно переопределить значение метода по умолчанию:

```rust
# trait Foo {
# fn bar(&self);
# fn baz(&self) { println!("We called baz."); }
# }
struct UseDefault;

impl Foo for UseDefault {
    fn bar(&self) { println!("We called bar."); }
}

struct OverrideDefault;

impl Foo for OverrideDefault {
    fn bar(&self) { println!("We called bar."); }

    fn baz(&self) { println!("Override baz!"); }
}

let default = UseDefault;
default.baz(); // prints "We called baz."

let over = OverrideDefault;
over.baz(); // prints "Override baz!"
```
