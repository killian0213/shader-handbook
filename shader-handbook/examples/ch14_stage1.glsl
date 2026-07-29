// 第 14 章 · 阶梯实战 · 阶段 1：粒子系统（单 Pass）
// 不用 Buffer：每个粒子的位置由 id + iTime 解析算出。
// 真·交互粒子要把状态写进 Buffer；这里先把「成千上万个点」的感觉做出来。
float hash11(float n) { return fract(sin(n)*43758.5453); }
vec2  hash12(float n) { return fract(sin(vec2(n,n+17.1))*vec2(43758.5453,22578.145)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y;
    vec3 col = vec3(0.02, 0.03, 0.06);

    const int N = 80;
    for (int i = 0; i < N; i++) {
        float id = float(i);
        vec2  seed = hash12(id);
        float spd  = 0.35 + 0.65*seed.x;
        float ph   = seed.y * 6.28318;
        // 椭圆轨道 + 轻微噪声相位
        vec2  cen  = 0.55 * vec2(sin(iTime*spd + ph), cos(iTime*spd*0.85 + ph*1.3));
        cen += 0.08 * vec2(sin(iTime*2.0+id), cos(iTime*1.7-id));
        float d = length(uv - cen);
        float glow = exp(-d * 90.0) * (0.6 + 0.4*seed.x);
        vec3  pc = 0.5 + 0.5*cos(6.28318*(seed.x + vec3(0.0,0.33,0.67)));
        col += pc * glow;
    }

    fragColor = vec4(col, 1.0);
}
