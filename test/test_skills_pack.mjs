import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, cp, mkdir, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
const root = resolve(import.meta.dirname, '..');

test('portable pack builds deterministically and lints from an isolated extraction', async () => {
  const temp = await mkdtemp(join(tmpdir(), 'pte-pack-'));
  try {
    const { buildPack } = await import('../tools/build-skills.mjs');
    await buildPack(join(temp, 'a'));
    await buildPack(join(temp, 'b'));
    const zip = await readFile(join(temp, 'a/pte100-skills.zip'));
    assert.deepEqual(zip, await readFile(join(temp, 'b/pte100-skills.zip')));
    const unpack = spawnSync('unzip', ['-q', join(temp, 'a/pte100-skills.zip'), '-d', join(temp, 'clean')]);
    assert.equal(unpack.status, 0, unpack.stderr?.toString());
    const pack = join(temp, 'clean/pte100-skills');
    const manifest = JSON.parse(await readFile(join(pack, 'manifest.json'), 'utf8'));
    const { createHash } = await import('node:crypto');
    for (const [file, hash] of Object.entries(manifest.files)) {
      assert.equal(createHash('sha256').update(await readFile(join(pack, file))).digest('hex'), hash, file);
    }
    const installed = join(temp, 'project with spaces/.agents/skills');
    await mkdir(installed, { recursive: true });
    await cp(join(pack, 'skills'), installed, { recursive: true });
    const skill = join(installed, 'pte100-review');
    const lint = spawnSync(process.env.RUBY || 'ruby', [join(skill, 'runtime/bin/pte-lint'), 'check', join(skill, 'runtime/examples/procedure-pte.md'), '--config', join(skill, 'references/pilot-config.yaml'), '--format', 'json'], { cwd: temp });
    assert.equal(lint.status, 0, lint.stderr?.toString());
    assert.deepEqual(JSON.parse(lint.stdout).summary, { files: 1, errors: 0, warnings: 0, info: 0, suppressed: 0 });
    const synthetic = join(temp, 'document with spaces.md');
    await writeFile(synthetic, 'Use XYZ.\n');
    const cli = join(skill, 'runtime/bin/pte-lint');
    const config = join(skill, 'references/pilot-config.yaml');
    const run = (document, configuration = config) => spawnSync(process.env.RUBY || 'ruby', [cli, 'check', document, '--config', configuration, '--format', 'json'], { cwd: temp, timeout: 10000 });
    const findings = run(synthetic);
    assert.equal(findings.status, 1, findings.stderr?.toString());
    assert.ok(JSON.parse(findings.stdout).diagnostics.some(item => item.rule === 'R004'));
    assert.equal(await readFile(synthetic, 'utf8'), 'Use XYZ.\n');
    const missing = run(join(temp, 'missing.md'));
    assert.equal(missing.status, 3, missing.stderr?.toString());
    assert.match(missing.stderr.toString(), /Nenhum arquivo/);
    const invalidConfiguration = run(synthetic, join(temp, 'missing.yaml'));
    assert.equal(invalidConfiguration.status, 2, invalidConfiguration.stderr?.toString());
    const skills = ['pte100-review', 'pte100-pilot'];
    for (const name of skills) {
      const entry = await readFile(join(installed, name, 'SKILL.md'), 'utf8');
      assert.match(entry, new RegExp(`^---\\nname: ${name}\\n`));
      for (const [, target] of entry.matchAll(/\[[^\]]+\]\(([^)#]+)(?:#[^)]*)?\)/g)) {
        assert.ok(!target.startsWith('/') && !target.includes('..'), target);
        await readFile(join(installed, name, target));
      }
    }
  } finally { await rm(temp, { recursive: true, force: true }); }
});

test('site download uses base URL and build emits ZIP plus checksum', async () => {
  const page = await readFile(join(root, 'website/src/pages/index.astro'), 'utf8');
  assert.ok(page.includes('href={`${base}/downloads/pte100-skills.zip`}'));
  const copy = await readFile(join(root, 'website/scripts/copy-public.mjs'), 'utf8');
  assert.ok(copy.includes('buildPack'));
});
