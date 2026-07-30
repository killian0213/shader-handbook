// 第 16 章 · 交互模拟 · 阶段 3：键盘 HUD  mock
// 网格键位：部分键由 hash(floor(iTime)) 随机「按下」；
// WASD 集群高亮。Web 无真实键盘输入。
//
// 真版：Shadertoy texture(iChannel1, keyUV) 读取键盘状态纹理，
// 或宿主通过 uniform 传入 keyDown[] 数组。
const float TAU = 6.2831853;

float hash11(float n) { return fract(sin(n) * 43758.5453); }
float hash21(vec2 p)  { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

// QWERTY 简化布局：行内 key 索引 → 是否 WASD 区
bool isWASD(int row, int col)
{
    return (row == 2 && col >= 1 && col <= 4);
}

float sdRoundedBox(vec2 p, vec2 b, float r)
{
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec3 bg = vec3(0.06, 0.07, 0.10);
    vec3 col = bg;

    float t = iTime;
    float tick = floor(t * 3.5);  // 按键刷新节拍

    const int ROWS = 4;
    const int COLS = 10;
    vec2 panelSize = vec2(0.72, 0.38);
    vec2 panelOrigin = vec2(0.5 - panelSize.x * 0.5, 0.28);

    if (uv.x >= panelOrigin.x && uv.x < panelOrigin.x + panelSize.x &&
        uv.y >= panelOrigin.y && uv.y < panelOrigin.y + panelSize.y) {

        vec2 local = (uv - panelOrigin) / panelSize;
        vec2 keySize = vec2(1.0 / float(COLS), 1.0 / float(ROWS));
        vec2 gap = vec2(0.008, 0.012);

        vec2 cell = local / keySize;
        int ic = clamp(int(floor(cell.x)), 0, COLS - 1);
        int ir = clamp(int(floor(cell.y)), 0, ROWS - 1);

        vec2 keyUV = fract(cell);
        vec2 kp = keyUV - 0.5;
        kp.x *= keySize.x / keySize.y * float(ROWS) / float(COLS);

        float keyId = float(ir * COLS + ic);
        float pressed = step(0.62, hash11(keyId + tick * 13.7));

        // WASD 强制更常亮
        if (isWASD(ir, ic))
            pressed = max(pressed, step(0.35, hash11(keyId + floor(t * 6.0))));

        float d = sdRoundedBox(kp, vec2(0.038, 0.032), 0.012);
        float key = smoothstep(0.004, -0.002, d);

        vec3 keyUp   = vec3(0.18, 0.20, 0.26);
        vec3 keyDown = mix(vec3(0.35, 0.85, 1.0), vec3(1.0, 0.45, 0.55), hash11(keyId));
        if (isWASD(ir, ic))
            keyDown = mix(vec3(0.2, 0.95, 0.55), vec3(0.95, 0.85, 0.25), 0.5);

        vec3 kcol = mix(keyUp, keyDown, pressed * key);
        col = mix(col, kcol, key);

        // 键面标签感：中心小方块
        float label = smoothstep(0.015, 0.0, length(kp) - 0.012);
        col = mix(col, keyDown * 0.6, label * key * 0.4);
    }

    // HUD 标题栏
    float titleBar = smoothstep(0.015, 0.0, abs(uv.y - 0.72));
    col = mix(col, vec3(0.12, 0.14, 0.20), titleBar);
    col = mix(col, vec3(0.25, 0.85, 0.65), titleBar * 0.3 * (0.5 + 0.5 * sin(t * 2.0)));

    // WASD 提示框
    vec2 wasdCenter = vec2(0.5, 0.12);
    float wasdBox = smoothstep(0.002, 0.0, abs(length(uv - wasdCenter) - 0.06) - 0.002);
    col += vec3(0.2, 0.9, 0.6) * wasdBox * 0.35;

    col = pow(col, vec3(0.95));
    fragColor = vec4(col, 1.0);
}
