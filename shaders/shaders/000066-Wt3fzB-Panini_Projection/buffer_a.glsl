// Buffer A (buffer) — Panini Projection by TinyTexel
// https://www.shadertoy.com/view/Wt3fzB

// License: CC0 (https://creativecommons.org/publicdomain/zero/1.0/)

/* persistent state stuff and knobs */

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
#define OutCol col
#define OutChannel w

#define WRITEVAR(v, cx, cy) {if(uv.x == float(cx) && uv.y == float(cy)) OutCol.OutChannel = v;}
#define WRITEVAR2(v, cx, cy) {WRITEVAR(v.x, cx, cy) WRITEVAR(v.y, cx, cy + 1)}
#define WRITEVAR3(v, cx, cy) {WRITEVAR(v.x, cx, cy) WRITEVAR(v.y, cx, cy + 1) WRITEVAR(v.z, cx, cy + 2)}
#define WRITEVAR4(v, cx, cy) {WRITEVAR(v.x, cx, cy) WRITEVAR(v.y, cx, cy + 1) WRITEVAR(v.z, cx, cy + 2) WRITEVAR(v.w, cx, cy + 3)}

#define WriteVar(v, x) {WRITEVAR(v, x, 0) ++x;}
#define WriteVar2(v, x) {WRITEVAR2(v, x, 0) ++x;}
#define WriteVar3(v, x) {WRITEVAR3(v, x, 0) ++x;}
#define WriteVar4(v, x) {WRITEVAR4(v, x, 0) ++x;}

float ReadVar(int cx, int cy) {return texelFetch(VarTex, ivec2(cx, cy), 0).OutChannel;}
vec2 ReadVar2(int cx, int cy) {return vec2(ReadVar(cx, cy), ReadVar(cx, cy + 1));}
vec3 ReadVar3(int cx, int cy) {return vec3(ReadVar(cx, cy), ReadVar(cx, cy + 1), ReadVar(cx, cy + 2));}
vec4 ReadVar4(int cx, int cy) {return vec4(ReadVar(cx, cy), ReadVar(cx, cy + 1), ReadVar(cx, cy + 2), ReadVar(cx, cy + 3));}

float ReadVar(inout int x) { return ReadVar(x++, 0); }
vec2 ReadVar2(inout int x) { return ReadVar2(x++, 0); }
vec3 ReadVar3(inout int x) { return ReadVar3(x++, 0); }
vec4 ReadVar4(inout int x) { return ReadVar4(x++, 0); }

vec2 Knob(vec2 uv, KnobState state)
{
    uv -= state.p;
    
    float v = 0.0;
    
    float l = length(uv);
    
    v = abs(l - (state.r.x - state.r.y)) - state.r.y;
    
    float sh = 1.0;
    sh = clamp01(v * 0.15);
    sh = 1.0-(1.0-sh)*(1.0-sh);
    sh = mix(0.85, 1.0, sh);
    v = clamp01(v);
    
    v = 1.0 - v;
    float o;
    {
        float a = state.n;

        bool tc = state.signed;
        if(tc) a = a * 0.5 + 0.5;
        a *= 2.0;
        bool ac = a > 1.0;
        float m = clamp01((ac ? uv.x : -uv.x)+0.5);
        if(ac) a = a - 1.0;

        m = min(m, clamp01((tc ? 1.0 : -1.0) * dot(AngToVec((1.0-a)*Pi), uv)+0.5));
        if(!tc && ac) m = 1.0-m;
       
        o = m;
    }
    
    float r = v;
    r = v * mix(0.15, 0.95, o);

    if(state.signed && uv.x < 0.0) { r = v * mix(0.06, 0.6, o);}
    return vec2(r, sh);
}

// https://www.shadertoy.com/view/4tfBzn
float TextSDF(vec2 p, float glyph)
{
    p = abs(p.x - .5) > .5 || abs(p.y - .5) > .5 ? vec2(0.) : p;
    return 2. * (texture(iChannel3, p / 16. + fract(vec2(glyph, 15. - floor(glyph / 16.)) / 16.)).w - 127. / 255.);
}

void ValueText(inout vec4 col, vec2 uv0, float n)
{
    vec2 p = uv0 * 0.5;
    
    vec2 scale = vec2(4., 8.);
    vec2 t = floor(p / scale);   

    if(t.x < 0.0 || t.x > 5.0 || t.y != 0.0) return;
    if((n == 0.0 || abs(n) == 1.0) && t.x > 1.0) return;
    if(t.x == 0.0 && n >= 0.0) return;
    

    float c = 0.0;
    
    if(t.x == 0.0) c = 45.0;
    else if(t.x == 1.0) c = n == 0.0 ? 48.0 : (abs(n) == 1.0 ? 49.0 : 46.0);
    else
    c = abs(n) == 1.0 ? 48.0 : 48.0 + mod(floor(abs(n)*1000.0 * exp2((4.0-t.x) * -(log2(10.0)/log2(2.0)))), 10.0);

    p = (p - t * scale) / scale;
    p.x = (p.x - 0.5) * 0.5 + 0.5;

    if (c == 0.) return;
    
    float sdf = TextSDF(p, c);
    
    sdf = smoothstep(-0.05, 0.05, sdf);

    col.r = (1.0 - sdf) * 0.75;
}


void mainImage( out vec4 col, in vec2 uv0 )
{  
    Resolution = iResolution;
    
    col = vec4(0.0);
    vec2 uv = uv0 - 0.5;
   
    
    //if(uv.y > 5.0) return;
    
    int I = 0;
    vec4 iMouseLast     = ReadVar4(I);
    vec4 iMouseAccuLast = ReadVar4(I);
    vec4 wasdAccuLast   = ReadVar4(I);
    float frameAccuLast = ReadVar (I);
    float knobVal       = ReadVar (I);
    //KnobState stateLast = ReadKnobState(I);
    
    vec2 iMouseClick    = ReadVar2(I);
    
    
    bool isClick = iMouseLast.z < 0.0 && iMouse.z >= 0.0;
    
    if(isClick) iMouseClick = iMouse.xy;
    
    bool shift = ReadKey(KEY_SHIFT) != 0.0;
    
    float kW = ReadKey(KEY_W);
    float kA = ReadKey(KEY_A);
    float kS = ReadKey(KEY_S);
    float kD = ReadKey(KEY_D);
    
    float left  = ReadKey(KEY_LEFT);
    float right = ReadKey(KEY_RIGHT);
    float up    = ReadKey(KEY_UP);
    float down  = ReadKey(KEY_DOWN);
    
    vec2 mouseDelta = iMouse.xy - iMouseLast.xy;
    
    bool didInteractUI = false;
    
    float knopMouseDelta = mouseDelta.y * (1.0 / 96.0 * (shift ? 0.125 : 1.0));
     
    if(uv.y == 4.0)
    {
        KnobState knob;
    	if(GetKnob(int(uv.x), iChannel0, frameAccuLast == 0.0, /*out*/ knob))
        {
            if(!isClick)
            if(SqrLen(iMouseClick.xy - knob.p) < Pow2(knob.r.x))
            {
                knobVal = knob.n = clamp(knob.n + knopMouseDelta * (knob.signed ? 2.0 : 1.0), knob.signed ? -1.0 : 0.0, 1.0);
                didInteractUI = true;
            }

            col.w = knob.n;
        }
    }
    
    float knobVal0 = 0.0;
    {
        KnobState knob; int i;
        if((i = GetKnob(iMouseClick.xy, iChannel0, /*out*/ knob)) >= 0)
        {
            knobVal0 = knob.n;
            didInteractUI = true;
        }
        
        //if(uv.y != 4.0) knobVal0 = knobVal;
    }
    
    {
        KnobState state;
        bool isKnob = GetKnob(uv0, iChannel0, frameAccuLast == 0.0, /*out*/ state) >= 0;

        if(isKnob)
        {
            vec2 k = Knob(uv0, state);
            col.xy = vec2(k.x, 1.0 - k.y);
        }
        
    	ValueText(col, uv0, knobVal0);
    }
    
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
    
    
    float frameAccu = frameAccuLast + 1.0;
    //if(anyK) frameAccu = 0.0;
    
    
    vec4 wasdAccu = wasdAccuLast;
    wasdAccu += vec4(kW, kA, kS, kD);
    wasdAccu += vec4(up, left, down, right);        
    
        
    bool cond0 = iMouse.z > 0.0 && iMouseLast.z > 0.0;
    cond0 = cond0 && !didInteractUI;
    
    vec2 mouseDelta2 = cond0 && !shift ? mouseDelta.xy : vec2(0.0);
    vec2 mouseDelta3 = cond0 &&  shift ? mouseDelta.xy : vec2(0.0);
    
    vec4 iMouseAccu = iMouseAccuLast + vec4(mouseDelta2, mouseDelta3);
    

    
    int J = 0;
    WriteVar4(iMouse,       J);
    WriteVar4(iMouseAccu,   J);
    WriteVar4(wasdAccu,     J);
    WriteVar(frameAccu,     J);
    WriteVar(knobVal,       J);
	//WriteKnobState(state, uv, col, J);

    WriteVar2(iMouseClick,  J);
}