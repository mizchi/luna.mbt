import { describe, test, expect } from "vitest";
import {
  createContext,
  provide,
  useContext,
  createRoot,
  createRenderEffect,
} from "../src/index";

describe("Context API", () => {
  describe("createContext", () => {
    test("creates a context with default value", () => {
      const ctx = createContext("default");
      expect(ctx).toBeDefined();
    });

    test("useContext returns default value when not provided", () => {
      const ctx = createContext("default-value");
      const value = useContext(ctx);
      expect(value).toBe("default-value");
    });

    test("useContext returns default for number", () => {
      const ctx = createContext(42);
      expect(useContext(ctx)).toBe(42);
    });

    test("useContext returns default for object", () => {
      const defaultObj = { name: "test", count: 0 };
      const ctx = createContext(defaultObj);
      expect(useContext(ctx)).toBe(defaultObj);
    });
  });

  describe("provide", () => {
    test("provides value within function scope", () => {
      const ctx = createContext("default");
      let capturedValue: string | undefined;

      provide(ctx, "provided-value", () => {
        capturedValue = useContext(ctx);
      });

      expect(capturedValue).toBe("provided-value");
    });

    test("value reverts after provide scope ends", () => {
      const ctx = createContext("default");

      provide(ctx, "inner", () => {
        expect(useContext(ctx)).toBe("inner");
      });

      // After provide scope, should return to default
      expect(useContext(ctx)).toBe("default");
    });

    test("nested provide overrides outer value", () => {
      const ctx = createContext("default");
      const values: string[] = [];

      provide(ctx, "outer", () => {
        values.push(useContext(ctx));

        provide(ctx, "inner", () => {
          values.push(useContext(ctx));
        });

        values.push(useContext(ctx));
      });

      expect(values).toEqual(["outer", "inner", "outer"]);
    });

    test("returns value from provided function", () => {
      const ctx = createContext(0);
      const result = provide(ctx, 10, () => {
        return useContext(ctx) * 2;
      });
      expect(result).toBe(20);
    });
  });

  describe("multiple contexts", () => {
    test("different contexts are independent", () => {
      const themeCtx = createContext("light");
      const langCtx = createContext("en");

      provide(themeCtx, "dark", () => {
        expect(useContext(themeCtx)).toBe("dark");
        expect(useContext(langCtx)).toBe("en");

        provide(langCtx, "ja", () => {
          expect(useContext(themeCtx)).toBe("dark");
          expect(useContext(langCtx)).toBe("ja");
        });
      });
    });
  });

  describe("context with reactive effects", () => {
    test("context value accessible in effect", () => {
      const ctx = createContext("initial");
      let effectValue: string | undefined;

      createRoot((dispose) => {
        provide(ctx, "effect-value", () => {
          createRenderEffect(() => {
            effectValue = useContext(ctx);
          });
        });
        dispose();
      });

      expect(effectValue).toBe("effect-value");
    });
  });
});
