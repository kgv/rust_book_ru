% Выбор гарантий

Одна из важных черт языка Rust — это то, что он позволяет нам управлять
накладными расходами и гарантиями программы.

One important feature of Rust as language is that it lets us control the costs and guarantees
of a program.

В стандартной библиотеке Rust много «обёрточных типов», которые реализуют
множество компромиссов между накладными расходами, эргономикой, и гарантиями.
Многие позволяют выбирать между проверками во время компиляции и проверками во
время исполнения. Эта глава подробно объяснит несколько избранных абстракций.

There are various &ldquo;wrapper type&rdquo; abstractions in the Rust standard library which embody
a multitude of tradeoffs between cost, ergonomics, and guarantees. Many let one choose between
run time and compile time enforcement. This section will explain a few selected abstractions in
detail.

Очень рекомендуем сначала познакомиться с [владением][ownership] и
[заимствованием][borrowing] в Rust.

Before proceeding, it is highly recommended that one reads about [ownership][ownership] and
[borrowing][borrowing] in Rust.

[ownership]: ownership.html
[borrowing]: references-and-borrowing.html

# Основные типы указателей

## `Box<T>`

[`Box<T>`][box] — это указатель, который «владеет» данными, по-другому
называемый «упаковкой». Хотя он и может выдавать ссылки на данные, содержащиеся
в нём, он — единственный владелец этих данных. В частности, когда происходит
что-то вроде этого:

[`Box<T>`][box] is pointer which is &ldquo;owned&rdquo;, or a &ldquo;box&rdquo;. While it can hand
out references to the contained data, it is the only owner of the data. In particular, when
something like the following occurs:

```rust
let x = Box::new(1);
let y = x;
// x больше не доступен
```

Здесь упаковка была _перемещена_ в `y`. Поскольку `x` больше не владеет ею, с
этого момента компилятор не позволит использовать `x`. Упаковка также может быть
перемещена _из_ функции — для этого функция возвращает её как свой результат.

Here, the box was _moved_ into `y`. As `x` no longer owns it, the compiler will no longer allow the
programmer to use `x` after this. A box can similarly be moved _out_ of a function by returning it.

Когда упаковка, которая не была перемещена, выходит из области видимости,
выполняются деструкторы. Эти деструкторы освобождают содержащиеся данные.

When a box (that hasn't been moved) goes out of scope, destructors are run. These destructors take
care of deallocating the inner data.

Мы абстрагируемся от динамического выделения памяти, и это абстракция без
накладных расходов. Это идеальный способ выделить память в куче и безопасно
передавать указатель на эту память. Заметьте, что вы можете создавать ссылки на
упаковку по обычным правилам заимствования, которые проверяются во время
компиляции.

This is a zero-cost abstraction for dynamic allocation. If you want to allocate some memory on the
heap and safely pass around a pointer to that memory, this is ideal. Note that you will only be
allowed to share references to this by the regular borrowing rules, checked at compile time.

[box]: ../std/boxed/struct.Box.html

## `&T` и `&mut T`

Это неизменяемые и изменяемые ссылки, соответственно. Они реализуют шаблон
«read-write lock», т.е. вы можете создать или одну изменяемую ссылку на данные,
или любое число неизменяемых, но не оба вида ссылок одновременно. Эта гарантия
проверяется во время компиляции, и ничего не стоит во время исполнения. В
большинстве случаев эти два типа указателей покрывают все нужды по передаче
дешёвых ссылок между частями кода.

These are immutable and mutable references respectively. They follow the &ldquo;read-write lock&rdquo;
pattern, such that one may either have only one mutable reference to some data, or any number of
immutable ones, but not both. This guarantee is enforced at compile time, and has no visible cost at
runtime. In most cases these two pointer types suffice for sharing cheap references between sections
of code.

При копировании эти указатели сохраняют связанное с ними время жизни — они всё
равно не могут прожить дольше, чем исходное значение, на которое они ссылаются.

These pointers cannot be copied in such a way that they outlive the lifetime associated with them.

## `*const T` и `*mut T`

Это сырые указатели в стиле C, не имеющие связанной информации о времени жизни и
владельце. Они просто указывают на какое-то место в памяти, без дополнительных
ограничений. Они гарантируют только то, что они могут быть разыменованы только в
коде, помеченном как «небезопасный».

These are C-like raw pointers with no lifetime or ownership attached to them. They just point to
some location in memory with no other restrictions. The only guarantee that these provide is that
they cannot be dereferenced except in code marked `unsafe`.

Они полезны при создании безопасных низкоуровневых абстракций вроде `Vec<T>`, но
их следует избегать в безопасном коде.

These are useful when building safe, low cost abstractions like `Vec<T>`, but should be avoided in
safe code.

## `Rc<T>`

Это первая рассматриваемая обёртка, использование которой влечёт за собой
накладные расходы во время исполнения.

This is the first wrapper we will cover that has a runtime cost.

[`Rc<T>`][rc] — это указатель со счётчиком ссылок. С его помощью можно
создавать несколько «владеющих» указателей на одни и те же данные, и эти данные
будут уничтожены, когда все указатели выйдут из области видимости.

[`Rc<T>`][rc] is a reference counted pointer. In other words, this lets us have multiple "owning"
pointers to the same data, and the data will be dropped (destructors will be run) when all pointers
are out of scope.

Собственно, внутри у него счётчик ссылок (reference count, или сокращённо
refcount), который увеличивается каждый раз, когда происходит клонирование `Rc`,
и уменьшается когда `Rc` выходит из области видимости. Основная ответственность
`Rc<T>` — удостовериться в том, что для разделяемых данных вызываются
деструкторы.

Internally, it contains a shared &ldquo;reference count&rdquo; (also called &ldquo;refcount&rdquo;),
which is incremented each time the `Rc` is cloned, and decremented each time one of the `Rc`s goes
out of scope. The main responsibility of `Rc<T>` is to ensure that destructors are called for shared
data.

Хранимые данные при этом неизменяемы, и если создаётся цикл ссылок, данные
утекут. Если нам нужно отсутствие утечек в присутствие циклов, нужно
использовать сборщик мусора.

The internal data here is immutable, and if a cycle of references is created, the data will be
leaked. If we want data that doesn't leak when there are cycles, we need a garbage collector.

#### Гарантии

Здесь главная гарантия в том, что данные не будут уничтожены, пока все ссылки на
них не исчезнут.

The main guarantee provided here is that the data will not be destroyed until all references to it
are out of scope.

Счётчик ссылок нужно использовать, когда мы хотим динамически выделить какие-то
данные и предоставить ссылки на эти данные только для чтения, и при этом неясно,
какая часть программы последней закончит использование ссылки. Это подходящая
альтернатива `&T`, когда невозможно статически доказатль правильность `&T`, или
когда это создаёт слишком большие неудобства в написании кода, на который
разработчик не хочет тратить своё время.

This should be used when we wish to dynamically allocate and share some data (read-only) between
various portions of your program, where it is not certain which portion will finish using the pointer
last. It's a viable alternative to `&T` when `&T` is either impossible to statically check for
correctness, or creates extremely unergonomic code where the programmer does not wish to spend the
development cost of working with.

Этот указатель _не_ является потокобезопасным, и Rust не позволяет передавать
его или делиться им с другими потоками. Это позволяет избежать накладных
расходов от использования атомарных операций там, где они не нужны.

This pointer is _not_ thread safe, and Rust will not let it be sent or shared with other threads.
This lets one avoid the cost of atomics in situations where they are unnecessary.

Есть похожий умный указатель, `Weak<T>`. Это невладеющий, но и не заимствуемый,
умный указатель. Он тоже похож на `&T`, но не ограничен временем жизни —
`Weak<T>` можно не отпускать. Однако, возможна ситуация, когда попытка доступа к
хранимым в нём данным провалится и вернёт `None`, поскольку `Weak<T>` может
пережить владеющие `Rc`. Его удобно использовать в случае циклических структур
данных и некоторых других.

There is a sister smart pointer to this one, `Weak<T>`. This is a non-owning, but also non-borrowed,
smart pointer. It is also similar to `&T`, but it is not restricted in lifetime&mdash;a `Weak<T>`
can be held on to forever. However, it is possible that an attempt to access the inner data may fail
and return `None`, since this can outlive the owned `Rc`s. This is useful for cyclic
data structures and other things.

#### Накладные расходы

Что касается памяти, `Rc<T>` — это одно выделение, однако оно будет включать
два лишних слова (т.е. два значения типа `usize`) по сравнению с обычным
`Box<T>`. Это верно и для «сильных», и для «слабых» счётчиков ссылок.

As far as memory goes, `Rc<T>` is a single allocation, though it will allocate two extra words (i.e.
two `usize` values) as compared to a regular `Box<T>` (for "strong" and "weak" refcounts).

Вычислительная сложность поддержания `Rc<T>` заключается в увеличении и
уменьшении счётчика ссылок каждый раз, когда `Rc<T>` клонируется или выходит из
области видимости, соответственно. Отметим, что клонирование не выполняет
глубокое копирование, а просто увеличивает счётчик и возвращает копию `Rc<T>`.

`Rc<T>` has the computational cost of incrementing/decrementing the refcount whenever it is cloned
or goes out of scope respectively. Note that a clone will not do a deep copy, rather it will simply
increment the inner reference count and return a copy of the `Rc<T>`.

[rc]: ../std/rc/struct.Rc.html

# Типы-ячейки (cell types)

Типы `Cell` предоставляют «внутреннюю» изменяемость. Другими словами, они
содержат данные, которые можно изменять даже если тип не может быть получен в
изменяемом виде (например, когда он за указателем `&` или за `Rc<T>`).

`Cell`s provide interior mutability. In other words, they contain data which can be manipulated even
if the type cannot be obtained in a mutable form (for example, when it is behind an `&`-ptr or
`Rc<T>`).

[Документация модуля `cell` довольно хорошо объясняет эти вещи][cell-mod].

[The documentation for the `cell` module has a pretty good explanation for these][cell-mod].

Эти типы _обычно_ используют в полях структур, но они не ограничены таким
использованием.

These types are _generally_ found in struct fields, but they may be found elsewhere too.

## `Cell<T>`

[`Cell<T>`][cell] — это тип, который обеспечивает внутреннюю изменяемость без
накладных расходов, но только для типов, реализующих типаж `Copy`. Поскольку
компилятор знает, что все данные, вложенные в `Cell<T>`, находятся на стеке, их
можно просто заменять без страха утечки ресурсов.

[`Cell<T>`][cell] is a type that provides zero-cost interior mutability, but only for `Copy` types.
Since the compiler knows that all the data owned by the contained value is on the stack, there's
no worry of leaking any data behind references (or worse!) by simply replacing the data.

Нарушить инварианты с помощью этой обёртки всё равно можно, поэтому будьте
осторожны при её использовании. Если поле обёрнуто в `Cell`, это индикатор того,
что эти данные изменяемы и поле может не сохранить своё значение с момента
чтения до момента его использования.

It is still possible to violate your own invariants using this wrapper, so be careful when using it.
If a field is wrapped in `Cell`, it's a nice indicator that the chunk of data is mutable and may not
stay the same between the time you first read it and when you intend to use it.

```rust
use std::cell::Cell;

let x = Cell::new(1);
let y = &x;
let z = &x;
x.set(2);
y.set(3);
z.set(4);
println!("{}", x.get());
```

Заметьте, что здесь мы смогли изменить значение через различные ссылки без права
изменения.

Note that here we were able to mutate the same value from various immutable references.

В плане затрат во время исполнения, такой код аналогичен нижеследующему:

This has the same runtime cost as the following:

```rust,ignore
let mut x = 1;
let y = &mut x;
let z = &mut x;
x = 2;
*y = 3;
*z = 4;
println!("{}", x);
```

но имеет преимущество в том, что он действительно компилируется.

but it has the added benefit of actually compiling successfully.

#### Гарантии

Этот тип ослабляет правило отсутствия совпадающих указателей с правом записи
там, где оно не нужно. Однако, он также ослабляет гарантии, которые
предоставляет такое ограничение; поэтому если ваши инварианты зависят от данных,
хранимых в `Cell`, будьте осторожны.

This relaxes the &ldquo;no aliasing with mutability&rdquo; restriction in places where it's
unnecessary. However, this also relaxes the guarantees that the restriction provides; so if your
invariants depend on data stored within `Cell`, you should be careful.

Это применяется при изменении примитивов и других типов, реализующих `Copy`,
когда нет лёгкого способа сделать это в соответствии с статическими правилами
`&` и `&mut`.

This is useful for mutating primitives and other `Copy` types when there is no easy way of
doing it in line with the static rules of `&` and `&mut`.

`Cell` не позволяет получать внутрение ссылки на данные, что позволяет безопасно
менять его содержимое.

`Cell` does not let you obtain interior references to the data, which makes it safe to freely
mutate.

#### Накладные расходы

Накладные расходы при использовании `Cell<T>` отсутствуют, однако если вы
оборачиваете в него большие структуры, есть смысл вместо этого обернуть
отдельные поля, поскольку иначе каждая запись будет производить полное
копирование структуры.

There is no runtime cost to using `Cell<T>`, however if you are using it to wrap larger (`Copy`)
structs, it might be worthwhile to instead wrap individual fields in `Cell<T>` since each write is
otherwise a full copy of the struct.

## `RefCell<T>`

[`RefCell<T>`][refcell] также предоставляет внутреннюю изменяемость, но не
ограничен только типами, реализующими `Copy`.

[`RefCell<T>`][refcell] also provides interior mutability, but isn't restricted to `Copy` types.

Однако, у этого решения есть накладные расходы. `RefCell<T>` реализует шаблон
«read-write lock» во время исполнения, а не во время компиляции, как `&T`/
`&mut T`. Он похож на однопоточный мьютекс. У него есть функции `borrow()` и
`borrow_mut()`, которые изменяют внутрений счётчик ссылок и возвращают умный
указатель, который может быть разыменован без права изменения или с ним,
соответственно. Счётчик ссылок восстанавливается, когда умные указатели выходят
из области видимости. С этой системой мы можем динамически гарантировать, что во
время заимствования с правом изменения никаких других ссылок на значение больше
нет. Если программист пытается позаимствовать значение в этот момент, поток
запаникует.

Instead, it has a runtime cost. `RefCell<T>` enforces the read-write lock pattern at runtime (it's
like a single-threaded mutex), unlike `&T`/`&mut T` which do so at compile time. This is done by the
`borrow()` and `borrow_mut()` functions, which modify an internal reference count and return smart
pointers which can be dereferenced immutably and mutably respectively. The refcount is restored when
the smart pointers go out of scope. With this system, we can dynamically ensure that there are never
any other borrows active when a mutable borrow is active. If the programmer attempts to make such a
borrow, the thread will panic.

```rust
use std::cell::RefCell;

let x = RefCell::new(vec![1,2,3,4]);
{
    println!("{:?}", *x.borrow())
}

{
    let mut my_ref = x.borrow_mut();
    my_ref.push(1);
}
```

Как и `Cell`, это в основном применяется в ситуациях, когда сложно или
невозможно удовлетворить статическую проверку заимствования. В целом мы знаем,
что такие изменения не будут происходить вложенным образом, но это стоит
дополнительно проверить.

Similar to `Cell`, this is mainly useful for situations where it's hard or impossible to satisfy the
borrow checker. Generally we know that such mutations won't happen in a nested form, but it's good
to check.

Для больших, сложных программ, есть смысл положить некоторые вещи в `RefCell`,
чтобы упростить работу с ними. Например, многие словари в структуре `ctxt`[ctxt]
в компиляторе Rust обёрнуты в этот тип. Они изменяются только однажды — во
время создания, но не во время инициализации, или несколько раз в явно отдельных
местах. Однако, поскольку эта структура повсеместно используется везде,
жонглирование изменяемыми и неизменяемыми указателями было бы очень сложным (или
невозможным), и наверняка создало бы мешанину указателей `&`, которую сложно
было бы расширять. С другой стороны, `RefCell` предоставляет дешёвый (но не
бесплатный) способ обращаться к таким данным. В будущем, если кто-то добавит
код, который пытается изменить ячейку, пока она заимствована, это вызывет
панику, источник которой можно отследить. И такая паника обычно происходит
детерминированно.

For large, complicated programs, it becomes useful to put some things in `RefCell`s to make things
simpler. For example, a lot of the maps in [the `ctxt` struct][ctxt] in the rust compiler internals
are inside this wrapper. These are only modified once (during creation, which is not right after
initialization) or a couple of times in well-separated places. However, since this struct is
pervasively used everywhere, juggling mutable and immutable pointers would be hard (perhaps
impossible) and probably form a soup of `&`-ptrs which would be hard to extend. On the other hand,
the `RefCell` provides a cheap (not zero-cost) way of safely accessing these. In the future, if
someone adds some code that attempts to modify the cell when it's already borrowed, it will cause a
(usually deterministic) panic which can be traced back to the offending borrow.

Похожим образом, в DOM Servo много изменения данных, большая часть которого
происходит внутри типа DOM, но часть выходит за его границы и изменяет
произвольные вещи. Использование `RefCell` и `Cell` для ограждения этих
изменений позволяет нам избежать необходимости беспокоиться об изменяемости
везде, и одновременно обозначает места, где изменение _действительно_
происходит.

Similarly, in Servo's DOM there is a lot of mutation, most of which is local to a DOM type, but some
of which crisscrosses the DOM and modifies various things. Using `RefCell` and `Cell` to guard all
mutation lets us avoid worrying about mutability everywhere, and it simultaneously highlights the
places where mutation is _actually_ happening.

Заметьте, что стоит избегать использования `RefCell`, если возможно достаточно
простое решение с помощью указателей `&`.

Note that `RefCell` should be avoided if a mostly simple solution is possible with `&` pointers.

#### Гарантии

`RefCell` ослабляет _статические_ ограничения, предотвращающие совпадение
изменяемых указателей, и заменяет их на _динамические_ ограничения. Сами
гарантии при этом не изменяются.

`RefCell` relaxes the _static_ restrictions preventing aliased mutation, and replaces them with
_dynamic_ ones. As such the guarantees have not changed.

#### Накладные расходы

`RefCell` не выделяет память, но содержит дополнительный индикатор «состояния
заимствования» (размером в одно слово) вместе с данными.

`RefCell` does not allocate, but it contains an additional "borrow state"
indicator (one word in size) along with the data.

Во время исполнения каждое заимствование вызывает изменение и проверку счётчика
ссылок.

At runtime each borrow causes a modification/check of the refcount.

[cell-mod]: ../std/cell/
[cell]: ../std/cell/struct.Cell.html
[refcell]: ../std/cell/struct.RefCell.html
[ctxt]: ../rustc/middle/ty/struct.ctxt.html

# Синхронизированные типы

Многие из вышеперечисленных типов не могут быть использованы потокобезопасным
образом. В частности, `Rc<T>` и `RefCell<T>`, оба из которых используют
не-атомарные счётчики ссылок, не могут быть использованы так. (_Атомарные_
счётчики ссылок — это такие, которые могут быть увеличены из нескольких
потоков, не вызывая при этом гонку данных.) Благодаря этому они привносят меньше
накладных расходов, но нам также потребуются и потокобезопасные варианты этих
типов. Они существуют — это `Arc<T>` и `Mutex<T>`/`RWLock<T>`.

Many of the types above cannot be used in a threadsafe manner. Particularly, `Rc<T>` and
`RefCell<T>`, which both use non-atomic reference counts (_atomic_ reference counts are those which
can be incremented from multiple threads without causing a data race), cannot be used this way. This
makes them cheaper to use, but we need thread safe versions of these too. They exist, in the form of
`Arc<T>` and `Mutex<T>`/`RwLock<T>`

Заметьте, что не-потокобезопасные типы _не могут_ быть переданы между потоками,
и это проверяется во время компиляции.

Note that the non-threadsafe types _cannot_ be sent between threads, and this is checked at compile
time.

В модуле [sync][sync] много полезных обёрточных типов для многопоточного
программирования, но мы затронем только главные из них.

There are many useful wrappers for concurrent programming in the [sync][sync] module, but only the
major ones will be covered below.

[sync]: ../std/sync/index.html

## `Arc<T>`

[`Arc<T>`][arc] — это вариант `Rc<T>`, который использует атомарный счётчик
ссылок (поэтому «Arc»). Его можно свободно передавать между потоками.

[`Arc<T>`][arc] is just a version of `Rc<T>` that uses an atomic reference count (hence, "Arc").
This can be sent freely between threads.

`shared_ptr` из C++ похож на `Arc`, но в случае C++ вложенные данные всегда
изменяемы. Чтобы получить семантику, похожую на семантику C++, нужно
использовать `Arc<Mutex<T>>`, `Arc<RwLock<T>>`, или `Arc<UnsafeCell<T>>`[^4].
(`UnsafeCell<T>` — это тип-ячейка, который может содержать любые данные и не
имеет накладных расходов, но доступ к его содержимому производится только внутри
небезопасных блоков.) Последний стоит использовать только тогда, когда мы
уверены в том, что наша работа не вызывет нарушения безопасности памяти.
Учитывайте, что запись в структуру не атомарна, а многие функции вроде
`vec.push()` могут выделять память заново в процессе работы, и тем самым
вызывать небезопасное поведение.

C++'s `shared_ptr` is similar to `Arc`, however in the case of C++ the inner data is always mutable.
For semantics similar to that from C++, we should use `Arc<Mutex<T>>`, `Arc<RwLock<T>>`, or
`Arc<UnsafeCell<T>>`[^4] (`UnsafeCell<T>` is a cell type that can be used to hold any data and has
no runtime cost, but accessing it requires `unsafe` blocks). The last one should only be used if we
are certain that the usage won't cause any memory unsafety. Remember that writing to a struct is not
an atomic operation, and many functions like `vec.push()` can reallocate internally and cause unsafe
behavior, so even monotonicity may not be enough to justify `UnsafeCell`.

[^4]: На самом деле, `Arc<UnsafeCell<T>>` не скомпилируется, поскольку
    `UnsafeCell<T>` не реализует `Send` или `Sync`, но мы можем обернуть его в
    тип и реализовать для него `Send`/`Sync` вручную, чтобы получить
    `Arc<Wrapper<T>>`, где `Wrapper` — это `struct Wrapper<T>(UnsafeCell<T>)`.

[^4]: `Arc<UnsafeCell<T>>` actually won't compile since `UnsafeCell<T>` isn't `Send` or `Sync`, but we can wrap it in a type and implement `Send`/`Sync` for it manually to get `Arc<Wrapper<T>>` where `Wrapper` is `struct Wrapper<T>(UnsafeCell<T>)`.

#### Гарантии

Как и `Rc`, этот тип гарантирует, что деструктор хранимых в нём данных будет
вызван, когда последний `Arc` выходит из области видимости (за исключением
случаев с циклами). В отличие от `Rc`, `Arc` предоставляет эту гарантию и в
многопоточном окружении.

Like `Rc`, this provides the (thread safe) guarantee that the destructor for the internal data will
be run when the last `Arc` goes out of scope (barring any cycles).

#### Накладные расходы

Накладные расходы увеличиваются по сравнению с `Rc`, т.к. теперь для изменения
счётчика ссылок используются атомарные операции (которые происходят каждый раз
при клонировании или выходе из области видимости). Когда вы хотите поделиться
данными в пределах одного потока, предпочтительнее использовать простые ссылки
`&`.

This has the added cost of using atomics for changing the refcount (which will happen whenever it is
cloned or goes out of scope). When sharing data from an `Arc` in a single thread, it is preferable
to share `&` pointers whenever possible.

[arc]: ../std/sync/struct.Arc.html

## `Mutex<T>` and `RwLock<T>`

[`Mutex<T>`][mutex] и [`RwLock<T>`][rwlock] предоставляют механизм
взаимоисключения с помощью охранных значений RAII. Охранные значения — это
объекты, имеющие некоторое состояние, как замок, пока не выполнится их
деструктор. В обоих случаях, мьютекс непрозрачен, пока на нём не вызовут
`lock()`, после чего поток остановится до момента, когда мьютекс может быть
закрыт, после чего возвращается охранное значение. Оно может быть использовано
для доступа к вложенным данным с правом изменения, а мьютекс будет снова открыт,
когда охранное значение выйдет из области видимости.

[`Mutex<T>`][mutex] and [`RwLock<T>`][rwlock] provide mutual-exclusion via RAII guards (guards are
objects which maintain some state, like a lock, until their destructor is called). For both of
these, the mutex is opaque until we call `lock()` on it, at which point the thread will block
until a lock can be acquired, and then a guard will be returned. This guard can be used to access
the inner data (mutably), and the lock will be released when the guard goes out of scope.

```rust,ignore
{
    let guard = mutex.lock();
    // охранное значение разыменовывается в изменяемое значение
    // вложенного в мьютекс типа
    *guard += 1;
} // мьютекс открывается когда выполняется деструктор
```

`RwLock` имеет преимущество — он эффективно работает в случае множественных
чтений. Ведь читать из общих данных всегда безопасно, пока в эти данные никто не
хочет писать; и `RwLock` позволяет читающим получить «право чтения». Право
чтения может быть получено многими потоками одновременно, и за читающими следит
счётчик ссылок. Тот же, кто хочет записать данные, должен получить «право
записи», а оно может быть получено только когда все читающие вышли из области
видимости.

`RwLock` has the added benefit of being efficient for multiple reads. It is always safe to have
multiple readers to shared data as long as there are no writers; and `RwLock` lets readers acquire a
"read lock". Such locks can be acquired concurrently and are kept track of via a reference count.
Writers must obtain a "write lock" which can only be obtained when all readers have gone out of
scope.

#### Гарантии

Оба этих типа предоставляют безопасное изменение данных из разных потоков, но не
защищают от взаимной блокировки (deadlock). Некоторая дополнительная
безопасность протокола работы с данными может быть получена с помощью системы
типов.

Both of these provide safe shared mutability across threads, however they are prone to deadlocks.
Some level of additional protocol safety can be obtained via the type system.

#### Накладные расходы

Для поддержания состояния прав чтения и записи эти типы используют в своей
реализации конструкции, похожие на атомарные типы, и они довольно дороги. Они
могут блокировать все межпроцессорные чтения из памяти, пока не закончат работу.
Ожидание возможности закрытия этих примитивов синхронизации тоже может быть
медленным, когда производится много одновременных попыток доступа к данным.

These use internal atomic-like types to maintain the locks, which are pretty costly (they can block
all memory reads across processors till they're done). Waiting on these locks can also be slow when
there's a lot of concurrent access happening.

[rwlock]: ../std/sync/struct.RwLock.html
[mutex]: ../std/sync/struct.Mutex.html
[sessions]: https://github.com/Munksgaard/rust-sessions

# Сочетание

Распространённая жалоба на код на Rust — это сложность чтения типов вроде
`Rc<RefCell<Vec<T>>>` (или ещё более сложных сочетаний похожих типов). Не всегда
понятно, что делает такая комбинация, или почему автор решил использовать именно
такой тип. Не ясно и то, в каких случаях сам программист должен использовать
похожие сочетания типов.

A common gripe when reading Rust code is with types like `Rc<RefCell<Vec<T>>>` (or even more more
complicated compositions of such types). It's not always clear what the composition does, or why the
author chose one like this (and when one should be using such a composition in one's own code)

Обычно, вам понадобятся такие типы, когда вы хотите сочетать гарантии разных
типов, но не хотите переплачивать за то, что вам не нужно.

Usually, it's a case of composing together the guarantees that you need, without paying for stuff
that is unnecessary.

Например, одно из таких сочетаний — это `Rc<RefCell<T>>`. Сам по себе `Rc<T>`
не может быть разыменован с правом изменения; поскольку `Rc<T>` позволяет
делиться данными и одновременная попытка изменения данных может привести к
небезопасному поведению, мы кладём внутрь `RefCell<T>`, чтобы получить
динамическую проверку одновременных попыток изменения. Теперь у нас есть
разделяемые изменяемые данные, но одновременный доступ к ним предоставляется
только на чтение, а запись всегда исключительна.

For example, `Rc<RefCell<T>>` is one such composition. `Rc<T>` itself can't be dereferenced mutably;
because `Rc<T>` provides sharing and shared mutability can lead to unsafe behavior, so we put
`RefCell<T>` inside to get dynamically verified shared mutability. Now we have shared mutable data,
but it's shared in a way that there can only be one mutator (and no readers) or multiple readers.

Далее мы можем развить эту мысль и получить `Rc<RefCell<Vec<T>>>` или
`Rc<Vec<RefCell<T>>>`. Это — изменяемые, разделяемые между потоками вектора,
но они не одинаковы.

Now, we can take this a step further, and have `Rc<RefCell<Vec<T>>>` or `Rc<Vec<RefCell<T>>>`. These
are both shareable, mutable vectors, but they're not the same.

В первом типе `RefCell<T>` оборачивает `Vec<T>`, поэтому изменяем весь `Vec<T>`
целиком. В то же время, это значит, что в каждый момент времени может быть
только одна ссылка на `Vec<T>` с правом изменения. Поэтому код не может
одновременно работать с разными элементами вектора, обращаясь к ним через разные
`Rc`. Однако, мы сможем добавлять и удалять элементы вектора в произвольные
моменты времени. Этот тип похож на `&mut Vec<T>`, с тем различием, что проверка
заимствования делается во время исполнения.

With the former, the `RefCell<T>` is wrapping the `Vec<T>`, so the `Vec<T>` in its entirety is
mutable. At the same time, there can only be one mutable borrow of the whole `Vec` at a given time.
This means that your code cannot simultaneously work on different elements of the vector from
different `Rc` handles. However, we are able to push and pop from the `Vec<T>` at will. This is
similar to an `&mut Vec<T>` with the borrow checking done at runtime.

Во втором типе заимствуются отдельные элементы, а вектор в целом неизменяем.
Поэтому мы можем получить ссылки на отдельные элементы, но не можем добавлять
или удалять элементы. Это похоже на `&mut [T]`[^3], но, опять-таки, проверка
заимствования производится во время исполнения.

With the latter, the borrowing is of individual elements, but the overall vector is immutable. Thus,
we can independently borrow separate elements, but we cannot push or pop from the vector. This is
similar to an `&mut [T]`[^3], but, again, the borrow checking is at runtime.

В многопоточных программах возникает похожая ситуация с `Arc<Mutex<T>>`, который
обеспечивает разделяемое владение и одновременное изменение.

In concurrent programs, we have a similar situation with `Arc<Mutex<T>>`, which provides shared
mutability and ownership.

Когда вы читаете такой код, рассматривайте гарантии и накладные расходы каждого
вложенного типа шаг за шагом.

When reading code that uses these, go in step by step and look at the guarantees/costs provided.

Когда вы выбираете сложный тип, поступайте наоборот: решите, какие гарантии вам
нужны, и в каком «слое» сочетания они понадобятся. Например, если у вас стоит
выбор между `Vec<RefCell<T>>` и `RefCell<Vec<T>>`, найдите компромисс путём
рассуждений, как мы делали выше по тексту, и выберите нужный вам тип.

When choosing a composed type, we must do the reverse; figure out which guarantees we want, and at
which point of the composition we need them. For example, if there is a choice between
`Vec<RefCell<T>>` and `RefCell<Vec<T>>`, we should figure out the tradeoffs as done above and pick
one.

[^3]: `&[T]` и `&mut [T]` — это _срезы_; они состоят из указателя и длины, и
    могут ссылаться на часть вектора или массива. `&mut [T]` также позволяет
    изменять свои элементы, но его длину изменить нельзя.

[^3]: `&[T]` and `&mut [T]` are _slices_; they consist of a pointer and a length and can refer to a portion of a vector or array. `&mut [T]` can have its elements mutated, however its length cannot be touched.
