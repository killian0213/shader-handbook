// Image (image) — Voxel Terrain Minmax Traversal by gelami
// https://www.shadertoy.com/view/csscD4


// Voxel Terrain Minmax Traversal - gelami
// https://www.shadertoy.com/view/csscD4

/* 
 * Rendering voxel terrain using minmax mipmaps/quadtree displacement mapping
 * 
 * Mouse drag to look around
 * 
 * The heightmap and its mipmaps is each stored in a cubemap face,
 * which has a constant resolution of 1024x1024, unlike in my previous minmax shader
 * 
 * Grass is rendered as a special intersection on the top block 
 * 
 * Clouds are only 2D, with a fake shadow to give it some shape and depth
 * 
 * There is still more room to add to this, for example you could store
 * up to 4 heightmaps in 4 faces, and store its mipmaps in the remaining 2,
 * allowing you to make a 2048x2048 sized terrain, or use it to add more layers
 * 
 * Like in this shader from kastorp:
 * Heightmap with Layers - kastorp
 * https://www.shadertoy.com/view/7l23Rc
 * 
 * My previous minmax traversal shader:
 * Fast Minmax Terrain Traversal - gelami
 * https://www.shadertoy.com/view/msj3Dh
 * 
 * I changed my fake AO to use voxel AO instead, from:
 * Voxel Ambient Occlusion - fb39ca4
 * https://www.shadertoy.com/view/ldl3DS
 * 
 * Catmull-rom spline camera path based on: 
 * Fractal Flythrough - Shane
 * https://www.shadertoy.com/view/4s3SRN
 * 
 */

// Fork of "Gelami Raymarching Template" by gelami. https://shadertoy.com/view/mslGRs
// 2023-06-15 09:26:29

float map(vec3 p)
{
    const float sc = SCALE;
    float s = 1.0 / (float(getLodSize(MIN_LOD)) * sc);
    
    #if 1
    float h = luminance(sRGBToLinear(textureLod(iChannel2, p.xz * sc, 1.0).rgb)) * MAX_HEIGHT;
    
    return p.y - h;
    #else
    vec4 data = SampleCubemapLod(iChannel0, fract(p.xz * sc), vec2(1024), 0);
    
    float h = (data.r - (data.a + data.g) * s) * MAX_HEIGHT;
    
    return p.y - h;
    #endif
}

vec3 grad(vec3 p)
{
    vec2 e = vec2(0, 1.0 / 1024.0);
    
    return vec3(map(p - e.yxx) - map(p + e.yxx),
                e.y,
                map(p - e.xxy) - map(p + e.xxy)
            ) / (e.y * 2.0);
}

float getVoxel(vec3 id) {
    const float sc = SCALE;
    
    float s = 1.0 / (float(getLodSize(MIN_LOD)) * sc);
    
    vec3 p = (floor(id) + 0.5) * s;
	vec4 data = SampleCubemapLodNearest(iChannel0, fract(p.xz * sc), vec2(1024), 0);
    
    float h = data.r * MAX_HEIGHT;
    
    return float(p.y < h - (data.a == 1.0 ? s : 0.0));
}

// Voxel AO from:
// Voxel Ambient Occlusion - fb39ca4
// https://www.shadertoy.com/view/ldl3DS
float vertexAo(vec2 side, float corner) {
	//if (side.x == 1.0 && side.y == 1.0) return 1.0;
	return (side.x + side.y + max(corner, side.x * side.y)) / 3.0;
}

vec4 voxelAo(vec3 pos, vec3 d1, vec3 d2) {
	vec4 side = vec4(getVoxel(pos + d1), getVoxel(pos + d2), getVoxel(pos - d1), getVoxel(pos - d2));
	vec4 corner = vec4(getVoxel(pos + d1 + d2), getVoxel(pos - d1 + d2), getVoxel(pos - d1 - d2), getVoxel(pos + d1 - d2));
	vec4 ao;
	ao.x = vertexAo(side.xy, corner.x);
	ao.y = vertexAo(side.yz, corner.y);
	ao.z = vertexAo(side.zw, corner.z);
	ao.w = vertexAo(side.wx, corner.w);
	return 1.0 - ao;
}

vec2 asign(vec2 p)
{
    return vec2(
        p.x >= 0.0 ? 1.0 : -1.0,
        p.y >= 0.0 ? 1.0 : -1.0);
}

vec3 asign(vec3 p)
{
    return vec3(
        p.x >= 0.0 ? 1.0 : -1.0,
        p.y >= 0.0 ? 1.0 : -1.0,
        p.z >= 0.0 ? 1.0 : -1.0);
}

struct HitInfo
{
    float t;
    vec3 n;
    vec2 id;
    int i;
    int type;
};

bool intersectObject(vec3 ro, vec3 rd, vec2 id, float t, float h, float s, out HitInfo hit)
{
    vec3 sp = vec3(id.x, h - s * 0.5, id.y);
    
    float tP2 = -(ro.y - (h - s)) / rd.y;

    #if 0
    vec2 sph = sphereIntersection(ro - sp, rd, s * 0.5);

    if (sph.x < MAX_DIST)
    {
        hit.t = sph.x;
        hit.n = normalize(ro + rd * sph.x - sp);
        hit.id = id;
        hit.i = i;
        hit.type = 1;
        return true;
    }
    #else

    float ang = hash12(id*12.0) * TAU;

    vec3 gn0 = vec3(cos(ang), 0, sin(ang));
    vec3 gn1 = vec3(-gn0.z, 0, gn0.x);
    //const vec3 gn0 = vec3(sqrt(0.5), 0, sqrt(0.5));
    //const vec3 gn1 = vec3(-sqrt(0.5), 0, sqrt(0.5));
    
    float pa = dot(rd, gn0);
    float pb = -dot(ro - sp, gn0) / pa;

    vec3 pp = ro + rd * pb;

    vec2 puv = vec2(dot(pp - sp, gn1), pp.y - sp.y);

    pb = pb > 0.0 && abs(puv.x) < s * 0.5 && abs(puv.y) < s * 0.5 ? pb : MAX_DIST;

    float pa2 = dot(rd, gn1);
    float pb2 = -dot(ro - sp, gn1) / pa2;

    vec3 pp2 = ro + rd * pb2;

    vec2 puv2 = vec2(dot(pp2 - sp, gn0), pp2.y - sp.y);

    pb2 = pb2 > 0.0 && abs(puv2.x) < s * 0.5 && abs(puv2.y) < s * 0.5 ? pb2 : MAX_DIST;

    vec3 pn = gn0;
    if (pb2 < pb)
    {
        pb = pb2;
        puv = puv2;
        pn = gn1;
        pa = pa2;
    }

    if (pb < MAX_DIST)
    {
        hit.t = pb;
        hit.n = -pn * sign(pa);
        hit.id = id;
        //hit.i = i;
        hit.type = 1;
        return true;
    }

    #endif
    else if (rd.y < 0.0 && tP2 > 0.0 && tP2 < t)
    {
        hit.t = tP2;
        hit.n = vec3(0, 1, 0);
        hit.id = id;
        //hit.i = i;
        return true;
    }

    return false;
}


bool trace(vec3 ro, vec3 rd, out HitInfo hit, float tmin, float tmax)
{
    if ((rd.y > 0.0 && ro.y > MAX_HEIGHT) ||
        (rd.y < 0.0 && ro.y < 0.0) || iFrame < MAX_LOD)
        return false;
    
    hit.t = MAX_DIST;
    hit.type = 0;
    
    ro = ro + rd * tmin;
    vec3 pos = ro;
    
    vec3 ird = 1.0 / rd;
    vec3 srd = asign(ird);
    vec3 ard = abs(ird);
    vec3 iro = pos * ird;
    
    const int minlod = MIN_LOD;
    const float sc = SCALE;
    
    int lod = MAX_LOD;
    float s = 1.0 / (float(getLodSize(lod)) * sc);
    vec2 id = (floor(pos.xz / s) + 0.5) * s;
    vec2 pid = id;
    
    float t = 0.0;
    vec2 nrd = vec2(0);
    int i = min(0, iFrame);
    for (; i < STEPS; i++)
    {
        vec4 data = SampleCubemapLodNearest(iChannel0, fract(id * sc), vec2(1024), lod);
        
        float h = data.r * MAX_HEIGHT;
        
        vec2 p = id;
        vec2 n = iro.xz - p * ird.xz;
        vec2 k = ard.xz * s * 0.5;
        
        vec2 t0 = -n - k;
        vec2 t1 = -n + k;
        
        float tF = min(t1.x, t1.y);
        
        if (pos.y < h)
        {
            if (lod == minlod)
            {
                if (lod == 0 && data.a == 1.0 && h - pos.y < s * MAX_HEIGHT)
                {
                    if (intersectObject(ro, rd, id, tF, h, s, hit))
                    {
                        hit.i = i;
                        return true;
                    }
                    
                } else
                {
                    hit.t = t;
                    hit.n = vec3(-nrd, 0).xzy;
                    hit.id = id;
                    hit.i = i;
                    return true;
                }
            } else
            {
                s *= 0.5;
                lod--;
                id += asign(pos.xz - id) * s * 0.5;
                continue;
            }
        }
        
        float tP = -(ro.y - h) * ird.y;
        
        pos = ro + rd * tF;
        
        if (pos.y < h)
        {
            if (lod == minlod)
            {
                if (lod == 0 && data.a == 1.0)
                {
                    if (intersectObject(ro, rd, id, tF, h, s, hit))
                    {
                        hit.i = i;
                        return true;
                    }
                } else
                {
                    hit.t = tP;
                    hit.n = vec3(0, 1, 0);
                    hit.id = id;
                    hit.i = i;
                    return true;
                }
            } else
            {
                pos = ro + rd * (-(ro.y - h) * ird.y - EPS);
                s *= 0.5;
                lod--;
                id += asign(pos.xz - id) * s * 0.5;
                continue;
            }
        }
        
        if (tF + tmin > tmax ||
           (rd.y > 0.0 && pos.y > MAX_HEIGHT) ||
           (rd.y < 0.0 && pos.y < 0.0))
            return false;
        
        t = tF;
        nrd = t1.x <= t1.y ? vec2(srd.x, 0) : vec2(0, srd.z);
        pid = id;
        id += nrd * s;
        
        vec2 iid = id / s;
        vec2 ipid = pid / s;
        if (floor(iid*0.5) != floor(ipid*0.5) && lod < MAX_LOD)
        {
            s *= 2.0;
            id = (floor(iid*0.5) + 0.5) * s;
            pid = id;
            lod++;
        }
    }
    
    return false;
}

vec3 shade()
{
    vec3 col = vec3(0);

    return col;
}

float noise(vec3 x)
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
    
    vec2 uv = (p.xy+vec2(37.0,239.0)*p.z) + f.xy;
    vec2 rg = textureLod(iChannel3,(uv+0.5)/256.0,0.0).yx;
	return mix( rg.x, rg.y, f.z );
}

const mat2 rot = mat2(0.866, 0.5, -0.5, 0.866) * 2.0;

float getClouds(vec2 p, const float a, const float b)
{
    #if 0
    float d = texture(iChannel3, p).r*0.5; p *= rot;
    d += texture(iChannel3, p).r*0.25*0.9; p *= rot;
    d += texture(iChannel3, p).r*0.125*0.7; p *= rot;
    d += texture(iChannel3, p).r*0.0625*0.5; p *= rot;
    #else
    vec3 q = vec3(p * 256.0, iTime*0.05);
    float d = noise(q)*0.5; q.xy *= rot;
    d += noise(q)*0.25*0.9; q.xy *= rot;
    d += noise(q)*0.125*0.7; q.xy *= rot;
    d += noise(q)*0.0625*0.5; q.xy *= rot;
    #endif
    d = smoothstep(a, b, d);
    
    return d;
}


#define CAM_PATH_LENGTH 30

const vec3[CAM_PATH_LENGTH] CAM_PATH = vec3[](
    vec3(0.08/SCALE, 0.28, 0.52/SCALE),
    vec3(0.105/SCALE, 0.15, 0.58/SCALE),
    vec3(0.1/SCALE, 0.2, 0.64/SCALE),
    vec3(0.1/SCALE, 0.25, 0.7/SCALE),
    vec3(0.16/SCALE, 0.15, 0.73/SCALE),
    vec3(0.21/SCALE, 0.1, 0.71/SCALE),
    vec3(0.25/SCALE, 0.15, 0.67/SCALE),
    vec3(0.31/SCALE, 0.2, 0.64/SCALE),
    vec3(0.35/SCALE, 0.28, 0.61/SCALE),
    vec3(0.39/SCALE, 0.3, 0.58/SCALE),
    vec3(0.40/SCALE, 0.25, 0.54/SCALE),
    vec3(0.42/SCALE, 0.28, 0.5/SCALE),
    vec3(0.46/SCALE, 0.26, 0.47/SCALE),
    vec3(0.5/SCALE, 0.2, 0.45/SCALE),
    vec3(0.54/SCALE, 0.15, 0.43/SCALE),
    vec3(0.59/SCALE, 0.25, 0.39/SCALE),
    vec3(0.605/SCALE, 0.32, 0.34/SCALE),
    vec3(0.58/SCALE, 0.30, 0.31/SCALE),
    vec3(0.53/SCALE, 0.38, 0.29/SCALE),
    vec3(0.49/SCALE, 0.42, 0.3/SCALE),
    vec3(0.44/SCALE, 0.45, 0.31/SCALE),
    vec3(0.39/SCALE, 0.48, 0.28/SCALE),
    vec3(0.35/SCALE, 0.52, 0.25/SCALE),
    vec3(0.29/SCALE, 0.58, 0.23/SCALE),
    vec3(0.21/SCALE, 0.5, 0.28/SCALE),
    vec3(0.18/SCALE, 0.3, 0.30/SCALE),
    vec3(0.14/SCALE, 0.2, 0.32/SCALE),
    vec3(0.11/SCALE, 0.12, 0.36/SCALE),
    vec3(0.08/SCALE, 0.22, 0.4/SCALE),
    vec3(0.07/SCALE, 0.28, 0.46/SCALE)
);

vec3 CatmullRomSpline(vec3 p0, vec3 p1, vec3 p2, vec3 p3, float t)
{
    return p1 + 0.5 * t * (-p0 + p2 + t * (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3 + t * (-p0 + 3.0 * p1- 3.0 * p2 + p3)));
}

vec3 getCamPath(float t)
{
    t = mod(t, float(CAM_PATH_LENGTH));
    
    int i = int(floor(t));
    float f = fract(t);
        
    int i0 = (i - 1 + CAM_PATH_LENGTH) % CAM_PATH_LENGTH;
    int i2 = (i + 1) % CAM_PATH_LENGTH;
    int i3 = (i + 2) % CAM_PATH_LENGTH;
    
    return CatmullRomSpline(CAM_PATH[i0], CAM_PATH[i], CAM_PATH[i2], CAM_PATH[i3], f);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 tot = vec3(0);
    
    #if SSAA > 0
    for (int x = 0; x <= SSAA; x++)
    {
        for (int y = 0; y <= SSAA; y++)
        {
    vec2 o = (vec2(x, y) + 0.5) / float(SSAA+1);
    vec2 pv = (2. * (fragCoord + o) - iResolution.xy) / iResolution.y;
    
    #else
    vec2 pv = (2. * (fragCoord) - iResolution.xy) / iResolution.y;
    #endif
    
    vec2 uv = fragCoord / iResolution.xy;
    vec2 m = iMouse.xy / iResolution.xy;
    
    float ax, ay;
    
    #ifdef TURNTABLE_CAM
    vec3 ro = vec3(0, 0, 0.6);
    vec3 lo = vec3(1.6, 0.1, 2.3);
    
    #ifdef STATIC_CAM
    ax = -0.15 * TAU + PI;
    ay = -0.46 * TAU + PI;
    #else
    if (iMouse.z > 0.0)
    {
        ax = -m.x * TAU + PI;
        ay = -m.y * PI + PI * 0.5;
    } else
    {
        ax = -PI * .7 + iTime * .15;
        ay = PI * 0.15;
    }
    #endif
    
    ro.yz *= rot2D(ay);
    ro.xz *= rot2D(ax);
    ro += lo;
    
    #else
    float ct = iTime * 0.4;
    vec3 ro = getCamPath(ct);
    vec3 lo = getCamPath(ct + 0.2);
    if (iMouse.z > 0.0)
    {
        lo = vec3(0, 0, 1);
        ax = -m.x * TAU + PI;
        ay = -m.y * PI + PI * 0.5;
        
        lo.yz *= rot2D(-ay);
        lo.xz *= rot2D(ax);
        lo += ro; 
    }
    #endif
    
    mat3 cmat = getCameraMatrix(ro, lo);

    const float invTanFov = 1.25;
    vec3 rd = normalize(cmat * vec3(pv, invTanFov));
    
    vec3 col = vec3(0);
    
    float pt = 0.0;
    if (rd.y < 0.0 && ro.y > MAX_HEIGHT)
    {
        pt = -(ro.y - MAX_HEIGHT) / rd.y - EPS;
    }
    
    HitInfo hit;
    bool isHit = trace(ro, rd, hit, pt, MAX_DIST);
    
    float t = hit.t + pt;
    
    vec3 pos = ro + rd * t;
    
    const float sc = SCALE;
    float s = 1.0 / (float(getLodSize(MIN_LOD)) * sc);
    
    vec3 p = (pos - hit.n * EPS) / s;
    vec3 vid = floor(p);
    
    vec3 id = vec3(hit.id, 0).xzy;
    id.y = floor((pos.y + rd.y * EPS) / MAX_HEIGHT * 1024.0 * SCALE) / (1024.0 * SCALE);
    
    vec3 alb = vec3(texture(iChannel0, cubeUVToPos(fract(hit.id * SCALE), 0)).rgb);
    
    float k = texture(iChannel1, id.xz * 0.02).r;
    k = smoothstep(0.05, 0.2, k * k);
    
    alb = mix(vec3(0.95,0.4,0.25)*0.4, vec3(0.95, 0.4, 0.3), 1.0 - k);
    //alb *= hash12(hit.id*3232.0)*0.2+0.8;
    
    vec3 gn = normalize(grad(id));
    
    float ky = id.y + (textureLod(iChannel3, id.xz * 0.0006, 0.0).r - 0.5) * 0.002;
    float k1 = smoothstep(0.0,0.5,hash11(ky * 4.3+1.0));
    float k2 = smoothstep(0.2,0.15,hash11(ky * 8.0+1.0));
    alb *= k1 * vec3(0.7, 0.6, 0.5) + 0.35;
    
    alb = mix(alb, vec3(1, 0.7, 0.6), k2 * 0.8);
    
    vec3 tcol = (0.4+0.6*texture(iChannel1, id.xz * 0.4).rgb) * vec3(0.9, 0.55, 0.2);
    float tk = smoothstep(0.6, 0.9, gn.y);
    alb = mix(alb, alb * vec3(1, 0.6, 0.3), tk);
    tk *= smoothstep(0.2, 0.0, id.y);
    tk *= smoothstep(0.1, 0.2, texture(iChannel1, -id.xz * 0.02).r);
    alb = mix(alb, tcol, tk);
    
    alb *= 1.0-texture(iChannel1, -id.xz * 0.3).rgb * 0.8;
    
    col = alb;
    
    vec4 data = SampleCubemapLodNearest(iChannel0, fract(hit.id * sc), vec2(1024), 0);
    
    if (data.a > 1.0 && (vid.y + 1.0) * s > (data.r - data.a * s) * MAX_HEIGHT)
    {
        col = (col*0.6+0.4)*vec3(0.4, 0.5, 0.15) + col * 0.1;
        col *= hash13(vid) * 0.3 + 0.7;
    }
    
    vec3 ldir = normalize(vec3(1, 1.2, 0.8));
    vec3 lcol = vec3(1, 0.8, 0.6) * 2.5;
    vec3 skyCol = vec3(0.6, 0.85, 1) + smoothstep(0.2, 0.0, abs(rd.y)) * vec3(0.35,0.4,0.5);
    vec3 skyCol2 = vec3(0.35,0.62,0.9);
    
    HitInfo hitL;
    bool isHitL = trace(pos + hit.n * 1e-6, ldir, hitL, 0.0, MAX_DIST);
    
    float sha = float(!isHitL);
    
    if (hitL.type == 1)
        sha = sha * 0.8 + 0.2;
    
    float dif = max(dot(hit.n, ldir), 0.0) * sha;
    float hao = smoothstep(0.0, MAX_HEIGHT * 0.3, pos.y);
    
    if (hit.type == 1)
    {
        col = mix(col, (col*0.6+0.4)*vec3(0.8, 0.9, 0.2), 0.3);
        //dif += 0.2 * max(-dot(hit.n, ldir), 0.0) * sha;
        dif = (max(dot(hit.n, ldir), 0.0) + 0.6*max(-dot(hit.n, ldir), 0.0)) * (sha * 0.4+0.6);
    }
    
    col *= lcol * (dif * 0.7 + 0.3);
    
    float ao = 1.0;
    if (hit.type == 0)
    {
        vec3 mask = abs(hit.n);
        vec2 vuv = mod(vec2(dot(mask * p.yzx, vec3(1.0)), dot(mask * p.zxy, vec3(1.0))), vec2(1.0));

        vec4 vao = voxelAo(vid + hit.n, mask.zxy, mask.yzx);
        ao = mix(mix(vao.z, vao.w, vuv.x), mix(vao.y, vao.x, vuv.x), vuv.y);

        col *= dot(abs(hit.n), vec3(0.9, 1, 0.95));
    
        col *= ao * 0.6 + 0.4;
    }
    
    col += skyCol * 0.1;
    
    if (hit.type == 1)
    {
        //col += alb * lcol * (dot(hit.n, ldir)*0.5+0.5) * 0.2;
    }
    
    col *= hao * 0.4 + 0.6;
    
    float cost = dot(rd, ldir);
    //float fog = 1.0 - exp(-t*t * 0.001);
    float fog = 1.0 - exp(-t * 0.04);
    float hg = mix(henyeyGreenstein(cost, 0.65), henyeyGreenstein(cost, -0.3), 0.45);
    
    vec3 fogCol = skyCol * hg;
    col = mix(col, fogCol, fog);
    
    vec3 ref = reflect(rd, hit.n);
    
    HitInfo hitR;
    bool isHitR = trace(pos + hit.n * EPS, ref, hitR, 0.0, MAX_DIST);
    
    #ifdef SHOW_NORMALS
    col = hit.n;
    #endif
    
    if (!isHit)
    {
        col = mix(skyCol, skyCol2, smoothstep(0.0, 0.4, rd.y));
        
        #define SUN_ANGLE_DEGREES 0.52
        const float sunAngle = SUN_ANGLE_DEGREES * PI / 180.0;
        const float sunCost = cos(sunAngle);

        float cost = max(dot(rd, ldir), 0.0);
        float dist = cost - sunCost;

        float bloom = max(1.0 / (0.02 - min(dist, 0.0)*400.0), 0.0) * 0.08;

        vec3 sun = 20.0 * lcol * (smoothstep(0.0, 0.0001, dist) + bloom);
        
        col += sun;
        
        vec2 clsph = sphereIntersection(vec3(0, 0.46, 0), rd, 0.5);
        
        vec3 clpos = rd * clsph.y;
        vec2 cluv = (clpos.xz + iTime * 0.0015) * 0.3;
        cluv += (texture(iChannel3, cluv * 10.0 + iTime * 0.003).rg - 0.5) * 0.0004;
        float cld = getClouds(cluv, 0.35, 0.6);
        float clsh = getClouds(cluv + (ldir.xz - rd.xz) * 0.0008, 0.35, 0.65);
        
        vec3 ccol = (max(cld - clsh, 0.0) * lcol * 0.6 + skyCol * 0.5 + 0.35) * hg ;
        
        col = mix(col, ccol, (1.0 - exp(-cld)) * smoothstep(0.0, 0.02, rd.y));
        
        vec3 fp = (rd - ldir) * cmat;
        vec3 cldir = ldir * cmat;
        vec2 cuv = cldir.xy / cldir.z * invTanFov;
        vec2 fuv = pv - cuv;
        float fd = length(fuv * vec2(30, 1));
        fd = min(fd, length(rot2D(PI/3.0) * fuv * vec2(30, 1)));
        fd = min(fd, length(rot2D(-PI/3.0) * fuv * vec2(30, 1)));
        
        vec3 flare = 0.2 * lcol * smoothstep(1.0, 0.0, fd);//max(1.0 / max(fd, 0.00), 0.0) * 0.05;
        
        col += flare;
    }
    
    #ifdef SHOW_STEPS
    col = turbo(float(hit.i) / float(STEPS));
    
    if (fragCoord.y < 10.0)
        col = turbo(uv.x);
    #endif
    
    //vec2 luv = fragCoord / iResolution.y;
    //int lod = (iFrame/20)%(1+MAX_LOD);
    //col = luv.x > 1.0 ? vec3(0) : vec3(SampleCubemapLodNearest(iChannel0, luv, vec2(1024), lod).r);
    
    //col = texture(iChannel0, cubeUVToPos(fragCoord / iResolution.y, 1)).rgb;
    
    col = max(col, vec3(0));
    
    #if SSAA > 0
        tot += col;
        }
    }
    tot /= float((SSAA+1)*(SSAA+1));
    #else
    tot = col;
    #endif
    
    //tot = tot / (1.0 + tot);
    //tot = ReinhardExtLuma(tot, 5.0);
    tot = ACESFilm(tot * 0.35);
    
    fragColor = vec4(linearTosRGB(tot), 1);
    fragColor += (dot(hash23(vec3(fragCoord, iTime)), vec2(1)) - 0.5) / 255.;
}