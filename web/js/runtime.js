/* Shared WebGL2 runtime for every shader player on the page.
 *
 * Browsers cap the number of live WebGL contexts (~16), and a chapter can hold
 * forty snippets, so all players share one hidden GL canvas and blit their
 * result into a plain 2D canvas. That also keeps program objects in a single
 * context, which makes compiling cheap.
 */
(function (global) {
  'use strict';

  var MAX_DIM = 1280;

  var gl = null;
  var glCanvas = null;
  var quadVAO = null;
  var channelTex = [];
  var players = [];
  var rafId = 0;
  var lastNow = 0;
  var globalPaused = false;

  function initGL() {
    if (gl) return gl;
    glCanvas = document.createElement('canvas');
    glCanvas.width = 16; glCanvas.height = 16;
    gl = glCanvas.getContext('webgl2', {
      alpha: false,
      antialias: false,
      depth: false,
      stencil: false,
      preserveDrawingBuffer: true,
      powerPreference: 'high-performance'
    });
    if (!gl) return null;

    var vs = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vs, '#version 300 es\nvoid main(){ vec2 p = vec2((gl_VertexID<<1)&2, gl_VertexID&2); gl_Position = vec4(p*2.0-1.0,0.0,1.0); }');
    gl.compileShader(vs);
    quadVAO = { vs: vs };

    channelTex = [0, 1, 2, 3].map(makeNoiseTexture);
    return gl;
  }

  /* Shadertoy's default channel is a grey-noise LUT; a decent stand-in makes a
   * surprising number of corpus shaders render something sensible. */
  function makeNoiseTexture(seed) {
    var N = 256;
    var data = new Uint8Array(N * N * 4);
    var s = 1234567 + seed * 7919;
    function rnd() {
      s ^= s << 13; s ^= s >>> 17; s ^= s << 5; s |= 0;
      return ((s >>> 0) % 65536) / 65535;
    }
    for (var i = 0; i < N * N; i++) {
      data[i * 4] = rnd() * 255;
      data[i * 4 + 1] = rnd() * 255;
      data[i * 4 + 2] = rnd() * 255;
      data[i * 4 + 3] = rnd() * 255;
    }
    var tex = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, tex);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, N, N, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.generateMipmap(gl.TEXTURE_2D);
    return tex;
  }

  var UNIFORM_NAMES = ['iResolution', 'iTime', 'iTimeDelta', 'iFrameRate', 'iFrame',
    'iMouse', 'iDate', 'iSampleRate', 'iChannel0', 'iChannel1', 'iChannel2', 'iChannel3',
    'uArg[0]', 'uZoom', 'uMode'];

  function compile(src) {
    if (!initGL()) return { ok: false, log: '此浏览器不支持 WebGL2。' };
    var fs = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fs, src);
    gl.compileShader(fs);
    if (!gl.getShaderParameter(fs, gl.COMPILE_STATUS)) {
      var log = gl.getShaderInfoLog(fs) || '编译失败（无详细信息）';
      gl.deleteShader(fs);
      return { ok: false, log: log };
    }
    var prog = gl.createProgram();
    gl.attachShader(prog, quadVAO.vs);
    gl.attachShader(prog, fs);
    gl.linkProgram(prog);
    gl.deleteShader(fs);
    if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
      var llog = gl.getProgramInfoLog(prog) || '链接失败（通常是调用了未定义的函数）';
      gl.deleteProgram(prog);
      return { ok: false, log: llog };
    }
    var loc = {};
    UNIFORM_NAMES.forEach(function (n) { loc[n] = gl.getUniformLocation(prog, n); });
    return { ok: true, program: prog, loc: loc };
  }

  /** Rewrite `ERROR: 0:LINE:` so the number refers to the snippet, not the wrapper. */
  function mapLog(log, fullSrc, userCode) {
    if (!log) return log;
    var idx = userCode ? fullSrc.indexOf(userCode) : -1;
    if (idx < 0) return log;
    var offset = fullSrc.slice(0, idx).split('\n').length - 1;
    var span = userCode.split('\n').length;
    return log.replace(/(\d+):(\d+)/g, function (m, a, line) {
      var n = parseInt(line, 10) - offset;
      if (n >= 1 && n <= span + 1) return a + ':' + n;
      return m;
    });
  }

  function Player(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.program = null;
    this.loc = null;
    this.time = 0;
    this.frame = 0;
    this.playing = false;
    this.visible = false;
    this.speed = 1;
    this.zoom = 1;
    this.mode = 0;
    this.args = new Float32Array(24);
    this.mouse = [0, 0, 0, 0];
    this.dirty = true;
    this.rendered = false;
    this.onError = null;
    this.attachMouse();
    players.push(this);
  }

  Player.prototype.attachMouse = function () {
    var self = this, down = false;
    function pos(e) {
      var r = self.canvas.getBoundingClientRect();
      var sx = self.canvas.width / r.width, sy = self.canvas.height / r.height;
      return [(e.clientX - r.left) * sx, self.canvas.height - (e.clientY - r.top) * sy];
    }
    this.canvas.addEventListener('pointerdown', function (e) {
      down = true; self.canvas.setPointerCapture(e.pointerId);
      var p = pos(e); self.mouse = [p[0], p[1], p[0], p[1]]; self.dirty = true;
    });
    this.canvas.addEventListener('pointermove', function (e) {
      if (!down) return;
      var p = pos(e); self.mouse[0] = p[0]; self.mouse[1] = p[1]; self.dirty = true;
    });
    function up() { if (!down) return; down = false; self.mouse[2] = -Math.abs(self.mouse[2]); self.mouse[3] = -Math.abs(self.mouse[3]); self.dirty = true; }
    this.canvas.addEventListener('pointerup', up);
    this.canvas.addEventListener('pointercancel', up);
  };

  Player.prototype.setSource = function (src, userCode) {
    var res = compile(src);
    if (!res.ok) {
      return { ok: false, log: mapLog(res.log, src, userCode) };
    }
    if (this.program) gl.deleteProgram(this.program);
    this.program = res.program;
    this.loc = res.loc;
    this.dirty = true;
    this.rendered = false;
    return { ok: true };
  };

  /**
   * Cheap "is anything actually on screen" test, read from the 2D canvas so it
   * does not stall the GL pipeline. Sampling a few rows is enough to tell a
   * dead preview from a live one.
   */
  Player.prototype.probe = function () {
    if (!this.rendered) return null;
    var w = this.canvas.width, h = this.canvas.height;
    if (!w || !h) return null;
    var rows = 9, sum = 0, sum2 = 0, n = 0, maxv = 0;
    for (var i = 0; i < rows; i++) {
      var y = Math.min(h - 1, Math.floor((i + 0.5) * h / rows));
      var d;
      try { d = this.ctx.getImageData(0, y, w, 1).data; } catch (e) { return null; }
      for (var x = 0; x < w; x += 3) {
        var o = x * 4;
        var l = (d[o] * 0.299 + d[o + 1] * 0.587 + d[o + 2] * 0.114) / 255;
        sum += l; sum2 += l * l; n++;
        if (l > maxv) maxv = l;
      }
    }
    if (!n) return null;
    var mean = sum / n;
    return { mean: mean, variance: Math.max(0, sum2 / n - mean * mean), max: maxv };
  };

  Player.prototype.reset = function () { this.time = 0; this.frame = 0; this.dirty = true; };
  Player.prototype.play = function () { this.playing = true; };
  Player.prototype.pause = function () { this.playing = false; this.dirty = true; };
  Player.prototype.setArg = function (i, comp, v) { this.args[i * 4 + comp] = v; this.dirty = true; };
  Player.prototype.setZoom = function (z) { this.zoom = z; this.dirty = true; };
  Player.prototype.setMode = function (m) { this.mode = m; this.dirty = true; };

  Player.prototype.dispose = function () {
    var k = players.indexOf(this);
    if (k >= 0) players.splice(k, 1);
    if (this.program && gl) gl.deleteProgram(this.program);
    this.program = null;
  };

  Player.prototype.resizeBacking = function () {
    var r = this.canvas.getBoundingClientRect();
    if (!r.width) return false;
    var dpr = Math.min(global.devicePixelRatio || 1, 1.75);
    var w = Math.max(16, Math.min(MAX_DIM, Math.round(r.width * dpr)));
    var h = Math.max(16, Math.min(MAX_DIM, Math.round(r.height * dpr)));
    if (this.canvas.width !== w || this.canvas.height !== h) {
      this.canvas.width = w; this.canvas.height = h; this.dirty = true;
    }
    return true;
  };

  Player.prototype.render = function (dt) {
    if (!this.program || !gl) return;
    if (!this.resizeBacking()) return;
    if (this.playing) { this.time += dt * this.speed; this.frame++; this.dirty = true; }
    if (!this.dirty) return;
    this.dirty = false;

    var w = this.canvas.width, h = this.canvas.height;
    if (glCanvas.width < w || glCanvas.height < h) {
      glCanvas.width = Math.max(glCanvas.width, w);
      glCanvas.height = Math.max(glCanvas.height, h);
    }

    gl.viewport(0, 0, w, h);
    gl.useProgram(this.program);
    var L = this.loc;
    if (L.iResolution) gl.uniform3f(L.iResolution, w, h, 1);
    if (L.iTime) gl.uniform1f(L.iTime, this.time);
    if (L.iTimeDelta) gl.uniform1f(L.iTimeDelta, dt || 0.016);
    if (L.iFrameRate) gl.uniform1f(L.iFrameRate, dt > 0 ? 1 / dt : 60);
    if (L.iFrame) gl.uniform1i(L.iFrame, this.frame);
    if (L.iMouse) gl.uniform4f(L.iMouse, this.mouse[0], this.mouse[1], this.mouse[2], this.mouse[3]);
    if (L.iSampleRate) gl.uniform1f(L.iSampleRate, 44100);
    if (L.iDate) {
      var d = new Date();
      gl.uniform4f(L.iDate, d.getFullYear(), d.getMonth(), d.getDate(),
        d.getHours() * 3600 + d.getMinutes() * 60 + d.getSeconds());
    }
    if (L['uArg[0]']) gl.uniform4fv(L['uArg[0]'], this.args);
    if (L.uZoom) gl.uniform1f(L.uZoom, this.zoom);
    if (L.uMode) gl.uniform1f(L.uMode, this.mode);
    for (var c = 0; c < 4; c++) {
      var key = 'iChannel' + c;
      if (L[key]) {
        gl.activeTexture(gl.TEXTURE0 + c);
        gl.bindTexture(gl.TEXTURE_2D, channelTex[c]);
        gl.uniform1i(L[key], c);
      }
    }
    gl.drawArrays(gl.TRIANGLES, 0, 3);

    this.ctx.drawImage(glCanvas, 0, glCanvas.height - h, w, h, 0, 0, w, h);
    this.rendered = true;
  };

  function tick(now) {
    rafId = requestAnimationFrame(tick);
    var dt = lastNow ? Math.min((now - lastNow) / 1000, 0.05) : 0.016;
    lastNow = now;
    for (var i = 0; i < players.length; i++) {
      var p = players[i];
      if (!p.visible) continue;
      if (globalPaused && p.playing) { p.render(0); continue; }
      p.render(p.playing ? dt : 0);
    }
  }

  function start() { if (!rafId) rafId = requestAnimationFrame(tick); }

  global.Runtime = {
    init: initGL,
    compile: compile,
    Player: Player,
    start: start,
    supported: function () { return !!initGL(); },
    setGlobalPaused: function (v) { globalPaused = v; players.forEach(function (p) { p.dirty = true; }); },
    isGlobalPaused: function () { return globalPaused; }
  };
})(window);
