// apps/web/src/app/absurd/page.tsx
'use client';

import GameClient from './GameClient';

export default function AbsurdPage() {
  return (
    <main style={{ padding: 24 }}>
      <h1>Absurd Path</h1>
      <p style={{ opacity: 0.7, marginBottom: 16 }}>A tiny narrative engine demo.</p>
      <GameClient />
    </main>
  );
}

