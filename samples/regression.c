#include <stdio.h>
#define MAXVAL 100

typedef struct Point { int x; int y; } Point;

int add(int a, int b) {
    Point p = { .x = a, .y = b };
    if (a >= b || a == 0) {
        return p.x + p.y;
    }
    return a * b;
}

int main(void) {
    int total = add(3, 5);
    printf("total = %d\n", total);
    return 0;
}
