// Image (image) — Panini Projection by TinyTexel
// https://www.shadertoy.com/view/Wt3fzB

// License: CC0 (https://creativecommons.org/publicdomain/zero/1.0/)

/*
panini/pannini projection: http://tksharpless.net/vedutismo/Pannini/panini.pdf
camera controls via mouse + shift key

top knob - fov
bot knob - d (for d=0 projection becomes rectilinear/vanilla perspective)

Related:
    https://www.shadertoy.com/view/tt3BRS - "Panini Projection Visualization" (simple visualization of the projection)
*/
    
#define VarTex iChannel0
#define OutCol col
#define OutChannel w

#define WriteVar(v, cx, cy) {if(uv.x == float(cx) && uv.y == float(cy)) OutCol.OutChannel = v;}
#define WriteVar4(v, cx, cy) {WriteVar(v.x, cx, cy) WriteVar(v.y, cx, cy + 1) WriteVar(v.z, cx, cy + 2) WriteVar(v.w, cx, cy + 3)}

float ReadVar(int cx, int cy) {return texelFetch(VarTex, ivec2(cx, cy), 0).OutChannel;}
vec2 ReadVar2(int cx, int cy) {return vec2(ReadVar(cx, cy), ReadVar(cx, cy + 1));}
vec3 ReadVar3(int cx, int cy) {return vec3(ReadVar(cx, cy), ReadVar(cx, cy + 1), ReadVar(cx, cy + 2));}
vec4 ReadVar4(int cx, int cy) {return vec4(ReadVar(cx, cy), ReadVar(cx, cy + 1), ReadVar(cx, cy + 2), ReadVar(cx, cy + 3));}

float ReadVar(inout int x) { return ReadVar(x++, 0); }
vec2 ReadVar2(inout int x) { return ReadVar2(x++, 0); }
vec3 ReadVar3(inout int x) { return ReadVar3(x++, 0); }
vec4 ReadVar4(inout int x) { return ReadVar4(x++, 0); }

vec4 A, B, C, D;


bool map0(vec3 p)
{
    p += 0.5;
    vec3 b = abs(p);
    
    bool r;
    
    r =      b.x < 4.0;
    r = r && b.y < 4.0;
    r = r && b.z < 4.0;
    
    r = r && (b.x > 2.0 || b.y > 2.0);
    r = r && (b.z > 2.0 || b.y > 2.0);
    r = r && (b.x > 2.0 || b.z > 2.0);    
    
    return r;
}

bool map(vec3 p)
{
    float o = 2.0; 
    
    return map0(p + vec3( -o, 0.0, 0.0)) != 
           map0(p + vec3(  o, 0.0, 0.0)) != 
           map0(p + vec3(0.0,  -o, 0.0)) != 
           map0(p + vec3(0.0,   o, 0.0)) != 
           map0(p + vec3(0.0, 0.0,  -o)) != 
           map0(p + vec3(0.0, 0.0,   o));
}

vec3 minmask(vec3 v)
{
    return vec3(v.x <= v.y && v.x <= v.z,
                v.y <  v.z && v.y <  v.x,
                v.z <  v.x && v.z <= v.y);
}

// https://www.shadertoy.com/view/3s23Ww
bool VoxelRaycast(vec3 ro, vec3 rd, out vec3 vp, out vec3 N, out float t)
{
	vp = floor(ro);
	
    vec3 ri = 1.0/rd;
    
	vec3 rs = vec3(rd.x < 0.0 ? -1.0 : 1.0,
                   rd.y < 0.0 ? -1.0 : 1.0,
                   rd.z < 0.0 ? -1.0 : 1.0);
                     
	vec3 off = vec3(rd.x < 0.0 ? 0.0 : ri.x,
                    rd.y < 0.0 ? 0.0 : ri.y,
                    rd.z < 0.0 ? 0.0 : ri.z) - ro * ri;

	vec3 mm = vec3(0.0);
    vec3 t3 = vec3(0.0);
    
	bool hit = false;
	for(int i = 0; i < 24; i++) 
	{
		if(map(vp)) { hit = true; break; }
        
        t3 = vp * ri + off;
		
        mm = minmask(t3);
        
        vp += mm * rs;
	}
	
	N = -rs * mm;
    t = dot(t3, mm);

	return hit;
}

bool SceneRayCast(vec3 rp, vec3 rd, out vec3 c, out vec3 n, out vec3 p)
{
    vec3 vp; float t;
	bool hit = VoxelRaycast(rp, rd, /*out:*/ vp, n, t);
    
    if(hit)
    {
        p = rp + rd * t;
        
        vec3 fm = abs(n);
        
        p = mix(p, round(p), equal(fm, vec3(1.0))) + (n * 1e-5);

        bvec3 b = greaterThan(abs(fract(p) - 0.5), vec3(0.45));
        float wf = ((b.z && (b.x || b.y)) || (b.x && (b.y || b.z)) ? 0.0 : 1.0);

        c = (fm + fm.yzx*0.125) * wf;
    }

   #if 0
    vec2 tt;
    if(Intersect_Ray_Sphere(rp, rd, vec3(0.0), 0.5, tt) > 0.0 && (tt.x < t || !hit))
    {
        hit = true;
        t = tt.x;
        
        p = rp + rd * t;
        
        n = normalize(p);
        
        p += n * 1.0/512.0;
        
        c = vec3(1.0, 0.5, 0.0);
    }
   #endif
    
    return hit;
}


// tc ∈ [-1,1]² | fov ∈ [0, π) | d ∈ [0,1]
vec3 PaniniProjection(vec2 tc, float fov, float d)
{
    float d2 = d*d;

    {
        float fo = Pi05 - fov * 0.5;

        float f = cos(fo)/sin(fo) * 2.0;
        float f2 = f*f;

        float b = (sqrt(max(0.0, Pow2(d+d2)*(f2+f2*f2))) - (d*f+f)) / (d2+d2*f2-1.0);

        tc *= b;
    }
    
    /* http://tksharpless.net/vedutismo/Pannini/panini.pdf */
    float h = tc.x;
    float v = tc.y;
    
    float h2 = h*h;
    
    float k = h2/Pow2(d+1.0);
    float k2 = k*k;
    
    float discr = max(0.0, k2*d2 - (k+1.0)*(k*d2-1.0));
    
    float cosPhi = (-k*d+sqrt(discr))/(k+1.0);
    float S = (d+1.0)/(d+cosPhi);
    float tanTheta = v/S;
    
    float sinPhi = sqrt(max(0.0, 1.0-Pow2(cosPhi)));
    if(tc.x < 0.0) sinPhi *= -1.0;
    
    float s = inversesqrt(1.0+Pow2(tanTheta));
    
    return vec3(sinPhi, tanTheta, cosPhi) * s;
}


vec3 EvalSceneCol(vec3 rp, mat3 cmat, vec2 uv)
{    
    vec3 col = vec3(0.8);  
    
    vec2 tc = uv * (1.0 / (iResolution.xx*0.5)) - vec2(1.0, iResolution.y/iResolution.x);
    

    vec3 rd;
    {
        float fov = min(A.x, 0.999999) * Pi;
        float d = B.x;

        rd = cmat * PaniniProjection(tc, fov, d);
        //rd = normalize(cmat * vec3(tc, 0.5 * tan(Pi05 - fov * 0.5))); 
    }
    
    
#if 1
    vec2 tt; 
    float res = Intersect_Ray_Cube(rp, rd, vec3(6.0 + 1e-5), /*out:*/ tt);
    
    if(res == -1.0) { return col; }
    
    if(res == 1.0)
    {
    	rp += rd * tt.x;
    }
#endif
    
	vec3 c, n, p;
    if(SceneRayCast(rp, rd, /*out:*/ c, n, p))
    {
        vec3 r = n * (2.0 * dot(n, -rd)) + rd;
        
        col = c;
        
        vec3 n0;
        if(!SceneRayCast(p, r, /*out:*/ c, n0, p)) {c = vec3(0.8);}
        
        col = mix(col, c, mix(0.05, 1.0, Pow5(1.0 - dot(-rd, n))));
    }

    return col;
}


void mainImage(out vec4 outCol, in vec2 uv0)
{
    Resolution = iResolution;
    
    vec3 col = vec3(0.0);
    vec2 uv = uv0.xy - 0.5;
    
    int I = 0;
    vec4 iMouse     = ReadVar4(I);
    vec4 mouseAccu  = ReadVar4(I);
    vec4 wasdAccu   = ReadVar4(I);
    float frameAccu = ReadVar (I);
    float knobVal   = ReadVar (I);

    A.x = texelFetch(iChannel0, ivec2(0, 4), 0).w;
    //A.y = texelFetch(iChannel0, ivec2(1, 4), 0).w;
    //A.z = texelFetch(iChannel0, ivec2(2, 4), 0).w;
    //A.w = texelFetch(iChannel0, ivec2(3, 4), 0).w;

    B.x = texelFetch(iChannel0, ivec2(4, 4), 0).w;
    //B.y = texelFetch(iChannel0, ivec2(5, 4), 0).w;
    //B.z = texelFetch(iChannel0, ivec2(6, 4), 0).w;
    //B.w = texelFetch(iChannel0, ivec2(7, 4), 0).w;

    //C.x = texelFetch(iChannel0, ivec2( 8, 4), 0).w;
    //C.y = texelFetch(iChannel0, ivec2( 9, 4), 0).w;
    //C.z = texelFetch(iChannel0, ivec2(10, 4), 0).w;
    //C.w = texelFetch(iChannel0, ivec2(11, 4), 0).w;

    //D.x = texelFetch(iChannel0, ivec2(12, 4), 0).w;
    //D.y = texelFetch(iChannel0, ivec2(13, 4), 0).w;
    //D.z = texelFetch(iChannel0, ivec2(14, 4), 0).w;
    //D.w = texelFetch(iChannel0, ivec2(15, 4), 0).w;
        
    vec2 ang = vec2(-0.1 * Pi, -Pi * 0.1);
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
    
    vec3 cpos = -cmat[2] * exp2(1.5 + mouseAccu.w * 0.02);
    

#if 0
    // 1 sample
    col = vec3(EvalSceneCol(cpos, cmat, uv0));
#elif 1
    // 3 samples ( https://www.shadertoy.com/view/3tdBWM )
    uvec2 uvi = uvec2(uv);
    if(((uvi.x ^ uvi.y) & 4u) == 0u) uvi   = uvi.yx;
	if(((uvi.x        ) & 4u) == 0u) uvi.x =-uvi.x;

    // constants of the 2d Roberts sequence
    const uint r0 = 3242174893u;
    const uint r1 = 2447445397u;

    float u = float((uvi.x * r0) + (uvi.y * r1)) * (1.0 / 4294967296.0);

    if((uint(iFrame) & 1u) != 0u) u += 0.5;

    for(float i = 0.0; i < 3.0; ++i) 
    {
        float ang = (Pi*0.666667) * (i+u);
        
        vec2 off = vec2(cos(ang), sin(ang))*0.333333;

        col += vec3(EvalSceneCol(cpos, cmat, uv0 + off));
    }
    col *= 0.333333; 
#endif

#if 1
if(uv.x < 48.0*1.0 && abs(uv.y - iResolution.y*0.5) < 48.0 ||
   uv.x < 64.0 && uv.y < 16.0)
{    
    // knobs
    vec2 ui = texelFetch(iChannel0, ivec2(uv), 0).xy;
    
    col *= 1.0-ui.y;
    col = mix(col, vec3(0.03), ui.x);
}
#endif

#if 1
{
    // vignetting
    vec2 s = abs(uv0/iResolution.xy*2.0-1.0);
    s.x = 1.0-Pow3(s.x);    s.y = 1.0-Pow3(s.y);
    col *= mix(1.0, 0.4, Pow2(1.0-sqrt(s.x*s.y)));
}
#endif
    
	outCol = vec4(GammaEncode(clamp01(col)), 1.0);
}
