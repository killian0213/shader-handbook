// 第 14 章 · 阶梯实战 · 阶段 3：反应扩散的「静态切片」
// 完整 Gray-Scott 需要 float Buffer + nearest 邻域。网页上先用
// 扭曲噪声模拟 RD 常见的斑点/条纹相，建立调参直觉（f/k 空间）。
float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(hash12(i), hash12(i+vec2(1,0)), f.x),
               mix(hash12(i+vec2(0,1)), hash12(i+vec2(1,1)), f.x), f.y);
}
float fbm(vec2 p)
{
    float v=0.0, a=0.5;
    for(int i=0;i<5;i++){ v+=a*vnoise(p); p=p*2.03+vec2(100.0); a*=0.5; }
    return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y;

    // 鼠标/时间在「形态空间」里漫游：不同区像 spots / stripes / worms
    vec2  q = uv * 2.2;
    float t = iTime * 0.15;
    vec2  w = vec2(fbm(q + t), fbm(q + vec2(5.2,1.3) - t));
    float n = fbm(q + 1.8*w);

    // 类 RD 的阈值 + 轻微拉普拉斯味道（用 n 的曲率近似）
    float edge = smoothstep(0.02, 0.0, abs(n - 0.55));
    float body = smoothstep(0.45, 0.62, n);

    vec3 col = mix(vec3(0.08, 0.05, 0.12), vec3(0.95, 0.75, 0.35), body);
    col = mix(col, vec3(0.20, 0.85, 0.90), edge * 0.85);
    col *= 0.85 + 0.15*fbm(q*3.0);

    fragColor = vec4(col, 1.0);
}
