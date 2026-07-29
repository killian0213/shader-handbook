// 第 10 章 · 阶梯实战 · 阶段 5：方向导数光照 + HG 相函数银边
// 密度场仍是 fbm 云。新增：用密度梯度估法线做明暗，
// 再用 Henyey-Greenstein 让「对着太阳的边缘」亮起来。
#define STEPS 64

float hash13(vec3 p)
{
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}
float vnoise(vec3 x)
{
    vec3 i = floor(x), f = fract(x);
    f = f*f*(3.0 - 2.0*f);
    return mix(mix(mix(hash13(i+vec3(0,0,0)), hash13(i+vec3(1,0,0)), f.x),
                   mix(hash13(i+vec3(0,1,0)), hash13(i+vec3(1,1,0)), f.x), f.y),
               mix(mix(hash13(i+vec3(0,0,1)), hash13(i+vec3(1,0,1)), f.x),
                   mix(hash13(i+vec3(0,1,1)), hash13(i+vec3(1,1,1)), f.x), f.y), f.z);
}
float fbm(vec3 p)
{
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * vnoise(p);
        p = p * 2.05 + vec3(100.0);
        a *= 0.5;
    }
    return v;
}
float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float density(vec3 p)
{
    float hy = smoothstep(0.05, 0.30, p.y) * smoothstep(1.40, 0.80, p.y);
    float hr = 1.0 - smoothstep(1.0, 1.85, length(p.xz));
    float n  = fbm(p*1.25 + vec3(iTime*0.04, 0.0, -iTime*0.02));
    return clamp((n - 0.47) * 1.9 * hy * hr, 0.0, 1.0);
}

// Henyey-Greenstein：g→1 强前向散射（银边），g=0 各向同性
float henyeyGreenstein(float cosTheta, float g)
{
    float g2 = g*g;
    return (1.0 - g2) / (4.0*3.14159 * pow(1.0 + g2 - 2.0*g*cosTheta, 1.5));
}

vec3 sky(vec3 rd, vec3 sun)
{
    float h = clamp(rd.y*0.5+0.5, 0.0, 1.0);
    vec3  col = mix(vec3(0.62, 0.72, 0.92), vec3(0.20, 0.38, 0.70), h);
    float s = pow(max(dot(rd, sun), 0.0), 8.0);
    col += vec3(1.0, 0.85, 0.55) * s * 0.55;
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y;

    vec3 sun = normalize(vec3(0.55, 0.55, -0.35));
    vec3 ro  = vec3(0.0, 0.50, 3.5);
    vec3 ta  = vec3(0.0, 0.55, 0.0);
    vec3 ww  = normalize(ta - ro);
    vec3 uu  = normalize(cross(ww, vec3(0,1,0)));
    vec3 vv  = cross(uu, ww);
    vec3 rd  = normalize(uv.x*uu + uv.y*vv + 1.55*ww);

    float mu = dot(rd, sun);           // 相函数用，循环外算一次
    float phase = mix(henyeyGreenstein(mu, 0.6),
                      henyeyGreenstein(mu,-0.3), 0.35);

    float tMin = 1.3, tMax = 5.8;
    float dt   = (tMax - tMin) / float(STEPS);
    float t    = tMin + hash21(fragCoord)*dt;

    float T = 1.0;
    vec3  col = vec3(0.0);
    const float SIGMA_T = 3.8;
    const float SIGMA_S = 3.5;

    for (int i = 0; i < STEPS; i++) {
        vec3  p = ro + rd * t;
        float d = density(p);
        if (d > 1e-4) {
            // 方向导数：朝太阳走一小步，密度下降 → 这面朝光
            float dS = density(p + sun * 0.18);
            float dif = clamp((d - dS) * 3.5 + 0.25, 0.15, 1.5);
            vec3  lin = vec3(0.55, 0.70, 0.95)*0.35          // 天光
                      + vec3(1.00, 0.90, 0.70)*dif*phase*1.1; // 太阳×相函数
            col += T * lin * (SIGMA_S * d) * dt;
            T   *= exp(-SIGMA_T * d * dt);
            if (T < 0.02) break;
        }
        t += dt;
        if (t > tMax) break;
    }

    col += T * sky(rd, sun);
    fragColor = vec4(col, 1.0);
}
