// 第 6 章 · 阶梯实战 · 阶段 3：三层花瓣
// 一圈花瓣好看，但太单薄。曼陀罗的层次感来自【同一个函数换参数调用三次】。
const float TAU = 6.2831853;

vec2 fold(vec2 p, float n)
{
    float sector = TAU / n;
    float a = atan(p.x, p.y);
    a = mod(a + 0.5 * sector, sector) - 0.5 * sector;
    return length(p) * vec2(sin(a), cos(a));
}

float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);
    float b = sqrt(r * r - d * d);
    return ((p.y - b) * d > p.x * b)
        ? length(p - vec2(0.0, b))
        : length(p - vec2(-d, 0.0)) - r;
}

// vesica 的 (r,d) 不直观。改成用【半长 L、半宽 W】描述花瓣：
// 半宽 = r-d，半长 = sqrt(r*r-d*d)  →  反解出 r 和 d。要求 W < L。
float sdPetal(vec2 p, float L, float W)
{
    float s = L * L / W;
    return sdVesica(p, 0.5 * (W + s), 0.5 * (s - W));
}

// 一整圈花瓣：n 枚，花瓣中心距原点 rad，整圈转 rot
float petalRing(vec2 p, float n, float rad, float L, float W, float rot)
{
    float c = cos(rot), s = sin(rot);
    p = mat2(c, -s, s, c) * p;
    return sdPetal(fold(p, n) - vec2(0.0, rad), L, W);
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

    // --- 新增：三层，由外到内。瓣数、半径、长宽、相位全都不同 ---
    float d1 = petalRing(p, 12.0, 0.62, 0.26, 0.085,  0.00);
    float d2 = petalRing(p,  8.0, 0.40, 0.20, 0.075,  0.26);
    float d3 = petalRing(p, 16.0, 0.22, 0.12, 0.038, -0.10);

    // 由外到内依次盖上去，后画的在上面 —— 就是图层顺序
    vec3 c1 = vec3(0.86, 0.30, 0.48);
    vec3 c2 = vec3(0.98, 0.62, 0.30);
    vec3 c3 = vec3(1.00, 0.88, 0.52);

    col = mix(col, c1, smoothstep(0.005, -0.005, d1));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d1) - 0.003));
    col = mix(col, c2, smoothstep(0.005, -0.005, d2));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d2) - 0.003));
    col = mix(col, c3, smoothstep(0.005, -0.005, d3));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d3) - 0.003));

    fragColor = vec4(col, 1.0);
}
