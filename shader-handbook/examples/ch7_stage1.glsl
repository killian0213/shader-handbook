// 第 7 章 · 阶梯实战 · 阶段 1：命中，还是没命中
// 只做三件事：给每个像素造一条射线、沿射线往前走、看撞上没撞上。
// 画面丑得理直气壮 —— 但后面五个阶段全部长在这块地基上。
#define MAX_STEPS 90
#define MAX_DIST  30.0

float sdSphere(vec3 p, float r) { return length(p) - r; }

// 场函数：整个世界目前只有一个球，球心 (0,1,0)，半径 1 —— 正好坐在 y=0 上
float map(vec3 p)
{
    return sdSphere(p - vec3(0.0, 1.0, 0.0), 1.0);
}

// sphere tracing：每次沿视线安全前进 map(p) 那么远。
// 靠近表面时步长自动变小，远离时自动变大。
float raymarch(vec3 ro, vec3 rd)
{
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        float h = map(ro + rd * t);
        if (h < 0.001 || t > MAX_DIST) break;
        t += h;
    }
    return t;
}

mat3 setCamera(vec3 ro, vec3 ta, float cr)
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = cross(cu, cw);
    return mat3(cu, cv, cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 相机：极缓地绕场景摆动。六个阶段用的是同一台相机、同一个取景，
    // 这样你把六张图叠在一起看，变化的只有着色。
    float an = 0.28 + 0.10 * sin(iTime * 0.13);
    vec3  ta = vec3(0.0, 0.95, 0.0);
    vec3  ro = vec3(4.2 * sin(an), 1.45, 4.2 * cos(an));
    mat3  ca = setCamera(ro, ta, 0.0);

    // 焦距 2.2 → 纵向视场约 49°。务必 normalize，否则 t 不是世界距离。
    vec3 rd = ca * normalize(vec3(p, 2.2));

    float t = raymarch(ro, rd);

    // 命中 = 白，没命中 = 黑。就这样。
    vec3 col = vec3(t < MAX_DIST ? 1.0 : 0.0);

    fragColor = vec4(col, 1.0);
}
