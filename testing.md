% Тестирование

> Program testing can be a very effective way to show the presence of bugs, but
> it is hopelessly inadequate for showing their absence.
>
> Edsger W. Dijkstra, "The Humble Programmer" (1972)

Давайте поговорим о том, как тестировать Rust код. Мы не будем рассказывать о
том, какой подход к тестированию Rust кода является правильным. Есть много
подходов, каждый из которых имеет свое представление о правильном написании
тестов. Но все эти подходы используют одни и те же основные инструменты, и мы
покажем вам синтаксис их использования.

# Тесты с аттрибутом `test`

В самом простом случае, тест в Rust - это функция, аннотированная с помощью
атрибута `test`. Давайте создадим новый проект с помощью Cargo, который будет
называться `adder`:

```bash
$ cargo new adder
$ cd adder
```

При создании нового проекта, Cargo автоматически сгенерирует простой тест. Ниже
представлено содержимое `src/lib.rs`:

```rust
#[test]
fn it_works() {
}
```

Обратите внимание на `#[test]`. Этот аттрибут указывает, что это тестовая
функция. Сейчас она не имеет тела функции. Но такого вида функции достаточно,
чтобы успешно выполнить тест. Запуск тестов осуществляется командой `cargo
test`.

```bash
$ cargo test
   Compiling adder v0.0.1 (file:///home/you/projects/adder)
     Running target/adder-91b3e234d4ed382a

running 1 test
test it_works ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

   Doc-tests adder

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured
```

Cargo компилирует и запускает ваши тесты. В результате мы получаем выходные
данные, поделенные на два раздела: один содержит информацию о тесте, который мы
написали, а другой - информацию о тестах из документации. Но об этом позже. А
сейчас посмотрим на эту строку:

```text
test it_works ... ok
```

Обратите внимание на `it_works`. Это название нашей функции:

```rust
fn it_works() {
# }
```

Мы также получаем итоговую строку:

```text
test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured
```

Так почему же наш ничего не делающий тест был выполнен успешно? Любой тест,
который не вызывает `panic!`, выполняется успешно, и любой тест, который
вызывает `panic!`, выполняется неудачно. Давайте сделаем тест, который
выполнится неудачно:

```rust
#[test]
fn it_works() {
    assert!(false);
}
```

`assert!` является макросом, который принимает один аргумент: если аргумент
имеет значение `true`, то ничего не происходит; если аргумент является `false`,
то вызывается `panic!`. Давайте запустим наши тесты снова:

```bash
$ cargo test
   Compiling adder v0.0.1 (file:///home/you/projects/adder)
     Running target/adder-91b3e234d4ed382a

running 1 test
test it_works ... FAILED

failures:

---- it_works stdout ----
        thread 'it_works' panicked at 'assertion failed: false', /home/steve/tmp/adder/src/lib.rs:3



failures:
    it_works

test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured

thread '<main>' panicked at 'Some tests failed', /home/steve/src/rust/src/libtest/lib.rs:247
```

Rust сообщает, что наш тест выполнен неудачно:

```text
test it_works ... FAILED
```

Это же отражается в итоговой строке:

```text
test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured
```

Мы также получаем ненулевой код состояния:

```bash
$ echo $?
101
```

Это полезно, если вы хотите интегрировать `cargo test` в сторонний инструмент.

Мы можем обратить ожидаемый результат теста с помощью атрибута: `should_panic`:

```rust
#[test]
#[should_panic]
fn it_works() {
    assert!(false);
}
```

Теперь этот тест будет выполнен успешно, если вызывается `panic!`, и неудачно,
если `panic!` не вызывается. Давайте попробуем:

```bash
$ cargo test
   Compiling adder v0.0.1 (file:///home/you/projects/adder)
     Running target/adder-91b3e234d4ed382a

running 1 test
test it_works ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

   Doc-tests adder

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured
```

Rust предоставляет и другой макрос, `assert_eq!`, который проверяет
эквивалентность двух артументов:

```rust
#[test]
#[should_panic]
fn it_works() {
    assert_eq!("Hello", "world");
}
```

А теперь этот тест будет выполнен успешно или неудачно? Из-за атрибута
`should_panic` он завершится успешно:

```bash
$ cargo test
   Compiling adder v0.0.1 (file:///home/you/projects/adder)
     Running target/adder-91b3e234d4ed382a

running 1 test
test it_works ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

   Doc-tests adder

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured
```

`should_panic` тесты могут быть хрупкими, потому как трудно гарантировать, что
тест не выдаст панику по неожиданной причине. Чтобы помочь в этом аспекте, к
атрибуту `should_panic` может быть добавлен необязательный параметр `expected`.
Тогда тест также будет проверять, что сообщение об ошибке содержит ожидаемый
текст. Ниже представлен более безопасный вариант приведенного выше примера:

```
#[test]
#[should_panic(expected = "assertion failed")]
fn it_works() {
    assert_eq!("Hello", "world");
}
```

Вот и все, что касается основ! Давайте напишем один "реальный" тест:

```{rust,ignore}
pub fn add_two(a: i32) -> i32 {
    a + 2
}

#[test]
fn it_works() {
    assert_eq!(4, add_two(2));
}
```

Это распространенное использование макроса `assert_eq!`: вызывать некоторую
функцию с известными аргументами и сравнить ее вызов с ожидаемыми результатом.

# Тесты в модуле `test`

Есть один нюанс, из-за которого наш пример нельзя назвать идиоматическим:
отсутствует модуль тестирования. Идиоматический вариант написания нашего примера
будет выглядить примерно так:

```{rust,ignore}
pub fn add_two(a: i32) -> i32 {
    a + 2
}

#[cfg(test)]
mod tests {
    use super::add_two;

    #[test]
    fn it_works() {
        assert_eq!(4, add_two(2));
    }
}
```

Здесь есть несколько изменений. Первое - это введение `mod tests` с атрибутом
`cfg`. Модуль позволяет сгруппировать все наши тесты вместе, а также определить
вспомогательные функции, если это необходимо, которые будут отделены от
остальной части крейта. Атрибут `cfg` указывает на то, что тест будет
скомпилирован, только когда мы попытаемся запустить тесты. Это может сэкономить
время компиляции, а также гарантирует, что наши тесты полностью исключены из
обычного билда.

Второе изменение заключается в объявлении `use`. Так как мы находимся во
внутреннем модуле, то мы должны объявить использование тестируемой функции в его
области видимости. Это может раздражать, если у вас большой модуль, и поэтому
обычно используют фичу `glob`. Давайте, в соответствии с этим, изменим наш
`src/lib.rs`:

```{rust,ignore}

pub fn add_two(a: i32) -> i32 {
    a + 2
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        assert_eq!(4, add_two(2));
    }
}
```

Обратите внимание на различие в строке с `use`. Теперь запустим наши тесты:

```bash
$ cargo test
    Updating registry `https://github.com/rust-lang/crates.io-index`
   Compiling adder v0.0.1 (file:///home/you/projects/adder)
     Running target/adder-91b3e234d4ed382a

running 1 test
test test::it_works ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

   Doc-tests adder

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured
```

Работает!

Данный подход представляет собой использование модуля `test` содержащего тесты в
"юнит стиле". Любой код, задачей которого является только лишь тестирование
небольшего кусочка функциональности, имеет смысл перенести в этот модуль. Но что
если мы хотим использовать "интеграционный стиль" для создания тестов? Для этого
мы можем использовать директорию `tests`

# Тесты в директории `tests`

Чтобы написать интеграционный тест, давайте создадим директорию `tests`, и
положим в нее файл `tests/lib.rs` со следующим содержимое:

```{rust,ignore}
extern crate adder;

#[test]
fn it_works() {
    assert_eq!(4, adder::add_two(2));
}
```

Выглядит примерно так же, как и наши предыдущие тесты, но есть некоторые
отличия. Теперь сверху у нас расположено `extern crate adder`. Это потому, что
тесты в директории `tests` - это отдельный крейт, и, следовательно, мы должны
импортировать нашу библиотеку. Это также объясняет, почему директория `tests`
наиболее подходящее место для написания интеграционных тестов: они используют
библиотеку, как это делал бы любой другой потребитель.

Давайте запустим:

```bash
$ cargo test
   Compiling adder v0.0.1 (file:///home/you/projects/adder)
     Running target/adder-91b3e234d4ed382a

running 1 test
test test::it_works ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

     Running target/lib-c18e7d3494509e74

running 1 test
test it_works ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

   Doc-tests adder

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured
```

Теперь у нас появилось три раздела: запускается предыдущий тест, а также
запускается наш новый тест.

Это все, что касается директории `tests`. Модуль `test` здесь не нужен, так как
все здесь ориентировано на тесты.

Давайте, наконец, перейдем к третьей части: тесты из документации.

# Тесты в документации

Нет ничего лучше, чем документация с примерами. Нет ничего хуже, чем примеры,
которые на самом деле не работают, потому что код изменился с тех пор, как
документация была написана. Для этого, Rust поддерживает автоматический запуск
примеров в документации. Вот дополненный `src/lib.rs` с примерами:

```{rust,ignore}
//! The `adder` crate provides functions that add numbers to other numbers.
//!
//! # Examples
//!
//! ```
//! assert_eq!(4, adder::add_two(2));
//! ```

/// This function adds two to its argument.
///
/// # Examples
///
/// ```
/// use adder::add_two;
///
/// assert_eq!(4, add_two(2));
/// ```
pub fn add_two(a: i32) -> i32 {
    a + 2
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        assert_eq!(4, add_two(2));
    }
}
```

Обратите внимание на документацию уровня модуля, начинающуюся с `//!` и на
документацию уровня функции, начинающуюся с `///`. Документация Rust
поддерживает Markdown в комментариях, поэтому блоки кода помечают тройным \`.
Обычно включают раздел `# Examples`, содержащий примеры, такие как этот.

Давайте запустим тесты снова:

```bash
$ cargo test
   Compiling adder v0.0.1 (file:///home/steve/tmp/adder)
     Running target/adder-91b3e234d4ed382a

running 1 test
test test::it_works ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

     Running target/lib-c18e7d3494509e74

running 1 test
test it_works ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

   Doc-tests adder

running 2 tests
test add_two_0 ... ok
test _0 ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured
```

Теперь у нас есть все три вида запущенных тестов! Обратите внимание на имена
тестов из документации: `_0` создается для модульных тестов, и `add_two_0` для
функцииональных тестов. Цифры на конце будут автоматически инкрементироваться,
например `add_two_1`, если вы добавите еще примеров.

# Тесты производительности

Rust также поддерживает тесты производительности, которые помогают измерить
производительность вашего кода. Давайте изменим наш `src/lib.rs`, чтобы он
выглядел следующим образом (комментарии опущены):

```{rust,ignore}
extern crate test;

pub fn add_two(a: i32) -> i32 {
    a + 2
}

#[cfg(test)]
mod tests {
    use super::*;
    use test::Bencher;

    #[test]
    fn it_works() {
        assert_eq!(4, add_two(2));
    }

    #[bench]
    fn bench_add_two(b: &mut Bencher) {
        b.iter(|| add_two(2));
    }
}
```

Мы импортировали крейт `test`, который содержит поддержку измерения
производительности. У нас есть новая функция, аннотированная с помощью атрибута
`bench`. В отличие от обычных тестов, которые не принимают никаких аргументов,
тесты производительности в качестве аргумента принимают `&mut Bencher`.
`Bencher` предоставляет метод `iter`, который в качестве аргумента принимает
замыкание. Это замыкание содержит код, производительность которого мы хотели бы
протестировать.

Запуск тестов производительности осуществляется командой `cargo bench`:

```bash
$ cargo bench
   Compiling adder v0.0.1 (file:///home/steve/tmp/adder)
     Running target/release/adder-91b3e234d4ed382a

running 2 tests
test tests::it_works ... ignored
test tests::bench_add_two ... bench:         1 ns/iter (+/- 0)

test result: ok. 0 passed; 0 failed; 1 ignored; 1 measured
```

Все тесты, не относящиеся к тестам производительности, были проигнорированы. Вы,
наверное, заметили, что выполнение `cargo bench` занимает немного больше времени
чем `cargo test`. Это происходит потому, что Rust запускает наш тест несколько
раз, а затем выдает среднее значение. Так как мы выполняем слишком мало полезной
работы в этом примере, у нас получается `1 ns/iter (+/- 0)`, но была бы выведена
дисперсия, если бы был один.

Советы по написанию тестов производительности:

* Внутри `iter` цикла пишите только тот код, производительность которой вы
  хотите измерить; инициализацию выполняйте за пределами `iter` цикла
* Внутри `iter` цикла пишите код, который будет идемпотентным (будет делать "то
  же самое" на каждой итерации); не накапливайте и не изменяйте состояние
* Вне `iter` цикла пишите код который также будет идемпотентным; скорее всего,
  он будет запущен много раз во время теста
* Внутри `iter` цикла пишите код, который будет коротким и быстрым, **так чтобы
  тестов работает быстро и калибратор можно настроить по длине прогона на четком
  разрешении**
* Внутри `iter` цикла пишите код, делающий что-то простое, чтобы помочь в
  выявлении улучшения (или уменьшения) производительности

## Особенности оптимизации

А вот другой сложный момент, относящийся к написанию тестов производительности:
тесты, скомпилированные с оптимизацией, могут быть значительно изменены
оптимизатором, после чего тест будет мерить производительность не так, как мы
этого ожидаем. Например, компилятор может определить, что некоторые выражения не
оказывают каких-либо внешних эффектов и просто удалит их полностью.

```{rust,ignore}
extern crate test;
use test::Bencher;

#[bench]
fn bench_xor_1000_ints(b: &mut Bencher) {
    b.iter(|| {
        (0..1000).fold(0, |old, new| old ^ new);
    });
}
```

выведет следующие результаты

```text
running 1 test
test bench_xor_1000_ints ... bench:         0 ns/iter (+/- 0)

test result: ok. 0 passed; 0 failed; 0 ignored; 1 measured
```

Движок для запуска тестов производительности оставляет две возможности,
позволяющие этого избежать. Либо использовать замыкание, передаваемое в метод
`iter`, которое возвращает какое-либо значение; тогда это заставит оптимизатор
думать, что возвращаемое значение будет использовано, из-за чего удалить
вычисления полностью будет не возможно. Для примера выше этого можно достигнуть,
изменив вызова `b.iter`

```rust
# struct X;
# impl X { fn iter<T, F>(&self, _: F) where F: FnMut() -> T {} } let b = X;
b.iter(|| {
    // note lack of `;` (could also use an explicit `return`).
    (0..1000).fold(0, |old, new| old ^ new)
});
```

Либо использовать вызов функции `test::black_box`, которая представляет собой
"черный ящик", непрозрачный для оптимизатора, тем самым заставляя его
рассматривать любой аргумент как используемый.

```rust
# #![feature(test)]

extern crate test;

# fn main() {
# struct X;
# impl X { fn iter<T, F>(&self, _: F) where F: FnMut() -> T {} } let b = X;
b.iter(|| {
    let n = test::black_box(1000);

    (0..n).fold(0, |a, b| a ^ b)
})
# }
```

В этом примере не происходит ни чтения, ни измения значения, что очень дешево
для малых значений. Большие значения могут быть переданы косвенно для уменьшения
издержек (например, `black_box(&huge_struct)`).

Выполнение одного из вышеперечисленных изменений дает следующие результаты
измерения производительности

```text
running 1 test
test bench_xor_1000_ints ... bench:       131 ns/iter (+/- 3)

test result: ok. 0 passed; 0 failed; 0 ignored; 1 measured
```

Тем не менее, оптимизатор все еще может вносить нежелательные изменения в
определенных случаях, даже при использовании любого из вышеописанных приемов.
