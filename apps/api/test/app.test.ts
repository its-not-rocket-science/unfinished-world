import { describe, it, expect } from 'vitest';
import { buildApp } from '../src/app';

describe('api /hello/:name', () => {
  it('returns a greeting', async () => {
    const app = buildApp();
    const res = await app.inject({ method: 'GET', url: '/hello/Ada' });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ message: 'hello, Ada!' });
  });
});
