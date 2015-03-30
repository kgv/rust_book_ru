% Ассоциированные типы

Ассоциированные (связанные) типы - это мощная часть системы типов в Rust. Они
связаны с идеей 'семейства типа', другими словами, группировки различных типов
вместе. Это описание немного абстрактно, так что давайте разберем на примере.
Если вы хотите написать трейт `Graph`, то нужны два обобщенных параметра типа:
тип узел и тип ребро. Исходя из этого, вы можете написать трейт `Graph<N, E>`,
который выглядит следующим образом:

```rust
trait Graph<N, E> {
    fn has_edge(&self, &N, &N) -> bool;
    fn edges(&self, &N) -> Vec<E>;
    // etc
}
```

Такое решение вроде бы достигает своей цели, он, в конечном счете, является
неудобным. Например, любая функция, которая принимает `Graph` в качестве
параметра, _также_ должна быть дженериком с обобщенными параметрами `N` и `E`:

```rust,ignore
fn distance<N, E, G: Graph<N, E>>(graph: &G, start: &N, end: &N) -> u32 { ... }
```

Наша функция расчета расстояния работает независимо от типа `Edge`, поэтому
параметр `E` в этой сигнатуре является лишним и только отвлекает.

Что действительно нужно заявить, это чтобы сформировать какого-либо вида
`Graph`, нужны соответствующие типы `E` и `N`, собранные вместе. Мы можем
сделать это с помощью ассоциированных типов:

```rust
trait Graph {
    type N;
    type E;

    fn has_edge(&self, &Self::N, &Self::N) -> bool;
    fn edges(&self, &Self::N) -> Vec<Self::E>;
    // etc
}
```

Теперь наши клиенты могут абстрагироваться от определенного `Graph`:

```rust,ignore
fn distance<G: Graph>(graph: &G, start: &G::N, end: &G::N) -> uint { ... }
```

Больше нет необходимости иметь дело с типом `E`!

Давайте поговорим обо всем этом более подробно.

## Определение ассоциированных типов

Давайте построим наш трейт `Graph`. Вот его определение:

```rust
trait Graph {
    type N;
    type E;

    fn has_edge(&self, &Self::N, &Self::N) -> bool;
    fn edges(&self, &Self::N) -> Vec<Self::E>;
}
```

Достаточно просто. Ассоциированные типы используют ключевое слово `type`, и
расположены внутри тела трейта, наряду с функциями.

These `type` declarations can have all the same thing as functions do. For example,
if we wanted our `N` type to implement `Display`, so we can print the nodes out,
we could do this:
Эти объявления `type` могут иметь все то же самое, как функции делают. Например,
если бы мы хотели, чтобы тип `N` реализовывал `Display`, чтобы была возможность
печатать узлы, мы могли бы сделать следующее:

```rust
use std::fmt;

trait Graph {
    type N: fmt::Display;
    type E;

    fn has_edge(&self, &Self::N, &Self::N) -> bool;
    fn edges(&self, &Self::N) -> Vec<Self::E>;
}
```

## Реализация ассоциированных типов

Трейт, который включает ассоциированные типы, как и любой другой трейт, для
реализации использует ключевое слово `impl`. Вот простая реализация `Graph`:

```rust
# trait Graph {
#     type N;
#     type E;
#     fn has_edge(&self, &Self::N, &Self::N) -> bool;
#     fn edges(&self, &Self::N) -> Vec<Self::E>;
# }
struct Node;

struct Edge;

struct MyGraph;

impl Graph for MyGraph {
    type N = Node;
    type E = Edge;

    fn has_edge(&self, n1: &Node, n2: &Node) -> bool {
        true
    }

    fn edges(&self, n: &Node) -> Vec<Edge> {
        Vec::new()
    }
}
```

Это глупая реализация, которая всегда возвращает `true` и пустой `Vec<Edge>`, но
она дает вам общее представление о том, как реализуются такие ​​вещи. Для начала
нужны три `struct`, одна для графа, одна для узла и одна для ребра. В этой
реализации используются `struct` для всех трех сущностей, но вполне могли бы
использоваться и другие типы, которые работали бы так же хорошо, если бы
реализация была более продвинутой.

Затем идет строка с `impl`, которая является такой же, как и при реализации
любого другого трейта.

Далее мы используем знак `=`, чтобы определить наши ассоциированные типы. Имя
трейта идет слева от знака `=`, а конкретный тип, для которого мы `impl` этот
трейт, идет справа. Наконец, мы используем конкретные типы при объявлении
функций.

## Трейт объекты и ассоциированные типы

Вот еще немного синтаксиса, о котором следует упомянуть: трейт объекты. Если вы
попытаетесь создать трейт объект из ассоциированного типа, как в этом примере:

```rust,ignore
# trait Graph {
#     type N;
#     type E;
#     fn has_edge(&self, &Self::N, &Self::N) -> bool;
#     fn edges(&self, &Self::N) -> Vec<Self::E>;
# }
# struct Node;
# struct Edge;
# struct MyGraph;
# impl Graph for MyGraph {
#     type N = Node;
#     type E = Edge;
#     fn has_edge(&self, n1: &Node, n2: &Node) -> bool {
#         true
#     }
#     fn edges(&self, n: &Node) -> Vec<Edge> {
#         Vec::new()
#     }
# }
let graph = MyGraph;
let obj = Box::new(graph) as Box<Graph>;
```

Вы получите две ошибки:

```text
error: the value of the associated type `E` (from the trait `main::Graph`) must
be specified [E0191]
let obj = Box::new(graph) as Box<Graph>;
          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
24:44 error: the value of the associated type `N` (from the trait
`main::Graph`) must be specified [E0191]
let obj = Box::new(graph) as Box<Graph>;
          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

Мы не сможем создать трейт объект, подобный этому, потому что у него нет
информации об ассоциированных типах. Вместо этого, мы можем написать так:

```rust
# trait Graph {
#     type N;
#     type E;
#     fn has_edge(&self, &Self::N, &Self::N) -> bool;
#     fn edges(&self, &Self::N) -> Vec<Self::E>;
# }
# struct Node;
# struct Edge;
# struct MyGraph;
# impl Graph for MyGraph {
#     type N = Node;
#     type E = Edge;
#     fn has_edge(&self, n1: &Node, n2: &Node) -> bool {
#         true
#     }
#     fn edges(&self, n: &Node) -> Vec<Edge> {
#         Vec::new()
#     }
# }
let graph = MyGraph;
let obj = Box::new(graph) as Box<Graph<N=Node, E=Edge>>;
```

Синтаксис `N=Node` позволяет нам предоставлять конкретный тип, `Node`, для
параметра типа `N`. То же самое и для `E=Edge`. Если бы мы не предоставляли это
ограничение, то не могли бы знать наверняка, какая `impl` соответствует этому
трейт объекту.
