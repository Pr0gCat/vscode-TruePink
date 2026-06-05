// TruePink syntax preview — TypeScript
import { readFile } from "fs";
import type { Buffer } from "buffer";

export interface Animal {
    name: string;
    legs: number;
}

export enum Color {
    Pink,
    Blue,
}

type Pair<T> = [T, T];

function sealed(target: Function): void {
    Object.seal(target);
}

@sealed
export class Cat<T> extends Object implements Animal {
    public name: string = "Pinky";
    private age: number = 3;
    legs: number = 4;

    constructor(name: string, age: number = 3) {
        super();
        this.name = name;
        this.age = age;
    }

    async greet(loud: boolean = false): Promise<string> {
        const message = `Hello, I am ${this.name}!`;
        if (loud && this.age >= 2) {
            return message.toUpperCase();
        }
        return message;
    }
}

const MAX = 100;
const values: number[] = [1, 2, 3, 0x1f, 3.14];
const double = (x: number): number => x * 2;

for (let i = 0; i < values.length; i++) {
    const v = values[i];
    if (v > MAX || v === null) {
        console.log("skip", v);
    } else {
        values[i] = double(v);
    }
}

const cat = new Cat<string>("Mochi", 5);
cat.greet(true).then((s) => console.log(s));
