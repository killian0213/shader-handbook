// 第 14 章 · 阶梯实战 · 阶段 4：粒子 + 波 + 调色打磨
// 把阶段 1/2 叠在一起，加暗角与软膝——仿真章的「能截图」终点。
// 真 Gray-Scott / 流体请到 Shadertoy 按 14.3–14.5 节接 Buffer。
float hash11(float n) { return fract(sin(n)*43758.5453); }
vec2  hash12(float n) { return fract(sin(vec2(n,n+17.1))*vec2(43758.5453,22578.145)); }

vec3 softKnee(vec3 c)
{
    const float K = 0.85;
    vec3 hi = max(c - K, 0.0);
    return min(c, vec3(K)) + (1.0-K)*(1.0-exp(-hi/(1.0-K)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y;

    // 波底
    float h = 0.0;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        vec2  c  = 0.65 * vec2(sin(fi*1.9), cos(fi*2.1+0.5));
        float t  = max(iTime - fi*1.0, 0.0);
        float r  = length(uv - c);
        float w  = sin(36.0*r - 7.5*t) * exp(-2.0*r) * exp(-0.3*t);
        w *= smoothstep(0.0, 0.05, t - r*0.85);
        h += w;
    }
    vec3 col = mix(vec3(0.04, 0.06, 0.12), vec3(0.25, 0.45, 0.70), 0.5+0.5*h);

    // 粒子
    for (int i = 0; i < 60; i++) {
        float id = float(i);
        vec2  seed = hash12(id);
        float spd  = 0.4 + 0.6*seed.x;
        float ph   = seed.y * 6.28318;
        vec2  cen  = 0.50 * vec2(sin(iTime*spd + ph), 0.65*cos(iTime*spd*0.9 + ph));
        float d = length(uv - cen);
        float glow = exp(-d * 100.0);
        vec3  pc = 0.55 + 0.45*cos(6.28318*(seed.x + vec3(0.0,0.25,0.55)));
        col += pc * glow * 0.9;
    }

    vec2 q = fragCoord / iResolution.xy;
    col *= 0.55 + 0.45*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.35);
    col = softKnee(col);
    fragColor = vec4(col, 1.0);
}
