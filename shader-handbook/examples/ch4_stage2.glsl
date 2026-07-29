// 第 4 章 · 阶梯实战 · 阶段 2：余弦调色板
// 新增的只有一个 pal() 和 mainImage 里的两行。几何一个字没动。
const float TAU = 6.2831853;
const float RAD = 0.46;                       // 球半径

// ---------------------------------------------------------------------------
// iq 的余弦调色板：a + b*cos(TAU*(c*t + d))（4.1 节）。
// 这里只让它决定"颜色倾向"，亮度仍旧由 g 自己负责 —— 所以三个 a 都在 1 附近，
// 输出更像一组【白平衡系数】而不是颜色。
// d 的三个分量错开半个周期：暗处 (1.34, 0.76, 0.44) 偏红棕，
// 亮处 (0.98, 1.08, 1.00) 收回中性，于是得到一条从暗红烧到奶白的暖色阶。
// ---------------------------------------------------------------------------
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

    // --- 新增：用亮度查调色板，再把亮度【乘回去】 ---
    // 0.45 是把 g 的可用区间（0~2.2）压进 pal 的 0~1 定义域的缩放。
    // 乘法这一步很关键：它保证明暗层次和波纹细节一点不丢，调色板只改颜色比例。
    float u   = clamp(g * 0.45, 0.0, 1.0);
    vec3  col = g * pal(u);

    fragColor = vec4(col, 1.0);
}
