// 第 6 章 · 万花筒 ③：霓虹电路 Truchet 万花筒
// 气质接近 mrange《Truchet Kaleidoscope FTW》：格子选圆弧，再塞进镜子。
// 万花筒 × 本章 Truchet = 科幻玫瑰窗。
const float TAU = 6.2831853;

float hash21(vec2 p)
{
    p = fract(p * vec2(127.1, 311.7));
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 kaleido(vec2 p, float n)
{
    float seg = TAU / n;
    float a = atan(p.y, p.x);
    float r = length(p);
    a = mod(a, seg);
    a = abs(a - 0.5 * seg);
    return r * vec2(cos(a), sin(a));
}

float truchetArc(vec2 lp, float side)
{
    vec2 a = (side < 0.5) ? lp - vec2(-0.5, -0.5) : lp - vec2(0.5, -0.5);
    vec2 b = (side < 0.5) ? lp - vec2(0.5, 0.5)  : lp - vec2(-0.5, 0.5);
    return min(abs(length(a) - 0.5), abs(length(b) - 0.5));
}

vec3 neonPal(float t)
{
    return 0.55 + 0.45 * cos(TAU * (t + vec3(0.0, 0.28, 0.55)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float spin = iTime * 0.1;
    float c = cos(spin), s = sin(spin);
    uv = mat2(c, -s, s, c) * uv;

    vec2 p = kaleido(uv, 12.0);

    // 在折叠空间铺 Truchet 格
    float scale = 6.5;
    vec2 gp = p * scale + vec2(0.0, iTime * 0.35);
    vec2 id = floor(gp);
    vec2 lp = fract(gp) - 0.5;
    float side = step(0.5, hash21(id));
    float d = truchetArc(lp, side);

    // 线宽 + 霓虹辉光
    float line = smoothstep(0.08, 0.02, d);
    float glow = exp(-d * 18.0);
    vec3 col = vec3(0.02, 0.03, 0.08);
    vec3 neon = neonPal(hash21(id * 1.7) + iTime * 0.05);
    col += neon * glow * 0.85;
    col = mix(col, neon * 1.3, line);

    // 格点焊点
    float node = exp(-length(lp) * 28.0) * 0.5;
    col += vec3(0.8, 0.95, 1.0) * node;

    // 第二层更细的反向滚动
    vec2 gp2 = p * 11.0 - vec2(iTime * 0.2, 0.0);
    vec2 id2 = floor(gp2);
    vec2 lp2 = fract(gp2) - 0.5;
    float d2 = truchetArc(lp2, step(0.5, hash21(id2 + 9.0)));
    col += neonPal(0.6 + hash21(id2)) * exp(-d2 * 30.0) * 0.35;

    float tube = smoothstep(1.05, 0.9, length(uv));
    col *= tube;
    col *= 0.7 + 0.3 * (1.0 - length(uv) * 0.5);

    fragColor = vec4(pow(max(col, 0.0), vec3(0.9)), 1.0);
}
