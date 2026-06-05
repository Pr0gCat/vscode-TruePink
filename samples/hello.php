<?php
// TruePink — PHP
namespace App;

const MAX = 100;

class Cat
{
    private string $name;

    public function __construct(string $name = "Pinky")
    {
        $this->name = $name;
    }

    public function meow(bool $loud = false): string
    {
        $msg = "Hello, {$this->name}";
        return $loud ? strtoupper($msg) : $msg;
    }
}

$cat = new Cat("Mochi");
for ($i = 0; $i < MAX; $i++) {
    if ($i % 2 === 0) {
        echo $cat->meow(true) . PHP_EOL;
    }
}
