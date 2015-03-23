% Шалоны

Мы уже использовали шаблоны несколько раз в этом руководстве: сначала при рассмотрении оператора `let`, а затем при изучении конструкции `match`. Давайте коротко пробежимся по всем возможностям, которые можно реализовать с помощью шаблонов!

Быстро освежим в памяти: сопоставлять с образцами литералы можно либо напрямую, либо с помощью символа `_`, который означает *любой* случай:

```{rust}
let x = 1;

match x {
    1 => println!("one"),
    2 => println!("two"),
    3 => println!("three"),
    _ => println!("anything"),
}
```

Вы можете сопоставлять с несколькими шаблонами, используя `|`:

```{rust}
let x = 1;

match x {
    1 | 2 => println!("one or two"),
    3 => println!("three"),
    _ => println!("anything"),
}
```

Вы можете сопоставлять с диапазоном значений, используя `...`:

```{rust}
let x = 1;

match x {
    1 ... 5 => println!("one through five"),
    _ => println!("anything"),
}
```

Диапазоны в основном используются с числами или одиночными символами.

Если вы используете множественное сопоставление, с помощью `|` или `...`, вы можете присвоить значение переменной с именем `@`:

```{rust}
let x = 1;

match x {
    e @ 1 ... 5 => println!("got a range element {}", e),
    _ => println!("anything"),
}
```

Если при сопоставлении вы используете перечисление, содержащее варианты, то вы можете указать `..`, чтобы проигнорировать значение и тип в варианте:

```{rust}
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

Вы можете ввести *ограничители шаблонов сопоставления* (*match guards*) с помощью `if`:

```{rust}
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

Если вы сопоставляете с указателем, то вы можете использовать тот же синтаксис, что и при его объявлении. Во-первых, `&`:

```{rust}
let x = &5;

match x {
    &val => println!("Got a value: {}", val),
}
```

Здесь `val` внутри `match` имеет тип `i32`. Другими словами, в левой части шаблона сопоставления значение деструктурируется. Если `&val` соответствует `&5`, то `val` будет `5`.

Если же вы хотите получить ссылку, то используйте ключевое слово `ref`:

```{rust}
let x = 5;

match x {
    ref r => println!("Got a reference to {}", r),
}
```

Здесь `r` внутри `match` имеет тип `&i32`. Другими словами, ключевое слово `ref` _создает_ ссылку, для использования в шаблоне. Если вам нужна изменяемая ссылка, то `ref mut` будет работать аналогичным образом:

```{rust}
let mut x = 5;

match x {
    ref mut mr => println!("Got a mutable reference to {}", mr),
}
```

Если у вас есть структура, вы можете деструктурировать ее внутри шаблона:

```{rust}
# #![allow(non_shorthand_field_patterns)]
struct Point {
    x: i32,
    y: i32,
}

let origin = Point { x: 0, y: 0 };

match origin {
    Point { x: x, y: y } => println!("({},{})", x, y),
}
```

Если нам нужны значения только некоторых из полей структуры, то мы можем не присваивать им всем имена:

```{rust}
# #![allow(non_shorthand_field_patterns)]
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

```{rust}
# #![allow(non_shorthand_field_patterns)]
struct Point {
    x: i32,
    y: i32,
}

let origin = Point { x: 0, y: 0 };

match origin {
    Point { y: y, .. } => println!("y is {}", y),
}
```

Если вы хотите использовать сопоставление со срезом или массивом, то вы можете указать `&`:

```{rust}
fn main() {
    let v = vec!["match_this", "1"];

    match &v[..] {
        ["match_this", second] => println!("The second element is {}", second),
        _ => {},
    }
}
```

Вот так! Существует много разных способов использования конструкции сопоставления с шаблоном, и все они могут быть смешаны и состыкованы, в зависимости от того, что вы хотите сделать:

```{rust,ignore}
match x {
    Foo { x: Some(ref name), y: None } => ...
}
```

Шаблоны являются очень мощным инструментом. Их использование находит очень широкое применение.
