// 第 6 章 · 阶梯实战 · 阶段 2：第一圈花瓣
// 新东西只有两个函数：把平面折进一个扇形，然后在扇形里画【一枚】花瓣。
const float TAU = 6.2831853;

// 把整个平面折进 1/n 个扇形。
// 用 atan(p.x, p.y) 而不是 atan(p.y, p.x)：前者从 +y 轴量角，
// 折出来的花瓣自然"朝上"，摆图元时不用再脑内旋转 90°。
vec2 fold(vec2 p, float n)
{
    float sector = TAU / n;
    float a = atan(p.x, p.y);
    a = mod(a + 0.5 * sector, sector) - 0.5 * sector;
    return length(p) * vec2(sin(a), cos(a));
}

// iq 的 vesica：两个圆相交出的透镜形，是最像花瓣的 2D 图元。
// 长轴沿 y：半长 = sqrt(r*r-d*d)，半宽 = r-d。
float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);
    float b = sqrt(r * r - d * d);
    return ((p.y - b) * d > p.x * b)
        ? length(p - vec2(0.0, b))
        : length(p - vec2(-d, 0.0)) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float r = length(p);

    vec3 col = mix(vec3(0.16, 0.06, 0.14), vec3(0.02, 0.02, 0.06),
                   smoothstep(0.0, 1.10, r));
    float k    = r * 14.0;
    float ring = (abs(fract(k) - 0.5) - 0.18) / 14.0;
    col += vec3(0.10, 0.06, 0.16) * smoothstep(0.004, 0.0, ring);

    // --- 新增：12 枚花瓣。注意代码里只画了一枚。 ---
    vec2  q = fold(p, 12.0);
    float d = sdVesica(q - vec2(0.0, 0.58), 0.30, 0.21);

    col = mix(col, vec3(0.98, 0.72, 0.35), smoothstep(0.005, -0.005, d));
    // 有了真正的距离，描边就是免费的：|d| 小的地方就是轮廓
    col = mix(col, vec3(1.0), 0.7 * smoothstep(0.006, 0.0, abs(d) - 0.003));

    fragColor = vec4(col, 1.0);
}
