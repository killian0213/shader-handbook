// Image (image) — Turning space inside out by tdhooper
// https://www.shadertoy.com/view/fdfSDH

/*

    Turning space inside out
    ------------------------

    A quick demo of the transformation used in my animation,
    Inside, the new Outside!
    
    https://twitter.com/tdhooper/status/1378746948136624128
    
    This is a bit like sphere inversion, but we can transition
    from un-warped, to warped. It works by doing a stereographic
    projection to and from 4d, and performing a rotation in 4d.
    
    I think this is called a möbius transformation, there are
    some similar examples by Daniel Piker, along with code for
    other environments:
    
    https://twitter.com/KangarooPhysics/status/1292180181185179648
    https://spacesymmetrystructure.wordpress.com/2008/12/11/4-dimensional-rotations/

    I got the stereographic projection code, and the general
    approach for this from Matthew Arcus, who's made a lot of
    amazing 4d shaders:
    
    https://www.shadertoy.com/view/lsGyzm
    
*/

//#define SHOW_DISTANCE
#define FIX_DISTANCE

#define PI 3.14159265359

// HG_SDF
void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// https://iquilezles.org/articles/distfunctions/distfunctions.htm
float sdBoundingBox( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

// mla https://www.shadertoy.com/view/lsGyzm
vec4 inverseStereographic(vec3 p) {
  float k = 2.0/(1.0+dot(p,p));
  return vec4(k*p,k-1.0);
}
vec3 stereographic(vec4 p4) {
  float k = 1.0/(1.0+p4.w);
  return k*p4.xyz;
}

struct Model {
    float d;
    vec3 col;
};

Model scene(vec3 p) {
    vec3 col = normalize(p) * .5 + .5;
    float d = sdBoundingBox(p, vec3(.9), .2);
    return Model(d, col);
}

Model sceneWarped(vec3 p) {

    float f = length(p);

    // Project to 4d
    vec4 p4 = inverseStereographic(p);
    
    // Rotate in the 4th dimension
    pR(p4.zw, -iTime);
    
    // Project back to 3d
    p = stereographic(p4);
    
    Model model = scene(p);
    
    // When we're inside out, the entire universe gets collapsed
    // into the middle of the scene, causing a lot of raymarching
    // understepping and overstepping.
    // This ia a rough attempt at fixing this, there's still a bit
    // of overestimation in places so the raymarch loop is hacked
    // to accommodate it.
    #ifdef FIX_DISTANCE
        float e = length(p.xyz);
        model.d *= min(1., 1. / e) * max(1., f);
    #endif
    
    return model;
}

Model map(vec3 p) {
    Model model = sceneWarped(p);

    #ifdef SHOW_DISTANCE
        float d = abs(p.y);
        if (d < model.d) {
            model.col = min(vec3(0, 1. / model.d, model.d), 1.) * fract(model.d * 10.);
            model.d = d;
        }
    #endif

    return model;
}

// compile speed optim from IQ https://www.shadertoy.com/view/Xds3zN
vec3 calcNormal(vec3 pos){
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e).d;
    }
    return normalize(n);
}

mat3 calcLookAtMatrix(vec3 ro, vec3 ta, vec3 up) {
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww,up));
    vec3 vv = normalize(cross(uu,ww));
    return mat3(uu, vv, ww);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (-iResolution.xy + 2. * fragCoord.xy) / iResolution.y;
    
    vec3 camPos = vec3(0,0,8);
    
    vec2 im = iMouse.xy / iResolution.xy;
    
    if (iMouse.x <= 0.) {
        im = vec2(.6,.3);
    }
    
    pR(camPos.yz, (.5 - im.y) * PI / 2.);
    pR(camPos.xz, (.5 - im.x) * PI * 2.5);
    
    mat3 camMat = calcLookAtMatrix(camPos, vec3(0), vec3(0,1,0));
    
    float focalLength = 3.;
    vec3 rayDirection = normalize(camMat * vec3(p.xy, focalLength));
    
    vec3 rayPosition = camPos;
    float rayLength = 0.;
    Model model;
    float dist = 0.;
    bool bg = false;
    vec3 bgcol = vec3(.014,.01,.02);
    vec3 col = bgcol;

    for (int i = 0; i < 100; i++) {
        rayLength += dist * .8; // fix overstepping
        rayPosition = camPos + rayDirection * rayLength;
        model = map(rayPosition);
        dist = model.d;

        if (abs(dist) < .001) {
        	break;
        }
        
        if (rayLength > 15.) {
            bg = true;
            break;
        }
    }
    
    if ( ! bg) {
        col = model.col;
        vec3 nor = calcNormal(rayPosition);
        col *= dot(vec3(0,1,0), nor) * .5 + 1.;
        float fog = 1. - exp((rayLength - 6.) * -.5);
        col = mix(col, bgcol, clamp(fog, 0., 1.));
    }

    col = pow(col, vec3(1./2.2));

    fragColor = vec4(col,1);
}
