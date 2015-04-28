% Изменяемость (mutability)

Изменяемость, то есть возможность изменить что-то, работает в Rust несколько
особенно. Во-первых, по умолчанию связанные имена не изменяемы:

```rust,ignore
let x = 5;
x = 6; // ошибка!
```

Изменяемость можно добавить с помощью ключевого слова `mut`:

```rust
let mut x = 5;

x = 6; // нет проблем!
```

Это изменяемое [связанное имя][vb]. Когда связанное имя изменяемо, значение, с
которым имя связано, можно изменить. В примере выше не то, чтобы само значение
`x` менялось, а просто имя `x` связывается уже с другим значением типа `i32`.

[vb]: variable-bindings.html

Если вы хотите менять связанное имя, вам понадобится [изменяемая ссылка][mr]:

```rust
let mut x = 5;
let y = &mut x;
```

[mr]: references-and-borrowing.html

`y` - это неизменяемое имя для изменяемой ссылки. Это значит, что `y` нельзя
связать ещё с чем-то (`y = &mut z`), но можно изменить то, на что указывает
связанная ссылка (`*y = 5`). Тонкая разница.

Конечно, вы можете объявить и изменяемое имя для изменяемой ссылки:

```rust
let mut x = 5;
let mut y = &mut x;
```

Теперь `y` можно связать с другим значением, и само это значение тоже можно
менять.

Стоит отметить, что `mut` - это часть [образца][pattern], поэтому можно делать
такие вещи:

```rust
let (mut x, y) = (5, 6);

fn foo(mut x: i32) {
# }
```

[pattern]: patterns.html

# Interior vs. Exterior Mutability

However, when we say something is ‘immutable’ in Rust, that doesn’t mean that
it’s not able to be changed: We mean something has ‘exterior mutability’. Consider,
for example, [`Arc<T>`][arc]:

```rust
use std::sync::Arc;

let x = Arc::new(5);
let y = x.clone();
```

[arc]: ../std/sync/struct.Arc.html

When we call `clone()`, the `Arc<T>` needs to update the reference count. Yet
we’ve not used any `mut`s here, `x` is an immutable binding, and we didn’t take
`&mut 5` or anything. So what gives?

To this, we have to go back to the core of Rust’s guiding philosophy, memory
safety, and the mechanism by which Rust guarantees it, the
[ownership][ownership] system, and more specifically, [borrowing][borrowing]:

> You may have one or the other of these two kinds of borrows, but not both at
> the same time:
> 
> * 0 to N references (`&T`) to a resource.
> * exactly one mutable reference (`&mut T`)

[ownership]: ownership.html
[borrowing]: borrowing.html#The-Rules

So, that’s the real definition of ‘immutability’: is this safe to have two
pointers to? In `Arc<T>`’s case, yes: the mutation is entirely contained inside
the structure itself. It’s not user facing. For this reason, it hands out `&T`
with `clone()`. If it handed out `&mut T`s, though, that would be a problem.

Other types, like the ones in the [`std::cell`][stdcell] module, have the
opposite: interior mutability. For example:

```rust
use std::cell::RefCell;

let x = RefCell::new(42);

let y = x.borrow_mut();
```

[stdcell]: ../std/cell/index.html

RefCell hands out `&mut` references to what’s inside of it with the
`borrow_mut()` method. Isn’t that dangerous? What if we do:

```rust,ignore
use std::cell::RefCell;

let x = RefCell::new(42);

let y = x.borrow_mut();
let z = x.borrow_mut();
# (y, z);
```

This will in fact panic, at runtime. This is what `RefCell` does: it enforces
Rust’s borrowing rules at runtime, and `panic!`s if they’re violated. This
allows us to get around another aspect of Rust’s mutability rules. Let’s talk
about it first.

## Field-level mutability

Mutability is a property of either a borrow (`&mut`) or a binding (`let mut`).
This means that, for example, you cannot have a [`struct`][struct] with
some fields mutable and some immutable:

```rust,ignore
struct Point {
    x: i32,
    mut y: i32, // nope
}
```

The mutability of a struct is in its binding:

```rust,ignore
struct Point {
    x: i32,
    y: i32,
}

let mut a = Point { x: 5, y: 6 };

a.x = 10;

let b = Point { x: 5, y: 6};

b.x = 10; // error: cannot assign to immutable field `b.x`
```

[struct]: structs.html

However, by using `Cell<T>`, you can emulate field-level mutability:

```
use std::cell::Cell;

struct Point {
    x: i32,
    y: Cell<i32>,
}

let mut point = Point { x: 5, y: Cell::new(6) };

point.y.set(7);

println!("y: {:?}", point.y);
```

This will print `y: Cell { value: 7 }`. We’ve successfully updated `y`.
