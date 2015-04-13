% Шаблоны `match`

-Patterns are quite common in Rust. We use them in [variable
-bindings][bindings], [match statements][match], and other places, too. Let’s go
-on a whirlwind tour of all of the things patterns can do!

Шаблоны достаточно часто используются в Rust. Мы уже использовали их в разделе
[Связывание переменных][bindings], в разделе [Конструкция `match`][match] и в
некоторых других местах. Давайте коротко пробежимся по всем возможностям,
которые можно реализовать с помощью шаблонов!

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

# Сопоставление с диапазоном

Вы можете сопоставлять с диапазоном значений, используя `...`:

```rust
let x = 1;

match x {
    1 ... 5 => println!("one through five"),
    _ => println!("anything"),
}
```

Диапазоны в основном используются с числами или одиночными символами.

# Связывание

Если вы используете множественное сопоставление, с помощью `|` или `...`, вы
можете связать значение с именем с помощью символа `@`:

```rust
let x = 1;

match x {
    e @ 1 ... 5 => println!("got a range element {}", e),
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

# ref и ref mut

Если вы хотите получить [ссылку][ref], то используйте ключевое слово `ref`:

```rust
let x = 5;

match x {
    ref r => println!("Got a reference to {}", r),
}
```

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

Если у вас есть сложный тип данных, например структура, вы можете
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

Такое ‘деструктурирование‘ работает для любых сложных типов данных, таких как
[кортежи][tuples] или [перечисления][enums].

[tuples]: primitive-types.html#tuples
[enums]: enums.html

# Mix and Match

Вот так! Существует много разных способов использования конструкции
сопоставления с шаблоном, и все они могут быть смешаны и состыкованы, в
зависимости от того, что вы хотите сделать:

```{rust,ignore}
match x {
    Foo { x: Some(ref name), y: None } => ...
}
```

Шаблоны являются очень мощным инструментом. Их использование находит очень
широкое применение.
