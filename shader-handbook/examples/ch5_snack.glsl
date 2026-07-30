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
    return mix(mix(hash21(i), hash21(i + vec2(1,0)), f.x),
               mix(hash21(i + vec2(0,1)), hash21(i + vec2(1,1)), f.x), f.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 6; i++) { v += a * noise(p); p = p * 2.05 + 17.0; a *= 0.5; }
    return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    int st = snackStage();
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 p = uv * 2.0;
    vec3 col = vec3(0.05, 0.07, 0.12);

    if (st == 0) {
        col = vec3(hash21(floor(fragCoord / 4.0)));
    } else if (st == 1) {
        float n = noise(p * 3.0 + iTime * 0.2);
        col = mix(vec3(0.1, 0.12, 0.2), vec3(0.7, 0.75, 0.85), n);
    } else {
        vec2 q = p;
        if (st >= 3) q += 0.45 * vec2(fbm(p + iTime * 0.1), fbm(p + 3.1));
        float c = fbm(q * 1.2);
        col = mix(vec3(0.15, 0.18, 0.28), vec3(0.85, 0.82, 0.9), smoothstep(0.35, 0.75, c));
        col = mix(col, vec3(0.3, 0.35, 0.5), 1.0 - smoothstep(-0.4, 0.3, uv.y));
        if (st >= 4) {
            float bolt = 0.0;
            vec2 lp = uv * vec2(1.0, 1.8) + vec2(0.0, -iTime * 0.05);
            for (int i = 0; i < 4; i++) {
                float fi = float(i);
                float h = hash21(vec2(floor(iTime * 2.0), fi));
                if (h > 0.72) {
                    float x = (h - 0.85) * 3.0;
                    bolt += exp(-abs(lp.x - x - 0.1 * sin(lp.y * 12.0 + fi)) * 40.0)
                          * smoothstep(0.8, -0.2, lp.y);
                }
            }
            col += vec3(0.7, 0.85, 1.0) * bolt;
            col *= 0.75;
            col = pow(max(col, 0.0), vec3(1.1));
        }
    }
    col = snackHud(fragCoord, col, st);
    fragColor = vec4(col, 1.0);
}
