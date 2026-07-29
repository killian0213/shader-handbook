// 第 4 章 · 阶梯实战 · 阶段 3：明暗分离（双色调）
// 新增的只有 mainImage 末尾那四行。几何一个字没动。
const float TAU = 6.2831853;
const float RAD = 0.46;                       // 球半径

// 阴影色偏：往青蓝推。数值看着夸张（蓝通道 2.8 倍），是因为它得先把
// 上一阶段调色板给暗部的暖色抵消掉，再往冷的方向走过去。
const vec3 TINT_SHADOW = vec3(0.50, 1.05, 2.80);
// 高光色偏：往暖金推。蓝通道 0.52 —— "暖"主要靠【减蓝】，不是靠加红。
const vec3 TINT_HIGH   = vec3(1.30, 0.98, 0.52);

vec3 pal(float t)
{
    return vec3(1.16, 0.92, 0.72)
         + vec3(0.18, 0.16, 0.28) * cos(TAU * (vec3(0.5) * t + vec3(0.0, 0.5, 0.5)));
}

float field(vec2 p)
{
    float r = length(p);

    // ① 背景：从中心向外缓缓变暗。梯度非常平，正是最容易出色带的地形
    float g = 0.055 + 0.200 * exp(-r * r * 0.85);

    // ② 同心波纹：振幅只有 0.03，负责给背景一点结构
    g += 0.030 * sin(r * 12.0 - iTime * 0.6) * exp(-r * 0.7);

    // ③ 球：用半球高度伪造一个 3D 法线，再做最普通的兰伯特 + Blinn 高光
    float h = sqrt(max(1.0 - dot(p, p) / (RAD * RAD), 0.0));
    vec3  n = normalize(vec3(p / RAD, h));
    vec3  l = normalize(vec3(-0.42, 0.50, 0.76));   // 主光：左上前方
    vec3  f = normalize(vec3( 0.55, -0.60, 0.35));  // 补光：右下，只给一点

    float dif = max(dot(n, l), 0.0);
    float fil = max(dot(n, f), 0.0);
    float spe = pow(max(dot(n, normalize(l + vec3(0.0, 0.0, 1.0))), 0.0), 24.0);

    float sph = 0.030            // 环境光：暗部不能死黑，否则后面根本染不上色
              + 0.620 * dif      // 漫反射：这是"明暗层次"
              + 0.110 * fil      // 补光：让背光面还留一点信息
              + 1.550 * spe;     // 高光：故意冲到 1 以上，这是后面色调映射的靶子

    return mix(g, sph, smoothstep(0.006, -0.006, r - RAD));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float g = field(p);

    float u   = clamp(g * 0.45, 0.0, 1.0);
    vec3  col = g * pal(u);

    // --- 新增：明暗分离。用亮度切出两个互不重叠的权重，各染一个色偏。 ---
    // 用【乘】不用 mix：乘法只改三通道的比例，不动明暗层次。
    float sh = 1.0 - smoothstep(0.04, 0.75, g);   // 阴影权重：0.04 以下全算阴影
    float hl = smoothstep(0.55, 1.45, g);         // 高光权重：两段刻意留出间隙
    col *= mix(vec3(1.0), TINT_SHADOW, sh);
    col *= mix(vec3(1.0), TINT_HIGH,   hl);

    fragColor = vec4(col, 1.0);
}
