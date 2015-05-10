% Угадайка

В качестве нашего первого проекта, мы решим классическую для начинающих 
программистов задачу: игра-угадайка. Немного о том, как игра должна работать:
наша программа генерирует случайное целое число из промежутка от 1 до 100. Затем
она просит ввести число, которое она "загадала". Для каждого введённого нами 
числа, она говорит, больше ли оно, чем "загаданное", или меньше. Игра 
заканчивается когда мы отгадываем число. Звучит не плохо, не так ли?

# Создание нового проекта

Давайте создадим новый проект. Перейдите в вашу директорию с проектами. Помните,
как мы создавали структуру директорий и `Cargo.toml` для `hello_world`? Cargo 
может сделать это за нас. Давайте воспользуемся этим:

```bash
$ cd ~/projects
$ cargo new guessing_game --bin
$ cd guessing_game
```

Мы сказали Cargo, что хотим создать новый проект с именем `guessing_game`.При 
помощи флага `--bin`, мы указали что хотим создать исполняемый файл, а не 
библиотеку.

Давайте посмотрим сгенерированный `Cargo.toml`:

```toml
[package]

name = "guessing_game"
version = "0.0.1"
authors = ["Your Name <you@example.com>"]
```

Cargo взял эту информацию из вашего рабочего окружения. Если информация не 
корректна, исправьте её.

В завершение, Cargo создал программу `Hello, world!`. Посмотрите файл `src/main.rs`:

```rust
fn main() {
    println!("Hello, world!")
}
```

Давайте попробуем скомпилировать созданный Cargo проект:

```{bash}
$ cargo build
   Compiling guessing_game v0.0.1 (file:///home/you/projects/guessing_game)
```

Замечательно! Снова откройте `src/main.rs`. Мы будем писать весь наш код в этом
файле.

Прежде, чем мы начнём работу, давайте рассмотрим ещё одну команду Cargo: `run`.
`cargo run` похожа на `cargo build`, но после завершения компиляции, она 
запускает получившийся исполняемый файл:

```bash
$ cargo run
   Compiling guessing_game v0.0.1 (file:///home/you/projects/guessing_game)
     Running `target/debug/guessing_game`
Hello, world!
```

Великолепно! Команда `run` помогает, когда надо быстро пересобирать проект. Наша
игра как раз и есть такой проект: нам надо быстро тестировать каждое изменение,
прежде чем мы приступим к следующей части программы.

# Обработка предположения

Давайте начнём! Первая вещь, которую мы должны сделать для нашей игры - это 
позволить игроку вводить предположения. Поместите следующий код в ваш `src/main.rs`:

```rust,no_run
use std::io;

fn main() {
    println!("Угадайте число!");

    println!("Пожалуйста, введите предположение.");

    let mut guess = String::new();

    io::stdin().read_line(&mut guess)
        .ok()
        .expect("Не удалось прочитать строку");

    println!("Вы загадали: {}", guess);
}
```

Здесь много чего! Давайте разберём этот участок по частям.

```rust,ignore
use std::io;
```

Нам надо получить то, что ввёл пользователь, а затем вывести результат на экран.
Значит нам понадобится библиотека `io` из стандартной библиотеки. Изначально Rust 
импортирует лишь некоторые вещи в нашу программу, в так называемом [`вступлении`][prelude].
Если чего-то нет по вступлении, мы должны указать при помощи `use`, что хотим их
использовать.

[prelude]: ../std/prelude/index.html

```rust,ignore
fn main() {
```

Как вы уже видели до этого, функция `main()` - это точка входа в нашу программу.
`fn` объявляет новую функцию. Пустые круглые скобки `()` показывают, что она не
принимает аргументов. Открывающая фигурная скобка `{` начинает тело нашей 
функции. Из-за того, что мы не указали тип возвращаемого значения, предполагается,
что будет возвращаться `()` - пустой [кортеж][tuples].

[tuples]: primitive-types.html#tuples

```rust,ignore
    println!("Угадайте число!");

    println!("Пожалуйста, введите предположение.");
```

Мы уже изучили, что `println!()` - это [макрос][macro], который выводит 
[строки][strings] на экран.

[macros]: macros.html
[strings]: strings.html

```rust,ignore
    let mut guess = String::new();
```

Теперь интереснее! Как же много всего происходит в этой строке! Первая вещь, на 
которую следует обратить внимание - [выражение let][let], которое используется 
для `создания связи`. Оно выглядит так:

```rust,ignore
let foo = bar;
```

[let]: variable-bindings.html

Это создаёт новую связь с именем `foo` и привязывает ей значение `bar`. Во 
многих языках это называется `переменная`, но в Rust связывание переменных имеет
несколько трюков в рукаве.

Например, по умолчанию, связи [неизменяемы][immutable]. По этой причине наш пример
использует `mut`: этот модификатор разрешает менять связь. С стороны у `let` может
быть не просто имя связи, а [образец][patterns]. Мы будет использовать и дальше.
Их достаточно просто использовать:

```
let foo = 5; // неизменяемая связь
let mut bar = 5; // изменяемая связь
```

[immutable]: mutability.html
[patterns]: patterns.html

Ах да, `//` начинает комментарий, который заканчивается в конце строки. Rust 
игнорирует всё, что находится в [комментариях][comments].

[comments]: comments.html

Теперь мы знаем, что `let mut guess` объявляет изменяемую связь с именем `guess`,
но по другую сторону от `=` - это то, что будет привязано: `String::new()`.

`String` - это строковый тип, предоставляемый нам стандартной библиотекой.
[`String`][string] - это текст в кодировке UTF-8 переменной длины.

[string]: ../std/string/struct.String.html

Синтаксис `::new()` использует `::`, так как это привязанная к определённому 
типу функция. То есть, она привязана к самому типу `String`, а не к определённой
переменной типа `String`. Некоторые языки называют это "статическим методом".

Имя этой функции - `new()`, так как она создаёт новый, пустой `String`. Вы 
можете найти эту функцию у многих типов, потому что это общее имя для создания
нового значения определённого типа.

Давайте посмотри дальше:

```rust,ignore
    io::stdin().read_line(&mut guess)
        .ok()
        .expect("Не удалось прочитать строку");
```

Это уже побольше! Давайте это всё разберём. В первой строке есть две части.
Это первая:

```rust,ignore
io::stdin()
```

Помните, как мы импортировали (`use`) `std::io` в самом начале нашей программы?
Сейчас мы вызвали ассоциированную с ним функцию. Если бы мы не сделали `use std::io`,
нам бы пришлось здесь написать `std::io::stdin()`.

Эта функция возвращает обработчик стандартного ввода нашего терминала. Более 
подробно об это можно почитать в [std::io::Stdin][iostdin].

[iostdin]: http://doc.rust-lang.org/std/io/struct.Stdin.html

Следующая часть использует этот обработчик для получения всего, что введёт 
пользователь:

```rust,ignore
.read_line(&mut guess)
```

Здесь мы вызвали метод [`read_line()`][read_line] обработчика. [Методы][methos]
похожи на привязанные функции, но доступны только у определённого экземпляра
типа, а не самого типа. Мы указали один аргумент функции `read_line()`: `&mut guess`.

[read_line]: http://doc.rust-lang.org/std/io/struct.Stdin.html#method.read_line
[method]: methods.html

Помните, как мы выше привязали `guess`? Мы сказали, что она изменяема. Однако,
`read_line` не получает в качестве аргумента `String`: она получает `&mut String`.
В Rust есть такая особенность, называемая ["ссылки"][references], которая
позволяет нам иметь несколько ссылок на одни и так же данные, что позволяет 
избежать излишнего их копирования. Ссылки - достаточно сложная особенность, и
одним из основных подкупающих достоинств Rust является то, как он решает вопрос 
безопасности и простоты их использования. Пока что мы не должны знать об этих 
деталях, чтобы завершить нашу программу. Сейчас, всё, что нам нужно - это знать 
что ссылки, как и связывание при помощи `let`, неизменяемо по умолчанию. 
Следовательно, мы должны написать `&mut guess`, а не `&guess`.

Почему `read_line()` получает изменяемую ссылку на строку? Его работа - это взять
то, что пользователь написал в стандартный ввод, и положить это в строку. Итак,
функция получает строку в качестве аргумента, и для того, чтобы добавить в эту 
строку что-то, она должна быть изменяемой.

[references]: references-and-borrowing.html

But we’re not quite done with this line of code, though. While it’s
a single line of text, it’s only the first part of the single logical line of
code:

```rust,ignore
        .ok()
        .expect("Failed to read line");
```

When you call a method with the `.foo()` syntax, you may introduce a newline
and other whitespace. This helps you split up long lines. We _could_ have
done:

```rust,ignore
    io::stdin().read_line(&mut guess).ok().expect("failed to read line");
```

But that gets hard to read. So we’ve split it up, three lines for three
method calls. We already talked about `read_line()`, but what about `ok()`
and `expect()`? Well, we already mentioned that `read_line()` puts what
the user types into the `&mut String` we pass it. But it also returns
a value: in this case, an [`io::Result`][ioresult]. Rust has a number of
types named `Result` in its standard library: a generic [`Result`][result],
and then specific versions for sub-libraries, like `io::Result`.

[ioresult]: ../std/io/type.Result.html
[result]: ../std/result/enum.Result.html

The purpose of these `Result` types is to encode error handling information.
Values of the `Result` type, like any type, have methods defined on them. In
this case, `io::Result` has an `ok()` method, which says ‘we want to assume
this value is a successful one. If not, just throw away the error
information’. Why throw it away? Well, for a basic program, we just want to
print a generic error, as basically any issue means we can’t continue. The
[`ok()` method][ok] returns a value which has another method defined on it:
`expect()`. The [`expect()` method][expect] takes a value it’s called on, and
if it isn’t a successful one, [`panic!`][panic]s with a message you passed you
passed it. A `panic!` like this will cause our program to crash, displaying
the message.

[ok]: ../std/result/enum.Result.html#method.ok
[expect]: ../std/option/enum.Option.html#method.expect
[panic]: error-handling.html

If we leave off calling these two methods, our program will compile, but
we’ll get a warning:

```bash
$ cargo build
   Compiling guessing_game v0.1.0 (file:///home/you/projects/guessing_game)
src/main.rs:10:5: 10:39 warning: unused result which must be used,
#[warn(unused_must_use)] on by default
src/main.rs:10     io::stdin().read_line(&mut guess);
                   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

Rust warns us that we haven’t used the `Result` value. This warning comes from
a special annotation that `io::Result` has. Rust is trying to tell you that
you haven’t handled a possible error. The right way to suppress the error is
to actually write error handling. Luckily, if we just want to crash if there’s
a problem, we can use these two little methods. If we can recover from the
error somehow, we’d do something else, but we’ll save that for a future
project.

There’s just one line of this first example left:

```rust,ignore
    println!("You guessed: {}", guess);
}
```

This prints out the string we saved our input in. The `{}`s are a placeholder,
and so we pass it `guess` as an argument. If we had multiple `{}`s, we would
pass multiple arguments:

```rust
let x = 5;
let y = 10;

println!("x and y: {} and {}", x, y);
```

Easy.

Anyway, that’s the tour. We can run what we have with `cargo run`:

```bash
$ cargo run
   Compiling guessing_game v0.1.0 (file:///home/you/projects/guessing_game)
     Running `target/debug/guessing_game`
Guess the number!
Please input your guess.
6
You guessed: 6
```

All right! Our first part is done: we can get input from the keyboard,
and then print it back out.

# Generating a secret number

Next, we need to generate a secret number. Rust does not yet include random
number functionality in its standard library. The Rust team does, however,
provide a [`rand` crate][randcrate]. A ‘crate’ is a package of Rust code.
We’ve been building a ‘binary crate’, which is an executable. `rand` is a
‘library crate’, which contains code that’s intended to be used with other
programs.

[randcrate]: https://crates.io/crates/rand

Using external crates is where Cargo really shines. Before we can write
the code using `rand`, we need to modify our `Cargo.toml`. Open it up, and
add these few lines at the bottom:

```toml
[dependencies]

rand="0.3.0"
```

The `[dependencies]` section of `Cargo.toml` is like the `[package]` section:
everything that follows it is part of it, until the next section starts.
Cargo uses the dependencies section to know what dependencies on external
crates you have, and what versions you require. In this case, we’ve used version `0.3.0`.
Cargo understands [Semantic Versioning][semver], which is a standard for writing version
numbers. If we wanted to use the latest version we could use `*` or we could use a range 
of versions. [Cargo’s documentation][cargodoc] contains more details.

[semver]: http://semver.org
[cargodoc]: http://doc.crates.io/crates-io.html

Now, without changing any of our code, let’s build our project:

```bash
$ cargo build
    Updating registry `https://github.com/rust-lang/crates.io-index`
 Downloading rand v0.3.8
 Downloading libc v0.1.6
   Compiling libc v0.1.6
   Compiling rand v0.3.8
   Compiling guessing_game v0.1.0 (file:///home/you/projects/guessing_game)
```

(You may see different versions, of course.)

Lots of new output! Now that we have an external dependency, Cargo fetches the
latest versions of everything from the registry, which is a copy of data from
[Crates.io][cratesio]. Crates.io is where people in the Rust ecosystem
post their open source Rust projects for others to use.

[cratesio]: https://crates.io

After updating the registry, Cargo checks our `[dependencies]` and downloads
any we don’t have yet. In this case, while we only said we wanted to depend on
`rand`, we’ve also grabbed a copy of `libc`. This is because `rand` depends on
`libc` to work. After downloading them, it compiles them, and then compiles
our project.

If we run `cargo build` again, we’ll get different output:

```bash
$ cargo build
```

That’s right, no output! Cargo knows that our project has been built, and that
all of its dependencies are built, and so there’s no reason to do all that
stuff. With nothing to do, it simply exits. If we open up `src/main.rs` again,
make a trivial change, and then save it again, we’ll just see one line:

```bash
$ cargo build
   Compiling guessing_game v0.1.0 (file:///home/you/projects/guessing_game)
```

So, we told Cargo we wanted any `0.3.x` version of `rand`, and so it fetched the latest
version at the time this was written, `v0.3.8`. But what happens when next
week, version `v0.3.9` comes out, with an important bugfix? While getting
bugfixes is important, what if `0.3.9` contains a regression that breaks our
code?

The answer to this problem is the `Cargo.lock` file you’ll now find in your
project directory. When you build your project for the first time, Cargo
figures out all of the versions that fit your criteria, and then writes them
to the `Cargo.lock` file. When you build your project in the future, Cargo
will see that the `Cargo.lock` file exists, and then use that specific version
rather than do all the work of figuring out versions again. This lets you
have a repeatable build automatically. In other words, we’ll stay at `0.3.8`
until we explicitly upgrade, and so will anyone who we share our code with,
thanks to the lock file.

What about when we _do_ want to use `v0.3.9`? Cargo has another command,
`update`, which says ‘ignore the lock, figure out all the latest versions that
fit what we’ve specified. If that works, write those versions out to the lock
file’. But, by default, Cargo will only look for versions larger than `0.3.0`
and smaller than `0.4.0`. If we want to move to `0.4.x`, we’d have to update
the `Cargo.toml` directly. When we do, the next time we `cargo build`, Cargo
will update the index and re-evaluate our `rand` requirements.

There’s a lot more to say about [Cargo][doccargo] and [its
ecosystem][doccratesio], but for now, that’s all we need to know. Cargo makes
it really easy to re-use libraries, and so Rustaceans tend to write smaller
projects which are assembled out of a number of sub-packages.

[doccargo]: http://doc.crates.io
[doccratesio]: http://doc.crates.io/crates-io.html

Let’s get on to actually _using_ `rand`. Here’s our next step:

```rust,ignore
extern crate rand;

use std::io;
use rand::Rng;

fn main() {
    println!("Guess the number!");

    let secret_number = rand::thread_rng().gen_range(1, 101);

    println!("The secret number is: {}", secret_number);

    println!("Please input your guess.");

    let mut guess = String::new();

    io::stdin().read_line(&mut guess)
        .ok()
        .expect("failed to read line");

    println!("You guessed: {}", guess);
}
```

The first thing we’ve done is change the first line. It now says
`extern crate rand`. Because we declared `rand` in our `[dependencies]`, we
can use `extern crate` to let Rust know we’ll be making use of it. This also
does the equivalent of a `use rand;` as well, so we can make use of anything
in the `rand` crate by prefixing it with `rand::`.

Next, we added another `use` line: `use rand::Rng`. We’re going to use a
method in a moment, and it requires that `Rng` be in scope to work. The basic
idea is this: methods are defined on something called ‘traits’, and for the
method to work, it needs the trait to be in scope. For more about the
details, read the [traits][traits] section.

[traits]: traits.html

There are two other lines we added, in the middle:

```rust,ignore
    let secret_number = rand::thread_rng().gen_range(1, 101);

    println!("The secret number is: {}", secret_number);
```

We use the `rand::thread_rng()` function to get a copy of the random number
generator, which is local to the particular [thread][concurrency] of execution
we’re in. Because we `use rand::Rng`’d above, it has a `gen_range()` method
available. This method takes two arguments, and generates a number between
them. It’s inclusive on the lower bound, but exclusive on the upper bound,
so we need `1` and `101` to get a number between one and a hundred.

[concurrency]: concurrency.html

The second line just prints out the secret number. This is useful while
we’re developing our program, so we can easily test it out. But we’ll be
deleting it for the final version. It’s not much of a game if it prints out
the answer when you start it up!

Try running our new program a few times:

```bash
$ cargo run
   Compiling guessing_game v0.1.0 (file:///home/you/projects/guessing_game)
     Running `target/debug/guessing_game`
Guess the number!
The secret number is: 7
Please input your guess.
4
You guessed: 4
$ cargo run
     Running `target/debug/guessing_game`
Guess the number!
The secret number is: 83
Please input your guess.
5
You guessed: 5
```

Great! Next up: let’s compare our guess to the secret guess.

# Comparing guesses

Now that we’ve got user input, let’s compare our guess to the random guess.
Here’s our next step, though it doesn’t quite work yet:

```rust,ignore
extern crate rand;

use std::io;
use std::cmp::Ordering;
use rand::Rng;

fn main() {
    println!("Guess the number!");

    let secret_number = rand::thread_rng().gen_range(1, 101);

    println!("The secret number is: {}", secret_number);

    println!("Please input your guess.");

    let mut guess = String::new();

    io::stdin().read_line(&mut guess)
        .ok()
        .expect("failed to read line");

    println!("You guessed: {}", guess);

    match guess.cmp(&secret_number) {
        Ordering::Less    => println!("Too small!"),
        Ordering::Greater => println!("Too big!"),
        Ordering::Equal   => println!("You win!"),
    }
}
```

A few new bits here. The first is another `use`. We bring a type called
`std::cmp::Ordering` into scope. Then, five new lines at the bottom that use
it:

```rust,ignore
match guess.cmp(&secret_number) {
    Ordering::Less    => println!("Too small!"),
    Ordering::Greater => println!("Too big!"),
    Ordering::Equal   => println!("You win!"),
}
```

The `cmp()` method can be called on anything that can be compared, and it
takes a reference to the thing you want to compare it to. It returns the
`Ordering` type we `use`d earlier. We use a [`match`][match] statement to
determine exactly what kind of `Ordering` it is. `Ordering` is an
[`enum`][enum], short for ‘enumeration’, which looks like this:

```rust
enum Foo {
    Bar,
    Baz,
}
```

[match]: match.html
[enum]: enums.html

With this definition, anything of type `Foo` can be either a
`Foo::Bar` or a `Foo::Baz`. We use the `::` to indicate the
namespace for a particular `enum` variant.

The [`Ordering`][ordering] enum has three possible variants: `Less`, `Equal`,
and `Greater`. The `match` statement takes a value of a type, and lets you
create an ‘arm’ for each possible value. Since we have three types of
`Ordering`, we have three arms:

```rust,ignore
match guess.cmp(&secret_number) {
    Ordering::Less    => println!("Too small!"),
    Ordering::Greater => println!("Too big!"),
    Ordering::Equal   => println!("You win!"),
}
```

[ordering]: ../std/cmp/enum.Ordering.html

If it’s `Less`, we print `Too small!`, if it’s `Greater`, `Too big!`, and if
`Equal`, `You win!`. `match` is really useful, and is used often in Rust.

I did mention that this won’t quite work yet, though. Let’s try it:

```bash
$ cargo build
   Compiling guessing_game v0.1.0 (file:///home/you/projects/guessing_game)
src/main.rs:28:21: 28:35 error: mismatched types:
 expected `&collections::string::String`,
    found `&_`
(expected struct `collections::string::String`,
    found integral variable) [E0308]
src/main.rs:28     match guess.cmp(&secret_number) {
                                   ^~~~~~~~~~~~~~
error: aborting due to previous error
Could not compile `guessing_game`.
```

Whew! This is a big error. The core of it is that we have ‘mismatched types’.
Rust has a strong, static type system. However, it also has type inference.
When we wrote `let guess = String::new()`, Rust was able to infer that `guess`
should be a `String`, and so it doesn’t make us write out the type. And with
our `secret_number`, there are a number of types which can have a value
between one and a hundred: `i32`, a thirty-two-bit number, or `u32`, an
unsigned thirty-two-bit number, or `i64`, a sixty-four-bit number. Or others.
So far, that hasn’t mattered, and so Rust defaults to an `i32`. However, here,
Rust doesn’t know how to compare the `guess` and the `secret_number`. They
need to be the same type. Ultimately, we want to convert the `String` we
read as input into a real number type, for comparison. We can do that
with three more lines. Here’s our new program:

```rust,ignore
extern crate rand;

use std::io;
use std::cmp::Ordering;
use rand::Rng;

fn main() {
    println!("Guess the number!");

    let secret_number = rand::thread_rng().gen_range(1, 101);

    println!("The secret number is: {}", secret_number);

    println!("Please input your guess.");

    let mut guess = String::new();

    io::stdin().read_line(&mut guess)
        .ok()
        .expect("failed to read line");

    let guess: u32 = guess.trim().parse()
        .ok()
        .expect("Please type a number!");

    println!("You guessed: {}", guess);

    match guess.cmp(&secret_number) {
        Ordering::Less    => println!("Too small!"),
        Ordering::Greater => println!("Too big!"),
        Ordering::Equal   => println!("You win!"),
    }
}
```

The new three lines:

```rust,ignore
    let guess: u32 = guess.trim().parse()
        .ok()
        .expect("Please type a number!");
```

Wait a minute, I thought we already had a `guess`? We do, but Rust allows us
to ‘shadow’ the previous `guess` with a new one. This is often used in this
exact situation, where `guess` starts as a `String`, but we want to convert it
to an `u32`. Shadowing lets us re-use the `guess` name, rather than forcing us
to come up with two unique names like `guess_str` and `guess`, or something
else.

We bind `guess` to an expression that looks like something we wrote earlier:

```rust,ignore
guess.trim().parse()
```

Followed by an `ok().expect()` invocation. Here, `guess` refers to the old
`guess`, the one that was a `String` with our input in it. The `trim()`
method on `String`s will eliminate any white space at the beginning and end of
our string. This is important, as we had to press the ‘return’ key to satisfy
`read_line()`. This means that if we type `5` and hit return, `guess` looks
like this: `5\n`. The `\n` represents ‘newline’, the enter key. `trim()` gets
rid of this, leaving our string with just the `5`. The [`parse()` method on
strings][parse] parses a string into some kind of number. Since it can parse a
variety of numbers, we need to give Rust a hint as to the exact type of number
we want. Hence, `let guess: u32`. The colon (`:`) after `guess` tells Rust
we’re going to annotate its type. `u32` is an unsigned, thirty-two bit
integer. Rust has [a number of built-in number types][number], but we’ve
chosen `u32`. It’s a good default choice for a small positive numer.

[parse]: ../std/primitive.str.html#method.parse
[number]: primitive-types.html#numeric-types

Just like `read_line()`, our call to `parse()` could cause an error. What if
our string contained `A👍%`? There’d be no way to convert that to a number. As
such, we’ll do the same thing we did with `read_line()`: use the `ok()` and
`expect()` methods to crash if there’s an error.

Let’s try our program out!

```bash
$ cargo run
   Compiling guessing_game v0.0.1 (file:///home/you/projects/guessing_game)
     Running `target/guessing_game`
Guess the number!
The secret number is: 58
Please input your guess.
  76
You guessed: 76
Too big!
```

Nice! You can see I even added spaces before my guess, and it still figured
out that I guessed 76. Run the program a few times, and verify that guessing
the number works, as well as guessing a number too small.

Now we’ve got most of the game working, but we can only make one guess. Let’s
change that by adding loops!

# Looping

The `loop` keyword gives us an infinite loop. Let’s add that in:

```rust,ignore
extern crate rand;

use std::io;
use std::cmp::Ordering;
use rand::Rng;

fn main() {
    println!("Guess the number!");

    let secret_number = rand::thread_rng().gen_range(1, 101);

    println!("The secret number is: {}", secret_number);

    loop {
        println!("Please input your guess.");

        let mut guess = String::new();

        io::stdin().read_line(&mut guess)
            .ok()
            .expect("failed to read line");

        let guess: u32 = guess.trim().parse()
            .ok()
            .expect("Please type a number!");

        println!("You guessed: {}", guess);

        match guess.cmp(&secret_number) {
            Ordering::Less    => println!("Too small!"),
            Ordering::Greater => println!("Too big!"),
            Ordering::Equal   => println!("You win!"),
        }
    }
}
```

And try it out. But wait, didn’t we just add an infinite loop? Yup. Remember
our discussion about `parse()`? If we give a non-number answer, we’ll `return`
and quit. Observe:

```bash
$ cargo run
   Compiling guessing_game v0.0.1 (file:///home/you/projects/guessing_game)
     Running `target/guessing_game`
Guess the number!
The secret number is: 59
Please input your guess.
45
You guessed: 45
Too small!
Please input your guess.
60
You guessed: 60
Too big!
Please input your guess.
59
You guessed: 59
You win!
Please input your guess.
quit
thread '<main>' panicked at 'Please type a number!'
```

Ha! `quit` actually quits. As does any other non-number input. Well, this is
suboptimal to say the least. First, let’s actually quit when you win the game:

```rust,ignore
extern crate rand;

use std::io;
use std::cmp::Ordering;
use rand::Rng;

fn main() {
    println!("Guess the number!");

    let secret_number = rand::thread_rng().gen_range(1, 101);

    println!("The secret number is: {}", secret_number);

    loop {
        println!("Please input your guess.");

        let mut guess = String::new();

        io::stdin().read_line(&mut guess)
            .ok()
            .expect("failed to read line");

        let guess: u32 = guess.trim().parse()
            .ok()
            .expect("Please type a number!");

        println!("You guessed: {}", guess);

        match guess.cmp(&secret_number) {
            Ordering::Less    => println!("Too small!"),
            Ordering::Greater => println!("Too big!"),
            Ordering::Equal   => {
                println!("You win!");
                break;
            }
        }
    }
}
```

By adding the `break` line after the `You win!`, we’ll exit the loop when we
win. Exiting the loop also means exiting the program, since it’s the last
thing in `main()`. We have just one more tweak to make: when someone inputs a
non-number, we don’t want to quit, we just want to ignore it. We can do that
like this:

```rust,ignore
extern crate rand;

use std::io;
use std::cmp::Ordering;
use rand::Rng;

fn main() {
    println!("Guess the number!");

    let secret_number = rand::thread_rng().gen_range(1, 101);

    println!("The secret number is: {}", secret_number);

    loop {
        println!("Please input your guess.");

        let mut guess = String::new();

        io::stdin().read_line(&mut guess)
            .ok()
            .expect("failed to read line");

        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,
            Err(_) => continue,
        };

        println!("You guessed: {}", guess);

        match guess.cmp(&secret_number) {
            Ordering::Less    => println!("Too small!"),
            Ordering::Greater => println!("Too big!"),
            Ordering::Equal   => {
                println!("You win!");
                break;
            }
        }
    }
}
```

These are the lines that changed:

```rust,ignore
let guess: u32 = match guess.trim().parse() {
    Ok(num) => num,
    Err(_) => continue,
};
```

This is how you generally move from ‘crash on error’ to ‘actually handle the
error’, by switching from `ok().expect()` to a `match` statement. The `Result`
returned by `parse()` is an enum just like `Ordering`, but in this case, each
variant has some data associated with it: `Ok` is a success, and `Err` is a
failure. Each contains more information: the successful parsed integer, or an
error type. In this case, we `match` on `Ok(num)`, which sets the inner value
of the `Ok` to the name `num`, and then we just return it on the right-hand
side. In the `Err` case, we don’t care what kind of error it is, so we just
use `_` intead of a name. This ignores the error, and `continue` causes us
to go to the next iteration of the `loop`.

Now we should be good! Let’s try:

```bash
$ cargo run
   Compiling guessing_game v0.0.1 (file:///home/you/projects/guessing_game)
     Running `target/guessing_game`
Guess the number!
The secret number is: 61
Please input your guess.
10
You guessed: 10
Too small!
Please input your guess.
99
You guessed: 99
Too big!
Please input your guess.
foo
Please input your guess.
61
You guessed: 61
You win!
```

Awesome! With one tiny last tweak, we have finished the guessing game. Can you
think of what it is? That’s right, we don’t want to print out the secret
number. It was good for testing, but it kind of ruins the game. Here’s our
final source:

```rust,ignore
extern crate rand;

use std::io;
use std::cmp::Ordering;
use rand::Rng;

fn main() {
    println!("Guess the number!");

    let secret_number = rand::thread_rng().gen_range(1, 101);

    loop {
        println!("Please input your guess.");

        let mut guess = String::new();

        io::stdin().read_line(&mut guess)
            .ok()
            .expect("failed to read line");

        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,
            Err(_) => continue,
        };

        println!("You guessed: {}", guess);

        match guess.cmp(&secret_number) {
            Ordering::Less    => println!("Too small!"),
            Ordering::Greater => println!("Too big!"),
            Ordering::Equal   => {
                println!("You win!");
                break;
            }
        }
    }
}
```

# Complete!

At this point, you have successfully built the Guessing Game! Congratulations!

This first project showed you a lot: `let`, `match`, methods, associated
functions, using external crates, and more. Our next project will show off
even more.
