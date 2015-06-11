% Плагины к компилятору

# Введение

`rustc`, компилятор Rust, поддерживает плагины. Плагины - это разработанные
пользователями библиотеки, которые добавляют новые возможности в компилятор: это
могут быть синтаксические расширения, дополнительные синтаксические анализы
(lints), и другое.

Плагин - это контейнер, собираемый в динамическую библиотеку, и имеющий
отдельную функцию для регистрации расширения в `rustc`. Другие контейнеры могут
загружать эти расширения с помощью атрибута `#![plugin(...)]`. Также смотрите
раздел [`rustc::plugin`](http://doc.rust-lang.org/rustc/plugin/index.html) с
подробным описанием механизма определения и загрузки плагина.

Передаваемые в `#![plugin(foo(... args ...))]` аргументы не обрабатываются самим
`rustc`. Они передаются плагину с помощью
[метода `args`](http://doc.rust-lang.org/rustc/plugin/registry/struct.Registry.html#method.args)
структуры `Registry`.

В подавляющем большинстве случаев плагин должен использоваться *только* через
конструкцию `#![plugin]`, а не через `extern crate`. Компоновка втащила бы
внутренние библиотеки `libsyntax` и `librustc` как зависимости для вашего
контейнера. Обычно это нежелательно, и может потребоваться только если вы
собираете ещё один, другой, плагин. Статический анализ `plugin_as_library`
проверяет выполннение этой рекомендации.

Обычная практика - помещать плагины в отдельный контейнер, не содержащий
определений макросов (`macro_rules!`) и обычного кода на Rust, который
предназначен для непосредственно конечных пользователей библиотеки.

# Syntax extensions

Plugins can extend Rust's syntax in various ways. One kind of syntax extension
is the procedural macro. These are invoked the same way as [ordinary
macros](macros.html), but the expansion is performed by arbitrary Rust
code that manipulates [syntax trees](http://doc.rust-lang.org/syntax/ast/index.html) at
compile time.

Let's write a plugin
[`roman_numerals.rs`](https://github.com/rust-lang/rust/tree/master/src/test/auxiliary/roman_numerals.rs)
that implements Roman numeral integer literals.

```ignore
#![crate_type="dylib"]
#![feature(plugin_registrar, rustc_private)]

extern crate syntax;
extern crate rustc;

use syntax::codemap::Span;
use syntax::parse::token;
use syntax::ast::{TokenTree, TtToken};
use syntax::ext::base::{ExtCtxt, MacResult, DummyResult, MacEager};
use syntax::ext::build::AstBuilder;  // trait for expr_usize
use rustc::plugin::Registry;

fn expand_rn(cx: &mut ExtCtxt, sp: Span, args: &[TokenTree])
        -> Box<MacResult + 'static> {

    static NUMERALS: &'static [(&'static str, u32)] = &[
        ("M", 1000), ("CM", 900), ("D", 500), ("CD", 400),
        ("C",  100), ("XC",  90), ("L",  50), ("XL",  40),
        ("X",   10), ("IX",   9), ("V",   5), ("IV",   4),
        ("I",    1)];

    let text = match args {
        [TtToken(_, token::Ident(s, _))] => token::get_ident(s).to_string(),
        _ => {
            cx.span_err(sp, "argument should be a single identifier");
            return DummyResult::any(sp);
        }
    };

    let mut text = &*text;
    let mut total = 0;
    while !text.is_empty() {
        match NUMERALS.iter().find(|&&(rn, _)| text.starts_with(rn)) {
            Some(&(rn, val)) => {
                total += val;
                text = &text[rn.len()..];
            }
            None => {
                cx.span_err(sp, "invalid Roman numeral");
                return DummyResult::any(sp);
            }
        }
    }

    MacEager::expr(cx.expr_u32(sp, total))
}

#[plugin_registrar]
pub fn plugin_registrar(reg: &mut Registry) {
    reg.register_macro("rn", expand_rn);
}
```

Then we can use `rn!()` like any other macro:

```ignore
#![feature(plugin)]
#![plugin(roman_numerals)]

fn main() {
    assert_eq!(rn!(MMXV), 2015);
}
```

The advantages over a simple `fn(&str) -> u32` are:

* The (arbitrarily complex) conversion is done at compile time.
* Input validation is also performed at compile time.
* It can be extended to allow use in patterns, which effectively gives
  a way to define new literal syntax for any data type.

In addition to procedural macros, you can define new
[`derive`](http://doc.rust-lang.org/reference.html#derive)-like attributes and other kinds of
extensions.  See
[`Registry::register_syntax_extension`](http://doc.rust-lang.org/rustc/plugin/registry/struct.Registry.html#method.register_syntax_extension)
and the [`SyntaxExtension`
enum](http://doc.rust-lang.org/syntax/ext/base/enum.SyntaxExtension.html).  For
a more involved macro example, see
[`regex_macros`](https://github.com/rust-lang/regex/blob/master/regex_macros/src/lib.rs).


## Tips and tricks

Some of the
[macro debugging tips](macros.html#%D0%9E%D1%82%D0%BB%D0%B0%D0%B4%D0%BA%D0%B0-%D0%BC%D0%B0%D0%BA%D1%80%D0%BE%D1%81%D0%BE%D0%B2)
are applicable.

You can use [`syntax::parse`](http://doc.rust-lang.org/syntax/parse/index.html) to turn token trees into
higher-level syntax elements like expressions:

```ignore
fn expand_foo(cx: &mut ExtCtxt, sp: Span, args: &[TokenTree])
        -> Box<MacResult+'static> {

    let mut parser = cx.new_parser_from_tts(args);

    let expr: P<Expr> = parser.parse_expr();
```

Looking through [`libsyntax` parser
code](https://github.com/rust-lang/rust/blob/master/src/libsyntax/parse/parser.rs)
will give you a feel for how the parsing infrastructure works.

Keep the [`Span`s](http://doc.rust-lang.org/syntax/codemap/struct.Span.html) of
everything you parse, for better error reporting. You can wrap
[`Spanned`](http://doc.rust-lang.org/syntax/codemap/struct.Spanned.html) around
your custom data structures.

Calling
[`ExtCtxt::span_fatal`](http://doc.rust-lang.org/syntax/ext/base/struct.ExtCtxt.html#method.span_fatal)
will immediately abort compilation. It's better to instead call
[`ExtCtxt::span_err`](http://doc.rust-lang.org/syntax/ext/base/struct.ExtCtxt.html#method.span_err)
and return
[`DummyResult`](http://doc.rust-lang.org/syntax/ext/base/struct.DummyResult.html),
so that the compiler can continue and find further errors.

To print syntax fragments for debugging, you can use
[`span_note`](http://doc.rust-lang.org/syntax/ext/base/struct.ExtCtxt.html#method.span_note) together
with
[`syntax::print::pprust::*_to_string`](http://doc.rust-lang.org/syntax/print/pprust/index.html#functions).

The example above produced an integer literal using
[`AstBuilder::expr_usize`](http://doc.rust-lang.org/syntax/ext/build/trait.AstBuilder.html#tymethod.expr_usize).
As an alternative to the `AstBuilder` trait, `libsyntax` provides a set of
[quasiquote macros](http://doc.rust-lang.org/syntax/ext/quote/index.html).  They are undocumented and
very rough around the edges.  However, the implementation may be a good
starting point for an improved quasiquote as an ordinary plugin library.


# Lint plugins

Plugins can extend [Rust's lint
infrastructure](http://doc.rust-lang.org/reference.html#lint-check-attributes) with additional checks for
code style, safety, etc. You can see
[`src/test/auxiliary/lint_plugin_test.rs`](https://github.com/rust-lang/rust/blob/master/src/test/auxiliary/lint_plugin_test.rs)
for a full example, the core of which is reproduced here:

```ignore
declare_lint!(TEST_LINT, Warn,
              "Warn about items named 'lintme'");

struct Pass;

impl LintPass for Pass {
    fn get_lints(&self) -> LintArray {
        lint_array!(TEST_LINT)
    }

    fn check_item(&mut self, cx: &Context, it: &ast::Item) {
        let name = token::get_ident(it.ident);
        if name.get() == "lintme" {
            cx.span_lint(TEST_LINT, it.span, "item is named 'lintme'");
        }
    }
}

#[plugin_registrar]
pub fn plugin_registrar(reg: &mut Registry) {
    reg.register_lint_pass(box Pass as LintPassObject);
}
```

Then code like

```ignore
#![plugin(lint_plugin_test)]

fn lintme() { }
```

will produce a compiler warning:

```txt
foo.rs:4:1: 4:16 warning: item is named 'lintme', #[warn(test_lint)] on by default
foo.rs:4 fn lintme() { }
         ^~~~~~~~~~~~~~~
```

The components of a lint plugin are:

* one or more `declare_lint!` invocations, which define static
  [`Lint`](http://doc.rust-lang.org/rustc/lint/struct.Lint.html) structs;

* a struct holding any state needed by the lint pass (here, none);

* a [`LintPass`](http://doc.rust-lang.org/rustc/lint/trait.LintPass.html)
  implementation defining how to check each syntax element. A single
  `LintPass` may call `span_lint` for several different `Lint`s, but should
  register them all through the `get_lints` method.

Lint passes are syntax traversals, but they run at a late stage of compilation
where type information is available. `rustc`'s [built-in
lints](https://github.com/rust-lang/rust/blob/master/src/librustc/lint/builtin.rs)
mostly use the same infrastructure as lint plugins, and provide examples of how
to access type information.

Lints defined by plugins are controlled by the usual [attributes and compiler
flags](http://doc.rust-lang.org/reference.html#lint-check-attributes), e.g. `#[allow(test_lint)]` or
`-A test-lint`. These identifiers are derived from the first argument to
`declare_lint!`, with appropriate case and punctuation conversion.

You can run `rustc -W help foo.rs` to see a list of lints known to `rustc`,
including those provided by plugins loaded by `foo.rs`.
