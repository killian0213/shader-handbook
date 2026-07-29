// Common (common) — Power (Chainsaw Man) by panna_pudi
// https://www.shadertoy.com/view/cljGR3

const vec3 BLOOD_COLOR = vec3(179, 236, 15) / 255.;
const vec3 BACKGROUND_COLOR = vec3(179, 236, 15) / 255.;
const vec3 BRIGHT_RED = vec3(254, 81, 51) / 255.;
const vec3 TEETH_COLOR = vec3(224, 195, 226) / 255. * 1.2;
const vec3 BORDER_COLOR = vec3(0.01);
const vec3 SKIN_COLOR = vec3(158, 0, 24) / 255.;
const vec3 HIGHLIGHT_COLOR = vec3(240, 48, 18) / 255. * 1.2;
const vec3 HAIR_COLOR = vec3(68, 0, 50) / 255.;
const vec3 HAIR_SHADOW_COLOR = vec3(28, 0, 62) / 255.;

const float PI = acos(-1.);
const float TAU = 2. * PI;

#define sat(x) clamp(x, 0., 1.)
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}
float pow2(float x) {
    return x * x;
}
float dot2(in vec2 v) {
    return dot(v, v);
}
float cross2(in vec2 a, in vec2 b) {
    return a.x * b.y - a.y * b.x;
}

float smooth_hill(float x, float off, float width, float gap) {
    x -= off;
    float start = width, end = width + max(0., gap);
    return smoothstep(-end, -start, x) - smoothstep(start, end, x);
}
float remap(float val, float start1, float stop1, float start2, float stop2) {
    return start2 + (val - start1) / (stop1 - start1) * (stop2 - start2);
}
float remap01(float val, float start, float stop) {
    return start + val * (stop - start);
}

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(ax, p) * ax, p, cos(ro)) + sin(ro) * cross(ax, p);
}

float hash11(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 3.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(in vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    // f *= f * f * (f * (f * 6. - 15.) + 10.);

    float a = hash21(p + vec2(0, 0));
    float b = hash21(p + vec2(1, 0));
    float c = hash21(p + vec2(0, 1));
    float d = hash21(p + vec2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

mat2 rot45 = mat2(0.707, -0.707, 0.707, 0.707);

float voronoi(vec2 uv) {
    float d = 1e9;
    vec2 id = floor(uv);
    uv = fract(uv);

    for (float i = -1.; i <= 1.; i++) {
        for (float j = -1.; j <= 1.; j++) {
            vec2 nbor = vec2(i, j);
            d = min(d, length(uv - noise(id + nbor) - nbor));
        }
    }
    return d;
}

vec2 clog(vec2 z) {
    float r = length(z);
    return vec2(log(r), atan(z.y, z.x));
}

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * (1.0 / 4.0);
}
float smax(in float a, in float b, in float k) {
    float h = max(k - abs(a - b), 0.0);
    return max(a, b) + h * h * k * (1.0 / 4.0);
}

float sd_circle(vec2 p, float r) {
    return length(p) - r;
}
float sd_box(vec2 p, vec2 h) {
    p = abs(p) - h;
    return length(max(p, 0.)) + min(0., max(p.x, p.y));
}

float sd_hook(vec2 p, float r, float a, float s) {
    float base = max(sd_circle(p, r), -p.x * sign(s));
    p.x -= r;
    p *= rot(a);
    p.x += r;
    float crop = sd_circle(p, r);

    return max(base, -crop);
}
float sd_line(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float k = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
    return distance(p, mix(a, b, k));
}
float sd_line_y(vec2 p, float h, float r) {
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}

float op_rem_lim(in float p, in float s, in float l) {
    return p - s * clamp(round(p / s), -l, l);
}

float sd_trig_isosceles(in vec2 p, in vec2 q) {
    p.x = abs(p.x);
    vec2 a = p - q * clamp(dot(p, q) / dot(q, q), 0.0, 1.0);
    vec2 b = p - q * vec2(clamp(p.x / q.x, 0.0, 1.0), 1.0);
    float s = -sign(q.y);
    vec2 d = min(vec2(dot(a, a), s * (p.x * q.y - p.y * q.x)),
                 vec2(dot(b, b), s * (p.y - q.y)));
    return -sqrt(d.x) * sign(d.y);
}

float sd_uneven_capsule(vec2 p, vec2 pa, vec2 pb, float ra, float rb) {
    p -= pa;
    pb -= pa;
    float h = dot(pb, pb);
    vec2 q = vec2(dot(p, vec2(pb.y, -pb.x)), dot(p, pb)) / h;

    q.x = abs(q.x);
    float b = ra - rb;
    vec2 c = vec2(sqrt(h - b * b), b);

    float k = cross2(c, q);
    float m = dot(c, q), n = dot(q, q);

    if (k < 0.0) {
        return sqrt(h * (n)) - ra;
    } else if (k > c.x) {
        return sqrt(h * (n + 1.0 - 2.0 * q.y)) - rb;
    }
    return m - ra;
}

// TODO: rb?!?!?!?!?
float sd_egg(in vec2 p, in float ra, in float rb) {
    const float k = sqrt(3.0);
    p.x = abs(p.x);
    float r = ra - rb;
    return ((p.y < 0.0)             ? length(vec2(p.x, p.y)) - r
            : (k * (p.x + r) < p.y) ? length(vec2(p.x, p.y - k * r))
                                    : length(vec2(p.x + r, p.y)) - 2.0 * r) -
           rb;
}

vec3 sd_bezier_base(in vec2 pos, in vec2 A, in vec2 B, in vec2 C) {
    vec2 a = B - A;
    vec2 b = A - 2.0 * B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;

    float kk = 1.0 / dot(b, b);
    float kx = kk * dot(a, b);
    float ky = kk * (2.0 * dot(a, a) + dot(d, b)) / 3.0;
    float kz = kk * dot(d, a);
    float t = 0.;

    float res = 0.0;
    float sgn = 1.0;

    float p = ky - kx * kx;
    float p3 = p * p * p;
    float q = kx * (2.0 * kx * kx - 3.0 * ky) + kz;
    float h = q * q + 4.0 * p3;

    if (h >= 0.0) {  // 1 root
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x) * pow(abs(x), vec2(1.0 / 3.0));
        t = clamp(uv.x + uv.y - kx, 0.0, 1.0);
        vec2 q = d + (c + b * t) * t;
        res = dot2(q);
        sgn = cross2(c + 2.0 * b * t, q);
    } else {  // 3 roots
        float z = sqrt(-p);
        float v = acos(q / (p * z * 2.0)) / 3.0;
        float m = cos(v);
        float n = sin(v) * 1.732050808;
        vec2 tt = clamp(vec2(m + m, -n - m) * z - kx, 0.0, 1.0);
        vec2 qx = d + (c + b * tt.x) * tt.x;
        float dx = dot2(qx), sx = cross2(c + 2.0 * b * tt.x, qx);
        vec2 qy = d + (c + b * tt.y) * tt.y;
        float dy = dot2(qy), sy = cross2(c + 2.0 * b * tt.y, qy);
        if (dx < dy) {
            res = dx;
            sgn = sx;
        } else {
            res = dy;
            sgn = sy;
        }
        t = res;
    }

    return vec3(res, sgn, t);
}
vec2 sd_bezier(in vec2 pos, in vec2 A, in vec2 B, in vec2 C) {
    vec3 bz = sd_bezier_base(pos, A, B, C);
    return vec2(sqrt(bz.x) * sign(bz.y), bz.z);
}

// https://www.shadertoy.com/view/3dtBR4
float sd_bezier_convex(in vec2 pos, in vec2 A, in vec2 B, in vec2 C) {
    if (cross2(C - A, B - A) < 0.0) {
        vec2 t = A;
        A = C;
        C = t;
    }
    float sa = cross2(A - 0., pos - 0.);
    float sc = cross2(C - A, pos - A);
    float s0 = cross2(0. - C, pos - C);
    float o = cross2(C - A, -A);

    float ts = (1.0 - 2.0 * float(sa < 0. && sc < 0. && s0 < 0.));
    float ts2 = (1.0 - 2.0 * float(sa > 0. && sc > 0. && s0 > 0.));
    ts = o > 0. ? ts2 : ts;

    vec3 bz = sd_bezier_base(pos, A, B, C);
    return sqrt(bz.x) * sign(sc < 0. ? 1.0 : -bz.y) * ts;
}

vec4 sd_bezier_rep(in vec2 pos, in vec2 A, in vec2 B, in vec2 C) {
    vec2 bz = sd_bezier(pos, A, B, C);
    float t = bz.y;
    vec2 tangent = normalize((2.0 - 2.0 * t) * (B - A) + 2.0 * t * (C - B));
    vec2 normal = vec2(tangent.y, -tangent.x);
    mat2 mm = mat2(normal, tangent);
    pos = mix(mix(A, B, t), mix(B, C, t), t) - pos;
    return vec4(bz.x, pos * mm, t);
}

vec4 alpha_blending(vec4 d, vec4 s) {
    // return mix(d, s, s.a);
    vec4 res = vec4(0.);
    res.a = mix(1., d.a, s.a);
    if (res.a == 0.) {
        res.rgb = vec3(0.);
    } else {
        res.rgb = mix(d.rgb * d.a, s.rgb, s.a) / res.a;
    }
    return res;
}
void alpha_blend_inplace(inout vec4 d, in vec4 s) {
    d = alpha_blending(d, s);
}

float AAstep(float thre, float val) {
    return smoothstep(-.5, .5, (val - thre) / min(0.03, fwidth(val - thre)));
}
float AAstep(float val) {
    return AAstep(val, 0.);
}

vec4 render(float d, vec4 color) {
    return vec4(color.rgb, color.a * AAstep(d));
}
vec4 render(float d, vec3 color) {
    return render(d, vec4(color, 1.0));
}

vec4 render_stroked_masked(float d,
                           vec4 color,
                           float stroke,
                           float stroke_mask) {
    vec4 stroke_layer = vec4(vec3(0.01), AAstep(d));
    vec4 color_layer = vec4(color.rgb, AAstep(d + stroke));
    return vec4(mix(mix(stroke_layer.rgb, color_layer.rgb, AAstep(stroke_mask)),
                    color_layer.rgb, color_layer.a),
                stroke_layer.a * color.a);
}
vec4 render_stroked(float d, vec4 color, float stroke) {
    return render_stroked_masked(d, color, stroke, 1.);
}
vec4 render_stroked(float d, vec3 color, float stroke) {
    return render_stroked(d, vec4(color, 1.), stroke);
}

#define LayerFlat(d, color) alpha_blend_inplace(final_color, render(d, color))
#define LayerStroked(d, color, stroke) \
    alpha_blend_inplace(final_color, render_stroked(d, color, stroke))
#define LayerStrokedMask(d, color, stroke, mask) \
    alpha_blend_inplace(final_color,             \
                        render_stroked_masked(d, color, stroke, mask))

void draw_highlight(inout vec4 final_color, float highlight) {
    LayerFlat(highlight, HIGHLIGHT_COLOR);
    float s = 0.15;
    alpha_blend_inplace(final_color, vec4(HIGHLIGHT_COLOR,
                                          0.07 * smoothstep(s, 0., highlight)));
}
