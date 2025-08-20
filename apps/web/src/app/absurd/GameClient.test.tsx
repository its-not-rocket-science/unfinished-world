import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import GameClient from './GameClient';

describe('GameClient', () => {
  beforeEach(() => localStorage.clear());

  it('renders start node and advances on a choice', async () => {
    render(<GameClient />);

    // initial node
    const heading = await screen.findByRole('heading', {
      name: /\[camus_start]\s+The Tower That Isn't There/i,
    });
    expect(heading).toBeInTheDocument();

    // click first visible choice
    const buttons = screen.getAllByRole('button');
    const choice = buttons.find(b =>
      within(b).queryByText(/Approach the Tower|Wander aimlessly|Sit and observe/i)
    );
    expect(choice).toBeTruthy();
    await userEvent.click(choice!);

    // moved to a new node
    const next = await screen.findByRole('heading', {
      name: /\[(camus_sandstorm|camus_oasis|camus_observe)]/i,
    });
    expect(next).toBeInTheDocument();
  });
});
