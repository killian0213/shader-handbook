// 第 18 章 · 效果配方 18.18 · 流体 / 墨水（curl noise）
// 无压流体感的旋涡染料扩散。

float hash21(vec2 p)
{
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float noise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p)
{
    float v = 0.0, a = 0.5;
    mat2 r = mat2(1.6, 1.2, -1.2, 1.6);
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = r * p;
        a *= 0.5;
    }
    return v;
}

vec2 curl(vec2 p)
{
    float e = 0.001;
    float n1 = fbm(p + vec2(0.0, e));
    float n2 = fbm(p - vec2(0.0, e));
    float n3 = fbm(p + vec2(e, 0.0));
    float n4 = fbm(p - vec2(e, 0.0));
    return vec2(n1 - n2, n4 - n3) / (2.0 * e);
}

vec3 ink(vec2 uv, vec2 c, vec3 col, float t)
{
    vec2 p = uv - c;
    for (int i = 0; i < 12; i++) {
        p += curl(p * 1.6 + t * 0.15) * 0.018;
    }
    float d = length(p);
    float m = exp(-d * 12.0);
    return col * m;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.35;

    vec3 bg = vec3(0.96, 0.94, 0.90);
    vec3 col = bg;

    col += ink(uv, vec2(-0.35, 0.15), vec3(0.15, 0.35, 0.85), t);
    col += ink(uv, vec2(0.4, -0.1), vec3(0.85, 0.2, 0.35), t + 2.0);
    col += ink(uv, vec2(0.0, -0.35), vec3(0.15, 0.65, 0.45), t + 4.0);
    col += ink(uv, vec2(0.25, 0.35), vec3(0.95, 0.55, 0.1), t + 1.0);

    // 纸张纹理
    col *= 0.97 + 0.03 * fbm(uv * 40.0);

    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
