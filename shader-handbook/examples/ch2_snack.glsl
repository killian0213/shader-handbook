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

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    int st = snackStage();
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec3 sky = mix(vec3(0.05, 0.02, 0.12), vec3(0.15, 0.05, 0.25), uv.y * 0.5 + 0.5);
    vec3 col = sky;

    if (st >= 1) {
        float y = max(uv.y + 0.65, 0.02);
        vec2 road = vec2(uv.x / y, 1.0 / y);
        road.y += iTime * 1.8;
        float pavement = smoothstep(0.0, 0.02, 0.55 - abs(road.x));
        col = mix(col, vec3(0.08, 0.08, 0.1), pavement * step(uv.y, -0.05));
        if (st >= 2) {
            float dash = step(0.5, fract(road.y * 0.35));
            float center = smoothstep(0.04, 0.0, abs(road.x)) * dash;
            col = mix(col, vec3(1.0, 0.95, 0.6), center * pavement);
            float zebra = step(0.5, fract(road.x * 3.0 + road.y));
            col = mix(col, col * 1.15, zebra * pavement * 0.15);
        }
        if (st >= 3) {
            float poles = 0.0;
            for (int i = 0; i < 6; i++) {
                float z = fract(road.y * 0.15 + float(i) / 6.0);
                float px = 0.62 / max(z, 0.05);
                poles += exp(-abs(uv.x - sign(uv.x + 0.001) * px) * 40.0) *
                         smoothstep(0.2, 0.0, z) * step(uv.y, 0.2);
            }
            col += vec3(1.0, 0.85, 0.5) * poles * 0.55;
        }
        if (st >= 4) {
            float neonL = exp(-abs(road.x + 0.55) * 12.0) * pavement;
            float neonR = exp(-abs(road.x - 0.55) * 12.0) * pavement;
            col += vec3(1.0, 0.2, 0.6) * neonL * 0.7;
            col += vec3(0.2, 0.7, 1.0) * neonR * 0.7;
            vec2 q = fragCoord / iResolution.xy;
            col *= 0.5 + 0.5 * pow(32.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.4);
        }
    }
    col = snackHud(fragCoord, col, st);
    fragColor = vec4(max(col, 0.0), 1.0);
}
