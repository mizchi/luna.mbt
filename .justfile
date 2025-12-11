# Default recipe
default: test

# Run all tests (MoonBit + Node)
test: test-moonbit test-vitest test-browser

test-browser: build
    pnpm test:browser


# Run MoonBit tests
test-moonbit:
    moon test src --target all
    moon test src/server/ssr --target all
    moon test src/browser --target js

# Run Node.js tests (vitest)
test-vitest: build
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
