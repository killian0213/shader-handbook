// 第 14 章 · 阶梯实战 · 阶段 11：假布料 / 旗帜
// 网格顶点 sin 波位移 + 简易光照，悬挂织物直觉。
// 真版 = Verlet 质点弹簧链 + 约束；这里解析位移，展示「格子面片」观感。
const int GRID_X = 28;
const int GRID_Y = 16;

float hash11(float n) { return fract(sin(n) * 43758.5453); }

// 解析「质点」位置：顶部固定，下方随 sin + 风场摆动
vec3 clothPoint(float ix, float iy, float t)
{
    float u = ix / float(GRID_X - 1);
    float v = iy / float(GRID_Y - 1);

    vec3 p = vec3(u * 2.4 - 1.2, 1.35 - v * 1.5, 0.0);

    // 顶部边固定（pin）
    float pin = smoothstep(0.02, 0.08, v);

    float wave = sin(u * 8.0 + t * 2.2) * 0.08 * v;
    wave += sin(u * 5.0 - t * 1.4 + v * 3.0) * 0.05 * v;
    float wind = sin(t * 0.9 + u * 4.0) * 0.06 * v * v;

    p.x += (wave + wind) * pin;
    p.z += (cos(u * 6.0 + t * 1.8) * 0.04 + wind * 0.5) * pin;
    p.y += sin(v * 3.14 + t * 0.5) * 0.02 * pin;

    return p;
}

// 两三角形面片的法线（quad 由四顶点构成）
vec3 quadNormal(vec2 ij, float t)
{
    vec3 p00 = clothPoint(ij.x,     ij.y,     t);
    vec3 p10 = clothPoint(ij.x + 1.0, ij.y,     t);
    vec3 p01 = clothPoint(ij.x,     ij.y + 1.0, t);
    vec3 p11 = clothPoint(ij.x + 1.0, ij.y + 1.0, t);
    vec3 n1 = normalize(cross(p10 - p00, p01 - p00));
    vec3 n2 = normalize(cross(p01 - p10, p11 - p10));
    return normalize(n1 + n2);
}

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    return mat3(cu, cross(cu, cw), cw);
}

// 射线-三角形（Möller–Trumbore 简化）
float rayTri(vec3 ro, vec3 rd, vec3 v0, vec3 v1, vec3 v2)
{
    vec3 e1 = v1 - v0, e2 = v2 - v0;
    vec3 p  = cross(rd, e2);
    float det = dot(e1, p);
    if (abs(det) < 1e-5) return -1.0;
    float inv = 1.0 / det;
    vec3 tv = ro - v0;
    float u = dot(tv, p) * inv;
    if (u < 0.0 || u > 1.0) return -1.0;
    vec3 q = cross(tv, e1);
    float v = dot(rd, q) * inv;
    if (v < 0.0 || u + v > 1.0) return -1.0;
    float tt = dot(e2, q) * inv;
    return (tt > 0.01) ? tt : -1.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime;

    vec3 ro = vec3(0.0, 0.85, 3.2);
    vec3 rd = setCamera(ro, vec3(0.0, 0.65, 0.0)) * normalize(vec3(p, 1.6));

    vec3 col = mix(vec3(0.12, 0.16, 0.24), vec3(0.04, 0.05, 0.08), p.y * 0.5 + 0.5);

    float hitT = 1e9;
    vec2 hitIJ = vec2(-1.0);
    int hitTri = 0;

    for (int j = 0; j < GRID_Y - 1; j++)
        for (int i = 0; i < GRID_X - 1; i++) {
            vec3 p00 = clothPoint(float(i),     float(j),     t);
            vec3 p10 = clothPoint(float(i + 1), float(j),     t);
            vec3 p01 = clothPoint(float(i),     float(j + 1), t);
            vec3 p11 = clothPoint(float(i + 1), float(j + 1), t);

            float t0 = rayTri(ro, rd, p00, p10, p01);
            if (t0 > 0.0 && t0 < hitT) { hitT = t0; hitIJ = vec2(float(i), float(j)); hitTri = 0; }

            t0 = rayTri(ro, rd, p10, p11, p01);
            if (t0 > 0.0 && t0 < hitT) { hitT = t0; hitIJ = vec2(float(i), float(j)); hitTri = 1; }
        }

    if (hitT < 1e8) {
        vec3 nor = quadNormal(hitIJ, t);
        vec3 pos = ro + rd * hitT;

        vec3 sun = normalize(vec3(0.4, 0.7, -0.5));
        float dif = clamp(dot(nor, sun), 0.0, 1.0);
        float rim = pow(1.0 - clamp(dot(nor, -rd), 0.0, 1.0), 3.0);

        // 格子纹理暗示网格
        float u = hitIJ.x / float(GRID_X);
        float v = hitIJ.y / float(GRID_Y);
        float weave = 0.85 + 0.15 * sin(u * 120.0) * sin(v * 80.0);
        vec3 fabric = vec3(0.72, 0.18, 0.14) * weave;

        col = fabric * (0.25 + 0.75 * dif);
        col += vec3(0.9, 0.85, 0.7) * rim * 0.25;
        col += vec3(0.15, 0.12, 0.10) * (1.0 - dif) * 0.3;
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
