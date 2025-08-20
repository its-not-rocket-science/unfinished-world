import Fastify from 'fastify';
import { greet } from '@unfinished-world/shared';
import { registerEngineRoutes } from './engineRoutes';

const app = Fastify();

app.get('/hello/:name', async (req) => {
  const name = (req.params as { name: string }).name;
  return { message: greet(name) };
});

await registerEngineRoutes(app);

const port = Number(process.env.PORT ?? 3001);
app.listen({ port, host: '0.0.0.0' }).then(() => {
  console.log(`api listening on http://localhost:${port}`);
});
