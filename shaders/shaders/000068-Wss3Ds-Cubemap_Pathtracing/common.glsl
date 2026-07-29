// Common (common) — Cubemap Pathtracing by fizzer
// https://www.shadertoy.com/view/Wss3Ds

vec2 mats = vec2(.9, .5) * .99;

// Lambert BRDF sampling-function.
vec3 lambertNoTangent(in vec3 normal, in vec2 uv)
{
    float theta = 6.283185 * uv.x;
    uv.y = 2.0 * uv.y - 1.0;
    vec3 spherePoint = vec3(sqrt(1.0 - uv.y * uv.y) * vec2(cos(theta), sin(theta)), uv.y);
    return normalize(normal + spherePoint);
}

// Ray-box intersection.
vec2 box(vec3 ro,vec3 rd,vec3 p0,vec3 p1)
{
    vec3 t0 = (mix(p1, p0, step(0., rd * sign(p1 - p0))) - ro) / rd;
    vec3 t1 = (mix(p0, p1, step(0., rd * sign(p1 - p0))) - ro) / rd;
    return vec2(max(t0.x, max(t0.y, t0.z)),min(t1.x, min(t1.y, t1.z)));
}

// Box surface normal.
vec3 boxNormal(vec3 rp,vec3 p0,vec3 p1)
{
    rp = rp - (p0 + p1) / 2.;
    vec3 arp = abs(rp) / (p1 - p0);
    return step(arp.yzx, arp) * step(arp.zxy, arp) * sign(rp);
}

// Ray intersection test with scene. Returns surface ID, hit distance,
// surface normal, and local space texture coordinates.
vec2 traceScene(vec3 ro, vec3 rd, inout vec3 outn, inout vec3 uvw)
{
    vec3 p = vec3(-1),q = vec3(1);
    vec2 b = box(ro, rd, p, q);

    float mint = 1e4;
    float id = 0.;

    // First box test
    if(b.y > 0. && b.x < b.y && b.y < mint)
    {
        mint = b.y;
        id = 1.;
        uvw = ro + rd * mint;
        outn = -boxNormal(uvw, p, q);
        uvw = (uvw - p) / (q - p) * 2. - 1.;
    }
    else
        return vec2(mint, id);

    p = vec3(-.5, -.9, -.5), q = vec3(.5, -.5, .5);
    b = box(ro, rd, p, q);

    // Second box test
    if(b.x > 0. && b.x < b.y && b.x < mint)
    {
        mint = b.x;
        id = 2.;
        uvw = ro + rd * mint;
        outn = boxNormal(uvw, p, q);
        uvw = (uvw - p) / (q - p) * 2. - 1.;
    }

    float a = 3.9;
    mat2 m = mat2(cos(a), sin(a), -sin(a), cos(a));   

    ro.xz *= m;
    rd.xz *= m;

    ro.xy *= m;
    rd.xy *= m;

    ro.yz *= m;
    rd.yz *= m;

    p = vec3(-.26), q = vec3(.26);
    b = box(ro, rd, p, q);

    // Third box test
    if(b.x > 0. && b.x < b.y && b.x < mint)
    {
        mint = b.x;
        id = 3.;
        vec3 rp = ro + rd * mint;
        outn = (rp - (p + q) / 2.) / (q - p);
        outn = normalize(pow(abs(outn), vec3(32)) * sign(outn));      

        m = transpose(m);
        outn.yz *= m;
        outn.xy *= m;
        outn.xz *= m;
    }

    return vec2(mint, id);
}

// Ray intersection test with scene. Tests for any intersection.
// Doesn't test against first box, because it's inverted and encloses the whole scene.
bool traceSceneShadow(vec3 ro, vec3 rd)
{
    vec3 p = vec3(-.5, -.9, -.5), q = vec3(.5, -.5, .5);
    vec2 b = box(ro, rd, p,q);

    if(b.x > 0. && b.x < b.y)
    {
        return false;
    }

    float a = 3.9;
    mat2 m = mat2(cos(a), sin(a), -sin(a), cos(a));   

    ro.xz *= m;
    rd.xz *= m;

    ro.xy *= m;
    rd.xy *= m;

    ro.yz *= m;
    rd.yz *= m;

    p = vec3(-.26), q = vec3(.26);
    b = box(ro, rd, p, q);

    if(b.x > 0. && b.x < b.y)
    {
        return false;
    }

    return true;
}

