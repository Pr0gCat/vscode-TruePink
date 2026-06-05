import os
from dataclasses import dataclass


@dataclass
class Cat:
    name: str = "Pinky"

    def greet(self) -> str:
        return f"Hi {self.name}".upper()


VALUE = 42
for i in range(VALUE):
    if i % 2 == 0:
        print(i, os.getpid())
