import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import GameClient from './GameClient';

describe('GameClient actions', () => {
  beforeEach(() => localStorage.clear());

  it('save, load, restart flow', async () => {
    render(<GameClient />);
    await screen.findByRole('heading', { name: /\[camus_start]/i });

    await userEvent.click(screen.getByRole('button', { name: /save/i }));
    await userEvent.click(screen.getByRole('button', { name: /load/i }));
    await userEvent.click(screen.getByRole('button', { name: /restart/i }));

    // still renders a valid node after actions
    expect(await screen.findByRole('heading', { name: /\[camus_start]/i })).toBeInTheDocument();
  });
});
