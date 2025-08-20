// apps/web/src/app/absurd/GameClient.tsx
'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  Engine, GameState, buildContent, demoContent, type NodeView, statsLine
} from '@unfinished-world/engine';

const SAVE_KEY = 'absurd_path_save_v1';

type SaveSnap = ReturnType<GameState['snapshot']>;

function loadSnap(): SaveSnap | null {
  try { const raw = localStorage.getItem(SAVE_KEY); return raw ? JSON.parse(raw) : null; }
  catch { return null; }
}
function saveSnap(s: SaveSnap) { try { localStorage.setItem(SAVE_KEY, JSON.stringify(s)); } catch {} }
function clearSnap() { try { localStorage.removeItem(SAVE_KEY); } catch {} }

export default function GameClient() {
  const content = useMemo(() => buildContent(demoContent), []);
  const engine = useMemo(() => new Engine(content), [content]);

  const [state, setState] = useState<GameState | null>(null);
  const [view, setView] = useState<NodeView | null>(null);

  useEffect(() => {
    const snap = loadSnap();
    const s = snap ? GameState.fromSnapshot(snap) : new GameState(content.start);
    setState(s);
    setView(engine.view(s));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (!state || !view) return <p>Loading…</p>;

  const choose = (idx: number) => {
    const next = engine.choose(state, idx);
    setView({ ...next });
    saveSnap(state.snapshot());
  };

  const reset = () => {
    const fresh = new GameState(content.start);
    setState(fresh);
    setView(engine.view(fresh));
    clearSnap();
  };

  const save = () => saveSnap(state.snapshot());
  const load = () => {
    const snap = loadSnap();
    if (!snap) return;
    const loaded = GameState.fromSnapshot(snap);
    setState(loaded);
    setView(engine.view(loaded));
  };

  const statLine = statsLine(state);
  const flags = Object.keys(view.flags);

  return (
    <section style={{ display: 'grid', gap: 16, maxWidth: 760 }}>
      <header style={{ fontFamily: 'monospace', whiteSpace: 'pre-wrap' }}>
        {statLine}
        <div style={{ opacity: 0.8 }}>
          Flags: {flags.length ? flags.join(', ') : '(none)'}<br />
          Visited: {view.visited.slice(-6).join(', ')}
        </div>
      </header>

      <article>
        <h2 style={{ margin: '12px 0' }}>
          [{view.node.id}] {view.node.title ?? view.node.id}
        </h2>
        {view.node.body && <p style={{ lineHeight: 1.6 }}>{view.node.body}</p>}
      </article>

      {view.node.end ? (
        <div style={{ padding: 12, border: '1px solid #ddd', borderRadius: 8 }}>
          <strong>=== THE JOURNEY PAUSES HERE ===</strong>
          <Journal journal={view.journal} />
          <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
            <button onClick={reset}>Restart</button>
            <button onClick={save}>Save</button>
            <button onClick={load}>Load</button>
          </div>
        </div>
      ) : view.choices.length ? (
        <div style={{ display: 'grid', gap: 8 }}>
          {view.choices.map((c) => (
            <button
              key={c.index}
              onClick={() => choose(c.index)}
              style={{ textAlign: 'left', padding: 12, borderRadius: 8, border: '1px solid #ddd' }}
            >
              {c.text}
            </button>
          ))}
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={save}>Save</button>
            <button onClick={load}>Load</button>
            <button onClick={reset}>Restart</button>
          </div>
        </div>
      ) : (
        <em>No available choices. The world refuses to respond.</em>
      )}

      <Journal journal={view.journal} />
    </section>
  );
}

function Journal({ journal }: { journal: string[] }) {
  return (
    <details style={{ marginTop: 8 }}>
      <summary>Journal ({journal.length})</summary>
      {journal.length === 0 ? (
        <p style={{ opacity: 0.7 }}>(empty)</p>
      ) : (
        <ol style={{ marginTop: 8, paddingLeft: 20 }}>
          {journal.map((line, i) => (
            <li key={i}>{line}</li>
          ))}
        </ol>
      )}
    </details>
  );
}
