// 第 15 章 · 后期进阶 · 阶段 8：电影感出场配方（HARD）
// 一条 runnable 管线：霓虹场景 → 色差 → 暗角 → 胶片颗粒 → 轻微桶形畸变。
//
// === 出场配方（Cinematic Pack）===
// 1. 渲染源（此处：2D 霓虹 + 简易 raymarch 混合）
// 2. Chromatic aberration：RGB 各偏移采样
// 3. Vignette：四角压暗
// 4. Film grain：时间噪声叠加
// 5. Barrel distortion：边缘微弯
const float TAU = 6.2831853;

float hash11(float n) { return fract(sin(n) * 43758.5453); }
float hash21(vec2 p)  { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

// --- 源场景：2D 霓虹隧道 ---
vec3 neonTunnel(vec2 uv)
{
    vec2 p = uv;
    float t = iTime * 0.4;
    float a = atan(p.y, p.x);
    float r = length(p);

    float tunnel = sin(8.0 / (r + 0.15) - t * 3.0 + a * 2.0);
    tunnel = smoothstep(0.2, 0.85, tunnel);

    vec3 c1 = vec3(0.1, 0.85, 1.0);
    vec3 c2 = vec3(1.0, 0.25, 0.65);
    vec3 col = mix(c1, c2, 0.5 + 0.5 * sin(a * 3.0 + t));
    col *= tunnel * exp(-r * 0.55);

    col += vec3(0.05, 0.02, 0.12) * (1.0 - smoothstep(0.0, 1.2, r));
    return col;
}

// --- 简易 raymarch 球体点缀 ---
mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    return mat3(cu, cross(cu, cw), cw);
}

float sdSphere(vec3 p, float r) { return length(p) - r; }

float mapRM(vec3 p)
{
    float d = sdSphere(p - vec3(0.0, 0.0, 2.5), 0.55);
    d = min(d, sdSphere(p - vec3(0.8 * sin(iTime), 0.3, 1.8), 0.25));
    return d;
}

vec3 rmShade(vec3 ro, vec3 rd)
{
    float t = 0.0;
    for (int i = 0; i < 48; i++) {
        vec3 p = ro + rd * t;
        float d = mapRM(p);
        if (d < 0.001 || t > 12.0) break;
        t += d * 0.85;
    }
    if (t > 12.0) return vec3(0.0);
    vec3 p = ro + rd * t;
    vec3 n = normalize(vec3(
        mapRM(p + vec3(0.01, 0, 0)) - mapRM(p - vec3(0.01, 0, 0)),
        mapRM(p + vec3(0, 0.01, 0)) - mapRM(p - vec3(0, 0.01, 0)),
        mapRM(p + vec3(0, 0, 0.01)) - mapRM(p - vec3(0, 0, 0.01))
    ));
    float dif = max(dot(n, normalize(vec3(0.5, 0.7, -0.4))), 0.0);
    vec3 alb = mix(vec3(1.0, 0.35, 0.55), vec3(0.2, 0.9, 1.0), 0.5 + 0.5 * sin(iTime));
    return alb * (0.2 + dif) + alb * 0.5;
}

vec3 renderSource(vec2 uv)
{
    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);

    vec3 neon = neonTunnel(p);
    vec3 ro = vec3(0.0, 0.0, -2.0);
    vec3 rd = setCamera(ro, vec3(0, 0, 3)) * normalize(vec3(p, 1.2));
    vec3 rm = rmShade(ro, rd);

    vec3 col = neon + rm * 0.85;
    col = col / (col + vec3(0.6));
    return col;
}

vec2 barrel(vec2 uv, float k)
{
    vec2 c = uv - 0.5;
    float r2 = dot(c, c);
    return uv + c * r2 * k;
}

vec3 chromaticSample(vec2 uv, float amt)
{
    vec3 col;
    col.r = renderSource(barrel(uv + vec2(amt, 0.0), 0.0)).r;
    col.g = renderSource(barrel(uv, 0.0)).g;
    col.b = renderSource(barrel(uv - vec2(amt, 0.0), 0.0)).b;
    return col;
}

float filmGrain(vec2 uv, float t)
{
    return hash21(uv * iResolution.xy + floor(t * 24.0)) * 2.0 - 1.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // 配方 Step 1-2：桶形 + 色差（先对 UV 做 barrel，再 RGB 分离）
    float aber = 0.0018 + 0.0008 * sin(iTime * 0.5);
    vec2 uvc = barrel(uv, 0.12);
    vec3 col = chromaticSample(clamp(uvc, 0.01, 0.99), aber);

    // Step 3：暗角
    vec2 q = uv - 0.5;
    float vig = 1.0 - dot(q, q) * 1.35;
    col *= smoothstep(0.15, 1.0, vig);

    // Step 4：胶片颗粒
    col += filmGrain(uv, iTime) * 0.035;

    // Step 5：轻微色调 + 扫描感
    col *= 0.92 + 0.08 * sin(fragCoord.y * 1.8 + iTime * 10.0);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.92));

    fragColor = vec4(col, 1.0);
}
