import { animate, flip, measure } from '@luna_ui/luna/animation';
import * as easing from '@luna_ui/luna/easing';
import type { Easing } from '@luna_ui/luna/easing';

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const select = $<HTMLSelectElement>('easing');
const duration = $<HTMLInputElement>('duration');
const position = $<HTMLInputElement>('position');
const speed = $<HTMLSelectElement>('speed');
const respectMotion = $<HTMLInputElement>('respect-motion');
const traveler = $('traveler');
const curves = Object.fromEntries(Object.entries(easing).filter(([name]) => name !== 'toCss')) as Record<string, Easing>;
for (const name of Object.keys(curves).sort()) select.add(new Option(name, name));
select.value = 'cubicOut';

let active: Animation | undefined;
let renderFrame = 0;
let flipped: Animation[] = [];
const media = matchMedia('(prefers-reduced-motion: reduce)');
const isReduced = () => respectMotion.checked && media.matches;
const milliseconds = () => Number(duration.value);
const currentFraction = () => {
  if (!active) return 0;
  if (isReduced()) return active.playState === 'finished' ? 1 : 0;
  return Math.max(0, Math.min(1, Number(active.currentTime ?? 0) / milliseconds()));
};

function render() {
  cancelAnimationFrame(renderFrame);
  const fraction = currentFraction();
  position.value = String(Math.round(fraction * 1000));
  $('progress').textContent = `${Math.round(fraction * 100)}%`;
  $('time').textContent = `${Math.round(fraction * milliseconds())} / ${milliseconds()} ms`;
  $('play-state').textContent = active?.playState ?? 'paused';
  $('direction').textContent = (active?.playbackRate ?? 1) < 0 ? '← Reverse' : '→ Forward';
  document.getElementById('curve-point')!.setAttribute('cx', String(40 + fraction * 240));
  document.getElementById('curve-point')!.setAttribute('cy', String(160 - curves[select.value](fraction) * 120));
  if (active?.playState === 'running' || active?.pending) renderFrame = requestAnimationFrame(render);
}

function refresh(fraction = 0) {
  active?.cancel();
  active = animate(traveler, [
    { transform: 'translateX(0px)' },
    { transform: `translateX(${traveler.parentElement!.clientWidth - 32}px)` },
  ], { duration: milliseconds(), easing: curves[select.value], fill: 'both', respectReducedMotion: respectMotion.checked });
  active.pause();
  active.currentTime = fraction * milliseconds();
  active.playbackRate = Number(speed.value);
  active.finished.then(render, () => {});
  $('duration-value').textContent = `${milliseconds()} ms`;
  $('curve-name').textContent = select.value;
  $('motion-preference').textContent = `prefers-reduced-motion: ${media.matches ? 'reduce' : 'no-preference'}`;
  const path = Array.from({ length: 101 }, (_, i) => {
    const t = i / 100;
    return `${i ? 'L' : 'M'}${40 + t * 240},${160 - curves[select.value](t) * 120}`;
  }).join(' ');
  document.getElementById('curve-path')!.setAttribute('d', path);
  $('example-code').textContent = `animate(element, keyframes, {\n  duration: ${milliseconds()},\n  easing: ${select.value},\n  fill: 'both'\n});`;
  render();
}

$('play').onclick = () => {
  if (!active || active.playState === 'finished') refresh();
  active!.playbackRate = Number(speed.value);
  active!.play();
  render();
};
$('pause').onclick = () => { active!.pause(); render(); };
$('reverse').onclick = () => {
  if (isReduced()) { active!.finish(); render(); return; }
  if (Number(active!.currentTime) <= 0) active!.currentTime = milliseconds();
  active!.reverse();
  active!.ready.then(render, () => {});
  render();
};
$('reset').onclick = () => refresh();
position.oninput = () => {
  const fraction = Number(position.value) / 1000;
  active!.pause();
  active!.currentTime = fraction * milliseconds();
  render();
};
select.onchange = () => refresh(currentFraction());
duration.oninput = () => refresh();
speed.onchange = () => {
  active!.playbackRate = Number(speed.value) * (active!.playbackRate < 0 ? -1 : 1);
  render();
};
respectMotion.onchange = () => refresh();
media.addEventListener('change', () => refresh());
window.addEventListener('resize', () => refresh(currentFraction()));

const cards = $('cards');
const palettes = [
  ['Orbit', '#eeecff', '#dcd7f9', '#7465ba'],
  ['Bloom', '#fcece9', '#f0d9d2', '#b47b70'],
  ['Tide', '#e7f2fa', '#d3e4f1', '#6491b0'],
  ['Moss', '#edf3e7', '#dce7d1', '#82916b'],
  ['Dawn', '#fff4db', '#f0e3c3', '#b49a59'],
  ['Cloud', '#f1ecf4', '#e4d9e9', '#9f83ad'],
];
palettes.forEach(([title, color, border, ink], index) => {
  const card = document.createElement('div');
  card.className = 'card';
  card.dataset.testid = 'flip-card';
  card.style.setProperty('--color', color);
  card.style.setProperty('--border', border);
  card.style.setProperty('--ink', ink);
  const number = document.createElement('span');
  number.className = 'card-number';
  number.textContent = String(index + 1).padStart(2, '0');
  const label = document.createElement('span');
  label.className = 'card-title';
  label.textContent = title;
  const mark = document.createElement('span');
  mark.className = 'card-mark';
  mark.setAttribute('aria-hidden', 'true');
  card.append(number, label, mark);
  cards.append(card);
});

function reorder(reverse: boolean) {
  // Capture visual positions before cancelling any previous FLIP. Measure the
  // final layout only after removing its effect so rapid clicks remain smooth.
  const elements = Array.from(cards.children) as HTMLElement[];
  const before = new Map(elements.map(element => [element, measure(element)]));
  flipped.forEach(animation => animation.cancel());
  if (reverse) elements.reverse();
  else {
    for (let i = elements.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [elements[i], elements[j]] = [elements[j], elements[i]];
    }
  }
  elements.forEach(element => cards.append(element));
  const after = new Map(elements.map(element => [element, measure(element)]));
  flipped = elements.map(element => flip(element, { from: before.get(element)!, to: after.get(element)! }, {
    duration: milliseconds(), easing: curves[select.value], respectReducedMotion: respectMotion.checked,
  }));
  const current = flipped;
  $('flip-status').textContent = '6 elements · animating';
  Promise.all(current.map(animation => animation.finished)).then(() => {
    if (flipped === current) $('flip-status').textContent = '6 elements · complete';
  }, () => {});
}
$('shuffle').onclick = () => reorder(false);
$('flip-order').onclick = () => reorder(true);
refresh();

window.addEventListener('pagehide', () => {
  cancelAnimationFrame(renderFrame);
  active?.cancel();
  flipped.forEach(animation => animation.cancel());
});
