#!/bin/bash

# Test script to validate init.sh improvements
echo "Testing init.sh script improvements..."

# Test 1: Check syntax
echo "1. Checking bash syntax..."
if bash -n init.sh; then
    echo "✅ Syntax check passed"
else
    echo "❌ Syntax errors found"
    exit 1
fi

# Test 2: Check for undefined variables
echo "2. Checking for common variable issues..."
if grep -n "base_model" init.sh | head -5; then
    echo "✅ base_model references found"
else
    echo "❌ base_model variable not found"
fi

# Test 3: Check function definitions
echo "3. Checking function definitions..."
functions=("display_header" "loading_animation" "fine_tune_model" "check_or_install_ollama" "check_fine_tune_model" "ollama_chat" "show_menu" "check_script_exists")

for func in "${functions[@]}"; do
    if grep -q "^$func()" init.sh || grep -q "^function $func" init.sh; then
        echo "✅ Function $func defined"
    else
        echo "❌ Function $func not found"
    fi
done

# Test 4: Check for improved error handling
echo "4. Checking error handling improvements..."
error_patterns=("return 1" "exit_code" "|| -z" "\[[ -z")
for pattern in "${error_patterns[@]}"; do
    if grep -q "$pattern" init.sh; then
        echo "✅ Error handling pattern '$pattern' found"
    else
        echo "⚠️  Error handling pattern '$pattern' not found"
    fi
done

echo "Test completed!"
