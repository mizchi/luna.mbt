// @vitest-environment node
import { expect, it } from "vitest";
import { flipFrames } from "../src/animation";
import { cubicOut, toCss } from "../src/easing";

it("imports animation and computes frames/easing without DOM globals", () => {
  expect(typeof window).toBe("undefined");
  expect(typeof document).toBe("undefined");
  expect(cubicOut(0.5)).toBe(0.875);
  expect(toCss(t => t, 2)).toBe("linear(0, 0.5, 1)");
  const rect = { left: 0, top: 0, width: 10, height: 10 };
  expect(flipFrames(rect, { ...rect, left: 10 })[0].transform).toBe("translate(-10px, 0px)");
});
