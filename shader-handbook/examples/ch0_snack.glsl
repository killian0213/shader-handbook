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
    vec3 col = vec3(uv.xy * 0.5 + 0.5, 0.35);

    if (st >= 1) {
        vec3 sky = mix(vec3(0.98, 0.55, 0.35), vec3(0.25, 0.45, 0.85),
                       smoothstep(-0.3, 0.9, uv.y));
        vec2 sun = vec2(0.45, 0.35);
        sky += vec3(1.0, 0.85, 0.5) * exp(-length(uv - sun) * 6.0);
        sky += vec3(1.0, 0.9, 0.7) * (0.015 / (length(uv - sun) + 0.02));
        col = sky;
    }
    if (st >= 2) {
        float hill = 0.12 * sin(uv.x * 2.2) + 0.05 * sin(uv.x * 5.0 + 1.0);
        float m = smoothstep(0.02, -0.01, uv.y + 0.05 - hill);
        col = mix(col, vec3(0.12, 0.14, 0.22), m);
    }
    if (st >= 3) {
        float w = sin(uv.x * 14.0 - iTime * 3.0 + sin(uv.x * 3.0)) * 0.02;
        float sea = smoothstep(0.03, -0.02, uv.y + 0.42 + w);
        vec3 water = mix(vec3(0.05, 0.18, 0.35), vec3(0.2, 0.45, 0.55),
                         0.5 + 0.5 * sin(uv.x * 20.0 - iTime * 4.0));
        col = mix(col, water, sea);
        col += vec3(0.8, 0.9, 1.0) * sea * exp(-abs(uv.y + 0.42) * 40.0) * 0.35;
    }
    if (st >= 4) {
        float fog = smoothstep(-0.2, 0.6, length(uv * vec2(0.5, 1.0)));
        col = mix(col, vec3(0.95, 0.7, 0.55), fog * 0.22);
        vec2 q = fragCoord / iResolution.xy;
        col *= 0.55 + 0.45 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.35);
        col = pow(max(col, 0.0), vec3(0.92));
    }
    col = snackHud(fragCoord, col, st);
    fragColor = vec4(col, 1.0);
}
