// 第 6 章 · 网格扩展 · 阶段 7：六边形蜂巢
// 把屏幕切成六边形网格，每格一颗发光六边形，颜色随格子 id 脉冲。
//
// 六边形坐标简述（任选其一）：
// · 经典法：用 mat2 把直角坐标变到「尖顶 hex」空间，floor 得格子 id。
// · 轴向/立方：轴向 (q,r) 满足 q+r+s=0（立方坐标 s=-q-r），
//   邻居偏移为 (±1,0)、(0,±1)、(±1,∓1) —— 比正方形网格更均匀。
const float TAU = 6.2831853;
const float HEX_R = 0.92;   // 六边形外接圆半径（格内局部坐标）

// 尖顶六边形：直角 uv → 格 id + 格内局部坐标（hex 空间）
vec3 hexGrid(vec2 uv)
{
    const mat2 toHex = mat2(1.0, 0.0, 0.5773503, 1.1547005);
    vec2 p  = toHex * uv;
    vec2 pi = floor(p);
    vec2 pf = fract(p);

    // 立方坐标 round：选离得最近的六边形中心
    vec3 qr = vec3(pf.x, pf.y, -pf.x - pf.y);
    float d0 = abs(qr.x), d1 = abs(qr.y), d2 = abs(qr.z);
    if (d0 > d1 && d0 > d2) qr.x -= sign(qr.x);
    else if (d1 > d2)       qr.y -= sign(qr.y);
    else                    qr.z -= sign(qr.z);

    vec2 id = pi + qr.xy;
    vec2 lc = pf - qr.xy;
    return vec3(id, 0.0); // .xy = id；lc 由 hexLocal 复算
}

vec2 hexLocal(vec2 uv, vec2 id)
{
    const mat2 toHex = mat2(1.0, 0.0, 0.5773503, 1.1547005);
    return toHex * uv - id;
}

float sdHex(vec2 p, float r)
{
    p = abs(p);
    return max(dot(p, normalize(vec2(1.0, 1.7320508))), p.x) - r;
}

float hash21(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 pal(float t)
{
    return vec3(0.5, 0.5, 0.5)
         + vec3(0.5, 0.5, 0.5) * cos(TAU * (vec3(1.0, 1.0, 1.0) * t + vec3(0.0, 0.33, 0.67)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    uv *= 3.8;

    vec2 id = hexGrid(uv).xy;
    vec2 lc = hexLocal(uv, id);

    float h   = hash21(id);
    float pulse = 0.55 + 0.45 * sin(iTime * (1.2 + h * 2.5) + h * TAU);
    vec3  cellCol = pal(h * 0.35 + 0.08) * (0.35 + 0.65 * pulse);

    float d = sdHex(lc, HEX_R * 0.42);
    float hex = smoothstep(0.012, -0.008, d);
    float edge = exp(-abs(d) * 55.0) * 0.55;

    vec3 bg = vec3(0.03, 0.025, 0.06);
    vec3 col = mix(bg, cellCol, hex);
    col += cellCol * edge;
    col += cellCol * exp(-length(lc) * 4.5) * 0.18 * pulse;

    // 格线：六边形边界 faint grid
    float grid = smoothstep(0.006, 0.0, abs(sdHex(lc, HEX_R * 0.46)));
    col += vec3(0.12, 0.10, 0.18) * grid * 0.35;

    vec2 uvn = fragCoord / iResolution.xy;
    col *= 0.62 + 0.38 * pow(16.0 * uvn.x * uvn.y * (1.0 - uvn.x) * (1.0 - uvn.y), 0.28);

    fragColor = vec4(col, 1.0);
}
