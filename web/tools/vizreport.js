/* How many statement fragments now get an auto-visualisation instead of black?
 *   node web/tools/vizreport.js
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

const manifest = JSON.parse(fs.readFileSync(path.join(WEB, 'manifest.json'), 'utf8'));
let frag = 0, viz = 0, dead = 0;
const deadList = [];

for (const ch of manifest.chapters) {
  const res = MD.render(fs.readFileSync(path.join(BOOK, ch.file), 'utf8'), {});
  res.blocks.forEach((blk, i) => {
    if (blk.lang !== 'glsl') return;
    const plan = GLSLLib.plan(blk.code.replace(/\s+$/, ''), blk.marker, null);
    if (plan.kind !== 'fragment') return;
    frag++;
    const hit = plan.candidates.some(c => c.view && c.view.autoViz);
    const writes = /\bcol\b\s*(?:\+|-|\*|\/)?=/.test(blk.code) || /fragColor/.test(blk.code);
    if (hit) viz++;
    else if (!writes) { dead++; deadList.push(ch.id + '#' + i + '  ' + blk.code.split('\n')[0].slice(0, 62)); }
  });
}
console.log('statement fragments:', frag);
console.log('  auto-visualised  :', viz);
console.log('  still no output  :', dead);
deadList.forEach(s => console.log('    ' + s));
