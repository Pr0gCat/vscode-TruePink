// TruePink — Java
package com.truepink;

import java.util.List;
import java.util.ArrayList;

public class Hello {
    private static final int MAX = 100;
    private String name;

    public Hello(String name) {
        this.name = name;
    }

    public String greet(boolean loud) {
        String msg = "Hello, " + this.name;
        return loud ? msg.toUpperCase() : msg;
    }

    public static void main(String[] args) {
        List<String> names = new ArrayList<>();
        names.add("Mochi");
        for (int i = 0; i < MAX; i++) {
            if (i % 2 == 0) {
                System.out.println(new Hello(names.get(0)).greet(true));
            }
        }
    }
}
