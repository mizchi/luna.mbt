---
title: Animation and easing
---

# Animation and easing

Luna provides numerical easing functions and helpers for the Web Animations API.
They are inspired by [Svelte's animate](https://svelte.dev/docs/svelte/svelte-animate)
and [easing](https://svelte.dev/docs/svelte/svelte-easing) modules. No Svelte runtime
or compiler is required.

## Interactive demo

From the repository root, run `just demo-animation` and open
<http://127.0.0.1:4179/animation.html>. The playground includes all 31 curves,
scrubbing, playback speed, reverse playback, reduced-motion handling, and FLIP
card reordering. It imports the actual npm entry points.

If build artifacts are missing, run `pnpm build:npm` first.
Run its Playwright checks with `just test-animation-demo`.

## TypeScript

```ts
import { animate, flip, measure } from '@luna_ui/luna/animation';
import { cubicOut } from '@luna_ui/luna/easing';

const animation = animate(element, [
  { opacity: 0, transform: 'translateY(12px)' },
  { opacity: 1, transform: 'translateY(0)' },
], { duration: 250, easing: cubicOut });

animation.pause();
animation.play();
await animation.finished;
```

The return value is the browser's native `Animation`. It supports `reverse()`,
`cancel()`, `currentTime`, `playbackRate`, `finished`, and other native APIs.
`animate` accepts an array of native `Keyframe` objects. Its options extend
`KeyframeAnimationOptions`, including delay, fill, iterations and direction.
Duration defaults to 300 milliseconds; fill defaults to the browser's `none`.
Use `fill: 'forwards'` explicitly if the effect should remain after completion.

Cancel animations when their owning component is disposed. Within a Luna owner:

```ts
import { onCleanup } from '@luna_ui/luna';

onCleanup(() => animation.cancel());
```

As with native WAAPI, cancelling rejects an observed `animation.finished` promise
with `AbortError`. Handle that rejection when awaiting an animation that may be
cancelled. Luna does not automatically register lifecycle cleanup or retain styles.

## Layout animation (FLIP)

Read all positions before a layout update, apply the update, read the new positions,
then start the animations. This separates layout reads from writes:

```ts
const before = new Map(items.map(element => [element, measure(element)]));
reorderItems(); // Complete the DOM update before continuing.
const after = new Map(items.map(element => [element, measure(element)]));
const animations = items.map(element => flip(element, {
  from: before.get(element)!,
  to: after.get(element)!,
}, {
  duration: distance => Math.min(500, Math.sqrt(distance) * 30),
  easing: cubicOut,
}));
```

`flip(element, { from, to? }, options?)` measures `to` if omitted. Its default is
300 milliseconds with `cubicOut` and backwards fill (the starting position applies
during a delay). It returns an `Animation` immediately, rather than a Svelte
`AnimationConfig`. There is no automatic keyed-list directive or enter/exit lifecycle.

FLIP animates **translation only**. It preserves the element's computed transform
and leaves inline styles unchanged. Width/height changes, transformed ancestors,
and concurrent animations of the same transform are not compensated. Use an
untransformed wrapper for those layouts. Cancel a previous FLIP before measuring
the final layout for another one. Changing layout during an animation requires
new measurements and a new animation.

`flipFrames(from, to, transform = 'none')` computes keyframes without accessing the
DOM. Pass these directly to `element.animate()` when managing timing yourself.
Rectangles contain `left`, `top`, `width`, and `height` in viewport pixels.

## Easing and native CSS timing

The easing module exports `linear` and In/Out/InOut variants of `quad`, `cubic`,
`quart`, `quint`, `sine`, `circ`, `expo`, `back`, `elastic`, and `bounce`:

```ts
import { backOut, toCss } from '@luna_ui/luna/easing';

backOut(0.7); // Progress can exceed 1 for overshooting curves.
element.animate([{ opacity: 0 }, { opacity: 1 }], {
  duration: 300,
  easing: toCss(backOut),
});
```

Easing functions take normalized time in `[0, 1]`. `toCss(easing, samples = 100)`
approximates a function with CSS `linear()` stops. Samples is an integer number of
intervals between 2 and 4096; nonfinite function output is rejected. More samples
improve approximation at the cost of a longer timing string. Overshoot is preserved.

`animate` and `flip` accept either a CSS easing string or a numerical function.
Functions are sampled once when starting; the browser interpolates subsequent
frames. Pass `samples` to control precision. Browsers must support CSS `linear()`
for function easing; a CSS string such as `'ease-out'` uses native timing directly.
There is no requestAnimationFrame polyfill.

## MoonBit

Import `mizchi/luna/easing` and `mizchi/luna/js/animation` in `moon.pkg`:

```moonbit
import {
  "mizchi/luna/easing",
  "mizchi/luna/js/animation",
  "mizchi/js_browser/dom",
}
```

```moonbit
fn reveal(element : @dom.Element) -> @animation.Animation raise {
  @animation.animate(element, [
    @animation.Keyframe::new().set(Opacity, "0"),
    @animation.Keyframe::new().set(Opacity, "1"),
  ], duration=250.0, easing=@easing.cubic_out)
}
```

`Keyframe::set` accepts Luna's typed CSS `Property` enum and returns a new frame.
Values use CSS strings. `offset` returns a frame with an explicit normalized offset.
`animate` accepts duration, delay, numerical easing, fill (`None`, `Forwards`,
`Backwards`, `Both`), and `respect_reduced_motion`.

For native CSS easing, construct `Options::new(easing="ease-out")` and call
`play(element, frames, options)`. `measure(element)` captures a `Rect`;
`flip(element, from)` animates after the layout update. `flip_frames(from, to,
transform)` computes the same keyframes used by TypeScript.

Animation methods include `pause`, `play`, `reverse`, `cancel`, `finish`, and
`seek(milliseconds)`. `finished()` returns `mizchi/js/core.Promise[Animation]`,
which can be awaited with `.wait()` in an async function.

## SSR and reduced motion

Both npm modules can be imported during SSR. Easing and `flipFrames` are DOM-free;
measurement and playback require a browser element and should run after mounting.
The MoonBit `easing` package is independent of DOM APIs and supports all targets;
`js/animation` targets JavaScript.

Playback respects `prefers-reduced-motion: reduce` in the element's document by
default, using zero duration and delay and a single iteration. Preferences are read
at animation creation, not watched during playback. Set `respectReducedMotion:
false` (MoonBit: `respect_reduced_motion=false`) to opt out explicitly. The direct
`element.animate()` examples use native behavior and do not apply this preference.
