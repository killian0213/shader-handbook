// Buffer A (buffer) — Holographic storage by tdhooper
// https://www.shadertoy.com/view/fsffWH

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

struct Model {
    float d;
    vec3 col;
    int id;
};

float t;

Model map(vec3 p) {
    
    vec3 col = normalize(p) * .5 + .5;

    p -= sin(p.y * 15. + t * PI * 2. * 3.) * .05;

    vec3 ps = p * mix(50., 100., smoothstep(-1., 1., p.y));
    p += ((sin(ps.x) + sin(ps.z) + sin(ps.y))) * .02 * smoothstep(-1., 1., p.y);

    p += sin(p.y * 10. + t * PI * 2. * 3.) * .05;
    p += sin(p * 8. + t * PI * 2.) * .1;
    
    float r = 1.;
    p -= r * .5;
    vec3 o = floor(p / r + .5);
    o = clamp(o, vec3(-1,-2,-1), vec3(0,1,0));
    p -= o * r;
    col = mix(col, normalize(p) * .5 + .5, .5);

    float d = sdBoundingBox(p, vec3(.3), .5);
    return Model(d, col, 1);
}

// Dave_Hoskins https://www.shadertoy.com/view/4djSRW
vec2 hash22(vec2 p)
{
    p += 1.61803398875; // fix artifacts when reseeding
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

const float sqrt3 = 1.7320508075688772;

mat3 calcLookAtMatrix(vec3 ro, vec3 ta, vec3 up) {
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww,up));
    vec3 vv = normalize(cross(uu,ww));
    return mat3(uu, vv, ww);
}

vec3 draw(vec2 fragCoord, int frame) {

    vec2 p = (-iResolution.xy + 2. * fragCoord.xy) / iResolution.y;
        
    vec2 seed = hash22(fragCoord + (float(frame)) * sqrt3);
    
    p += 2. * (seed - .5) / iResolution.xy;

    vec3 camPos = vec3(0,0,8);
    
    pR(camPos.yz, PI * .2);
    pR(camPos.xz, PI * .25);

    mat3 camMat = calcLookAtMatrix(camPos, vec3(0), vec3(0,1,0));
    
    float focalLength = 60.;
    camPos *= focalLength / 3.;
    vec3 rayDir = normalize(camMat * vec3(p.xy, focalLength));
    vec3 origin = camPos;
    
    vec3 col = vec3(0);

    vec3 rayPosition;
    float rayLength = 0.;
    Model model;
        
    float maxlen = 10. * focalLength;
    int iter = 200;
    float eps = .00004;
    
    for (int i = 0; i < iter; i++) {
        rayPosition = origin + rayDir * rayLength;
        model = map(rayPosition);
        
        float d = max(eps, abs(model.d));
        rayLength += d * (1. - seed.x * .125);
        
        seed = hash22(seed);
 
        if (rayLength > maxlen) {
            break;
        }
        
        col += model.col / pow(d, .125) * .002;
    }

    return col;
}

#define ANIMATE

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    t = .1;
    
    #ifdef ANIMATE
        t = fract(iTime / 4.);
        vec4 col = vec4(0.);
        const int c = 4;
        for (int i = 0; i < c; i++) {
            col += vec4(draw(fragCoord, iFrame * c + i), 1);
        }
        col /= float(c);
    #else
        vec4 col = vec4(draw(fragCoord, iFrame), 1);
        if (iFrame > 0 && iMouse.z <= 0.) {
            vec4 lastCol = texelFetch(iChannel0, ivec2(fragCoord.xy), 0);
            col += lastCol;
        }
    #endif
    
    fragColor = col;
}

