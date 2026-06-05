// TruePink syntax preview — JavaScript
const fs = require("fs");

class Cat extends Object {
    constructor(name, age = 3) {
        super();
        this.name = name;
        this.age = age;
    }

    greet(loud = false) {
        const message = `Hello, I am ${this.name}!`;
        if (loud && this.age >= 2) {
            return message.toUpperCase();
        }
        return message;
    }
}

const MAX = 100;
const values = [1, 2, 3, 0x1f, 3.14];
const double = (x) => x * 2;

for (let i = 0; i < values.length; i++) {
    const v = values[i];
    if (v > MAX || v === null) {
        console.log("skip", v);
    } else {
        values[i] = double(v);
    }
}

const cat = new Cat("Mochi", 5);
cat.greet(true);
