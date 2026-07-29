// 第 13 章 · 阶梯实战 · 阶段 2：单 Pass 近似 Bloom
// 亮球场景 + 阈值提取 + 可分离高斯模糊的单 Pass 近似（真 bloom 需 Buffer 横/纵两趟）。
#define BLUR_TAPS 5
const float SIGMA = 2.0;

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float gauss(float x)
{
    return exp(-0.5 * x * x / (SIGMA * SIGMA));
}

// 几颗自发光亮球 + 暗背景
vec3 scene(vec2 uv)
{
    vec3 col = vec3(0.02, 0.025, 0.04);

    vec2 balls[4];
    balls[0] = vec2(-0.45,  0.15);
    balls[1] = vec2( 0.35, -0.05);
    balls[2] = vec2( 0.05,  0.42);
    balls[3] = vec2(-0.15, -0.38);

    vec3 cols[4];
    cols[0] = vec3(1.2, 0.35, 0.15);
    cols[1] = vec3(0.25, 0.85, 1.1);
    cols[2] = vec3(1.0, 0.95, 0.55);
    cols[3] = vec3(0.75, 0.25, 1.05);

    for (int i = 0; i < 4; i++) {
        vec2 c = balls[i] + 0.06 * vec2(sin(iTime * (0.7 + float(i) * 0.2)),
                                          cos(iTime * (0.9 + float(i) * 0.15)));
        float d = length(uv - c);
        col += cols[i] * exp(-d * d * 120.0);
        col += cols[i] * 0.15 * exp(-d * 8.0);
    }
    return col;
}

// 单 Pass 近似：先横后纵各扫一遍（在同函数里串行，非真 Buffer）
vec3 blurH(vec2 uv, vec2 px)
{
    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -BLUR_TAPS; i <= BLUR_TAPS; i++) {
        float w = gauss(float(i));
        sum  += scene(uv + vec2(float(i) * px.x, 0.0)) * w;
        wsum += w;
    }
    return sum / wsum;
}

vec3 blurV(vec2 uv, vec2 px)
{
    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -BLUR_TAPS; i <= BLUR_TAPS; i++) {
        float w = gauss(float(i));
        sum  += blurH(uv + vec2(0.0, float(i) * px.y), px) * w;
        wsum += w;
    }
    return sum / wsum;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 px = 1.0 / iResolution.xy;

    vec3 base = scene((uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0));

    // 阈值提取亮部
    float lum = dot(base, vec3(0.299, 0.587, 0.114));
    vec3  bright = base * smoothstep(0.55, 0.95, lum);

    // 对亮部做近似可分离模糊
    vec2 puv = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    vec3 bloom = blurV(puv, px * 3.5);

    vec3 col = base + bloom * 1.35;
    col = col / (col + 0.6);
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
