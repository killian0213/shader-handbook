// Image (image) — OscilloStereoXY Trippy Donut  by ttoinou
// https://www.shadertoy.com/view/ldSfWV



vec3 sampleBuff(vec2 uv)
{
    return texture( iChannel0, uv ).xyz;// + vec3(.1); 
}

vec3 sampleBuff(float u,float v)
{
    return sampleBuff( vec2(u,v) ); 
}

// https://www.shadertoy.com/view/Ms23DR
// Loosely based on postprocessing shader by inigo quilez, License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec2 curve(vec2 uv)
{
    return uv;
	/*uv = (uv - 0.5) * 2.0;
	uv *= 1.1;	
	uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
	uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
	uv  = (uv / 2.0) + 0.5;
	uv =  uv *0.92 + 0.04;
	return uv;*/
}

vec4 crtBuffA( vec2 fragCoord )
{
    vec2 q = fragCoord.xy;// / iResolution.xy;
    vec2 uv = q;
    uv = curve( uv );
    vec3 oricol = sampleBuff(q.x,q.y);
    vec3 col;
	float x =  sin(0.3*iTime+uv.y*21.0)*sin(0.7*iTime+uv.y*29.0)*sin(0.3+0.33*iTime+uv.y*31.0)*0.0017;

    col.r = sampleBuff(x+uv.x+0.001,uv.y+0.001).x+0.05;
    col.g = sampleBuff(x+uv.x+0.000,uv.y-0.002).y+0.05;
    col.b = sampleBuff(x+uv.x-0.002,uv.y+0.000).z+0.05;
    col.r += 0.08*sampleBuff(0.75*vec2(x+0.025, -0.027)+vec2(uv.x+0.001,uv.y+0.001)).x;
    col.g += 0.05*sampleBuff(0.75*vec2(x+-0.022, -0.02)+vec2(uv.x+0.000,uv.y-0.002)).y;
    col.b += 0.08*sampleBuff(0.75*vec2(x+-0.02, -0.018)+vec2(uv.x-0.002,uv.y+0.000)).z;

    col = clamp(col*0.6+0.4*col*col*1.0,0.0,1.0);

    float vig = (0.0 + 1.0*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y));
	col *= vec3(pow(vig,0.3));

    col *= vec3(0.95,1.05,0.95);
	col *= 2.8;

	float scans = clamp( 0.35+0.35*sin(4.*iTime+uv.y*iResolution.y*1.), 0.0, 1.0);
	
	float s = pow(scans,1.7);
	col = col*vec3( 0.4+0.7*s) ;

    col *= 1.0+0.01*sin(50.0*iTime);
	if (uv.x < 0.0 || uv.x > 1.0)
		col *= 0.0;
	if (uv.y < 0.0 || uv.y > 1.0)
		col *= 0.0;
	
	col*=1.0-0.65*vec3(clamp((mod(fragCoord.x, 2.0)-1.0)*2.0,0.0,1.0));
	
    
    
    
    
    // from https://www.shadertoy.com/view/XsjSzc
    q = uv;

    float grid = 1.0;
    grid *= 1.0-smoothstep( 0.98, 0.99, 2.0*abs(fract( q.x*10.0 )-0.5) );
    grid *= 1.0-smoothstep( 0.96, 0.98, 2.0*abs(fract( q.y*6.0 )-0.5) );
    grid *= 1.0-smoothstep( 0.90, 0.92, 2.0*abs(fract( q.x*50.0 )-0.5) )*
                smoothstep( 0.84, 0.85, 2.0*abs(fract( q.y* 6.0 )-0.5) );
    grid *= 1.0-smoothstep( 0.91, 0.92, 2.0*abs(fract( q.y*30.0 )-0.5) )*
                smoothstep( 0.85, 0.86, 2.0*abs(fract( q.x*10.0 )-0.5) );
    col *= 0.5 + 0.5*grid;
    

    return vec4(col,1.0);
    
}

// https://www.shadertoy.com/view/lt2SDK
// ------------------------------------
//#define MOUSE_CURVE
//#define MOUSE_MOVE

#define MAIN_BLOOM_ITERATIONS 10
#define MAIN_BLOOM_SIZE 0.01

#define REFLECTION_BLUR_ITERATIONS 10
#define REFLECTION_BLUR_SIZE 0.05

#define WIDTH 0.48
#define HEIGHT 0.3
#define CURVE 3.0

#define BEZEL_COL vec4(0.8, 0.8, 0.6, 0.0)
#define PHOSPHOR_COL vec4(1.)
#define AMBIENT 0.2

#define NO_OF_LINES iResolution.y*HEIGHT
#define SMOOTH 0.004

// using normal vectors of a sphere with radius r
vec2 crtCurve(vec2 uv, float r) 
{
        uv = (uv - 0.5) * 2.0;// uv is now -1 to 1
    	uv = r*uv/sqrt(r*r -dot(uv, uv));
        uv = (uv / 2.0) + 0.5;// back to 0-1 coords
        return uv;
}

float roundSquare(vec2 p, vec2 b, float r)
{
    return length(max(abs(p)-b,0.0))-r;
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Calculate normal to distance function and move along
// normal with distance to get point of reflection
vec2 borderReflect(vec2 p, float r)
{
    float eps = 0.0001;
    vec2 epsx = vec2(eps,0.0);
    vec2 epsy = vec2(0.0,eps);
    vec2 b = (1.+vec2(r,r))* 0.5;
    r /= 3.0;
    
    p -= 0.5;
    vec2 normal = vec2(roundSquare(p-epsx,b,r)-roundSquare(p+epsx,b,r),
                       roundSquare(p-epsy,b,r)-roundSquare(p+epsy,b,r))/eps;
    float d = roundSquare(p, b, r);
    p += 0.5;
    return p + d*normal;
}

// Some Plasma stolen from dogeshibu for testing
vec4 somePlasma(vec2 uv)
{
    if(uv.x < 0.0 || uv.x > 1.0 ||  uv.y < 0.0 || uv.y > 1.0) return vec4(0.0);
    //return vec4(.5);
    
    return crtBuffA(uv)*.8;
    /*
    float scln = 0.5 - 0.5*cos(uv.y*3.14*NO_OF_LINES); // scanlines
    uv *= vec2(80, 24); // 80 by 24 characters
    uv = ceil(uv);
    uv /= vec2(80, 24);
    
    float color = 0.0;
    color += 0.7*sin(0.5*uv.x + iTime/5.0);
    color += 3.0*sin(1.6*uv.y + iTime/5.0);
    color += 1.0*sin(10.0*(uv.y * sin(iTime/2.0) + uv.x * cos(iTime/5.0)) + iTime/2.0);
    float cx = uv.x + 0.5*sin(iTime/2.0);
    float cy = uv.y + 0.5*cos(iTime/4.0);
    color += 0.4*sin(sqrt(100.0*cx*cx + 100.0*cy*cy + 1.0) + iTime);
    color += 0.9*sin(sqrt(75.0*cx*cx + 25.0*cy*cy + 1.0) + iTime);
    color += -1.4*sin(sqrt(256.0*cx*cx + 25.0*cy*cy + 1.0) + iTime);
    color += 0.3 * sin(0.5*uv.y + uv.x + sin(iTime));
    return scln*floor(3.0*(0.5+0.499*sin(color)))/3.0; // vt220 has 2 intensitiy levels*/
}

void mainImage(out vec4 fragColor, in vec2 fragCoord )
{
    vec4 c = vec4(0.0, 0.0, 0.0, 0.0);
    
    vec2 uv = fragCoord.xy / iResolution.xy;
	// aspect-ratio correction
	vec2 aspect = vec2(1.,iResolution.y/iResolution.x);
	uv = 0.5 + (uv -0.5)/ aspect.yx;
    
#ifdef MOUSE_CURVE
    float r = 1.5*exp(1.0-iMouse.y/iResolution.y);
#else
    float r = CURVE;
#endif
        
    // Screen Layer
    vec2 uvS = crtCurve(uv, r);
#ifdef MOUSE_MOVE
    uvS.x -= iMouse.x/iResolution.x - 0.5;
#endif

    // Screen Content
    vec2 uvC = (uvS - 0.5)* 2.; // screen content coordinate system
    uvC *= vec2(0.5/WIDTH, 0.5/HEIGHT);
    uvC = (uvC / 2.0) + 0.5;
    
    c += PHOSPHOR_COL * somePlasma(uvC);
    //c = crtBuffA(uvC);
    
    // Simple Bloom
    /*float B = float(MAIN_BLOOM_ITERATIONS*MAIN_BLOOM_ITERATIONS);
    for(int i=0; i<MAIN_BLOOM_ITERATIONS; i++)
    {
        float dx = float(i-MAIN_BLOOM_ITERATIONS/2)*MAIN_BLOOM_SIZE;
        for(int j=0; j<MAIN_BLOOM_ITERATIONS; j++)
        {
            float dy = float(j-MAIN_BLOOM_ITERATIONS/2)*MAIN_BLOOM_SIZE;
            c += PHOSPHOR_COL * somePlasma(uvC + vec2(dx, dy))/B;
        }
    }*/           
    
    // Ambient
    c += max(0.0, AMBIENT - 0.3*distance(uvS, vec2(0.5,0.5))) *
        smoothstep(SMOOTH, -SMOOTH, roundSquare(uvS-0.5, vec2(WIDTH, HEIGHT), 0.05));
  

    // Enclosure Layer
    vec2 uvE = crtCurve(uv, r+0.25);
#ifdef MOUSE_MOVE
    uvE.x -= iMouse.x/iResolution.x - 0.5;
#endif
    
    // Inner Border
    for( int i=0; i<REFLECTION_BLUR_ITERATIONS; i++)
    {
    	vec2 uvR = borderReflect(uvC + (vec2(rand(uvC+float(i)), rand(uvC+float(i)+0.1))-0.5)*REFLECTION_BLUR_SIZE, 0.05) ;
    	c += (PHOSPHOR_COL - BEZEL_COL*AMBIENT) * somePlasma(uvR) / float(REFLECTION_BLUR_ITERATIONS) * 
	        smoothstep(-SMOOTH, SMOOTH, roundSquare(uvS-vec2(0.5, 0.5), vec2(WIDTH, HEIGHT), 0.05)) * 
			smoothstep(SMOOTH, -SMOOTH, roundSquare(uvE-vec2(0.5, 0.5), vec2(WIDTH, HEIGHT) + 0.05, 0.05));
    }
               
  	c += BEZEL_COL * AMBIENT * 0.7 *
        smoothstep(-SMOOTH, SMOOTH, roundSquare(uvS-vec2(0.5, 0.5), vec2(WIDTH, HEIGHT), 0.05)) * 
        smoothstep(SMOOTH, -SMOOTH, roundSquare(uvE-vec2(0.5, 0.5), vec2(WIDTH, HEIGHT) + 0.05, 0.05));
    
    // Corner
  	c -= (BEZEL_COL )* 
        smoothstep(-SMOOTH*2.0, SMOOTH*10.0, roundSquare(uvE-vec2(0.5, 0.5), vec2(WIDTH, HEIGHT) + 0.05, 0.05)) * 
        smoothstep(SMOOTH*2.0, -SMOOTH*2.0, roundSquare(uvE-vec2(0.5, 0.5), vec2(WIDTH, HEIGHT) + 0.05, 0.05));

    // Outer Border
    c += BEZEL_COL * AMBIENT *
       	smoothstep(-SMOOTH, SMOOTH, roundSquare(uvE-vec2(0.5, 0.5), vec2(WIDTH, HEIGHT) + 0.05, 0.05)) * 
        smoothstep(SMOOTH, -SMOOTH, roundSquare(uvE-vec2(0.5, 0.5), vec2(WIDTH, HEIGHT) + 0.15, 0.05)); 


    fragColor = c;
}

/*void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = crtBuffA(fragColor,fragCoord);
}*/