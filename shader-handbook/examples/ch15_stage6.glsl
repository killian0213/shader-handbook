// 第 15 章 · 后期进阶 · 阶段 6：假景深（DOF）
// 多颗不同深度的球体 + 基于 |z - focus| 的 Circle of Confusion 多采样模糊。
// 单 pass 近似：sharp 与 low-res 宽核混合，远处/近处都发虚。
const vec3 SUN = normalize(vec3(0.55, 0.72, -0.42));
const float FOCUS_Z = 4.2;
const float FOCUS_DIST = 5.5;

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    vec3 cv = cross(cu, cw);
    return mat3(cu, cv, cw);
}

float iPlane(vec3 ro, vec3 rd)
{
    if (abs(rd.y) < 1e-5) return -1.0;
    float t = -ro.y / rd.y;
    return (t > 0.001) ? t : -1.0;
}

float iSphere(vec3 ro, vec3 rd, vec3 c, float r)
{
    vec3  oc = ro - c;
    float b  = dot(oc, rd);
    float cc = dot(oc, oc) - r * r;
    float h  = b * b - cc;
    if (h < 0.0) return -1.0;
    h = sqrt(h);
    float t = -b - h;
    if (t < 0.001) t = -b + h;
    return (t > 0.001) ? t : -1.0;
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y * 0.5 + 0.5, 0.0, 1.0);
    return mix(vec3(0.08, 0.12, 0.22), vec3(0.45, 0.55, 0.72), h);
}

// 返回 (距离 t, 物体深度 z, 材质 id)
vec3 trace(vec3 ro, vec3 rd)
{
    float best = 1e20;
    float id   = 0.0;
    vec3  cen  = vec3(0.0);

    float tp = iPlane(ro, rd);
    if (tp > 0.0) { best = tp; id = 1.0; cen = ro + rd * tp; }

    vec3 spheres[4];
    spheres[0] = vec3(-1.4, 0.35, 2.0);
    spheres[1] = vec3(0.6,  0.55, 4.5);
    spheres[2] = vec3(1.3,  0.75, 7.2);
    spheres[3] = vec3(-0.5, 1.05, 10.0);
    float radii[4];
    radii[0] = 0.40; radii[1] = 0.55; radii[2] = 0.65; radii[3] = 0.85;

    for (int i = 0; i < 4; i++) {
        float t = iSphere(ro, rd, spheres[i], radii[i]);
        if (t > 0.0 && t < best) {
            best = t; id = float(i + 2); cen = spheres[i];
        }
    }

    if (id < 0.5) return vec3(-1.0);
    float z = length(cen - ro);
    return vec3(best, z, id);
}

vec3 shade(vec3 ro, vec3 rd, vec3 hit)
{
    if (hit.x < 0.0) return sky(rd);

    vec3 pos = ro + rd * hit.x;
    float id = hit.z;
    vec3 nor;
    vec3 alb;
    float emit = 0.0;

    if (id < 1.5) {
        nor = vec3(0.0, 1.0, 0.0);
        float chk = mod(floor(pos.x) + floor(pos.z), 2.0);
        alb = mix(vec3(0.18, 0.20, 0.24), vec3(0.42, 0.44, 0.48), chk);
    } else {
        vec3 c[4];
        c[0] = vec3(-1.4, 0.35, 2.0);
        c[1] = vec3(0.6,  0.55, 4.5);
        c[2] = vec3(1.3,  0.75, 7.2);
        c[3] = vec3(-0.5, 1.05, 10.0);
        int idx = int(id - 2.0);
        nor = normalize(pos - c[idx]);
        alb = mix(vec3(1.1, 0.35, 0.2), vec3(0.2, 0.9, 1.1), float(idx) / 3.0);
        emit = 0.35 + 0.15 * float(idx);
    }

    float dif = max(dot(nor, SUN), 0.0);
    float amb = 0.10 + 0.15 * max(nor.y, 0.0);
    return alb * (amb + dif) + alb * emit;
}

// CoC：离焦平面越远，模糊圈越大
float coc(float z)
{
    return clamp(abs(z - FOCUS_Z) * 0.055, 0.0, 0.035);
}

vec3 renderAt(vec2 uv)
{
    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float an = 0.15 + 0.08 * sin(iTime * 0.1);
    vec3 ta = vec3(0.0, 0.45, FOCUS_Z);
    vec3 ro = vec3(FOCUS_DIST * sin(an), 1.2, FOCUS_Z + FOCUS_DIST * cos(an));
    mat3 ca = setCamera(ro, ta);
    vec3 rd = ca * normalize(vec3(p, 1.8));
    vec3 hit = trace(ro, rd);
    return shade(ro, rd, hit);
}

vec3 dofSample(vec2 uv, vec2 px, float radius)
{
    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    const int TAPS = 8;
    for (int i = 0; i < TAPS; i++) {
        float ang = float(i) * 6.2831853 / float(TAPS);
        vec2 off = vec2(cos(ang), sin(ang)) * radius;
        float w = 1.0;
        acc += renderAt(uv + off * px) * w;
        wsum += w;
    }
    acc += renderAt(uv);
    wsum += 1.0;
    return acc / wsum;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 px = 2.0 / iResolution.xy;

    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float an = 0.15 + 0.08 * sin(iTime * 0.1);
    vec3 ta = vec3(0.0, 0.45, FOCUS_Z);
    vec3 ro = vec3(FOCUS_DIST * sin(an), 1.2, FOCUS_Z + FOCUS_DIST * cos(an));
    mat3 ca = setCamera(ro, ta);
    vec3 rd = ca * normalize(vec3(p, 1.8));
    vec3 hit = trace(ro, rd);

    vec3 sharp = shade(ro, rd, hit);
    float blurAmt = (hit.x > 0.0) ? coc(hit.y) : 0.01;

    vec3 blurred = dofSample(uv, px, blurAmt * 120.0);
    vec3 col = mix(sharp, blurred, smoothstep(0.002, 0.028, blurAmt));

    col = col / (col + vec3(0.9));
    col = pow(col, vec3(0.4545));
    col *= 0.62 + 0.38 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.28);

    fragColor = vec4(col, 1.0);
}
