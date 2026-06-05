// TruePink — Rust
use std::collections::HashMap;

#[derive(Debug)]
struct Cat {
    name: String,
    lives: u32,
}

impl Cat {
    fn new(name: &str) -> Self {
        Cat { name: name.to_string(), lives: 9 }
    }

    fn meow(&self, loud: bool) -> String {
        let msg = format!("{} says meow", self.name);
        if loud { msg.to_uppercase() } else { msg }
    }
}

const MAX: u32 = 100;

fn main() {
    let mut map: HashMap<&str, i32> = HashMap::new();
    map.insert("pink", 0xFF);
    let cat = Cat::new("Mochi");
    for i in 0..MAX {
        if i % 2 == 0 {
            println!("{}", cat.meow(true));
        }
    }
}
