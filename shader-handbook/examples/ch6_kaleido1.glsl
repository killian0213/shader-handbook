// 第 6 章 · 万花筒 ①：玩具万花筒（玻璃珠）
// 真万花筒的观感 = 扇形里塞满彩色碎屑 + 镜像折叠。
// 本例先在「一把扇形」里洒运动的彩珠，再 kaleido——你看到的对称华丽来自内容，不是来自 fold 本身。
const float TAU = 6.2831853;

float hash11(float n) { return fract(sin(n) * 43758.5453); }
vec2  hash12(float n) { return fract(sin(vec2(n, n + 19.1)) * vec2(43758.5453, 22578.145)); }

vec2 kaleido(vec2 p, float n)
{
    float seg = TAU / n;
    float a = atan(p.y, p.x);
    float r = length(p);
    a = mod(a, seg);
    a = abs(a - 0.5 * seg);          // 镜子
    return r * vec2(cos(a), sin(a));
}

vec3 beadPalette(float t)
{
    return 0.55 + 0.45 * cos(TAU * (t + vec3(0.00, 0.33, 0.67)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 圆筒遮罩：像凑近视筒
    float tube = smoothstep(1.05, 0.92, length(uv));

    // 慢旋整筒 + 轻微呼吸
    float spin = iTime * 0.18;
    float ca = cos(spin), sa = sin(spin);
    uv = mat2(ca, -sa, sa, ca) * uv;

    vec2 p = kaleido(uv, 8.0);       // 8 面镜

    // —— 扇形里的「内容」：一堆彩色玻璃珠 ——
    vec3 col = vec3(0.03, 0.02, 0.06);
    for (int i = 0; i < 28; i++) {
        float id = float(i);
        vec2  seed = hash12(id + 3.7);
        // 在极坐标扇形局部里爬行（折叠前坐标，所以会自动对称）
        float ang = seed.x * 0.55 + 0.15 * sin(iTime * (0.7 + seed.y) + id);
        float rad = 0.15 + 0.75 * seed.y + 0.04 * sin(iTime * 1.3 + id * 0.5);
        vec2  c = rad * vec2(cos(ang), sin(ang));
        float rBead = 0.035 + 0.045 * hash11(id * 1.9);
        float d = length(p - c) - rBead;
        float m = smoothstep(0.01, -0.01, d);
        float glow = exp(-max(d, 0.0) * 35.0);
        vec3  bc = beadPalette(seed.x + 0.15 * sin(iTime + id));
        col += bc * glow * 0.55;
        col = mix(col, bc * 1.15, m);
        // 高光点
        col += vec3(1.0) * m * exp(-length(p - c - vec2(0.012)) * 90.0) * 0.8;
    }

    // 碎玻璃细屑
    for (int i = 0; i < 40; i++) {
        float id = float(i) + 50.0;
        vec2  seed = hash12(id);
        float ang = fract(seed.x + iTime * 0.03 * seed.y) * 0.7;
        float rad = mix(0.1, 0.95, seed.y);
        vec2  c = rad * vec2(cos(ang), sin(ang));
        float spark = exp(-length(p - c) * 120.0);
        col += beadPalette(seed.x) * spark * 0.9;
    }

    // 筒壁暗角 + 外圈铜环
    float rim = smoothstep(0.02, 0.0, abs(length(uv) - 0.96));
    col = mix(col, vec3(0.55, 0.35, 0.15), rim * 0.65);
    col *= tube;
    col *= 0.75 + 0.25 * pow(max(1.0 - length(uv) * 0.7, 0.0), 1.2);

    fragColor = vec4(pow(max(col, 0.0), vec3(0.92)), 1.0);
}
