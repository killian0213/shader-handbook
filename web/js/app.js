/* Handbook web reader: routing, markdown mounting, live shader blocks. */
(function () {
  'use strict';

  var BOOK = '../shader-handbook/';
  var CORPUS = '../shaders/shaders/';

  var state = { manifest: null, chapter: null, blocks: [], searchIndex: null };
  var $ = function (id) { return document.getElementById(id); };

  /* --------------------------------------------------------------- utils */

  var cache = Object.create(null);
  function fetchText(url) {
    if (cache[url]) return cache[url];
    cache[url] = fetch(encodeURI(url)).then(function (r) {
      if (!r.ok) throw new Error(r.status + ' ' + url);
      return r.text();
    });
    return cache[url];
  }

  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }

  function debounce(fn, ms) {
    var t = 0;
    return function () {
      var a = arguments, self = this;
      clearTimeout(t);
      t = setTimeout(function () { fn.apply(self, a); }, ms);
    };
  }

  function fmt(v) {
    if (Math.abs(v) >= 100) return v.toFixed(1);
    if (Math.abs(v) >= 1) return v.toFixed(3).replace(/0+$/, '').replace(/\.$/, '.0');
    return v.toFixed(4).replace(/0+$/, '').replace(/\.$/, '.0');
  }

  /* ------------------------------------------------------------- sidebar */

  function buildSidebar() {
    var nav = $('sidebar');
    nav.innerHTML = '';
    var part = null;
    state.manifest.chapters.forEach(function (ch) {
      if (ch.part !== part) {
        part = ch.part;
        nav.appendChild(el('div', 'part', part));
      }
      var a = el('a', null, ch.title.replace(/^第\s*/, '第 '));
      a.href = '#/ch/' + encodeURIComponent(ch.id);
      a.dataset.id = ch.id;
      nav.appendChild(a);
    });
  }

  function markActive(id) {
    Array.prototype.forEach.call($('sidebar').querySelectorAll('a'), function (a) {
      a.classList.toggle('active', a.dataset.id === id);
    });
  }

  /* ------------------------------------------------------------- editor */

  function Editor(value, onChange) {
    var wrap = el('div', 'ed');
    var pre = el('pre');
    var code = el('code');
    var ta = document.createElement('textarea');
    ta.spellcheck = false;
    ta.value = value;
    pre.appendChild(code);
    wrap.appendChild(pre);
    wrap.appendChild(ta);

    function sync() {
      code.innerHTML = GLSLLib.highlight(ta.value + '\n');
      ta.style.height = pre.scrollHeight + 'px';
      ta.style.width = Math.max(pre.scrollWidth, wrap.clientWidth) + 'px';
    }

    ta.addEventListener('input', function () { sync(); onChange(ta.value); });
    ta.addEventListener('keydown', function (e) {
      if (e.key === 'Tab') {
        e.preventDefault();
        var s = ta.selectionStart, t = ta.selectionEnd;
        ta.value = ta.value.slice(0, s) + '  ' + ta.value.slice(t);
        ta.selectionStart = ta.selectionEnd = s + 2;
        sync(); onChange(ta.value);
      }
    });

    setTimeout(sync, 0);
    return {
      root: wrap,
      get: function () { return ta.value; },
      set: function (v) { if (ta.value !== v) { ta.value = v; sync(); } },
      sync: sync
    };
  }

  /* --------------------------------------------------------- code blocks */

  /**
   * Wraps one fenced GLSL block: source view, live preview, tunable sliders
   * and an inline editor.
   */
  function CodeBlock(host, block) {
    this.host = host;
    this.marker = block.marker || '';
    this.original = block.code.replace(/\s+$/, '');
    this.code = this.original;
    this.baseCode = this.original;
    this.player = null;
    this.plan = null;
    this.tunes = [];
    this.choice = null;
    this.started = false;
    this.exampleSrc = null;
    this.build();
  }

  CodeBlock.prototype.build = function () {
    var self = this;
    var root = el('div', 'code-block');
    this.root = root;

    var head = el('div', 'cb-head');
    this.badge = el('span', 'cb-badge');
    head.appendChild(this.badge);

    var tools = el('div', 'cb-tools');
    this.select = document.createElement('select');
    this.select.hidden = true;
    this.select.addEventListener('change', function () {
      self.choice = self.select.value;
      self.compile();
    });
    tools.appendChild(this.select);

    this.runBtn = el('button', 'btn', '▶ 预览');
    this.runBtn.addEventListener('click', function () { self.toggleStage(); });
    tools.appendChild(this.runBtn);

    this.editBtn = el('button', 'btn', '✎ 编辑');
    this.editBtn.addEventListener('click', function () { self.toggleEditor(); });
    tools.appendChild(this.editBtn);

    var copy = el('button', 'btn', '⧉ 复制');
    copy.addEventListener('click', function () {
      navigator.clipboard.writeText(self.code).then(function () {
        copy.textContent = '✓ 已复制';
        setTimeout(function () { copy.textContent = '⧉ 复制'; }, 1200);
      });
    });
    tools.appendChild(copy);

    head.appendChild(tools);
    root.appendChild(head);

    this.pre = el('pre', 'cb-code');
    this.codeEl = el('code');
    this.codeEl.innerHTML = GLSLLib.highlight(this.original);
    this.pre.appendChild(this.codeEl);
    root.appendChild(this.pre);

    this.stage = el('div', 'cb-stage');
    this.stage.hidden = true;
    var cwrap = el('div', 'cb-canvas-wrap');
    this.canvas = document.createElement('canvas');
    cwrap.appendChild(this.canvas);
    this.hint = el('div', 'cb-hint', '拖动画面可交互（iMouse）');
    cwrap.appendChild(this.hint);
    this.stage.appendChild(cwrap);
    this.ctrl = el('div', 'cb-ctrl');
    this.stage.appendChild(this.ctrl);
    this.info = el('div', 'cb-info');
    this.info.hidden = true;
    this.stage.appendChild(this.info);
    this.err = el('div', 'cb-err');
    this.err.hidden = true;
    this.stage.appendChild(this.err);
    root.appendChild(this.stage);

    this.editorHost = el('div', 'cb-editor');
    this.editorHost.hidden = true;
    root.appendChild(this.editorHost);

    // Badge + auto-run policy depend on how the handbook marked the block.
    if (/^glsl-from:/.test(this.marker)) {
      this.exampleFile = this.marker.split(':')[1].trim();
      this.badge.textContent = '示例文件 · ' + this.exampleFile;
      this.badge.classList.add('file');
      this.autoRun = true;
    } else if (this.marker === 'glsl-skip') {
      // Marked as "probably won't compile", but the auto shell has got much
      // better since. Try anyway -- a dead frame collapses itself.
      this.badge.textContent = '教学片段';
      this.badge.classList.add('note');
      this.runBtn.textContent = '▶ 试运行';
      this.autoRun = true;
    } else {
      this.badge.textContent = '可运行';
      this.badge.classList.add('run');
      this.autoRun = true;
    }

    this.host.appendChild(root);

    if (Runtime.supported() && this.autoRun) {
      observer.observe(root);
      root._cb = this;
    }
  };

  CodeBlock.prototype.toggleStage = function () {
    if (this.stage.hidden) { this.openStage(true); }
    else {
      this.stage.hidden = true;
      if (this.player) this.player.visible = false;
      this.runBtn.textContent = this.marker === 'glsl-skip' ? '▶ 试运行' : '▶ 预览';
      this.runBtn.classList.remove('on');
    }
  };

  CodeBlock.prototype.openStage = function (explicit) {
    var self = this;
    if (explicit) this.explicitOpen = true;
    this.stage.hidden = false;
    this.runBtn.textContent = '▣ 收起';
    this.runBtn.classList.add('on');
    if (this.started) { if (this.player) this.player.visible = true; return; }
    this.started = true;

    if (this.exampleFile) {
      fetchText(BOOK + this.exampleFile).then(function (src) {
        self.exampleSrc = src;
        self.baseCode = src;
        self.code = src;
        self.compile(explicit);
      }).catch(function () { self.compile(explicit); });
    } else {
      this.compile(explicit);
    }
  };

  CodeBlock.prototype.ensurePlayer = function () {
    if (!this.player) {
      this.player = new Runtime.Player(this.canvas);
      this.player.visible = true;
      this.player.play();
    }
    return this.player;
  };

  /** Re-plan and compile the current code, then rebuild the control strip. */
  CodeBlock.prototype.compile = function (explicit) {
    var p = this.ensurePlayer();
    this.tunes = GLSLLib.tunables(this.baseCode);
    this.code = this.tunes.length ? GLSLLib.applyTunables(this.baseCode, this.tunes) : this.baseCode;

    var plan = GLSLLib.plan(this.code, this.marker, this.choice);
    this.plan = plan;

    var lastErr = null, used = null;
    for (var i = 0; i < plan.candidates.length; i++) {
      var r = p.setSource(plan.candidates[i].src, this.code);
      if (r.ok) { used = plan.candidates[i]; break; }
      lastErr = r.log;
    }

    if (!used) { this.showUnrunnable(plan, lastErr, explicit); return; }

    // A candidate may refine the view (auto-visualisation modes, shape…).
    var view = plan;
    if (used.view) {
      view = {};
      Object.keys(plan).forEach(function (k) { view[k] = plan[k]; });
      Object.keys(used.view).forEach(function (k) { view[k] = used.view[k]; });
    }

    this.err.hidden = true;
    this.canvas.style.display = '';
    this.stage.hidden = false;
    this.hint.hidden = !(plan.kind === 'shader' || plan.interactive);
    this.usedSrc = used.src;
    this.info.hidden = false;
    this.info.textContent = used.label +
      (plan.kind !== 'shader' ? '　外壳由阅读器自动生成，不是原文的一部分' : '');
    this.stage.classList.remove('short');
    this.stage.classList.toggle('tall', view.shape === 'tall');
    this.stage.classList.toggle('short', view.shape === 'short');
    this.badge.className = 'cb-badge run';
    if (!this.exampleFile) this.badge.textContent = '可运行';
    this.buildControls(view);
    this.scheduleBlankCheck();
  };

  /**
   * Some snippets compile but draw nothing at all. A 420px black rectangle is
   * worse than no preview, so check twice (once settled, once after animation
   * has had time to start) and collapse if the frame is dead.
   */
  CodeBlock.prototype.scheduleBlankCheck = function () {
    var self = this;
    if (this.blankTimers) this.blankTimers.forEach(clearTimeout);
    this.blankTimers = [];
    var strikes = 0;
    function check(last) {
      if (!self.player || self.stage.hidden) return;
      var s = self.player.probe();
      if (!s) return;
      var dead = s.max < 0.035;
      var flat = s.variance < 3e-6;
      if (dead) {
        strikes++;
        if (strikes >= 2 || last) self.showBlank();
      } else if (flat && last) {
        // A single solid colour is a real result, just not worth 420px.
        self.stage.classList.remove('tall');
        self.stage.classList.add('short');
        self.info.textContent = self.info.textContent + '　输出是一片纯色';
      }
    }
    this.blankTimers.push(setTimeout(function () { check(false); }, 350));
    this.blankTimers.push(setTimeout(function () { check(true); }, 1600));
  };

  CodeBlock.prototype.showBlank = function () {
    var self = this;
    if (this.player) this.player.visible = false;
    this.canvas.style.display = 'none';
    this.hint.hidden = true;
    this.info.hidden = true;
    this.err.hidden = true;
    this.badge.textContent = '教学片段';
    this.badge.className = 'cb-badge note';
    this.runBtn.textContent = '▶ 试运行';
    this.runBtn.classList.remove('on');
    this.ctrl.innerHTML = '';

    var msg = el('span', 'cb-blank', '这段片段本身画不出东西 —— 它依赖正文没有引用的上下文。');
    this.ctrl.appendChild(msg);

    var toPg = el('button', 'btn', '⚡ 在沙盒里补全');
    toPg.addEventListener('click', function () {
      sessionStorage.setItem('pg-seed', self.code);
      location.hash = '#/playground';
    });
    this.ctrl.appendChild(toPg);

    var show = el('button', 'btn', '仍要显示画面');
    show.addEventListener('click', function () {
      self.canvas.style.display = '';
      if (self.player) self.player.visible = true;
      show.remove();
      self.buildControls(self.plan);
    });
    this.ctrl.appendChild(show);

    if (!this.explicitOpen) { this.stage.hidden = true; }
  };

  /**
   * A snippet that needs context it was never given. Auto-runs fail quietly
   * (the reader is here to read); an explicit click gets the compiler log.
   */
  CodeBlock.prototype.showUnrunnable = function (plan, log, explicit) {
    this.badge.textContent = '教学片段';
    this.badge.className = 'cb-badge note';
    this.runBtn.textContent = '▶ 试运行';
    this.runBtn.classList.remove('on');
    this.canvas.style.display = 'none';
    this.hint.hidden = true;
    this.info.hidden = true;
    this.ctrl.innerHTML = '';

    var toPg = el('button', 'btn', '⚡ 在沙盒里补全');
    var self = this;
    toPg.addEventListener('click', function () {
      sessionStorage.setItem('pg-seed', self.code);
      location.hash = '#/playground';
    });
    this.ctrl.appendChild(toPg);

    if (!explicit) { this.stage.hidden = true; return; }
    this.stage.hidden = false;
    this.err.hidden = false;
    this.err.textContent = (plan.note || log || '无法编译') +
      (plan.note ? '' : '\n\n这段代码依赖手册正文里没有引用的上下文。点「✎ 编辑」补全，或到沙盒里接着写。');
  };

  CodeBlock.prototype.buildControls = function (plan) {
    var self = this, p = this.player;
    this.ctrl.innerHTML = '';

    var play = el('button', 'btn', p && p.playing ? '⏸' : '▶');
    play.title = '播放 / 暂停';
    play.addEventListener('click', function () {
      if (!p) return;
      if (p.playing) { p.pause(); play.textContent = '▶'; }
      else { p.play(); play.textContent = '⏸'; }
    });
    this.ctrl.appendChild(play);

    var rst = el('button', 'btn', '↻');
    rst.title = '重置时间';
    rst.addEventListener('click', function () { if (p) p.reset(); });
    this.ctrl.appendChild(rst);

    if (!plan) return;

    // Preview-target picker for snippets that define several functions.
    if (plan.functions && plan.functions.length > 1) {
      this.select.hidden = false;
      this.select.innerHTML = '';
      plan.functions.forEach(function (f) {
        var o = document.createElement('option');
        o.value = f.name;
        o.textContent = '预览 ' + f.name + '()';
        if (f.name === plan.picked) o.selected = true;
        self.select.appendChild(o);
      });
    } else {
      this.select.hidden = true;
    }

    if (plan.modes) {
      var sel = document.createElement('select');
      plan.modes.forEach(function (label, i) {
        var o = document.createElement('option');
        o.value = String(i); o.textContent = label;
        if (i === (plan.defaultMode || 0)) o.selected = true;
        sel.appendChild(o);
      });
      p.setMode(plan.defaultMode || 0);
      sel.addEventListener('change', function () { p.setMode(parseFloat(sel.value)); });
      this.ctrl.appendChild(sel);
    } else {
      p.setMode(0);
    }

    if (plan.supportsZoom) {
      this.ctrl.appendChild(this.knob('视野', 0.25, 4, 0.01, 1, function (v) { p.setZoom(v); }));
    }

    // Harness arguments are plain uniforms: dragging is instant.
    (plan.args || []).forEach(function (arg) {
      var comps = arg.type === 'vec2' ? 2 : arg.type === 'vec3' ? 3 : arg.type === 'vec4' ? 4 : 1;
      for (var c = 0; c < comps; c++) {
        (function (c) {
          var label = arg.name + (comps > 1 ? '.' + 'xyzw'[c] : '');
          var v0 = arg.value[c];
          p.setArg(arg.index, c, v0);
          var lo = arg.type === 'int' ? 1 : -1.5, hi = arg.type === 'int' ? 16 : 1.5;
          var step = arg.type === 'int' ? 1 : 0.005;
          self.ctrl.appendChild(self.knob(label, lo, hi, step, v0, function (v) {
            p.setArg(arg.index, c, v);
          }));
        })(c);
      }
    });

    // Source constants: changing these rewrites the code and recompiles.
    this.tunes.forEach(function (t, i) {
      self.ctrl.appendChild(self.knob(t.name, t.min, t.max, t.step, t.value, function (v) {
        self.tunes[i].value = v;
        self.recompileTunables();
      }, true));
    });
  };

  CodeBlock.prototype.knob = function (name, min, max, step, value, onInput, isSource) {
    var wrap = el('div', 'knob');
    var lab = el('label', null, name);
    if (isSource) lab.title = '这是源码里的常量，拖动会改写代码并重新编译';
    var range = document.createElement('input');
    range.type = 'range';
    range.min = min; range.max = max; range.step = step; range.value = value;
    var out = el('span', 'val', fmt(value));
    range.addEventListener('input', function () {
      var v = parseFloat(range.value);
      out.textContent = fmt(v);
      onInput(v);
    });
    wrap.appendChild(lab); wrap.appendChild(range); wrap.appendChild(out);
    return wrap;
  };

  CodeBlock.prototype.recompileTunables = debounce(function () {
    var code = GLSLLib.applyTunables(this.baseCode, this.tunes);
    this.code = code;
    this.codeEl.innerHTML = GLSLLib.highlight(code);
    if (this.editor) this.editor.set(code);
    var plan = GLSLLib.plan(code, this.marker, this.choice);
    for (var i = 0; i < plan.candidates.length; i++) {
      var r = this.player.setSource(plan.candidates[i].src, code);
      if (r.ok) { this.err.hidden = true; this.usedSrc = plan.candidates[i].src; return; }
    }
  }, 40);

  CodeBlock.prototype.toggleEditor = function () {
    var self = this;
    if (!this.editor) {
      if (this.stage.hidden) this.openStage();
      var seed = this.exampleSrc || this.code;
      this.editor = Editor(seed, debounce(function (v) {
        self.baseCode = v;
        self.choice = null;
        self.compile();
        self.codeEl.innerHTML = GLSLLib.highlight(v);
      }, 350));
      this.editorHost.appendChild(this.editor.root);
      this.pre.hidden = true;
      this.editorHost.hidden = false;
      this.editBtn.classList.add('on');
      this.editBtn.textContent = '✎ 编辑中';
      setTimeout(function () { self.editor.sync(); }, 30);
      return;
    }
    var showing = !this.editorHost.hidden;
    this.editorHost.hidden = showing;
    this.pre.hidden = !showing;
    this.editBtn.classList.toggle('on', !showing);
    this.editBtn.textContent = showing ? '✎ 编辑' : '✎ 编辑中';
    if (!showing) this.editor.sync();
  };

  /* Lazily start players only when a block is near the viewport. */
  function setVisible(cb, on) {
    if (!cb) return;
    if (on) {
      if (!cb.started) cb.openStage(false);
      else if (cb.player && !cb.stage.hidden) cb.player.visible = true;
    } else if (cb.player) {
      cb.player.visible = false;
    }
  }

  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) { setVisible(e.target._cb, e.isIntersecting); });
  }, { rootMargin: '150px 0px' });

  /* Safety net: the observer can miss the first paint after a route change. */
  function sweepVisible() {
    var h = window.innerHeight;
    state.blocks.forEach(function (cb) {
      var r = cb.root.getBoundingClientRect();
      setVisible(cb, r.bottom > -150 && r.top < h + 150);
    });
  }

  function disposeBlocks() {
    state.blocks.forEach(function (cb) {
      if (cb.blankTimers) cb.blankTimers.forEach(clearTimeout);
      if (cb.player) cb.player.dispose();
    });
    state.blocks = [];
  }

  /* --------------------------------------------------------- corpus view */

  function openCorpus(path) {
    var full = path.indexOf('/') >= 0 ? path : path + '/image.glsl';
    var url = CORPUS + full;
    $('modalTitle').textContent = full;
    var body = $('modalBody');
    body.innerHTML = '<div class="loading" style="padding:24px">载入中…</div>';
    $('modal').hidden = false;

    fetchText(url).then(function (src) {
      body.innerHTML = '';
      var stageWrap = el('div');
      body.appendChild(stageWrap);
      var pre = el('pre', 'cb-code');
      var code = el('code');
      code.innerHTML = GLSLLib.highlight(src);
      pre.appendChild(code);
      body.appendChild(pre);

      $('modalRun').onclick = function () {
        stageWrap.innerHTML = '';
        var stage = el('div', 'cb-stage');
        var canvas = document.createElement('canvas');
        stage.appendChild(canvas);
        var note = el('div', 'cb-info');
        stage.appendChild(note);
        stageWrap.appendChild(stage);

        var player = new Runtime.Player(canvas);
        player.visible = true; player.play();
        var plan = GLSLLib.plan(src, '', null);
        var ok = false, log = '';
        for (var i = 0; i < plan.candidates.length; i++) {
          var r = player.setSource(plan.candidates[i].src, src);
          if (r.ok) { ok = true; break; }
          log = r.log;
        }
        if (ok) {
          note.textContent = '注意：多 Pass 作品的 Buffer 通道、以及原作使用的贴图/音频，这里都用程序化噪声代替，画面可能与原作不同。';
        } else {
          var e = el('div', 'cb-err', log + '\n\n多 Pass 作品或依赖特定输入通道的作品无法在这里直接运行。');
          stage.appendChild(e);
          canvas.style.display = 'none';
        }
        modalPlayers.push(player);
      };
    }).catch(function () {
      body.innerHTML = '<div class="notice">找不到 ' + full + '，可能是多 Pass 作品（试试 buffer_a.glsl / common.glsl），或该作品不在本地语料里。</div>';
    });
  }

  var modalPlayers = [];
  function closeModal() {
    $('modal').hidden = true;
    modalPlayers.forEach(function (p) { p.dispose(); });
    modalPlayers = [];
    $('modalBody').innerHTML = '';
  }

  var CORPUS_RE = /^\d{6}-[A-Za-z0-9_+.\-]+(?:\/[\w.\-]+\.glsl)?$/;
  function linkifyCorpus(root) {
    Array.prototype.forEach.call(root.querySelectorAll('code'), function (c) {
      var t = c.textContent.trim();
      if (!CORPUS_RE.test(t)) return;
      c.classList.add('corpus-link');
      c.title = '点击查看 / 运行这个语料作品';
      c.addEventListener('click', function () { openCorpus(t); });
    });
  }

  /* -------------------------------------------------------------- render */

  function mdOptions() {
    return {
      resolve: function (p) {
        if (/^https?:/.test(p)) return p;
        return BOOK + p;
      },
      link: function (href) {
        if (/^https?:/.test(href)) return { href: href, external: true };
        if (/\.md(#.*)?$/.test(href)) {
          var parts = href.split('#');
          var id = parts[0].replace(/\.md$/, '');
          return { href: '#/ch/' + encodeURIComponent(id) + (parts[1] ? '@' + parts[1] : ''), external: false };
        }
        if (href.charAt(0) === '#') return { href: href, external: false };
        return { href: BOOK + href, external: true };
      }
    };
  }

  function renderChapter(id) {
    var ch = state.manifest.chapters.filter(function (c) { return c.id === id; })[0];
    if (!ch) { $('content').innerHTML = '<div class="notice">找不到这一章。</div>'; return; }

    markActive(id);
    disposeBlocks();
    var content = $('content');
    content.className = 'content';
    content.innerHTML = '<div class="loading">载入中…</div>';

    fetchText(BOOK + ch.file).then(function (src) {
      var res = MD.render(src, mdOptions());
      content.innerHTML = '';

      var parts = res.html.split(/\u0000B(\d+)\u0000/);
      for (var i = 0; i < parts.length; i++) {
        if (i % 2 === 0) {
          if (!parts[i].trim()) continue;
          var d = el('div');
          d.innerHTML = parts[i];
          while (d.firstChild) content.appendChild(d.firstChild);
        } else {
          var blk = res.blocks[+parts[i]];
          if (!blk) continue;
          if (blk.lang !== 'glsl') {
            var p = el('pre', 'code-block cb-code');
            var c = el('code', null, blk.code);
            p.appendChild(c);
            content.appendChild(p);
          } else {
            state.blocks.push(new CodeBlock(content, blk));
          }
        }
      }

      linkifyCorpus(content);
      buildToc(res.headings);
      window.scrollTo(0, 0);
      requestAnimationFrame(sweepVisible);
      setTimeout(sweepVisible, 400);

      var anchor = location.hash.split('@')[1];
      if (anchor) {
        var target = document.getElementById(anchor);
        if (target) target.scrollIntoView();
      }
    }).catch(function (e) {
      content.innerHTML = '<div class="notice">载入失败：' + e.message +
        '<br>请确认是用 <code>python web/serve.py</code> 启动的本地服务器，而不是直接双击 index.html。</div>';
    });
  }

  function buildToc(headings) {
    var toc = $('toc');
    toc.innerHTML = '';
    var hs = headings.filter(function (h) { return h.level >= 2 && h.level <= 4; });
    if (!hs.length) return;
    toc.appendChild(el('h4', null, '本章目录'));
    hs.forEach(function (h) {
      var a = el('a', h.level >= 3 ? 'lv' + h.level : null, h.text);
      a.href = '#' + h.id;
      a.addEventListener('click', function (e) {
        e.preventDefault();
        var t = document.getElementById(h.id);
        if (t) t.scrollIntoView({ behavior: 'smooth', block: 'start' });
      });
      toc.appendChild(a);
    });

    var links = Array.prototype.slice.call(toc.querySelectorAll('a'));
    var spy = debounce(function () {
      var best = null, bestY = -Infinity;
      hs.forEach(function (h, i) {
        var t = document.getElementById(h.id);
        if (!t) return;
        var y = t.getBoundingClientRect().top - 80;
        if (y <= 0 && y > bestY) { bestY = y; best = i; }
      });
      links.forEach(function (a, i) { a.classList.toggle('active', i === best); });
    }, 80);
    window.removeEventListener('scroll', window.__tocSpy || function () {});
    window.__tocSpy = spy;
    window.addEventListener('scroll', spy, { passive: true });
    spy();
  }

  /* ---------------------------------------------------------- playground */

  var PG_DEFAULT = [
    'void mainImage(out vec4 fragColor, in vec2 fragCoord)',
    '{',
    '    vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y;',
    '',
    '    float d = length(uv) - 0.45;',
    '    float px = 2.0 / iResolution.y;',
    '',
    '    vec3 col = 0.5 + 0.5*cos(iTime + uv.xyx + vec3(0.0, 2.0, 4.0));',
    '    col *= 0.30;',
    '    col += vec3(1.0, 0.6, 0.25) * exp(-max(d, 0.0) * 7.0) * 0.7;',
    '    col = mix(col, vec3(0.97, 0.95, 0.92), smoothstep(px, -px, d));',
    '',
    '    fragColor = vec4(pow(col, vec3(0.4545)), 1.0);',
    '}'
  ].join('\n');

  function renderPlayground() {
    markActive(null);
    $('toc').innerHTML = '';
    var content = $('content');
    content.className = 'content wide';
    content.innerHTML = '';
    content.appendChild(el('h1', null, '沙盒'));
    var p = el('p', null, '左边写代码，右边实时出图。改动会在停手约 0.3 秒后自动编译。可以从上方选一个手册示例作为起点。');
    content.appendChild(p);

    var grid = el('div', 'pg');
    var left = el('div', 'panel');
    var lhead = el('div', 'panel-head');
    var presets = document.createElement('select');
    presets.appendChild(new Option('— 从手册示例载入 —', ''));
    (state.manifest.examples || []).forEach(function (f) {
      presets.appendChild(new Option(f, f));
    });
    lhead.appendChild(presets);
    var status = el('span', 'cb-badge', '就绪');
    lhead.appendChild(status);
    left.appendChild(lhead);

    var right = el('div', 'panel');
    var rhead = el('div', 'panel-head');
    right.appendChild(rhead);
    var canvas = document.createElement('canvas');
    right.appendChild(canvas);
    var errBox = el('div', 'cb-err');
    errBox.hidden = true;
    right.appendChild(errBox);

    grid.appendChild(left);
    grid.appendChild(right);
    content.appendChild(grid);

    var player = new Runtime.Player(canvas);
    player.visible = true; player.play();

    function run(code) {
      var plan = GLSLLib.plan(code, '', null);
      var log = '';
      for (var i = 0; i < plan.candidates.length; i++) {
        var r = player.setSource(plan.candidates[i].src, code);
        if (r.ok) {
          errBox.hidden = true;
          status.textContent = '✓ ' + plan.candidates[i].label;
          status.className = 'cb-badge run';
          return;
        }
        log = r.log;
      }
      errBox.hidden = false;
      errBox.textContent = log;
      status.textContent = '✗ 编译失败';
      status.className = 'cb-badge';
    }

    var seed = sessionStorage.getItem('pg-seed');
    if (seed) sessionStorage.removeItem('pg-seed');
    var editor = Editor(seed || PG_DEFAULT, debounce(run, 300));
    left.appendChild(editor.root);

    var pbtn = el('button', 'btn', '⏸');
    pbtn.addEventListener('click', function () {
      if (player.playing) { player.pause(); pbtn.textContent = '▶'; }
      else { player.play(); pbtn.textContent = '⏸'; }
    });
    rhead.appendChild(pbtn);
    var rbtn = el('button', 'btn', '↻ 重置时间');
    rbtn.addEventListener('click', function () { player.reset(); });
    rhead.appendChild(rbtn);
    rhead.appendChild(el('span', 'cb-badge', '拖动画面 = iMouse'));

    presets.addEventListener('change', function () {
      if (!presets.value) return;
      fetchText(BOOK + 'examples/' + presets.value).then(function (src) {
        editor.set(src);
        run(src);
      });
    });

    run(seed || PG_DEFAULT);
    state.pgPlayer = player;
  }

  /* -------------------------------------------------------------- search */

  function buildIndex() {
    if (state.searchIndex) return Promise.resolve(state.searchIndex);
    return Promise.all(state.manifest.chapters.map(function (ch) {
      return fetchText(BOOK + ch.file).then(function (t) { return { ch: ch, text: t }; });
    })).then(function (all) {
      state.searchIndex = all;
      return all;
    });
  }

  function runSearch(q) {
    var box = $('searchResults');
    if (!q || q.length < 2) { box.hidden = true; return; }
    buildIndex().then(function (idx) {
      var needle = q.toLowerCase();
      var hits = [];
      idx.forEach(function (entry) {
        var lines = entry.text.split('\n');
        for (var i = 0; i < lines.length && hits.length < 40; i++) {
          var low = lines[i].toLowerCase();
          var at = low.indexOf(needle);
          if (at < 0) continue;
          var start = Math.max(0, at - 30);
          hits.push({
            ch: entry.ch,
            snippet: lines[i].slice(start, start + 120),
            at: at - start
          });
        }
      });
      box.innerHTML = '';
      if (!hits.length) {
        box.appendChild(el('div', 'sr-item', '没有找到「' + q + '」'));
      }
      hits.slice(0, 30).forEach(function (h) {
        var a = el('a', 'sr-item');
        a.href = '#/ch/' + encodeURIComponent(h.ch.id);
        var t = el('div', 'sr-ch', h.ch.title);
        var s = el('div');
        var raw = h.snippet;
        s.innerHTML = MD.escapeHtml(raw.slice(0, h.at)) +
          '<mark>' + MD.escapeHtml(raw.substr(h.at, q.length)) + '</mark>' +
          MD.escapeHtml(raw.slice(h.at + q.length));
        a.appendChild(t); a.appendChild(s);
        a.addEventListener('click', function () { box.hidden = true; $('search').value = ''; });
        box.appendChild(a);
      });
      box.hidden = false;
    });
  }

  /* ---------------------------------------------------------- appearance */

  // Single Chinese glyphs instead of symbol characters: Windows font fallback
  // turns ☀/☾ into unrelated shapes.
  var THEMES = [
    { id: 'light', label: '浅色', icon: '浅' },
    { id: 'sepia', label: '纸黄', icon: '纸' },
    { id: 'dark', label: '深色', icon: '深' }
  ];
  var SIZES = [
    { px: '16px', label: '小' },
    { px: '17.5px', label: '中' },
    { px: '19.5px', label: '大' },
    { px: '21.5px', label: '特大' }
  ];

  function currentTheme() {
    var t = document.documentElement.getAttribute('data-theme') || 'light';
    var i = THEMES.map(function (x) { return x.id; }).indexOf(t);
    return i < 0 ? 0 : i;
  }

  function applyTheme(i) {
    var t = THEMES[i % THEMES.length];
    document.documentElement.setAttribute('data-theme', t.id);
    localStorage.setItem('shbk-theme', t.id);
    var b = $('themeBtn');
    b.textContent = t.icon;
    b.style.fontSize = '13.5px';
    b.title = '配色：' + t.label + '（点击切换）';
  }

  function currentSize() {
    var v = localStorage.getItem('shbk-fontsize');
    var i = SIZES.map(function (x) { return x.px; }).indexOf(v);
    return i < 0 ? 1 : i;
  }

  function applySize(i) {
    var s = SIZES[i % SIZES.length];
    document.documentElement.style.setProperty('--base', s.px);
    localStorage.setItem('shbk-fontsize', s.px);
    var b = $('fontBtn');
    b.textContent = 'A';
    b.style.fontSize = (13 + i * 2) + 'px';
    b.title = '正文字号：' + s.label + '（点击切换）';
  }

  /* -------------------------------------------------------------- router */

  function route() {
    if (state.pgPlayer) { state.pgPlayer.dispose(); state.pgPlayer = null; }
    disposeBlocks();
    var h = location.hash.replace(/^#/, '');
    if (h.indexOf('/playground') === 0) { renderPlayground(); return; }
    var m = h.match(/^\/ch\/([^@]+)/);
    var id = m ? decodeURIComponent(m[1]) : 'README';
    state.chapter = id;
    renderChapter(id);
  }

  /* ---------------------------------------------------------------- boot */

  function boot() {
    fetchText('manifest.json').then(function (t) {
      state.manifest = JSON.parse(t);
      buildSidebar();
      Runtime.start();
      route();
    }).catch(function (e) {
      $('content').innerHTML = '<div class="notice">无法读取 manifest.json（' + e.message +
        '）。<br>请先运行 <code>python web/build_manifest.py</code>，并用 <code>python web/serve.py</code> 启动本地服务器。</div>';
    });

    window.addEventListener('hashchange', route);
    window.addEventListener('scroll', debounce(sweepVisible, 250), { passive: true });
    window.addEventListener('resize', debounce(sweepVisible, 250));

    var themeIdx = currentTheme(), sizeIdx = currentSize();
    applyTheme(themeIdx);
    applySize(sizeIdx);
    $('themeBtn').addEventListener('click', function () { applyTheme(++themeIdx); });
    $('fontBtn').addEventListener('click', function () {
      applySize(++sizeIdx);
      setTimeout(sweepVisible, 60);
    });

    $('menuBtn').addEventListener('click', function () {
      $('sidebar').classList.toggle('open');
    });

    $('pauseAll').addEventListener('click', function () {
      var v = !Runtime.isGlobalPaused();
      Runtime.setGlobalPaused(v);
      $('pauseAll').textContent = v ? '▶ 全部继续' : '⏸ 全部暂停';
      $('pauseAll').classList.toggle('on', v);
    });

    $('search').addEventListener('input', debounce(function (e) { runSearch(e.target.value.trim()); }, 220));
    $('search').addEventListener('blur', function () {
      setTimeout(function () { $('searchResults').hidden = true; }, 180);
    });
    $('search').addEventListener('focus', function (e) {
      if (e.target.value.trim().length >= 2) $('searchResults').hidden = false;
    });

    $('modalClose').addEventListener('click', closeModal);
    $('modal').addEventListener('click', function (e) { if (e.target === $('modal')) closeModal(); });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && !$('modal').hidden) closeModal();
      if (e.key === '/' && document.activeElement !== $('search')) {
        e.preventDefault(); $('search').focus();
      }
    });

    if (!Runtime.supported()) {
      var n = el('div', 'notice', '当前浏览器不支持 WebGL2，实时预览不可用，但手册内容仍可正常阅读。');
      document.querySelector('.content').prepend(n);
    }
  }

  boot();
})();
