% Макросы

К этому моменту вы узнали о многих инструментах Rust, которые нацелены на
абстрагирование и повторное использование кода. Эти единицы повторно
использованного кода имеют богатую смысловую структуру. Например, функции имеют
сигнатуры типа, типы параметров могут имеют ограничения по трейтам,
перегруженные функции также могут принадлежать к определенному трейту.

Эта структура означает, что ключевые абстракции Rust имеют мощный механизм
проверки времени компиляции. Но это достигается за счет снижения гибкости. Если
вы визуально определите структуру повторно используемого кода, то вы можете
найти трудным или громоздким выражение этой схемы в виде дженерик функции,
трейта, или чего-то еще в семантике Rust.

Макросы позволяют абстрагироваться на *синтаксическом* уровне. Вызов макроса
является сокращением для "расширенной" синтаксической формы. Это расширение
происходит в начале компиляции, до начала статической проверки. В результате,
макросы могут охватить много шаблонов повторного использования кода, которые
невозможны при использовании лишь ключевых абстракций Rust.

Недостатком является то, что код, основанный на макросах, может быть трудным для
понимания, потому что к нему применяется меньше встроенных правил. Подобно
обычной функции, качественный макрос может быть использован без понимания его
реализации. Тем не менее, может быть трудно разработать качественный макрос!
Кроме того, ошибки компилятора в макро коде сложнее интерпретировать, потому что
они описывают проблемы в расширенной форме кода, а не в исходной сокращенной
форме кода, которую используют разработчики.

Эти недостатки делают макросы чем-то вроде "фичи последней инстанции". Это не
означает, что макросы это плохо; они являются частью Rust, потому что иногда они
все же нужны для по-настоящему краткой записи хорошо абстрагированной части
кода. Просто имейте этот компромисс в виду.

# Определение макросов (Макроопределения)

Вы, возможно, видели макрос `vec!`, который используется для инициализации
[вектора][vector] с произвольным количеством элементов.

[vector]: vectors.html

```rust
let x: Vec<u32> = vec![1, 2, 3];
# assert_eq!(x, [1, 2, 3]);
```

Его нельзя реализовать в виде обычной функциии, так как он принимает любое
количество аргументов. Но мы можем представить его в виде синтаксического
сокращения для следующего кода

```rust
let x: Vec<u32> = {
    let mut temp_vec = Vec::new();
    temp_vec.push(1);
    temp_vec.push(2);
    temp_vec.push(3);
    temp_vec
};
# assert_eq!(x, [1, 2, 3]);
```

Мы можем реализовать это сокращение, используя макрос: [^actual]

[^actual]: Фактическое определение `vec!` в libcollections отличается от
представленной здесь по соображениям эффективности и повторного использования.
Некоторые из них упомянуты в главе [продвинутые макросы][advanced macros
chapter].

```rust
macro_rules! vec {
    ( $( $x:expr ),* ) => {
        {
            let mut temp_vec = Vec::new();
            $(
                temp_vec.push($x);
            )*
            temp_vec
        }
    };
}
# fn main() {
#     assert_eq!(vec![1,2,3], [1, 2, 3]);
# }
```

Вау, тут много нового синтаксиса! Давайте разберем его.

```ignore
macro_rules! vec { ... }
```

Тут мы определяем макрос с именем `vec`, аналогично тому, как `fn vec`
определяло бы функцию с именем `vec`. При вызове мы неформально пишем имя
макроса с восклицательным знаком, например, `vec!`. Восклицательный знак
является частью синтаксиса вызова и служит для того, чтобы отличать макрос от
обычной функции.

## Сопоставление (Matching) (Синтаксис вызова макрокоманды)

Макрос определяется с помощью ряда *правил*, которые представляют собой варианты
сопоставления с образцом. Выше у нас было

```ignore
( $( $x:expr ),* ) => { ... };
```

Это очень похоже на конструкцию `match`, но сопоставление происходит на уровне
синтаксических деревьев Rust, на этапе компиляции. Точка с запятой не является
обязательной для последнего (только здесь) варианта. "Образец" слева от `=>`
известен как *шаблон совпадений* (*образец*) (*обнаружитель совпадений*)
(*matcher*). Он имеет [свою собственную грамматику][their own little grammar] в
рамках языка.

[their own little grammar]: https://doc.rust-lang.org/stable/reference.html#macros

Образец `$x:expr` будет соответствовать любому выражению Rust, связывая его
дерево синтаксиса с *метапеременной* `$x`. Идентификатор `expr` является
*спецификатором фрагмента*; полные возможности перечислены в главе [продвинутые
макросы][advanced macros chapter]. Образец, окруженный `$(...),*`, будет
соответствовать нулю или более выражениям, разделенным запятыми.

За исключением специального синтаксиса сопоставления с образцом, любые другие
элементы Rust, которые появляются в образце, должны в точности совпадать.
Например,

```rust
macro_rules! foo {
    (x => $e:expr) => (println!("mode X: {}", $e));
    (y => $e:expr) => (println!("mode Y: {}", $e));
}

fn main() {
    foo!(y => 3);
}
```

выведет

```text
mode Y: 3
```

А с

```rust,ignore
foo!(z => 3);
```

мы получим ошибку компиляции

```text
error: no rules expected the token `z`
```

## Развертывание (Expansion) (Синтаксис преобразования макрокоманды)

С правой стороны макро правил используется, по большей части, обычный синтаксис
Rust. Но мы можем соединить кусочки раздробленного синтаксиса, захваченные при
сопоставлении с соответствующим образцом. Из предыдущего примера:

```ignore
$(
    temp_vec.push($x);
)*
```

Каждое соответствующее выражение `$x` будет генерировать одиночный оператор
`push` в развернутой форме макроса. Повторение в развернутой форме происходит
синхронно с повторением в форме образца (более подробно об этом чуть позже).

Поскольку `$x` уже объявлен в образце как выражение, мы не повторяем `:expr` с
правой стороны. Кроме того, мы не включаем разделителяющую запятую в качестве
части оператора повторения. Вместо этого, у нас есть точка с запятой в пределах
повторяемого блока.

Еще одна деталь: макрос `vec!` имеет *две* пары фигурных скобках правой части.
Они часто сочетаются таким образом:

```ignore
macro_rules! foo {
    () => {{
        ...
    }}
}
```

Внешние скобки являются частью синтаксиса `macro_rules!`. На самом деле, вы
можете использовать `()` или `[]` вместо них. Они просто разграничивают правую
часть в целом.

Внутренние скобки являются частью расширенного синтаксиса. Помните, что макрос
`vec!` используется в контексте выражения. Мы используем блок, для записи
выражения с множественными операторами, в том числе включающее `let` привязки.
Если ваш макрос раскрывается в одно единственное выражение, то дополнительной
слой скобок не нужен.

Note that we never *declared* that the macro produces an expression. In fact,
this is not determined until we use the macro as an expression. With care, you
can write a macro whose expansion works in several contexts. For example,
shorthand for a data type could be valid as either an expression or a pattern.

Обратите внимание, что мы никогда не *говорили*, что макрос создает выражения.
На самом деле, это не определяется, пока мы не используем макрос в качестве
выражения. Если соблюдать осторожность, то можно написать макрос, развернутая
форма которого будет валидна сразу в нескольких контекстах. Например,
сокращенная форма для типа данных может быть валидной и как выражение, и как
шаблон.

## Повторение (Repetition) (Многовариантность)

Операции повтора всегда сопутствуют два основных правила:

1. `$(...)*` walks through one "layer" of repetitions, for all of the `$name`s
   it contains, in lockstep, and
2. each `$name` must be under at least as many `$(...)*`s as it was matched
   against. If it is under more, it'll be duplicated, as appropriate.
1. `$(...)*` проходит через один "слой" повторений, для всех `$name`, которые он содержит, в ногу, и
2. каждое `$name` должно быть под крайней мере, столько `$(...)*`, как это было сопоставляется. Если это в более, это будет дублироваться, при необходимости.

This baroque macro illustrates the duplication of variables from outer
repetition levels.

Этот причудливый макрос иллюстрирует дублирования переменных из внешних уровней
повторения.

```rust
macro_rules! o_O {
    (
        $(
            $x:expr; [ $( $y:expr ),* ]
        );*
    ) => {
        &[ $($( $x + $y ),*),* ]
    }
}

fn main() {
    let a: &[i32]
        = o_O!(10; [1, 2, 3];
               20; [4, 5, 6]);

    assert_eq!(a, [11, 12, 13, 24, 25, 26]);
}
```

Это наибольшая синтаксиса совпадений. Эти примеры используют конструкцию
`$(...)*`, которая означает "ноль или более" совпадений. Также вы можете
написать `$(...)+`, что будет означать "одно или более" совпадений. Обе формы
записи включают необязательный разделитель, располагающийся сразу за закрывающей
скобкой, который может быть любым символом, за исключением `+` или `*`.

Эта система повторений основана на "[Macro-by-
Example](http://www.cs.indiana.edu/ftp/techreports/TR206.pdf)" (PDF ссылка).

# Гигиена (Hygiene)

Некоторые языки реализуют макросы с помощью простой текстовой замены, что
приводит к различным проблемам. Например, нижеприведенная C программа напечатает
`13` вместо ожидаемого `25`.

```text
#define FIVE_TIMES(x) 5 * x

int main() {
    printf("%d\n", FIVE_TIMES(2 + 3));
    return 0;
}
```

После развертывания мы получаем `5 * 2 + 3`, но умножение имеет больший
приоритет чем сложение. Если вы часто использовали C макросы, вы, наверное,
знаете стандартные идиомы для устранения этой проблемы, а также пять или шесть
других проблем. В Rust мы можем не беспокоиться об этом.

```rust
macro_rules! five_times {
    ($x:expr) => (5 * $x);
}

fn main() {
    assert_eq!(25, five_times!(2 + 3));
}
```

Метапеременная `$x` обрабатывается как единый узел выражения, и сохраняет свое
место в дереве синтаксиса даже после замены.

Другой распространенной проблемой в системе макросов является *захват
переменной* (*variable capture*). Вот C макрос, использующий [GNU C расширение][a GNU C extension],
который эмулирует блоки выражениий в Rust.

[a GNU C extension]: https://gcc.gnu.org/onlinedocs/gcc/Statement-Exprs.html

```text
#define LOG(msg) ({ \
    int state = get_log_state(); \
    if (state > 0) { \
        printf("log(%d): %s\n", state, msg); \
    } \
})
```

Вот простой случай использования, применение которого может плохо кончиться:

```text
const char *state = "reticulating splines";
LOG(state)
```

Он раскрывается в

```text
const char *state = "reticulating splines";
int state = get_log_state();
if (state > 0) {
    printf("log(%d): %s\n", state, state);
}
```

Вторая переменная с именем `state` затеняет первую. Это проблема, потому что
команде печати требуется обращаться к ним обоим.

Эквивалентный макрос в Rust обладает требуемым поведением.

```rust
# fn get_log_state() -> i32 { 3 }
macro_rules! log {
    ($msg:expr) => {{
        let state: i32 = get_log_state();
        if state > 0 {
            println!("log({}): {}", state, $msg);
        }
    }};
}

fn main() {
    let state: &str = "reticulating splines";
    log!(state);
}
```

Это работает, потому что Rust имеет [систему макросов с соблюдением
гигиены][hygienic macro system]. Раскрытие каждого макроса происходит в
отдельном *контексте синтаксиса*, и каждая переменная обладает меткой контекста
синтаксиса, где она была введена. Это как если бы переменная `state` внутри
`main` была бы окрашена в другой "цвет" в отличае от переменной `state` внутри
макроса, из-за чего они бы не конфликтовали.

[hygienic macro system]: http://en.wikipedia.org/wiki/Hygienic_macro

Это также ограничивает возможности макросов для внедрения новых связываний
переменных на месте вызова. Код, приведенный ниже, не будет работать:

```rust,ignore
macro_rules! foo {
    () => (let x = 3);
}

fn main() {
    foo!();
    println!("{}", x);
}
```

Вместо этого вы должны передавать имя переменной при вызове, тогда она будет
обладать меткой правильного контекста синтаксиса.

```rust
macro_rules! foo {
    ($v:ident) => (let $v = 3);
}

fn main() {
    foo!(x);
    println!("{}", x);
}
```

Это справедливо для `let` привязок и меток loop, но не для [элементов][items].
Код, приведенный ниже, компилируется:

```rust
macro_rules! foo {
    () => (fn x() { });
}

fn main() {
    foo!();
    x();
}
```

[items]: https://doc.rust-lang.org/stable/reference.html#items

# Рекурсия макросов

Раскрытие макроса также может включать в себя вызовы макросов, в том числе
вызовы того макроса, который раскрывается. Эти рекурсивные макросы могут быть
использованы для обработки древовидного ввода, как показано на этом (упрощенном)
HTML сокращение:

```rust
# #![allow(unused_must_use)]
macro_rules! write_html {
    ($w:expr, ) => (());

    ($w:expr, $e:tt) => (write!($w, "{}", $e));

    ($w:expr, $tag:ident [ $($inner:tt)* ] $($rest:tt)*) => {{
        write!($w, "<{}>", stringify!($tag));
        write_html!($w, $($inner)*);
        write!($w, "</{}>", stringify!($tag));
        write_html!($w, $($rest)*);
    }};
}

fn main() {
#   // FIXME(#21826)
    use std::fmt::Write;
    let mut out = String::new();

    write_html!(&mut out,
        html[
            head[title["Macros guide"]]
            body[h1["Macros are the best!"]]
        ]);

    assert_eq!(out,
        "<html><head><title>Macros guide</title></head>\
         <body><h1>Macros are the best!</h1></body></html>");
}
```

# Отладка макросов

Чтобы увидеть результаты расширения макросов, выполните команду `rustc --pretty
expanded`. Вывод представляет собой целый контейнер, так что вы можете подать
его обратно в `rustc`, что иногда выдает лучшие сообщения об ошибках, чем при
обычной компиляции. Обратите внимание, что вывод `--pretty expanded` может иметь
разное значение, если несколько переменных, имеющих одно и то же имя (но разные
контексты синтаксиса), находятся в той же области видимости. В этом случае
`--pretty expanded,hygiene` расскажет вам о контекстах синтаксиса.

`rustc`, поддерживает два синтаксических расширения, которые помогают с отладкой
макросов. В настоящее время, они неустойчивы и требуют feature gates.

* `log_syntax!(...)` будет печатать свои аргументы в стандартный вывод во время
  компиляции, и "развертываться" в ничто.

* `trace_macros!(true)` будет выдавать сообщение компилятора каждый раз, когда
  макрос развертывается. Используйте `trace_macros!(false)` в конце развертывания,
  чтобы выключить его.

# Требования синтаксиса

Код на Rust может быть разобран в [синтаксическое дерево][ast], даже когда он
содержит неразвёрнутые макросы. Это свойство очень полезно для редакторов и
других инструментов, обрабатывающих исходный код. Оно также влияет на вид
системы макросов Rust.

<!-- #abstract-syntax-tree -->
[ast]: glossary.html#%D0%90%D0%B1%D1%81%D1%82%D1%80%D0%B0%D0%BA%D1%82%D0%BD%D0%BE%D0%B5-%D1%81%D0%B8%D0%BD%D1%82%D0%B0%D0%BA%D1%81%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%BE%D0%B5-%D0%B4%D0%B5%D1%80%D0%B5%D0%B2%D0%BE-%28%D0%94%D0%B5%D1%80%D0%B5%D0%B2%D0%BE-%D0%B0%D0%B1%D1%81%D1%82%D1%80%D0%B0%D0%BA%D1%82%D0%BD%D0%BE%D0%B3%D0%BE-%D1%81%D0%B8%D0%BD%D1%82%D0%B0%D0%BA%D1%81%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%BE%D0%B3%D0%BE-%D0%B0%D0%BD%D0%B0%D0%BB%D0%B8%D0%B7%D0%B0%29

Как следствие, когда компилятор разбирает вызов макроса, ему необходимо знать,
во что развернётся данный макрос. Макрос может разворачиваться в следующее:

* ноль или больше элементов;
* ноль или больше методов;
* выражение;
* оператор;
* образец.

Вызов макроса в блоке может представлять собой элементы, выражение, или
оператор. Rust использует простое правило для разрешения этой
неоднозначности. Вызов макроса, производящего элементы, должен либо

* ограничиваться фигурными скобками, т.е. `foo! { ... }`;
* завершаться точкой с запятой, т.е. `foo!(...);`.

Другое следствие разбора перед раскрытием макросов - это то, что вызов макроса
должен состоять из допустимых лексем. Более того, скобки всех видов должны быть
сбалансированы в месте вызова. Например, `foo!([)` не является разрешённым
кодом. Такое поведение позволяет компилятору понимать где заканчивается вызов
макроса.

Говоря более формально, тело вызова макроса должно представлять собой
последовательность *деревьев лексем*. Дерево лексем определяется рекурсивно и
представляет собой либо:

* последовательность деревьев лексем, окружённую согласованными круглыми,
  квадратными или фигурными скобками (`()`, `[]`, `{}`);
* любую другую одиночную лексему.

Внутри сопоставления каждая метапеременная имеет *указатель фрагмента*,
определяющий синтаксическую форму, с которой она совпадает. Вот список этих
указателей:

* `ident`: идентификатор. Например: `x`; `foo`.
* `path`: квалифицированное имя. Например: `T::SpecialA`.
* `expr`: выражение. Например: `2 + 2`; `if true then { 1 } else { 2 }`;
  `f(42)`.
* `ty`: тип. Например: `i32`; `Vec<(char, String)>`; `&T`.
* `pat`: образец. Например: `Some(t)`; `(17, 'a')`; `_`.
* `stmt`: единственный оператор. Например: `let x = 3`.
* `block`: последовательность операторов, ограниченная фигурными
  скобками. Например: `{ log(error, "hi"); return 12; }`.
* `item`: [элемент][item]. Например: `fn foo() { }`; `struct Bar;`.
* `meta`: "мета-элемент", как в атрибутах. Например: `cfg(target_os =
  "windows")`.
* `tt`: единственное дерево лексем.

Есть дополнительные правила относительно лексем, следующих за метапеременной:

* за `expr` должно быть что-то из этого: `=> , ;`;
* за `ty` и `path` должно быть что-то из этого: `=> , : = > as`;
* за `pat` должно быть что-то из этого : `=> , =`;
* за другими лексемами могут следовать любые символы.

Приведённые правила обеспечивают развитие синтаксиса Rust без необходимости
менять существующие макросы.

И ещё: система макросов никак не обрабатывет неоднозначность разбора. Например,
грамматика `$($t:ty)* $e:expr` всегда будет выдавать ошибку, потому что
синтаксическому анализатору пришлось бы выбирать между разбором `$t` и разбором
`$e`. Можно изменить синтаксис вызова так, чтобы грамматика отличалась в начале.
В данном случае можно написать `$(T $t:ty)* E $e:exp`.

[item]: http://doc.rust-lang.org/stable/reference.html#items

# Scoping and macro import/export

Macros are expanded at an early stage in compilation, before name resolution.
One downside is that scoping works differently for macros, compared to other
constructs in the language.

Definition and expansion of macros both happen in a single depth-first,
lexical-order traversal of a crate's source. So a macro defined at module scope
is visible to any subsequent code in the same module, which includes the body
of any subsequent child `mod` items.

A macro defined within the body of a single `fn`, or anywhere else not at
module scope, is visible only within that item.

If a module has the `macro_use` attribute, its macros are also visible in its
parent module after the child's `mod` item. If the parent also has `macro_use`
then the macros will be visible in the grandparent after the parent's `mod`
item, and so forth.

The `macro_use` attribute can also appear on `extern crate`. In this context
it controls which macros are loaded from the external crate, e.g.

```rust,ignore
#[macro_use(foo, bar)]
extern crate baz;
```

If the attribute is given simply as `#[macro_use]`, all macros are loaded. If
there is no `#[macro_use]` attribute then no macros are loaded. Only macros
defined with the `#[macro_export]` attribute may be loaded.

To load a crate's macros *without* linking it into the output, use `#[no_link]`
as well.

An example:

```rust
macro_rules! m1 { () => (()) }

// visible here: m1

mod foo {
    // visible here: m1

    #[macro_export]
    macro_rules! m2 { () => (()) }

    // visible here: m1, m2
}

// visible here: m1

macro_rules! m3 { () => (()) }

// visible here: m1, m3

#[macro_use]
mod bar {
    // visible here: m1, m3

    macro_rules! m4 { () => (()) }

    // visible here: m1, m3, m4
}

// visible here: m1, m3, m4
# fn main() { }
```

When this library is loaded with `#[macro_use] extern crate`, only `m2` will
be imported.

The Rust Reference has a [listing of macro-related
attributes](https://doc.rust-lang.org/stable/reference.html#macro--and-plugin-related-attributes).

# The variable `$crate`

A further difficulty occurs when a macro is used in multiple crates. Say that
`mylib` defines

```rust
pub fn increment(x: u32) -> u32 {
    x + 1
}

#[macro_export]
macro_rules! inc_a {
    ($x:expr) => ( ::increment($x) )
}

#[macro_export]
macro_rules! inc_b {
    ($x:expr) => ( ::mylib::increment($x) )
}
# fn main() { }
```

`inc_a` only works within `mylib`, while `inc_b` only works outside the
library. Furthermore, `inc_b` will break if the user imports `mylib` under
another name.

Rust does not (yet) have a hygiene system for crate references, but it does
provide a simple workaround for this problem. Within a macro imported from a
crate named `foo`, the special macro variable `$crate` will expand to `::foo`.
By contrast, when a macro is defined and then used in the same crate, `$crate`
will expand to nothing. This means we can write

```rust
#[macro_export]
macro_rules! inc {
    ($x:expr) => ( $crate::increment($x) )
}
# fn main() { }
```

to define a single macro that works both inside and outside our library. The
function name will expand to either `::increment` or `::mylib::increment`.

To keep this system simple and correct, `#[macro_use] extern crate ...` may
only appear at the root of your crate, not inside `mod`. This ensures that
`$crate` is a single identifier.

# The deep end

The introductory chapter mentioned recursive macros, but it did not give the
full story. Recursive macros are useful for another reason: Each recursive
invocation gives you another opportunity to pattern-match the macro's
arguments.

As an extreme example, it is possible, though hardly advisable, to implement
the [Bitwise Cyclic Tag](http://esolangs.org/wiki/Bitwise_Cyclic_Tag) automaton
within Rust's macro system.

```rust
macro_rules! bct {
    // cmd 0:  d ... => ...
    (0, $($ps:tt),* ; $_d:tt)
        => (bct!($($ps),*, 0 ; ));
    (0, $($ps:tt),* ; $_d:tt, $($ds:tt),*)
        => (bct!($($ps),*, 0 ; $($ds),*));

    // cmd 1p:  1 ... => 1 ... p
    (1, $p:tt, $($ps:tt),* ; 1)
        => (bct!($($ps),*, 1, $p ; 1, $p));
    (1, $p:tt, $($ps:tt),* ; 1, $($ds:tt),*)
        => (bct!($($ps),*, 1, $p ; 1, $($ds),*, $p));

    // cmd 1p:  0 ... => 0 ...
    (1, $p:tt, $($ps:tt),* ; $($ds:tt),*)
        => (bct!($($ps),*, 1, $p ; $($ds),*));

    // halt on empty data string
    ( $($ps:tt),* ; )
        => (());
}
```

Exercise: use macros to reduce duplication in the above definition of the
`bct!` macro.

# Procedural macros

If Rust's macro system can't do what you need, you may want to write a
[compiler plugin](plugins.html) instead. Compared to `macro_rules!`
macros, this is significantly more work, the interfaces are much less stable,
and bugs can be much harder to track down. In exchange you get the
flexibility of running arbitrary Rust code within the compiler. Syntax
extension plugins are sometimes called *procedural macros* for this reason.
