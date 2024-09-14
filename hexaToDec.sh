#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2023-09-25 ######
##################################################################################

######### FUNCTIONS #########

# Function to convert hexadecimal to decimal
function hexaToDec {
  local hex="$1"
  local result=0
  local length=${#hex}

  for ((i = 0; i < length; i++)); do
    local digit="${hex:i:1}"
    local value

    case $digit in
      0) value=0 ;;
      1) value=1 ;;
      2) value=2 ;;
      3) value=3 ;;
      4) value=4 ;;
      5) value=5 ;;
      6) value=6 ;;
      7) value=7 ;;
      8) value=8 ;;
      9) value=9 ;;
      [Aa]) value=10 ;;
      [Bb]) value=11 ;;
      [Cc]) value=12 ;;
      [Dd]) value=13 ;;
      [Ee]) value=14 ;;
      [Ff]) value=15 ;;
      *)
        echo "Invalid hexadecimal digit: $digit"
        exit 1
        ;;
      esac

    result=$((result * 16 + value))
  done

  echo "$result"
}

# Check if the user provided an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <decimal_number>"
    exit 1
fi

hexadecimal_number="$1"
decimal=$(hexaToDec "$hexadecimal_number")

echo "Hexadecimal: $hexadecimal_number"
echo "Decimal: $decimal"

