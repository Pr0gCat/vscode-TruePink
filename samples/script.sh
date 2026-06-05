#!/usr/bin/env bash
# TruePink — Shell
set -euo pipefail

NAME="${1:-Mochi}"
MAX=10

greet() {
    local loud="$1"
    if [[ "$loud" == "yes" ]]; then
        echo "HELLO ${NAME^^}"
    else
        echo "hello $NAME"
    fi
}

for i in $(seq 1 "$MAX"); do
    if (( i % 2 == 0 )); then
        greet "yes"
    fi
done
