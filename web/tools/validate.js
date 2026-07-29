/* Offline check: run every handbook code block through the reader's markdown
 * parser and auto-harness, then compile the generated shader with
 * glslangValidator. Reports how many blocks the web reader can actually draw.
 *
 *   node web/tools/validate.js            # summary
 *   node web/tools/validate.js -v         # list every failing block
 */
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const vm = require('vm');
const { execFileSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..', '..');
const WEB = path.join(ROOT, 'web');
const BOOK = path.join(ROOT, 'shader-handbook');
const GLSLANG = path.join(ROOT, 'analysis', 'glslang', 'bin', 'glslangValidator.exe');

const verbose = process.argv.includes('-v');
const only = (process.argv.find(a => a.startsWith('--ch=')) || '').slice(5);

// Load the browser modules in a minimal sandbox.
const sandbox = { window: {}, console };
sandbox.window.window = sandbox.window;
vm.createContext(sandbox);
for (const f of ['js/md.js', 'js/glsl-lib.js']) {
  vm.runInContext(fs.readFileSync(path.join(WEB, f), 'utf8'), sandbox, { filename: f });
}
const { MD, GLSLLib } = sandbox.window;

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'shbk-'));
function compile(src) {
  const file = path.join(tmp, 'a.frag');
  fs.writeFileSync(file, src, 'utf8');
  try {
    execFileSync(GLSLANG, [file], { stdio: 'pipe' });
    return { ok: true };
  } catch (e) {
    const out = ((e.stdout || '') + (e.stderr || '')).toString().replace(file, '<gen>');
    return { ok: false, log: out.trim() };
  }
}

const manifest = JSON.parse(fs.readFileSync(path.join(WEB, 'manifest.json'), 'utf8'));
const stats = { total: 0, shader: 0, library: 0, fragment: 0, ok: 0, fail: 0, skipped: 0 };
const failures = [];

for (const ch of manifest.chapters) {
  if (only && ch.id.indexOf(only) < 0) continue;
  const src = fs.readFileSync(path.join(BOOK, ch.file), 'utf8');
  const res = MD.render(src, {});
  let chOk = 0, chTotal = 0;

  res.blocks.forEach((blk, i) => {
    if (blk.lang !== 'glsl') return;
    if (/^glsl-from:/.test(blk.marker)) { stats.skipped++; return; }
    stats.total++; chTotal++;

    const code = blk.code.replace(/\s+$/, '');
    const plan = GLSLLib.plan(code, blk.marker, null);
    stats[plan.kind]++;

    if (!plan.candidates.length) { stats.nopreview = (stats.nopreview || 0) + 1; stats.total--; chTotal--; return; }

    let ok = false, log = '';
    for (const cand of plan.candidates) {
      const r = compile(cand.src);
      if (r.ok) { ok = true; break; }
      log = r.log;
    }
    if (ok) { stats.ok++; chOk++; }
    else {
      stats.fail++;
      failures.push({ ch: ch.id, i, marker: blk.marker, kind: plan.kind, log, code });
    }
  });

  const pct = chTotal ? Math.round(chOk / chTotal * 100) : 100;
  console.log(`${String(pct).padStart(3)}%  ${String(chOk).padStart(3)}/${String(chTotal).padEnd(3)}  ${ch.id}`);
}

console.log('\n--- summary ---');
console.log(`blocks        ${stats.total}   (+${stats.skipped} example-file blocks run from disk)`);
console.log(`  full shader ${stats.shader}`);
console.log(`  library     ${stats.library}  (auto harness)`);
console.log(`  fragment    ${stats.fragment} (statement shell)`);
console.log(`renderable    ${stats.ok}  (${Math.round(stats.ok / stats.total * 100)}%)`);
console.log(`not runnable  ${stats.fail}`);

if (process.argv.includes('--top')) {
  const sig = {};
  failures.forEach(f => {
    const line = (f.log || '').split('\n').find(l => /ERROR/.test(l) && !/compilation errors/.test(l)) || '(none)';
    const key = line.replace(/^ERROR: \d+:\d+: /, '').replace(/'[^']*'/g, m => m.length > 20 ? "'…'" : m);
    sig[key] = (sig[key] || 0) + 1;
  });
  Object.entries(sig).sort((a, b) => b[1] - a[1]).slice(0, 30)
    .forEach(([k, v]) => console.log(String(v).padStart(4), k));
}

if (verbose) {
  const byKind = {};
  failures.forEach(f => { byKind[f.kind] = (byKind[f.kind] || 0) + 1; });
  console.log('\nfailures by kind:', byKind);
  failures.forEach(f => {
    console.log(`\n=== ${f.ch} #${f.i} [${f.marker || 'plain'}] ${f.kind}`);
    console.log(f.code.split('\n').slice(0, 6).join('\n'));
    console.log('--- ' + (f.log || '').split('\n').slice(0, 4).join('\n'));
  });
}

fs.rmSync(tmp, { recursive: true, force: true });
