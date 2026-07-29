// 第 4 章 · 阶梯实战 · 阶段 5：色调映射
// 新增一个 aces() + mainImage 里一行。几何一个字没动。
// 上一阶段那片死白的高光，就是这一步要救的东西。
const float TAU = 6.2831853;
const float RAD = 0.46;                       // 球半径

const vec3 TINT_SHADOW = vec3(0.50, 1.05, 2.80);
const vec3 TINT_HIGH   = vec3(1.30, 0.98, 0.52);
const vec3 LUMA_W      = vec3(0.2126, 0.7152, 0.0722);

// 曝光。往下拧到 0.60，因为上一阶段的对比度已经把整体推亮了一大截。
// 曝光和 tonemap 是一对：先决定"进多少光"，再决定"怎么把超标的压回去"。
const float EXPOSURE = 0.60;

// Narkowicz 的 ACES 拟合（4.4 节 ③）。输入线性光强，输出可以直接送去 gamma。
vec3 aces(vec3 x)
{
    return (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);
}

vec3 saturation(vec3 c, float s)
{
    return mix(vec3(dot(c, LUMA_W)), c, s);
}

vec3 contrast(vec3 c, float k)
{
    const float PIVOT = 0.18;
    return pow(max(c, 0.0) / PIVOT, vec3(k)) * PIVOT;
}

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

    float sh = 1.0 - smoothstep(0.04, 0.75, g);
    float hl = smoothstep(0.55, 1.45, g);
    col *= mix(vec3(1.0), TINT_SHADOW, sh);
    col *= mix(vec3(1.0), TINT_HIGH,   hl);

    col = saturation(col, 1.30);
    col = contrast(col, 1.22);

    // --- 新增：曝光 + 色调映射。三个候选放在一起对比，注释掉的两个也请各跑一次。 ---
    // col = clamp(col * EXPOSURE, 0.0, 1.0);            // ① 硬切：高光核心糊成死白
    // col = col * EXPOSURE / (1.0 + col * EXPOSURE);    // ② Reinhard：不爆白但发灰
    col = aces(col * EXPOSURE);                          // ③ ACES：高光滚降 + 暗部结实

    fragColor = vec4(col, 1.0);
}
