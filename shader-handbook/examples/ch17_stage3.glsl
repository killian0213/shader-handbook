// 第 17 章 · 代码高尔夫 · 阶段 3：理解后的「迷你高尔夫」
// 真·Creation 高尔夫约 15 行、无空格、变量单字母；这是「你已读懂之后」的短版。
// 真实竞赛版还会用 #define t iTime、省略 max() 防护等——此处仍保证可编译。

#define t iTime
#define r iResolution.xy

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 c;
    float l, z = t;
    for (int i = 0; i < 3; i++) {
        vec2 uv, p = fragCoord / r;
        uv = p;
        p -= 0.5;
        p.x *= r.x / r.y;
        z += 0.07;
        l = length(p);
        uv += p / max(l, 1e-4) * (sin(z) + 1.0) * abs(sin(l * 9.0 - z - z));
        c[i] = 0.01 / length(mod(uv, 1.0) - 0.5);
    }
    fragColor = vec4(c / max(l, 0.15), 1.0);
}
