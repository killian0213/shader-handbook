// Image (image) — Worley Hyperdisc - Ocean Planet by CaliCoastReplay
// https://www.shadertoy.com/view/Xlc3Rf

//Adapted from:  https://www.shadertoy.com/view/Xl33Wn
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float length2(vec2 p){
    return dot(p,p);
}
float noise(vec2 p )
{
    return fract(sin(fract(sin(p.x)*(41.13311))+ p.y)*31.0011);
}

float worley(vec2 p) {
 float d = 1e30;
 for (int xo = -1; xo <= 1; ++xo) {
  for (int yo = -1; yo <= 1; ++yo) {
   vec2 tp = floor(p) + vec2(xo, yo);
   d = min(d, length2(p - tp - noise(tp)));
  }
 }
  return 3.0*exp(-4.4*abs((2.5*d)-1.0));
}

float fworley(vec2 p)
{
    return sqrt(sqrt(sqrt(worley(p * 11.0 + 0.15 * iTime) * 
                          sqrt(worley(p*50.0+ 0.18+ -0.12*iTime)) *
                         sqrt(sqrt(worley(p*-10.0+0.3*iTime))))));
}


//hyperbolic disc/radial distortion adapted from https://www.shadertoy.com/view/XllSWf
vec2 HyperbolicDisc(vec2 fragCoord) {    
    fragCoord -= iResolution.xy * 0.29;
    fragCoord /= iResolution.x;
    float r = length(fragCoord);
    vec2 d = fragCoord / r *1.5 ;
    fragCoord = d / atanh(r * (2.5 )) / 2.0;
    fragCoord *= iResolution.x;
    fragCoord += iResolution.xy *0.212;
    fragCoord += 1.59+ sin(iTime/10.0);
    return fragCoord;
}

float flare( vec2 U )                            // rotating hexagon 
{	vec2 A = sin(vec2(0, 1.57) + iDate.w);
    U = abs( U * mat2(A, -A.y, A.x) ) * mat2(2,0,1,1.7); 
    return .2/max(U.x,U.y);                      // glowing-spiky approx of step(max,.2)
  //return .2*pow(max(U.x,U.y), -2.);
 
}

#define r(x)     fract(1e4*sin((x)*541.17))      // rand, signed rand   in 1, 2, 3D.
#define sr2(x)   ( r(vec2(x,x+.1)) *2.-1. )
#define sr3(x)   ( r(vec4(x,x+.1,x+.2,0)) *2.-1. )

vec4 stars( vec4 O, vec2 U )
{
    vec2 R = iResolution.xy;
    U =  (U+U - R) / R.y;
	O -= O+.3;
    for (float i=0.; i<99.; i++)
        O += flare (U - sr2(i)*R/R.y )           // rotating flare at random location
              * r(i+.2)                          // random scale
              * (1.+sin(iDate.w+r(i+.3)*6.))*.1  // time pulse
            //* (1.+.1*sr3(i+.4));               // random color - uncorrelated
              * (1.+.1*sr3(i));                  // random color - correlated
    return O;
}

vec4 fake_planet( vec2 fragCoord )
{
    vec4 fragColor;
    vec2 fragCoord2;
    fragCoord2.x += sin(iTime/3.5)*12.0;
    fragCoord2.y += cos(iTime/3.5)*12.0;
    fragCoord2 = HyperbolicDisc(fragCoord);
    vec2 uv = fragCoord2.xy / iResolution.xy;
    float wolo = fworley(uv*iResolution.xy / 1919.0) + fworley((uv*iResolution.xy + sin(iTime*2.0)) / 3200.0)
         + fworley((uv*iResolution.xy - sin(iTime*2.0)) / 4800.0);
 	wolo *= .85*exp(-length2(abs(0.5*uv-0.9)));
    fragColor = vec4(wolo * vec3(0.1*wolo*wolo, 0.3*wolo, 1.2*pow(wolo, 0.90-wolo)), 1.0);
    vec3 hsv = rgb2hsv(fragColor.xyz);
    hsv.z *= sqrt(hsv.z) * 1.1+ cos(iTime/13.0)*0.4;
    hsv.x += hsv.z/200.0 * sin(iTime/2.0)*2.0;
    hsv.y -= hsv.z/102.0;
    fragColor.xyz = hsv2rgb(hsv);
    return fragColor;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 starColor = stars(fragColor, fragCoord);
    vec4 planetColor = fake_planet(fragCoord);
    float distanceToCenter = 0.0;
    vec2 uv = fragCoord.xy / iResolution.xy;
    float xDist = uv.x - 0.35;
    float yDist = uv.y - 0.35;
    distanceToCenter += sqrt(xDist*xDist/.29 + yDist*yDist);
    if (distanceToCenter > 0.60)
    	fragColor =starColor/2.0;
    else        
    {
        float falloff =  1.0-distanceToCenter;
    	fragColor = planetColor * falloff *falloff * falloff * 1.90;
    }

}