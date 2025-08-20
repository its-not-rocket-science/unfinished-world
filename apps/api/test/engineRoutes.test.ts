import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import Fastify from 'fastify';
import { registerEngineRoutes } from '../src/engineRoutes';

describe('engine routes', () => {
  type NodeIdView = { node: { id: string } };
  type SessionStart = { id: string; view: NodeIdView };
  type ChooseResponse = { view: NodeIdView };

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
    const body = res.json() as SessionStart;
    expect(body.id).toBeTruthy();
    expect(body.view?.node?.id).toBe('camus_start');
  });

  it('progresses the session on choose', async () => {
    const start = await app.inject({ method: 'POST', url: '/engine/session' });
    const { id, view } = start.json() as SessionStart;

    const step = await app.inject({
      method: 'POST',
      url: `/engine/${id}/choose`,
      payload: { index: 0 },
    });

    expect(step.statusCode).toBe(200);
    const { view: v2 } = step.json() as ChooseResponse;
    expect(v2.node.id).not.toBe(view.node.id);
  });

  it('404 for missing session', async () => {
    const res = await app.inject({ method: 'GET', url: '/engine/nope/view' });
    expect(res.statusCode).toBe(404);
  });

  it('400 when index is missing', async () => {
    const start = await app.inject({ method: 'POST', url: '/engine/session' });
    const { id } = start.json() as SessionStart;

    const res = await app.inject({
      method: 'POST',
      url: `/engine/${id}/choose`,
      payload: {}, // no index
    });
    expect(res.statusCode).toBe(400);
  });
});
