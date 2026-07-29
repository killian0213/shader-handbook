// Buffer A (buffer) — Frostbite Material Render-Ref by TinyTexel
// https://www.shadertoy.com/view/wsScWt

// Lincense: CC0 (https://creativecommons.org/publicdomain/zero/1.0/)

/*
Basic implementation of Frostbite's material + relevant sampling strategies.
Camera controls via mouse + shift key.

References:
	https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
	https://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf

The bulk of the material specific code is in the Common tab; direct light sampling routines + rendering in BufferA. Tonemapping in Image.
*/


////////////////////////////////////////////////////////////
//--------------------------------------------------------//
#define KEY_LEFT  37
#define KEY_UP    38
#define KEY_RIGHT 39
#define KEY_DOWN  40

#define KEY_SHIFT 0x10
#define KEY_A 0x41
#define KEY_D 0x44
#define KEY_S 0x53
#define KEY_W 0x57

#define KeyBoard iChannel1

float ReadKey(int keyCode) {return texelFetch(KeyBoard, ivec2(keyCode, 0), 0).x;}


#define VarTex iChannel0
#define OutCol outCol
#define OutChannel w

#define WriteVar(v, cx, cy) {if(uv.x == float(cx) && uv.y == float(cy)) OutCol.OutChannel = v;}
#define WriteVar4(v, cx, cy) {WriteVar(v.x, cx, cy) WriteVar(v.y, cx, cy + 1) WriteVar(v.z, cx, cy + 2) WriteVar(v.w, cx, cy + 3)}

float ReadVar(int cx, int cy) {return texelFetch(VarTex, ivec2(cx, cy), 0).OutChannel;}
vec4 ReadVar4(int cx, int cy) {return vec4(ReadVar(cx, cy), ReadVar(cx, cy + 1), ReadVar(cx, cy + 2), ReadVar(cx, cy + 3));}
//--------------------------------------------------------//
////////////////////////////////////////////////////////////


// settings for the spherical light sources:
const vec3 LightPos = vec3(0.0, 6.9, 0.0);
const float R2 = 16.1;// squared radius
const float Flux = 512.0;

const float A = R2 * 4.0 * Pi;

const float HemiSphProjOmega = Pi;
const float SphOmega = 4.0 * Pi;

const float Radiance = Flux / A / HemiSphProjOmega;
const float Intensity = Flux / SphOmega; // = Radiance * (HemiSphProjOmega * R2);


// voxel-based, Cornell box-like scene:
bool map(vec3 p)
{
    p += 0.5;
    vec3 b = abs(p);
    
    bool r;
    
    r =      b.x < 8.0;
    r = r && b.y < 8.0;
    r = r && b.z < 8.0;
    
    r = r && !(b.x < 7.0 && b.y < 7.0 && p.z > -7.0);
   
    r = r || (p.x > 1.0 && p.x < 5.0 && p.z > 1.0 && p.z < 5.0 && p.y > -8.0 && p.y < -3.0);
    r = r || (p.x >-5.0 && p.x <-1.0 && p.z > -5.0 && p.z <-1.0 && p.y > -8.0 && p.y < 0.0);
    
    float ws = 2.0;
    //if(p.y > 7.0 && b.x < ws && b.z < ws) r = false;
    
    return r;
}

// albedo:
vec3 mapC(vec3 p)
{
    p += 0.5;
    vec3 b = abs(p);
    
    vec3 c = vec3(1.0);
    
    if(b.y < 7.0 && p.z > -7.0) 
        if(p.x < -7.0) 
            c = vec3(1.0, 0.2, 0.01);//orange wall
        else if(p.x > 7.0) 
            c = vec3(0.01, 0.3, 1.0);// blue wall
        

    return c;
}

vec3 minmask(vec3 v)
{
    return vec3(v.x <= v.y && v.x <= v.z,
                v.y <  v.z && v.y <  v.x,
                v.z <  v.x && v.z <= v.y);
}

// modified version of iq's DDA implementation: https://www.shadertoy.com/view/4dfGzs
bool VoxelRayCast(vec3 rp, vec3 rd, /**/ out vec3 vp, out vec3 n, out float t)
{
	vec3 pos = floor(rp);
	vec3 ri = 1.0/rd;
	vec3 rs = sign(rd);
	vec3 off = (-rp + (rs * 0.5 + 0.5)) * ri;

	vec3 mm = vec3(0.0);
    
	if(map(pos)) { t = 0.0; n = vec3(0.0); vp = pos; return true; }
    
	bool hit = false;
	for(int i = 0; i < 128; i++) 
	{        
        vec3 dis = pos * ri + off;

        mm = minmask(dis);
            
        pos += mm * rs;
        
		if(map(pos)) { hit = true; break; }
	}
	
    // intersect the cube	
    vec3 mini = (pos - rs) * ri + off;   
	t = max(mini.x, max(mini.y, mini.z));

	n = -mm * rs;
	vp = pos;

	return hit;
}


bool Intersect_Scene(vec3 rp, vec3 rd, bool isPrimaryRay,
                     out float t, out vec3 n, out vec3 a, inout bool hitLight)
{
    bool doTestLight = hitLight;
    hitLight = false;
        
    vec3 vp;
    bool hit = VoxelRayCast(rp, rd, /*out*/ vp, n, t);
    
    //a = vec3(1.0);
    a = mapC(vp);
    
	if(doTestLight)    
    {
        vec2 t0;
		float hit0 = Intersect_Ray_Sphere(rp, rd, LightPos, R2, /*out*/ t0);
        
        if(hit0 == 1.0)
        {
            if(!hit || t0.x < t)
            {
                t = t0.x;
                n = normalize(rp + rd * t0.x - LightPos);
                a = vec3(1.0);
                
                hitLight = true;
            }
            
            hit = true;
        }
    }
    
    return hit;
}

// --------------------------------------------------------------------------------------------------------------------------
vec3 Sample_PointLight(vec3 V, vec3 p, vec3 N, vec3 albedo, float roughness, vec3 F0)
{
    float alpha = GGXAlphaFromRoughness(roughness);
    
    vec3 pl = LightPos;
    vec3 vecl = pl - p;
    vec3 L = normalize(vecl);
    float d2 = dot(vecl, vecl);

    float t2; vec3 n2; vec3 a2; bool hitLight2 = false;
    bool hit = Intersect_Scene(p, L, false, /*out*/ t2, n2, a2, hitLight2);

    if(hit && t2*t2 < d2) return vec3(0.0);
        
    float att = 1.0 / d2;

    return Frostbite_R(V, N, L, albedo, roughness, F0) * att * Intensity;
}

vec3 Sample_DirLight(vec3 V, vec3 p, vec3 N, vec3 L, vec3 albedo, float roughness, vec3 F0)
{
    float alpha = GGXAlphaFromRoughness(roughness);
    
    float t2; vec3 n2; vec3 a2; bool hitLight2 = false;
    bool hit = Intersect_Scene(p, L, false, /*out*/ t2, n2, a2, hitLight2);

    if(hit) return vec3(0.0);

    return Frostbite_R(V, N, L, albedo, roughness, F0) * (Intensity * Pow2(0.125));// just set brightness heuristically here based on point light intensity
}


vec3 Sample_SphLight_HemiSph(vec3 V, vec3 p, vec3 N, inout uint h, vec3 albedo, float roughness, vec3 F0)
{
    float alpha = GGXAlphaFromRoughness(roughness);
    
    vec3 L;
    {
        float h0 = Hash11(h);
        float h1 = Hash01(h);
        	  
        L = Sample_Sphere(h0, h1, N);
    }

    float t2; vec3 n2; vec3 a2; bool isLight2 = true;
    bool hit = Intersect_Scene(p, L, false, /*out*/ t2, n2, a2, isLight2);

    if(!isLight2) return vec3(0.0);
    
    float NoL = clamp01(dot(N, L));
    
    return Frostbite_R(V, N, L, albedo, roughness, F0) * Radiance * NoL * pi2;
}

vec3 Sample_SphLight_ClmpCos(vec3 V, vec3 p, vec3 N, inout uint h, vec3 albedo, float roughness, vec3 F0)
{
    float alpha = GGXAlphaFromRoughness(roughness);
    
    vec3 L;
    {
        float h0 = Hash11(h);
        float h1 = Hash01(h);

        L = Sample_ClampedCosineLobe(h0, h1, N);
    }

    float t2; vec3 n2; vec3 a2; bool isLight2 = true;
    bool hit = Intersect_Scene(p, L, false, /*out*/ t2, n2, a2, isLight2);

    if(!isLight2) return vec3(0.0);
    
    return Frostbite_R(V, N, L, albedo, roughness, F0) * Radiance * pi;
}

// s [0..1]
vec3 Sample_SphLight_SolidAngle(vec2 s, vec3 V, vec3 p, vec3 N, vec3 albedo, float roughness, vec3 F0)
{
    float alpha = GGXAlphaFromRoughness(roughness);
    
    float ct; vec3 Lc, L; float sang;
    Sample_SolidAngle(s, p, LightPos, R2, /*out*/ ct, /*out*/ Lc, /*out*/ L, /*out*/ sang);

    float NoL = dot(N, L);

    if(NoL <= 0.0) return vec3(0.0);
    
    float t2; vec3 n2; vec3 a2; bool isLight2 = true;
    bool hit = Intersect_Scene(p, L, false, /*out: */ t2, n2, a2, isLight2);

    if(!isLight2 && t2 < dot(LightPos-p, Lc)) return vec3(0.0);
    
    vec3 f = Frostbite_R(V, N, L, albedo, roughness, F0);
    float rpdf = sang;

    return f * rpdf * Radiance;
}

// s0 [0..1], s1 [0..1]
vec3 Sample_SphLight_MIS(vec2 s0, vec2 s1, vec3 V, vec3 p, vec3 N, vec3 albedo, float roughness, vec3 F0)
{
    float alpha = GGXAlphaFromRoughness(roughness);
    
    float ct; vec3 Lc, L0; float sang;
    Sample_SolidAngle(s0, p, LightPos, R2, /*out*/ ct, /*out*/ Lc, /*out*/ L0, /*out*/ sang);
    float pdf00 = 1.0/sang;

    vec3 L1; vec3 f1; float pdf11;
    Sample_GGX_R(s1, V, N, alpha, F0, /*out*/ L1, /*out*/ f1, /*out*/ pdf11);

    bool couldL1HitLight = dot(L1, Lc) > ct;
    
    vec3 f0 = Frostbite_R(V, N, L0, albedo, roughness, F0);
         f1 = Frostbite_R(V, N, L1, albedo, roughness, F0);

    float pdf01 = couldL1HitLight ? pdf00 : 0.0;
    float pdf10 = EvalPDF_GGX_R(V, N, L0, alpha);

    float w0, w1;
    #if 1
    w0 = (pdf00) / (Pow2(pdf00) + Pow2(pdf10));
    w1 = (pdf11) / (Pow2(pdf11) + Pow2(pdf01));        
    #else
    w0 = 1.0 / (pdf00 + pdf23);
    w1 = 1.0 / (pdf11 + pdf32);
    #endif

    float t2; vec3 n2; vec3 a2; bool isLight2 = true;
    bool hit2 = Intersect_Scene(p, L0, false, /*out*/ t2, n2, a2, isLight2);

    float t3; vec3 n3; vec3 a3; bool isLight3 = true;
    bool hit3 = Intersect_Scene(p, L1, false, /*out*/ t3, n3, a3, isLight3);

    if((isLight2 == false && t2 < dot(LightPos-p, Lc)) || dot(N, L0) <= 0.0) f0 = vec3(0.0);
    if(couldL1HitLight == false || isLight3 == false) f1 = vec3(0.0);

    vec3 res  = pdf00 == 0.0 ? vec3(0.0) : f0 * w0;
         res += pdf11 == 0.0 ? vec3(0.0) : f1 * w1;

    return res * Radiance;       
}

// single sample version of Sample_SphLight_MIS; use this if intersecting the scene is expensive
// s0 [0..1], s1 [0..1], s2 [0..1]
vec3 Sample_SphLight_MIS2(vec2 s0, vec2 s1, float s2, vec3 V, vec3 p, vec3 N, vec3 albedo, float roughness, vec3 F0)
{
    float alpha = GGXAlphaFromRoughness(roughness);
    
    float ct; vec3 Lc, L0; float sang;
    Sample_SolidAngle(s0, p, LightPos, R2, /*out*/ ct, /*out*/ Lc, /*out*/ L0, /*out*/ sang);
    float pdf00 = 1.0/sang;

    vec3 L1; vec3 f1; float pdf11;
    Sample_GGX_R(s1, V, N, alpha, F0, /*out*/ L1, /*out*/ f1, /*out*/ pdf11);

    bool couldL1HitLight = dot(L1, Lc) > ct;
    
    vec3 f0 = Frostbite_R(V, N, L0, albedo, roughness, F0);
         f1 = Frostbite_R(V, N, L1, albedo, roughness, F0);

    float pdf01 = couldL1HitLight ? pdf00 : 0.0;
    float pdf10 = EvalPDF_GGX_R(V, N, L0, alpha);

    float w0, w1;
    #if 1
    w0 = Pow2(pdf00) / (Pow2(pdf00) + Pow2(pdf10));
    w1 = Pow2(pdf11) / (Pow2(pdf11) + Pow2(pdf01));        
    #elif 1
    w0 = (pdf00) / ((pdf00) + (pdf10));
    w1 = (pdf11) / ((pdf11) + (pdf01)); 
    #else
    w0 = 0.5; 
    w1 = 1.0 - w1;
    #endif

    float wn = couldL1HitLight == false ? 1.0 : w0 / (w0 + w1);

    bool doUseSmpl0 = s2 <= wn;

    float denom = doUseSmpl0 ? pdf00 * wn : pdf11 * (1.0 - wn);

    vec3 L = doUseSmpl0 ? L0 : L1;

    if(dot(N, L) <= 0.0 || denom == 0.0) return vec3(0.0);
    
    float t2; vec3 n2; vec3 a2; bool isLight2 = true;
    bool hit2 = Intersect_Scene(p, L, false, /*out*/ t2, n2, a2, isLight2);

    if(hit2 && isLight2)
    {
        if(doUseSmpl0)
            return f0 / denom * w0 * Radiance;
        else
            return f1 / denom * w1 * Radiance;
    }
}


// sRGB => XYZ => D65_2_D60 => AP1
const mat3 sRGBtoAP1 = mat3
(
	0.613097, 0.339523, 0.047379,
	0.070194, 0.916354, 0.013452,
	0.020616, 0.109570, 0.869815
);

vec3 MapColor(vec3 srgb)
{
    #ifdef USE_ACESCG
    return srgb * sRGBtoAP1;
    #else
    return srgb;
    #endif
}

vec3 UnitDiskToHemisphere(vec2 p)
{
    float s = dot(p, p);
    float l = sqrt(2.0 - s);
    
    return vec3(p.x * l, 1.0 - s, p.y * l);
}


void mainImage(out vec4 outCol, in vec2 uvO)
{     
    float aspect = iResolution.x / iResolution.y;
    
    vec2 iResolution2 = iResolution.xy;
    vec2 uv0 = uvO;
    
    bool isRight = false;
    
    #if 0
    if(uv0.x >= iResolution.x * 0.5)
    {
       uv0.x -= iResolution.x * 0.5;
       isRight = true;
    }
    
    iResolution2.x = iResolution.x * 0.5;
    #endif
    
    vec2 uv = uv0.xy - 0.5;
	vec2 tex = uv0.xy / iResolution2.xy;
    vec2 tex21 = tex * 2.0 - vec2(1.0);
    
    vec4 mouseAccu  = ReadVar4(1, 0);
    vec4 wasdAccu   = ReadVar4(2, 0);
    float frameAccu = ReadVar (3, 0);


    vec2 ang = vec2(-0.42 * Pi, -Pi * 0.08);
    ang += mouseAccu.xy * 0.008;
    
    mat3 cmat;
    {
        float sinPhi   = sin(ang.x);
        float cosPhi   = cos(ang.x);
        float sinTheta = sin(ang.y);
        float cosTheta = cos(ang.y);    

        vec3 front = vec3(cosPhi * cosTheta, 
                                   sinTheta, 
                          sinPhi * cosTheta);

        vec3 right = vec3(-sinPhi, 0.0, cosPhi);
        
        vec3 up    = vec3(-cosPhi * sinTheta,
                                    cosTheta,
                          -sinPhi * sinTheta);
        
        cmat = mat3(right, up, front);
    }
    
    float cdist = exp2(2.5 + mouseAccu.w * 0.02);
    vec3 cpos = -cmat[2] * cdist;
    

    uint frameNum = uint(frameAccu);
    
    uint h = WellonsHash(uvec3(uv, frameNum), 0u).x;
    uvec2 hh = WellonsHash(uvec2(uv), 0u).xy;
    uint hh1 = WellonsHash(uvec2(uv), 0u).z;
    
    vec2 tc;
    {
        vec2 off;
        {
            // filter kernel:
            float h0 = Hash11(h);
            float h1 = Hash11(h);
            
        	off = vec2(Sample_Triangle(h0), 
                       Sample_Triangle(h1));
        }

       #ifdef USE_BLOOM
       //if(false)
        {
            // heavy tail bloom kernel:
            vec2 h01 = Float01(Roberts(hh, frameNum));
            float h0 = h01.x*2.0-1.0;
            float rr = h01.y;
            
            vec2 dir = AngToVec(h0 * Pi);
            float r = sqrt(rr);
            
           #if 0
           
            r = sqrt(2.0*rr-rr*rr) / (1.0 - rr);
            
           #elif 0
           
            r = tan(r*Pi*0.5)/(Pi)*2.0;
            r=r*r;
            r*=0.125*0.125;
            
           #elif 1
           
            r = rr / (1.0 - rr);
            
            float s = 0.5;
            r = (sqrt(s*s+r*r)-s)*(s+sqrt(1.0+s*s));
            
            r*= 0.0001 * iResolution.x;
           
           #elif 1
           
            r = log((1.0+r)/(1.0-r))*0.3;
            r*=r;
            r*=r;
            r*=r;
           
           #endif
           
        	off += AngToVec(h0 * Pi) * r;
        }
       #endif
        
       #ifdef USE_BLOOM
       //if(false)
        if(((frameNum + hh1) % 16u) == 0u) 
        {
            // blobby bloom kernel:
            vec2 h01 = Float01(Roberts(uvec2(0u), (frameNum + hh1) / 16u));
            float h0 = h01.x*2.0-1.0;
            float rr = h01.y;
            
            vec2 dir = AngToVec(h0 * Pi);
            float r = sqrt(rr);
            
           #if 0
           
           float s = 64.0*(rr+.5);// * (rr*rr);
           
           float bump = pow(clamp01(1.0-Pow2(r*2.0-1.0)), 32.0);
           //bump = 0.0;
           
           //rr = mix((cos(rr*s)+rr*s-1.0)/s, rr, 0.5);
           
           r = (sqrt(1.0/pow(1.0-rr, 8.0) - 1.0)-0.75*bump)*0.5;
           
           #elif 0
           
           r = sqrt(1.0/((rr*rr) * (rr*rr)) - 1.0)*0.25;
           //r = sqrt(1.0/pow(rr, 8.0) - 1.0)*0.5;
            //r = sqrt((2.0*rr-rr*rr)*(2.0-(2.0*rr-rr*rr))) / Pow2(rr - 1.0)*0.5;
            
           #elif 0
           
            r = sqrt(2.0*rr-rr*rr) / (1.0 - rr)*0.5;
            
           #elif 0
           
            r = sqrt(rr / sqrt(1.0 - rr*rr));
           
           #elif 1
           
            r = log((1.0+r)/(1.0-r));
            r*=r;
            r *= 0.125;
            //r = pow(r, 1.25);
           #endif           
           
        	off += AngToVec(h0 * Pi) * r * (0.125 * iResolution.x);
            
           //vec2 gauss = Sample_Gauss2D(h01.x, h01.y*2.0-1.0);
            
            //off += gauss * (0.125*0.5  * iResolution.x);
        }
       #endif
        
        tc = (uv0.xy + off - iResolution2.xy * 0.5) / (iResolution2.xx * 0.5);
    }
    
    vec3 lpos = vec3(0.0);
    #if 0
    {
        // lens pos / dof:
        float h0 = Hash11(h);
        float h1 = Hash01(h);
		
        vec2 lpos0 = Sample_Disk(h0, h1) * 0.1;
        
        lpos = cmat * vec3(lpos0, 0.0);
    }
    #endif

    float focalLen = 0.6;// = 0.5 * tan(Pi05 - fov * 0.5)

    #if 0
    {
        float c = 0.5;
        float s = 0.7;
        
        tc.y *= c;
        tc *= s;
        
        vec3 u = UnitDiskToHemisphere(tc);
        tc = u.xz;
        focalLen = u.y*0.9;
        
        tc /= s;
        tc.y/=c;
    }
    #endif

    float S1 = max(18.0, cdist);// focus plane dist / focalLen
    S1 = 1.0;
    vec3 rdir = normalize(cmat * (vec3(tc, focalLen) * S1) - lpos); 
 
    //rdir = cmat * Pannini(tc, Pi*0.6, 0.5);
    
    #if 0
    vec2 lightAng = vec2(Pi * 0.7, Pi * 0.1);
    lightAng.x += (wasdAccu.y - wasdAccu.w) * 0.06; 
    lightAng.y += (wasdAccu.x - wasdAccu.z) * 0.04;    
    
    vec3 light0 = AngToVec(lightAng);
    light0 = vec3(0.49292178644304296, 0.7169771439171534, 0.49292178644304296);
    
    vec3 light = light0;
    {
        float h0 = Hash11(h);
        float h1 = Hash01(h);

        h1 = mix(0.999, 1.0, h1);
        h1 = 1.0;
        
        light = Sample_Sphere(h0, h1, light);
    }
    #endif
    
    vec3 W = vec3(1.0);
    vec3 col = vec3(0.0);
    
    float t; vec3 N; vec3 color;
    vec3 p = cpos + lpos;
    vec3 dir = rdir;

    vec2 tt; 
    float res = Intersect_Ray_Cube(p, dir, vec3(16.0) + vec3(1e-5), /*out:*/ tt);   
    
    if(res == 1.0)
    {
    	p += dir * tt.x;
    }
    
    if(res != -1.0)
    {
        uint GIBounceCount = 3u;
        
        for(uint i = 0u; i < GIBounceCount; ++i)
        {
            bool hitLight = true;
            if(Intersect_Scene(p, dir, i == 0u, /*out:*/ t, N, color, hitLight))
            {
                if(t == 0.0) break;
                
                p += dir * t;
                p += N * 0.0001;
                p -= dir * min(t*0.5, 0.0001);

                vec3 V = -dir;

                vec3 albedo, F0; float roughness;
                {
                    float metalness = 0.0;
                    float reflectance = 0.5;
                    
                   #if 0
                    vec3 fp = fract(p);
                    
                    float s = 0.01;
                    bool m;
                    m =      (fp.x < s || fp.x > 1.0 - s || fp.y < s || fp.y > 1.0 - s);   
                    m = m && (fp.x < s || fp.x > 1.0 - s || fp.z < s || fp.z > 1.0 - s);   
                    m = m && (fp.z < s || fp.z > 1.0 - s || fp.y < s || fp.y > 1.0 - s);   

                    color *= m ? 0.0 : 1.0;
				   #endif
                    
                    vec3 fp2 = fract((p - N * 0.001) * 0.5);
                    bvec3 m2 = greaterThan(fp2, vec3(0.5));

                    bool checker = m2.x != m2.y != m2.z;

                    if((p.x > 0.0) != (p.y > 0.0) != (p.z > 0.0))
                    {
                        metalness = 1.0;
                        //color = mix(color, vec3(1.0), 0.2);
                        //roughness *= 0.5;
                        roughness = 0.7;

                        roughness = checker ? 0.4 : 0.1;

                    }
                    else
                    {
                        roughness = checker ? 0.6 : 0.1;
                    }
                    //alpha = 0.02;
            
					color = MapColor(color);
                    
					ConvertMtlParams(color, reflectance, metalness, /*out*/ albedo, /*out*/ F0);
                }
                
                // -------------------------------------------------------------------------------------------------------------

               #if 0
                // implicit light sampling (for verification)
                if(hitLight == true)
                {
                    col += W * Radiance;

                    break;
                }

               #else

                if(hitLight == true)
                {
                    if(i == 0u) 
                    col += W * Radiance;

                    break;
                }

               #if 0

                // make sure LightPos is not inside scene geometry when using this
                col += Sample_PointLight(V, p, N, albedo, roughness, F0) * W;

               #elif 0

                col += Sample_DirLight(V, p, N, normalize(vec3(1.0, 1.0, 1.0)), albedo, roughness, F0) * W;

               #elif 0

                //col += Sample_SphLight_HemiSph(V, p, N, /*inout*/ h, albedo, roughness, F0) * W;      
                col += Sample_SphLight_ClmpCos(V, p, N, /*inout*/ h, albedo, roughness, F0) * W;      

               #elif 0

                col += Sample_SphLight_SolidAngle(Hash01x2(h), V, p, N, albedo, roughness, F0) * W;      

               #elif 1
                {
                    vec2  s0 = Hash01x2(h);
                    vec2  s1 = Hash01x2(h);
                    
                   #ifdef USE_LDS
                    if(i == 0u)
                    {
                        s0 = Float01(Roberts(hh ^ 0xFA760509u, frameNum));
                        s1 = Float01(Roberts(hh ^ 0x82DD24D6u, frameNum));
                    }
                   #endif
                    
                	col += Sample_SphLight_MIS(s0, s1, V, p, N, albedo, roughness, F0) * W;      
                }   
               #elif 1
                {
                    vec2  s0 = Hash01x2(h);
                    vec2  s1 = Hash01x2(h);
                    float s2 = Hash01(h);
                    
                   #ifdef USE_LDS
                    if(i == 0u)
                    {
                        s0 = Float01(Roberts(hh   ^ 0xFA760509u, frameNum));
                        s1 = Float01(Roberts(hh   ^ 0x82DD24D6u, frameNum));
                        s2 = Float01(Roberts(hh.x ^ 0x2FE84799u, frameNum));
                    }
                   #endif
                    
                	col += Sample_SphLight_MIS2(s0, s1, s2, V, p, N, albedo, roughness, F0) * W;      
                }
               #endif
               #endif


                {
                    vec2  s0 = Hash01x2(h);
                    vec2  s1 = Hash01x2(h);
                    float s2 = Hash01(h);
                    
                   #ifdef USE_LDS
                    if(i == 0u)
                    {
                        s0 = Float01(Roberts(hh   ^ 0x8CF64DC5u, frameNum));
                        s1 = Float01(Roberts(hh   ^ 0xFED0592Du, frameNum));
                        s2 = Float01(Roberts(hh.x ^ 0xAEDF2BF3u, frameNum));
                    }
                   #endif
                    
                   #if 1
                    // appears to work better than the MIS version
                    Sample_ScatteredDir(s0, s1, s2, /*inout*/dir, /*inout*/W, N, albedo, roughness, F0);
                   #else
                    Sample_ScatteredDirMIS(s0, s1, s2, /*inout*/dir, /*inout*/W, N, albedo, roughness, F0);
                   #endif
                }
            } 
            else 
            {
				// sample sky box

                break;
            }
        }
    } 
    else 
    {
		// sample sky box
    }
    
    vec3 colLast = textureLod(iChannel0, uvO.xy / iResolution.xy, 0.0).rgb;
    
    col = mix(colLast, col, 1.0 / (frameAccu + 1.0));    
    
    outCol = vec4(col, 0.0);
    
    
    {
        // persistent state stuff:
        vec4 iMouseLast     = ReadVar4(0, 0);
        vec4 iMouseAccuLast = ReadVar4(1, 0);
        vec4 wasdAccuLast   = ReadVar4(2, 0);
        float frameAccuLast = ReadVar (3, 0);


        bool shift = ReadKey(KEY_SHIFT) != 0.0;

        float kW = ReadKey(KEY_W);
        float kA = ReadKey(KEY_A);
        float kS = ReadKey(KEY_S);
        float kD = ReadKey(KEY_D);

        float left  = ReadKey(KEY_LEFT);
        float right = ReadKey(KEY_RIGHT);
        float up    = ReadKey(KEY_UP);
        float down  = ReadKey(KEY_DOWN);
        
        
        bool anyK = false;
        
        anyK = anyK || iMouse.z > 0.0;
        anyK = anyK || shift;
        anyK = anyK || kW != 0.0;
        anyK = anyK || kA != 0.0;
        anyK = anyK || kS != 0.0;
        anyK = anyK || kD != 0.0;
        anyK = anyK || left  != 0.0;
        anyK = anyK || right != 0.0;
        anyK = anyK || up    != 0.0;
        anyK = anyK || down  != 0.0;
        
        
        frameAccuLast += 1.0;
        if(anyK) frameAccuLast = 0.0;
        

        vec4 wasdAccu = wasdAccuLast;
        wasdAccu += vec4(kW, kA, kS, kD);
        wasdAccu += vec4(up, left, down, right);        

        
        vec2 mouseDelta = iMouse.xy - iMouseLast.xy;

        bool cond0 = iMouse.z > 0.0 && iMouseLast.z > 0.0;
        vec2 mouseDelta2 = cond0 && !shift ? mouseDelta.xy : vec2(0.0);
        vec2 mouseDelta3 = cond0 &&  shift ? mouseDelta.xy : vec2(0.0);

        vec4 iMouseAccu = iMouseAccuLast + vec4(mouseDelta2, mouseDelta3);

        
        WriteVar4(iMouse,        0, 0);
        WriteVar4(iMouseAccu,    1, 0);
        WriteVar4(wasdAccu,      2, 0);
        WriteVar (frameAccuLast, 3, 0);
    }
}