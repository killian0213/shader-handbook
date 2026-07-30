// 第 6 章 · 万花筒 ②：域扭曲丝绸（迷幻万花筒）
// 折叠之后喂「会流动的噪声丝绸」——对称把有机纹理变成教堂玫瑰窗。
// 对比 ①：① 靠离散彩珠，② 靠连续场；同一个 kaleido，气质完全不同。
const float TAU = 6.2831853;

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i), b = hash21(i + vec2(1, 0));
    float c = hash21(i + vec2(0, 1)), d = hash21(i + vec2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p)
{
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = p * 2.03 + vec2(17.0, 9.0);
        a *= 0.5;
    }
    return v;
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

vec3 pal(float t)
{
    return vec3(0.5, 0.35, 0.55)
         + vec3(0.5, 0.45, 0.35) * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float nFold = 10.0;

    // 整筒缓转
    float ang = iTime * 0.12;
    float c = cos(ang), s = sin(ang);
    uv = mat2(c, -s, s, c) * uv;

    vec2 p = kaleido(uv, nFold);

    // 域扭曲：在折叠空间里拧——对称自动「复印」出万花纹
    vec2 q = p * 2.2;
    q += 0.55 * vec2(fbm(q + iTime * 0.15), fbm(q + vec2(5.2, 1.3) - iTime * 0.12));
    float v = fbm(q * 1.4);
    float v2 = fbm(q * 3.0 + v);

    // 多层色带像丝绸褶皱
    vec3 col = pal(v * 1.2 + 0.15 * v2 + iTime * 0.03);
    col = mix(col, pal(v2 + 0.4), smoothstep(0.35, 0.75, v));
    // 亮丝
    float silk = pow(max(sin(v * 18.0 + v2 * 6.0), 0.0), 8.0);
    col += vec3(1.0, 0.9, 0.8) * silk * 0.35;

    // 径向节奏：越靠中心越密，像真筒里的景深堆叠
    float rings = 0.55 + 0.45 * sin(length(p) * 14.0 - iTime * 0.8);
    col *= 0.75 + 0.35 * rings;

    // 外圈暗筒
    float tube = smoothstep(1.08, 0.88, length(uv));
    col *= tube;
    col *= 0.65 + 0.35 * (1.0 - length(uv) * 0.55);

    fragColor = vec4(pow(max(col, 0.0), vec3(0.9)), 1.0);
}
