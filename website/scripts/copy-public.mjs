import { cp, mkdir, rm } from 'node:fs/promises';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '../..');
const dist = resolve(import.meta.dirname, '../dist');

await rm(resolve(dist, 'schemas'), { recursive: true, force: true });
await rm(resolve(dist, 'rules'), { recursive: true, force: true });
await mkdir(resolve(dist, 'schemas'), { recursive: true });
await mkdir(resolve(dist, 'rules'), { recursive: true });
await cp(resolve(root, 'schemas'), resolve(dist, 'schemas'), { recursive: true });
await cp(resolve(root, 'rules/catalog.md'), resolve(dist, 'rules/catalog.md'));
