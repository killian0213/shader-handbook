// 第 4 章 · 阶梯实战 · 阶段 9：HDR 太阳假 Bloom + Tonemap 对比
// 左半 ACES、右半 softKnee；中间竖线分割，教"压高光"的不同手感。
const float TAU = 6.2831853;

const vec2 SUN = vec2(0.0, 0.18);

vec3 aces(vec3 x)
{
    return (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);
}

vec3 softKnee(vec3 c, float K)
{
    vec3 hi = max(c - K, 0.0);
    return min(c, vec3(K)) + (1.0 - K) * (1.0 - exp(-hi / (1.0 - K)));
}

float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}

// 简易场景：渐变天空 + 太阳盘 + 地面
vec3 sceneRaw(vec2 uv)
{
    float sy = clamp(uv.y * 0.5 + 0.5, 0.0, 1.0);
    vec3  sky = mix(vec3(0.08, 0.14, 0.32), vec3(0.95, 0.55, 0.28), pow(sy, 0.55));

    float sd = length(uv - SUN);
    // 太阳核心：故意远超 1.0
    vec3 sun = vec3(8.0, 6.5, 4.0) * smoothstep(0.07, 0.0, sd);
    sky += sun;

    // 地面
    float gnd = smoothstep(0.02, -0.02, uv.y + 0.22);
    vec3 ground = mix(vec3(0.12, 0.10, 0.08), vec3(0.28, 0.22, 0.16), uv.x * 0.5 + 0.5);
    vec3 col = mix(sky, ground, gnd);

    // 假 Bloom：宽核 + 窄核叠加（全在 tone 之前，线性空间）
    col += vec3(1.0, 0.65, 0.35) * exp(-sd * 6.0) * 1.8;
    col += vec3(1.0, 0.80, 0.50) * exp(-sd * 18.0) * 0.9;
    col += vec3(1.0, 0.95, 0.85) * pow(0.015 / max(sd, 0.002), 1.4) * 0.35;

    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 px = vec2(1.0 / iResolution.y);

    vec3 raw = sceneRaw(uv);

    // 额外宽 bloom 采样（廉价 5-tap）
    float sd = length(uv - SUN);
    vec3 bloom = vec3(0.0);
    bloom += sceneRaw(uv + px * vec2(1.5, 0.0)) * 0.2;
    bloom += sceneRaw(uv + px * vec2(-1.5, 0.0)) * 0.2;
    bloom += sceneRaw(uv + px * vec2(0.0, 1.5)) * 0.2;
    bloom += sceneRaw(uv + px * vec2(0.0, -1.5)) * 0.2;
    bloom += sceneRaw(uv) * 0.2;
    raw += bloom * exp(-sd * 4.0) * 0.35;

    float split = 0.5 + 0.08 * sin(iTime * 0.5);
    bool left = (fragCoord.x / iResolution.x) < split;

    vec3 col;
    if (left)
        col = aces(raw * 0.22);
    else
        col = softKnee(raw * 0.22, 0.75);

    // 分割线
    float line = smoothstep(0.004, 0.0, abs(fragCoord.x / iResolution.x - split));
    col = mix(col, vec3(1.0), line * 0.85);

    // 标签底色
    vec2 labelUV = fragCoord / iResolution.xy;
    if (labelUV.y > 0.92)
    {
        vec3 lbl = left ? vec3(0.25, 0.45, 0.65) : vec3(0.55, 0.35, 0.25);
        col = mix(col, lbl, 0.85);
    }

    col = pow(max(col, 0.0), vec3(1.0 / 2.2));

    vec2 q = fragCoord / iResolution.xy;
    col *= 0.75 + 0.25 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.35);
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
