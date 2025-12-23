import { test, expect } from "@playwright/test";

/**
 * E2E tests for Server Action functionality in examples/sol-app
 * Tests form submission with CSRF protection, validation, and response handling
 */
test.describe("Server Action", () => {
  const BASE_URL = "http://localhost:3457";

  test.describe("Form Page", () => {
    test("renders contact form page", async ({ page }) => {
      await page.goto(`${BASE_URL}/form`);
      await expect(page.locator("h1")).toContainText("Contact Form");
    });

    test("displays form fields", async ({ page }) => {
      await page.goto(`${BASE_URL}/form`);
      await expect(page.locator('input[name="name"]')).toBeVisible();
      await expect(page.locator('input[name="email"]')).toBeVisible();
      await expect(page.locator('button[type="submit"]')).toBeVisible();
    });

    test("shows live preview of input values", async ({ page }) => {
      await page.goto(`${BASE_URL}/form`);

      // Wait for hydration
      await page.waitForTimeout(500);

      // Type in fields
      await page.fill('input[name="name"]', "John Doe");
      await page.fill('input[name="email"]', "john@example.com");

      // Check preview updates
      await expect(page.locator(".preview-name")).toContainText("John Doe");
      await expect(page.locator(".preview-email")).toContainText(
        "john@example.com"
      );
    });
  });

  test.describe("Server Action Endpoint", () => {
    test("submit-contact action accepts valid data", async ({ request }) => {
      const response = await request.post(
        `${BASE_URL}/_action/submit-contact`,
        {
          headers: {
            "Content-Type": "application/json",
            Origin: "http://localhost:3000",
          },
          data: {
            name: "John Doe",
            email: "john@example.com",
          },
        }
      );

      expect(response.ok()).toBeTruthy();
      const json = await response.json();
      expect(json.success).toBe(true);
      expect(json.message).toContain("submitted successfully");
      expect(json.data.name).toBe("John Doe");
      expect(json.data.email).toBe("john@example.com");
    });

    test("submit-contact action validates required name", async ({
      request,
    }) => {
      const response = await request.post(
        `${BASE_URL}/_action/submit-contact`,
        {
          headers: {
            "Content-Type": "application/json",
            Origin: "http://localhost:3000",
          },
          data: {
            name: "",
            email: "john@example.com",
          },
        }
      );

      expect(response.status()).toBe(400);
      const json = await response.json();
      expect(json.error).toContain("Name is required");
    });

    test("submit-contact action validates required email", async ({
      request,
    }) => {
      const response = await request.post(
        `${BASE_URL}/_action/submit-contact`,
        {
          headers: {
            "Content-Type": "application/json",
            Origin: "http://localhost:3000",
          },
          data: {
            name: "John Doe",
            email: "",
          },
        }
      );

      expect(response.status()).toBe(400);
      const json = await response.json();
      expect(json.error).toContain("Email is required");
    });

    test("submit-contact action validates email format", async ({
      request,
    }) => {
      const response = await request.post(
        `${BASE_URL}/_action/submit-contact`,
        {
          headers: {
            "Content-Type": "application/json",
            Origin: "http://localhost:3000",
          },
          data: {
            name: "John Doe",
            email: "invalid-email",
          },
        }
      );

      expect(response.status()).toBe(400);
      const json = await response.json();
      expect(json.error).toContain("Invalid email format");
    });
  });

  test.describe("CSRF Protection", () => {
    test("rejects request without Origin header from different origin", async ({
      request,
    }) => {
      const response = await request.post(
        `${BASE_URL}/_action/submit-contact`,
        {
          headers: {
            "Content-Type": "application/json",
            Origin: "http://evil.com",
          },
          data: {
            name: "John Doe",
            email: "john@example.com",
          },
        }
      );

      expect(response.status()).toBe(403);
    });

    test("accepts request with valid Origin header", async ({ request }) => {
      const response = await request.post(
        `${BASE_URL}/_action/submit-contact`,
        {
          headers: {
            "Content-Type": "application/json",
            Origin: "http://localhost:3000",
          },
          data: {
            name: "John Doe",
            email: "john@example.com",
          },
        }
      );

      expect(response.ok()).toBeTruthy();
    });

    test("accepts same-origin request without Origin header", async ({
      request,
    }) => {
      // Same-origin requests may not include Origin header
      const response = await request.post(
        `${BASE_URL}/_action/submit-contact`,
        {
          headers: {
            "Content-Type": "application/json",
          },
          data: {
            name: "John Doe",
            email: "john@example.com",
          },
        }
      );

      // Should be accepted (same-origin)
      expect(response.ok()).toBeTruthy();
    });
  });

  test.describe("Form Submission Integration", () => {
    test("submits form and shows success message", async ({ page }) => {
      await page.goto(`${BASE_URL}/form`);

      // Wait for hydration
      await page.waitForTimeout(500);

      // Fill form
      await page.fill('input[name="name"]', "John Doe");
      await page.fill('input[name="email"]', "john@example.com");

      // Submit form
      await page.click('button[type="submit"]');

      // Wait for response
      await page.waitForTimeout(1000);

      // Check success message
      const result = page.locator('[data-testid="form-result"]');
      await expect(result).toContainText("submitted successfully");
    });

    test("shows error message for invalid data", async ({ page }) => {
      await page.goto(`${BASE_URL}/form`);

      // Wait for hydration
      await page.waitForTimeout(500);

      // Fill form with invalid email
      await page.fill('input[name="name"]', "John Doe");
      await page.fill('input[name="email"]', "invalid-email");

      // Submit form
      await page.click('button[type="submit"]');

      // Wait for response
      await page.waitForTimeout(1000);

      // Check error message
      const result = page.locator('[data-testid="form-result"]');
      await expect(result).toContainText("Invalid email format");
    });
  });
});
