// Image (image) — Hybrid SDF-Voxel Traversal by gelami
// https://www.shadertoy.com/view/dtVSzw


// Hybrid SDF-Voxel Traversal - gelami
// https://www.shadertoy.com/view/dtVSzw

/* 
 * Voxel traversal using a hybrid SDF-voxel method
 * 
 * Traversal is done by doing raymarching/sphere tracing initially, switching
 * to voxel traversal when the distance is less than the bounding radius of the voxel
 * 
 * Mouse drag to look around
 * Defines in Common
 * 
 * This was much faster than octree traversal which I've done before
 * Around similar speeds with sphere tracing more or less depending on voxel size
 * 
 * Other hybrid SDF-voxel traversal shaders:
 * 
 * Twisted Eye (Voxelmarched) - Elyxian
 * https://www.shadertoy.com/view/ts23zy
 * 
 * Moon voxels - nimitz
 * https://www.shadertoy.com/view/tdlSR8
 * 
 */

// Fork of "Gelami Raymarching Template" by gelami. https://shadertoy.com/view/mslGRs
// 2023-05-31 08:11:32

vec3 getCameraPos(float t)
{
    t += CAMERA_TIME_OFFSET;
    return vec3(
        (cos(t * 0.35 * CAMERA_SPEED) + sin(t * 0.25 * CAMERA_SPEED) * 0.5) * 0.55,
        (sin(t * 0.25 * CAMERA_SPEED) + cos(t * 0.2 * CAMERA_SPEED) * 0.4) * 0.35,
        t * CAMERA_SPEED);
}

float map(vec3 p)
{
    float d = MAX_DIST;
    
    float sc = 0.3;
    
    vec3 q = sc * p / iChannelResolution[1].xyz;
    q -= vec3(0.003, -0.006, 0.0);
    
    d  = texture(iChannel1, q*1.0).r*0.5;
    d += texture(iChannel1, q*2.0 + 0.3).r*0.25;
    d += texture(iChannel1, q*4.0 + 0.7).r*0.125;
    
    float tp = smoothstep(50.0, -6.0, p.y);
    tp = tp*tp;
    
    d = (d/0.875 - SURFACE_FACTOR) / sc;
    
    d = smax(d, p.y - MAX_HEIGHT, 0.6);
    
    float c = TUNNEL_RADIUS - length(p.xy - getCameraPos(p.z / CAMERA_SPEED - CAMERA_TIME_OFFSET).xy);
    
    d = smax(d, c, 0.75);
    
    return d;
}

vec3 grad(vec3 p)
{
    const vec2 e = vec2(0, 0.1);
    return (map(p) - vec3(
        map(p - e.yxx),
        map(p - e.xyx),
        map(p - e.xxy))) / e.y;
}

struct HitInfo
{
    float t;
    vec3 n;
    vec3 id;
    int i;
};

vec3 getVoxelPos(vec3 p, float s)
{
    return (floor(p / s) + 0.5) * s;
}

bool trace(vec3 ro, vec3 rd, out HitInfo hit, const float tmax)
{
    const float s = VOXEL_SIZE;
    const float sd = s * sqrt(3.0);
    
    vec3 ird = 1.0 / rd;
    vec3 iro = ro * ird;
    vec3 srd = sign(ird);
    vec3 ard = abs(ird);
    
    float t = 0.0;
    
    #ifdef SDF_TRAVERSAL
    for (int i = 0; i < STEPS; i++)
    {
        vec3 pos = ro + rd * t;
        float d = map(pos);
        
        if (d < EPS)
        {
            hit.t = t;
            hit.id = pos;
            hit.n = normalize(grad(pos));
            hit.i = i;
            return true;
        }
        
        t += d;
        
        if (t >= tmax || (rd.y > 0.0 && pos.y > MAX_HEIGHT))
            return false;
    }
    #else
    
    vec3 vpos = getVoxelPos(ro, s);
    
    bool voxel = false;
    int vi = 0;
    vec3 prd = vec3(0);
    for (int i = 0; i < STEPS; i++)
    {
        vec3 pos = ro + rd * t;

        float d = map(voxel ? vpos : pos);
        
        if (!voxel)
        {
            t += d;
            
            if (d < sd)
            {
                vpos = getVoxelPos(ro + rd * max(t - sd, 0.0), s);
                voxel = true;
                vi = 0;
            }
            
        } else
        {
            vec3 n = (ro - vpos) * ird;
            vec3 k = ard * s * 0.5;

            vec3 t1 = -n - k;
            vec3 t2 = -n + k;

            float tF = min(min(t2.x, t2.y), t2.z);
            //float tN = max(max(t1.x, t1.y), t1.z);
            
            #if 0
            vec3 nrd = srd * step(t2, t2.yzx) * step(t2, t2.zxy);
            #else
            vec3 nrd = t2.x <= t2.y && t2.x <= t2.z ? vec3(srd.x,0,0) :
                       t2.y <= t2.z ? vec3(0,srd.y,0) : vec3(0,0,srd.z);
            #endif
            
            if (d < 0.0)
            {
                hit.t = t;
                hit.id = vpos;
                hit.n = -prd;
                hit.i = i;
                return true;
            } else if (d > sd && vi > 2)
            {
                voxel = false;
                t = tF + sd;
                continue;
            }
            
            vpos += nrd * s;
            prd = nrd;
            t = tF;
            vi++;
        }
        
        if (t >= tmax || (rd.y > 0.0 && pos.y > MAX_HEIGHT))
            return false;
    }
    #endif

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

vec3 triplanarLod(sampler2D tex, vec3 p, vec3 n, const float k, float lod)
{
    n = pow(abs(n), vec3(k));
    n /= dot(n, vec3(1));

    vec3 col = textureLod(tex, p.yz, lod).rgb * n.x;
    col += textureLod(tex, p.xz, lod).rgb * n.y;
    col += textureLod(tex, p.xy, lod).rgb * n.z;
    
    return col;
}

const vec3 lcol = vec3(1, 0.9, 0.75) * 2.0;
const vec3 ldir = normalize(vec3(0.85, 1.2, 0.8));

const vec3 skyCol = vec3(0.353, 0.611, 1);
const vec3 skyCol2 = vec3(0.8, 0.9, 1);

vec2 getBiome(vec3 pos)
{
    float snow = textureLod(iChannel3, pos.xz * 0.00015, 0.0).r;
    snow = smoothstep(0.695, 0.7, snow);
    
    float desert = textureLod(iChannel3, 0.55-pos.zx * 0.00008, 0.0).g;
    desert = smoothstep(0.67, 0.672, desert);
    
    return vec2(desert, snow);
}

vec3 getAlbedo(vec3 vpos, vec3 gn, float lod)
{
    vec3 alb = 1.0-triplanarLod(iChannel2, vpos * 0.08, gn, 4.0, lod);
    alb *= alb;
    
    vec3 alb2 = 1.0-triplanarLod(iChannel3, vpos * 0.08, gn, 4.0, lod);
    alb2 *= alb2;
    
    float k = triplanarLod(iChannel0, vpos * 0.0005, gn, 4.0, 0.0).r;
    k = smoothstep(0.3, 0.25, k);
    
    float wk = smoothstep(MAX_WATER_HEIGHT, MAX_WATER_HEIGHT + 0.5, vpos.y);
    float top = smoothstep(0.3, 0.7, gn.y);
    
    alb = alb * 0.95 * vec3(1, 0.7, 0.65) + 0.05;
    alb = mix(alb, alb2 * vec3(0.55, 1, 0.1), top * wk);
    
    alb = mix(alb, smoothstep(vec3(0.0), vec3(1.0), alb2), k * (1.0 - top));
    
    vec2 biome = getBiome(vpos);
    
    vec3 snow = alb2 * 0.8 + 0.2 * vec3(0.25, 0.5, 1);
    snow = mix(snow, vec3(0.85, 0.95, 1), top * wk * 0.5);
    
    alb = mix(alb, saturate(vec3(1,0.95,0.9)-alb2*0.65), biome.x);
    alb = mix(alb, snow * 2.0, biome.y);
    
    vec3 dcol = vec3(0.8, 0.55, 0.35);
    dcol = mix(dcol, vec3(0.8, 0.65, 0.4), biome.x);
    dcol = mix(dcol, vec3(0.2, 0.6, 0.8), biome.y);
    
    alb = mix(alb, alb * dcol, (1.0 - wk) * mix(1.0 - k, 1.0, max(biome.x, biome.y)));
    
    return alb;
}

vec3 shade(vec3 pos, vec3 ldir, float lod, HitInfo hit)
{
    vec3 vpos = hit.id;
    
    vec3 g = grad(vpos);
    float gd = length(g);
    vec3 gn = g / gd;
    vec3 n = hit.n;
    
    float dif = max(dot(n, ldir), 0.0);
    
    if (dif > 0.0)
    {
        #ifdef SDF_TRAVERSAL
        pos += hit.n * 0.05;
        #else
        pos += hit.n * 1e-3;
        #endif
        
        HitInfo hitL;
        bool isHitL = trace(pos, ldir, hitL, 12.0);

        dif *= float(!isHitL);
    }
    
    const float s = exp2(-4.0);
    vec3 uvw = fract(pos / s);
    vec2 vuv = abs(n.x) * uvw.yz + abs(n.y) * uvw.xz + abs(n.z) * uvw.xy;
    
    vec3 col = getAlbedo(vpos, gn, lod);
    
    float ao = smoothstep(-0.08, 0.04, map(pos) / length(grad(pos)));
    float hao = smoothstep(WATER_HEIGHT - 12.0, WATER_HEIGHT, pos.y);
    
    #ifndef SDF_TRAVERSAL
    col *= dot(abs(n), vec3(0.8, 1, 0.9));
    #endif
    
    col *= (dif * 0.6 + 0.4) * lcol;
    
    col *= ao * 0.6 + 0.4;
    col *= hao * 0.6 + 0.4;
    
    return col;
}

vec3 shade2(vec3 pos, vec3 ldir, float lod, HitInfo hit)
{
    vec3 vpos = hit.id;
    
    vec3 g = grad(vpos);
    float gd = length(g);
    vec3 gn = g / gd;
    vec3 n = hit.n;
    
    float dif = max(dot(n, ldir), 0.0);
    
    const float s = exp2(-4.0);
    vec3 uvw = fract(pos / s);
    vec2 vuv = abs(n.x) * uvw.yz + abs(n.y) * uvw.xz + abs(n.z) * uvw.xy;
    
    vec3 col = getAlbedo(vpos, gn, lod);
    
    float ao = smoothstep(-0.08, 0.04, map(pos) / length(grad(pos)));
    float hao = smoothstep(WATER_HEIGHT - 12.0, WATER_HEIGHT, pos.y);
    
    #ifndef SDF_TRAVERSAL
    col *= dot(abs(n), vec3(0.8, 1, 0.9));
    #endif
    
    col *= (dif * 0.6 + 0.4) * lcol;
    
    col *= ao * 0.6 + 0.4;
    col *= hao * 0.6 + 0.4;
    
    return col;
}

vec3 getSky(vec3 rd)
{
    vec3 col = mix(skyCol2, skyCol, smoothstep(0.0, 0.2, rd.y)) * 1.2;
    
    #define SUN_ANGLE_DEGREES 0.52
    const float sunAngle = SUN_ANGLE_DEGREES * PI / 180.0;
    const float sunCost = cos(sunAngle);
    
    float cost = max(dot(rd, ldir), 0.0);
    float dist = cost - sunCost;
    
    float bloom = max(1.0 / (0.02 - min(dist, 0.0)*500.0), 0.0) * 0.02;
    
    vec3 sun = 10.0 * lcol * (smoothstep(0.0, 0.0001, dist) + bloom);
    
    return col + sun;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pv = (2. * (fragCoord) - iResolution.xy) / iResolution.y;
    vec2 uv = fragCoord / iResolution.xy;
    
    const float fov = 80.0;
    const float invTanFov = 1.0 / tan(radians(fov) * 0.5);
    
    #ifdef MOTION_BLUR
    float mb = MOTION_BLUR * dot(pv, pv) / invTanFov * hash13(vec3(fragCoord, iFrame));
    vec3 ro = getCameraPos(iTime + mb);
    #else
    vec3 ro = getCameraPos(iTime);
    #endif
    vec3 lo = vec3(0,0,-1);
    
    vec2 m = iMouse.xy / iResolution.xy;
    
    #ifdef STATIC_CAM
    m = vec2(0.6, 0.45);
    m = vec2(0.3, 0.42);
    m = vec2(0.43, 0.48);
    #endif
    
    float ax = -m.x * TAU + PI;
    float ay = -m.y * PI + PI * 0.5;
    
    #ifdef STATIC_CAM
    if (true)
    #else
    if (iMouse.z > 0.0)
    #endif
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
    
    HitInfo hit;
    bool isHit = trace(ro, rd, hit, MAX_DIST);
    
    float t = hit.t;
    
    vec3 pos = ro + rd * t;
    vec3 vpos = hit.id;
    
    float lod = clamp(log2(distance(ro, vpos)) - 2.0, 0.0, 6.0);
    
    vec3 col = shade(pos, ldir, lod, hit);

    const float a = 0.012;
    const float b = 0.08;
    float fog = (a / b) * exp(-(ro.y - WATER_HEIGHT) * b) * (1.0 - exp(-t * rd.y * b)) / rd.y;

    vec2 biome = getBiome(vpos);

    vec3 fogCol = vec3(0.5, 0.8, 1);
    fogCol = mix(fogCol, vec3(1, 0.85, 0.6), biome.x);

    col = mix(col, fogCol, fog);
    
    if (!isHit)
    {
        t = MAX_DIST;
        col = getSky(rd);
    }
    
    float pt = -(ro.y - WATER_HEIGHT) / rd.y;
    
    if (pt > 0.0 && pt < t || ro.y < WATER_HEIGHT)
    {
        if (!isHit)
        {
            col = fogCol;
        }
        
        vec3 wcol = vec3(0.5, 1, 1);
        wcol = mix(wcol, vec3(0.5,1,0.9), biome.x);
        wcol = mix(wcol, vec3(0.2, 0.8, 1), biome.y);
        
        vec3 wabs = vec3(0.15,0.8,1);
        
        pt = ro.y < WATER_HEIGHT && pt < 0.0 ? MAX_DIST : pt;
        
        vec3 wpos = ro + rd * pt;
        
        const float e = 0.001;
        const float wnstr = 1500.0;
        
        vec2 wo = vec2(1, 0.8) * iTime * 0.01;
        vec2 wuv = wpos.xz * 0.08 + wo;
        float wh = texture(iChannel2, wuv).r;
        float whdx = texture(iChannel2, wuv + vec2(e, 0)).r;
        float whdy = texture(iChannel2, wuv + vec2(0, e)).r;
        
        vec3 wn = normalize(vec3(wh - whdx, e * wnstr, wh - whdy));
        
        vec3 wref = reflect(rd, wn);
        
        vec3 rcol = vec3(0);
        
        if (ro.y > WATER_HEIGHT)
        {
            HitInfo hitR;
            bool isHitR = trace(wpos + vec3(0, 0.01, 0), wref, hitR, 15.0);

            rcol = isHitR ? shade2(wpos, ldir, lod, hitR) : getSky(wref);
        }
        
        float spec = pow(max(dot(wref, ldir), 0.0), 50.0);
        
        const float r0 = 0.35;
        float fre = r0 + (1.0 - r0) * pow(max(dot(rd, wn), 0.0), 5.0);
        
        if (rd.y < 0.0 && ro.y < WATER_HEIGHT)
            fre = 0.0;
        
        float abt = ro.y < WATER_HEIGHT ? min(t, pt) : t - pt;
        col *= exp(-abt * (1.0 - wabs) * 0.08);
        
        if (pt < t)
        {
        
            col = mix(col, wcol * (rcol + spec), fre);
        
            vec3 wp = wpos + wn * vec3(1,0,1) * 0.2;
            float wd = map(wp) / length(grad(wp));
            float foam = sin((wd - iTime * 0.03) * 60.0);
            foam = smoothstep(0.22, 0.0, wd + foam * 0.03 + (wh - 0.5) * 0.12);

            col = mix(col, col + vec3(1), foam * 0.4);
        }
    }
    
    float cost = max(dot(rd, ldir), 0.0);
    col += 0.12 * lcol * pow(cost, 6.0);
    
    #ifdef SHOW_NORMALS
    col = hit.n;
    #endif
    
    #ifdef SHOW_STEPS
    col = turbo(float(hit.i) / float(STEPS));
    
    if (fragCoord.y < 10.0)
        col = turbo(uv.x);
    #endif
    
    col = max(col, vec3(0));
    //col = col / (1.0 + col);
    //col = ReinhardExtLuma(col, 5.0);
    col = ACESFilm(col * 0.35);
    
    fragColor = vec4(linearTosRGB(col), 1);
    fragColor += (dot(hash23(vec3(fragCoord, iTime)), vec2(1)) - 0.5) / 255.;
}