// 第 10 章 · 阶梯实战 · 阶段 8：火焰柱
// 竖直噪声密度 + 暖色自发光 × 密度 × 累计透过率。
// 比云简单：密度只向上翻涌，palette 负责黄→橙→暗红。
#define STEPS 64

float hash13(vec3 p)
{
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}

float vnoise(vec3 x)
{
    vec3 i = floor(x), f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash13(i + vec3(0, 0, 0)), hash13(i + vec3(1, 0, 0)), f.x),
                   mix(hash13(i + vec3(0, 1, 0)), hash13(i + vec3(1, 1, 0)), f.x), f.y),
               mix(mix(hash13(i + vec3(0, 0, 1)), hash13(i + vec3(1, 0, 1)), f.x),
                   mix(hash13(i + vec3(0, 1, 1)), hash13(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p)
{
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * vnoise(p);
        p = p * 2.1 + vec3(17.0, 3.0, 29.0);
        a *= 0.5;
    }
    return v;
}

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 火焰密度：底部宽、顶部窄，噪声向上对流
float fireDensity(vec3 p)
{
    float h = p.y + 0.15;
    if (h < 0.0) return 0.0;
    float taper = exp(-h * 1.35) * (1.0 - smoothstep(1.6, 2.2, h));
    vec3  q = vec3(p.x, p.y - iTime * 1.8, p.z) * vec3(2.8, 3.5, 2.8);
    float n = fbm(q);
    float core = exp(-dot(p.xz, p.xz) * 14.0);
    return clamp((n - 0.38) * 2.6 * taper * core, 0.0, 1.0);
}

vec3 fireColor(float h, float n)
{
    float t = clamp(h * 0.55 + n * 0.35, 0.0, 1.0);
    vec3 hot = mix(vec3(1.0, 0.95, 0.55), vec3(1.0, 0.35, 0.05), t);
    vec3 cool = mix(vec3(0.85, 0.12, 0.02), vec3(0.08, 0.02, 0.01), t);
    return mix(hot, cool, smoothstep(0.35, 0.85, t));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    vec3 ro = vec3(0.0, 0.05, 2.6);
    vec3 ta = vec3(0.0, 0.85, 0.0);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + 1.75 * ww);

    vec3 bg = mix(vec3(0.02, 0.02, 0.04), vec3(0.06, 0.05, 0.10), 0.5 + 0.5 * rd.y);

    float tMin = 0.8, tMax = 4.5;
    float dt   = (tMax - tMin) / float(STEPS);
    float t    = tMin + hash21(fragCoord) * dt;

    float T = 1.0;
    vec3  col = vec3(0.0);
    const float SIGMA_T = 4.5;

    for (int i = 0; i < STEPS; i++) {
        vec3  p = ro + rd * t;
        float d = fireDensity(p);
        if (d > 1e-4) {
            vec3 emit = fireColor(p.y, d) * d * 5.5;
            col += T * emit * dt;
            T   *= exp(-SIGMA_T * d * dt);
            if (T < 0.01) break;
        }
        t += dt;
    }

    col += T * bg;

    // 底部点光源感
    col += vec3(1.0, 0.45, 0.08) * exp(-length(uv - vec2(0.0, -0.55)) * 2.2) * 0.18;

    vec2 q = fragCoord / iResolution.xy;
    col *= 0.60 + 0.40 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.30);
    col = pow(col, vec3(0.4545));
    col += (hash21(fragCoord) - 0.5) / 255.0;

    fragColor = vec4(col, 1.0);
}
