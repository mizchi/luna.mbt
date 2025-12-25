# @luna_ui/playwright-chaos

Playwright-based chaos testing library for web applications. Uses accessibility-aware weighted random actions to discover errors.

## Features

- **Accessibility-based targeting**: Uses ARIA roles and visible text to prioritize interactive elements
- **Weighted random actions**: Navigation links > buttons > inputs > scroll
- **External navigation blocking**: Prevents leaving the test domain
- **Error detection**: Console errors, network errors, JS exceptions, unhandled promise rejections
- **Performance metrics**: TTFB, FCP, LCP
- **Playwright Test integration**: Use as a fixture in your existing tests
- **CLI tool**: Standalone crawler for CI/CD pipelines

## Installation

```bash
pnpm add @luna_ui/playwright-chaos playwright @playwright/test
```

## Playwright Test Integration

### Basic Usage

```typescript
import { test, expect } from '@playwright/test';
import { chaosTest, chaosExpect } from '@luna_ui/playwright-chaos';

// Use the pre-configured chaosTest
chaosTest('chaos test homepage', async ({ page, chaos }) => {
  await page.goto('http://localhost:3000');
  const result = await chaos.testPage(page, page.url());

  // Assert no errors
  chaos.expectNoErrors(result);
  // Or use chaosExpect helpers
  chaosExpect.toHaveNoExceptions(result);
  chaosExpect.toLoadWithin(result, 3000);
});
```

### Extend Your Existing Tests

```typescript
import { test as base } from '@playwright/test';
import { withChaos, type ChaosFixtures } from '@luna_ui/playwright-chaos';

const test = base.extend<ChaosFixtures>(withChaos({
  maxActionsPerPage: 10,
  ignoreErrorPatterns: ['analytics', 'tracking'],
}));

test('my feature test', async ({ page, chaos }) => {
  await page.goto('/dashboard');
  // ... your test logic ...

  // Run chaos testing at the end
  const result = await chaos.testPage(page, page.url());
  expect(result.errors).toHaveLength(0);
});
```

### Crawl Multiple Pages

```typescript
chaosTest('crawl entire site', async ({ chaos }) => {
  const report = await chaos.crawl('http://localhost:3000');

  console.log(`Visited ${report.pagesVisited} pages`);
  console.log(`Found ${report.totalErrors} errors`);

  chaos.expectNoErrors(report);
});
```

## CLI Usage

```bash
# Basic crawl
chaos-crawler --url http://localhost:3000

# With analytics errors ignored (recommended for dev mode)
chaos-crawler --url http://localhost:3000 --ignore-analytics

# CI mode with strict checking
chaos-crawler --url http://localhost:3000 --strict --compact --ignore-analytics

# With screenshots
chaos-crawler --url https://docs.example.com --max-pages 20 --screenshots
```

### CLI Options

| Option | Description | Default |
|--------|-------------|---------|
| `--url <url>` | Base URL to crawl (required) | - |
| `--max-pages <n>` | Max pages to visit | 50 |
| `--max-actions <n>` | Max random actions per page | 5 |
| `--timeout <ms>` | Page load timeout | 30000 |
| `--headless` | Run in headless mode | true |
| `--no-headless` | Show browser window | - |
| `--screenshots` | Take screenshots | false |
| `--output <path>` | Output report path | chaos-report.json |
| `--exclude <pattern>` | Exclude URL patterns (regex) | - |
| `--ignore-error <pattern>` | Ignore error patterns (regex) | - |
| `--ignore-analytics` | Ignore common analytics errors | false |
| `--compact` | Compact output format | false |
| `--strict` | Exit with error on console errors | false |

## Action Weighting

Elements are selected with weighted probability based on:

| Element Type | Default Weight |
|--------------|----------------|
| Navigation links (in nav/header) | 4.5 (3 × 1.5) |
| Regular links | 3.0 |
| Buttons | 2.0 |
| ARIA interactive roles | 2.0 |
| Input fields | 1.0 |
| Scroll | 0.5 |

Elements with visible text get a 1.5x multiplier.

### Customize Weights

```typescript
const crawler = new ChaosCrawler({
  baseUrl: 'http://localhost:3000',
  actionWeights: {
    navigationLinks: 5,  // Prioritize nav links
    buttons: 3,
    inputs: 0.5,         // De-prioritize inputs
    scroll: 0.1,
  },
});
```

## Error Types Detected

- `console`: Console.error() calls
- `network`: Failed network requests
- `exception`: Uncaught JavaScript errors
- `unhandled-rejection`: Unhandled Promise rejections
- `crash`: Page crashes

## Report Format

```json
{
  "baseUrl": "http://localhost:3000",
  "duration": 12345,
  "pagesVisited": 20,
  "totalErrors": 2,
  "blockedExternalNavigations": 5,
  "pages": [
    {
      "url": "http://localhost:3000/",
      "status": "success",
      "loadTime": 500,
      "errors": [],
      "metrics": { "ttfb": 50, "fcp": 120 }
    }
  ],
  "summary": {
    "successPages": 20,
    "consoleErrors": 1,
    "jsExceptions": 1,
    "unhandledRejections": 0
  }
}
```

## License

MIT
