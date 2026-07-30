// 第 11 章 · 3D 分形阶梯 · 阶段 10：Mandelbulb（较难）
// 球坐标上的「三维平方」；先 stage8/9 吃透折叠，再来这里。
// 迭代 7 次保预览性能；加到 8～10 细节更锐、更慢。
#define MAX_STEPS 72
#define MAX_DIST  8.0
#define MB_ITER   7
const float POWER = 8.0;

float mandelbulbDE(vec3 pos, out float trap)
{
    vec3  z = pos;
    float dr = 1.0, r = 0.0;
    trap = 1e10;
    for (int i = 0; i < 16; i++) {
        if (i >= MB_ITER) break;
        r = length(z);
        if (r > 2.0) break;
        trap = min(trap, r);

        float theta = acos(clamp(z.z / max(r, 1e-6), -1.0, 1.0));
        float phi   = atan(z.y, z.x);
        dr = pow(r, POWER - 1.0) * POWER * dr + 1.0;

        float zr = pow(r, POWER);
        theta *= POWER;
        phi   *= POWER;
        z = zr * vec3(sin(theta) * cos(phi),
                      sin(theta) * sin(phi),
                      cos(theta)) + pos;
    }
    return 0.5 * log(max(r, 1e-6)) * r / max(dr, 1e-6);
}

float map(vec3 p, out float trap)
{
    // 略放大：经典 bulb 大约落在 |p|<1.2
    return mandelbulbDE(p, trap);
}

float map(vec3 p)
{
    float t;
    return map(p, t);
}

vec2 raymarch(vec3 ro, vec3 rd, out float trap)
{
    float t = 0.0, m = -1.0;
    trap = 1.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        float tr;
        float h = map(ro + rd * t, tr);
        if (h < 0.001 * t) { m = 1.0; trap = tr; break; }
        if (t > MAX_DIST) break;
        t += h * 0.9;
    }
    return vec2(t, m);
}

vec3 calcNormal(vec3 pos)
{
    vec2 e = vec2(1.0, -1.0) * 0.5773 * 0.0008;
    return normalize(e.xyy * map(pos + e.xyy) +
                     e.yyx * map(pos + e.yyx) +
                     e.yxy * map(pos + e.yxy) +
                     e.xxx * map(pos + e.xxx));
}

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    return mat3(cu, cross(cu, cw), cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float an = 0.4 + iTime * 0.12;
    vec3  ta = vec3(0.0, 0.15, 0.0);
    vec3  ro = vec3(2.4 * sin(an), 0.9, 2.4 * cos(an));
    vec3  rd = setCamera(ro, ta) * normalize(vec3(p, 2.4));

    float trap;
    vec2 hit = raymarch(ro, rd, trap);
    vec3 col = mix(vec3(0.02, 0.03, 0.06), vec3(0.08, 0.10, 0.18), rd.y * 0.5 + 0.5);

    if (hit.y > 0.0) {
        vec3 pos = ro + rd * hit.x;
        vec3 nor = calcNormal(pos);
        vec3 lig = normalize(vec3(0.6, 0.8, 0.3));
        float dif = clamp(dot(nor, lig), 0.0, 1.0);
        float fre = pow(1.0 - clamp(dot(-rd, nor), 0.0, 1.0), 3.0);
        float tt  = clamp(trap * 1.2, 0.0, 1.0);
        vec3 mate = 0.5 + 0.5 * cos(6.28318 * (tt + vec3(0.0, 0.33, 0.67)));
        mate = mix(mate, vec3(0.9, 0.85, 0.75), 0.25);
        col = mate * (1.1 * dif + 0.2) + fre * vec3(0.6, 0.7, 1.0) * 0.25;
    }

    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
