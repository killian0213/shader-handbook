// Image (image) — Even More Fractal Rope by SnoopethDuckDuck
// https://www.shadertoy.com/view/fsXcRS

// "RayMarching starting point" 
// by Martijn Steinrucken aka The Art of Code/BigWings - 2020
// The MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Email: countfrolic@gmail.com
// Twitter: @The_ArtOfCode
// YouTube: youtube.com/TheArtOfCodeIsCool
// Facebook: https://www.facebook.com/groups/theartofcode/
//
// You can use this shader as a template for ray marching shaders

#define MAX_STEPS 400
#define MAX_DIST 50.
#define SURF_DIST .001

#define S smoothstep
#define T iTime

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float GetDist(vec3 p) {
    vec2 uv = p.xz;
   
    //p = abs(p) - 0.5;
    float time = 1. * p.y + 0.2 * iTime;
    float th = 2. + 0.45 * iTime;
    uv = abs(Rot(-0.8 *p.y + 0.1 * iTime) * uv );
    
    float m = 0.8;
    float n = 4.;
    for (float i = 0.; i < n; i++) {
        th -= 2. * abs(.5 * i * iTime + 1.5 * th + (1.-i/n) * p.y);
        uv = abs(Rot(th) * (uv - m));
        m *= 0.35;
    }

    float d = length(uv) - 0.02;
    d = max(p.y, d);
    //float d = length(p) - 0.5;
    
    //float d = length(uv)- 0.5;
    
    return 0.5 * d;
}

float RayMarch(vec3 ro, vec3 rd) {
	float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
	float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
	vec2 m = iMouse.xy/iResolution.xy;

    float l = 0.5 + 0.5 * thc(3., 0.5 * iTime);

    float r = mix(0.01, 5.5, 1.-l);
    float time = 0.45 * iTime;
    vec3 ro = vec3(r * cos(time), mix(6., -3., 1.-l) + 0. * iTime, r * sin(time));
    //ro.yz *= Rot(-m.y*3.14+1.);
    //ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0,mix(0., -3., 1.-l),0), 2.);
    vec3 col = vec3(0);
   
    float d = RayMarch(ro, rd);

    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);

        float ambient = .3;
        float difPower = .4;
        float dif = max(dot(n, normalize(vec3(1,2,3))), 0.);
        col = vec3(dif*difPower + ambient);

        col *= texture(iChannel0,r).rgb;
        col *= 1. + r.y;//+ p.y;
        col = clamp(col, 0., 1.);
        
        vec3 e = vec3(1.);
        col *= pal(r.y, e, e, e, 0.35 * vec3(0.,0.33,0.66));
        //col *= 0.5 + 0.5 * thc(4., 12. * length(p) + 0.4 * iTime) * cos(4. * p.y + iTime);
        //col *= 0.5 * (1. + thc(2., iTime + p.y * 4.));
    }

    col = pow(col, vec3(.4545));	// gamma correction
    
    fragColor = vec4(col,1.0);
}