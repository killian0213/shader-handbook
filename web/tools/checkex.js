/* Compile every shader-handbook/examples/*.glsl through the reader's wrapper.
 * validate.js skips `glsl-from:` blocks, so these files were never checked.
 *
 *   node web/tools/checkex.js
 */
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const vm = require('vm');
const { execFileSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..', '..');
const WEB = path.join(ROOT, 'web');
const EX = path.join(ROOT, 'shader-handbook', 'examples');
const GLSLANG = path.join(ROOT, 'analysis', 'glslang', 'bin', 'glslangValidator.exe');

const sandbox = { window: {}, console };
sandbox.window.window = sandbox.window;
vm.createContext(sandbox);
for (const f of ['js/md.js', 'js/glsl-lib.js']) {
  vm.runInContext(fs.readFileSync(path.join(WEB, f), 'utf8'), sandbox, { filename: f });
}
const { GLSLLib } = sandbox.window;

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'shbk-ex-'));
let bad = 0;
for (const name of fs.readdirSync(EX).filter(f => f.endsWith('.glsl')).sort()) {
  const src = fs.readFileSync(path.join(EX, name), 'utf8');
  const plan = GLSLLib.plan(src.replace(/\s+$/, ''), '', null);
  const file = path.join(tmp, 'a.frag');
  fs.writeFileSync(file, plan.candidates[0].src, 'utf8');
  try {
    execFileSync(GLSLANG, [file], { stdio: 'pipe' });
    console.log('  ok   ' + name + '   (' + plan.kind + ')');
  } catch (e) {
    bad++;
    const out = ((e.stdout || '') + (e.stderr || '')).toString().replace(file, '<gen>');
    console.log('  FAIL ' + name);
    console.log(out.trim().split('\n').slice(0, 8).map(l => '       ' + l).join('\n'));
  }
}
fs.rmSync(tmp, { recursive: true, force: true });
console.log(bad ? '\n' + bad + ' example file(s) failed' : '\nall example files compile');
process.exit(bad ? 1 : 0);
