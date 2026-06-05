"""TruePink syntax preview — Python."""
from __future__ import annotations

import os
import sys
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional

DEBUG = True
MAX_RETRY: int = 3


class Color(Enum):
    PINK = "#fd9999"
    BLUE = "#61aeee"


@dataclass
class Cat:
    """A pink cat with a name and nine lives."""

    name: str = "Pinky"
    lives: int = 9
    tags: list[str] = field(default_factory=list)

    def __post_init__(self) -> None:
        self._secret = f"{self.name}#{id(self)}"

    @property
    def alive(self) -> bool:
        return self.lives > 0

    async def meow(self, loud: bool = False) -> str:
        msg = f"{self.name} says meow"
        return msg.upper() if loud else msg


def fib(n: int) -> list[int]:
    a, b = 0, 1
    seq: list[int] = []
    while len(seq) < n:
        seq.append(a)
        a, b = b, a + b
    return seq


def classify(value: object) -> str:
    match value:
        case int() | float() if value > 0:
            return "positive number"
        case str() as s:
            return f"string of length {len(s)}"
        case _:
            return "unknown"


def main() -> None:
    cats = [Cat(name, lives=i) for i, name in enumerate(["Mochi", "Tofu"])]
    squares = {x: x ** 2 for x in range(0x10) if x % 2 == 0}
    total = sum(c.lives for c in cats)

    cats.sort(key=lambda c: c.lives, reverse=True)
    if (best := cats[0]) and best.alive:
        print(f"best cat is {best.name!r}", end="\n")

    with open(os.devnull, "w") as fp:
        fp.write(str(total))

    try:
        result = 10 / (total - total)
    except ZeroDivisionError as exc:
        print("oops:", exc, file=sys.stderr)
    else:
        print(result)
    finally:
        print(Color.PINK.value, DEBUG, squares, fib(5))


if __name__ == "__main__":
    main()
