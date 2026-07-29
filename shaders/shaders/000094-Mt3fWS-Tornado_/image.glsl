// Image (image) — Tornado ! by hamtarodeluxe
// https://www.shadertoy.com/view/Mt3fWS

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
#define PI 3.14159265359
#define maxDist 10.
#define nStep 35
#define nStepLight 4

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

uint integerMod(uint x, uint y)
{
    return x - x/y;
}

float saturate(float i)
{
    return clamp(i,0.,1.);
}

float hash1( uint n ) 
{
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float( n & uvec3(0x7fffffffU))/float(0x7fffffff);
}

float noise (vec3 x)
{
    //smoothing distance to texel https://iquilezles.org/articles/texture
    x*=32.;
    x += 0.5;
    
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f*f*f*(f*(f*6.0-15.0)+10.0);
	x = f+i;    
    x-=0.5;
    
    return texture( iChannel0, x/32.0 ).x;
}

// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

const mat3 m = mat3( 0.00,  0.80,  0.60,
           		    -0.80,  0.36, -0.48,
             		-0.60, -0.48,  0.64 );


float fbm( vec3 p ) { // in [0,1]
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p ); p = m*p*2.01;
    f += 0.0625*noise( p );
    return f;
}
// --- End of: Created by inigo quilez --------------------

vec3 camera (vec2 ndc, vec3 camPos, float f, vec3 lookAt)
{
    vec3 forward = normalize(lookAt - camPos);
    vec3 right = cross(vec3(0.,1,0.), forward);
    vec3 up = normalize(cross (forward, right));
   	right = normalize(cross (up, forward));
    vec3 rd = up * ndc.y + right * ndc.x + f*forward;
	return rd;
}


float map (vec3 p)
{
   
    mat4x4 rot = rotationMatrix(vec3(0.,1,0), 00.2*PI*p.y);
    vec3 oldP =p;
    p = (rot* vec4(p,0.)).xyz;
    float density = 3.5;
    float invFct = 1./oldP.y;
    float n = fbm ((p+vec3 (0.,-iTime,0.))*.04 ) ; //Fractal noise
    //center part
    float radius = invFct * 2.; 
    float v1 =  1. - smoothstep(radius,radius+3.25*n ,length(oldP.xz));
   
    //peripherial part
	radius = invFct*8.;
 	float v2 =smoothstep(radius,radius+1.  ,length(oldP.xz)) - smoothstep(radius+1.,radius+2.,length(oldP.xz));
    v2 = saturate( v2 - smoothstep (radius,radius+2.*n  ,length(oldP.xz)))* saturate(.07*oldP.y);
 	   
    return density *saturate(v1+v2)+ smoothstep(0.,1.,1.-length(oldP/10.))*0.025;
}

float lightMarch(vec3 ro, vec3 lightPos)
{
    
    vec3 rd = lightPos-ro;
    float d = length (rd);
    rd = rd/d;
    float t = 0.;
    float stepLength = d/ float(nStepLight);
    float densitySum = 0.;
    float sampleNoise;
    int i = 0;
    for (; i < nStepLight; i++)
    {
    	sampleNoise = map ( ro + t * rd);
       
        densitySum += sampleNoise;
        
        t += stepLength;
    }    
    return exp(- d * (densitySum / float(i)));
}

vec3 calculateLight(vec3 samplePos, vec3 lightPos, vec3 lightColor, float lightStr)
{
        float sampleLight = lightMarch (samplePos, lightPos);
        float distToLight = length(lightPos-samplePos)+1.;
        vec3 light = lightColor * lightStr * (1./(distToLight*distToLight)) * sampleLight;

    	return light;
}

vec3 march(vec3 ro, vec3 rd, float dither, float var)
{
    float value = 0.;
    float densitySum = 0.;
    float stepLength = maxDist / float(nStep);
    vec3 color = vec3(0.02,0.01,0.2)*0.1;
    float t = dither;

    for (int i = 0; i < nStep; i++)
    {
        
        vec3 samplePos = ro + t * rd ; 
    	float sampleNoise = map (samplePos);
        densitySum += sampleNoise;
    	
        //light1
        vec3 lightPos1 = vec3 (-5.,5.0,-5);         
        vec3 light1 = calculateLight(samplePos, lightPos1, vec3 (0.6,0.25,0.15), 20.);
        
        //light2
        vec3 lightPos2 = vec3 (-5.,5.,5.);
        vec3 light2 = calculateLight(samplePos, lightPos2, vec3 (0.1 ,1.,0.6),20.);
     	    
        vec3 ambientColor = vec3 (0.025,0.025,0.005)*0.4;
        
        color += exp(- t*(densitySum/float(i+1)))  * sampleNoise *(ambientColor + light1 + light2) ;
        
        t +=  stepLength * var;
    }
    
    return color;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
   	uv *=1.5;
    uv.x-=0.25;
    vec2 ndc = uv * 2. - 1.;
    ndc.x *=iResolution.x/iResolution.y;
  
    vec2 mouse = iMouse.xy/iResolution.xy;
      
    vec3 lookAt = vec3(0.,2.,0.);
   
    float mY = (1.-mouse.y) *5. +2.; //Remap zoom 
    
    vec3 cameraPos = vec3((mY*cos(-mouse.x*2.*PI)), 4., (mY*sin(-mouse.x * 2.*PI)));
    
    vec3 rd = camera(ndc, cameraPos, 1.0,lookAt);
    
    float var = length(rd)/1.0; //to get constant z in samples, but reduce extreme rays definition
    var = 1.; //not used here
    rd = normalize (rd);

    float dither = 0.3*hash1(   uint(fragCoord.x+iResolution.x*fragCoord.y) + 
                                uint(iResolution.x*iResolution.y) * integerMod(uint(iFrame), 32u));
                                
    vec3 col = march(cameraPos, rd, dither,var);

    fragColor = vec4(col, 1.0f);
}