import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import Home from './page';

describe('web Home page', () => {
  it('renders greeting from shared', () => {
    render(<Home />);
    expect(screen.getByText('hello, web!')).toBeInTheDocument();
  });
});
