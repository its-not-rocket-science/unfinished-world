import { describe, expect, it } from 'vitest';
import {
  Engine,
  GameState,
  buildContent,
  condIsMet,
  choiceIsAvailable,
  applyEffect,
  statsLine,
  type NodeView,
} from '../src/core';
import type { ContentDoc, Choice } from '../src/types';

describe('rules helpers', () => {
  it('condIsMet works for flags and comparisons', () => {
    const s = new GameState('start');
    s.stats.Absurdism = 2;
    s.flags['seen'] = true;

    expect(condIsMet({ flag_set: 'seen' }, s)).toBe(true);
    expect(condIsMet({ flag_unset: 'missing' }, s)).toBe(true);

    expect(condIsMet({ stat: 'Absurdism', op: '>', value: 1 }, s)).toBe(true);
    expect(condIsMet({ stat: 'Absurdism', op: '>=', value: 2 }, s)).toBe(true);
    expect(condIsMet({ stat: 'Absurdism', op: '<', value: 3 }, s)).toBe(true);
    expect(condIsMet({ stat: 'Absurdism', op: '<=', value: 2 }, s)).toBe(true);
    expect(condIsMet({ stat: 'Absurdism', op: '==', value: 2 }, s)).toBe(true);
    expect(condIsMet({ stat: 'Absurdism', op: '!=', value: 3 }, s)).toBe(true);

    // negative case
    expect(condIsMet({ stat: 'Absurdism', op: '>', value: 5 }, s)).toBe(false);
  });

  it('choiceIsAvailable + applyEffect update state', () => {
    const s = new GameState('x');
    const c: Choice = {
      text: 'gain + set + journal',
      next: 'y',
      conditions: [{ flag_unset: 'locked' }, { stat: 'Faith', op: '==', value: 0 }],
      effects: [{ stat: 'Faith', delta: 2 }, { set_flag: 'opened' }, { journal: 'did a thing' }],
    };
    expect(choiceIsAvailable(c, s)).toBe(true);
    applyEffect(c.effects![0], s);
    applyEffect(c.effects![1], s);
    applyEffect(c.effects![2], s);
    expect(s.stats.Faith).toBe(2);
    expect(s.flags.opened).toBe(true);
    expect(s.journal).toContain('did a thing');

    // clear_flag
    s.flags.temp = true;
    applyEffect({ clear_flag: 'temp' }, s);
    expect(s.flags.temp).toBeUndefined();
  });

  it('statsLine renders signed values', () => {
    const s = new GameState('start');
    s.stats.Absurdism = 1; s.stats.Stability = -2;
    const line = statsLine(s);
    expect(line).toMatch(/Absurdism:\+1/);
    expect(line).toMatch(/Stability:-2/);
  });
});

describe('Engine view/choose/visited', () => {
  const doc: ContentDoc = {
    start: 'a',
    nodes: [
      {
        id: 'a',
        title: 'A',
        choices: [
          { text: 'to b', next: 'b' },
          { text: 'hidden unless Freedom>=1', next: 'c', conditions: [{ stat: 'Freedom', op: '>=', value: 1 }] },
        ],
      },
      {
        id: 'b',
        title: 'B',
        choices: [{ text: 'effect then end', next: 'end', effects: [{ stat: 'Freedom', delta: 1 }] }],
      },
      { id: 'c', title: 'C', choices: [], end: true },
      { id: 'end', title: 'End', choices: [], end: true },
    ],
  };

  it('view lists available choices and tracks visited once', () => {
    const engine = new Engine(buildContent(doc));
    const s = new GameState('a');
    const v1 = engine.view(s);
    expect(v1.node.id).toBe('a');
    expect(v1.choices.map((x) => x.text)).toEqual(['to b']); // hidden second choice
    expect(s.visited).toEqual(['a']);

    const v2 = engine.view(s); // calling again shouldn’t duplicate visit
    expect(s.visited).toEqual(['a']);
  });

  it('choose applies effects, advances node, and reveals conditional paths', () => {
    const engine = new Engine(buildContent(doc));
    const s = new GameState('a');

    // pick the first choice (original index 0)
    let v = engine.choose(s, 0);
    expect(v.node.id).toBe('b');
    expect(s.visited).toEqual(['a', 'b']);

    // take the only choice on B; should increase Freedom and go to "end"
    v = engine.choose(s, 0);
    expect(v.node.id).toBe('end');
    expect(s.stats.Freedom).toBe(1);
  });

  it('invalid choice index throws', () => {
    const engine = new Engine(buildContent(doc));
    const s = new GameState('a');
    expect(() => engine.choose(s, 99)).toThrow(/Invalid choice/);
  });

  it('missing node throws', () => {
    const engine = new Engine(buildContent({ start: 'missing', nodes: [] }));
    const s = new GameState('missing');
    expect(() => engine.view(s)).toThrow(/Missing node/);
  });
});
