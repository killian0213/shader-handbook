// 阶段 8：分层合成 —— 同一场景按层叠加；floor(iTime*0.25)%4 循环展示进度
// 五步：天空 → 太阳 → 山脉 → 海面/地面 → 后期（雾/暗角）

const float HORIZON = -0.15;

float mountain(float x)
{
    return 0.26 * sin(x * 1.1 + 0.3) + 0.13 * sin(x * 2.3 + 1.7)
         + 0.06 * sin(x * 4.7 + 3.1);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    int phase = int(mod(floor(iTime * 0.25), 4.0));

    float t = clamp(uv.y - HORIZON, 0.0, 1.0);
    vec3 col = mix(vec3(1.00, 0.30, 0.45), vec3(0.04, 0.01, 0.16), t);

    // 层 2：太阳
    if (phase >= 1) {
        vec2 sp = uv - vec2(0.0, 0.30);
        float sd = length(sp) - 0.32;
        vec3 sunCol = mix(vec3(1.0, 0.95, 0.35), vec3(1.0, 0.15, 0.45),
                          clamp(0.5 - sp.y * 1.5, 0.0, 1.0));
        col += sunCol * exp(-max(sd, 0.0) * 6.0) * 0.55;
        col = mix(col, sunCol, smoothstep(0.004, -0.004, sd));
    }

    // 层 3：山脉
    if (phase >= 2) {
        float md = uv.y - (HORIZON + 0.05 + 0.45 * mountain(uv.x * 2.0));
        col = mix(col, vec3(0.05, 0.01, 0.13), smoothstep(0.004, -0.004, md));
        col += vec3(1.0, 0.35, 0.90) * smoothstep(0.018, 0.0, abs(md)) * 0.9;
    }

    // 层 4：海面/地面网格
    if (phase >= 3) {
        float depth = max(HORIZON - uv.y, 1e-3);
        vec2 g = vec2(uv.x / depth, 1.0 / depth + iTime * 1.5) * vec2(0.45, 0.35);
        vec2 f = abs(fract(g) - 0.5);
        vec2 w = fwidth(g) * 1.5;
        vec2 l = 1.0 - smoothstep(vec2(0.0), w, f);
        float grid = clamp(l.x + l.y, 0.0, 1.0);
        vec3 ground = mix(vec3(0.03, 0.00, 0.10), vec3(1.00, 0.35, 0.95), grid);
        col = mix(col, ground, step(uv.y, HORIZON));
        col += vec3(1.0, 0.30, 0.80) * exp(-abs(uv.y - HORIZON) * 26.0) * 0.7;
    }

    // 层 5：后期（仅 phase==3 全开时）
    if (phase >= 3) {
        vec2 q = fragCoord / iResolution.xy;
        col *= 0.35 + 0.65 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.25);
    }

    // 底部五步指示条
    vec2 buv = fragCoord / iResolution.xy;
    float barY = smoothstep(0.06, 0.0, abs(buv.y - 0.04));
    for (int i = 0; i < 5; i++) {
        float cx = (float(i) + 0.5) / 5.0;
        float on = step(abs(buv.x - cx), 0.07) * barY;
        float lit = (phase == 0 && i == 0) || (phase == 1 && i <= 1)
                 || (phase == 2 && i <= 2) || (phase >= 3 && i <= 4) ? 1.0 : 0.25;
        col = mix(col, vec3(1.0, 0.75, 0.35) * lit, on);
    }

    fragColor = vec4(col, 1.0);
}
