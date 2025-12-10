# Default recipe
default: test

# Run all tests (MoonBit + Node)
test: test-moonbit test-node

# Run MoonBit tests
test-moonbit:
    moon test src --target all
    moon test src/ssr --target all
    moon test src/js/dom --target js

# Run Node.js tests (vitest)
test-node: build
    pnpm test

# Build MoonBit
build:
    moon build --target js
    pnpm build

# Clean build artifacts
clean:
    moon clean

# Format code
fmt:
    moon fmt
