import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import Fastify from 'fastify';
import { registerEngineRoutes } from '../src/engineRoutes';

describe('engine routes', () => {
  let app: ReturnType<typeof Fastify>;

  beforeAll(async () => {
    app = Fastify();
    await registerEngineRoutes(app);
  });

  afterAll(async () => {
    await app.close();
  });

  it('creates a session and returns initial view', async () => {
    const res = await app.inject({ method: 'POST', url: '/engine/session' });
    expect(res.statusCode).toBe(200);
    const body = res.json() as any;
    expect(body.id).toBeTruthy();
    expect(body.view?.node?.id).toBe('camus_start');
  });

  it('progresses the session on choose', async () => {
    const start = await app.inject({ method: 'POST', url: '/engine/session' });
    const { id, view } = start.json() as any;

    const step = await app.inject({
      method: 'POST',
      url: `/engine/${id}/choose`,
      payload: { index: 0 },
    });

    expect(step.statusCode).toBe(200);
    const v2 = step.json().view;
    expect(v2.node.id).not.toBe(view.node.id);
  });

  it('404 for missing session', async () => {
    const res = await app.inject({ method: 'GET', url: '/engine/nope/view' });
    expect(res.statusCode).toBe(404);
  });

  it('400 when index is missing', async () => {
    const start = await app.inject({ method: 'POST', url: '/engine/session' });
    const { id } = start.json() as any;

    const res = await app.inject({
      method: 'POST',
      url: `/engine/${id}/choose`,
      payload: {}, // no index
    });
    expect(res.statusCode).toBe(400);
  });
});
