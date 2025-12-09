# Default recipe
default: test

# Run all tests (MoonBit + Node)
test: test-moonbit test-node

# Run MoonBit tests
test-moonbit:
    moon test --target js

# Run Node.js tests
test-node: build
    cd packages/ui && npm test

# Build MoonBit
build:
    moon build --target js

# Clean build artifacts
clean:
    moon clean

# Format code
fmt:
    moon fmt

# Check formatting
check:
    moon check --target js
