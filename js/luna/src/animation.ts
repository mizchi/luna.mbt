import * as core from "../../../_build/js/release/build/mizchi/luna/js/animation/animation.js";
import { cubicOut, toCss, type Easing } from "./easing";

export interface Rect {
  readonly left: number;
  readonly top: number;
  readonly width: number;
  readonly height: number;
}

export interface AnimationOptions extends Omit<KeyframeAnimationOptions, "easing"> {
  easing?: string | Easing;
  /** Number of intervals when sampling a function easing. Defaults to 100. */
  samples?: number;
  /** Respect the element's document's reduced-motion preference. Defaults to true. */
  respectReducedMotion?: boolean;
}

export interface FlipOptions {
  duration?: number | ((distance: number) => number);
  delay?: number;
  easing?: string | Easing;
  samples?: number;
  respectReducedMotion?: boolean;
}

/** Start a native animation. Importing this module is safe during SSR. */
export function animate(
  element: Element,
  keyframes: Keyframe[],
  options: AnimationOptions = {},
): Animation {
  const { easing = "linear", samples = 100, respectReducedMotion = true, ...timing } = options;
  return core.play(element, keyframes, {
    duration: 300,
    ...timing,
    easing: typeof easing === "function" ? toCss(easing, samples) : easing,
  }, respectReducedMotion) as Animation;
}

/** Capture layout before making a DOM update. */
export function measure(element: Element): Rect {
  return core.measure(element) as Rect;
}

/** Compute translation-only FLIP frames without accessing browser globals. */
export function flipFrames(from: Rect, to: Rect, transform = "none"): Keyframe[] {
  return core.flipFrames(from, to, transform) as Keyframe[];
}

/**
 * Animate a completed layout update from its previous rectangle.
 * Preserves the element's computed transform; does not compensate ancestor transforms
 * or animate width/height. Cancel an earlier FLIP before capturing a new final layout.
 */
export function flip(
  element: Element,
  { from, to = measure(element) }: { from: Rect; to?: Rect },
  options: FlipOptions = {},
): Animation {
  const { duration = 300, easing = cubicOut, ...timing } = options;
  const distance = Math.hypot(from.left - to.left, from.top - to.top);
  const transform = element.ownerDocument.defaultView!.getComputedStyle(element).transform;
  return animate(element, flipFrames(from, to, transform), {
    ...timing,
    duration: typeof duration === "function" ? duration(distance) : duration,
    easing,
    fill: "backwards",
  });
}
