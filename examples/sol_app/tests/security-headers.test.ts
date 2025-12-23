import { test, expect } from '@playwright/test';

/**
 * Security Headers Tests
 *
 * Tests for security headers identified by OWASP ZAP scan.
 * These headers protect against various web attacks.
 */
test.describe('Security Headers', () => {
  const pages = ['/', '/about', '/form', '/wc-counter'];

  for (const path of pages) {
    test.describe(`Page: ${path}`, () => {

      test('should have X-Frame-Options header (anti-clickjacking)', async ({ request }) => {
        const response = await request.get(path);
        const header = response.headers()['x-frame-options'];

        // Should be DENY or SAMEORIGIN
        expect(header).toBeTruthy();
        expect(['DENY', 'SAMEORIGIN', 'deny', 'sameorigin']).toContain(header?.toUpperCase());
      });

      test('should have X-Content-Type-Options header (MIME sniffing protection)', async ({ request }) => {
        const response = await request.get(path);
        const header = response.headers()['x-content-type-options'];

        expect(header?.toLowerCase()).toBe('nosniff');
      });

      test('should have Content-Security-Policy header', async ({ request }) => {
        const response = await request.get(path);
        const header = response.headers()['content-security-policy'];

        expect(header).toBeTruthy();
        // At minimum, should have default-src directive
        expect(header).toContain('default-src');
      });

      test('should have Permissions-Policy header', async ({ request }) => {
        const response = await request.get(path);
        const header = response.headers()['permissions-policy'];

        expect(header).toBeTruthy();
        // Should restrict dangerous features
      });

      test('should have Cross-Origin-Opener-Policy header (Spectre protection)', async ({ request }) => {
        const response = await request.get(path);
        const header = response.headers()['cross-origin-opener-policy'];

        expect(header).toBeTruthy();
        expect(['same-origin', 'same-origin-allow-popups']).toContain(header);
      });

      test('should have Referrer-Policy header', async ({ request }) => {
        const response = await request.get(path);
        const header = response.headers()['referrer-policy'];

        expect(header).toBeTruthy();
        // Recommended: strict-origin-when-cross-origin or no-referrer
        expect([
          'no-referrer',
          'strict-origin',
          'strict-origin-when-cross-origin',
          'same-origin'
        ]).toContain(header);
      });
    });
  }

  test.describe('Static assets', () => {
    test.skip('static JS files should have X-Content-Type-Options', async ({ request }) => {
      // TODO: Static files are served by Hono's static middleware, not our custom middleware
      // This requires configuring static file serving with security headers
      const response = await request.get('/static/loader.js');
      const header = response.headers()['x-content-type-options'];

      expect(header?.toLowerCase()).toBe('nosniff');
    });
  });

  test.describe('API endpoints', () => {
    test('API should have security headers', async ({ request }) => {
      const response = await request.get('/api/health');
      const headers = response.headers();

      expect(headers['x-content-type-options']?.toLowerCase()).toBe('nosniff');
    });

    test.skip('Server Action should have security headers', async ({ request }) => {
      // TODO: Server Actions use their own route registration with CSRF middleware
      // Need to add security headers to action routes separately
      const response = await request.post('/_action/submit-contact', {
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'http://localhost:3000',
        },
        data: { name: 'Test', email: 'test@example.com' },
      });

      const headers = response.headers();
      expect(headers['x-content-type-options']?.toLowerCase()).toBe('nosniff');
    });
  });

  test.describe('Cache-Control', () => {
    test('HTML pages should have appropriate cache headers', async ({ request }) => {
      const response = await request.get('/');
      const cacheControl = response.headers()['cache-control'];

      // HTML should not be cached or have short cache
      expect(cacheControl).toBeTruthy();
      // Should include no-cache, no-store, or max-age=0
      expect(
        cacheControl?.includes('no-cache') ||
        cacheControl?.includes('no-store') ||
        cacheControl?.includes('private') ||
        cacheControl?.includes('max-age=0')
      ).toBeTruthy();
    });

    test.skip('static assets can be cached', async ({ request }) => {
      // TODO: Static files served by Hono's static middleware
      const response = await request.get('/static/loader.js');
      const cacheControl = response.headers()['cache-control'];

      // Static assets can have longer cache
      // Just verify header exists
      expect(cacheControl).toBeTruthy();
    });
  });

  test.describe('Content-Security-Policy details', () => {
    test('CSP should restrict script sources', async ({ request }) => {
      const response = await request.get('/');
      const csp = response.headers()['content-security-policy'];

      expect(csp).toBeTruthy();

      // Should have script-src directive
      // Allow 'self' and possibly 'unsafe-inline' for inline scripts
      expect(csp).toMatch(/script-src[^;]*/);
    });

    test('CSP should restrict object sources', async ({ request }) => {
      const response = await request.get('/');
      const csp = response.headers()['content-security-policy'];

      expect(csp).toBeTruthy();

      // object-src should be 'none' to prevent Flash/plugin attacks
      expect(csp).toContain("object-src 'none'");
    });

    test('CSP should have frame-ancestors (replaces X-Frame-Options)', async ({ request }) => {
      const response = await request.get('/');
      const csp = response.headers()['content-security-policy'];

      expect(csp).toBeTruthy();

      // frame-ancestors restricts who can embed the page
      expect(csp).toMatch(/frame-ancestors[^;]*/);
    });
  });
});
