// Buffer A (buffer) — Extruded Quadtree Path Tracing by gelami
// https://www.shadertoy.com/view/Dly3DW


// Fork of "Gelami Raymarching Template" by gelami. https://shadertoy.com/view/mslGRs
// 2023-05-12 02:58:47

vec2 map(vec2 p, float lod)
{
    float h = 1.0;
    bool leaf = false;
    for (float i = MAX_LOD; i >= lod; i--)
    {
        float s = exp2(MAX_LOD-i);
        vec2 o = floor(p * s) / exp2(MAX_LOD-i);
        
        vec2 r = texture(iChannel1, (floor(p * s) + 0.5) / iChannelResolution[1].xy).xy;
        //vec2 r = hash22(o);
        float k = r.x;
        
        if (i == MAX_LOD)
        {
            h = (k*0.25+0.75) * 0.9999;
            //h = mix(k, 1.0, 0.95);
        } else
        {
            k = mix(k, 1.0, 0.95);
            h *= k;
        }
        if (i != MAX_LOD && r.y < 0.1 + (MAX_LOD-i) * 0.1)
        {
            leaf = true;
            break;
        }
    }
    
    return vec2(h * MAX_HEIGHT, leaf);
}

struct HitInfo
{
    float t;
    vec3 n;
    vec2 id;
};

bool trace(vec3 ro, vec3 rd, out HitInfo hit)
{

    vec3 ird = 1.0 / rd;
    vec3 srd = sign(ird);
    vec3 ard = abs(ird);
    
    vec3 iro = ro * ird;
    
    vec2 id = floor(ro.xz);
    vec2 pid = id;

    float s = 1.0;
    float lod = MAX_LOD;
    vec3 pos = ro;
    
    vec2 nrd = vec2(0);
    float t = 0.0;

    for (int i = 0; i < STEPS; i++)
    {
        vec2 p = (id + 0.5) * s;
        
        vec2 h = map(id * s, lod);
        
        if (pos.y < h.x)
        {
            if (lod > 0.0 && h.y < 0.5)
            {
                id *= 2.0;
                id += step(vec2(0), pos.xz - p);
                pid = id;
                
                s *= 0.5;
                lod--;
                continue;
            } else
            {
                hit.t = t;
                hit.n = -vec3(nrd.x, 0, nrd.y);
                hit.id = id;
                return true;
            }
        }
        
        vec2 n = iro.xz - p * ird.xz;
        vec2 k = ard.xz * s * 0.5;
        
        vec2 t2 = -n + k;
        
        float nt = min(t2.x, t2.y);
        
        vec3 npos = ro + rd * nt;
        
        if (rd.y > 0.0 && npos.y > MAX_HEIGHT)
            return false;
        
        if (npos.y < h.x)
        {
            
            if (lod > 0.0 && h.y < 0.5)
            {
                id *= 2.0;
                id += step(vec2(0), pos.xz - p);
                pid = id;
                
                s *= 0.5;
                lod--;
                continue;
                
            } else
            {
                hit.t = -(ro.y - h.x) / rd.y;
                hit.n = vec3(0, 1, 0);
                hit.id = id;
                return true;
            }
        }
        
        pos = npos;
        t = nt;
        
        nrd = step(t2, t2.yx) * srd.xz;
        pid = id;
        id += nrd;
        
        if (floor(pid*0.5) != floor(id*0.5) && lod < MAX_LOD)
        {
            id = floor(id*0.5);
            pid = id;
            s *= 2.0;
            lod++;
        }
    }

    return false;
}

float fresnel(float r0, vec3 rd, vec3 n)
{
    return r0 + (1.0 + r0) * pow(1.0 - dot(-rd, n), 5.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    initState(fragCoord, iFrame);
    
    ivec2 iFragCoord = ivec2(fragCoord);
    
    vec2 o = getJitter(fragCoord, iFrame);
    vec2 pv = (2. * (fragCoord + o) - iResolution.xy) / iResolution.y;
    vec2 uv = fragCoord / iResolution.xy;
    
    vec3 ro = vec3(0, 0, CAMERA_DIST);
    vec3 pro = vec3(0, 0, CAMERA_DIST);
    vec3 lo = CAMERA_POSITION;
    
    #define MOUSE_DEFAULT vec4(CAMERA_ANGLE, 0, 0)
    vec4 m = texelFetch(iChannel0, ivec2(0, 0), 0);
    vec4 pm = texelFetch(iChannel0, ivec2(1, 0), 0);
    
    if (iFrame < 2)
    {
        m = MOUSE_DEFAULT;
        pm = MOUSE_DEFAULT;
    }
    
    #ifdef STATIC_CAMERA
    m = MOUSE_DEFAULT;
    #endif
    
    if (iFragCoord == ivec2(0, 0))
    {
        if (iFrame < 2)
        {
            fragColor = MOUSE_DEFAULT;
        } else
        {
            vec2 mn = iMouse.xy / iResolution.xy;
            fragColor = vec4(m);
            if (iMouse.z > 0.0)
            {
                if (fragColor.zw != vec2(0))
                {
                    fragColor.xy += (mn - m.zw);
                    fragColor.y = clamp(fragColor.y, 1e-4, 1.0 - 1e-4);
                }
                fragColor.zw = mn;
            } else
            {
                fragColor.zw = vec2(0);
            }
        }
        return;
    } else if (iFragCoord == ivec2(1, 0))
    {
        if (iFrame < 2)
            fragColor = MOUSE_DEFAULT;
        else
            fragColor = texelFetch(iChannel0, ivec2(0, 0), 0);
        return;
    }
    
    float ax = -m.x * TAU + PI;
    float ay = m.y * PI - PI * 0.5;
    
    ro.yz *= rot2D(ay);
    ro.xz *= rot2D(ax);
    ro += lo;

    mat3 cmat = getCameraMatrix(ro, lo);
    
    const float invTanFov = 2.5;
    
    const float dofStrength = DOF_STRENGTH;
    const float dofDist = DOF_FOCUS_DISTANCE / invTanFov;
    
    vec3 nro = ro;
    
    #ifndef REPROJECT
    
    #if DOF_SIDES == 0
    vec2 rc = randomPointInCircle();
    #else
    vec2 rc = randomPointInPolygon(float(DOF_SIDES));
    #endif
    
    rc *= dofStrength * dofDist;
    
    pv -= rc / dofDist;
    nro += cmat * vec3(rc, 0);
    #endif
    
    vec3 rd = normalize(cmat * vec3(pv, invTanFov));
    
    vec3 sunDir = normalize(vec3(0.7, 1.2, 1));
    
    vec3 ligCol = (vec3(1,0.6,0.15)*0.8+0.2)*1.5;
    vec3 skyCol = vec3(0.2, 0.3, 0.5) * 0.4;
    
    vec3 ldir = randomUniformCone(radians(0.56 * 2.0));
    
    mat3 sunMat = getBasis(sunDir);
    
    ldir = sunMat * ldir;
    
    vec3 col = vec3(0);
    vec3 thr = vec3(1);
    
    vec3 pos = nro;
    float pt = 0.0;
    
    if (pos.y > MAX_HEIGHT)
    {
        pt = -(pos.y - MAX_HEIGHT) / rd.y;
        pos = pos + rd * pt;
    }
    
    HitInfo hit;
    bool isHit = trace(pos, rd, hit);
    
    vec3 cpos = pos;
    vec3 crd = rd;
    
    float t = isHit ? pt + hit.t : MAX_DIST;
    pos = pos + rd * hit.t;
    
    for (int i = 0; i < BOUNCES; i++)
    {
        if (!isHit)
        {
            col += skyCol * thr;
            break;
        }
        
        cpos = cpos + crd * hit.t + hit.n * EPS;
        
        vec3 alb = vec3(hash12(hit.id.yx) * 0.2 + 0.8);
        alb = palette2(hash12(hit.id.yx));
        
        float fre = fresnel(0.08, crd, hit.n);
        
        if (hash(state) < fre && i < BOUNCES-1)
            crd = reflect(crd, hit.n);
        else
            crd = randomCosineHemisphere(hit.n);
        
        thr *= alb;
        
        float dif = max(dot(hit.n, ldir), 0.0);
        
        HitInfo hitL;
        bool isHitL = trace(cpos, ldir, hitL);

        if (!isHitL)
        {
            col += dif * ligCol * thr;
        }
        
        isHit = trace(cpos, crd, hit);
        
        if (!isHit)
        {
            col += skyCol * thr;
            break;
        }
    }
    
    #ifdef REPROJECT
    float blend = iFrame == 0 ? 1.0 : 1.0 / 16.0;
    
    float pax = -pm.x * TAU + PI;
    float pay = pm.y * PI - PI * 0.5;
    
    pro.yz *= rot2D(pay);
    pro.xz *= rot2D(pax);
    pro += lo;

    mat3 pmat = getCameraMatrix(pro, lo);
    
    vec3 pvpos = (pos - pro) * pmat;
    vec2 pndc = invTanFov * pvpos.xy / pvpos.z;
    vec2 puv = pndc * vec2(iResolution.y / iResolution.x, 1) * .5 + .5 - o / iResolution.xy;
    
    vec2 ppv = (2.0 * puv * iResolution.xy - iResolution.xy) / iResolution.y;
    vec2 pfc = puv * iResolution.xy;
    
    vec3 prd = normalize(pmat * vec3(ppv, invTanFov));
    
    vec4 prev = texture(iChannel0, puv);
    
    vec3 ppos = pro + prd * prev.a;
    
    if (puv != saturate(puv))
        blend = 1.0;
    
    #ifndef STATIC_CAMERA
    if (m.zw != vec2(0) && abs(t - prev.a) > 0.05) blend = 1.0;
    #endif
    
    col = max(col, vec3(0));
    col = mix(prev.rgb, col, blend);
    
    fragColor = vec4(col, t);
    
    #else
        
    vec4 prev = texture(iChannel0, uv);
    
    float blend = iFrame == 0 ? 1.0 : 1.0 / (1.0 + 1.0 / prev.a);
    
    #ifndef STATIC_CAMERA
    if (m.zw != vec2(0)) blend = 1.0;
    #endif
    
    col = max(col, vec3(0));
    col = mix(prev.rgb, col, blend);
    
    fragColor = vec4(col, blend);
    
    #endif
}
