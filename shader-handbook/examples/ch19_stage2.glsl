// 第 19 章 · 性能调试 · LOD 对比（高/低 octave FBM 地形）
// 左：6 octave 精细；右：2 octave 廉价；同机位。

float hash21(vec2 p)
{
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float noise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p, int oct)
{
    float v = 0.0, a = 0.5;
    mat2 r = mat2(1.6, 1.2, -1.2, 1.6);
    for (int i = 0; i < 6; i++) {
        if (i >= oct) break;
        v += a * noise(p);
        p = r * p;
        a *= 0.5;
    }
    return v;
}

vec3 renderTerrain(vec2 uv, int oct, float t)
{
    vec3 ro = vec3(0.0, 1.8, 3.2);
    vec3 rd = normalize(vec3(uv, -1.1));
    ro.xz *= mat2(cos(t * 0.1), -sin(t * 0.1), sin(t * 0.1), cos(t * 0.1));

    float depth = 0.0;
    vec3 col = mix(vec3(0.55, 0.72, 0.95), vec3(0.75, 0.85, 1.0), uv.y * 0.5 + 0.5);

    for (int i = 0; i < 80; i++) {
        vec3 p = ro + rd * depth;
        float h = fbm(p.xz * 0.8, oct) * 1.4 - 0.3;
        float d = p.y - h;
        if (d < 0.002) {
            vec2 e = vec2(0.05, 0.0);
            vec3 n = normalize(vec3(
                fbm(p.xz + e.xy, oct) - fbm(p.xz - e.xy, oct),
                0.12,
                fbm(p.xz + e.yx, oct) - fbm(p.xz - e.yx, oct)));
            col = mix(vec3(0.25, 0.45, 0.22), vec3(0.55, 0.48, 0.35), clamp(n.y, 0.0, 1.0));
            col *= 0.4 + 0.6 * max(dot(n, normalize(vec3(0.4, 0.8, 0.3))), 0.0);
            break;
        }
        depth += d * 0.6;
        if (depth > 15.0) break;
    }
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.3;
    bool left = fragCoord.x < iResolution.x * 0.5;
    vec2 luv = uv;
    if (!left) luv.x -= (iResolution.x / iResolution.y) * 0.5;

    int oct = left ? 6 : 2;
    vec3 col = renderTerrain(luv, oct, t);

    // 分隔线与标签色
    float split = smoothstep(0.008, 0.0, abs(uv.x));
    col = mix(col, vec3(0.95, 0.85, 0.35), split);
    if (fragCoord.y > iResolution.y * 0.92)
        col = mix(left ? vec3(0.2, 0.85, 0.45) : vec3(0.95, 0.45, 0.25), col, 0.3);

    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
