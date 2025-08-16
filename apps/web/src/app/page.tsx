import { greet } from "@unfinished-world/shared";

export default function Home() {
  return (
    <main style={{ padding: 24 }}>
      <h1>Web</h1>
      <p>{greet("web")}</p>
    </main>
  );
}
