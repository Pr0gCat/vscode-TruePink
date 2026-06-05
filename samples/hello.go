// TruePink — Go
package main

import (
	"fmt"
	"strings"
)

const MaxLives = 9

type Cat struct {
	Name  string
	Lives int
}

func (c *Cat) Meow(loud bool) string {
	msg := fmt.Sprintf("%s says meow", c.Name)
	if loud {
		return strings.ToUpper(msg)
	}
	return msg
}

func main() {
	cat := &Cat{Name: "Mochi", Lives: MaxLives}
	nums := []int{1, 2, 3, 0xFF}
	for i, n := range nums {
		if n%2 == 0 {
			fmt.Println(i, cat.Meow(true))
		}
	}
}
