#!/bin/bash

# Check if the user provided an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <decimal_number>"
    exit 1
fi

decimal_number="$1"

# Function to convert decimal to hexadecimal
decimal_to_hexadecimal() {
    local decimal="$1"
    local result=""
    local hex_digits=("0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D" "E" "F")

    while [ "$decimal" -gt 0 ]; do
        remainder=$((decimal % 16))
        result="${hex_digits[remainder]}$result"
        decimal=$((decimal / 16))
    done

    echo "$result"
}

hexadecimal=$(decimal_to_hexadecimal "$decimal_number")

echo "Decimal: $decimal_number"
echo "Hexadecimal: $hexadecimal"

