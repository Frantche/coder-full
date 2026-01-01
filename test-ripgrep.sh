#!/bin/bash
# Functional test script for ripgrep
set -e

echo "============================================"
echo "Testing ripgrep (rg) functionality"
echo "============================================"

# Create a temporary test directory
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

cd "$TEST_DIR"

# Create test files
mkdir -p project/src
cat > project/src/main.js << 'EOF'
// Main application file
function helloWorld() {
    console.log("Hello, World!");
}

function helloUniverse() {
    console.log("Hello, Universe!");
}

module.exports = { helloWorld, helloUniverse };
EOF

cat > project/src/utils.js << 'EOF'
// Utility functions
function helperFunction() {
    return "helper";
}

function anotherHelper() {
    return "another";
}

module.exports = { helperFunction, anotherHelper };
EOF

cat > project/README.md << 'EOF'
# Test Project

This is a test project for ripgrep.

## Features
- Hello World functionality
- Helper functions
EOF

cat > project/.gitignore << 'EOF'
node_modules/
*.log
EOF

echo ""
echo "Test 1: Basic pattern search"
echo "------------------------------"
RESULT=$(rg "hello" project/ --no-heading)
if echo "$RESULT" | grep -q "helloWorld\|helloUniverse"; then
    echo "✓ PASS: Found 'hello' pattern in expected functions"
else
    echo "✗ FAIL: Could not find 'hello' pattern"
    echo "Output: $RESULT"
    exit 1
fi

echo ""
echo "Test 2: Case-insensitive search"
echo "--------------------------------"
RESULT=$(rg -i "HELLO" project/ --no-heading)
if echo "$RESULT" | grep -q "helloWorld"; then
    echo "✓ PASS: Case-insensitive search works"
else
    echo "✗ FAIL: Case-insensitive search failed"
    echo "Output: $RESULT"
    exit 1
fi

echo ""
echo "Test 3: File type filtering"
echo "----------------------------"
JS_COUNT=$(rg -t js "function" project/ --count | awk -F: '{sum+=$2} END {print sum}')
if [ "$JS_COUNT" -ge 4 ]; then
    echo "✓ PASS: Found $JS_COUNT function declarations in JavaScript files"
else
    echo "✗ FAIL: Expected at least 4 function declarations, found $JS_COUNT"
    exit 1
fi

echo ""
echo "Test 4: List files with matches"
echo "--------------------------------"
if rg -l "hello" project/ | grep -q "main.js"; then
    echo "✓ PASS: File listing works correctly"
else
    echo "✗ FAIL: Could not list files with matches"
    exit 1
fi

echo ""
echo "Test 5: Whole word search"
echo "-------------------------"
# Search for whole word "helper" (should match) but not partial matches
RESULT=$(rg -w "helper" project/ --no-heading)
if echo "$RESULT" | grep -q "helperFunction\|anotherHelper"; then
    echo "✓ PASS: Whole word search works"
else
    echo "✗ FAIL: Whole word search failed"
    echo "Output: $RESULT"
    exit 1
fi

echo ""
echo "Test 6: Regex pattern search"
echo "-----------------------------"
if rg "hello[A-Z][a-z]+" project/ --no-heading | grep -q "helloWorld"; then
    echo "✓ PASS: Regex pattern search works"
else
    echo "✗ FAIL: Regex pattern search failed"
    exit 1
fi

echo ""
echo "Test 7: Version check"
echo "---------------------"
VERSION=$(rg --version | head -1)
echo "ripgrep version: $VERSION"
if echo "$VERSION" | grep -q "ripgrep"; then
    echo "✓ PASS: Version check works"
else
    echo "✗ FAIL: Version check failed"
    exit 1
fi

echo ""
echo "Test 8: Help command"
echo "--------------------"
if rg --help | grep -q "USAGE:"; then
    echo "✓ PASS: Help command works"
else
    echo "✗ FAIL: Help command failed"
    exit 1
fi

echo ""
echo "============================================"
echo "All ripgrep tests passed! ✓"
echo "============================================"
