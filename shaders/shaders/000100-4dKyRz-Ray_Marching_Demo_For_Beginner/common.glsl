// Common (common) — Ray Marching Demo For Beginner by Trashe725
// https://www.shadertoy.com/view/4dKyRz


// bufA
// vec2(0 ~ 0.5, 0 ~ 0.5)
// 		r : draw map  (check box)
// 		g : draw start (check box)
// 		b : show end pos (check box)
//      a : fixed origin point (check box)

// bufB
// vec2(0.5 ~ 1, 0 ~ 0.5)
//		r : step count
//		g : fixed target point(check box)
//		b : key event
//		a : iMouse.z

// bufC
// vec2(0 ~ 0.5, 0.5 ~ 1)
//      r : key drag flag
//      g : map number
//      b : 
//      a :

// bufD
// vec2(0.5 ~ 1, 0.5 ~ 1)
//      r : origin.x
//      g : origin.y
//      b : target.x
//      a : target.y


// step limit
#define MAX_STEP_COUNT 25.
#define MIN_STEP_COUNT 0.


//map limit
#define MAX_MAP_COUNT 3.
#define MIN_MAP_COUNT 0.

// origin
#define ORI vec2(asp*0.5, 0.2)
// target
#define TAR vec2(-asp*0.4, -0.5)



//buf A
#define DRAW_MAP bufA.r
#define DRAW_START bufA.g
#define SHOW_TAR bufA.b
#define FIX_ORI bufA.a

//buf B
#define STEP_COUNT bufB.r
#define FIX_TAR bufB.g
#define KEY_EVENT bufB.b
#define P_MOUSE_Z bufB.a

//buf C
#define KEY_DRAG_FLAG bufC.r
#define MAP_NUM bufC.g

//buf D
#define ORIGIN bufD.rg
#define TARGET bufD.ba

//set offset
#define DEFAULT_SHOW 1

#if DEFAULT_SHOW
	#define STEP_COUNT_OFFSET 4.
	#define INVERSE(x) 1.-(x)
	#define ORIGIN_OFFSET ORI
	#define TARGET_OFFSET TAR
	#define MAP_OFFSET 0.
#else
	#define STEP_COUNT_OFFSET 0.
	#define INVERSE(x) (x)
	#define ORIGIN_OFFSET vec2(0.)
	#define TARGET_OFFSET vec2(0.)
	#define MAP_OFFSET 0.
#endif


// get/set function (with offset)
#define GET_STEP_COUNT STEP_COUNT+STEP_COUNT_OFFSET
#define SET_STEP_COUNT(x) STEP_COUNT=(x)-STEP_COUNT_OFFSET
#define GET_DRAW_MAP INVERSE(DRAW_MAP)
#define SET_DRAW_MAP(x) DRAW_MAP=INVERSE(x)
#define GET_DRAW_START INVERSE(DRAW_START)
#define SET_DRAW_START(x) DRAW_START=INVERSE(x)
#define GET_SHOW_TAR INVERSE(SHOW_TAR)
#define SET_SHOW_TAR(x) SHOW_TAR=INVERSE(x)
#define GET_ORIGIN ORIGIN+ORIGIN_OFFSET
#define SET_ORIGIN(x) ORIGIN=(x)-ORIGIN_OFFSET
#define GET_TARGET TARGET+TARGET_OFFSET
#define SET_TARGET(x) TARGET=(x)-TARGET_OFFSET
#define GET_MAP_NUM MAP_NUM+MAP_OFFSET
#define SET_MAP_NUM(x) MAP_NUM=(x)-MAP_OFFSET

vec4 blend(vec4 a, vec4 b)
{
	if(a.a == 0.)
    {
    	return b;
    }
    else
    {
    	return mix(a, b, b.a);
    }
}

vec2 cx_pow2(vec2 a)
{
	return vec2(a.x*a.x-a.y*a.y, 2.0*a.x*a.y);
}

bool is(float n)
{
	return n > 0.5;
}

float box(vec2 p, vec2 c, vec2 sz)
{
	vec2 d = abs(p-c) - sz;
  	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float triangle(vec2 p, vec2 a, vec2 b, vec2 c)
{
	vec2 e0 = b - a;
	vec2 e1 = c - b;
	vec2 e2 = a - c;

	vec2 v0 = p - a;
	vec2 v1 = p - b;
	vec2 v2 = p - c;

	vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
	vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
	vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min( min( vec2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                       vec2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                       vec2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));

	return -sqrt(d.x)*sign(d.y);
}

float circle(vec2 p, vec2 c, float r)
{
	return length(p-c) - r;
}

float line(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp( dot(pa, ba)/dot(ba, ba), 0., 1.);
    return length(pa - ba * h);
}

vec2 get_text_position(int ascii)
{
	int x = (ascii % 16);
    int y = 15-(ascii / 16);
    
    return vec2(float(x), float(y))*0.0625;
}

float get_text(vec2 uv, vec2 pos, int ascii, vec2 unit, sampler2D buf)
{
    vec2 p = clamp(uv-pos, -unit/2., unit/2.);
    p += unit/2.;
    p /= unit*16.;
    
    return smoothstep(0.55, 0.46, textureLod(buf, get_text_position(ascii)+p, 1.).a);
}

