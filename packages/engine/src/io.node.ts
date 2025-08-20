// packages/engine/src/io.node.ts
import * as fs from 'node:fs';
import { GameState } from './core';
import type { GameStateSnapshot, ContentDoc } from './types';
import { buildContent } from './core';

export function saveToFile(state: GameState, savePath = 'savegame.json') {
  fs.writeFileSync(savePath, JSON.stringify(state.snapshot(), null, 2), 'utf8');
}
export function loadFromFile(savePath = 'savegame.json'): GameState | null {
  if (!fs.existsSync(savePath)) return null;
  const raw = fs.readFileSync(savePath, 'utf8');
  return GameState.fromSnapshot(JSON.parse(raw) as GameStateSnapshot);
}
export function loadContentFile(p: string) {
  const raw = fs.readFileSync(p, 'utf8');
  const doc: ContentDoc = JSON.parse(raw);
  return buildContent(doc);
}
