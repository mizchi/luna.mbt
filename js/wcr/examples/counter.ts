/**
 * Example: Counter Web Component
 */

import { register, attrInt, attrString, attrBool, Signal } from '../src/index.js';

interface CounterProps {
  initial: number;
  label: string;
  disabled: boolean;
}

register<CounterProps>({
  tag: 'x-counter',

  attributes: [
    attrInt('initial', 0),
    attrString('label', 'Count'),
    attrBool('disabled', false),
  ],

  styles: `
    :host {
      display: block;
      font-family: system-ui, sans-serif;
    }
    .counter {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .label {
      font-weight: 500;
    }
    .value {
      font-size: 1.5em;
      min-width: 2em;
      text-align: center;
    }
    button {
      padding: 4px 12px;
      font-size: 1em;
      cursor: pointer;
    }
    button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
  `,

  template: (props) => `
    <div class="counter">
      <span class="label">${props.label}:</span>
      <button class="dec">-</button>
      <span class="value">${props.initial}</span>
      <button class="inc">+</button>
    </div>
  `,

  setup: (ctx) => {
    // Internal state derived from props
    const count = new Signal(ctx.props.initial.get());

    // Sync with external attribute changes
    const unsyncInitial = ctx.props.initial.subscribe(() => {
      count.set(ctx.props.initial.get());
    });

    // Bind value display
    const unbindValue = ctx.bind('.value', () => String(count.get()));

    // Bind disabled attribute
    const unbindDecDisabled = ctx.bindAttr('.dec', 'disabled', ctx.props.disabled);
    const unbindIncDisabled = ctx.bindAttr('.inc', 'disabled', ctx.props.disabled);

    // Bind label
    const unbindLabel = ctx.bind('.label', () => `${ctx.props.label.get()}:`);

    // Event handlers
    const unbindDec = ctx.on('.dec', 'click', () => {
      count.update(n => n - 1);
    });
    const unbindInc = ctx.on('.inc', 'click', () => {
      count.update(n => n + 1);
    });

    // Cleanup
    return () => {
      unsyncInitial();
      unbindValue();
      unbindDecDisabled();
      unbindIncDisabled();
      unbindLabel();
      unbindDec();
      unbindInc();
    };
  },
});
