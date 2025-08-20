#!/usr/bin/env node
import * as readline from 'node:readline';
import { Engine, GameState, statsLine } from './core';
import { loadContentFile } from './io.node';

function wrap(text: string, width = 78): string {
    if (!text) return '';
    const words = text.split(/\s+/);
    const lines: string[] = [];
    let line: string[] = [];
    let count = 0;
    for (const w of words) {
        const len = w.length + 1;
        if (count + len > width) { lines.push(line.join(' ')); line = [w]; count = len; }
        else { line.push(w); count += len; }
    }
    if (line.length) lines.push(line.join(' '));
    return lines.join('\n');
}

async function run(contentPath: string) {
    const content = loadContentFile(contentPath);
    const engine = new Engine(content);
    const state = new GameState(content.start);

    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    const ask = (q: string) => new Promise<string>(res => rl.question(q, res));
    try {
        while (true) {
            const view = engine.view(state);
            const node = view.node;

            console.log('\n' + '='.repeat(74));
            console.log('ABSURD PATH — Minimal TS Engine');
            console.log('='.repeat(74));
            console.log(statsLine(state));
            const activeFlags = Object.keys(view.flags);
            console.log('Flags:', activeFlags.length ? activeFlags.join(', ') : '(none)');
            console.log('Visited:', view.visited.slice(-6).join(', '));
            console.log('-'.repeat(74));

            console.log(`\n[${node.id}] ${node.title ?? node.id}\n`);
            if (node.body) console.log(wrap(node.body));

            if (node.end) {
                console.log('\n=== THE JOURNEY PAUSES HERE ===');
                console.log('Journal:\n' + (view.journal.map((l, i) => `  ${String(i + 1).padStart(2, '0')}. ${l}`).join('\n') || '  (empty)'));
                break;
            }

            if (!view.choices.length) {
                console.log('\nNo available choices. The world refuses to respond.');
                break;
            }

            view.choices.forEach((c, i) => console.log(`  ${i + 1}) ${c.text}`));
            console.log('  q) Quit');

            const sel = (await ask('\nChoose: ')).trim().toLowerCase();
            if (sel === 'q') { console.log('Goodbye.'); break; }

            const idx = Number(sel) - 1;
            const picked = Number.isFinite(idx) ? view.choices[idx] : undefined;
            if (!picked) { console.log('Invalid selection.'); continue; }
            engine.choose(state, picked.index);
        }
    } finally {
        rl.close();
    }
}

const contentPath = process.argv[2];
if (!contentPath) {
    console.error('Usage: absurd-path <content.json>');
    process.exit(1);
}
run(contentPath);
