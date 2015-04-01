% Указатели

Rust уникален в своей реализации указателей. В то же время, эта черта языка -
одна из наиболее непонятных для новичков. И даже люди, имеющие опыт с
указателями в других языках, могут смутиться. Эта глава поможет вам разобраться
с этой важной темой.

Не-ссылочные указатели в Rust надо использовать с умом - не применяйте их
"просто, чтобы программа скомпилировалась". Каждый вид указателей имеет
определённую область применения. По умолчанию, используйте обычные ссылки.

[Страница подсказок](#cheat-sheet) с обзором типов, имён и назначений различных
указателей также может быть вам интересна.

# Введение

Короткое введение для тех, кто не знаком с понятием "указатель".  Это
основополагающая сущность в языках системного программирования.  Убедитесь в
том, что вы понимаете данную тему.

## Основы указателей

Когда вы создаёте новое имя с помощью оператора `let`, вы называете значение,
находящееся в определённом месте на стеке. (Если вы не знакомы с понятиями
*стек* и *куча*, рассмотрите
[данный вопрос на Stack Overflow](http://stackoverflow.com/questions/79923/what-and-where-are-the-stack-and-heap).
Текст далее подразумевает, что вы понимаете разницу.)

Вот о чём мы говорим:

```{rust}
let x = 5;
let y = 8;
```

| адрес    | значение |
|----------|----------|
| 0xd3e030 | 5        |
| 0xd3e028 | 8        |

Адреса в памяти в данном случае придуманы. Это просто значения для примера. Суть
в том, что имя `x` соответствует адресу `0xd3e030`, и значение, хранящееся по
этому адресу - это `5`. Когда мы обращаемся к `x`, мы получаем соответствующее
значение. Таким образом, `x` - это `5`.

Давайте введём указатель. В некоторых языках только один тип указателей, но в
Rust их несколько. В данном случае мы используем *ссылку*. Это простейший вид
указателей:

```{rust}
let x = 5;
let y = 8;
let z = &y;
```

|адрес    | значение |
|-------- |----------|
|0xd3e030 | 5        |
|0xd3e028 | 8        |
|0xd3e020 | 0xd3e028 |

Видите разницу? Значение указателя - это адрес в памяти. В данном случае, это
адрес `y`. `x` и `y` имеют тип `i32`, а вот `z` - `&i32`.  Мы можем распечатать
адрес с помощью форматной строки `{:p}`:

```{rust}
let x = 5;
let y = 8;
let z = &y;

println!("{:p}", z);
```

С нашими придуманными адресами, этот код напечатал бы `0xd3e028`.

Поскольку `i32` и `&i32` - разные типы, мы не можем складывать их:

```{rust,ignore}
let x = 5;
let y = 8;
let z = &y;

println!("{}", x + z);
```

Такой код выдаёт ошибку:

```text
hello.rs:6:24: 6:25 error: mismatched types: expected `_`, found `&_` (expected integral variable, found &-ptr)
hello.rs:6     println!("{}", x + z);
                                  ^
```

Мы можем *разыменовать* указатель с помощью операции `*`. Разыменовать
указатель - значит получить значение, хранящееся по данному адресу в памяти. Вот
пример рабочего кода:

```{rust}
let x = 5;
let y = 8;
let z = &y;

println!("{}", x + *z);
```

Он напечатает `13`.

Вот и всё! Указатели просто указывают на некоторое место в памяти. Ничего
особенного. Теперь, когда мы узнали, *что* такое указатели, обсудим, *зачем* они
нужны.

## Использование указателей

Указатели в Rust используются по-другому, нежели в других языках системного
программирования. Позже мы поговорим о лучших способах их применения в Rust, а
пока рассмотрим указатели в других языках.

В C, строки - это указатели на список `char`ов, закачивающийся нулевым
байтом. Только поняв указатели, вы сможете пользоваться строками.

Указатели используют для указания на места в памяти, которые не находятся на
стеке. Наш предыдущий пример использовал две стековые переменные, и мы могли
дать им имя. В C, функция `malloc` выделяет память в куче, и она возвращает
указатель.

Как обобщение предыдущих двух случаев, указатели используют когда нужно хранить
некие структуры переменного размера. Размер памяти, необходимый для хранения
таких структур, нельзя определить во время компиляции. Поэтому память выделяют
динамически, и сохраняют указатель на эту память.

Указатели полезны в языках, в которых используется передача аргументов функциям
по значению. По сути, языки следуют одной из двух моделей (пример дальше - на
выдуманном языке, не Rust):

```text
func foo(x) {
    x = 5
}

func main() {
    i = 1
    foo(i)
    // каково значение i здесь?
}
```

В языках с передачей аргументов по значению `foo` получит свою копию `i`, так
что исходная версия переменной не поменяется. В конце программы `i` всё равно
будет равно `1`. А в языках, использующих передачу по ссылке, `foo` получит
ссылку на `i` и сможет изменять её значение. В конце программы `i` будет `5`.

Так как всё это связано с указателями? Поскольку указатели указывают на место в
памяти...

```text
func foo(&i32 x) {
    *x = 5
}

func main() {
    i = 1
    foo(&i)
    // каково значение i здесь?
}
```

Даже в языке, использующем передачу по значению, `i` будет равно `5` в конце.
Аргумент функции `x` - это указатель, и хотя `foo` получит свою копию аргумента,
это всё равно будет указатель на то же место в памяти! Поэтому мы сможем
изменить исходную переменную. Это называется *передачей ссылки по значению*.
Хитро!

## Проблемы использования указателей

Мы поговорили о том, какие указатели классные. Но в чём же их недостатки?
Давайте рассмотрим проблемы, возникающие при использовании указателей в других
языках, и обсудим, как Rust решает их.

Неинициализированные указатели могут вызвать проблемы. К примеру, что сделает
эта программа?

```{ignore}
&int x;
*x = 5; // ой!
```

Никто не знает. Мы объявляем указатель, который не указывает ни на один объект.
Затем мы разыменовываем указатель и присваиваем этому месту в памяти значение
`5`. Но что это за место в памяти? Неизвестно. Возможно, этот код выполнится без
особых последствий, а возможно, случится катастрофа.

Когда вы работаете с указателями в функциях, легко случайно испортить память,
на которую указывает указатель. Например:

```text
func make_pointer(): &int {
    x = 5;

    return &x;
}

func main() {
    &int i = make_pointer();
    *i = 5; // ох!
}
```

`x` - это локальная переменная в функции `make_pointer`, и её значение
неопределено после выхода из функции. Но мы возвращаем указатель на это место
в памяти и пытаемся присвоить ему значение в `main`! Это похоже на предыдущий
пример. Присваивание значений по неверным адресам до добра не доведёт!

Ещё одна большая проблема указателей - это *совпадение* указателей. Два
указателя совпадают, если они указывают на одно и то же место в памяти. Вот так:

```text
func mutate(&int i, int j) {
    *i = j;
}

func main() {
  x = 5;
  y = &x;
  z = &x; //y and z are aliased


  run_in_new_thread(mutate, y, 1);
  run_in_new_thread(mutate, z, 100);

  // каково значение x здесь?
}
```

В этом придуманном примере, `run_in_new_thread` запускает вычисляет функцию в
новом потоке. Поскольку у нас два потока, и они работают с совпадающими
указателями, они будут пытаться изменить одно и то же место в памяти. Поэтому
значение `x` в конце программы не детерминировано. К тому же, один из потоков
мог испортить память, на которую указывал аргумент. Мы снова попытались бы
записать значение в неправильное место в памяти.

## Conclusion

That's a basic overview of pointers as a general concept. As we alluded to
before, Rust has different kinds of pointers, rather than just one, and
mitigates all of the problems that we talked about, too. This does mean that
Rust pointers are slightly more complicated than in other languages, but
it's worth it to not have the problems that simple pointers have.

# References

The most basic type of pointer that Rust has is called a *reference*. Rust
references look like this:

```{rust}
let x = 5;
let y = &x;

println!("{}", *y);
println!("{:p}", y);
println!("{}", y);
```

We'd say "`y` is a reference to `x`." The first `println!` prints out the
value of `y`'s referent by using the dereference operator, `*`. The second
one prints out the memory location that `y` points to, by using the pointer
format string. The third `println!` *also* prints out the value of `y`'s
referent, because `println!` will automatically dereference it for us.

Here's a function that takes a reference:

```{rust}
fn succ(x: &i32) -> i32 { *x + 1 }
```

You can also use `&` as an operator to create a reference, so we can
call this function in two different ways:

```{rust}
fn succ(x: &i32) -> i32 { *x + 1 }

fn main() {

    let x = 5;
    let y = &x;

    println!("{}", succ(y));
    println!("{}", succ(&x));
}
```

Both of these `println!`s will print out `6`.

Of course, if this were real code, we wouldn't bother with the reference, and
just write:

```{rust}
fn succ(x: i32) -> i32 { x + 1 }
```

References are immutable by default:

```{rust,ignore}
let x = 5;
let y = &x;

*y = 5; // error: cannot assign to immutable borrowed content `*y`
```

They can be made mutable with `mut`, but only if its referent is also mutable.
This works:

```{rust}
let mut x = 5;
let y = &mut x;
```

This does not:

```{rust,ignore}
let x = 5;
let y = &mut x; // error: cannot borrow immutable local variable `x` as mutable
```

Immutable pointers are allowed to alias:

```{rust}
let x = 5;
let y = &x;
let z = &x;
```

Mutable ones, however, are not:

```{rust,ignore}
let mut x = 5;
let y = &mut x;
let z = &mut x; // error: cannot borrow `x` as mutable more than once at a time
```

Despite their complete safety, a reference's representation at runtime is the
same as that of an ordinary pointer in a C program. They introduce zero
overhead. The compiler does all safety checks at compile time. The theory that
allows for this was originally called *region pointers*. Region pointers
evolved into what we know today as *lifetimes*.

Here's the simple explanation: would you expect this code to compile?

```{rust,ignore}
fn main() {
    println!("{}", x);
    let x = 5;
}
```

Probably not. That's because you know that the name `x` is valid from where
it's declared to when it goes out of scope. In this case, that's the end of
the `main` function. So you know this code will cause an error. We call this
duration a *lifetime*. Let's try a more complex example:

```{rust}
fn main() {
    let mut x = 5;

    if x < 10 {
        let y = &x;

        println!("Oh no: {}", y);
        return;
    }

    x -= 1;

    println!("Oh no: {}", x);
}
```

Here, we're borrowing a pointer to `x` inside of the `if`. The compiler, however,
is able to determine that that pointer will go out of scope without `x` being
mutated, and therefore, lets us pass. This wouldn't work:

```{rust,ignore}
fn main() {
    let mut x = 5;

    if x < 10 {
        let y = &x;

        x -= 1;

        println!("Oh no: {}", y);
        return;
    }

    x -= 1;

    println!("Oh no: {}", x);
}
```

It gives this error:

```text
test.rs:7:9: 7:15 error: cannot assign to `x` because it is borrowed
test.rs:7         x -= 1;
                  ^~~~~~
test.rs:5:18: 5:19 note: borrow of `x` occurs here
test.rs:5         let y = &x;
                           ^
```

As you might guess, this kind of analysis is complex for a human, and therefore
hard for a computer, too! There is an entire [guide devoted to references, ownership,
and lifetimes](ownership.html) that goes into this topic in
great detail, so if you want the full details, check that out.

## Best practices

In general, prefer stack allocation over heap allocation. Using references to
stack allocated information is preferred whenever possible. Therefore,
references are the default pointer type you should use, unless you have a
specific reason to use a different type. The other types of pointers cover when
they're appropriate to use in their own best practices sections.

Use references when you want to use a pointer, but do not want to take ownership.
References just borrow ownership, which is more polite if you don't need the
ownership. In other words, prefer:

```{rust}
fn succ(x: &i32) -> i32 { *x + 1 }
```

to

```{rust}
fn succ(x: Box<i32>) -> i32 { *x + 1 }
```

As a corollary to that rule, references allow you to accept a wide variety of
other pointers, and so are useful so that you don't have to write a number
of variants per pointer. In other words, prefer:

```{rust}
fn succ(x: &i32) -> i32 { *x + 1 }
```

to

```{rust}
use std::rc::Rc;

fn box_succ(x: Box<i32>) -> i32 { *x + 1 }

fn rc_succ(x: Rc<i32>) -> i32 { *x + 1 }
```

Note that the caller of your function will have to modify their calls slightly:

```{rust}
use std::rc::Rc;

fn succ(x: &i32) -> i32 { *x + 1 }

let ref_x = &5;
let box_x = Box::new(5);
let rc_x = Rc::new(5);

succ(ref_x);
succ(&*box_x);
succ(&*rc_x);
```

The initial `*` dereferences the pointer, and then `&` takes a reference to
those contents.

# Boxes

`Box<T>` is Rust's *boxed pointer* type. Boxes provide the simplest form of
heap allocation in Rust. Creating a box looks like this:

```{rust}
let x = Box::new(5);
```

Boxes are heap allocated and they are deallocated automatically by Rust when
they go out of scope:

```{rust}
{
    let x = Box::new(5);

    // stuff happens

} // x is destructed and its memory is free'd here
```

However, boxes do _not_ use reference counting or garbage collection. Boxes are
what's called an *affine type*. This means that the Rust compiler, at compile
time, determines when the box comes into and goes out of scope, and inserts the
appropriate calls there.

You don't need to fully grok the theory of affine types to grok boxes, though.
As a rough approximation, you can treat this Rust code:

```{rust}
{
    let x = Box::new(5);

    // stuff happens
}
```

As being similar to this C code:

```c
{
    int *x;
    x = (int *)malloc(sizeof(int));
    *x = 5;

    // stuff happens

    free(x);
}
```

Of course, this is a 10,000 foot view. It leaves out destructors, for example.
But the general idea is correct: you get the semantics of `malloc`/`free`, but
with some improvements:

1. It's impossible to allocate the incorrect amount of memory, because Rust
   figures it out from the types.
2. You cannot forget to `free` memory you've allocated, because Rust does it
   for you.
3. Rust ensures that this `free` happens at the right time, when it is truly
   not used. Use-after-free is not possible.
4. Rust enforces that no other writeable pointers alias to this heap memory,
   which means writing to an invalid pointer is not possible.

See the section on references or the [ownership guide](ownership.html)
for more detail on how lifetimes work.

Using boxes and references together is very common. For example:

```{rust}
fn add_one(x: &i32) -> i32 {
    *x + 1
}

fn main() {
    let x = Box::new(5);

    println!("{}", add_one(&*x));
}
```

In this case, Rust knows that `x` is being *borrowed* by the `add_one()`
function, and since it's only reading the value, allows it.

We can borrow `x` as read-only multiple times, even simultaneously:

```{rust}
fn add(x: &i32, y: &i32) -> i32 {
    *x + *y
}

fn main() {
    let x = Box::new(5);

    println!("{}", add(&*x, &*x));
    println!("{}", add(&*x, &*x));
}
```

We can mutably borrow `x` multiple times, but only if x itself is mutable, and
it may not be *simultaneously* borrowed: 

```{rust,ignore}
fn increment(x: &mut i32) {
    *x += 1;
}

fn main() {
    // If variable x is not "mut", this will not compile
    let mut x = Box::new(5);

    increment(&mut x);
    increment(&mut x);
    println!("{}", x);
}
```

Notice the signature of `increment()` requests a mutable reference.

## Best practices

Boxes are appropriate to use in two situations: Recursive data structures,
and occasionally, when returning data.

### Recursive data structures

Sometimes, you need a recursive data structure. The simplest is known as a
*cons list*:


```{rust}
#[derive(Debug)]
enum List<T> {
    Cons(T, Box<List<T>>),
    Nil,
}

fn main() {
    let list: List<i32> = List::Cons(1, Box::new(List::Cons(2, Box::new(List::Cons(3, Box::new(List::Nil))))));
    println!("{:?}", list);
}
```

This prints:

```text
Cons(1, Box(Cons(2, Box(Cons(3, Box(Nil))))))
```

The reference to another `List` inside of the `Cons` enum variant must be a box,
because we don't know the length of the list. Because we don't know the length,
we don't know the size, and therefore, we need to heap allocate our list.

Working with recursive or other unknown-sized data structures is the primary
use-case for boxes.

### Returning data

This is important enough to have its own section entirely. The TL;DR is this:
you don't want to return pointers, even when you might in a language like C or
C++.

See [Returning Pointers](#returning-pointers) below for more.

# Rc and Arc

This part is coming soon.

## Best practices

This part is coming soon.

# Raw Pointers

This part is coming soon.

## Best practices

This part is coming soon.

# Returning Pointers

In many languages with pointers, you'd return a pointer from a function
so as to avoid copying a large data structure. For example:

```{rust}
struct BigStruct {
    one: i32,
    two: i32,
    // etc
    one_hundred: i32,
}

fn foo(x: Box<BigStruct>) -> Box<BigStruct> {
    Box::new(*x)
}

fn main() {
    let x = Box::new(BigStruct {
        one: 1,
        two: 2,
        one_hundred: 100,
    });

    let y = foo(x);
}
```

The idea is that by passing around a box, you're only copying a pointer, rather
than the hundred `int`s that make up the `BigStruct`.

This is an antipattern in Rust. Instead, write this:

```rust
#![feature(box_syntax)]

struct BigStruct {
    one: i32,
    two: i32,
    // etc
    one_hundred: i32,
}

fn foo(x: Box<BigStruct>) -> BigStruct {
    *x
}

fn main() {
    let x = Box::new(BigStruct {
        one: 1,
        two: 2,
        one_hundred: 100,
    });

    let y: Box<BigStruct> = box foo(x);
}
```

Note that this uses the `box_syntax` feature gate, so this syntax may change in
the future.

This gives you flexibility without sacrificing performance.

You may think that this gives us terrible performance: return a value and then
immediately box it up ?! Isn't this pattern the worst of both worlds? Rust is
smarter than that. There is no copy in this code. `main` allocates enough room
for the `box`, passes a pointer to that memory into `foo` as `x`, and then
`foo` writes the value straight into the `Box<T>`.

This is important enough that it bears repeating: pointers are not for
optimizing returning values from your code. Allow the caller to choose how they
want to use your output.

# Creating your own Pointers

This part is coming soon.

## Best practices

This part is coming soon.

# Patterns and `ref`

When you're trying to match something that's stored in a pointer, there may be
a situation where matching directly isn't the best option available. Let's see
how to properly handle this:

```{rust,ignore}
fn possibly_print(x: &Option<String>) {
    match *x {
        // BAD: cannot move out of a `&`
        Some(s) => println!("{}", s)

        // GOOD: instead take a reference into the memory of the `Option`
        Some(ref s) => println!("{}", *s),
        None => {}
    }
}
```

The `ref s` here means that `s` will be of type `&String`, rather than type
`String`.

This is important when the type you're trying to get access to has a destructor
and you don't want to move it, you just want a reference to it.

# Cheat Sheet

Here's a quick rundown of Rust's pointer types:

| Type         | Name                | Summary                                                             |
|--------------|---------------------|---------------------------------------------------------------------|
| `&T`         | Reference           | Allows one or more references to read `T`                           |
| `&mut T`     | Mutable Reference   | Allows a single reference to read and write `T`                     |
| `Box<T>`     | Box                 | Heap allocated `T` with a single owner that may read and write `T`. |
| `Rc<T>`      | "arr cee" pointer   | Heap allocated `T` with many readers                                |
| `Arc<T>`     | Arc pointer         | Same as above, but safe sharing across threads                      |
| `*const T`   | Raw pointer         | Unsafe read access to `T`                                           |
| `*mut T`     | Mutable raw pointer | Unsafe read and write access to `T`                                 |

# Related resources

* [API documentation for Box](../std/boxed/index.html)
* [Ownership guide](ownership.html)
* [Cyclone paper on regions](http://www.cs.umd.edu/projects/cyclone/papers/cyclone-regions.pdf), which inspired Rust's lifetime system
