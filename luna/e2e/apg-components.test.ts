import { test, expect } from "@playwright/test";

/**
 * E2E Tests for APG Components
 *
 * Tests WAI-ARIA Authoring Practices Guide (APG) compliant components.
 * Based on patterns from https://www.w3.org/WAI/ARIA/apg/patterns/
 */

test.describe("APG Components", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/apg-playground");
    await page.waitForSelector(".main-content");
  });

  // ===========================================================================
  // SWITCH COMPONENT
  // ===========================================================================
  test.describe("Switch", () => {
    test.describe("ARIA Structure", () => {
      test('has role="switch"', async ({ page }) => {
        const switches = page.locator('#switch [role="switch"]');
        const count = await switches.count();
        expect(count).toBeGreaterThan(0);

        for (let i = 0; i < count; i++) {
          await expect(switches.nth(i)).toHaveAttribute("role", "switch");
        }
      });

      test("has aria-checked attribute", async ({ page }) => {
        const switches = page.locator('#switch [role="switch"]');
        const count = await switches.count();

        for (let i = 0; i < count; i++) {
          const ariaChecked = await switches.nth(i).getAttribute("aria-checked");
          expect(["true", "false"]).toContain(ariaChecked);
        }
      });

      test("has accessible name", async ({ page }) => {
        const switches = page.locator('#switch [role="switch"]');
        const count = await switches.count();

        for (let i = 0; i < count; i++) {
          const switchEl = switches.nth(i);
          const text = await switchEl.textContent();
          const ariaLabel = await switchEl.getAttribute("aria-label");
          const hasAccessibleName =
            (text && text.trim().length > 0) || ariaLabel !== null;
          expect(hasAccessibleName).toBe(true);
        }
      });
    });

    test.describe("Click Interaction", () => {
      test("toggles aria-checked on click", async ({ page }) => {
        const switchEl = page.locator('#switch [role="switch"]').first();
        const initialState = await switchEl.getAttribute("aria-checked");

        await switchEl.click();

        const newState = await switchEl.getAttribute("aria-checked");
        expect(newState).not.toBe(initialState);

        // Click again to toggle back
        await switchEl.click();
        const finalState = await switchEl.getAttribute("aria-checked");
        expect(finalState).toBe(initialState);
      });
    });

    test.describe("Keyboard Interaction", () => {
      test("toggles on Space key", async ({ page }) => {
        const switchEl = page.locator('#switch [role="switch"]').first();
        const initialState = await switchEl.getAttribute("aria-checked");

        await switchEl.focus();
        await page.keyboard.press("Space");

        const newState = await switchEl.getAttribute("aria-checked");
        expect(newState).not.toBe(initialState);
      });

      test("toggles on Enter key", async ({ page }) => {
        const switchEl = page.locator('#switch [role="switch"]').first();
        const initialState = await switchEl.getAttribute("aria-checked");

        await switchEl.focus();
        await page.keyboard.press("Enter");

        const newState = await switchEl.getAttribute("aria-checked");
        expect(newState).not.toBe(initialState);
      });

      test("is focusable via Tab", async ({ page }) => {
        // First scroll to the switch section
        await page.locator("#switch").scrollIntoViewIfNeeded();

        const switchEl = page.locator('#switch [role="switch"]').first();

        // Tab key should be able to reach the switch
        // Instead of looping through tabs, we verify the switch has tabindex="0"
        const tabindex = await switchEl.getAttribute("tabindex");
        expect(tabindex).toBe("0");
      });
    });

    test.describe("Disabled State", () => {
      test('disabled switch has aria-disabled="true"', async ({ page }) => {
        const disabledSwitch = page.locator(
          '#switch [role="switch"][aria-disabled="true"]'
        );

        if ((await disabledSwitch.count()) > 0) {
          await expect(disabledSwitch.first()).toHaveAttribute(
            "aria-disabled",
            "true"
          );
        }
      });

      test("disabled switch does not toggle on click", async ({ page }) => {
        const disabledSwitch = page.locator(
          '#switch [role="switch"][aria-disabled="true"]'
        );

        if ((await disabledSwitch.count()) > 0) {
          const initialState = await disabledSwitch
            .first()
            .getAttribute("aria-checked");
          await disabledSwitch.first().click({ force: true });
          const newState = await disabledSwitch
            .first()
            .getAttribute("aria-checked");
          expect(newState).toBe(initialState);
        }
      });
    });
  });

  // ===========================================================================
  // RADIO GROUP COMPONENT
  // ===========================================================================
  test.describe("Radio Group", () => {
    test.describe("ARIA Structure", () => {
      test('has role="radiogroup"', async ({ page }) => {
        const radiogroup = page.locator('#radio [role="radiogroup"]');
        await expect(radiogroup.first()).toHaveAttribute("role", "radiogroup");
      });

      test('has role="radio" for each option', async ({ page }) => {
        const radios = page.locator('#radio [role="radio"]');
        const count = await radios.count();
        expect(count).toBeGreaterThan(0);

        for (let i = 0; i < count; i++) {
          await expect(radios.nth(i)).toHaveAttribute("role", "radio");
        }
      });

      test("has aria-checked attribute", async ({ page }) => {
        const radios = page.locator('#radio [role="radio"]');
        const count = await radios.count();

        let checkedCount = 0;
        for (let i = 0; i < count; i++) {
          const ariaChecked = await radios.nth(i).getAttribute("aria-checked");
          expect(["true", "false"]).toContain(ariaChecked);
          if (ariaChecked === "true") checkedCount++;
        }
        // Only one should be checked
        expect(checkedCount).toBe(1);
      });
    });

    test.describe("Click Interaction", () => {
      test("selects radio on click", async ({ page }) => {
        const radios = page.locator('#radio [role="radio"]');

        // Click second radio
        await radios.nth(1).click();

        // Second should be checked
        await expect(radios.nth(1)).toHaveAttribute("aria-checked", "true");
        // First should be unchecked
        await expect(radios.nth(0)).toHaveAttribute("aria-checked", "false");
      });
    });

    test.describe("Keyboard Interaction", () => {
      test("ArrowDown moves to next radio and selects it", async ({
        page,
      }) => {
        const radios = page.locator(
          '#radio [role="radio"]:not([aria-disabled="true"])'
        );

        // Focus first radio
        await radios.first().focus();
        await expect(radios.first()).toHaveAttribute("aria-checked", "true");

        // Press ArrowDown
        await page.keyboard.press("ArrowDown");

        // Second radio should be selected and focused
        await expect(radios.nth(1)).toHaveAttribute("aria-checked", "true");
        await expect(radios.first()).toHaveAttribute("aria-checked", "false");
      });

      test("ArrowUp moves to previous radio and selects it", async ({
        page,
      }) => {
        const radios = page.locator(
          '#radio [role="radio"]:not([aria-disabled="true"])'
        );

        // First select second radio
        await radios.nth(1).click();
        await radios.nth(1).focus();

        // Press ArrowUp
        await page.keyboard.press("ArrowUp");

        // First radio should be selected
        await expect(radios.first()).toHaveAttribute("aria-checked", "true");
      });

      test("Home moves to first radio", async ({ page }) => {
        const radios = page.locator(
          '#radio [role="radio"]:not([aria-disabled="true"])'
        );

        // First select last radio
        await radios.nth(2).click();
        await radios.nth(2).focus();

        // Press Home
        await page.keyboard.press("Home");

        // First radio should be selected
        await expect(radios.first()).toHaveAttribute("aria-checked", "true");
      });

      test("End moves to last enabled radio", async ({ page }) => {
        const radios = page.locator(
          '#radio [role="radio"]:not([aria-disabled="true"])'
        );

        // Focus first radio
        await radios.first().focus();

        // Press End
        await page.keyboard.press("End");

        // Last enabled radio should be selected
        const lastEnabledIndex = (await radios.count()) - 1;
        await expect(radios.nth(lastEnabledIndex)).toHaveAttribute(
          "aria-checked",
          "true"
        );
      });

      test("Space selects focused radio", async ({ page }) => {
        const radios = page.locator(
          '#radio [role="radio"]:not([aria-disabled="true"])'
        );

        // Focus second radio (but don't click)
        await radios.nth(1).focus();

        // Press Space
        await page.keyboard.press("Space");

        // Second radio should be selected
        await expect(radios.nth(1)).toHaveAttribute("aria-checked", "true");
      });
    });
  });

  // ===========================================================================
  // ACCORDION COMPONENT
  // ===========================================================================
  test.describe("Accordion", () => {
    test.describe("ARIA Structure", () => {
      test("headers have aria-expanded attribute", async ({ page }) => {
        const headers = page.locator("#accordion [aria-expanded]");
        const count = await headers.count();
        expect(count).toBeGreaterThan(0);

        for (let i = 0; i < count; i++) {
          const expanded = await headers.nth(i).getAttribute("aria-expanded");
          expect(["true", "false"]).toContain(expanded);
        }
      });

      test("headers have aria-controls referencing panel", async ({ page }) => {
        const headers = page.locator("#accordion button[aria-expanded]");
        const count = await headers.count();

        for (let i = 0; i < count; i++) {
          const controls = await headers.nth(i).getAttribute("aria-controls");
          expect(controls).toBeTruthy();
          // Verify panel exists
          if (controls) {
            const panel = page.locator(`#${controls}`);
            await expect(panel).toHaveCount(1);
          }
        }
      });
    });

    test.describe("Click Interaction", () => {
      test("expands panel on header click", async ({ page }) => {
        const headers = page.locator("#accordion button[aria-expanded]");

        // Click first header (assuming initially collapsed or will toggle)
        await headers.first().click();

        // Should be expanded
        await expect(headers.first()).toHaveAttribute("aria-expanded", "true");
      });

      test("collapses panel on second click", async ({ page }) => {
        const headers = page.locator("#accordion button[aria-expanded]");

        // First click to expand
        await headers.first().click();
        await expect(headers.first()).toHaveAttribute("aria-expanded", "true");

        // Second click to collapse
        await headers.first().click();
        await expect(headers.first()).toHaveAttribute("aria-expanded", "false");
      });
    });

    test.describe("Keyboard Interaction", () => {
      test("Enter/Space toggles panel", async ({ page }) => {
        const headers = page.locator("#accordion button[aria-expanded]");

        await headers.first().focus();
        const initialState = await headers.first().getAttribute("aria-expanded");

        await page.keyboard.press("Enter");
        const newState = await headers.first().getAttribute("aria-expanded");
        expect(newState).not.toBe(initialState);

        await page.keyboard.press("Space");
        const finalState = await headers.first().getAttribute("aria-expanded");
        expect(finalState).toBe(initialState);
      });

      test("ArrowDown moves focus to next header", async ({ page }) => {
        const headers = page.locator("#accordion button[aria-expanded]");

        await headers.first().focus();
        await page.keyboard.press("ArrowDown");

        // Second header should be focused
        const secondId = await headers.nth(1).getAttribute("id");
        const activeId = await page.evaluate(
          () => document.activeElement?.getAttribute("id")
        );
        expect(activeId).toBe(secondId);
      });

      test("ArrowUp moves focus to previous header", async ({ page }) => {
        const headers = page.locator("#accordion button[aria-expanded]");

        await headers.nth(1).focus();
        await page.keyboard.press("ArrowUp");

        // First header should be focused
        const firstId = await headers.first().getAttribute("id");
        const activeId = await page.evaluate(
          () => document.activeElement?.getAttribute("id")
        );
        expect(activeId).toBe(firstId);
      });

      test("Home moves focus to first header", async ({ page }) => {
        const headers = page.locator("#accordion button[aria-expanded]");

        await headers.nth(2).focus();
        await page.keyboard.press("Home");

        // First header should be focused
        const firstId = await headers.first().getAttribute("id");
        const activeId = await page.evaluate(
          () => document.activeElement?.getAttribute("id")
        );
        expect(activeId).toBe(firstId);
      });

      test("End moves focus to last header", async ({ page }) => {
        const headers = page.locator("#accordion button[aria-expanded]");

        await headers.first().focus();
        await page.keyboard.press("End");

        // Last header should be focused
        const lastIndex = (await headers.count()) - 1;
        const lastId = await headers.nth(lastIndex).getAttribute("id");
        const activeId = await page.evaluate(
          () => document.activeElement?.getAttribute("id")
        );
        expect(activeId).toBe(lastId);
      });
    });
  });

  // ===========================================================================
  // DIALOG COMPONENT
  // ===========================================================================
  test.describe("Dialog", () => {
    test.describe("ARIA Structure", () => {
      test('has role="dialog"', async ({ page }) => {
        // Open dialog
        await page.locator("#dialog button").first().click();
        await page.waitForSelector('[role="dialog"]');

        const dialog = page.locator('[role="dialog"]');
        await expect(dialog).toHaveAttribute("role", "dialog");
      });

      test("has accessible label", async ({ page }) => {
        await page.locator("#dialog button").first().click();
        await page.waitForSelector('[role="dialog"]');

        const dialog = page.locator('[role="dialog"]');
        const ariaLabel = await dialog.getAttribute("aria-label");
        const ariaLabelledby = await dialog.getAttribute("aria-labelledby");

        const hasAccessibleName = ariaLabel !== null || ariaLabelledby !== null;
        expect(hasAccessibleName).toBe(true);
      });
    });

    test.describe("Focus Management", () => {
      test("focus moves into dialog on open", async ({ page }) => {
        await page.locator("#dialog button").first().click();
        await page.waitForSelector('[role="dialog"]');

        // Wait a bit for focus to move
        await page.waitForTimeout(100);

        // Focus should be inside dialog
        const activeElement = await page.evaluate(() => {
          const dialog = document.querySelector('[role="dialog"]');
          return dialog?.contains(document.activeElement);
        });
        expect(activeElement).toBe(true);
      });
    });

    test.describe("Keyboard Interaction", () => {
      test("Escape closes dialog", async ({ page }) => {
        await page.locator("#dialog button").first().click();
        await page.waitForSelector('[role="dialog"]');

        // Focus on the dialog for keydown event to work
        const dialog = page.locator('[role="dialog"]');
        await dialog.focus();

        await page.keyboard.press("Escape");

        // Dialog should be closed (not visible)
        await expect(page.locator('[role="dialog"]')).toHaveCount(0);
      });
    });
  });

  // ===========================================================================
  // TOOLTIP COMPONENT
  // ===========================================================================
  test.describe("Tooltip", () => {
    test.describe("ARIA Structure", () => {
      test('has role="tooltip"', async ({ page }) => {
        // Hover to show tooltip
        const trigger = page.locator("#tooltip .tooltip-wrapper").first();
        await trigger.hover();

        await page.waitForSelector('[role="tooltip"]');
        const tooltip = page.locator('[role="tooltip"]');
        await expect(tooltip).toHaveAttribute("role", "tooltip");
      });

      test("trigger has aria-describedby when tooltip is visible", async ({
        page,
      }) => {
        const trigger = page.locator("#tooltip .tooltip-wrapper button").first();
        await trigger.hover();

        await page.waitForSelector('[role="tooltip"]');
        const ariaDescribedby = await trigger.getAttribute("aria-describedby");
        expect(ariaDescribedby).toBeTruthy();
      });
    });

    test.describe("Interaction", () => {
      test("shows on hover", async ({ page }) => {
        const trigger = page.locator("#tooltip .tooltip-wrapper").first();

        // Initially no tooltip
        await expect(page.locator('[role="tooltip"]')).toHaveCount(0);

        // Hover to show
        await trigger.hover();
        await expect(page.locator('[role="tooltip"]')).toBeVisible();
      });

      test("shows on focus", async ({ page }) => {
        const trigger = page.locator("#tooltip .tooltip-wrapper button").first();

        // Focus to show
        await trigger.focus();
        await expect(page.locator('[role="tooltip"]')).toBeVisible();
      });

      test("hides on blur", async ({ page }) => {
        const trigger = page.locator("#tooltip .tooltip-wrapper button").first();

        // Focus to show
        await trigger.focus();
        await expect(page.locator('[role="tooltip"]')).toBeVisible();

        // Blur to hide
        await trigger.blur();
        await expect(page.locator('[role="tooltip"]')).toHaveCount(0);
      });
    });
  });

  // ===========================================================================
  // TABS COMPONENT
  // ===========================================================================
  test.describe("Tabs", () => {
    test.describe("ARIA Structure", () => {
      test('has role="tablist"', async ({ page }) => {
        const tablist = page.locator('#tabs [role="tablist"]');
        await expect(tablist.first()).toHaveAttribute("role", "tablist");
      });

      test('has role="tab" for each tab', async ({ page }) => {
        const tabs = page.locator('#tabs [role="tab"]');
        const count = await tabs.count();
        expect(count).toBeGreaterThan(0);
      });

      test("selected tab has aria-selected=true", async ({ page }) => {
        const tabs = page.locator('#tabs [role="tab"]');
        const count = await tabs.count();

        let selectedCount = 0;
        for (let i = 0; i < count; i++) {
          const selected = await tabs.nth(i).getAttribute("aria-selected");
          if (selected === "true") selectedCount++;
        }
        expect(selectedCount).toBe(1);
      });
    });

    test.describe("Keyboard Interaction", () => {
      // Note: Arrow key navigation for tabs is optional per APG.
      test("ArrowRight moves to next tab", async ({ page }) => {
        const tabs = page.locator('#tabs [role="tab"]');

        await tabs.first().focus();
        await page.keyboard.press("ArrowRight");

        // Second tab should be focused and selected
        await expect(tabs.nth(1)).toHaveAttribute("aria-selected", "true");
      });

      test("ArrowLeft moves to previous tab", async ({ page }) => {
        const tabs = page.locator('#tabs [role="tab"]');

        // First select second tab
        await tabs.nth(1).click();
        await tabs.nth(1).focus();

        await page.keyboard.press("ArrowLeft");

        // First tab should be selected
        await expect(tabs.first()).toHaveAttribute("aria-selected", "true");
      });
    });
  });

  // ===========================================================================
  // CHECKBOX COMPONENT
  // ===========================================================================
  test.describe("Checkbox", () => {
    test.describe("ARIA Structure", () => {
      test("checkboxes have proper role or input type", async ({ page }) => {
        const checkboxes = page.locator('#checkbox input[type="checkbox"]');
        const count = await checkboxes.count();
        expect(count).toBeGreaterThan(0);
      });
    });

    test.describe("Click Interaction", () => {
      test("toggles checked state on click", async ({ page }) => {
        // The styled checkbox uses a label that wraps the input
        // Click the checkbox root (label) element instead of the hidden input
        const checkboxRoot = page.locator("#checkbox .checkbox").first();
        const input = checkboxRoot.locator('input[type="checkbox"]');

        // Get initial state via aria-checked attribute (the input's aria state is controlled by the component)
        const initialAriaChecked = await input.getAttribute("aria-checked");

        // Click the checkbox root element
        await checkboxRoot.click();

        // Verify aria-checked state changed
        const newAriaChecked = await input.getAttribute("aria-checked");
        expect(newAriaChecked).not.toBe(initialAriaChecked);
      });
    });

    test.describe("Keyboard Interaction", () => {
      test("toggles on Space key", async ({ page }) => {
        const checkbox = page.locator('#checkbox input[type="checkbox"]').first();
        const initialChecked = await checkbox.isChecked();

        await checkbox.focus();
        await page.keyboard.press("Space");

        const newChecked = await checkbox.isChecked();
        expect(newChecked).not.toBe(initialChecked);
      });
    });
  });

  // ===========================================================================
  // DISCLOSURE COMPONENT
  // ===========================================================================
  test.describe("Disclosure", () => {
    test.describe("ARIA Structure", () => {
      test("button has aria-expanded attribute", async ({ page }) => {
        const button = page.locator("#disclosure button[aria-expanded]").first();
        const expanded = await button.getAttribute("aria-expanded");
        expect(["true", "false"]).toContain(expanded);
      });

      test("button has aria-controls", async ({ page }) => {
        const button = page.locator("#disclosure button[aria-expanded]").first();
        const controls = await button.getAttribute("aria-controls");
        expect(controls).toBeTruthy();
      });
    });

    test.describe("Interaction", () => {
      test("toggles content visibility on click", async ({ page }) => {
        const button = page.locator("#disclosure button[aria-expanded]").first();
        const initialExpanded = await button.getAttribute("aria-expanded");

        await button.click();

        const newExpanded = await button.getAttribute("aria-expanded");
        expect(newExpanded).not.toBe(initialExpanded);
      });

      test("toggles on Enter key", async ({ page }) => {
        const button = page.locator("#disclosure button[aria-expanded]").first();
        const initialExpanded = await button.getAttribute("aria-expanded");

        await button.focus();
        await page.keyboard.press("Enter");

        const newExpanded = await button.getAttribute("aria-expanded");
        expect(newExpanded).not.toBe(initialExpanded);
      });
    });
  });

  // ===========================================================================
  // GENERAL TESTS
  // ===========================================================================
  test.describe("General", () => {
    test("no console errors during component interaction", async ({ page }) => {
      const errors: string[] = [];
      page.on("console", (msg) => {
        if (msg.type() === "error") {
          errors.push(msg.text());
        }
      });

      // Interact with various components
      // Switch
      const switchEl = page.locator('#switch [role="switch"]').first();
      await switchEl.click();

      // Radio
      const radio = page.locator('#radio [role="radio"]').nth(1);
      await radio.click();

      // Accordion
      const accordion = page.locator("#accordion button[aria-expanded]").first();
      await accordion.click();

      // Dialog
      await page.locator("#dialog button").first().click();
      await page.waitForSelector('[role="dialog"]');
      await page.keyboard.press("Escape");

      expect(errors).toEqual([]);
    });
  });
});
