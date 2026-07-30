// 课间餐点 · 自动分阶段（STAGE_SEC=2.75）· 鼠标拖拽 scrub
#define STAGE_N 5
#define STAGE_SEC 2.75

// —— 课间餐点通用：分阶段实时解锁 ——
// 自动：每 STAGE_SEC 秒进入下一阶段并循环
// 交互：按住鼠标左右拖 = 手动 scrub 阶段
#ifndef STAGE_N
#define STAGE_N 5
#endif
#ifndef STAGE_SEC
#define STAGE_SEC 2.75
#endif

int snackStage()
{
    if (iMouse.z > 0.0) {
        float u = clamp(iMouse.x / max(iResolution.x, 1.0), 0.0, 0.999);
        return int(u * float(STAGE_N));
    }
    return int(mod(floor(iTime / STAGE_SEC), float(STAGE_N)));
}

// 底部整条阶段指示（当前格高亮）
vec3 snackHud(vec2 frag, vec3 col, int st)
{
    vec2 uv = frag / iResolution.xy;
    if (uv.y > 0.055) return col;
    float slot = floor(uv.x * float(STAGE_N));
    float on = (int(slot) == st) ? 1.0 : 0.22;
    vec3 bar = mix(vec3(0.05, 0.06, 0.09), vec3(0.98, 0.78, 0.32), on);
    float edge = step(0.96, fract(uv.x * float(STAGE_N)));
    bar = mix(bar, vec3(0.015), edge);
    float a = smoothstep(0.055, 0.028, uv.y);
    return mix(col, bar, a);
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i), b = hash21(i + vec2(1,0));
    float c = hash21(i + vec2(0,1)), d = hash21(i + vec2(1,1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.02; a *= 0.5; }
    return v;
}
vec3 pal(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}
vec3 aces(vec3 x) {
    const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    int st = snackStage();
    vec2 uv = fragCoord / iResolution.xy;
    float g = fbm(uv * 3.0 + vec2(iTime * 0.05, 0.0));
    vec3 col = vec3(g);

    if (st >= 1) col = pal(g * 0.9 + 0.1);
    if (st >= 2) {
        float h = fract(g + iTime * 0.05);
        col = pal(h);
        col = mix(vec3(dot(col, vec3(0.299, 0.587, 0.114))), col, 1.25);
    }
    if (st >= 3) {
        col = pow(max(col, 0.0), vec3(0.85));
        col = (col - 0.5) * 1.35 + 0.5;
    }
    if (st >= 4) {
        col *= 1.15;
        col = aces(col);
        float rnd = hash21(fragCoord + floor(iTime * 60.0));
        col += (rnd - 0.5) * 0.04;
        vec2 q = uv;
        col *= 0.7 + 0.3 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.4);
    }
    col = snackHud(fragCoord, col, st);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
