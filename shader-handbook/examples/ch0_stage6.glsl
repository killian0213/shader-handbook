// 阶段 6：辉光、地平线雾、暗角、抖动 —— 让画面"成片"
const float HORIZON = -0.15;

float mountain(float x)
{
    float h = 0.0;
    h += 0.26 * sin(x * 1.1 + 0.3);
    h += 0.13 * sin(x * 2.3 + 1.7);
    h += 0.06 * sin(x * 4.7 + 3.1);
    h += 0.03 * sin(x * 9.1 + 0.9);
    return h;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float t = clamp(uv.y - HORIZON, 0.0, 1.0);
    vec3 col = mix(vec3(1.00, 0.30, 0.45), vec3(0.04, 0.01, 0.16), t);

    // --- 太阳 ---
    vec2  sp = uv - vec2(0.0, 0.30);
    float sd = length(sp) - 0.32;
    vec3 sunCol = mix(vec3(1.00, 0.95, 0.35), vec3(1.00, 0.15, 0.45),
                      clamp(0.5 - sp.y * 1.5, 0.0, 1.0));
    float cut = 3.0 * sin((sp.y + iTime * 0.25) * 90.0)
              + clamp(sp.y * 16.0 + 2.0, -6.0, 6.0);
    cut = clamp(cut, 0.0, 1.0);
    // 辉光：盘面之外按距离衰减地加光，这是"发光"最省事的做法
    col += sunCol * exp(-max(sd, 0.0) * 6.0) * 0.55;
    col = mix(col, sunCol, smoothstep(0.004, -0.004, sd) * cut);

    // --- 山 ---
    float md = uv.y - (HORIZON + 0.05 + 0.45 * mountain(uv.x * 2.0));
    col = mix(col, vec3(0.05, 0.01, 0.13), smoothstep(0.004, -0.004, md));
    col += vec3(1.00, 0.35, 0.90) * smoothstep(0.018, 0.0, abs(md)) * 0.9;

    // --- 地面网格 ---
    float depth = max(HORIZON - uv.y, 1e-3);
    vec2  g = vec2(uv.x / depth, 1.0 / depth + iTime * 1.5) * vec2(0.45, 0.35);
    vec2  f = abs(fract(g) - 0.5);
    vec2  w = fwidth(g) * 1.5;
    vec2  l = 1.0 - smoothstep(vec2(0.0), w, f);
    float grid = clamp(l.x + l.y, 0.0, 1.0);
    vec3 ground = mix(vec3(0.03, 0.00, 0.10), vec3(1.00, 0.35, 0.95), grid);
    col = mix(col, ground, step(uv.y, HORIZON));

    // --- 地平线辉光：一条亮带把天地缝合起来 ---
    col += vec3(1.00, 0.30, 0.80) * exp(-abs(uv.y - HORIZON) * 26.0) * 0.7;

    // --- 暗角 ---
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.35 + 0.65 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.25);

    // --- 抖动：打散 8-bit 量化造成的色带 ---
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) / 255.0;

    fragColor = vec4(col, 1.0);
}
