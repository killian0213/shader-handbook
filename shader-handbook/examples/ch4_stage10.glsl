// 第 4 章 · 阶梯实战 · 阶段 10（HARD）：电影调色 —— 三种 Look 链式混合
// 同一 2D 景观（球 + 地面 + 天空），teal-orange / bleach / night-neon 三 LUT 循环。
const float TAU = 6.2831853;

const vec3 LUMA_W = vec3(0.2126, 0.7152, 0.0722);

vec3 aces(vec3 x)
{
    return (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);
}

vec3 saturation(vec3 c, float s)
{
    return mix(vec3(dot(c, LUMA_W)), c, s);
}

// 基础场景（线性 HDR）
vec3 baseScene(vec2 p)
{
    float skyG = clamp(p.y * 0.45 + 0.55, 0.0, 1.0);
    vec3  sky  = mix(vec3(0.06, 0.10, 0.22), vec3(0.55, 0.62, 0.75), pow(skyG, 0.7));

    // 地面
    float gnd = smoothstep(0.015, -0.015, p.y + 0.35);
    vec3  ground = mix(vec3(0.15, 0.13, 0.11), vec3(0.32, 0.28, 0.22), p.x * 0.4 + 0.5);
    vec3 col = mix(sky, ground, gnd);

    // 三个球体
    for (int i = 0; i < 3; i++)
    {
        float fi = float(i);
        vec2  sp = vec2(-0.35 + fi * 0.35, -0.05 - 0.08 * fi);
        float r  = 0.14 - fi * 0.015;
        float d  = length(p - sp) - r;
        float h = sqrt(max(1.0 - dot(p - sp, p - sp) / (r * r), 0.0));
        vec3  n = normalize(vec3((p - sp) / r, h));
        vec3  l = normalize(vec3(-0.5, 0.6, 0.7));
        float dif = max(dot(n, l), 0.0);
        float spe = pow(max(dot(n, normalize(l + vec3(0.0, 0.0, 1.0))), 0.0), 32.0);
        vec3  sph = vec3(0.08) + vec3(0.55, 0.48, 0.42) * dif + vec3(2.5) * spe;
        col = mix(col, sph, smoothstep(0.004, -0.004, d));
    }

    // 远山剪影
    float ridge = p.y + 0.28 + 0.06 * sin(p.x * 4.0) + 0.03 * sin(p.x * 11.0 + 1.2);
    col = mix(col, vec3(0.04, 0.05, 0.08), smoothstep(0.008, -0.008, ridge));

    return col;
}

// Look 1：Teal & Orange —— 暗部偏青、高光偏琥珀
vec3 gradeTealOrange(vec3 c)
{
    float l = dot(c, LUMA_W);
    c = mix(c, c * vec3(0.75, 1.05, 1.25), 1.0 - smoothstep(0.0, 0.45, l));
    c = mix(c, c * vec3(1.25, 1.05, 0.80), smoothstep(0.45, 1.0, l));
    c = saturation(c, 1.25);
    c = aces(c * 0.85);
    return pow(max(c, 0.0), vec3(1.0 / 2.2));
}

// Look 2：Bleach Bypass —— 低饱和、高对比、银盐感
vec3 gradeBleach(vec3 c)
{
    c = aces(c * 0.95);
    float l = dot(c, LUMA_W);
    c = mix(vec3(l), c, 0.45);
    c = pow(max(c / 0.18, 0.0), vec3(1.15)) * 0.18;
    c = mix(c, vec3(l * 0.9), 0.12);
    return pow(max(c, 0.0), vec3(1.0 / 2.2));
}

// Look 3：Night Neon —— 暗部压深、亮部品红青
vec3 gradeNeon(vec3 c)
{
    float l = dot(c, LUMA_W);
    c *= vec3(0.55, 0.65, 0.95);
    c = mix(c, c + vec3(0.15, 0.05, 0.35) * l, smoothstep(0.2, 0.9, l));
    c = mix(c, c * vec3(1.2, 0.85, 1.3), smoothstep(0.5, 1.0, l));
    c = saturation(c, 1.45);
    c = aces(c * 1.1);
    return pow(max(c * 1.05, 0.0), vec3(1.0 / 2.25));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec3 raw = baseScene(p);

    // 三 Look 循环：每 4 秒一个，过渡 1 秒
    float cycle = mod(iTime, 12.0);
    float seg = floor(cycle / 4.0);
    float blend = smoothstep(0.0, 1.0, fract(cycle / 4.0));

    vec3 l0 = gradeTealOrange(raw);
    vec3 l1 = gradeBleach(raw);
    vec3 l2 = gradeNeon(raw);

    vec3 col;
    if (seg < 0.5)
        col = mix(l0, l1, blend);
    else if (seg < 1.5)
        col = mix(l1, l2, blend);
    else
        col = mix(l2, l0, blend);

    // 底部 Look 指示条
    vec2 uv = fragCoord / iResolution.xy;
    if (uv.y < 0.06)
    {
        vec3 bar = vec3(0.08);
        if (uv.x < 0.33) bar = mix(vec3(0.1, 0.35, 0.45), vec3(0.9, 0.55, 0.2), uv.x / 0.33);
        else if (uv.x < 0.66) bar = mix(vec3(0.5), vec3(0.85), (uv.x - 0.33) / 0.33);
        else bar = mix(vec3(0.05, 0.08, 0.25), vec3(0.9, 0.3, 0.8), (uv.x - 0.66) / 0.34);
        col = mix(col, bar, 0.9);
    }

    col *= 0.82 + 0.18 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.32);
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
