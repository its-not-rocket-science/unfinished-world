// packages/engine/src/core.ts
import {
  STATS, StatKey, Condition, Effect, Choice, NodeDef,
  ContentDoc, GameStateSnapshot
} from './types';

export class GameState {
  current: string;
  stats: Record<StatKey, number> = {
    Absurdism: 0, Freedom: 0, Faith: 0, Stability: 0, SelfAffirmation: 0,
  };
  flags: Record<string, boolean> = {};
  visited: string[] = [];
  journal: string[] = [];
  constructor(current: string) { this.current = current; }
  snapshot(): GameStateSnapshot {
    return {
      current: this.current,
      stats: { ...this.stats },
      flags: { ...this.flags },
      visited: [...this.visited],
      journal: [...this.journal],
    };
  }
  static fromSnapshot(s: GameStateSnapshot): GameState {
    const gs = new GameState(s.current);
    gs.stats = s.stats; gs.flags = s.flags; gs.visited = s.visited; gs.journal = s.journal;
    return gs;
  }
}

export type Content = { start: string; nodes: Map<string, NodeDef> };

export function buildContent(doc: ContentDoc): Content {
  const nodes = new Map<string, NodeDef>();
  for (const n of doc.nodes) nodes.set(n.id, n);
  return { start: doc.start, nodes };
}

// rules
export function condIsMet(cond: Condition, state: GameState): boolean {
  if (cond.flag_set !== undefined) return !!state.flags[cond.flag_set];
  if (cond.flag_unset !== undefined) return !state.flags[cond.flag_unset];
  if (!cond.stat) return true;
  const lhs = state.stats[cond.stat] ?? 0;
  const rhs = cond.value ?? 0;
  switch (cond.op) {
    case '>': return lhs > rhs;
    case '>=': return lhs >= rhs;
    case '<': return lhs < rhs;
    case '<=': return lhs <= rhs;
    case '==': return lhs === rhs;
    case '!=': return lhs !== rhs;
    default: return false;
  }
}

export function choiceIsAvailable(choice: Choice, state: GameState): boolean {
  return (choice.conditions ?? []).every(c => condIsMet(c, state));
}

export function applyEffect(effect: Effect, state: GameState): void {
  if (effect.stat) state.stats[effect.stat] = (state.stats[effect.stat] ?? 0) + (effect.delta ?? 0);
  if (effect.set_flag) state.flags[effect.set_flag] = true;
  if (effect.clear_flag) delete state.flags[effect.clear_flag];
  if (effect.journal) state.journal.push(effect.journal);
}

export function statsLine(state: GameState): string {
  return STATS.map(k => `${k}:${(state.stats[k] ?? 0) >= 0 ? '+' : ''}${state.stats[k] ?? 0}`).join(' ');
}

// runtime
export type NodeView = {
  node: NodeDef;
  choices: { index: number; text: string }[];
  stats: Record<StatKey, number>;
  flags: Record<string, boolean>;
  visited: string[];
  journal: string[];
};

export class Engine {
  constructor(public content: Content) {}
  private getNode(id: string): NodeDef {
    const n = this.content.nodes.get(id);
    if (!n) throw new Error(`Missing node: ${id}`);
    return n;
  }
  private getAvailable(node: NodeDef, state: GameState) {
    return (node.choices ?? []).map((c, i) => ({ c, i })).filter(x => choiceIsAvailable(x.c, state));
  }
  view(state: GameState): NodeView {
    const node = this.getNode(state.current);
    if (!state.visited.includes(node.id)) state.visited.push(node.id);
    const available = this.getAvailable(node, state);
    return {
      node,
      choices: available.map(a => ({ index: a.i, text: a.c.text })),
      stats: { ...state.stats },
      flags: Object.fromEntries(Object.entries(state.flags).filter(([, v]) => !!v)),
      visited: [...state.visited],
      journal: [...state.journal],
    };
  }

  choose(state: GameState, choiceIndex: number): NodeView {
    const node = this.getNode(state.current);
    const available = this.getAvailable(node, state);
    const picked = available.find(a => a.i === choiceIndex);
    if (!picked) throw new Error(`Invalid choice index: ${choiceIndex}`);

    // NEW: ensure the current node is recorded as visited before moving on
    if (!state.visited.includes(node.id)) state.visited.push(node.id);

    for (const eff of (picked.c.effects ?? [])) applyEffect(eff, state);
    state.current = picked.c.next;

    // this will mark the NEW node as visited
    return this.view(state);
  }

}
