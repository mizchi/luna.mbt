import { afterEach, describe, expect, it, vi } from "vitest";
import { animate, flip, flipFrames, measure } from "../src/animation";
import { cubicIn, cubicOut, backOut, toCss } from "../src/easing";

afterEach(() => {
  for (const animation of document.getAnimations()) animation.cancel();
  document.body.replaceChildren();
  vi.restoreAllMocks();
});

function box() {
  const node = document.createElement("div");
  node.style.cssText = "position:absolute;left:10px;top:20px;width:40px;height:30px;background:red";
  document.body.append(node);
  return node;
}

describe("native animation", () => {
  it("samples an easing once and exposes native controls", async () => {
    const node = box();
    const easing = vi.fn(cubicIn);
    const animation = animate(node, [{ opacity: 0 }, { opacity: 1 }], {
      duration: 1000, easing, fill: "both", respectReducedMotion: false,
    });
    expect(animation).toBeInstanceOf(Animation);
    animation.pause();
    await animation.ready;
    animation.currentTime = 500;
    expect(Number(getComputedStyle(node).opacity)).toBeCloseTo(0.125, 3);
    expect(easing).toHaveBeenCalledTimes(101);
    animation.reverse();
    await animation.ready;
    expect(animation.playbackRate).toBe(-1);
    animation.cancel();
  });

  it("preserves native completion and cancellation semantics", async () => {
    const node = box();
    const completed = animate(node, [{ opacity: 0 }, { opacity: 1 }]);
    completed.finish();
    await expect(completed.finished).resolves.toBe(completed);
    const cancelled = animate(node, [{ opacity: 0 }, { opacity: 1 }]);
    const rejection = expect(cancelled.finished).rejects.toMatchObject({ name: "AbortError" });
    cancelled.cancel();
    await rejection;
    expect(node.style.opacity).toBe("");
  });

  it("reduces duration and delay, with an explicit opt out", () => {
    vi.spyOn(window, "matchMedia").mockReturnValue({ matches: true } as MediaQueryList);
    const node = box();
    const frames = [{ opacity: 0 }, { opacity: 1 }];
    const animation = animate(node, frames, { duration: 1000, delay: 500, iterations: Infinity });
    expect(animation.effect!.getTiming()).toMatchObject({ duration: 0, delay: 0, iterations: 1 });
    const normal = animate(node, frames, { duration: 1000, respectReducedMotion: false });
    expect(normal.effect!.getTiming().duration).toBe(1000);
  });
});

describe("FLIP", () => {
  it("starts at the old position and finishes at the new layout", async () => {
    const node = box();
    const from = measure(node);
    node.style.left = "110px";
    node.style.top = "70px";
    const animation = flip(node, { from }, { duration: 1000, easing: "linear", respectReducedMotion: false });
    animation.pause();
    await animation.ready;
    animation.currentTime = 0;
    expect(node.getBoundingClientRect().left).toBeCloseTo(10);
    animation.currentTime = 500;
    expect(node.getBoundingClientRect().left).toBeCloseTo(60);
    animation.finish();
    await animation.finished;
    expect(node.getBoundingClientRect().left).toBeCloseTo(110);
    expect(node.style.transform).toBe("");
  });

  it("preserves an existing transform and supplies distance to duration", () => {
    const node = box();
    node.style.transform = "rotate(10deg)";
    const from = measure(node);
    node.style.left = "40px";
    node.style.top = "60px";
    const duration = vi.fn((_distance: number) => 200);
    const animation = flip(node, { from }, { duration });
    expect(duration.mock.calls[0][0]).toBeCloseTo(50);
    const frames = (animation.effect as KeyframeEffect).getKeyframes();
    expect(frames[0].transform).toContain("matrix(");
    animation.cancel();
    expect(node.style.transform).toBe("rotate(10deg)");
  });

  it("computes frames without a DOM element, including zero-size rectangles", () => {
    const rect = { left: 0, top: 0, width: 0, height: 0 };
    expect(flipFrames(rect, rect)).toEqual([
      { transform: "translate(0px, 0px)" }, { transform: "none" },
    ]);
  });
});

describe("CSS easing conversion", () => {
  it("produces supported CSS easing and preserves overshoot", () => {
    expect(toCss(t => t, 2)).toBe("linear(0, 0.5, 1)");
    expect(CSS.supports("animation-timing-function", toCss(backOut))).toBe(true);
    expect(backOut(0.7)).toBeGreaterThan(1);
    expect(cubicOut(0.5)).toBe(0.875);
  });

  it("rejects invalid sampling and nonfinite output", () => {
    for (const samples of [0, 1, 2.5, NaN, Infinity, 4097]) {
      expect(() => toCss(cubicOut, samples)).toThrow(RangeError);
    }
    expect(() => toCss(() => Infinity)).toThrow(RangeError);
    expect(() => toCss(() => NaN)).toThrow(RangeError);
  });
});
