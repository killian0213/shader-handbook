// 第 9 章 · 阶梯实战 · 阶段 8：Triplanar 程序化岩石
// 盒体 + 球体：三平面投影混合噪声作 albedo，梯度作法线 bump。
// 真 triplanar = 三方向采样纹理加权混合；这里全程序化，可移植。
#define SUN normalize(vec3(0.55, 0.65, -0.20))

float hash11(float n) { return fract(sin(n) * 43758.5453); }

float vnoise(vec3 p)
{
    vec3 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n000 = hash11(dot(i, vec3(127.1, 311.7, 74.7)));
    float n100 = hash11(dot(i + vec3(1,0,0), vec3(127.1, 311.7, 74.7)));
    float n010 = hash11(dot(i + vec3(0,1,0), vec3(127.1, 311.7, 74.7)));
    float n110 = hash11(dot(i + vec3(1,1,0), vec3(127.1, 311.7, 74.7)));
    float n001 = hash11(dot(i + vec3(0,0,1), vec3(127.1, 311.7, 74.7)));
    float n101 = hash11(dot(i + vec3(1,0,1), vec3(127.1, 311.7, 74.7)));
    float n011 = hash11(dot(i + vec3(0,1,1), vec3(127.1, 311.7, 74.7)));
    float n111 = hash11(dot(i + vec3(1,1,1), vec3(127.1, 311.7, 74.7)));
    float nx00 = mix(n000, n100, f.x), nx10 = mix(n010, n110, f.x);
    float nx01 = mix(n001, n101, f.x), nx11 = mix(n011, n111, f.x);
    float nxy0 = mix(nx00, nx10, f.y), nxy1 = mix(nx01, nx11, f.y);
    return mix(nxy0, nxy1, f.z);
}

float fbm3(vec3 p)
{
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * vnoise(p);
        p = p * 2.02 + vec3(17.0, 23.0, 11.0);
        a *= 0.5;
    }
    return v;
}

// Triplanar 权重 + 三方向采样
float triplanarFbm(vec3 p, vec3 n)
{
    vec3 w = pow(abs(n), vec3(4.0));
    w /= dot(w, vec3(1.0));
    return fbm3(vec3(p.yz, 0.0)) * w.x
         + fbm3(vec3(p.zx, 0.0)) * w.y
         + fbm3(vec3(p.xy, 0.0)) * w.z;
}

vec3 triplanarColor(vec3 p, vec3 n)
{
    float h = triplanarFbm(p * 2.5, n);
    float d = triplanarFbm(p * 6.0 + 3.7, n);
    vec3 rock = mix(vec3(0.22, 0.20, 0.18), vec3(0.45, 0.42, 0.38), h);
    rock = mix(rock, vec3(0.12, 0.14, 0.11), smoothstep(0.55, 0.75, d));
    rock *= 0.85 + 0.15 * fbm3(p * 12.0);
    return rock;
}

vec3 bumpNormal(vec3 p, vec3 n, float scale)
{
    float e = 0.008;
    float c = triplanarFbm(p * scale, n);
    vec3 np = n;
    np.x += (triplanarFbm((p + vec3(e,0,0)) * scale, n) - c) / e;
    np.y += (triplanarFbm((p + vec3(0,e,0)) * scale, n) - c) / e;
    np.z += (triplanarFbm((p + vec3(0,0,e)) * scale, n) - c) / e;
    return normalize(np);
}

vec2 map(vec3 p)
{
    vec2 res = vec2(p.y, 0.0); // 地面优先参与比较

    float sph = length(p - vec3(-0.55, 0.95, 0.15)) - 0.75;
    if (sph < res.x) res = vec2(sph, 1.0);

    vec3 q = abs(p - vec3(1.05, 0.55, -0.25)) - vec3(0.55, 0.55, 0.45);
    float box = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
    if (box < res.x) res = vec2(box, 2.0);

    return res;
}

vec2 trace(vec3 ro, vec3 rd)
{
    float t = 0.02;
    for (int i = 0; i < 90; i++) {
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
    return mix(vec3(0.35, 0.42, 0.52), vec3(0.08, 0.14, 0.28), pow(abs(h), 0.5));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float an = 0.35 + 0.12 * sin(iTime * 0.15);
    vec3  ro = vec3(4.0 * sin(an), 1.55, 4.0 * cos(an));
    vec3  rd = setCamera(ro, vec3(0.2, 0.7, 0.0)) * normalize(vec3(p, 1.8));

    vec3 col = envColor(rd);

    vec2 h = trace(ro, rd);
    if (h.x > 0.0) {
        vec3 pos = ro + rd * h.x;
        vec3 geoNor = calcNormal(pos);
        vec3 nor = bumpNormal(pos, geoNor, 2.5);

        vec3 albedo = triplanarColor(pos, geoNor);
        if (h.y < 0.5) albedo = vec3(0.16, 0.15, 0.14);

        float dif = clamp(dot(nor, SUN), 0.0, 1.0);
        float sky = sqrt(clamp(0.5 + 0.5 * nor.y, 0.0, 1.0));
        float bou = clamp(0.25 - 0.75 * nor.y, 0.0, 1.0);
        float spe = pow(clamp(dot(reflect(-SUN, nor), -rd), 0.0, 1.0), 24.0);

        vec3 lin = vec3(0.0);
        lin += dif * vec3(1.25, 1.05, 0.82);
        lin += sky * vec3(0.20, 0.32, 0.50);
        lin += bou * vec3(0.12, 0.10, 0.08);
        col = albedo * lin;
        col += vec3(0.85, 0.80, 0.72) * spe * dif * 0.25;
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
