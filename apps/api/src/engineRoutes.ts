import { FastifyInstance } from 'fastify';
import { Engine, GameState, buildContent } from '@unfinished-world/engine';
import { demoContent } from '@unfinished-world/engine';

type Session = { engine: Engine; state: GameState };
const sessions = new Map<string, Session>();
const makeId = () => Math.random().toString(36).slice(2, 10);

export async function registerEngineRoutes(app: FastifyInstance) {
    app.post('/engine/session', async () => {
        const id = makeId();
        const engine = new Engine(buildContent(demoContent));
        const state = new GameState(demoContent.start);
        sessions.set(id, { engine, state });
        return { id, view: engine.view(state) };
    });

    app.get('/engine/:id/view', async (req, reply) => {
        const { id } = req.params as { id: string };
        const s = sessions.get(id);
        if (!s) return reply.code(404).send({ error: 'no such session' });
        return { id, view: s.engine.view(s.state) };
    });

    app.post('/engine/:id/choose', async (req, reply) => {
        const { id } = req.params as { id: string };
        const { index } = (req.body ?? {}) as { index?: number };
        const s = sessions.get(id);
        if (!s) return reply.code(404).send({ error: 'no such session' });
        if (!Number.isInteger(index)) return reply.code(400).send({ error: 'index required' });
        return { id, view: s.engine.choose(s.state, Number(index)) };
    });
}
