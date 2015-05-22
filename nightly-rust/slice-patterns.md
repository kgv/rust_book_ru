% Шаблоны `match` для срезов

Если вы хотите в качестве шаблона для сопоставления использовать срез или
массив, то вы можете использовать `&` и активировать фичу `slice_patterns`:

```rust
#![feature(slice_patterns)]

fn main() {
    let v = vec!["match_this", "1"];

    match &v[..] {
        ["match_this", second] => println!("The second element is {}", second),
        _ => {},
    }
}
```

