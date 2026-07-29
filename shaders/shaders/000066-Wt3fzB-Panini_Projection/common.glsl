// Common (common) — Panini Projection by TinyTexel
// https://www.shadertoy.com/view/Wt3fzB

vec3 Resolution;

#define Frame float(iFrame)

#define rsqrt inversesqrt
#define clamp01(x) clamp(x, 0.0, 1.0)
#define If(cond, resT, resF) mix(resF, resT, cond)


const float Pi = 3.14159265359;
const float Pi2 = Pi * 2.0;
const float Pi05 = Pi * 0.5;

const float RcpPi  = 1.0 / (1.0 * Pi);
const float RcpPi2 = 1.0 / (2.0 * Pi);
const float RcpPi4 = 1.0 / (4.0 * Pi);

float Pow2(float x) {return x*x;}
float Pow3(float x) {return x*x*x;}
float Pow4(float x) {return Pow2(Pow2(x));}
float Pow5(float x) {return Pow4(x)*x;}

float SqrLen(float v) {return v * v;}
float SqrLen(vec2  v) {return dot(v, v);}
float SqrLen(vec3  v) {return dot(v, v);}
float SqrLen(vec4  v) {return dot(v, v);}

vec3 GammaEncode(vec3 x) {return pow(x, vec3(1.0 / 2.2));}   

vec2 AngToVec(float ang)
{	
	return vec2(cos(ang), sin(ang));
}

float Intersect_Ray_Cube(vec3 rp, vec3 rd, vec3 cth, out vec2 t)
{	
	vec3 m = 1.0 / -rd;
	vec3 o = If(lessThan(rd, vec3(0.0)), -cth, cth);
	
	vec3 uf = (rp + o) * m;
	vec3 ub = (rp - o) * m;
	
	t.x = max(uf.x, max(uf.y, uf.z));
	t.y = min(ub.x, min(ub.y, ub.z));
	
	bool inside = t.x < 0.0 && t.y > 0.0;
    
	if(inside) {return 0.0;}
	
	return t.y < t.x ? -1.0 : (t.x > 0.0 ? 1.0 : -1.0);
}

float Intersect_Ray_Sphere(
vec3 rp, vec3 rd, 
vec3 sp, float sr2, 
out vec2 t)
{	
	rp -= sp;
	
	float a = dot(rd, rd);
	float b = 2.0 * dot(rp, rd);
	float c = dot(rp, rp) - sr2;
	
	float D = b*b - 4.0*a*c;
	
	if(D < 0.0) return 0.0;
	
	float sqrtD = sqrt(D);
	// t = (-b + (c < 0.0 ? sqrtD : -sqrtD)) / a * 0.5;
	t = (-b + vec2(-sqrtD, sqrtD)) / a * 0.5;
	
	// if(start == inside) ...
	if(c < 0.0) t.xy = t.yx;

	// t.x > 0.0 || start == inside ? infront : behind
	return t.x > 0.0 || c < 0.0 ? 1.0 : -1.0;
}

// ============================================================================================================================= //
struct KnobState
{
    vec2 p;
    vec2 r;
    bool signed;
    
    float n;
};

KnobState CreateKnobState(vec2 p, vec2 r, bool signed, float n)
{
    KnobState state;
    state.p = p;
    state.r = r;
    state.signed = signed;
    state.n = n;

    return state;
}
    
KnobState GetKnobOfMat(int i, bool signed, float n)
{
    float x = float(uint(i) & 3u);
    float y = float(uint(i) >> 2u);
    
    float s = 32.0 + 8.0;
    
    KnobState knob;
    knob.p.x = s * 0.5 + x * s;
    knob.p.y = s * 0.5 + y * s;
    
    knob.p.y = Resolution.y*0.5 + (s*1.0) - knob.p.y;

    knob.r = vec2(16.0, 4.0);
    knob.signed = signed;
	knob.n = n;
    
    return knob;
}

const int KnobCount = 16;
bool GetKnob(int i, out KnobState knob)
{
    switch(i)
    {
        case  0: knob = GetKnobOfMat(i, false, 0.6667);  return true;// A.x
        //case  1: knob = GetKnobOfMat(i, false, 0.44); return true;// A.y
      //case  2: knob = GetKnobOfMat(i, false, 0.0); return true;// A.z
      //case  3: knob = GetKnobOfMat(i, false, 0.0); return true;// A.w
      
        case  4: knob = GetKnobOfMat(i, false, 0.75); return true;// B.x
      //  case  5: knob = GetKnobOfMat(i, false, 0.4); return true;// B.y
      //case  6: knob = GetKnobOfMat(i, false, 0.0); return true;// B.z
      //case  7: knob = GetKnobOfMat(i, false, 0.0); return true;// B.w
      
      //case  8: knob = GetKnobOfMat(i, false, 0.0); return true;// C.x
      //case  9: knob = GetKnobOfMat(i, false, 0.0); return true;// C.y
      //case 10: knob = GetKnobOfMat(i, false, 0.0); return true;// C.z
      //case 11: knob = GetKnobOfMat(i, false, 0.0); return true;// C.w
      
      //case 12: knob = GetKnobOfMat(i, false, 0.0); return true;// D.x
      //case 13: knob = GetKnobOfMat(i, false, 0.0); return true;// D.y
      //case 14: knob = GetKnobOfMat(i, false, 0.0); return true;// D.z
      //case 15: knob = GetKnobOfMat(i, false, 0.0); return true;// D.w
    }
    
    KnobState knob0;
    knob0.n = 1.25;
    knob = knob0;
    
    return false;
}

bool GetKnob(int i, sampler2D stateBuffer, bool doInit, out KnobState knob)
{
	if(!GetKnob(i, /*out*/ knob)) return false;

    if(!doInit)
    knob.n = texelFetch(stateBuffer, ivec2(i, 4), 0).w;
    
    return i < KnobCount;
}

bool GetKnob(int i, sampler2D stateBuffer, out KnobState knob)
{
    return GetKnob(i, stateBuffer, false, knob);
}

int GetKnob(vec2 uv, sampler2D stateBuffer, bool doInit, out KnobState knob)
{
    for(int i = 0; i < KnobCount; ++i)//TODO optimize loop away for knob array
    {
    	if(!GetKnob(i, /*out*/ knob)) continue;
        
        if(SqrLen(uv - knob.p) < Pow2(knob.r.x + 4.0))
        {
	        if(!doInit)
            knob.n = texelFetch(stateBuffer, ivec2(i, 4), 0).w;

            return i;
        }
    }
    
    return -1;
}

int GetKnob(vec2 uv, sampler2D stateBuffer, out KnobState knob)
{
    return GetKnob(uv, stateBuffer, false, /*out*/ knob);
}
