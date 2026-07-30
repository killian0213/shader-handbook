// 第 11 章 · 3D 分形阶梯 · 阶段 9：Menger 完整（4 次迭代）
// 在 stage8 看懂十字掏空后，加迭代 + 简易 AO + 陷阱着色。
#define MAX_STEPS 80
#define MAX_DIST  20.0

const vec3 LIG = normalize(vec3(0.55, 0.75, -0.35));

float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float mengerDE(vec3 p, int iters, out float trap)
{
    float d = sdBox(p, vec3(1.0));
    float s = 1.0;
    trap = 1e10;
    for (int i = 0; i < 8; i++) {
        if (i >= iters) break;
        vec3 a = mod(p * s, 2.0) - 1.0;
        s *= 3.0;
        vec3 r = abs(1.0 - 3.0 * abs(a));
        float da = max(r.x, r.y);
        float db = max(r.y, r.z);
        float dc = max(r.z, r.x);
        float c = (min(da, min(db, dc)) - 1.0) / s;
        d = max(d, c);
        trap = min(trap, length(a));
    }
    return d;
}

float map(vec3 p, out float trap) { return mengerDE(p, 4, trap); }

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
        if (h < 0.0012 * t) { m = 1.0; trap = tr; break; }
        if (t > MAX_DIST) break;
        t += h;
    }
    return vec2(t, m);
}

vec3 calcNormal(vec3 pos)
{
    vec2 e = vec2(1.0, -1.0) * 0.5773 * 0.001;
    return normalize(e.xyy * map(pos + e.xyy) +
                     e.yyx * map(pos + e.yyx) +
                     e.yxy * map(pos + e.yxy) +
                     e.xxx * map(pos + e.xxx));
}

float ao(vec3 p, vec3 n)
{
    float occ = 0.0, sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.02 + 0.12 * float(i);
        occ += (h - map(p + n * h)) * sca;
        sca *= 0.85;
    }
    return clamp(1.0 - 1.8 * occ, 0.0, 1.0);
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
    float an = 0.55 + iTime * 0.08;
    vec3  ta = vec3(0.0, 0.05, 0.0);
    vec3  ro = vec3(2.8 * sin(an), 1.4, 2.8 * cos(an));
    vec3  rd = setCamera(ro, ta) * normalize(vec3(p, 2.2));

    float trap;
    vec2 hit = raymarch(ro, rd, trap);
    vec3 col = mix(vec3(0.05, 0.06, 0.10), vec3(0.12, 0.16, 0.28), rd.y * 0.5 + 0.5);

    if (hit.y > 0.0) {
        vec3 pos = ro + rd * hit.x;
        vec3 nor = calcNormal(pos);
        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float fre = pow(1.0 - clamp(dot(-rd, nor), 0.0, 1.0), 2.5);
        float occ = ao(pos, nor);
        vec3 mate = mix(vec3(0.55, 0.62, 0.75), vec3(0.95, 0.55, 0.35), smoothstep(0.2, 0.9, trap));
        col = mate * (1.15 * dif + 0.25) * occ + vec3(0.5, 0.65, 0.9) * fre * 0.2;
    }

    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
