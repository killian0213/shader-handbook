// 第 18 章 · 效果配方 · 星空 + 星云
// 心法：分层 hash 星点 + fbm 着色星云；缓慢漂移与 twinkle。
// 语料对照：Starship / nebula / starfield 类（Xor 320 字符系的可读对照）

float hash11(float n) { return fract(sin(n) * 43758.5453); }
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vnoise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p)
{
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 6; i++) {
        v += a * vnoise(p);
        p = p * 2.03 + vec2(17.0);
        a *= 0.5;
    }
    return v;
}

vec3 nebula(vec2 uv, float t)
{
    vec2 q = uv * 1.5 + vec2(t * 0.01, -t * 0.008);
    float n1 = fbm(q);
    float n2 = fbm(q * 2.1 + vec2(5.2, 1.3));
    float mask = smoothstep(0.35, 0.85, n1) * smoothstep(0.2, 0.7, n2);
    vec3 cA = vec3(0.08, 0.05, 0.25);
    vec3 cB = vec3(0.35, 0.12, 0.45);
    vec3 cC = vec3(0.05, 0.18, 0.35);
    return mix(cA, mix(cB, cC, n2), mask) * mask * 1.2;
}

float stars(vec2 uv, float t)
{
    vec2 gv = uv * 120.0;
    vec2 id = floor(gv);
    vec2 f = fract(gv) - 0.5;
    float h = hash21(id);
    if (h > 0.965) {
        vec2 off = vec2(hash21(id + 0.1), hash21(id + 0.2)) - 0.5;
        float d = length(f - off * 0.8);
        float tw = 0.6 + 0.4 * sin(t * (3.0 + h * 20.0) + h * 6.28);
        return exp(-d * d * 800.0) * tw * (0.5 + h);
    }
    return 0.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float t = iTime;

    vec3 col = vec3(0.01, 0.012, 0.025);
    col += nebula(p, t);

    // 多层星点
    float s = 0.0;
    s += stars(p, t);
    s += stars(p * 1.3 + 3.7, t + 1.0) * 0.7;
    s += stars(p * 0.7 - 1.2, t + 2.0) * 0.5;
    col += vec3(0.85, 0.9, 1.0) * s;
    col += vec3(1.0, 0.95, 0.8) * s * s * 2.0;

    // 银河带
    float milky = exp(-pow((p.y + 0.15) * 2.5, 2.0)) * 0.15;
    col += vec3(0.25, 0.28, 0.4) * milky;

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
