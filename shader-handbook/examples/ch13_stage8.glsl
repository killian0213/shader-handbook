// 第 13 章 · 阶梯实战 · 阶段 8：小游戏感 HUD
// 解析「玩家圆」：WASD 无键盘时用 iMouse 控制；收集闪烁金币；左上角方块条显示分数。
// 真版 = 玩家位置/分数写入 BufA 的 texel(0,0)，每帧积分与碰撞在 Buffer 里更新。
#define COIN_N 12
#define SCORE_MAX 12

float hash11(float p)
{
    p = fract(p * 0.1031);
    p *= p + 33.33;
    return fract(p);
}

vec2 hash22(float n)
{
    return fract(sin(vec2(n, n + 17.3)) * vec2(43758.5453, 22578.1459));
}

// 解析玩家位置（假 WASD：鼠标或自动游走）
vec2 playerPos()
{
    if (iMouse.z > 0.0)
        return iMouse.xy / iResolution.xy;
    float t = iTime * 0.7;
    return vec2(0.5 + 0.35 * sin(t), 0.5 + 0.28 * cos(t * 1.2));
}

// 第 id 枚金币的 hash 位置
vec2 coinPos(int id)
{
    vec2 h = hash22(float(id) * 13.7);
    return vec2(0.12 + h.x * 0.76, 0.15 + h.y * 0.70);
}

// 解析分数：玩家靠近金币即「收集」（用距离阈值 + 时间相位模拟）
int calcScore(vec2 pl)
{
    int s = 0;
    for (int i = 0; i < COIN_N; i++) {
        vec2 cp = coinPos(i);
        float d = length(pl - cp);
        // 收集半径；已收集的金币用时间让位（闪烁后消失）
        float pulse = 0.5 + 0.5 * sin(iTime * 4.0 + float(i) * 2.1);
        if (d < 0.045 + pulse * 0.008)
            s++;
    }
    // 循环加分演示：每 3 秒自动 +1 模拟持久化分数
    s += int(mod(floor(iTime / 3.0), float(SCORE_MAX)));
    return min(s, SCORE_MAX);
}

// 左上角方块条 HUD
vec3 drawScoreBar(vec2 uv, int score)
{
    vec3 hud = vec3(0.0);
    vec2 origin = vec2(0.03, 0.92);
    float cell = 0.028;
    float gap  = 0.006;

    for (int i = 0; i < SCORE_MAX; i++) {
        vec2 c0 = origin + vec2(float(i) * (cell + gap), 0.0);
        vec2 c1 = c0 + vec2(cell, -cell);
        bool inside = all(greaterThan(uv, c0)) && all(lessThan(uv, c1));
        if (inside) {
            bool lit = i < score;
            hud = lit ? vec3(1.0, 0.85, 0.2) : vec3(0.15, 0.18, 0.25);
            // 边框
            vec2 g = (uv - c0) / cell;
            float edge = min(min(g.x, 1.0 - g.x), min(g.y, 1.0 - g.y));
            if (edge < 0.08)
                hud = vec3(0.9, 0.95, 1.0);
        }
    }
    return hud;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uvScr = fragCoord / iResolution.xy;
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    vec2 plScr = playerPos();
    vec2 pl = (plScr * iResolution.xy * 2.0 - iResolution.xy) / iResolution.y;

    int score = calcScore(plScr);

    // 背景：深色竞技场
    vec3 col = mix(vec3(0.04, 0.05, 0.09), vec3(0.06, 0.08, 0.14),
                   0.5 + 0.5 * sin(uv.x * 3.0) * sin(uv.y * 3.0));
    col *= 0.85 + 0.15 * (1.0 - dot(uv, uv) * 0.3);

    // 边界墙
    float bx = max(abs(uv.x) - 0.95, abs(uv.y) - 0.53);
    col += vec3(0.2, 0.35, 0.55) * exp(-max(bx, 0.0) * 80.0) * 2.0;

    // 金币
    for (int i = 0; i < COIN_N; i++) {
        vec2 cpScr = coinPos(i);
        vec2 cp = (cpScr * iResolution.xy * 2.0 - iResolution.xy) / iResolution.y;
        float d = length(uv - cp);
        float pulse = 0.5 + 0.5 * sin(iTime * 5.0 + float(i) * 1.8);
        float collected = step(length(plScr - cpScr), 0.05);
        float vis = (1.0 - collected) * (0.6 + 0.4 * pulse);

        col += vec3(1.0, 0.82, 0.15) * exp(-d * d * 500.0) * vis * 1.5;
        col += vec3(1.0, 0.95, 0.5) * exp(-d * 18.0) * vis * 0.4;
    }

    // 玩家圆
    float pd = length(uv - pl);
    col += vec3(0.25, 0.75, 1.0) * exp(-pd * pd * 400.0) * 1.8;
    col += vec3(0.6, 0.9, 1.0) * exp(-pd * 12.0) * 0.5;

    // HUD 分数条（屏幕空间 uvScr）
    col += drawScoreBar(uvScr, score);

    // 提示文字区：小亮点排成 "GO"
    col += vec3(0.35, 0.55, 0.75) * step(abs(uvScr.y - 0.06), 0.004) *
           step(0.02, uvScr.x) * step(uvScr.x, 0.12);

    col = pow(col, vec3(0.4545));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
