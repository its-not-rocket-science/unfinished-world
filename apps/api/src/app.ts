import Fastify from 'fastify';
import { greet } from '@unfinished-world/shared';

export function buildApp() {
  const app = Fastify();
  app.get('/hello/:name', async (req) => {
    const name = (req.params as { name: string }).name;
    return { message: greet(name) };
  });
  return app;
}
export type AppType = ReturnType<typeof buildApp>;
