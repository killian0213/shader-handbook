// Image (image) — wireframe stellated dodecahedron by ChunderFPV
// https://www.shadertoy.com/view/McfXzr

// radial blur
// updated oct 7 2024
// jitter method from https://www.shadertoy.com/view/MXlyW8
// blur loop is cut in half with this method
float hash12(vec2 u)
{
	vec3 p = fract(u.xyx * .1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

#define T(p) texture(iChannel0, mix(u, m, (v+j)/l*p)).rgb       // scale texture
#define H(a) (cos(radians(vec3(0, 60, 120))+(a)*6.2832)*.5+.5)  // hue
void mainImage( out vec4 C, in vec2 U )
{
    vec2 R = iResolution.xy,
         m = vec2(.5),//iMouse.xy/R,
         u = U/R;
    
    vec3 c = texture(iChannel0, u).rgb * .7;
    
    float l = 25.,  // scale loop
          s = 1.,   // step size
          j = hash12(U + iTime),  // jitter
          i = 0., v = i, d;
    
    for (i; i<l; i++)  // blur loop
        d = 1.-i/l,  // gradient
        c += ( T(1.) + T(-1.) ) * H(d) * .2,  // blur out & in & color
        v += s;  // step
    
    c.r += .3-length((U+U-R)/R.y*3.)*.1; // add red to center
    
    C = vec4(tanh(c*c), 1);
}

// original
/*
#define H(a) (cos(radians(vec3(0, 60, 120))+(a)*6.2832)*.5+.5)  // hue
#define T(p) texture(iChannel0, mix(u, vec2(.5), p-i*p), a).rgb // scale texture
void mainImage( out vec4 C, in vec2 U )
{
    vec2 R = iResolution.xy,
         u = U/R;
    
    vec3 c = texture(iChannel0, u).rgb, k;
    
    float l = 50.,  // loop size
          j = 1./l, // increment size
          a = length((U+U-R)/R.y*3.), // mipmap aa
          b = j*4., // brightness
          i = j;
    
    for (; i<=1.; i+=j)
          k = T(1.) + T(-1.), // blur out & in
          c += b * H(i) * k;  // brightness, color, texture
    
    c.r += .3-a*.1; // add red to center
    C = vec4(tanh(c*c), 1);
}
*/