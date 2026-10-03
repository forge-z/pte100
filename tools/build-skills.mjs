import { readFile, writeFile, readdir, mkdir, rm, stat } from 'node:fs/promises';
import { resolve, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { deflateRawSync } from 'node:zlib';

const root = resolve(import.meta.dirname, '..');
const packRoot = join(root, 'agent-skills');
const shared = ['spec', 'docs', 'rules', 'schemas', 'vocabulary', 'examples', 'LICENSE', 'NOTICE', 'ROADMAP.md'];
const mappings = [
  ...[...shared, 'bin', 'lib'].map(path => [path, `skills/pte100-review/runtime/${path}`]),
  ...shared.map(path => [path, `skills/pte100-pilot/references/pte/${path}`]),
];
// Include only the documented local references, not historical audits or private inputs.
const referenceFiles = new Set(['docs/conformance.md', 'docs/document-model.md', 'docs/locales.md', 'docs/grammar.md', 'docs/alerts.md', 'docs/vocabulary.md', 'docs/writing-for-ai.md', 'docs/design-principles.md', 'docs/architecture.md', 'docs/pte-lint.md']);
async function filesIn(directory, prefix = '') {
  const files = [];
  for (const entry of (await readdir(directory, { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name, 'en'))) {
    const path = join(prefix, entry.name);
    if (entry.isSymbolicLink()) throw new Error(`Symlink not allowed: ${path}`);
    if (entry.isDirectory()) files.push(...await filesIn(join(directory, entry.name), path));
    else if (entry.isFile()) files.push(path.replaceAll('\\', '/'));
  }
  return files;
}
async function sources() {
  const entries = [];
  for (const [source, target] of mappings) {
    if ((await stat(join(root, source))).isFile()) entries.push([source, target]);
    else for (const file of await filesIn(join(root, source))) {
      const path = `${source}/${file}`;
      if (source !== 'docs' || referenceFiles.has(path)) entries.push([path, `${target}/${file}`]);
    }
  }
  return entries;
}
async function snapshot(source, targets) {
  const data = await readFile(join(root, source));
  if (!source.endsWith('.md')) return data;
  // Preserve canonical prose; optional links outside the snapshot point to GitHub.
  const text = data.toString('utf8').replace(/(\[[^\]]*\]\()([^)]+)(\))/g, (match, opening, target, closing) => {
    if (/^[a-z][a-z0-9+.-]*:|^#/i.test(target)) return match;
    const [path, anchor] = target.split('#', 2);
    const canonical = resolve(root, dirname(source), path).slice(root.length + 1).replaceAll('\\', '/');
    if (targets.has(canonical)) return match;
    return `${opening}https://github.com/forge-z/pte100/blob/main/${canonical}${anchor ? '#' + anchor : ''}${closing}`;
  });
  return Buffer.from(text);
}
export async function syncSources() {
  await rm(join(packRoot, 'skills/pte100-review/runtime'), { recursive: true, force: true });
  await rm(join(packRoot, 'skills/pte100-pilot/references/pte'), { recursive: true, force: true });
  const entries = await sources();
  const targets = new Set(entries.map(([source]) => source));
  for (const [source, target] of entries) {
    await mkdir(resolve(packRoot, target, '..'), { recursive: true });
    await writeFile(join(packRoot, target), await snapshot(source, targets));
  }
}
async function validateSources() {
  const entries = await sources();
  const targets = new Set(entries.map(([source]) => source));
  for (const [source, target] of entries) {
    const a = await snapshot(source, targets);
    const b = await readFile(join(packRoot, target)).catch(() => null);
    if (!b || !a.equals(b)) throw new Error(`Stale skill snapshot: ${target}; run node tools/build-skills.mjs --sync`);
  }
  const expected = new Set(entries.map(([, target]) => target));
  for (const path of await filesIn(packRoot)) {
    if ((path.startsWith('skills/pte100-review/runtime/') || path.startsWith('skills/pte100-pilot/references/pte/')) && !expected.has(path)) throw new Error(`Unexpected snapshot file: ${path}`);
  }
}
function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function zip(entries) {
  const local = [], central = [];
  let offset = 0;
  for (const [path, data] of entries) {
    const name = Buffer.from(`pte100-skills/${path}`, 'utf8');
    const compressed = deflateRawSync(data, { level: 9 });
    const crc = crc32(data);
    const header = Buffer.alloc(30);
    header.writeUInt32LE(0x04034b50); header.writeUInt16LE(20, 4); header.writeUInt16LE(0x800, 6);
    header.writeUInt16LE(8, 8); header.writeUInt16LE(33, 12); // 1980-01-01, 00:00
    header.writeUInt32LE(crc, 14); header.writeUInt32LE(compressed.length, 18); header.writeUInt32LE(data.length, 22); header.writeUInt16LE(name.length, 26);
    local.push(header, name, compressed);
    const directory = Buffer.alloc(46);
    directory.writeUInt32LE(0x02014b50); directory.writeUInt16LE(0x314, 4); directory.writeUInt16LE(20, 6);
    directory.writeUInt16LE(0x800, 8); directory.writeUInt16LE(8, 10); directory.writeUInt16LE(33, 14);
    directory.writeUInt32LE(crc, 16); directory.writeUInt32LE(compressed.length, 20); directory.writeUInt32LE(data.length, 24); directory.writeUInt16LE(name.length, 28);
    directory.writeUInt32LE(0x81a40000, 38); directory.writeUInt32LE(offset, 42); // regular file, 0644
    central.push(directory, name); offset += header.length + name.length + compressed.length;
  }
  const index = Buffer.concat(central), end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50); end.writeUInt16LE(entries.length, 8); end.writeUInt16LE(entries.length, 10);
  end.writeUInt32LE(index.length, 12); end.writeUInt32LE(offset, 16);
  return Buffer.concat([...local, index, end]);
}
export async function buildPack(output) {
  await validateSources();
  const files = await filesIn(packRoot);
  const entries = await Promise.all(files.map(async path => [path, await readFile(join(packRoot, path))]));
  const manifest = { pack_version: '0.1.0', standard: 'PTE-100:0.1', engine_version: '0.1.0', license: 'Apache-2.0', files: Object.fromEntries(entries.map(([path, data]) => [path, createHash('sha256').update(data).digest('hex')])) };
  entries.push(['manifest.json', Buffer.from(JSON.stringify(manifest, null, 2) + '\n')]);
  entries.sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0);
  const archive = zip(entries);
  await mkdir(output, { recursive: true });
  await writeFile(join(output, 'pte100-skills.zip'), archive);
  await writeFile(join(output, 'pte100-skills.zip.sha256'), `${createHash('sha256').update(archive).digest('hex')}  pte100-skills.zip\n`);
  return manifest;
}
if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  const args = process.argv.slice(2);
  if (args.includes('--sync')) await syncSources();
  const out = args.indexOf('--out');
  if (out >= 0) { if (!args[out + 1]) throw new Error('--out requires a directory'); await buildPack(resolve(args[out + 1])); }
  if (!args.includes('--sync') && out < 0) throw new Error('Usage: node tools/build-skills.mjs --sync | --out DIRECTORY');
}
