// 第 9 章 · 阶梯实战 · 阶段 7：廉价 SSS —— 半透明球 vs 不透明邻居
// Wrap lighting + 厚度近似（背光透射）；左 SSS 玉球，右普通漫反射球。
// 真 SSS = 多散射积分/厚度图；这里 wrap + pow 透射足够「有趣」。
#define SUN normalize(vec3(0.55, 0.65, -0.20))

vec2 map(vec3 p)
{
    float sphL = length(p - vec3(-1.15, 1.0, 0.0)) - 0.85;
    float sphR = length(p - vec3( 1.15, 1.0, 0.0)) - 0.85;
    float sph  = min(sphL, sphR);
    float id   = (sphL < sphR) ? 1.0 : 2.0;
    return (sph < p.y) ? vec2(sph, id) : vec2(p.y, 0.0);
}

vec2 trace(vec3 ro, vec3 rd)
{
    float t = 0.02;
    for (int i = 0; i < 80; i++) {
        vec2 h = map(ro + rd * t);
        if (h.x < 0.002 * t) return vec2(t, h.y);
        t += h.x;
        if (t > 50.0) break;
    }
    return vec2(-1.0, 0.0);
}

vec3 calcNormal(vec3 p)
{
    vec2 e = vec2(0.0015, 0.0);
    return normalize(vec3(map(p + e.xyy).x - map(p - e.xyy).x,
                          map(p + e.yxy).x - map(p - e.yxy).x,
                          map(p + e.yyx).x - map(p - e.yyx).x));
}

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    return mat3(cu, cross(cu, cw), cw);
}

vec3 envColor(vec3 rd)
{
    float h = rd.y;
    vec3 horizon = vec3(0.42, 0.50, 0.62);
    vec3 col = (h > 0.0)
        ? mix(horizon, vec3(0.06, 0.14, 0.36), pow(h, 0.55))
        : mix(horizon, vec3(0.10, 0.09, 0.085), pow(-h, 0.35));
    return col;
}

// 厚度近似：沿背光方向在球内的路径长度
float approxThickness(vec3 pos, vec3 nor, vec3 lightDir, float radius)
{
    float ndl = dot(nor, lightDir);
    // 背光面：光穿过球体，厚度 ∝ 1/|N·L|
    float wrap = clamp((ndl + 0.45) / 1.45, 0.0, 1.0);  // wrap diffuse
    float back = clamp(-ndl, 0.0, 1.0);
    float thick = back * 1.6 + (1.0 - wrap) * 0.3;
    return thick;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float an = 0.42 + 0.08 * sin(iTime * 0.18);
    vec3  ro = vec3(3.95 * sin(an), 1.45, 3.95 * cos(an));
    vec3  rd = setCamera(ro, vec3(0.0, 0.92, 0.0)) * normalize(vec3(p, 1.7));

    vec3 col = envColor(rd);

    vec2 h = trace(ro, rd);
    if (h.x > 0.0) {
        vec3 pos = ro + rd * h.x;
        vec3 nor = calcNormal(pos);
        bool isSSS = (h.y < 1.5);

        vec3 albedo = isSSS ? vec3(0.25, 0.72, 0.42)    // 玉色
                            : vec3(0.62, 0.13, 0.07);   // 不透明红

        float ndl = dot(nor, SUN);
        float dif = clamp(ndl, 0.0, 1.0);
        float sky = sqrt(clamp(0.5 + 0.5 * nor.y, 0.0, 1.0));

        vec3 lin = vec3(0.0);

        if (isSSS) {
            // Wrap lighting：暗部不全黑
            float wrap = clamp((ndl + 0.55) / 1.55, 0.0, 1.0);
            lin += albedo * wrap * vec3(0.9, 1.1, 0.85);

            // 背光透射（次表面）
            float thick = approxThickness(pos, nor, SUN, 0.85);
            vec3 transCol = vec3(0.15, 0.95, 0.55);
            float trans = pow(clamp(-ndl, 0.0, 1.0), 2.0) * exp(-thick * 1.8);
            lin += transCol * trans * 1.4;

            // 边缘 rim（蜡质感）
            float rim = pow(1.0 - clamp(dot(nor, -rd), 0.0, 1.0), 2.5);
            lin += vec3(0.4, 0.9, 0.6) * rim * 0.35;
        } else {
            lin += albedo * dif * vec3(1.35, 1.10, 0.80);
        }

        lin += albedo * sky * 0.22;
        col = lin;
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
