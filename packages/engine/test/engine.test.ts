import { describe, it, expect } from 'vitest';
import { Engine, GameState, buildContent } from '../src/core';
import { demoContent } from '../src/demo';

describe('engine basics', () => {
  it('starts and progresses', () => {
    const content = buildContent(demoContent);
    const engine = new Engine(content);
    const state = new GameState(content.start);

    const view0 = engine.view(state);
    expect(view0.node.id).toBe('camus_start');
    expect(view0.choices.length).toBeGreaterThan(0);

    // choose first visible option
    const next = engine.choose(state, view0.choices[0].index);
    expect(next.node.id).toBe('camus_sandstorm');
  });
});
