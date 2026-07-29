// Buffer A (buffer) — Beetle juice by tdhooper
// https://www.shadertoy.com/view/wlyyWD


//#define DARK_MODE


#if HW_PERFORMANCE==1
    const float MAX_DISPERSE = 5.;
    const float MAX_BOUNCE = 10.;
#else
    const float MAX_DISPERSE = 3.;
    const float MAX_BOUNCE = 6.;
#endif


#define PI 3.14159265359
#define PHI 1.618033988749895


// HG_SDF
// https://www.shadertoy.com/view/Xs3GRB

#define PI 3.14159265359
#define TAU 6.28318530718

#define saturate(x) clamp(x, 0., 1.)

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

float smax(float a, float b, float r) {
    vec2 u = max(vec2(r + a,r + b), vec2(0));
    return min(-r, max (a, b)) + length(u);
}

float vmax(vec2 v) {
	return max(v.x, v.y);
}

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

float fBox(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}

float fBox(vec3 p, vec3 b) {
	vec3 d = abs(p) - b;
	return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float range(float vmin, float vmax, float value) {
  return clamp((value - vmin) / (vmax - vmin), 0., 1.);
}

// Spectrum palette
// IQ https://www.shadertoy.com/view/ll2GD3

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 spectrum(float n) {
    return pal( n, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
}


//========================================================
// Modelling
//========================================================


float time;

vec2 map(vec3 p) {

    float scl = .9;

    if (iMouse.z > 0.) {
        pR(p.yz, (.5 - iMouse.y / iResolution.y) * PI / 2.);
        pR(p.xz, (.5 - iMouse.x / iResolution.x) * PI * 2.);
    } else {
        pR(p.yz, (.5 - .75) * PI / 2.);
        pR(p.xz, (.5 - .875) * PI * 2.);
    }

    p /= scl;

    p += sin(sin(p * 5.) * 3. + time * PI * 2.) * .1;
    p += (sin(p.x * 10. + time * PI * 2.) * sin(p.y * 20.) * sin(p.z * 30.)) * .03;
    float sc = 3.;
    p += (sin(p.x * 20. * sc + time * PI * 2.) * sin(p.y * 20. * sc) * sin(p.z * 20. * sc)) * .002;
    
    pR(p.xy, -PI/4.);
    pR(p.xz, -PI/4.);

    float d = length(p) - 1.;
       
    float r = .3;
    d = mix(d, fBox(p, vec3(.8 - r)) - r, 2.5);
    d = max(d, -(d + .01));
    
    d *= scl;
    
    return vec2(d, 1);
}


//========================================================
// Lighting
//========================================================

vec3 BGCOL = vec3(.9,.83,1);

float intersectPlane(vec3 rOrigin, vec3 rayDir, vec3 origin, vec3 normal, vec3 up, out vec2 uv) {
    float d = dot(normal, (origin - rOrigin)) / dot(rayDir, normal);
  	vec3 point = rOrigin + d * rayDir;
	vec3 tangent = cross(normal, up);
	vec3 bitangent = cross(normal, tangent);
    point -= origin;
    uv = vec2(dot(tangent, point), dot(bitangent, point));
    return max(sign(d), 0.);
}

mat3 envOrientation;

vec3 light(vec3 origin, vec3 rayDir) {
    origin = -origin;
    rayDir = -rayDir;

    origin *= envOrientation;
    rayDir *= envOrientation;

    vec2 uv;
    vec3 pos = vec3(-6);
    float hit = intersectPlane(origin, rayDir, pos, normalize(pos), normalize(vec3(-1,1,0)), uv);
    float l = smoothstep(.75, .0, fBox(uv, vec2(.5,2)) - 1.);
    l *= smoothstep(6., 0., length(uv));
	return vec3(l) * hit;
}

vec3 env(vec3 origin, vec3 rayDir) {    
    origin = -(vec4(origin, 1)).xyz;
    rayDir = -(vec4(rayDir, 0)).xyz;

    origin *= envOrientation;
    rayDir *= envOrientation;

    float l = smoothstep(.0, 1.7, dot(rayDir, vec3(.5,-.3,1))) * .4;
   	return vec3(l) * BGCOL;
}



//========================================================
// Marching
//========================================================

#define ZERO (min(iFrame,0))

// https://iquilezles.org/articles/normalsSDF
vec3 normal( in vec3 pos )
{
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.001*e).x;
    }
    return normalize(n);
}

struct Hit {
    vec2 res;
    vec3 p;
    float len;
    float steps;
};

Hit march(vec3 origin, vec3 rayDir, float invert, float maxDist, float understep) {
    vec3 p;
    float len = 0.;
    float dist = 0.;
    vec2 res = vec2(0.);
    vec2 candidate = vec2(0.);
    float steps = 0.;
    
    understep *= .2;

    for (float i = 0.; i < 300.; i++) {
        len += dist * understep;
        p = origin + len * rayDir;
        candidate = map(p);
        dist = candidate.x * invert;
        steps += 1.;
        res = candidate;
        if (dist < .001) {
            break;
        }
        if (len >= maxDist) {
            len = maxDist;
            res.y = 0.;
            break;
        }
    }   

    return Hit(res, p, len, steps);
}

mat3 sphericalMatrix(vec2 tp) {
    float theta = tp.x;
    float phi = tp.y;
    float cx = cos(theta);
    float cy = cos(phi);
    float sx = sin(theta);
    float sy = sin(phi);
    return mat3(
        cy, -sy * -sx, -sy * cx,
        0, cx, sx,
        sy, cy * -sx, cy * cx
    );
}

mat3 calcLookAtMatrix(vec3 ro, vec3 ta, vec3 up) {
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww,up));
    vec3 vv = normalize(cross(uu,ww));
    return mat3(uu, vv, ww);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float duration = 4.;
    time = mod(iTime / duration, 1.);
    
    #ifndef DARK_MODE
        envOrientation = sphericalMatrix(((vec2(81.5, 119) / vec2(187)) * 2. - 1.) * 2.);
    #else
        envOrientation = sphericalMatrix((vec2(0.7299465240641712,0.3048128342245989) * 2. - 1.) * 2.);
    #endif

    vec2 uv = (2. * fragCoord - iResolution.xy) / iResolution.y;

    
    if (iMouse.z > 0.) {
        uv /= 1.75;
    }

    Hit hit, firstHit;
    vec2 res;
    vec3 p, rayDir, origin, sam, ref, raf, nor, camOrigin, camDir;
    float invert, ior, offset, extinctionDist, maxDist, firstLen, bounceCount, wavelength;
    
    vec3 col = vec3(0);
    float focal = 3.8;
    bool refracted;

    vec3 bgCol = BGCOL * .22;

    invert = 1.;
    maxDist = 15.; 
    
	camOrigin = vec3(0,0,9.5);
   	camDir = normalize(vec3(uv * .168, -1.));

    //camOrigin = vec3(1.8, 5.5, -5.5) * 1.75;

    firstHit = march(camOrigin, camDir, invert, maxDist, .8);
    firstLen = firstHit.len;

    float steps = 0.;

    float rand = texture(iChannel0, (fragCoord + floor(iTime * 60.) * 10.) / iChannelResolution[0].xy).r;
    
    for (float disperse = 0.; disperse < MAX_DISPERSE; disperse++) {
        invert = 1.;
    	sam = vec3(0);

        origin = camOrigin;
        rayDir = camDir;

        extinctionDist = 0.;
        wavelength = disperse / MAX_DISPERSE;
        wavelength += (rand * 2. - 1.) * (.5 / MAX_DISPERSE);
        wavelength = mix(-.5/5., 1. - .5/5., mod(wavelength, 1.));
        
		bounceCount = 0.;

        for (float bounce = 0.; bounce < MAX_BOUNCE; bounce++) {

            if (bounce == 0.) {
                hit = firstHit;
            } else {
                hit = march(origin, rayDir, invert, maxDist / 2., 1.);
            }
            
            steps += hit.steps;
            
            res = hit.res;
            p = hit.p;
            
            if (invert < 0.) {
	            extinctionDist += hit.len;
            }

            // hit background
            if ( res.y == 0.) {
                break;
            }

            vec3 nor = normal(p) * invert;            
            ref = reflect(rayDir, nor);
            
            // shade
            sam += light(p, ref) * .5;
            sam += pow(max(1. - abs(dot(rayDir, nor)), 0.), 5.) * .1;
            sam *= vec3(.85,.85,.98);

            // refract
            float ior = mix(.1, .95, wavelength);
            ior = invert < 0. ? ior : 1. / ior;
            raf = refract(rayDir, nor, ior);
            bool tif = raf == vec3(0); // total internal reflection
            rayDir = tif ? ref : raf;
            offset = .01 / abs(dot(rayDir, nor));
            origin = p + offset * rayDir;
            //invert = tif ? invert : invert * -1.;
            invert *= -1.; // not correct but gives more interesting results

            bounceCount = bounce;
        }

        #ifndef DARK_MODE
            sam += bounceCount == 0. ? bgCol : env(p, rayDir);	
        #endif

        if (bounceCount == 0.) {
            // didn't bounce, so don't bother calculating dispersion
            col += sam * MAX_DISPERSE / 2.;
            break;
        } else {
            vec3 extinction = vec3(.5,.5,.5) * .0;
            extinction = 1. / (1. + (extinction * extinctionDist));	
            col += sam * extinction * spectrum(-wavelength+.25);
        }
	}
    
    // debug
 	//fragColor = vec4(spectrum(steps / 2000.), 1); return;
    //fragColor = vec4(vec3(bounceCount / MAX_BOUNCE), 1); return;
    //fragColor = vec4(vec3(firstHit.steps / 100.), 1); return;

    col /= MAX_DISPERSE;
    
    //col = mix(col, bgCol, clamp(range(9., 30., firstLen), 0., 1.));
        
    float depth = range(0., 13., firstLen);
        
    fragColor = vec4(col, depth);
}
