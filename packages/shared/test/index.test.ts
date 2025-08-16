import { describe, it, expect } from 'vitest';
import { greet } from '../src';

describe('shared/greet', () => {
  it('says hello', () => {
    expect(greet('web')).toBe('hello, web!');
  });
});
