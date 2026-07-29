/* Print the generated shader for one handbook block.
 *   node web/tools/dump.js 02- 5          # chapter id prefix, block index
 *   node web/tools/dump.js 02- 5 --last   # show the last candidate instead
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..', '..');
const WEB = path.join(ROOT, 'web');
const BOOK = path.join(ROOT, 'shader-handbook');

const sandbox = { window: {}, console };
sandbox.window.window = sandbox.window;
vm.createContext(sandbox);
for (const f of ['js/md.js', 'js/glsl-lib.js']) {
  vm.runInContext(fs.readFileSync(path.join(WEB, f), 'utf8'), sandbox, { filename: f });
}
const { MD, GLSLLib } = sandbox.window;

const [prefix, idxArg] = process.argv.slice(2);
const manifest = JSON.parse(fs.readFileSync(path.join(WEB, 'manifest.json'), 'utf8'));
const ch = manifest.chapters.find(c => c.id.startsWith(prefix));
const res = MD.render(fs.readFileSync(path.join(BOOK, ch.file), 'utf8'), {});
const blk = res.blocks[+idxArg];

console.log('=== marker:', JSON.stringify(blk.marker), 'lang:', JSON.stringify(blk.lang));
console.log('=== snippet ---------------------------------');
console.log(blk.code);
const plan = GLSLLib.plan(blk.code.replace(/\s+$/, ''), blk.marker, null);
console.log('=== kind:', plan.kind, ' candidates:', plan.candidates.map(c => c.label));
const pick = process.argv.includes('--last') ? plan.candidates.length - 1 : 0;
const src = plan.candidates[pick].src;
src.split('\n').forEach((l, i) => console.log(String(i + 1).padStart(3) + '| ' + l));
