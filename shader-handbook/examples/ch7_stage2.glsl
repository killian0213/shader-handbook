// 第 7 章 · 阶梯实战 · 阶段 2：法线上色
// 新增的只有一个函数 calcNormal，和一行 col = nor*0.5+0.5。
// 剪影一下变成球体 —— 立体感全部来自法线。
#define MAX_STEPS 90
#define MAX_DIST  30.0

float sdSphere(vec3 p, float r) { return length(p) - r; }

float map(vec3 p)
{
    return sdSphere(p - vec3(0.0, 1.0, 0.0), 1.0);
}

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

// 法线就是距离场的梯度。四面体 4-tap：四个采样点取正四面体的顶点方向，
// 只要 4 次 map（中心差分要 6 次），精度同阶。
// 0.5773 ≈ 1/√3，把 (±1,±1,±1) 归一化成单位向量。
vec3 calcNormal(vec3 pos)
{
    vec2 e = vec2(1.0, -1.0) * 0.5773 * 0.0015;
    return normalize(e.xyy * map(pos + e.xyy) +
                     e.yyx * map(pos + e.yyx) +
                     e.yxy * map(pos + e.yxy) +
                     e.xxx * map(pos + e.xxx));
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

    float an = 0.28 + 0.10 * sin(iTime * 0.13);
    vec3  ta = vec3(0.0, 0.95, 0.0);
    vec3  ro = vec3(4.2 * sin(an), 1.45, 4.2 * cos(an));
    mat3  ca = setCamera(ro, ta, 0.0);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    float t   = raymarch(ro, rd);
    vec3  col = vec3(0.0);

    if (t < MAX_DIST) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);
        col = nor * 0.5 + 0.5;      // [-1,1] → [0,1]，法线当颜色看
    }

    fragColor = vec4(col, 1.0);
}
