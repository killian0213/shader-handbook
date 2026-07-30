// 第 14 章 · 阶梯实战 · 阶段 12：软体帘幕 + 假流体染料（Showcase）
// 前景：鼠标交互的 Verlet 直觉 ribbon/帘幕；背景：curl-noise 染料平流。
// 真流体/布料 = 多 Pass Buffer（速度/密度/约束）；这里单 Pass 叠味道。
float hash11(float n) { return fract(sin(n) * 43758.5453); }

float vnoise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash11(dot(i, vec2(127.1, 311.7)));
    float b = hash11(dot(i + vec2(1, 0), vec2(127.1, 311.7)));
    float c = hash11(dot(i + vec2(0, 1), vec2(127.1, 311.7)));
    float d = hash11(dot(i + vec2(1, 1), vec2(127.1, 311.7)));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p)
{
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * vnoise(p);
        p = p * 2.1 + vec2(13.0);
        a *= 0.5;
    }
    return v;
}

vec2 curlNoise(vec2 p, float t)
{
    float e = 0.015;
    float n0 = fbm(p + t * 0.05);
    float nx = fbm(p + vec2(e, 0.0) + t * 0.05) - n0;
    float ny = fbm(p + vec2(0.0, e) + t * 0.05) - n0;
    return vec2(-ny, nx) / e;
}

// 假染料平流：沿 curl 场反向追踪
vec3 fluidDye(vec2 uv, float t)
{
    vec2 p = uv;
    for (int i = 0; i < 5; i++)
        p -= curlNoise(p * 2.8, t) * 0.012;

    float d1 = fbm(p * 3.5 + vec2(t * 0.1, -t * 0.08));
    float d2 = fbm(p * 5.0 - vec2(t * 0.15, t * 0.12));
    vec3 c1 = vec3(0.08, 0.35, 0.85);
    vec3 c2 = vec3(0.85, 0.15, 0.45);
    vec3 c3 = vec3(0.12, 0.75, 0.55);
    return mix(mix(c1, c2, smoothstep(0.3, 0.7, d1)), c3, smoothstep(0.4, 0.8, d2) * 0.6);
}

const int RIBBON_PTS = 24;

vec3 ribbonPoint(float i, float t, vec2 mouse)
{
    float u = i / float(RIBBON_PTS - 1);
    vec2 m = (mouse / iResolution.xy) * 2.0 - 1.0;
    m.x *= iResolution.x / iResolution.y;

    // 顶部固定，底部受鼠标「推」
    vec3 p = vec3(u * 2.2 - 1.1, 1.1 - u * 1.6, 0.0);
    float sway = sin(u * 6.28 + t * 1.5) * 0.06 * u;
    vec2 toM = m - p.xy;
    float push = exp(-dot(toM, toM) * 3.0) * 0.35 * u;
    p.x += sway + toM.x * push;
    p.z += cos(u * 5.0 + t * 2.0) * 0.08 * u + toM.y * push * 0.5;
    p.y -= push * 0.15;

    return p;
}

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    return mat3(cu, cross(cu, cw), cw);
}

float segDist(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float ribbonSDF(vec2 uv, float t, vec2 mouse, out float shade)
{
    float d = 1e6;
    shade = 0.0;
    for (int i = 0; i < RIBBON_PTS - 1; i++) {
        vec3 a3 = ribbonPoint(float(i),     t, mouse);
        vec3 b3 = ribbonPoint(float(i + 1), t, mouse);
        vec2 a = a3.xy, b = b3.xy;
        float sd = segDist(uv, a, b);
        float w = mix(0.035, 0.012, float(i) / float(RIBBON_PTS));
        d = min(d, sd - w);
        shade = max(shade, exp(-sd * 80.0) * (0.5 + 0.5 * a3.z));
    }
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime;
    vec2 mouse = (iMouse.z > 0.0) ? iMouse.xy : iResolution.xy * vec2(0.65, 0.45);

    // 背景假流体
    vec3 col = fluidDye(uv, t) * 0.35;
    col = mix(vec3(0.02, 0.03, 0.06), col, 0.85);

    // 前景 ribbon（2D 投影 + 厚度 SDF）
    float shade;
    float d = ribbonSDF(uv, t, mouse, shade);
    float ribbon = smoothstep(0.008, 0.0, d);

    vec3 sun = normalize(vec3(0.3, 0.8, -0.4));
    vec3 fabric = vec3(0.92, 0.88, 0.82);
    vec3 lit = fabric * (0.3 + 0.7 * shade);
    lit += vec3(1.0, 0.95, 0.85) * ribbon * 0.15;

    col = mix(col, lit, ribbon);

    // 鼠标光标辉光
    vec2 muv = (mouse / iResolution.xy) * 2.0 - 1.0;
    muv.x *= iResolution.x / iResolution.y;
    col += vec3(0.4, 0.7, 1.0) * exp(-length(uv - muv) * 8.0) * 0.25;

    col = pow(col, vec3(0.4545));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
