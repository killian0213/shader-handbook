// Image (image) — Jeweled Vortex by ChunderFPV
// https://www.shadertoy.com/view/fdjfDc

#define M iMouse
#define R iResolution.xy
#define PI 3.14159265358979
#define TAU 6.283185307179586
void mainImage( out vec4 RGBA, in vec2 XY )
{
    vec3 c = vec3(0);
    vec2 m = (M.xy-.5*R)/R.y*2.; // mouse coords
    float t = (M.z > 0.) ? atan(m.x, -m.y): -.54+(iTime*TAU)/3600., // arc from time or mouse
          n = (cos(t) > 0.) ? sin(t): 1./sin(t), // t to sin/csc
          e = n*2.,                              // exponent
          z = clamp(pow(500., n), 1e-16, 1e+18); // zoom
    vec2 uv = (XY-.5*R)/R.y*2., // screen coords
          u = uv*z;             // coords with zoom
    float ro = -PI/2.,               // rotation
          cr = iTime*TAU/5.,         // counter rotation
          a = atan(u.y, u.x)-ro,     // screen arc
          i = a/TAU,                 // arc to range between +/-0.5
          r = exp(log(length(u))/e), // radius | slightly faster than pow(length(u), 1./e)
          sc = ceil(r-i),            // spiral contour
          s = pow(sc+i, 2.),         // spiral gradient
          vd = cos((sc*TAU+a)/n),    // visual denominator
          ts = cr+s/n*TAU;           // segment with time
    c += sin(ts/2.); // spiral 1
    c *= cos(ts);    // spiral 2
    c *= pow(abs(sin((r-i)*PI)), abs(e)+5.);    // smooth edges & thin near inf
    c *= .2+abs(vd);                            // dark folds
    c = min(c, pow(length(u)/z, -1./n));        // dark gradient
    vec3 rgb = vec3(vd+1., abs(sin(t)), 1.-vd); // color
    c += (c*2.)-(rgb*.5);                       // add color
    if (M.z > 0.) c = max(c, digit(iChannel0, uv-m, n, .2, 4., 4.)); // digits
    RGBA = vec4(c, 1.);
}

/* golf 489 char with help from Fabrice
void mainImage( out vec4 c, vec2 U )
{
    vec2 R = iResolution.xy, u,
         m = (2.*iMouse.xy-R)/R.y;
    float T = 6.283,
          t = (iMouse.z > 0.) ? 
              atan(m.x, -m.y): 
              -.54+iTime*T/3600.,
          n = (cos(t) > 0.) ? sin(t): 1./sin(t),
          z = clamp(pow(5e2, n), 1e-16, 1e+18);
    u = (2.*U-R)/R.y*z;
    float a = T/4.+atan(u.y, u.x),
          i = a/T,
          l = length(u),
          r = exp(log(l)/n/2.),
          h = ceil(r-i),
          v = cos((h*T+a)/n),
          k = iTime*T/5.+pow(h+i, 2.)/n*T;
    c *= 0.;
    c += sin(k/2.)*cos(k) *
             pow(abs(sin((r-i)*T/2.)), abs(n*2.)+5.) *
             (.2+abs(v));
    c = min(c, pow(l/z, -1./n));
    c += c+c-.5*vec4(v+1., abs(sin(t)), 1.-v, 0);
}
*/