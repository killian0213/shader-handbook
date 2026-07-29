// Image (image) — Octree Traversal using SDF by gelami
// https://www.shadertoy.com/view/DlGGDd


// Octree Traversal using SDF - gelami
// https://www.shadertoy.com/view/DlGGDd

/* 
 * Implicit octree traversal using SDFs to define occupancy of a given cell
 * 
 * The basic idea is to query the SDF at the cell center,
 * and check if the distance is less than the cell size, if so the cell is occupied
 * 
 * Mouse drag to look around
 * Defines in Common
 *
 * Probably my slowest shader yet, runs at 30-40 fps/25-33 ms on my GTX 1650 T_T
 * I really wanted to show the big open spaces of the terrain,
 *   but I guess this isn't really the method for that
 * 
 * Though another method which might work better is a hybrid SDF/voxel traversal
 * Using sphere tracing for the initial traversal, then switching to voxel traversal
 * when the distance is less than the voxel size, as done in this shader by nimitz:
 * 
 * Moon voxels - nimitz
 * https://www.shadertoy.com/view/tdlSR8
 * 
 * Another shader that uses an SDF for the octree,
 * but uses a stack-based traversal instead:
 * Voxel Mandelbulb - thorn0906
 * https://www.shadertoy.com/view/3d2XRd
 * 
 * This shader introduced me into octree traversal back then
 * Also used their exit condition as I couldn't figure it out v _ v
 * random octree - abje
 * https://www.shadertoy.com/view/4sVfWw
 * 
 */

// Fork of "Gelami Raymarching Template" by gelami. https://shadertoy.com/view/mslGRs
// 2023-05-23 12:49:41

vec3 getCameraPos(float t)
{
    return vec3(
        (cos(t * 0.35 * CAMERA_SPEED) + sin(t * 0.25 * CAMERA_SPEED) * 0.5) * 0.55,
        (sin(t * 0.25 * CAMERA_SPEED) + cos(t * 0.2 * CAMERA_SPEED) * 0.4) * 0.35,
        t * CAMERA_SPEED);
}

float map(vec3 p, float s)
{
    float d = MAX_DIST;
    
    float sc = 0.3;
    
    vec3 q = sc * p / iChannelResolution[1].xyz;
    q -= vec3(0.003, -0.006, 0.0);
    
    d  = texture(iChannel1, q*1.0).r*0.5;
    d += texture(iChannel1, q*2.0).r*0.25;
    d += texture(iChannel1, q*4.0).r*0.125;
    
    d = (d/0.875 - SURFACE_FACTOR) / sc;
    
    #ifdef TOP_PLANE
    d = smax(d, p.y - MAX_HEIGHT, 0.3);
    #endif
    
    float c = 0.75 - length(p.xy - getCameraPos(p.z / CAMERA_SPEED).xy);
    
    d = smax(d, c, 0.75);
    
    //d = min(d, sdBox(p - vec3(1,0,-3), vec3(0.5, 0.2, 0.1)));
    //d = min(d, length(p - vec3(-2, 0, -4)) - 1.0);
    
    return d;
}

vec3 grad(vec3 p)
{
    const float s = exp2(-MAX_LOD);
    const vec2 e = vec2(0, s);
    return (map(p, s) - vec3(
        map(p - e.yxx, s),
        map(p - e.xyx, s),
        map(p - e.xxy, s))) / e.y;
}

struct HitInfo
{
    float t;
    vec3 n;
    vec3 id;
    float lod;
    int i;
};

bool trace(vec3 ro, vec3 rd, out HitInfo hit, const float tmax)
{
    hit.t = tmax;
    hit.n = vec3(0);
    hit.i = STEPS;
    
    vec3 ird = 1.0 / rd;
    vec3 srd = sign(ird);
    vec3 ard = abs(ird);
    
    vec3 iro = ro * ird;
    
    vec3 id = floor(ro);
    vec3 pid = id;

    float s = 1.0;
    float lod = MAX_LOD;
    vec3 pos = ro;
    
    vec3 nrd = vec3(0);
    float t = 0.0;
    float minlod = 0.0;
    
    bool exit = false;
    for (int i = 0; i < STEPS; i++)
    {   
        if (exit)
        {
            id = floor(id*0.5);
            pid = id;
            s *= 2.0;
            lod++;
            
            // Thank u abje for the exit condition
            // random octree - abje
            // https://www.shadertoy.com/view/4sVfWw
            exit = abs(dot(mod(id+0.5,2.0)-1.0 + nrd*0.5, abs(nrd))) == 0.0 && lod < MAX_LOD;
            
            i--;
            continue;
        }
        
        vec3 p = (id + 0.5) * s;
        
        float d = map(p, s);
        
        vec3 n = iro - p * ird;
        vec3 k = ard * s * 0.5;
        
        vec3 t2 = -n + k;
        
        float nt = min(min(t2.x, t2.y), t2.z);
        
        vec3 npos = ro + rd * nt;
        
        if (d * 2.0 < s)
        {
            if (lod > minlod)
            {
                id *= 2.0;
                id += step(vec3(0), pos - p);
                pid = id;
                
                s *= 0.5;
                lod--;
                continue;
            } else
            {
                hit.t = t;
                #ifndef ROUNDED_NORMALS
                hit.n = -nrd;
                #else
                float r = s * 0.05;
                hit.n = sign(pos - p) * normalize(max(abs(pos - p) - vec3((s - r) * 0.5), 0.0));
                //hit.n *= t2.x <= t2.y && t2.x <= t2.z ? vec3(1, srd.x, srd.x) :
                //         t2.y <= t2.z ? vec3(srd.y) : vec3(srd.z);
                #endif
                hit.id = id;
                hit.lod = lod;
                hit.i = i;
                return true;
            }
        }
        
        if (nt >= tmax)
            return false;
        
        #ifdef TOP_PLANE
        if (rd.y > 0.0 && ro.y + rd.y * nt > MAX_HEIGHT)
            return false;
        #endif
        
        // Change min LOD with distance, doesn't reduce perf much
        #ifdef DYNAMIC_LOD
        minlod = clamp(floor(log2(nt * 0.12)), 0.0, MAX_LOD);
        #endif
        
        // Step check with tie break when two components are equal
        #if 0
        t2 += vec3(0, EPS, EPS+EPS);
        nrd = srd * step(t2, t2.yzx) * step(t2, t2.zxy);
        #else
        nrd = t2.x <= t2.y && t2.x <= t2.z ? vec3(srd.x,0,0) :
              t2.y <= t2.z ? vec3(0,srd.y,0) : vec3(0,0,srd.z);
        #endif
        
        pos = npos;
        t = nt;
        
        pid = id;
        id += nrd;
        
        #if 1
        if (floor(pid*0.5) != floor(id*0.5) && lod < MAX_LOD)
            exit = true;
        #endif
        
    }

    return false;
}

vec3 triplanar(sampler2D tex, vec3 p, vec3 n, const float k)
{
    n = pow(abs(n), vec3(k));
    n /= dot(n, vec3(1));

    vec3 col = texture(tex, p.yz).rgb * n.x;
    col += texture(tex, p.xz).rgb * n.y;
    col += texture(tex, p.xy).rgb * n.z;
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pv = (2. * (fragCoord) - iResolution.xy) / iResolution.y;
    vec2 uv = fragCoord / iResolution.xy;
    
    const float fov = 67.5;
    const float invTanFov = 1.0 / tan(radians(fov) * 0.5);//1.5;
    
    #ifdef MOTION_BLUR
    float mb = MOTION_BLUR * dot(pv, pv) / invTanFov * hash13(vec3(fragCoord, iFrame));
    vec3 ro = getCameraPos(iTime + mb);
    #else
    vec3 ro = getCameraPos(iTime);
    #endif
    vec3 lo = vec3(0,0,-1);
    
    vec2 m = iMouse.xy / iResolution.xy;
    
    float ax = -m.x * TAU + PI;
    float ay = -m.y * PI + PI * 0.5;
    
    if (iMouse.z > 0.0)
    {
        lo.yz *= rot2D(ay);
        lo.xz *= rot2D(ax);
        lo += ro;
    } else
    {
        #ifdef MOTION_BLUR
        lo = getCameraPos(iTime + mb + 0.12);
        #else
        lo = getCameraPos(iTime + 0.12);
        #endif
    }
    
    mat3 cmat = getCameraMatrix(ro, lo);

    vec3 rd = normalize(cmat * vec3(pv, invTanFov));
    
    vec3 col = vec3(0);
    
    HitInfo hit;
    bool isHit = trace(ro, rd, hit, MAX_DIST);
    
    vec3 pos = ro + rd * hit.t;
    vec3 pid = hit.id * exp2(-(MAX_LOD - hit.lod));
    
    vec3 n = hit.n;
    vec3 g = grad(pos);
    vec3 nv = normalize(grad(pid));
    float d = map(pos, exp2(-MAX_LOD)) / length(g);
    
    vec3 ref = reflect(rd, hit.n);
    
    vec3 uvw = 2.0 * (pos - pid) / exp2(-(MAX_LOD - hit.lod));
    vec2 buv = abs(hit.n.x) * uvw.yz + abs(hit.n.y) * uvw.xz + abs(hit.n.z) * uvw.xy;
    buv /= dot(abs(hit.n), vec3(1));
    
    vec3 id = 0.11*hit.id * exp2(-hit.lod);
    float k = fract(sin(id.x *0.33)*0.6 + cos(id.y*0.25) * sin(id.z*0.3) - sin(id.z*0.2));
    
    vec3 alb = triplanar(iChannel2, 0.15*pid, nv, 4.0);
    
    float k2 = sin(id.z *0.09)*0.6 + cos(id.x*0.12) * sin(id.y*0.15) - sin(id.y*0.1);
    k2 = abs(fract(k2) * 2.0 - 1.0);
    k2 = 1.0-smoothstep(0.4, 0.8, k2);
    //k2 = smoothstep(0.0, 1.0, abs(pid.y + 1.0));
    
    alb = mix(alb*0.9+0.1, (1.0-alb) * vec3(1, 0.85, 0.75), k2);
    
    float tk = triplanar(iChannel3, 0.1*pid, nv, 4.0).r;
    alb = mix(alb, alb*palette2(k), (1.0-smoothstep(0.05, 0.5, tk)) * 0.8);
    
    col = alb;
    col *= dot(abs(hit.n), vec3(0.8, 1, 0.9));
    
    #ifdef VOXEL_NORMALS
    n = nv;
    #endif
    
    const vec3 lcol = vec3(1, 0.95, 0.9) * 1.8;
    const vec3 ldir = normalize(vec3(0.85, 1.2, 1));
    
    HitInfo hitL;
    bool isHitL = trace(pos + hit.n * EPS, ldir, hitL, 5.0);
    
    float dif = max(dot(n, ldir), 0.0) * float(!isHitL);
    float ao = smoothstep(-0.06, 0.12, d);
    
    col *= (dif * 0.6 + 0.4) * lcol;
    
    float spot = smoothstep(0.78, 0.96, dot(rd, cmat[2])) * max(dot(-rd, hit.n), 0.0);
    spot *= 0.8 / (hit.t*hit.t);
    
    col += alb * spot * vec3(1, 0.8, 0.6);
    
    const float r0 = 0.08;
    float fre = r0 + (1.0 - r0) * pow(1.0 - dot(-rd, hit.n), 5.0);
    
    vec3 refcol = 0.6*sRGBToLinear(texture(iChannel0, ref).rgb) / vec3(1, 0.65, 0.4);
    
    col = mix(col, refcol, fre * 0.5 * (k2*0.8+0.2));
    
    col *= ao * 0.7 + 0.3;
    
    vec3 fogCol = vec3(0.4, 0.65, 1) * 0.12;
    
    #ifdef FOG
    
    #if 1
    float fog = 1.0 - exp(-hit.t*hit.t * 0.003);
    #else
    const float a = 0.032;
    const float b = 0.005;
    float fog = (a / b) * exp(-max(ro.y + 35.0, 0.0) * b) * (1.0 - exp(-hit.t * rd.y * b)) / rd.y;
    #endif
    
    col = mix(col, fogCol, saturate(fog));
    #endif
    
    if (!isHit)
        col = fogCol;
    
    #ifdef SHOW_STEPS
    #if 0
    col = vec3(float(hit.i) / float(STEPS));
    if (fragCoord.y < 10.0)
        col = vec3(uv.x);
    #else
    col = palette(float(hit.i) / float(STEPS));
    
    if (fragCoord.y < 10.0)
        col = palette(uv.x);
    #endif
    #endif
    
    col = max(col, vec3(0));
    
    col = ACESFilm(col * 0.35);
    
    fragColor = vec4(linearTosRGB(col), 1);
    fragColor += (dot(hash23(vec3(fragCoord, iTime)), vec2(1)) - 0.5) / 255.;
}
