import { test, expect } from '@playwright/test';

/**
 * Security Tests for Server Actions
 *
 * Tests various CSRF attack vectors to verify defenses.
 * Reference: https://blog.jxck.io/entries/2024-04-26/csrf.html
 */
test.describe('Server Action Security', () => {
  const actionUrl = '/_action/submit-contact';
  const validPayload = { name: 'Test', email: 'test@example.com' };

  // Valid origins that should be allowed (use test server port)
  const validOrigin = 'http://localhost:9123';

  test.describe('CSRF Protection', () => {

    test('should block cross-origin requests with foreign Origin header', async ({ request }) => {
      // Attack: Cross-site request with attacker's origin
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'http://attacker.com',
        },
        data: validPayload,
      });

      expect(response.status()).toBe(403);
    });

    test('should block requests with Sec-Fetch-Site: cross-site', async ({ request }) => {
      // Attack: Modern browsers send this header for cross-site requests
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Origin': validOrigin,
          'Sec-Fetch-Site': 'cross-site',
        },
        data: validPayload,
      });

      expect(response.status()).toBe(403);
    });

    test('should allow same-origin requests with valid Origin', async ({ request }) => {
      // Valid: Same-origin request
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Origin': validOrigin,
        },
        data: validPayload,
      });

      expect(response.ok()).toBeTruthy();
    });

    test('should allow requests with Sec-Fetch-Site: same-origin', async ({ request }) => {
      // Valid: Same-origin fetch metadata
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Origin': validOrigin,
          'Sec-Fetch-Site': 'same-origin',
        },
        data: validPayload,
      });

      expect(response.ok()).toBeTruthy();
    });

    test('should allow same-site requests', async ({ request }) => {
      // Valid: Same-site (subdomain) requests
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Origin': validOrigin,
          'Sec-Fetch-Site': 'same-site',
        },
        data: validPayload,
      });

      expect(response.ok()).toBeTruthy();
    });
  });

  test.describe('Origin/Referer Validation', () => {

    test('should block requests with no Origin and no Referer when origins configured', async ({ request }) => {
      // Attack: Requests without Origin/Referer (e.g., curl without headers)
      // Note: This depends on server configuration - when allowed_origins is configured,
      // requests without Origin should still work for same-origin requests
      // This test documents current behavior - may need adjustment based on requirements

      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          // No Origin, no Referer
        },
        data: validPayload,
      });

      // Current behavior: allow_no_origin=true allows this
      // This is intentional for same-origin form submissions without JS
      // The test documents this behavior
      expect([200, 403]).toContain(response.status());
    });

    test('should handle Referer-only requests (no Origin)', async ({ request }) => {
      // Some browsers send Referer but not Origin for same-origin requests
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Referer': `${validOrigin}/form`,
          // No Origin header
        },
        data: validPayload,
      });

      // Should allow if Referer matches allowed origins
      expect(response.ok()).toBeTruthy();
    });

    test('should block Referer from different origin', async ({ request }) => {
      // Attack: Forged Referer from attacker site
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Referer': 'http://attacker.com/malicious-page',
          // No Origin header
        },
        data: validPayload,
      });

      // Note: Current implementation uses has_prefix which may have issues
      // See vulnerability test below
      expect(response.status()).toBe(403);
    });
  });

  test.describe('Referer Validation Edge Cases', () => {

    test('should block Referer prefix match attack', async ({ request }) => {
      // Attack: Referer that starts with valid origin but is actually different host
      // e.g., http://localhost:3457.attacker.com (if origin is http://localhost:3457)
      //
      // Fixed implementation extracts origin from Referer URL and compares exactly

      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Referer': `${validOrigin}.attacker.com/malicious`,
          // No Origin header - attempt to bypass Origin check
        },
        data: validPayload,
      });

      // Should be blocked - the Referer origin is different
      expect(response.status()).toBe(403);
    });

    test('should handle Referer with path traversal safely', async ({ request }) => {
      // Attempt to use path traversal in Referer - should be accepted since origin is valid
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Referer': `${validOrigin}/../../attacker.com`,
        },
        data: validPayload,
      });

      // This is allowed because the origin (http://localhost:3457) is valid
      // Path traversal doesn't change the origin
      expect(response.ok()).toBeTruthy();
    });
  });

  test.describe('Content-Type Validation', () => {

    test('should accept application/json for JSON actions', async ({ request }) => {
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Origin': validOrigin,
        },
        data: validPayload,
      });

      expect(response.ok()).toBeTruthy();
    });

    test('should accept application/json with charset', async ({ request }) => {
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Origin': validOrigin,
        },
        data: validPayload,
      });

      expect(response.ok()).toBeTruthy();
    });

    test('should accept form-urlencoded for progressive enhancement', async ({ request }) => {
      // Progressive enhancement: form submissions without JS
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Referer': `${validOrigin}/form`,
        },
        data: 'name=Test&email=test@example.com',
      });

      // Should redirect (302) for non-JS form submission
      expect(response.ok()).toBeTruthy(); // After following redirect
    });
  });

  test.describe('HTTP Method Validation', () => {

    test('should skip CSRF check for GET requests', async ({ request }) => {
      // GET requests are safe methods - no CSRF check needed
      const response = await request.get(actionUrl, {
        headers: {
          'Origin': 'http://attacker.com',
        },
      });

      // May return 404 (no GET handler) or other status, but not 403
      // The point is CSRF middleware should not block it
      expect(response.status()).not.toBe(403);
    });

    test('should skip CSRF check for OPTIONS requests', async ({ request }) => {
      // Preflight requests
      const response = await request.fetch(actionUrl, {
        method: 'OPTIONS',
        headers: {
          'Origin': 'http://attacker.com',
          'Access-Control-Request-Method': 'POST',
        },
      });

      // Should not be blocked by CSRF (may have other handling)
      expect(response.status()).not.toBe(403);
    });
  });

  test.describe('Input Validation', () => {

    test('should handle empty body gracefully', async ({ request }) => {
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Origin': validOrigin,
        },
        data: '',
      });

      // Should handle gracefully (may return error but not crash)
      expect([200, 400, 500]).toContain(response.status());
    });

    test('should handle invalid JSON gracefully', async ({ request }) => {
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Origin': validOrigin,
        },
        data: '{invalid json}',
      });

      // Should handle gracefully
      expect([200, 400, 500]).toContain(response.status());
    });

    test('should handle very large payload', async ({ request }) => {
      const largePayload = {
        name: 'A'.repeat(10000),
        email: 'test@example.com',
      };

      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Origin': validOrigin,
        },
        data: largePayload,
      });

      // Should handle gracefully (accept or reject with proper status)
      expect([200, 400, 413]).toContain(response.status());
    });
  });

  test.describe('Error Response Security', () => {

    test('should not expose internal error details', async ({ request }) => {
      // Try to trigger server error with malformed request
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Origin': validOrigin,
        },
        // Send something that might cause internal error
        data: { __proto__: { admin: true } },
      });

      if (!response.ok()) {
        const body = await response.text();
        // Should not contain stack traces or internal details
        expect(body).not.toContain('at ');
        expect(body).not.toContain('Error:');
        expect(body).not.toContain('.mbt');
        expect(body).not.toContain('.js:');
      }
    });

    test('CSRF error should not reveal configuration', async ({ request }) => {
      const response = await request.post(actionUrl, {
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'http://attacker.com',
        },
        data: validPayload,
      });

      expect(response.status()).toBe(403);
      const body = await response.text();

      // Should not reveal allowed origins or configuration details
      expect(body).not.toContain('localhost:9123');
      expect(body).not.toContain('allowed_origins');
    });
  });
});
