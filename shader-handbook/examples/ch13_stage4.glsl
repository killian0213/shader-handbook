// 第 13 章 · 阶梯实战 · 阶段 4：霓虹后期管线（单 Pass 成片）
// 霓虹亮点 + 阈值 bloom + 暗角 + ACES tonemap，模拟 Image Pass 读场景+模糊 Buffer 合成。
#define BLUR_TAPS 4
const float SIGMA = 1.8;

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

vec3 neonScene(vec2 uv)
{
    vec3 col = vec3(0.008, 0.01, 0.025);

    // 霓虹环
    float ring = abs(length(uv) - 0.42 + 0.02 * sin(iTime * 1.5));
    col += vec3(0.1, 0.55, 1.0) * exp(-ring * 80.0) * 2.5;

    // 几条发光曲线
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        vec2  c  = 0.35 * vec2(sin(iTime * 0.7 + fi * 1.2),
                               cos(iTime * 0.9 + fi * 0.8));
        float d  = length(uv - c);
        vec3  nc = 0.5 + 0.5 * cos(vec3(0.0, 2.0, 4.0) + fi * 2.3 + iTime * 0.5);
        col += nc * exp(-d * d * 100.0) * 1.8;
        col += nc * 0.2 * exp(-d * 12.0);
    }

    // 中心亮点
    col += vec3(1.0, 0.85, 0.95) * exp(-dot(uv, uv) * 30.0) * 1.5;
    return col;
}

vec3 blurPass(vec2 uv, vec2 px)
{
    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -BLUR_TAPS; i <= BLUR_TAPS; i++) {
        for (int j = -BLUR_TAPS; j <= BLUR_TAPS; j++) {
            float w = gauss(float(i)) * gauss(float(j));
            sum  += neonScene(uv + vec2(float(i), float(j)) * px) * w;
            wsum += w;
        }
    }
    return sum / wsum;
}

vec3 tonemapACES(vec3 x)
{
    x *= 1.15;
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 px = vec2(2.5) / iResolution.xy;

    vec3 base = neonScene(uv);
    float lum = dot(base, vec3(0.299, 0.587, 0.114));
    vec3  bright = base * smoothstep(0.45, 0.85, lum);
    vec3  bloom  = blurPass(uv, px);

    vec3 col = base + bloom * 1.6 + bright * 0.35;
    col = tonemapACES(col);
    col = pow(col, vec3(0.4545));

    vec2 q = fragCoord / iResolution.xy;
    col *= 0.58 + 0.42 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.30);
    col += (hash21(fragCoord) - 0.5) / 255.0;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
