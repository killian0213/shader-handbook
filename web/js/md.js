/* Minimal Markdown renderer tailored to this handbook.
 *
 * Deliberately not a general CommonMark implementation: it only supports what
 * the chapters actually use, which keeps it dependency-free and offline.
 * Fenced GLSL blocks are extracted first and handed back to the caller so the
 * app can turn them into live shader players.
 */
(function (global) {
  'use strict';

  function escapeHtml(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  /* ---------------------------------------------------------------- math */

  var TEX = [
    [/\\sigma/g, 'σ'], [/\\Sigma/g, 'Σ'], [/\\Delta/g, 'Δ'], [/\\delta/g, 'δ'],
    [/\\alpha/g, 'α'], [/\\beta/g, 'β'], [/\\gamma/g, 'γ'], [/\\theta/g, 'θ'],
    [/\\lambda/g, 'λ'], [/\\mu/g, 'μ'], [/\\pi/g, 'π'], [/\\rho/g, 'ρ'],
    [/\\omega/g, 'ω'], [/\\phi/g, 'φ'], [/\\epsilon/g, 'ε'], [/\\tau/g, 'τ'],
    [/\\nabla/g, '∇'], [/\\partial/g, '∂'], [/\\infty/g, '∞'],
    [/\\cdot/g, '·'], [/\\times/g, '×'], [/\\approx/g, '≈'],
    [/\\leq|\\le\b/g, '≤'], [/\\geq|\\ge\b/g, '≥'], [/\\neq/g, '≠'],
    [/\\int/g, '∫'], [/\\sum/g, '∑'], [/\\sqrt/g, '√'],
    [/\\left|\\right/g, ''], [/\\,|\\;|\\!/g, ' '], [/\\\\/g, ' ']
  ];

  var SUP = { '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹', 'n': 'ⁿ', 'i': 'ⁱ', '+': '⁺', '-': '⁻' };
  var SUB = { '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄', '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉', 'a': 'ₐ', 'e': 'ₑ', 'i': 'ᵢ', 'n': 'ₙ', 't': 'ₜ', 'x': 'ₓ' };

  function tex(src) {
    var s = src;
    s = s.replace(/\\(?:text|mathrm|mathbf)\{([^}]*)\}/g, '$1');
    s = s.replace(/\\frac\{([^{}]*)\}\{([^{}]*)\}/g, '($1)/($2)');
    TEX.forEach(function (r) { s = s.replace(r[0], r[1]); });
    s = s.replace(/\^\{([^}]*)\}|\^(\w)/g, function (m, a, b) {
      var t = a || b, out = '';
      for (var i = 0; i < t.length; i++) { if (!SUP[t[i]]) return '<sup>' + escapeHtml(t) + '</sup>'; out += SUP[t[i]]; }
      return out;
    });
    s = s.replace(/_\{([^}]*)\}|_(\w)/g, function (m, a, b) {
      var t = a || b, out = '';
      for (var i = 0; i < t.length; i++) { if (!SUB[t[i]]) return '<sub>' + escapeHtml(t) + '</sub>'; out += SUB[t[i]]; }
      return out;
    });
    return s;
  }

  /* -------------------------------------------------------------- inline */

  function inline(src, ctx) {
    var codes = [];
    // Protect code spans before anything else touches the text.
    var s = src.replace(/`([^`]+)`/g, function (m, code) {
      codes.push(code);
      return '\u0000C' + (codes.length - 1) + '\u0000';
    });

    s = escapeHtml(s);

    // Display / inline math -> unicode-ish plain text.
    s = s.replace(/\\\[([\s\S]*?)\\\]/g, function (m, t) { return '<span class="math block">' + tex(t.trim()) + '</span>'; });
    s = s.replace(/\\\(([\s\S]*?)\\\)/g, function (m, t) { return '<span class="math">' + tex(t.trim()) + '</span>'; });

    s = s.replace(/!\[([^\]]*)\]\(([^)\s]+)\)/g, function (m, alt, src2) {
      return '<img alt="' + alt + '" loading="lazy" src="' + ctx.resolve(src2) + '">';
    });

    s = s.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, function (m, text, href) {
      var link = ctx.link(href);
      return '<a href="' + link.href + '"' + (link.external ? ' target="_blank" rel="noopener"' : '') + '>' + text + '</a>';
    });

    s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    s = s.replace(/(^|[^*\w])\*([^*\n]+)\*(?![*\w])/g, '$1<em>$2</em>');

    s = s.replace(/\u0000C(\d+)\u0000/g, function (m, i) {
      return '<code>' + escapeHtml(codes[+i]) + '</code>';
    });
    return s;
  }

  /* --------------------------------------------------------------- table */

  // Splits a table row on unescaped pipes that are not inside a code span.
  function splitRow(line) {
    var cells = [], cur = '', tick = false;
    for (var i = 0; i < line.length; i++) {
      var c = line[i];
      if (c === '\\' && line[i + 1] === '|') { cur += '|'; i++; continue; }
      if (c === '`') tick = !tick;
      if (c === '|' && !tick) { cells.push(cur); cur = ''; continue; }
      cur += c;
    }
    cells.push(cur);
    if (cells.length && cells[0].trim() === '') cells.shift();
    if (cells.length && cells[cells.length - 1].trim() === '') cells.pop();
    return cells.map(function (x) { return x.trim(); });
  }

  function isDivider(line) {
    return /^\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?$/.test(line.trim());
  }

  function alignOf(cell) {
    var l = cell.startsWith(':'), r = cell.endsWith(':');
    if (l && r) return 'center';
    if (r) return 'right';
    return 'left';
  }

  /* ---------------------------------------------------------------- main */

  function looksLikeGlsl(code) {
    // Enough signal to distinguish real snippets from ASCII diagrams / tables.
    return /\b(void\s+mainImage|fragColor|iResolution|iTime|smoothstep|mix\s*\(|length\s*\(|vec[234]\s+\w+|float\s+\w+\s*\(|mat[234]\s+)/.test(code);
  }

  /**
   * @param {string} src raw markdown
   * @param {object} opts { resolve(path)->url, link(href)->{href,external} }
   * @returns {{html:string, blocks:Array, headings:Array}}
   */
  function render(src, opts) {
    var ctx = {
      resolve: (opts && opts.resolve) || function (p) { return p; },
      link: (opts && opts.link) || function (h) { return { href: h, external: /^https?:/.test(h) }; }
    };

    var blocks = [];
    var headings = [];

    // Windows editors / Python text-mode writes may leave CRLF. Normalise first
    // so the fence regex (which anchors on `\n`) still sees every code block.
    src = String(src || '').replace(/^\uFEFF/, '').replace(/\r\n/g, '\n').replace(/\r/g, '\n');

    // 1. Pull out fenced code blocks together with the marker comment above.
    var text = src.replace(/(?:^[ \t]*<!--\s*(glsl-from:[^>]*?|glsl-frag|glsl-skip)\s*-->[ \t]*\n)?^[ \t]*```([\w-]*)\n([\s\S]*?)^[ \t]*```[ \t]*$/gm,
      function (m, marker, lang, code) {
        marker = (marker || '').trim();
        lang = (lang || '').trim();
        // Handbook occasionally uses bare ``` for real GLSL. Promote those so
        // the reader still gets highlighting + live preview.
        if (!lang && looksLikeGlsl(code)) lang = 'glsl';
        if (lang === 'glsl-frag') { marker = marker || 'glsl-frag'; lang = 'glsl'; }
        blocks.push({ marker: marker, lang: lang, code: code });
        return '\u0000B' + (blocks.length - 1) + '\u0000';
      });

    // 2. Drop any remaining HTML comments.
    text = text.replace(/<!--[\s\S]*?-->/g, '');

    var lines = text.split(/\r?\n/);
    var out = [];
    var i = 0;

    function flushParagraph(buf) {
      if (!buf.length) return;
      var joined = buf.join('\n').trim();
      if (joined) out.push('<p>' + inline(joined, ctx) + '</p>');
      buf.length = 0;
    }

    var para = [];

    while (i < lines.length) {
      var line = lines[i];
      var trimmed = line.trim();

      // Standalone extracted code block
      var mb = trimmed.match(/^\u0000B(\d+)\u0000$/);
      if (mb) {
        flushParagraph(para);
        out.push('\u0000B' + mb[1] + '\u0000');
        i++;
        continue;
      }

      if (!trimmed) { flushParagraph(para); i++; continue; }

      if (/^(-{3,}|\*{3,}|_{3,})$/.test(trimmed)) {
        flushParagraph(para); out.push('<hr>'); i++; continue;
      }

      var mh = trimmed.match(/^(#{1,6})\s+(.*)$/);
      if (mh) {
        flushParagraph(para);
        var level = mh[1].length;
        var id = 'h' + headings.length;
        var raw = mh[2].replace(/`/g, '').trim();
        headings.push({ id: id, level: level, text: raw });
        out.push('<h' + level + ' id="' + id + '">' + inline(mh[2], ctx) + '</h' + level + '>');
        i++; continue;
      }

      // Table: header row followed by a divider row
      if (trimmed.indexOf('|') >= 0 && i + 1 < lines.length && isDivider(lines[i + 1])) {
        flushParagraph(para);
        var head = splitRow(trimmed);
        var aligns = splitRow(lines[i + 1]).map(alignOf);
        i += 2;
        var rows = [];
        while (i < lines.length && lines[i].trim().indexOf('|') >= 0 && lines[i].trim()) {
          rows.push(splitRow(lines[i].trim()));
          i++;
        }
        var t = ['<div class="table-wrap"><table><thead><tr>'];
        head.forEach(function (c, k) {
          t.push('<th style="text-align:' + (aligns[k] || 'left') + '">' + inline(c, ctx) + '</th>');
        });
        t.push('</tr></thead><tbody>');
        rows.forEach(function (r) {
          t.push('<tr>');
          for (var k = 0; k < head.length; k++) {
            t.push('<td style="text-align:' + (aligns[k] || 'left') + '">' + inline(r[k] || '', ctx) + '</td>');
          }
          t.push('</tr>');
        });
        t.push('</tbody></table></div>');
        out.push(t.join(''));
        continue;
      }

      // Blockquote
      if (/^>\s?/.test(trimmed)) {
        flushParagraph(para);
        var quote = [];
        while (i < lines.length && /^\s*>\s?/.test(lines[i])) {
          quote.push(lines[i].replace(/^\s*>\s?/, ''));
          i++;
        }
        var inner = render(quote.join('\n'), opts);
        // Re-map nested block indices into the outer list.
        var innerHtml = inner.html.replace(/\u0000B(\d+)\u0000/g, function (m2, k) {
          blocks.push(inner.blocks[+k]);
          return '\u0000B' + (blocks.length - 1) + '\u0000';
        });
        out.push('<blockquote>' + innerHtml + '</blockquote>');
        continue;
      }

      // Lists
      if (/^([-*+]|\d+\.)\s+/.test(trimmed)) {
        flushParagraph(para);
        var ordered = /^\d+\./.test(trimmed);
        var items = [];
        while (i < lines.length) {
          var lt = lines[i].trim();
          if (!lt) {
            // A blank line ends the list unless the next line continues it.
            var nxt = lines[i + 1] ? lines[i + 1].trim() : '';
            if (!/^([-*+]|\d+\.)\s+/.test(nxt)) break;
            i++; continue;
          }
          var mi = lt.match(/^([-*+]|\d+\.)\s+(.*)$/);
          if (mi) { items.push(mi[2]); i++; continue; }
          if (/^\s{2,}\S/.test(lines[i]) && items.length) { items[items.length - 1] += '\n' + lt; i++; continue; }
          break;
        }
        var tag = ordered ? 'ol' : 'ul';
        out.push('<' + tag + '>' + items.map(function (x) { return '<li>' + inline(x, ctx) + '</li>'; }).join('') + '</' + tag + '>');
        continue;
      }

      para.push(line);
      i++;
    }
    flushParagraph(para);

    return { html: out.join('\n'), blocks: blocks, headings: headings };
  }

  global.MD = { render: render, escapeHtml: escapeHtml };
})(window);
