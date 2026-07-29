// Image (image) — Curve fitting by Dave_Hoskins
// https://www.shadertoy.com/view/MsXGDj

// Curve fitting
// A Bunch of 1D curve fitting functions. 7,8,9 appear to be the same,
// I didn't make them from first principles.

// Replace float points with vectors for more dimensions.
//
// Feel free to use them anywhere you want.
// Dave H.




#define Use_Linear 1
#define Use_Cosine 2
#define Use_Smoothstep 3
#define Use_Smoothstep2 4
#define Use_Cubic 5
#define Use_Hermite 6
#define Use_ThirdOrderSpline 7
#define Use_Catmull_Rom 8
#define Centripetal_Catmull_Rom 9
#define end 10

// Font stuff first...
#define C(c) O+= char(F,c) ; F.x-=.5
float char(vec2 p, int c) 
{
    if (p.x<.0|| p.x>=1. || p.y<0.|| p.y>=1.) return 0.;
	return textureGrad( iChannel0, p/16. + fract( vec2(c, 15-c/16) / 16. ), dFdx(p/16.),dFdy(p/16.) ).x;
}

#define __ F.x-=.25
#define _A C(65)
#define _B C(66)
#define _C C(67)
#define _D C(68)
#define _E C(69)
#define _F C(70)
#define _G C(71)
#define _H C(72)
#define _I C(73)
#define _J C(74)
#define _K C(75)
#define _L C(76)
#define _M C(77)
#define _N C(78)
#define _O C(79)
#define _P C(80)
#define _Q C(81)
#define _R C(82)
#define _S C(83)
#define _T C(84)
#define _U C(85)
#define _V C(86)
#define _W C(87)
#define _X C(88)
#define _Y C(89)
#define _Z C(90)
#define _0 C(48)
#define _1 C(49)
#define _2 C(50)
#define _3 C(51)
#define _4 C(52)
#define _5 C(53)
#define _6 C(54)
#define _7 C(55)
#define _8 C(56)
#define _9 C(57)
#define _DASH C(45)
//.. End Font stuff



// Most of these functions use the following format:

// v0----v1--x--v2----v3

// Where 'x' is the fractional diff between v1 and v2.

//--------------------------------------------------------------------------------
//  1 out, 1 in...
float Hash(float p)
{
	vec3 p3  = fract(vec3(p) * .1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

//--------------------------------------------------------------------------------
float Cubic(float x, float v0,float v1, float v2,float v3) 
{
	float p = (v3 - v2) - (v0 - v1);
	return p*(x*x*x) + ((v0 - v1) - p)*(x*x) + (v2 - v0)*x + v1;
}

//--------------------------------------------------------------------------------
float Catmull_Rom(float x, float v0,float v1, float v2,float v3) 
{
	float c2 = -.5 * v0	+ 0.5*v2;
	float c3 = v0		+ -2.5*v1 + 2.0*v2 + -.5*v3;
	float c4 = -.5 * v0	+ 1.5*v1 + -1.5*v2 + 0.5*v3;
	return(((c4 * x + c3) * x + c2) * x + v1);
	
//	Or, the same result with...
//	float x2 = x  * x;
//	float x3 = x2 * x;
//	return 0.5 * ( ( 2.0 * v1) + (-v0 + v2) * x +
//                  (2.0 * v0 - 5.0 *v1 + 4.0 * v2 - v3) * x2 +
//                  (-v0 + 3.0*v1 - 3.0 *v2 + v3) * x3);
}



float Centripetal_Catmull_Rom_Coefficient(float x, float p0,float p1, float p2,float p3) 
{
	float a = p1;
	float b = 0.5 * (p2 - p0);
	float c = p0 - 2.5 * p1 + 2.0 * p2 - 0.5 * p3;
        float d = 1.5 * (p1 - p2) + 0.5 * (p3 - p0);
	return(a + x*(b + x*(c + x*d)));
}


//--------------------------------------------------------------------------------
float ThirdOrderSpline(float x, float L1,float L0, float H0,float H1) 
{
	return 		  L0 +.5 *
			x * ( H0-L1 +
			x * ( H0 + L0 * -2.0 +  L1 +
			x * ((H0 - L0)* 9.0	 + (L1 - H1)*3.0 +
			x * ((L0 - H0)* 15.0 + (H1 - L1)*5.0 +
			x * ((H0 - L0)* 6.0	 + (L1 - H1)*2.0 )))));
}

//--------------------------------------------------------------------------------
float Cosine(float x, float v0, float v1) 
{
	x = (1.0-cos(x*3.1415927)) * .5;
	return (v1-v0)*x + v0;
}

//--------------------------------------------------------------------------------
float Linear(float x, float v0, float v1) 
{
	return (v1-v0)*x + v0;
}

//--------------------------------------------------------------------------------
float Smoothstep(float x, float v0, float v1) 
{
	x = x*x*(3.0-2.0*x);
	return (v1-v0)*x + v0;
}

//--------------------------------------------------------------------------------
float Smoothstep2(float x, float v0, float v1) 
{
    x = x*x*x*(x*(x*6.0-15.0)+10.0);
    return (v1-v0)*x + v0;
}

//--------------------------------------------------------------------------------
float Hermite(float x, float a, float b, float c, float d)
{
    float e = c-b;
    float f = a-d;
    return(b+.5*x*(e+b-a+x*(a-b+e+x*3.*(e*3.+f+x*5./3.*(-e*3.-f+x*.4*(e*3.+f))))));
}
float hermiteThird(float x, float y0, float y1, float y2, float y3)
{
    // 4-point, 3rd-order Hermite (x-form)
    float c0 = y1;
    float c1 = 0.5 * (y2 - y0);
    float c3 = 1.5 * (y1 - y2) + 0.5 * (y3 - y0);
    float c2 = y0 - y1 + c1 - c3;

    return ((c3 * x + c2) * x + c1) * x + c0;
}

//================================================================================
void mainImage( out vec4 outCol, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.y;
    float O = 0.0;	
    vec2 F = uv*12.-.25;
	float pos = (iTime*.2 +uv.x) * 6.0;
	float x  = fract(pos);
	float v0 = Hash(floor(pos));
	float v1 = Hash(floor(pos)+1.0);
	float v2 = Hash(floor(pos)+2.0);
	float v3 = Hash(floor(pos)+3.0);
	float f;
    int wh = 1+int(iTime*.5) % (end-1);
    // Or use mouse X if available...
    if (iMouse.z > 0.) wh = 1+int(float(end-1)*iMouse.x/iResolution.x);
    
    switch (wh)
    {
        case Use_Linear:
            f = Linear(x, v1, v2);
            _1;__;_L; _I; _N; _E; _A; _R;
            break;
        case Use_Cosine:
            f = Cosine(x, v1, v2);
            _2;__;_C; _O; _S; _I; _N; _E;
            break;
        case Use_Smoothstep:
            f = Smoothstep(x, v1, v2);
            _3;__;_S; _M; _O; _O; _T; _H; _S; _T; _E; _P;
            break;
        case Use_Smoothstep2:
            f = Smoothstep2(x, v1, v2);
            _4;__;_S; _M; _O; _O; _T; _H; _S; _T; _E; _P;__; _2;
            break;
        case Use_Cubic:
            f = Cubic(x, v0, v1, v2, v3);
            _5;__;_C; _U;_B;_I;_C;
            break;
        case Use_Hermite:
            f = Hermite(x, v0, v1, v2, v3);
            _6;__;_H;_E;_R;_M;_I;_T;_E;
            break;
        case Use_ThirdOrderSpline:
            f = ThirdOrderSpline(x, v0, v1, v2, v3);
            _7;__;_T;_H;_I;_R;_D;__;_O;_R;_D;_E;_R;__;_S;_P;_L;_I;_N;_E;
            break;
        case Use_Catmull_Rom:
            f = Catmull_Rom(x, v0, v1, v2, v3);
            _8;__;_C;_A;_T;_M;_U;_L;_L;_DASH;_R;_O;_M;
            break;
        case Centripetal_Catmull_Rom:
            f = Centripetal_Catmull_Rom_Coefficient(x, v0, v1, v2, v3);
            _9;__;_C;_E;_N;_T;__;_C;_A;_T;_M;_U;_L;_L;_DASH;_R;_O;_M;
            break;
    }
          

//--------------------------------------------------------------------------------

	// Blobs...
	f = .02 / abs(f-uv.y);
	float d = .03/length((vec2(((uv.x)/9.0*.25), uv.y)-vec2(x+.03, v1)) * vec2(.25,1.0));
	f = max(f, d*d*d);
    d = .03 / length((vec2(((uv.x)/9.0*.25), uv.y)-vec2(x-.97, v2)) * vec2(.25,1.0));
	f = max(f, d*d);
    
    // Output font + coloured line...
	outCol = vec4(O +vec3(1.0,.2, .05) * f, 1.0);
}