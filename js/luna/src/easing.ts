// Numerical easing is implemented once in MoonBit and shared by both APIs.
import * as core from "../../../_build/js/release/build/mizchi/luna/easing/easing.js";

/** Maps normalized time [0, 1] to progress; overshoot is intentional. */
export type Easing = (t: number) => number;

export const linear: Easing = core.linear;
export const quadIn: Easing = core.quadIn;
export const quadOut: Easing = core.quadOut;
export const quadInOut: Easing = core.quadInOut;
export const cubicIn: Easing = core.cubicIn;
export const cubicOut: Easing = core.cubicOut;
export const cubicInOut: Easing = core.cubicInOut;
export const quartIn: Easing = core.quartIn;
export const quartOut: Easing = core.quartOut;
export const quartInOut: Easing = core.quartInOut;
export const quintIn: Easing = core.quintIn;
export const quintOut: Easing = core.quintOut;
export const quintInOut: Easing = core.quintInOut;
export const sineIn: Easing = core.sineIn;
export const sineOut: Easing = core.sineOut;
export const sineInOut: Easing = core.sineInOut;
export const circIn: Easing = core.circIn;
export const circOut: Easing = core.circOut;
export const circInOut: Easing = core.circInOut;
export const expoIn: Easing = core.expoIn;
export const expoOut: Easing = core.expoOut;
export const expoInOut: Easing = core.expoInOut;
export const backIn: Easing = core.backIn;
export const backOut: Easing = core.backOut;
export const backInOut: Easing = core.backInOut;
export const elasticIn: Easing = core.elasticIn;
export const elasticOut: Easing = core.elasticOut;
export const elasticInOut: Easing = core.elasticInOut;
export const bounceIn: Easing = core.bounceIn;
export const bounceOut: Easing = core.bounceOut;
export const bounceInOut: Easing = core.bounceInOut;

/** Approximate an easing with CSS linear() (samples = intervals, 2..4096). */
export function toCss(easing: Easing, samples = 100): string {
  if (!Number.isInteger(samples) || samples < 2 || samples > 4096) {
    throw new RangeError("samples must be an integer between 2 and 4096");
  }
  const result = core.toCss(easing, samples);
  if (result.$tag === 0) throw new RangeError("easing must return finite values");
  return result._0;
}
