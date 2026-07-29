/* GLSL analysis, auto-harness generation and syntax highlighting.
 *
 * The handbook quotes three kinds of code: complete shaders, bare function
 * libraries, and loose statement fragments. Only the first kind can be handed
 * to WebGL as-is. This module makes the other two runnable by
 *   1. splitting a snippet into top-level declarations and loose statements,
 *   2. injecting implementations for helpers it references but never defines,
 *   3. declaring identifiers that the surrounding (unquoted) code would have
 *      provided, and
 *   4. wrapping it in a preview harness chosen from the signature of whichever
 *      function the snippet is demonstrating.
 */
(function (global) {
  'use strict';

  var HEADER = [
    '#version 300 es',
    'precision highp float;',
    'precision highp int;',
    'uniform vec3  iResolution;',
    'uniform float iTime;',
    'uniform float iTimeDelta;',
    'uniform float iFrameRate;',
    'uniform int   iFrame;',
    'uniform float iChannelTime[4];',
    'uniform vec3  iChannelResolution[4];',
    'uniform vec4  iMouse;',
    'uniform vec4  iDate;',
    'uniform float iSampleRate;',
    'uniform sampler2D iChannel0;',
    'uniform sampler2D iChannel1;',
    'uniform sampler2D iChannel2;',
    'uniform sampler2D iChannel3;',
    'uniform vec4  uArg[6];',
    'uniform float uZoom;',
    'uniform float uMode;',
    'out vec4 st_FragColor;',
    '#define texture2D texture',
    '#define textureCube texture',
    '#define texture2DLod textureLod',
    '#define textureCubeLod textureLod',
    ''
  ].join('\n');

  var EPILOGUE = '\nvoid main(){ vec4 st_c = vec4(0.0,0.0,0.0,1.0); mainImage(st_c, gl_FragCoord.xy); st_FragColor = st_c; }\n';

  /**
   * A stand-in for iChannel0. The post-processing and multi-pass chapters all
   * assume an input image; with no textures bound they would sample pure black
   * and every blur/bloom/edge snippet would render an empty frame. This gives
   * them something with the properties those effects need: smooth gradients
   * (banding + dither), over-bright spots (bloom), hard edges (blur, sharpen,
   * edge detect) and fine high-frequency detail (aliasing).
   */
  var SCENE = [
    'vec4 stScene(vec2 uv){',
    '  uv = clamp(uv, vec2(0.0), vec2(1.0));',   // like CLAMP_TO_EDGE
    '  vec2 p = (uv - 0.5) * vec2(1.7778, 1.0) * 2.0;',
    '  vec3 c = mix(vec3(0.04,0.06,0.13), vec3(0.38,0.20,0.32), clamp(uv.y,0.0,1.0));',
    '  c = mix(c, vec3(0.09,0.08,0.07), smoothstep(0.012,0.0,p.y+0.48));',
    '  for(int i=0;i<3;i++){',
    '    float f=float(i);',
    '    vec2 o=vec2(-0.72+0.72*f, -0.06+0.18*sin(f*2.1+1.0));',
    '    float d=length(p-o)-0.20;',
    '    vec3 sc=0.5+0.5*cos(6.28318*(0.13*f+vec3(0.0,0.33,0.67)));',
    '    c=mix(c, sc*1.7, smoothstep(0.007,-0.007,d));',
    '  }',
    '  vec2 q=abs(p-vec2(0.56,0.26))-vec2(0.22,0.15);',
    '  float b=min(max(q.x,q.y),0.0)+length(max(q,0.0));',
    '  c=mix(c, vec3(0.96,0.93,0.82), step(b,0.0));',
    '  c *= 0.90+0.10*sin(p.x*90.0)*sin(p.y*90.0);',
    '  return vec4(c,1.0);',
    '}',
    '// 采样被重定向到上面这张程序化"素材图"（阅读器没有贴图输入）',
    '#define texture(a, b) stScene(vec2(b))',
    '#define textureLod(a, b, c) stScene(vec2(b))',
    '#define texelFetch(a, b, c) stScene(vec2(b)/iResolution.xy)',
    ''
  ].join('\n');

  var SAMPLES_CHANNEL = /\biChannel[0-3]\b|\btexture(?:2D|Cube|Lod|2DLod|CubeLod)?\s*\(|\btexelFetch\s*\(/;

  var TYPES = 'void|float|int|uint|bool|vec2|vec3|vec4|ivec2|ivec3|ivec4|uvec2|uvec3|uvec4|bvec2|bvec3|bvec4|mat2|mat3|mat4|mat2x2|mat2x3|mat2x4|mat3x2|mat3x3|mat3x4|mat4x2|mat4x3|mat4x4';
  var TYPE_RE = new RegExp('^(?:' + TYPES + ')$');

  /* ------------------------------------------------------------- library */
  // `sym` is the GLSL symbol; `first` is its first parameter type, which lets
  // us inject e.g. noise(vec3) even when the snippet defines noise(vec2).
  var LIB = [
    { key: 'hash11', sym: 'hash11', first: 'float', deps: [], proto: 'float hash11(float p);', body:
      'float hash11(float p){ p=fract(p*0.1031); p*=p+33.33; p*=p+p; return fract(p); }' },
    { key: 'hash12', sym: 'hash12', first: 'vec2', deps: [], proto: 'float hash12(vec2 p);', body:
      'float hash12(vec2 p){ vec3 p3=fract(vec3(p.xyx)*0.1031); p3+=dot(p3,p3.yzx+33.33); return fract((p3.x+p3.y)*p3.z); }' },
    { key: 'hash13', sym: 'hash13', first: 'vec3', deps: [], proto: 'float hash13(vec3 p);', body:
      'float hash13(vec3 p3){ p3=fract(p3*0.1031); p3+=dot(p3,p3.zyx+31.32); return fract((p3.x+p3.y)*p3.z); }' },
    { key: 'hash21', sym: 'hash21', first: 'float', deps: [], proto: 'vec2 hash21(float p);', body:
      'vec2 hash21(float p){ vec3 p3=fract(vec3(p)*vec3(0.1031,0.1030,0.0973)); p3+=dot(p3,p3.yzx+33.33); return fract((p3.xx+p3.yz)*p3.zy); }' },
    { key: 'hash22', sym: 'hash22', first: 'vec2', deps: [], proto: 'vec2 hash22(vec2 p);', body:
      'vec2 hash22(vec2 p){ vec3 p3=fract(vec3(p.xyx)*vec3(0.1031,0.1030,0.0973)); p3+=dot(p3,p3.yzx+33.33); return fract((p3.xx+p3.yz)*p3.zy); }' },
    { key: 'hash31', sym: 'hash31', first: 'float', deps: [], proto: 'vec3 hash31(float p);', body:
      'vec3 hash31(float p){ vec3 p3=fract(vec3(p)*vec3(0.1031,0.1030,0.0973)); p3+=dot(p3,p3.yzx+33.33); return fract((p3.xxy+p3.yzz)*p3.zyx); }' },
    { key: 'hash32', sym: 'hash32', first: 'vec2', deps: [], proto: 'vec3 hash32(vec2 p);', body:
      'vec3 hash32(vec2 p){ vec3 p3=fract(vec3(p.xyx)*vec3(0.1031,0.1030,0.0973)); p3+=dot(p3,p3.yxz+33.33); return fract((p3.xxy+p3.yzz)*p3.zyx); }' },
    { key: 'hash33', sym: 'hash33', first: 'vec3', deps: [], proto: 'vec3 hash33(vec3 p);', body:
      'vec3 hash33(vec3 p3){ p3=fract(p3*vec3(0.1031,0.1030,0.0973)); p3+=dot(p3,p3.yxz+33.33); return fract((p3.xxy+p3.yxx)*p3.zyx); }' },
    { key: 'hash1_f', sym: 'hash', first: 'float', deps: ['hash11'], proto: 'float hash(float p);', body:
      'float hash(float p){ return hash11(p); }' },
    { key: 'hash1_2', sym: 'hash', first: 'vec2', deps: ['hash12'], proto: 'float hash(vec2 p);', body:
      'float hash(vec2 p){ return hash12(p); }' },
    { key: 'hash1_3', sym: 'hash', first: 'vec3', deps: ['hash13'], proto: 'float hash(vec3 p);', body:
      'float hash(vec3 p){ return hash13(p); }' },
    { key: 'random2', sym: 'random', first: 'vec2', deps: ['hash12'], proto: 'float random(vec2 p);', body:
      'float random(vec2 p){ return hash12(p); }' },
    { key: 'noise2', sym: 'noise', first: 'vec2', deps: ['hash12'], proto: 'float noise(vec2 p);', body:
      'float noise(vec2 p){ vec2 i=floor(p), f=fract(p); vec2 u=f*f*(3.0-2.0*f);' +
      ' return mix(mix(hash12(i),hash12(i+vec2(1,0)),u.x), mix(hash12(i+vec2(0,1)),hash12(i+vec2(1,1)),u.x), u.y); }' },
    { key: 'noise3v', sym: 'noise', first: 'vec3', deps: ['hash13'], proto: 'float noise(vec3 p);', body:
      'float noise(vec3 p){ vec3 i=floor(p), f=fract(p); vec3 u=f*f*(3.0-2.0*f);' +
      ' return mix(mix(mix(hash13(i+vec3(0,0,0)),hash13(i+vec3(1,0,0)),u.x),' +
      ' mix(hash13(i+vec3(0,1,0)),hash13(i+vec3(1,1,0)),u.x),u.y),' +
      ' mix(mix(hash13(i+vec3(0,0,1)),hash13(i+vec3(1,0,1)),u.x),' +
      ' mix(hash13(i+vec3(0,1,1)),hash13(i+vec3(1,1,1)),u.x),u.y),u.z); }' },
    { key: 'noise1', sym: 'noise', first: 'float', deps: ['hash11'], proto: 'float noise(float p);', body:
      'float noise(float p){ float i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f); return mix(hash11(i),hash11(i+1.0),f); }' },
    { key: 'noise3f', sym: 'noise3', first: 'vec3', deps: ['noise3v'], proto: 'float noise3(vec3 p);', body:
      'float noise3(vec3 p){ return noise(p); }' },
    { key: 'vnoise', sym: 'valueNoise', first: 'vec2', deps: ['noise2'], proto: 'float valueNoise(vec2 p);', body:
      'float valueNoise(vec2 p){ return noise(p); }' },
    { key: 'fbm2', sym: 'fbm', first: 'vec2', deps: ['noise2'], proto: 'float fbm(vec2 p);', body:
      'float fbm(vec2 p){ float v=0.0,a=0.5; mat2 m=mat2(0.8,0.6,-0.6,0.8);' +
      ' for(int i=0;i<5;i++){ v+=a*noise(p); p=m*p*2.0; a*=0.5; } return v; }' },
    { key: 'fbm3v', sym: 'fbm', first: 'vec3', deps: ['noise3v'], proto: 'float fbm(vec3 p);', body:
      'float fbm(vec3 p){ float v=0.0,a=0.5; for(int i=0;i<5;i++){ v+=a*noise(p); p*=2.02; a*=0.5; } return v; }' },
    { key: 'fbm3f', sym: 'fbm3', first: 'vec3', deps: ['fbm3v'], proto: 'float fbm3(vec3 p);', body:
      'float fbm3(vec3 p){ return fbm(p); }' },
    // Post-processing chapters call these on an input image; point them at the
    // stand-in scene so blur / edge / hatching snippets actually draw something.
    { key: 'tex', sym: 'tex', first: 'vec2', deps: [], proto: 'vec3 tex(vec2 uv);', body:
      'vec3 tex(vec2 uv){ return stScene(uv).rgb; }', needsScene: true },
    { key: 'getCol', sym: 'getCol', first: 'vec2', deps: [], proto: 'vec4 getCol(vec2 uv);', body:
      'vec4 getCol(vec2 uv){ return stScene(uv/iResolution.xy); }', needsScene: true },
    { key: 'luma3', sym: 'luma', first: 'vec3', deps: [], proto: 'float luma(vec3 c);', body:
      'float luma(vec3 c){ return dot(c, vec3(0.299,0.587,0.114)); }' },
    { key: 'luma4', sym: 'luma', first: 'vec4', deps: [], proto: 'float luma(vec4 c);', body:
      'float luma(vec4 c){ return dot(c.rgb, vec3(0.299,0.587,0.114)); }' },
    { key: 'lum3', sym: 'luminance', first: 'vec3', deps: [], proto: 'float luminance(vec3 c);', body:
      'float luminance(vec3 c){ return dot(c, vec3(0.2126,0.7152,0.0722)); }' },
    { key: 'rot', sym: 'rot', first: 'float', deps: [], proto: 'mat2 rot(float a);', body:
      'mat2 rot(float a){ float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }' },
    { key: 'rot2', sym: 'rot2', first: 'float', deps: [], proto: 'mat2 rot2(float a);', body:
      'mat2 rot2(float a){ float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }' },
    { key: 'r2d', sym: 'rotate2D', first: 'float', deps: [], proto: 'mat2 rotate2D(float a);', body:
      'mat2 rotate2D(float a){ float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }' },
    { key: 'smin', sym: 'smin', first: 'float', deps: [], proto: 'float smin(float a, float b, float k);', body:
      'float smin(float a,float b,float k){ float h=clamp(0.5+0.5*(b-a)/k,0.0,1.0); return mix(b,a,h)-k*h*(1.0-h); }' },
    { key: 'smax', sym: 'smax', first: 'float', deps: [], proto: 'float smax(float a, float b, float k);', body:
      'float smax(float a,float b,float k){ float h=clamp(0.5-0.5*(b-a)/k,0.0,1.0); return mix(a,b,h)+k*h*(1.0-h); }' },
    { key: 'sdCircle', sym: 'sdCircle', first: 'vec2', deps: [], proto: 'float sdCircle(vec2 p, float r);', body:
      'float sdCircle(vec2 p,float r){ return length(p)-r; }' },
    { key: 'sdBox2', sym: 'sdBox', first: 'vec2', deps: [], proto: 'float sdBox(vec2 p, vec2 b);', body:
      'float sdBox(vec2 p,vec2 b){ vec2 d=abs(p)-b; return min(max(d.x,d.y),0.0)+length(max(d,0.0)); }' },
    { key: 'sdBox3', sym: 'sdBox', first: 'vec3', deps: [], proto: 'float sdBox(vec3 p, vec3 b);', body:
      'float sdBox(vec3 p,vec3 b){ vec3 d=abs(p)-b; return min(max(d.x,max(d.y,d.z)),0.0)+length(max(d,0.0)); }' },
    { key: 'sdSphere', sym: 'sdSphere', first: 'vec3', deps: [], proto: 'float sdSphere(vec3 p, float r);', body:
      'float sdSphere(vec3 p,float r){ return length(p)-r; }' },
    { key: 'sdPlane', sym: 'sdPlane', first: 'vec3', deps: [], proto: 'float sdPlane(vec3 p, vec4 n);', body:
      'float sdPlane(vec3 p,vec4 n){ return dot(p,normalize(n.xyz))+n.w; }' },
    { key: 'sdTorus', sym: 'sdTorus', first: 'vec3', deps: [], proto: 'float sdTorus(vec3 p, vec2 t);', body:
      'float sdTorus(vec3 p,vec2 t){ vec2 q=vec2(length(p.xz)-t.x,p.y); return length(q)-t.y; }' },
    { key: 'palette', sym: 'palette', first: 'float', deps: [], proto: 'vec3 palette(float t);', body:
      'vec3 palette(float t){ return 0.5+0.5*cos(6.28318*(vec3(1.0)*t+vec3(0.0,0.33,0.67))); }' },
    { key: 'map', sym: 'map', first: 'vec3', deps: [], proto: 'float map(vec3 p);', body:
      'float map(vec3 p){ float d=length(p)-1.0; d=min(d,p.y+1.0); return d; }' },
    { key: 'sdf', sym: 'sdf', first: 'vec3', deps: ['map'], proto: 'float sdf(vec3 p);', body:
      'float sdf(vec3 p){ return map(p); }' },
    { key: 'scene', sym: 'scene', first: 'vec3', deps: ['map'], proto: 'float scene(vec3 p);', body:
      'float scene(vec3 p){ return map(p); }' },
    { key: 'map2', sym: 'map2', first: 'vec3', deps: ['map'], proto: 'vec2 map2(vec3 p);', body:
      'vec2 map2(vec3 p){ return vec2(map(p),1.0); }' },
    { key: 'calcNormal', sym: 'calcNormal', first: 'vec3', deps: ['map'], proto: 'vec3 calcNormal(vec3 p);', body:
      'vec3 calcNormal(vec3 p){ vec2 e=vec2(0.0015,0.0);' +
      ' return normalize(vec3(__MAP(p+e.xyy)-__MAP(p-e.xyy),__MAP(p+e.yxy)-__MAP(p-e.yxy),__MAP(p+e.yyx)-__MAP(p-e.yyx))); }' },
    { key: 'getNormal', sym: 'getNormal', first: 'vec3', deps: ['calcNormal'], proto: 'vec3 getNormal(vec3 p);', body:
      'vec3 getNormal(vec3 p){ return calcNormal(p); }' },
    { key: 'softshadow', sym: 'softshadow', first: 'vec3', deps: ['map'], proto: 'float softshadow(vec3 ro, vec3 rd, float mint, float maxt, float k);', body:
      'float softshadow(vec3 ro,vec3 rd,float mint,float maxt,float k){ float res=1.0,t=mint;' +
      ' for(int i=0;i<48;i++){ float h=__MAP(ro+rd*t); res=min(res,k*h/t); t+=clamp(h,0.01,0.2); if(res<0.004||t>maxt)break; }' +
      ' return clamp(res,0.0,1.0); }' },
    { key: 'calcAO', sym: 'calcAO', first: 'vec3', deps: ['map'], proto: 'float calcAO(vec3 pos, vec3 nor);', body:
      'float calcAO(vec3 pos,vec3 nor){ float occ=0.0,sca=1.0;' +
      ' for(int i=0;i<5;i++){ float h=0.01+0.12*float(i)/4.0; occ+=(h-__MAP(pos+h*nor))*sca; sca*=0.95; }' +
      ' return clamp(1.0-3.0*occ,0.0,1.0); }' },
    { key: 'raymarch', sym: 'raymarch', first: 'vec3', deps: ['map'], proto: 'float raymarch(vec3 ro, vec3 rd);', body:
      'float raymarch(vec3 ro,vec3 rd){ float t=0.0; for(int i=0;i<128;i++){ float h=__MAP(ro+rd*t);' +
      ' if(h<0.001*t+0.001||t>40.0) break; t+=h; } return t; }' },
    { key: 'calcSoft', sym: 'calcSoftshadow', first: 'vec3', deps: ['softshadow'], proto: 'float calcSoftshadow(vec3 ro, vec3 rd, float mint, float maxt);', body:
      'float calcSoftshadow(vec3 ro,vec3 rd,float mint,float maxt){ return softshadow(ro,rd,mint,maxt,8.0); }' },
    { key: 'pal1', sym: 'pal', first: 'float', deps: ['palette'], proto: 'vec3 pal(float t);', body:
      'vec3 pal(float t){ return palette(t); }' },
    { key: 'pal5', sym: 'pal', first: 'float', deps: [], proto: 'vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d);', body:
      'vec3 pal(float t,vec3 a,vec3 b,vec3 c,vec3 d){ return a+b*cos(6.28318*(c*t+d)); }' },
    { key: 'palette5', sym: 'palette', first: 'float', deps: [], proto: 'vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d);', body:
      'vec3 palette(float t,vec3 a,vec3 b,vec3 c,vec3 d){ return a+b*cos(6.28318*(c*t+d)); }' },
    { key: 'hsv2rgb', sym: 'hsv2rgb', first: 'vec3', deps: [], proto: 'vec3 hsv2rgb(vec3 c);', body:
      'vec3 hsv2rgb(vec3 c){ vec3 p=abs(fract(c.xxx+vec3(1.0,2.0/3.0,1.0/3.0))*6.0-3.0);' +
      ' return c.z*mix(vec3(1.0),clamp(p-1.0,0.0,1.0),c.y); }' },
    { key: 'rgb2hsv', sym: 'rgb2hsv', first: 'vec3', deps: [], proto: 'vec3 rgb2hsv(vec3 c);', body:
      'vec3 rgb2hsv(vec3 c){ vec4 K=vec4(0.0,-1.0/3.0,2.0/3.0,-1.0);' +
      ' vec4 p=mix(vec4(c.bg,K.wz),vec4(c.gb,K.xy),step(c.b,c.g));' +
      ' vec4 q=mix(vec4(p.xyw,c.r),vec4(c.r,p.yzx),step(p.x,c.r));' +
      ' float d=q.x-min(q.w,q.y); float e=1.0e-10;' +
      ' return vec3(abs(q.z+(q.w-q.y)/(6.0*d+e)),d/(q.x+e),q.x); }' },
    { key: 'aces', sym: 'aces', first: 'vec3', deps: [], proto: 'vec3 aces(vec3 x);', body:
      'vec3 aces(vec3 x){ return clamp((x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14),0.0,1.0); }' },
    { key: 'acesFilm', sym: 'ACESFilm', first: 'vec3', deps: ['aces'], proto: 'vec3 ACESFilm(vec3 x);', body:
      'vec3 ACESFilm(vec3 x){ return aces(x); }' },
    { key: 'tonemap', sym: 'tonemap', first: 'vec3', deps: ['aces'], proto: 'vec3 tonemap(vec3 x);', body:
      'vec3 tonemap(vec3 x){ return aces(x); }' },
    { key: 'saturate1', sym: 'saturate', first: 'float', deps: [], proto: 'float saturate(float x);', body:
      'float saturate(float x){ return clamp(x,0.0,1.0); }' },
    { key: 'saturate3', sym: 'saturate', first: 'vec3', deps: [], proto: 'vec3 saturate(vec3 x);', body:
      'vec3 saturate(vec3 x){ return clamp(x,0.0,1.0); }' },
    { key: 'sdSegment', sym: 'sdSegment', first: 'vec2', deps: [], proto: 'float sdSegment(vec2 p, vec2 a, vec2 b);', body:
      'float sdSegment(vec2 p,vec2 a,vec2 b){ vec2 pa=p-a,ba=b-a;' +
      ' float h=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0); return length(pa-ba*h); }' },
    { key: 'sdRoundBox', sym: 'sdRoundBox', first: 'vec2', deps: ['sdBox2'], proto: 'float sdRoundBox(vec2 p, vec2 b, float r);', body:
      'float sdRoundBox(vec2 p,vec2 b,float r){ return sdBox(p,b)-r; }' },
    { key: 'opSmoothUnion', sym: 'opSmoothUnion', first: 'float', deps: ['smin'], proto: 'float opSmoothUnion(float a, float b, float k);', body:
      'float opSmoothUnion(float a,float b,float k){ return smin(a,b,k); }' },
    { key: 'opU', sym: 'opU', first: 'vec2', deps: [], proto: 'vec2 opU(vec2 a, vec2 b);', body:
      'vec2 opU(vec2 a,vec2 b){ return (a.x<b.x)?a:b; }' },
    { key: 'checker', sym: 'checker', first: 'vec2', deps: [], proto: 'float checker(vec2 p);', body:
      'float checker(vec2 p){ vec2 q=floor(p); return mod(q.x+q.y,2.0); }' },
    { key: 'voronoi', sym: 'voronoi', first: 'vec2', deps: ['hash22'], proto: 'float voronoi(vec2 p);', body:
      'float voronoi(vec2 p){ vec2 n=floor(p), f=fract(p); float md=8.0;' +
      ' for(int j=-1;j<=1;j++) for(int i=-1;i<=1;i++){ vec2 g=vec2(float(i),float(j));' +
      ' vec2 o=hash22(n+g); o=0.5+0.5*sin(iTime+6.2831*o); md=min(md,length(g+o-f)); } return md; }' }
  ];

  LIB.forEach(function (e) {
    var inner = e.proto.slice(e.proto.indexOf('(') + 1, e.proto.lastIndexOf(')')).trim();
    e.arity = inner ? inner.split(',').length : 0;
  });

  var LIB_BY_KEY = {};
  LIB.forEach(function (e) { LIB_BY_KEY[e.key] = e; });

  var LIB_SYMS = Object.create(null);
  LIB.forEach(function (e) { LIB_SYMS[e.sym] = true; });

  /* ---------------------------------------------------- top-level parsing */

  /** Blank out comments so brace counting and regexes see only real code. */
  function blankComments(code) {
    var out = code.split('');
    var i = 0, n = code.length;
    while (i < n) {
      if (code[i] === '/' && code[i + 1] === '/') {
        while (i < n && code[i] !== '\n') { out[i] = ' '; i++; }
      } else if (code[i] === '/' && code[i + 1] === '*') {
        out[i] = out[i + 1] = ' '; i += 2;
        while (i < n && !(code[i] === '*' && code[i + 1] === '/')) {
          if (code[i] !== '\n') out[i] = ' ';
          i++;
        }
        if (i < n) { out[i] = out[i + 1] = ' '; i += 2; }
      } else i++;
    }
    return out.join('');
  }

  function parseParams(raw) {
    var s = raw.trim();
    if (!s || s === 'void') return [];
    return s.split(',').map(function (part) {
      var toks = part.trim().split(/\s+/).filter(function (t) {
        return !/^(in|out|inout|const|highp|mediump|lowp)$/.test(t);
      });
      return { type: toks[0] || '', name: (toks[1] || '').replace(/\[.*$/, '') };
    });
  }

  var HEAD_RE = new RegExp('(?:const[ \\t]+)?(?:lowp|mediump|highp)?[ \\t]*(' + TYPES + ')[ \\t\\r\\n]+([A-Za-z_]\\w*)[ \\t\\r\\n]*\\(([^)]*)\\)[ \\t\\r\\n]*\\{', 'g');

  /**
   * Split a snippet into what belongs at file scope (functions, structs,
   * consts, preprocessor) and what is a loose statement needing a shell.
   */
  function splitTopLevel(code) {
    var clean = blankComments(code);
    var n = code.length;

    // Depth at each character, ignoring preprocessor lines.
    var depth = new Int16Array(n + 1);
    var d = 0;
    for (var i = 0; i < n; i++) {
      var c = clean[i];
      depth[i] = d;
      if (c === '{') d++;
      else if (c === '}') d = Math.max(0, d - 1);
    }
    depth[n] = d;

    var ranges = [];   // [start, end) chunks that belong at file scope
    var funcs = [];

    // Functions defined at depth 0.
    HEAD_RE.lastIndex = 0;
    var m;
    while ((m = HEAD_RE.exec(clean))) {
      if (depth[m.index] !== 0) continue;
      var open = m.index + m[0].length - 1;
      var lvl = 1, j = open + 1;
      while (j < n && lvl > 0) {
        if (clean[j] === '{') lvl++;
        else if (clean[j] === '}') lvl--;
        j++;
      }
      if (lvl !== 0) continue;   // unterminated: leave it to the error report
      // Walk back over the return type so the whole definition is captured.
      var start = m.index;
      while (start > 0 && /[ \t]/.test(code[start - 1])) start--;
      ranges.push([start, j]);
      funcs.push({ ret: m[1], name: m[2], params: parseParams(m[3]), start: start, end: j });
      HEAD_RE.lastIndex = j;
    }

    // Structs, file-scope consts/uniforms and preprocessor lines.
    var sre = /\bstruct\s+[A-Za-z_]\w*\s*\{/g;
    while ((m = sre.exec(clean))) {
      if (depth[m.index] !== 0) continue;
      var k = m.index + m[0].length, l2 = 1;
      while (k < n && l2 > 0) { if (clean[k] === '{') l2++; else if (clean[k] === '}') l2--; k++; }
      while (k < n && /[\s;]/.test(code[k])) k++;
      ranges.push([m.index, k]);
    }
    var lre = /(^|\n)([ \t]*)(#[^\n]*|(?:const|uniform|varying|attribute|precision|layout)\b[^;\n]*;)/g;
    while ((m = lre.exec(clean))) {
      var s0 = m.index + m[1].length;
      if (depth[s0] !== 0) continue;
      ranges.push([s0, s0 + m[2].length + m[3].length]);
    }

    ranges.sort(function (a, b) { return a[0] - b[0]; });
    var top = '', loose = '', cursor = 0;
    ranges.forEach(function (r) {
      if (r[0] < cursor) return;
      loose += code.slice(cursor, r[0]);
      top += code.slice(r[0], r[1]) + '\n';
      cursor = r[1];
    });
    loose += code.slice(cursor);

    return { top: top, loose: loose, funcs: funcs, clean: clean };
  }

  function analyze(code) {
    var split = splitTopLevel(code);
    var refs = Object.create(null);
    (split.clean.match(/[A-Za-z_]\w*/g) || []).forEach(function (w) { refs[w] = true; });
    var defined = Object.create(null);
    split.funcs.forEach(function (f) {
      (defined[f.name] = defined[f.name] || []).push(f);
    });
    return {
      split: split, refs: refs, defined: defined, funcs: split.funcs,
      hasMain: !!defined['mainImage'],
      // Comment-only leftovers ("// 用法：…") are not runnable statements.
      looseIsEmpty: !/\S/.test(blankComments(split.loose)),
      samplesChannel: SAMPLES_CHANNEL.test(blankComments(code)),
      declaredVars: anyDeclarations(split.clean)
    };
  }

  /* --------------------------------------------------- library injection */

  function buildLib(info, extraRefs) {
    var refs = info.refs;
    var want = Object.create(null);

    // GLSL resolves overloads by full signature, so only a definition with the
    // same name, arity and first parameter type actually shadows a helper.
    function alreadyDefined(e) {
      // A user variable with the helper's name shadows it and makes the call
      // site a syntax error, so never inject over one.
      if (info.declaredVars && info.declaredVars[e.sym]) return true;
      var list = info.defined[e.sym];
      if (!list) return false;
      return list.some(function (f) {
        return f.params.length === e.arity &&
          (!e.arity || f.params[0].type === e.first);
      });
    }

    function need(key) {
      var e = LIB_BY_KEY[key];
      if (!e || want[key]) return;
      if (alreadyDefined(e)) return;
      want[key] = true;
      e.deps.forEach(need);
    }

    LIB.forEach(function (e) {
      if (refs[e.sym] || (extraRefs && extraRefs[e.sym])) need(e.key);
    });

    // Helpers that differentiate the scene need the snippet's own map().
    var userMap = (info.defined['map'] || [])[0];
    var protos = [], bodies = [], needsScene = false;
    LIB.forEach(function (e) {
      if (!want[e.key]) return;
      if (e.needsScene) needsScene = true;
      var body = e.body;
      if (body.indexOf('__MAP') >= 0) {
        var call = userMap
          ? (userMap.ret === 'float' ? 'map($)' : 'map($).x')
          : 'map($)';
        body = body.replace(/__MAP\(([^()]*(?:\([^()]*\)[^()]*)*)\)/g, function (mm, arg) {
          return call.replace('$', arg);
        });
      }
      protos.push(e.proto);
      bodies.push(body);
    });
    return { protos: protos.join('\n'), bodies: bodies.join('\n'), needsScene: needsScene };
  }

  /* -------------------------------------------------- undeclared symbols */

  var RESERVED = new Set(('if else for while do break continue return discard struct const uniform varying ' +
    'attribute in out inout layout precision highp mediump lowp switch case default true false ' +
    'sampler2D samplerCube sampler3D void ' +
    'abs acos all any asin atan ceil clamp cos cosh cross degrees determinant dFdx dFdy distance dot ' +
    'equal exp exp2 faceforward floor fract fwidth greaterThan greaterThanEqual inverse inversesqrt ' +
    'length lessThan lessThanEqual log log2 matrixCompMult max min mix mod modf normalize not notEqual ' +
    'outerProduct pow radians reflect refract round roundEven sign sin sinh smoothstep sqrt step tan ' +
    'tanh texture textureLod textureGrad textureProj texelFetch textureSize transpose trunc isnan isinf ' +
    'floatBitsToInt intBitsToFloat packSnorm2x16 unpackSnorm2x16 ' +
    'iResolution iTime iTimeDelta iFrame iFrameRate iMouse iDate iSampleRate iChannelTime iChannelResolution ' +
    'iChannel0 iChannel1 iChannel2 iChannel3 fragColor fragCoord mainImage main uArg uZoom uMode').split(/\s+/));

  var SWZ_RE = /^[xyzwrgbastpq]{1,4}$/;
  var COMP_INDEX = { x: 1, y: 2, z: 3, w: 4, r: 1, g: 2, b: 3, a: 4, s: 1, t: 2, p: 3, q: 4 };

  /** Names declared at the statement level of a fragment (nested ones shadow). */
  function topLevelDeclarations(clean) {
    var out = Object.create(null);
    var brace = 0, paren = 0;
    var re = /([{}()])|\b(#define)\s+([A-Za-z_]\w*)|\b(?:TYPES)\s+([A-Za-z_]\w*((?:\s*,\s*[A-Za-z_]\w*)*))/g;
    re = new RegExp('([{}()])|\\b(#define)\\s+([A-Za-z_]\\w*)|\\b(?:' + TYPES + ')\\s+([A-Za-z_]\\w*(?:\\s*,\\s*[A-Za-z_]\\w*)*)', 'g');
    var m;
    while ((m = re.exec(clean))) {
      if (m[1]) {
        if (m[1] === '{') brace++;
        else if (m[1] === '}') brace = Math.max(0, brace - 1);
        else if (m[1] === '(') paren++;
        else paren = Math.max(0, paren - 1);
        continue;
      }
      if (brace > 0 || paren > 0) continue;
      if (m[2]) { out[m[3]] = true; continue; }
      m[4].split(',').forEach(function (w) { out[w.trim()] = true; });
    }
    return out;
  }

  /** All names declared anywhere, used to avoid inventing duplicates. */
  function anyDeclarations(clean) {
    var out = Object.create(null);
    var m;
    var dre = new RegExp('\\b(?:' + TYPES + ')\\s+([A-Za-z_]\\w*(?:\\s*,\\s*[A-Za-z_]\\w*)*)', 'g');
    while ((m = dre.exec(clean))) m[1].split(',').forEach(function (w) { out[w.trim()] = true; });
    var pre = /#define\s+([A-Za-z_]\w*)/g;
    while ((m = pre.exec(clean))) out[m[1]] = true;
    return out;
  }

  /**
   * Guess declarations for identifiers a fragment uses but never defines --
   * they came from the surrounding code the handbook did not quote.
   */
  function inferUndeclared(loose, known) {
    var clean = blankComments(loose);
    var declared = anyDeclarations(clean);
    var m;

    var uses = Object.create(null);
    var re = /(\.\s*)?\b([A-Za-z_]\w*)\b[ \t]*([([]?)/g;
    while ((m = re.exec(clean))) {
      var name = m[2];
      if (m[1]) continue;                       // member / swizzle
      if (m[3] === '(') continue;               // call or constructor
      if (RESERVED.has(name) || TYPE_RE.test(name)) continue;
      if (declared[name] || known[name] || LIB_SYMS[name]) continue;
      if (/^gl_/.test(name)) continue;
      // `Material m;` -- a user type, not a variable.
      var rest = clean.slice(m.index + (m[1] ? m[1].length : 0));
      var pair = rest.match(/^([A-Za-z_]\w*)[ \t]+([A-Za-z_]\w*)/);
      if (pair && !RESERVED.has(pair[2])) continue;
      uses[name] = true;
    }

    return Object.keys(uses).slice(0, 24).map(function (name) {
      var size = 0;
      var sre = new RegExp('\\b' + name + '\\s*\\.\\s*([A-Za-z]+)', 'g');
      var mm;
      while ((mm = sre.exec(clean))) {
        if (!SWZ_RE.test(mm[1])) continue;
        size = Math.max(size, mm[1].length);
        for (var i = 0; i < mm[1].length; i++) size = Math.max(size, COMP_INDEX[mm[1][i]] || 1);
      }
      // A scalar cannot be swizzled at all in GLSL ES.
      if (size === 1) size = 2;
      var asg = new RegExp('\\b' + name + '\\s*=\\s*(vec([234])|texture\\b|mat([234]))').exec(clean);
      if (asg) {
        if (asg[2]) size = Math.max(size, parseInt(asg[2], 10));
        else if (asg[3]) return 'mat' + asg[3] + ' ' + name + ' = mat' + asg[3] + '(1.0);';
        else size = 4;
      }
      if (!size) return 'float ' + name + ' = 0.0;';
      return 'vec' + size + ' ' + name + ' = vec' + size + '(0.0);';
    });
  }

  /* ------------------------------------------------------------ harness */

  var ARG_SWZ = { float: '.x', vec2: '.xy', vec3: '.xyz', vec4: '' };

  function argExpr(type, idx) {
    if (type === 'int') return 'int(uArg[' + idx + '].x)';
    if (type === 'bool') return '(uArg[' + idx + '].x > 0.5)';
    if (type === 'mat2') return 'mat2(uArg[' + idx + '].x,uArg[' + idx + '].y,uArg[' + idx + '].z,uArg[' + idx + '].w)';
    if (ARG_SWZ[type] !== undefined) return 'uArg[' + idx + ']' + ARG_SWZ[type];
    return 'uArg[' + idx + '].x';
  }

  var ARG_DEFAULT = {
    float: [0.35, 0, 0, 0],
    vec2: [0.45, 0.28, 0, 0],
    vec3: [0.45, 0.3, 0.25, 0],
    vec4: [0.45, 0.3, 0.25, 1.0],
    int: [4, 0, 0, 0],
    bool: [1, 0, 0, 0],
    mat2: [1, 0, 0, 1]
  };

  var CAMERA =
    '  float an=iTime*0.35;\n' +
    '  if(iMouse.z>0.0) an=6.2831*(iMouse.x/iResolution.x-0.5);\n' +
    '  float hgt=1.3; if(iMouse.z>0.0) hgt=mix(-0.6,3.2,iMouse.y/iResolution.y);\n' +
    '  vec3 ro=vec3(3.4*sin(an),hgt,3.4*cos(an))*uZoom;\n' +
    '  vec3 ta=vec3(0.0);\n' +
    '  vec3 ww=normalize(ta-ro), uu=normalize(cross(ww,vec3(0.0,1.0,0.0))), vv=cross(uu,ww);\n' +
    '  vec3 rd=normalize(uv.x*uu+uv.y*vv+1.7*ww);\n';

  var HARNESS = {
    field2: function (call) {
      return 'void mainImage(out vec4 O, in vec2 F){\n' +
        '  vec2 uv=(2.0*F-iResolution.xy)/iResolution.y*uZoom;\n' +
        '  float d=' + call + ';\n' +
        '  vec3 c;\n' +
        '  if(uMode<0.5){\n' +
        '    c = (d>0.0)?vec3(0.30,0.52,0.82):vec3(0.96,0.58,0.30);\n' +
        '    c *= 1.0-exp(-5.0*abs(d));\n' +
        '    c *= 0.86+0.14*cos(140.0*d/uZoom);\n' +
        '    c = mix(c, vec3(1.0), 1.0-smoothstep(0.0,0.008*uZoom,abs(d)));\n' +
        '  } else if(uMode<1.5){ c = vec3(clamp(d,0.0,1.0));\n' +
        '  } else { c = 0.5+0.5*cos(6.28318*(vec3(1.0)*d+vec3(0.0,0.33,0.67))); }\n' +
        '  O=vec4(c,1.0);\n}';
    },
    color2: function (call, swz) {
      return 'void mainImage(out vec4 O, in vec2 F){\n' +
        '  vec2 uv=(2.0*F-iResolution.xy)/iResolution.y*uZoom;\n' +
        '  vec3 c=(' + call + ')' + (swz || '') + ';\n' +
        '  O=vec4(clamp(c,0.0,1.0),1.0);\n}';
    },
    warp2: function (call) {
      return 'void mainImage(out vec4 O, in vec2 F){\n' +
        '  vec2 uv=(2.0*F-iResolution.xy)/iResolution.y*uZoom;\n' +
        '  vec2 w=' + call + ';\n' +
        '  vec2 g=abs(fract(w*2.0)-0.5);\n' +
        '  float line=1.0-smoothstep(0.0,0.06,min(g.x,g.y));\n' +
        '  float chk=mod(floor(w.x*2.0)+floor(w.y*2.0),2.0);\n' +
        '  vec3 c=mix(vec3(0.07,0.09,0.13),vec3(0.16,0.20,0.28),chk);\n' +
        '  c=mix(c,vec3(0.55,0.85,1.0),line);\n' +
        '  O=vec4(c,1.0);\n}';
    },
    curve1: function (call) {
      return 'void mainImage(out vec4 O, in vec2 F){\n' +
        '  vec2 uv=(2.0*F-iResolution.xy)/iResolution.y*uZoom;\n' +
        '  float y=' + call + ';\n' +
        '  float px=uZoom*2.6/iResolution.y;\n' +
        '  vec3 c=vec3(0.055,0.065,0.085);\n' +
        '  vec2 g=abs(fract(uv)-0.5);\n' +
        '  c+=0.05*(1.0-smoothstep(0.0,px,min(g.x,g.y)));\n' +
        '  c=mix(c,vec3(0.30,0.34,0.42),1.0-smoothstep(0.0,px,min(abs(uv.x),abs(uv.y))));\n' +
        '  c=mix(c,vec3(1.0,0.75,0.35),1.0-smoothstep(px,px*2.5,abs(uv.y-y)));\n' +
        '  c+=vec3(1.0,0.6,0.2)*0.10*exp(-abs(uv.y-y)*9.0);\n' +
        '  O=vec4(c,1.0);\n}';
    },
    palette1: function (call) {
      return 'void mainImage(out vec4 O, in vec2 F){\n' +
        '  vec2 u=F/iResolution.xy;\n' +
        '  float t=u.x+iTime*0.04;\n' +
        '  vec3 c=' + call + ';\n' +
        '  c=clamp(c,0.0,1.0);\n' +
        '  float band=smoothstep(0.02,0.06,u.y)*smoothstep(0.98,0.94,u.y);\n' +
        '  c=mix(vec3(0.05),c,band);\n' +
        '  O=vec4(c,1.0);\n}';
    },
    mat2rot: function (call) {
      return 'void mainImage(out vec4 O, in vec2 F){\n' +
        '  vec2 uv=(2.0*F-iResolution.xy)/iResolution.y*uZoom;\n' +
        '  mat2 m=' + call + ';\n' +
        '  vec2 q=m*uv;\n' +
        '  vec2 dd=abs(q)-vec2(0.55,0.32);\n' +
        '  float box=min(max(dd.x,dd.y),0.0)+length(max(dd,0.0));\n' +
        '  float px=uZoom*2.6/iResolution.y;\n' +
        '  vec3 c=vec3(0.06,0.07,0.10);\n' +
        '  c=mix(c,vec3(0.20,0.55,0.95),smoothstep(px,-px,box));\n' +
        '  c=mix(c,vec3(1.0,0.85,0.4),1.0-smoothstep(px,px*2.5,abs(box)));\n' +
        '  O=vec4(c,1.0);\n}';
    },
    map3: function () {
      return 'void mainImage(out vec4 O, in vec2 F){\n' +
        '  vec2 uv=(2.0*F-iResolution.xy)/iResolution.y;\n' + CAMERA +
        '  float t=0.0; bool hit=false;\n' +
        '  for(int i=0;i<160;i++){ vec3 p=ro+rd*t; float h=__H(p);\n' +
        '    if(h<0.0008*t+0.0008){ hit=true; break; }\n' +
        '    t+=h*0.85; if(t>50.0) break; }\n' +
        '  vec3 c=mix(vec3(0.006,0.008,0.013),vec3(0.020,0.028,0.045),0.5+0.5*rd.y);\n' +
        '  if(hit){\n' +
        '    vec3 pos=ro+rd*t; vec2 e=vec2(0.0015,0.0);\n' +
        '    vec3 nor=normalize(vec3(__H(pos+e.xyy)-__H(pos-e.xyy),__H(pos+e.yxy)-__H(pos-e.yxy),__H(pos+e.yyx)-__H(pos-e.yyx)));\n' +
        '    vec3 lig=normalize(vec3(0.7,0.85,0.35));\n' +
        '    float dif=clamp(dot(nor,lig),0.0,1.0);\n' +
        '    float amb=0.5+0.5*nor.y;\n' +
        '    float fre=pow(clamp(1.0+dot(rd,nor),0.0,1.0),3.0);\n' +
        '    c=vec3(0.26,0.30,0.35)*amb+vec3(1.0,0.92,0.78)*dif;\n' +
        '    c+=vec3(0.35,0.55,0.9)*fre*0.4;\n' +
        '    c*=exp(-0.035*t);\n' +
        '  }\n' +
        '  O=vec4(pow(clamp(c,0.0,1.0),vec3(0.4545)),1.0);\n}';
    },
    render3: function (call, swz) {
      return 'void mainImage(out vec4 O, in vec2 F){\n' +
        '  vec2 uv=(2.0*F-iResolution.xy)/iResolution.y;\n' + CAMERA +
        '  vec3 c=(' + call + ')' + (swz || '') + ';\n' +
        '  O=vec4(clamp(c,0.0,1.0),1.0);\n}';
    },
    trace3: function (call) {
      return 'void mainImage(out vec4 O, in vec2 F){\n' +
        '  vec2 uv=(2.0*F-iResolution.xy)/iResolution.y;\n' + CAMERA +
        '  float t=' + call + ';\n' +
        '  vec3 c = (t>0.0 && t<49.0)\n' +
        '    ? 0.5+0.5*cos(vec3(0.0,0.6,1.2)+t*0.7)\n' +
        '    : vec3(0.04,0.05,0.07);\n' +
        '  O=vec4(c,1.0);\n}';
    }
  };

  var MODE_LABELS = { field2: ['SDF 可视化', '灰度场', '调色板'] };

  var RAY_NAMES = /^(ro|rd|o|d|dir|org|orig|origin|eye|cam|camPos|rayDir|ray)$/i;
  var RENDER_NAMES = /(render|shade|trace|raycast|raymarch|sky|scene|march|cast|lighting|light)/i;
  // These return a value, not a distance: draw the value, don't raymarch it.
  var FIELD_NAMES = /^(hash|rand|random|noise|fbm|turb|turbulence|voronoi|worley|perlin|simplex|value|gradient|cellular|curl|ridge|billow)/i;

  // Slice a 3-D field with an animated z plane instead of tracing it.
  var SLICE = 'vec3(uv, iTime*0.15)';

  function harnessFor(fn) {
    var p = fn.params, ret = fn.ret, name = fn.name;
    if (!p.length) return null;
    var t0 = p[0].type, t1 = p[1] ? p[1].type : null;

    if (FIELD_NAMES.test(name)) {
      if (t0 === 'vec2') {
        if (ret === 'float') return { kind: 'field2', drive: ['uv'], defaultMode: 1 };
        if (ret === 'vec2') return { kind: 'color2', drive: ['uv'], wrap: 'vec3(%, 0.5)' };
        if (ret === 'vec3') return { kind: 'color2', drive: ['uv'] };
        if (ret === 'vec4') return { kind: 'color2', drive: ['uv'], swz: '.xyz' };
      }
      if (t0 === 'vec3') {
        if (ret === 'float') return { kind: 'color2', drive: [SLICE], wrap: 'vec3(%)' };
        if (ret === 'vec2') return { kind: 'color2', drive: [SLICE], wrap: 'vec3(%, 0.5)' };
        if (ret === 'vec3') return { kind: 'color2', drive: [SLICE] };
        if (ret === 'vec4') return { kind: 'color2', drive: [SLICE], swz: '.xyz' };
      }
      if (t0 === 'float') {
        if (ret === 'float') return { kind: 'curve1', drive: ['uv.x'] };
        if (ret === 'vec2') return { kind: 'color2', drive: ['uv.x'], wrap: 'vec3(%, 0.5)' };
        if (ret === 'vec3') return { kind: 'color2', drive: ['uv.x'] };
      }
    }

    var raylike = t0 === 'vec3' && t1 === 'vec3' &&
      (RAY_NAMES.test(p[0].name) && RAY_NAMES.test(p[1].name) || RENDER_NAMES.test(name));

    if (raylike) {
      if (ret === 'vec3') return { kind: 'render3', drive: ['ro', 'rd'] };
      if (ret === 'vec4') return { kind: 'render3', drive: ['ro', 'rd'], swz: '.xyz' };
      if (ret === 'float') return { kind: 'trace3', drive: ['ro', 'rd'] };
      if (ret === 'vec2') return { kind: 'trace3', drive: ['ro', 'rd'], post: '.x' };
      return null;
    }
    if (t0 === 'vec2') {
      if (ret === 'float') return { kind: 'field2', drive: ['uv'] };
      if (ret === 'vec3') return { kind: 'color2', drive: ['uv'] };
      if (ret === 'vec4') return { kind: 'color2', drive: ['uv'], swz: '.xyz' };
      if (ret === 'vec2') return { kind: 'warp2', drive: ['uv'] };
      return null;
    }
    if (t0 === 'vec3') {
      if (ret === 'float') return { kind: 'map3', drive: ['p'] };
      if (ret === 'vec2') return { kind: 'map3', drive: ['p'], swz: '.x' };
      if (ret === 'vec4') return { kind: 'map3', drive: ['p'], swz: '.x' };
      return null;
    }
    if (t0 === 'float') {
      if (ret === 'vec3') return { kind: 'palette1', drive: ['t'] };
      if (ret === 'vec4') return { kind: 'palette1', drive: ['t'], swz: '.xyz' };
      if (ret === 'float') return { kind: 'curve1', drive: ['uv.x'] };
      if (ret === 'mat2') return { kind: 'mat2rot', drive: ['iTime'] };
      return null;
    }
    return null;
  }

  function harnessArgs(fn, h) {
    return fn.params.slice(h.drive.length).map(function (prm, k) {
      var def = ARG_DEFAULT[prm.type] || ARG_DEFAULT.float;
      return { index: k, type: prm.type, name: prm.name || ('arg' + (k + 1)), value: def.slice() };
    });
  }

  function buildCall(fn, h, driveOverride) {
    var args = (driveOverride || h.drive).slice();
    fn.params.slice(h.drive.length).forEach(function (prm, k) { args.push(argExpr(prm.type, k)); });
    return fn.name + '(' + args.join(', ') + ')';
  }

  function makeHarness(fn, h) {
    if (h.kind === 'map3') {
      // The raymarcher evaluates the field many times; splice the call in.
      var body = HARNESS.map3();
      return body.replace(/__H\(([^()]*(?:\([^()]*\)[^()]*)*)\)/g, function (mm, arg) {
        return '(' + buildCall(fn, h, [arg]) + ')' + (h.swz || '');
      });
    }
    var call = buildCall(fn, h);
    if (h.wrap) call = h.wrap.replace('%', call);
    return HARNESS[h.kind](call, h.swz);
  }

  /* -------------------------------------------------- statement fragments */

  // Each entry must stand alone: any of them may be dropped because the
  // snippet declares that name itself, so they cannot reference each other.
  var UVX = '((2.0*fragCoord - iResolution.xy)/iResolution.y)';
  var SHELL_VARS = [
    ['uv', 'vec2 uv = ' + UVX + ';'],
    ['p2', 'vec2 p2 = ' + UVX + ';'],
    ['q2', 'vec2 q2 = ' + UVX + ';'],
    ['col', 'vec3 col = vec3(0.0);'],
    ['ro', 'vec3 ro = vec3(0.0,1.0,-3.0);'],
    ['rd', 'vec3 rd = normalize(vec3(' + UVX + ',1.5));'],
    ['nor', 'vec3 nor = normalize(vec3(' + UVX + ',1.0));'],
    ['n', 'vec3 n = normalize(vec3(' + UVX + ',1.0));'],
    ['lig', 'vec3 lig = normalize(vec3(0.7,0.85,0.35));'],
    ['pos', 'vec3 pos = vec3(' + UVX + ', 0.0);'],
    ['background', 'vec3 background = vec3(0.05,0.06,0.09);'],
    ['dx', 'vec2 dx = vec2(1.0/iResolution.x, 0.0);'],
    ['dy', 'vec2 dy = vec2(0.0, 1.0/iResolution.y);'],
    ['t', 'float t = iTime;'],
    ['d', 'float d = length(' + UVX + ') - 0.5;'],
    ['h', 'float h = 0.0;'],
    ['k', 'float k = 0.15;'],
    ['r', 'float r = 0.5;'],
    ['w', 'float w = 0.02;'],
    ['s', 'float s = 1.0;'],
    ['i', 'int i = 0;']
  ];

  function typeOfDecl(line) {
    var m = line.trim().match(/^(\w+)\s/);
    return m ? m[1] : 'float';
  }

  /** Preamble shared by the statement shell and the return-body shell. */
  function shellDecls(loose, pAs, knownFuncs, skip, imageUV) {
    var clean = blankComments(loose);
    var taken = topLevelDeclarations(clean);
    (skip || []).forEach(function (nm) { taken[nm] = true; });

    var decls = [];
    var types = Object.create(null);
    SHELL_VARS.forEach(function (v) {
      if (taken[v[0]]) return;
      // Snippets that sample an image mean uv to be a 0..1 texture coordinate,
      // not the centred aspect-corrected one used everywhere else.
      var line = (imageUV && v[0] === 'uv') ? 'vec2 uv = fragCoord/iResolution.xy;' : v[1];
      decls.push('  ' + line);
      types[v[0]] = typeOfDecl(line);
    });
    if (!taken['p']) {
      decls.push(pAs === 'vec2' ? '  vec2 p = ' + UVX + ';' : '  vec3 p = vec3(' + UVX + ', 0.35*sin(iTime));');
      types['p'] = pAs;
    }
    if (!taken['q']) {
      decls.push(pAs === 'vec2' ? '  vec2 q = ' + UVX + ';' : '  vec3 q = vec3(' + UVX + ', 0.0);');
      types['q'] = pAs;
    }

    var known = Object.create(null);
    SHELL_VARS.forEach(function (v) { known[v[0]] = true; });
    known['p'] = known['q'] = known['fragColor'] = known['fragCoord'] = true;
    Object.keys(knownFuncs || {}).forEach(function (nm) { known[nm] = true; });
    inferUndeclared(loose, known).forEach(function (line) {
      decls.push('  ' + line);
      var nm = line.match(/^\w+\s+(\w+)/);
      if (nm) types[nm[1]] = typeOfDecl(line);
    });

    // The snippet's own top-level declarations are visualisable too.
    var dre = new RegExp('\\b(' + TYPES + ')\\s+([A-Za-z_]\\w*)', 'g');
    var m;
    while ((m = dre.exec(clean))) if (taken[m[2]]) types[m[2]] = m[1];

    return { text: decls.join('\n'), types: types };
  }

  /** Names written at statement level, in source order. */
  function topLevelAssignments(clean) {
    var out = [];
    var brace = 0, paren = 0;
    var re = new RegExp('([{}()])|\\b(?:(' + TYPES + ')\\s+)?([A-Za-z_]\\w*)\\s*(?:\\[[^\\]]*\\])?\\s*(?:\\+|-|\\*|/)?=(?!=)', 'g');
    var m;
    while ((m = re.exec(clean))) {
      if (m[1]) {
        if (m[1] === '{') brace++;
        else if (m[1] === '}') brace = Math.max(0, brace - 1);
        else if (m[1] === '(') paren++;
        else paren = Math.max(0, paren - 1);
        continue;
      }
      if (brace > 0 || paren > 0) continue;
      out.push(m[3]);
    }
    return out;
  }

  var DIST_NAME = /^(d|dd|dist|distance|sd|sdf|de|h|field)$|^(sd|dist|d)[A-Z_]/;

  /**
   * A fragment that never writes `col` would render pure black, which wastes a
   * lot of screen for nothing. Visualise its last computed value instead --
   * that is usually the thing the paragraph is talking about.
   */
  function autoVisualize(loose, types) {
    var clean = blankComments(loose);
    if (/\b(col|fragColor)\b\s*(?:\[[^\]]*\])?\s*(?:\+|-|\*|\/)?=(?!=)/.test(clean)) return null;

    var names = topLevelAssignments(clean);
    for (var i = names.length - 1; i >= 0; i--) {
      var nm = names[i];
      if (nm === 'fragColor' || nm === 'col') return null;
      var t = types[nm];
      if (!t) continue;
      if (t === 'float') {
        return {
          name: nm, type: t,
          // Grayscale saturates to flat white for anything outside 0..1, so
          // only trust it when the name says "distance"; otherwise band it.
          defaultMode: DIST_NAME.test(nm) ? 0 : 2,
          modes: ['当作距离场', '当作灰度', '等值色带'],
          code:
            '  float stV = ' + nm + ';\n' +
            '  if (uMode < 0.5) {\n' +
            '    col = (stV>0.0)?vec3(0.30,0.52,0.82):vec3(0.96,0.58,0.30);\n' +
            '    col *= 1.0-exp(-5.0*abs(stV));\n' +
            '    col *= 0.86+0.14*cos(140.0*stV);\n' +
            '    col = mix(col, vec3(1.0), 1.0-smoothstep(0.0,0.008,abs(stV)));\n' +
            '  } else if (uMode < 1.5) { col = vec3(clamp(stV,0.0,1.0));\n' +
            '  } else { col = 0.5+0.5*cos(6.28318*(vec3(1.0)*stV+vec3(0.0,0.33,0.67))); }\n'
        };
      }
      if (t === 'vec2') {
        return {
          name: nm, type: t, defaultMode: 0,
          modes: ['x→红 y→绿', '取小数部分', '等值色带'],
          code:
            '  vec2 stV = ' + nm + ';\n' +
            '  if (uMode < 0.5) col = vec3(clamp(stV*0.5+0.5, 0.0, 1.0), 0.35);\n' +
            '  else if (uMode < 1.5) col = vec3(fract(stV), 0.35);\n' +
            '  else col = 0.5+0.5*cos(6.28318*(length(stV)+vec3(0.0,0.33,0.67)));\n'
        };
      }
      // Accumulation snippets (bloom, god rays, blur) end up far above 1.0.
      // Clamping them would show a flat saturated block, so compress instead.
      if (t === 'vec3' || t === 'vec4') {
        return {
          name: nm, type: t, defaultMode: 0,
          modes: ['自动压缩曝光', '直接截断'],
          code:
            '  vec3 stV = ' + nm + (t === 'vec4' ? '.rgb' : '') + ';\n' +
            '  if (uMode < 0.5) col = stV / (1.0 + max(max(stV.r, max(stV.g, stV.b)), 0.0));\n' +
            '  else col = clamp(stV, 0.0, 1.0);\n'
        };
      }
      if (t === 'int') return { name: nm, type: t, code: '  col = vec3(fract(float(' + nm + ')*0.125));\n' };
    }
    return null;
  }

  function fragmentShell(loose, pAs, knownFuncs, imageUV) {
    var writesOut = /\bfragColor\b/.test(blankComments(loose));
    var decls = shellDecls(loose, pAs, knownFuncs, ['fragColor', 'fragCoord'], imageUV);
    var body = loose.replace(/^\s*\n/, '').replace(/\n/g, '\n  ');
    var viz = writesOut ? null : autoVisualize(loose, decls.types);
    return {
      src: 'void mainImage(out vec4 fragColor, in vec2 fragCoord){\n' +
        decls.text + '\n  ' + body + '\n' +
        (viz ? viz.code : '') +
        (writesOut ? '' : '  fragColor = vec4(col, 1.0);\n') + '}\n',
      viz: viz
    };
  }

  /** A body that ends in `return expr;` is an excerpt from inside a function. */
  function returnShell(loose, ret, pAs, knownFuncs) {
    var body = loose.replace(/^\s*\n/, '').replace(/\n/g, '\n  ');
    var zero = ret === 'float' ? '0.0' : ret + '(0.0)';
    return ret + ' stSnippet(vec2 uv){\n' +
      '  vec2 fragCoord = uv*iResolution.y*0.5 + iResolution.xy*0.5;\n' +
      shellDecls(loose, pAs, knownFuncs, ['uv', 'fragCoord']).text +
      '\n  ' + body + '\n  return ' + zero + ';\n}\n';
  }

  /* --------------------------------------------------------- source build */

  /**
   * Constants the snippet reads but the handbook never quoted (SIGMA, Res1,
   * EXPOSURE…). Without them a whole function library fails to compile on one
   * missing `#define`. Globals need constant initialisers, which is exactly
   * what inferUndeclared produces; only the zero defaults get bumped, since a
   * name like SIGMA is usually a divisor.
   */
  function inferGlobals(info) {
    var known = Object.create(null);
    Object.keys(info.defined).forEach(function (nm) { known[nm] = true; });
    return inferUndeclared(info.split.clean, known).slice(0, 12).map(function (line) {
      return line.replace(/=\s*0\.0;/, '= 1.0;').replace(/vec(\d)\(0\.0\)/, 'vec$1(1.0)');
    });
  }

  function assemble(top, mainSrc, info, extraRefs) {
    var lib = buildLib(info, extraRefs);
    var globals = inferGlobals(info);
    return HEADER +
      (info.samplesChannel || lib.needsScene ? SCENE : '') +
      (globals.length ? globals.join('\n') + '\n' : '') +
      (lib.protos ? lib.protos + '\n\n' : '') +
      (top ? top + '\n' : '') +
      (lib.bodies ? lib.bodies + '\n' : '') +
      (mainSrc || '') + EPILOGUE;
  }

  /**
   * Produce ordered candidate sources for a snippet. The runtime compiles them
   * in order and keeps the first that links.
   */
  function plan(rawCode, marker, choice) {
    // The wrapper supplies these; a stray copy inside the snippet is fatal.
    var code = rawCode
      .replace(/^[ \t]*#version[^\n]*$/gm, '')
      .replace(/^[ \t]*precision\s+\w+\s+\w+\s*;[ \t]*$/gm, '')
      .replace(/^[ \t]*uniform\s+\w+\s+(i(?:Resolution|Time|TimeDelta|Frame|FrameRate|Mouse|Date|SampleRate|Channel[0-3])|iChannelTime|iChannelResolution)\b[^;]*;[ \t]*$/gm, '');
    var info = analyze(code);
    var split = info.split;

    if (info.hasMain) {
      return {
        kind: 'shader', functions: [], args: [], modes: null,
        candidates: [{ label: '原样运行', src: assemble(code, '', info, null) }]
      };
    }

    var previewable = [];
    split.funcs.forEach(function (fn) {
      var h = harnessFor(fn);
      if (h) previewable.push({ fn: fn, h: h });
    });

    var knownFuncs = Object.create(null);
    split.funcs.forEach(function (f) { knownFuncs[f.name] = true; });

    function libraryPlan(label) {
      var pick = null;
      if (choice) pick = previewable.filter(function (x) { return x.fn.name === choice; })[0];
      if (!pick) pick = previewable[previewable.length - 1];
      var h = pick.h;
      return {
        kind: 'library',
        functions: previewable.map(function (x) { return { name: x.fn.name, kind: x.h.kind, ret: x.fn.ret }; }),
        picked: pick.fn.name,
        args: harnessArgs(pick.fn, h),
        modes: MODE_LABELS[h.kind] || null,
        defaultMode: h.defaultMode || 0,
        shape: h.kind === 'palette1' ? 'short' : 'tall',
        supportsZoom: h.kind !== 'palette1',
        interactive: h.kind === 'map3' || h.kind === 'render3' || h.kind === 'trace3',
        candidates: [{ label: label + pick.fn.name + '()', src: assemble(split.top, makeHarness(pick.fn, h), info, null) }]
      };
    }

    if (info.looseIsEmpty) {
      if (previewable.length) return libraryPlan('自动外壳 · ');
      // Compiles as a library but nothing here can be previewed on its own.
      return {
        kind: 'library', functions: [], args: [], modes: null,
        note: '这段是函数库：能编译，但没有可以单独出图的入口。点「✎ 编辑」写一个 mainImage，或在沙盒里用它。',
        candidates: []
      };
    }

    var extraRefs = Object.create(null);
    (blankComments(split.loose).match(/[A-Za-z_]\w*/g) || []).forEach(function (w) { extraRefs[w] = true; });

    // Loose statements: try a 2D and a 3D reading of `p`.
    var cands = [];
    ['vec2', 'vec3'].forEach(function (pAs) {
      var shell = fragmentShell(split.loose, pAs, knownFuncs, info.samplesChannel);
      cands.push({
        label: '语句外壳（p 视作 ' + pAs + '）' +
          (shell.viz ? '，自动可视化变量 ' + shell.viz.name : ''),
        src: assemble(split.top, shell.src, info, extraRefs),
        view: shell.viz ? {
          modes: shell.viz.modes || null,
          defaultMode: shell.viz.defaultMode || 0,
          autoViz: shell.viz.name
        } : null
      });
    });

    // `return expr;` at statement level means we were handed a function body.
    if (/(^|[\n;{}])\s*return\s+[^;]/.test(blankComments(split.loose))) {
      [['float', 'field2'], ['vec3', 'color2'], ['vec4', 'color2']].forEach(function (pair) {
        var fn = { ret: pair[0], name: 'stSnippet', params: [{ type: 'vec2', name: 'uv' }] };
        var h = { kind: pair[1], drive: ['uv'], swz: pair[0] === 'vec4' ? '.xyz' : '' };
        cands.push({
          label: '函数体外壳（返回 ' + pair[0] + '）',
          src: assemble(split.top + returnShell(split.loose, pair[0], 'vec2', knownFuncs),
            makeHarness(fn, h), info, extraRefs)
        });
      });
    }

    var plan2 = {
      kind: 'fragment',
      functions: previewable.map(function (x) { return { name: x.fn.name, kind: x.h.kind, ret: x.fn.ret }; }),
      args: [], modes: null, candidates: cands
    };

    if (previewable.length) {
      var lp = libraryPlan('自动外壳 · ');
      // If the statements themselves can only ever paint black, showing the
      // snippet's own function is far more useful than an empty frame.
      var statementsPaint = cands.some(function (c) { return c.view && c.view.autoViz; }) ||
        /\b(col|fragColor)\b\s*(?:\[[^\]]*\])?\s*(?:\+|-|\*|\/)?=(?!=)/.test(blankComments(split.loose));
      if (statementsPaint) { cands.push(lp.candidates[0]); return plan2; }
      lp.candidates.push(cands[0]);
      return lp;
    }
    return plan2;
  }

  /* ------------------------------------------------------------- tunables */

  function tunables(code) {
    var out = [];
    var re = /(#define[ \t]+([A-Za-z_]\w*)[ \t]+)(-?\d*\.?\d+(?:[eE][-+]?\d+)?)(?![\w.])|((?:^|\n)[ \t]*const[ \t]+(float|int)[ \t]+([A-Za-z_]\w*)[ \t]*=[ \t]*)(-?\d*\.?\d+(?:[eE][-+]?\d+)?)/g;
    var m;
    while ((m = re.exec(code))) {
      var name, valStr, start, isInt;
      if (m[2]) {
        name = m[2]; valStr = m[3]; isInt = valStr.indexOf('.') < 0;
        start = m.index + m[1].length;
      } else {
        name = m[6]; valStr = m[7]; isInt = m[5] === 'int';
        start = m.index + m[4].length;
      }
      var v = parseFloat(valStr);
      if (!isFinite(v)) continue;
      var mag = Math.abs(v) || 1;
      var lo, hi, step;
      if (isInt) {
        lo = Math.max(0, Math.round(v) - 8); hi = Math.round(v) + 8; step = 1;
        if (hi <= lo) hi = lo + 1;
      } else {
        lo = v - 2 * mag; hi = v + 2 * mag; step = (hi - lo) / 240;
      }
      out.push({ name: name, value: v, orig: valStr, start: start, end: start + valStr.length, min: lo, max: hi, step: step, isInt: isInt });
      if (out.length >= 14) break;
    }
    return out;
  }

  function applyTunables(code, list) {
    var sorted = list.slice().sort(function (a, b) { return b.start - a.start; });
    var s = code;
    sorted.forEach(function (t) {
      var txt = t.isInt ? String(Math.round(t.value)) : formatFloat(t.value);
      s = s.slice(0, t.start) + txt + s.slice(t.end);
    });
    return s;
  }

  function formatFloat(v) {
    var s = (Math.round(v * 10000) / 10000).toString();
    if (s.indexOf('.') < 0 && s.indexOf('e') < 0) s += '.0';
    return s;
  }

  /* ---------------------------------------------------------- highlighter */

  var KEYWORDS = /^(?:if|else|for|while|do|break|continue|return|discard|struct|const|uniform|varying|attribute|in|out|inout|layout|precision|highp|mediump|lowp|switch|case|default|true|false)$/;
  var TYPEWORD = new RegExp('^(?:' + TYPES + '|sampler2D|samplerCube|sampler3D)$');
  var BUILTIN = /^(?:abs|acos|all|any|asin|atan|ceil|clamp|cos|cosh|cross|degrees|determinant|dFdx|dFdy|distance|dot|equal|exp|exp2|faceforward|floatBitsToInt|floor|fract|fwidth|greaterThan|inverse|inversesqrt|length|log|log2|matrixCompMult|max|min|mix|mod|modf|normalize|not|outerProduct|pow|radians|reflect|refract|round|roundEven|sign|sin|sinh|smoothstep|sqrt|step|tan|tanh|texture|textureLod|textureGrad|texelFetch|textureSize|transpose|trunc|isnan|isinf)$/;
  var UNIFORMS = /^(?:iResolution|iTime|iTimeDelta|iFrame|iFrameRate|iMouse|iDate|iChannel0|iChannel1|iChannel2|iChannel3|iChannelTime|iChannelResolution|iSampleRate|fragColor|fragCoord|gl_FragCoord|mainImage)$/;

  function highlight(code) {
    var out = '';
    var re = /(\/\*[\s\S]*?\*\/|\/\/[^\n]*)|(^[ \t]*#[^\n]*)|(\b\d+\.?\d*(?:[eE][-+]?\d+)?\b|\.\d+)|([A-Za-z_]\w*)|([{}()[\];,.])/gm;
    var last = 0, m;
    while ((m = re.exec(code))) {
      out += MD.escapeHtml(code.slice(last, m.index));
      var txt = MD.escapeHtml(m[0]);
      if (m[1]) out += '<span class="tk-c">' + txt + '</span>';
      else if (m[2]) out += '<span class="tk-p">' + txt + '</span>';
      else if (m[3]) out += '<span class="tk-n">' + txt + '</span>';
      else if (m[4]) {
        var w = m[4];
        if (KEYWORDS.test(w)) out += '<span class="tk-k">' + txt + '</span>';
        else if (TYPEWORD.test(w)) out += '<span class="tk-t">' + txt + '</span>';
        else if (UNIFORMS.test(w)) out += '<span class="tk-u">' + txt + '</span>';
        else if (BUILTIN.test(w)) out += '<span class="tk-b">' + txt + '</span>';
        else out += txt;
      } else out += '<span class="tk-s">' + txt + '</span>';
      last = m.index + m[0].length;
    }
    out += MD.escapeHtml(code.slice(last));
    return out;
  }

  global.GLSLLib = {
    HEADER: HEADER,
    analyze: analyze,
    plan: plan,
    tunables: tunables,
    applyTunables: applyTunables,
    highlight: highlight
  };
})(window);
