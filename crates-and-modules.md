% Крейты и модули

Когда проект начинает разрастаться, то хорошей практикой разработки программного
обеспечения считается разбить его на кучу мелких кусочков, а затем собрать их
вместе. Также важно иметь четко определенный интерфейс, потому что часть вашей
функциональности является приватной, а часть - публичной. Для облегчения такого
рода вещей, Rust обладает модульной системой.

# Основные термины: крейты и модули

Rust имеет два различных термина, которые относятся к модульной системе: *крейт*
и *модуль*. Крейт - это синоним *библиотеки* или *пакета* на других языках.
Именно поэтому инструмент управления пакетами в Rust называется "Cargo": вы
пересылаете ваши ящики (crate - ящик) другим в виде груза (cargo - груз). Крейты
могут производить исполняемый файл или библиотеку, в зависимости от проекта.

Каждый крейт имеет неявный *корневой модуль*, содержащий код для этого ящика. В
рамках этого базового модуля можно определить дерево суб-модулей. Модули
позволяют разделить ваш код внутри крейта.

В качестве примера, давайте сделаем крейт *phrases*, который выдает нам
различные фразы на разных языках. Чтобы не усложнять пример, мы будем
использовать два вида фраз: "greetings" и "farewells", и два языка для этих
фраз: английский и японский (日本語). Мы будем использовать следующий шаблон
модуля:

```text
                                    +-----------+
                                +---| greetings |
                                |   +-----------+
                  +---------+   |
              +---| english |---+
              |   +---------+   |   +-----------+
              |                 +---| farewells |
+---------+   |                     +-----------+
| phrases |---+
+---------+   |                     +-----------+
              |                 +---| greetings |
              |   +----------+  |   +-----------+
              +---| japanese |--+
                  +----------+  |
                                |   +-----------+
                                +---| farewells |
                                    +-----------+
```

В этом примере, `phrases` - это название нашего крейта. Все остальное - модули.
Вы можете видеть, что они образуют дерево, в основании которого располагается
*корневой* крейт - `phrases`.

Теперь, когда у нас есть шаблон, давайте определим эти модули в коде. Для начала
создайте новый крейт с помощью Cargo:

```bash
$ cargo new phrases
$ cd phrases
```

Если вы помните, то эта команда создает простой проект:

```bash
$ tree .
.
├── Cargo.toml
└── src
    └── lib.rs

1 directory, 2 files
```

`src/lib.rs` - наш корневой крейт, соответствующий `phrases` в нашей диаграмме
выше.

# Определение модулей

Для определения каждого из наших модулей, мы используем ключевое слово `mod`.
Давайте сделаем, чтобы наш `src/lib.rs` выглядел следующим образом:

```
mod english {
    mod greetings {
    }

    mod farewells {
    }
}

mod japanese {
    mod greetings {
    }

    mod farewells {
    }
}
```

После ключевого слова `mod`, вы задаете имя модуля. Имена модулей следуют
соглашениям, как и другие идентификаторы Rust: `lower_snake_case`. Содержание
каждого модуля обрамляется в фигурные скобки (`{}`).

Внутри `mod` вы можете объявить суб-`mod`. Мы можем обращаться к суб-модулям с
помощью нотации (`::`). Обращение к нашим четырем вложенным модулям:
`english::greetings`, `english::farewells`, `japanese::greetings` и
`japanese::farewells`. Так как суб-модули располагаются в пространстве имен
своих родительских модулей, то суб-модули `english::greetings` и
`japanese::greetings` не конфликтуют, несмотря на то, что они имеют одинаковые
имена `greetings`.

Так как в этом крейте нет функции `main()`, и называется он `lib.rs`, Cargo
соберет этот ящик в виде библиотеки:

```bash
$ cargo build
   Compiling phrases v0.0.1 (file:///home/you/projects/phrases)
$ ls target
deps  libphrases-a7448e02a0468eaa.rlib  native
```

`libphrase-hash.rlib` - это скомпилированный крейт. Прежде чем мы рассмотрим,
как использовать этот крейт из другого крейта, давайте разобьем его на несколько
файлов.

# Крейты с несколькими файлами

Если бы каждый крейт мог состоять только из одного файла, то этот файл был бы
очень большими. Зачастую легче разделить крейты на несколько файлов, и Rust
поддерживает это двумя способами.

Вместо объявления модуля наподобие:

```{rust,ignore}
mod english {
    // contents of our module go here
}
```

Мы можем объявить наш модуль в виде:

```{rust,ignore}
mod english;
```

Если мы это сделаем, то Rust будет ожидать, что найдет либо файл `english.rs`,
либо файл `english/mod.rs` с содержимым нашего модуля.

Обратите внимание, что в этих файлах вам не нужно заново объявить модуль: это
уже сделано при изначальной декларации `mod`.

С помощью этих двух приемов мы можем разбить наш крейт на две директории и семь
файлов:

```bash
$ tree .
.
├── Cargo.lock
├── Cargo.toml
├── src
│   ├── english
│   │   ├── farewells.rs
│   │   ├── greetings.rs
│   │   └── mod.rs
│   ├── japanese
│   │   ├── farewells.rs
│   │   ├── greetings.rs
│   │   └── mod.rs
│   └── lib.rs
└── target
    ├── deps
    ├── libphrases-a7448e02a0468eaa.rlib
    └── native
```

`src/lib.rs` - наш корневой крейт, и выглядит он следующим образом:

```{rust,ignore}
mod english;
mod japanese;
```

Эти две декларации информируют Rust, что следует искать: `src/english.rs` или
`src/english/mod.rs`, `src/japanese.rs` или `src/japanese/mod.rs`, в зависимости
от нашей структуры. В данном примере мы выбрали второй вариант из-за того, что
наши модули содержат суб-модули. И `src/english/mod.rs` и `src/japanese/mod.rs`
выглядят следующим образом:

```{rust,ignore}
mod greetings;
mod farewells;
```

Опять же, эти декларации информируют Rust, что следует искать:
`src/english/greetings.rs`, `src/japanese/greetings.rs`,
`src/english/farewells.rs`, `src/japanese/farewells.rs` или
`src/english/greetings/mod.rs`, `src/japanese/greetings/mod.rs`,
`src/english/farewells/mod.rs`, `src/japanese/farewells/mod.rs`. Так как эти
суб-модули не содержат свои собственные суб-модули, то мы выбрали
`src/english/greetings.rs` и `src/japanese/farewells.rs`. Вот так!

Содержание `src/english/greetings.rs` и `src/japanese/farewells.rs` являются
пустыми на данный момент. Давайте добавим несколько функций.

Поместите следующий код в `src/english/greetings.rs`:

```rust
fn hello() -> String {
    "Hello!".to_string()
}
```

Следующий код в `src/english/farewells.rs`:

```rust
fn goodbye() -> String {
    "Goodbye.".to_string()
}
```

Следующий код в `src/japanese/greetings.rs`:

```rust
// in src/japanese/greetings.rs

fn hello() -> String {
    "こんにちは".to_string()
}
```

Конечно, вы можете скопировать и вставить этот код с этой страницы, или просто
напечатать что-нибудь еще. Не важно, что вы на самом деле поместили
"Konnichiwa", чтобы узнать о модульной системе.

Поместите следующий код в `src/japanese/farewells.rs`:

```rust
fn goodbye() -> String {
    "さようなら".to_string()
}
```

(Это "Sayonara", если вам интересно.)

Теперь у нас есть некоторая функциональность в нашем крейте, давайте попробуем
использовать его из другого крейта.

# Импорт внешних крейтов

У нас есть крейт библиотека. Давайте создадим исполняемый крейт, который
импортирует и использует нашу библиотеку.

Создайте `src/main.rs` и положите в не него следующее: (при этом он не будет
компилироваться)

```rust,ignore
extern crate phrases;

fn main() {
    println!("Hello in English: {}", phrases::english::greetings::hello());
    println!("Goodbye in English: {}", phrases::english::farewells::goodbye());

    println!("Hello in Japanese: {}", phrases::japanese::greetings::hello());
    println!("Goodbye in Japanese: {}", phrases::japanese::farewells::goodbye());
}
```

Декларация `extern crate` информирует Rust о том, что для компиляции и линковки
кода нам нужен крейт `phrases`. После этого мы сможем использовать модули
`phrases` здесь. Как мы уже упоминали ранее, вы можете использовать двойные
двоеточия для обращения к суб-модулям и функциям внутри них.

Кроме того, Cargo предполагает, что `src/main.rs` это корневой крейт бинарного
крейта, а не крейта библиотеки. Теперь наш пакет содержит два крейта:
`src/lib.rs` и `src/main.rs`. Этот шаблон является довольно распространенным для
исполняемых крейтов: основная функциональность сосредоточена в библиотечном
крейте, а исполняемый крейт использует эту библиотеку. Таким образом, другие
программы также могут использовать крейт библиотеку, к тому же этот подход
обеспечивает отделение интереса (разделение функциональности).

Хотя зтот все еще не работает. Мы получаем четыре ошибки, которые выглядят
примерно так:

```bash
$ cargo build
   Compiling phrases v0.0.1 (file:///home/you/projects/phrases)
/home/you/projects/phrases/src/main.rs:4:38: 4:72 error: function `hello` is private
/home/you/projects/phrases/src/main.rs:4     println!("Hello in English: {}", phrases::english::greetings::hello());
                                                                           ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
note: in expansion of format_args!
<std macros>:2:23: 2:77 note: expansion site
<std macros>:1:1: 3:2 note: in expansion of println!
/home/you/projects/phrases/src/main.rs:4:5: 4:76 note: expansion site

```

По умолчанию, все элементы в Rust являются приватными. Давайте поговорим об этом
более подробно.

# Экспорт публичных интерфейсов

Rust позволяет точно контролировать, какие элементы вашего интерфейса являются
публичными, и поэтому по умолчанию элементы являются приватными. Чтобы сделать
элементы публичными, вы используете ключевое слово `pub`. Давайте сначала
сосредоточимся на модуле `english`, поэтому сократим файл `src/main.rs` до
этого:

```{rust,ignore}
extern crate phrases;

fn main() {
    println!("Hello in English: {}", phrases::english::greetings::hello());
    println!("Goodbye in English: {}", phrases::english::farewells::goodbye());
}
```

В файле `src/lib.rs` давайте добавим `pub` в объявлении модуля `english`:

```{rust,ignore}
pub mod english;
mod japanese;
```

И в файле `src/english/mod.rs` давайте сделаем оба модуля `pub`:

```{rust,ignore}
pub mod greetings;
pub mod farewells;
```

В файле `src/english/greetings.rs` давайте добавим `pub` к декларации нашей
функции `fn`:

```{rust,ignore}
pub fn hello() -> String {
    "Hello!".to_string()
}
```

А также в `src/english/farewells.rs`:

```{rust,ignore}
pub fn goodbye() -> String {
    "Goodbye.".to_string()
}
```

Теперь наши крейты компилируются, хотя и с предупреждениями о том, что функции в
модуле `japanese` не используются:

```bash
$ cargo run
   Compiling phrases v0.0.1 (file:///home/you/projects/phrases)
/home/you/projects/phrases/src/japanese/greetings.rs:1:1: 3:2 warning: code is never used: `hello`, #[warn(dead_code)] on by default
/home/you/projects/phrases/src/japanese/greetings.rs:1 fn hello() -> String {
/home/you/projects/phrases/src/japanese/greetings.rs:2     "こんにちは".to_string()
/home/you/projects/phrases/src/japanese/greetings.rs:3 }
/home/you/projects/phrases/src/japanese/farewells.rs:1:1: 3:2 warning: code is never used: `goodbye`, #[warn(dead_code)] on by default
/home/you/projects/phrases/src/japanese/farewells.rs:1 fn goodbye() -> String {
/home/you/projects/phrases/src/japanese/farewells.rs:2     "さようなら".to_string()
/home/you/projects/phrases/src/japanese/farewells.rs:3 }
     Running `target/phrases`
Hello in English: Hello!
Goodbye in English: Goodbye.
```

Теперь, когда наши функции являются публичными, мы можем использовать их.
Отлично! Тем не менее, написание `phrases::english::greetings::hello()` является
очень длинным и неудобным. Rust предоставляет другое ключевое слово, для импорта
имен в текущую область, чтобы для обращения можно было использовать короткие
имена. Давайте поговорим об этом ключевом слове `use`.

# Импорт модулей с помощью `use`

Rust предоставляет ключевое слово `use`, которое позволяет импортировать имена в
нашу локальную область видимости. Давайте изменим наш файл `src/main.rs`, чтобы
он выглядел следующим образом:

```{rust,ignore}
extern crate phrases;

use phrases::english::greetings;
use phrases::english::farewells;

fn main() {
    println!("Hello in English: {}", greetings::hello());
    println!("Goodbye in English: {}", farewells::goodbye());
}
```

Две строки с `use` импортируют соответствующие модули в локальную область
видимости, поэтому мы можем обратиться к функциям по гораздо более коротким
именам. По соглашению, при импорте функции, лучшей практикой считается
импортировать модуль, а не функцию непосредственно. Другими словами, вы _могли
бы_ сделать следующее:

```{rust,ignore}
extern crate phrases;

use phrases::english::greetings::hello;
use phrases::english::farewells::goodbye;

fn main() {
    println!("Hello in English: {}", hello());
    println!("Goodbye in English: {}", goodbye());
}
```

Но такой подход не является идиоматическим. Он значительно чаще приводит к
конфликту имен. Для нашей короткой программы это не так важно, но, как только
программа разрастается, это становится проблемой. Если у нас возникает конфликт
имен, Rust выдает ошибку компиляции. Например, если мы сделаем функции
`japanese` публичными, и пытаемся сделать это:

```{rust,ignore}
extern crate phrases;

use phrases::english::greetings::hello;
use phrases::japanese::greetings::hello;

fn main() {
    println!("Hello in English: {}", hello());
    println!("Hello in Japanese: {}", hello());
}
```

Rust выдаст нам сообщение об ошибке во время компиляции:

```text
   Compiling phrases v0.0.1 (file:///home/you/projects/phrases)
/home/you/projects/phrases/src/main.rs:4:5: 4:40 error: a value named `hello` has already been imported in this module
/home/you/projects/phrases/src/main.rs:4 use phrases::japanese::greetings::hello;
                                          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
error: aborting due to previous error
Could not compile `phrases`.
```

Если мы импортируем несколько имен из одного модуля, то нам совсем не
обязательно писать одно и то же много раз. Вместо этого кода:

```{rust,ignore}
use phrases::english::greetings;
use phrases::english::farewells;
```

Вы можете использовать сокращение:

```{rust,ignore}
use phrases::english::{greetings, farewells};
```

## Реэкспорт с помощью `pub use`

Вы можете использовать `use` не просто для сокращения идентификаторов. Вы также
можете использовать его внутри вашего крейта, чтобы реэкспортировать функцию из
другого модуля. Это позволяет представить внешний интерфейс, который может не
напрямую отображать внутреннюю организацию кода.

Давайте посмотрим на примере. Измените файл `src/main.rs` следующим образом:

```{rust,ignore}
extern crate phrases;

use phrases::english::{greetings,farewells};
use phrases::japanese;

fn main() {
    println!("Hello in English: {}", greetings::hello());
    println!("Goodbye in English: {}", farewells::goodbye());

    println!("Hello in Japanese: {}", japanese::hello());
    println!("Goodbye in Japanese: {}", japanese::goodbye());
}
```

Затем измените файл `src/lib.rs`, чтобы сделать модуль `japanese` с публичным:

```{rust,ignore}
pub mod english;
pub mod japanese;
```

Далее, убедитесь, что обе функции публичные, сперва в
`src/japanese/greetings.rs`:

```{rust,ignore}
pub fn hello() -> String {
    "こんにちは".to_string()
}
```

А затем в `src/japanese/farewells.rs`:

```{rust,ignore}
pub fn goodbye() -> String {
    "さようなら".to_string()
}
```

Наконец, измените файл `src/japanese/mod.rs` вот так:

```{rust,ignore}
pub use self::greetings::hello;
pub use self::farewells::goodbye;

mod greetings;

mod farewells;
```

Декларация `pub use` переносит функцию в рамках в этой части нашего модуля
иерархии. Так как мы использовали `pub use` внутри нашего модуля `japanese`, то
теперь мы можем вызывать функцию `phrases::japanese::hello()` и функцию
`phrases::japanese::goodbye()`, хотя код для них расположен в
`phrases::japanese::greetings::hello()` и
`phrases::japanese::farewells::goodbye()` соответственно. Наша внутренняя
организация не определяет наш внешний интерфейс.

Здесь мы используем `pub use` для каждой функции, которую хотим перенести в
область `japanese`. В качестве альтернативы, мы могли бы использовать шаблонный
синтаксис, чтобы включать в себя все элементы из модуля `greetings` в текущую
области: `pub use self::greetings::*`.

Что можно сказать о `self`? По умолчанию декларации `use` используют абсолютные
пути, начинающиеся с корневого крейта. `self`, напротив, формирует эти пути
относительно текущего места в иерархии. У `use` есть еще одна особая форма: вы
можете использовать `use super::`, чтобы подняться на один уровень вверх по
дереву от вашего текущего местоположения. Некоторые предпочитают думать о `self`
как о `.`, а о `super` как о `..`, что для многих командных оболочек является
представлением для текущей директории и для родительской директории
соответственно.

Вне `use`, пути относительны: `foo::bar()` относится к функции внутри `foo`
относительно того, где мы находимся. Если же используется префикс `::`, как в
`::foo::bar()`, это указывает на другой `foo`, абсолютный путь относительно
корневого крейта.

Кроме того, обратите внимание, что мы использовали `pub use` прежде, чем
объявили наши модули `mod`. Rust требует, чтобы декларации `use` шли в первую
очередь.

Следующий код собирается и работает:

```bash
$ cargo run
   Compiling phrases v0.0.1 (file:///home/you/projects/phrases)
     Running `target/phrases`
Hello in English: Hello!
Goodbye in English: Goodbye.
Hello in Japanese: こんにちは
Goodbye in Japanese: さようなら
```
