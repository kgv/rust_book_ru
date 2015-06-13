% Шаблоны сопоставления `match`

Шаблоны достаточно часто используются в Rust. Мы уже использовали их в разделе
[Связывание переменных][bindings], в разделе [Конструкция `match`][match], а
также в некоторых других местах. Давайте коротко пробежимся по всем
возможностям, которые можно реализовать с помощью шаблонов!

[bindings]: variable-bindings.html
[match]: match.html

Быстро освежим в памяти: сопоставлять с шаблоном литералы можно либо напрямую,
либо с использованием символа `_`, который означает *любой* случай:

```rust
let x = 1;

match x {
    1 => println!("one"),
    2 => println!("two"),
    3 => println!("three"),
    _ => println!("anything"),
}
```

Этот код напечатает `one`.

# Сопоставление с несколькими шаблонами

Вы можете сопоставлять с несколькими шаблонами, используя `|`:

```rust
let x = 1;

match x {
    1 | 2 => println!("one or two"),
    3 => println!("three"),
    _ => println!("anything"),
}
```

Этот код напечатает `one or two`.

# Сопоставление с диапазоном

Вы можете сопоставлять с диапазоном значений, используя `...`:

```rust
let x = 1;

match x {
    1 ... 5 => println!("one through five"),
    _ => println!("anything"),
}
```

Этот код напечатает `one through five`.

Диапазоны в основном используются с числами или одиночными символами (`char`).

```rust
let x = '💅';

match x {
    'a' ... 'j' => println!("early letter"),
    'k' ... 'z' => println!("late letter"),
    _ => println!("something else"),
}
```

Этот код напечатает `something else`.

# Связывание

Вы можете связать значение с именем с помощью символа `@`:

```rust
let x = 1;

match x {
    e @ 1 ... 5 => println!("got a range element {}", e),
    _ => println!("anything"),
}
```

Этот код напечатает `got a range element 1`. Это полезно, когда вы хотите
сделать сложное сопоставление для части структуры данных:

```rust
#[derive(Debug)]
struct Person {
    name: Option<String>,
}

let name = "Steve".to_string();
let mut x: Option<Person> = Some(Person { name: Some(name) });
match x {
    Some(Person { name: ref a @ Some(_), .. }) => println!("{:?}", a),
    _ => {}
}
```

Этот код напечатает `Some("Steve")`: мы связали внутреннюю `name` с `a`.

Если вы используете `@` совместно с `|`, то вы должны убедиться, что имя
связывается в каждой из частей шаблона:

```rust
let x = 5;

match x {
    e @ 1 ... 5 | e @ 8 ... 10 => println!("got a range element {}", e),
    _ => println!("anything"),
}
```

# Игнорирование вариантов

Если при сопоставлении вы используете перечисление, содержащее варианты, то вы
можете указать `..`, чтобы проигнорировать значение и тип в варианте:

```rust
enum OptionalInt {
    Value(i32),
    Missing,
}

let x = OptionalInt::Value(5);

match x {
    OptionalInt::Value(..) => println!("Got an int!"),
    OptionalInt::Missing => println!("No such luck."),
}
```

Этот код напечатает `Got an int!`.

# Ограничители шаблонов

Вы можете ввести *ограничители шаблонов* (*match guards*) с помощью `if`:

```rust
enum OptionalInt {
    Value(i32),
    Missing,
}

let x = OptionalInt::Value(5);

match x {
    OptionalInt::Value(i) if i > 5 => println!("Got an int bigger than five!"),
    OptionalInt::Value(..) => println!("Got an int!"),
    OptionalInt::Missing => println!("No such luck."),
}
```

Этот код напечатает `Got an int!`.

# ref и ref mut

Если вы хотите получить [ссылку][ref], то используйте ключевое слово `ref`:

```rust
let x = 5;

match x {
    ref r => println!("Got a reference to {}", r),
}
```

Этот код напечатает `Got a reference to 5`.

[ref]: references-and-borrowing.html

Здесь `r` внутри `match` имеет тип `&i32`. Другими словами, ключевое слово `ref`
_создает_ ссылку, для использования в шаблоне. Если вам нужна изменяемая ссылка,
то `ref mut` будет работать аналогичным образом:

```rust
let mut x = 5;

match x {
    ref mut mr => println!("Got a mutable reference to {}", mr),
}
```

# Деструктуризация

Если у вас есть сложный тип данных, например [`struct`][struct], вы можете
деструктурировать его внутри шаблона:

```rust
struct Point {
    x: i32,
    y: i32,
}

let origin = Point { x: 0, y: 0 };

match origin {
    Point { x: x, y: y } => println!("({},{})", x, y),
}
```

[struct]: structs.html

Если нам нужны значения только некоторых из полей структуры, то мы можем не
присваивать им всем имена:

```rust
struct Point {
    x: i32,
    y: i32,
}

let origin = Point { x: 0, y: 0 };

match origin {
    Point { x: x, .. } => println!("x is {}", x),
}
```

Этот код напечатает `x is 0`.

Вы можете сделать это для любого поля, а не только для первого:

```rust
struct Point {
    x: i32,
    y: i32,
}

let origin = Point { x: 0, y: 0 };

match origin {
    Point { y: y, .. } => println!("y is {}", y),
}
```

Этот код напечатает `y is 0`.

Такое "деструктурирование" работает для любых сложных типов данных, таких как
[кортежи][tuples] или [перечисления][enums].

[tuples]: primitive-types.html#tuples
[enums]: enums.html

# Mix and Match

Вот так! Существует много разных способов использования конструкции
сопоставления с шаблоном, и все они могут быть смешаны и состыкованы, в
зависимости от того, что вы хотите сделать:

```rust,ignore
match x {
    Foo { x: Some(ref name), y: None } => ...
}
```

Шаблоны являются очень мощным инструментом. Их использование находит очень
широкое применение.
