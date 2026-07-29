// 第 6 章 · 阶梯实战 · 阶段 5：花瓣里的脉络
// 大色块已经成型，缺的是"细节密度"。
// 关键认识：在【折叠后的坐标】里加任何纹理，都会自动符合整圈对称——不用管重复。
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

float sdPetal(vec2 p, float L, float W)
{
    float s = L * L / W;
    return sdVesica(p, 0.5 * (W + s), 0.5 * (s - W));
}

float petalRing(vec2 p, float n, float rad, float L, float W, float rot)
{
    float c = cos(rot), s = sin(rot);
    p = mat2(c, -s, s, c) * p;
    return sdPetal(fold(p, n) - vec2(0.0, rad), L, W);
}

float ringBand(float r, float rad, float w)
{
    return smoothstep(0.005, 0.0, abs(r - rad) - w);
}

// 脉络：折叠空间里的一组弯曲条纹。
// sin 里再套一个 sin 就是最廉价的域扭曲，条纹立刻从"直"变"有机"。
float veins(vec2 q, float freq, float bend)
{
    return 0.5 + 0.5 * sin(freq * q.y + bend * sin(freq * 0.4 * q.x));
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

    float d1 = petalRing(p, 12.0, 0.62, 0.26, 0.085,  0.00);
    float d2 = petalRing(p,  8.0, 0.40, 0.20, 0.075,  0.26);
    float d3 = petalRing(p, 16.0, 0.22, 0.12, 0.038, -0.10);

    vec3 c1 = vec3(0.86, 0.30, 0.48);
    vec3 c2 = vec3(0.98, 0.62, 0.30);
    vec3 c3 = vec3(1.00, 0.88, 0.52);

    // --- 新增：每层花瓣填色时，用它自己折叠空间里的脉络调制明暗 ---
    float v1 = veins(fold(p, 12.0), 44.0, 2.2);
    float v2 = veins(fold(p,  8.0), 60.0, 1.6);

    col = mix(col, c1 * (0.72 + 0.28 * v1), smoothstep(0.005, -0.005, d1));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d1) - 0.003));
    col = mix(col, c2 * (0.78 + 0.22 * v2), smoothstep(0.005, -0.005, d2));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d2) - 0.003));
    col = mix(col, c3, smoothstep(0.005, -0.005, d3));
    col = mix(col, vec3(1.0), 0.5 * smoothstep(0.005, 0.0, abs(d3) - 0.003));

    const float NS     = 36.0;
    float       sector = TAU / NS;
    float a   = atan(p.y, p.x);
    float sid = mod(floor(a / sector), NS);
    vec3 bc   = mix(vec3(0.80, 0.26, 0.42), vec3(1.00, 0.84, 0.52), mod(sid, 2.0));
    col = mix(col, bc, ringBand(r, 0.95, 0.030));
    col = mix(col, vec3(1.00, 0.92, 0.72), ringBand(r, 1.005, 0.004));

    // --- 新增：外环内侧再加一圈 72 齿的细密射线，密度层次立刻拉开 ---
    float teeth = 0.5 + 0.5 * cos(a * 72.0);
    col = mix(col, vec3(0.95, 0.80, 0.95) * teeth, ringBand(r, 0.885, 0.020));

    col = mix(col, vec3(0.35, 0.10, 0.22), smoothstep(0.005, -0.005, r - 0.115));
    col = mix(col, vec3(1.00, 0.86, 0.40), smoothstep(0.005, -0.005, r - 0.075));
    col = mix(col, vec3(0.30, 0.08, 0.18), smoothstep(0.004, -0.004, r - 0.028));

    fragColor = vec4(col, 1.0);
}
