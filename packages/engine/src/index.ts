// Re-export public API from core
export {
  Engine,
  GameState,
  buildContent,
  statsLine,
  condIsMet,
  choiceIsAvailable,
  applyEffect,
} from './core';

// Types
export type {
  NodeView,
} from './core';

export type {
  ContentDoc,
  NodeDef,
  Choice,
  Condition,
  Effect,
  StatKey,
} from './types';

// Demo content (handy for web)
export { demoContent } from './demo';
