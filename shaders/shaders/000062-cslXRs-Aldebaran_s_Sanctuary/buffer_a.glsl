// Buffer A (buffer) — Aldebaran's Sanctuary by kishimisu
// https://www.shadertoy.com/view/cslXRs

#define ALTERNATE_VIEWS 1 // Set to 0 to prevent camera from switching viewpoints

#define MOTION_BLUR     10.
#define MAX_ITERATIONS 100.
#define MAX_DISTANCE   120.
#define EPSILON        .001

#define FBM_LAYERS  8
#define FAST_LAYERS 4
#define SHADOW_FBM_LAYERS 4
#define RELAXATION  1.

#define VOLUME_STEPS    20.
#define VOLUME_DENSITY  .8
#define VOLUME_LIGHT    0.7

#define sunCycle (iMouse.z == 0. ? smoothstep(-2.,10.,iTime) : iMouse.x/iResolution.x*.9+.1)
#define sunColor vec3(1.2,0.671,0.376)*(sunCycle*.9+.15)
#define skyColor vec3(0.604,0.784,0.976)*(sunCycle*.9+.15)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define treeRep 24.

// Value noise - https://www.shadertoy.com/view/lsf3WH
float hash(vec2 p) {
    p  = 50.0*fract( p*0.3183099 + vec2(0.71,0.113));
    return fract( p.x*p.y*(p.x+p.y) );
}
float noise2( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );
	vec2 u = f*f*(3.0-2.0*f);
    return mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

// https://shadertoyunofficial.wordpress.com/2019/01/02/
vec3 hash33(vec3 p) {
    return fract(cos((p)*mat3(127.1,311.7,74.7,269.5,183.3,246.1,113.5,271.9,124.6))*43758.5453123);
}

// https://www.shadertoy.com/view/4djSRW
vec3 hash32(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}
vec3 hash31(float p) {
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

// https://www.shadertoy.com/view/3ddGzn
float noise3(vec3 p) {
	vec3 ip=floor(p), s=vec3(7, 157, 113);
	vec4 h=vec4(0, s.yz, s.y+s.z)+dot(ip, s);
	p-=ip; p=p*p*(3.-2.*p);
	h=mix(fract(43758.5*sin(h)), fract(43758.5*sin(h+s.x)), p.x);
	h.xy=mix(h.xz, h.yw, p.y);
	return mix(h.x, h.y, p.z);
}

// https://iquilezles.org/articles/fbm/
float fbm3(vec3 p) { 
    p += vec3(iTime*.1, iTime*.1, 0.);
    float f = 1.0, a = 1.0,
          t = noise3(p);
    for(int i=1; i<5; i++) {
        t += a*noise3(f*p);
        f *= 2.0; a *= .5;
    }
    return t;
}

float fastnoise2(vec2 p) {
    return (sin(p.x)-cos(p.y))*.5+.5;
}

// https://iquilezles.org/articles/smin
float smax( float a, float b, float k ) {
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*h/(6.0*k*k);
}

// https://iquilezles.org/articles/distfunctions/
float sdCone(vec3 p) {
    const vec2 c = vec2(0.198669, 0.980067);
    vec2   q = vec2( length(p.xz), -p.y );
    float  d = length(q-c*max(dot(q,c), 0.0));
    return d * ((q.x*c.y-q.y*c.x<0.0)?-1.0:1.0) - .1;
}
float sdArc( in vec2 p, in float ra, float rb ) {
    const vec2 sc = vec2(0.808496, -0.588501);
    p.x = abs(p.x);
    return ((sc.y*p.x>sc.x*p.y) ? length(p-sc*ra) : 
                                  abs(length(p)-ra)) - rb;
}
float sdCircle(vec2 p, float ra, float rb) {
    return abs(length(p) - ra) - rb;
}
float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float sdCapsule( vec3 p, vec3 a, vec3 b, float r ) {
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}
float sdCylinder( vec3 p, float h, float r ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// https://iquilezles.org/articles/boxfunctions/
vec2 boxIntersection(in vec3 ro, in vec3 rd, in vec3 rad)  {
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.0) return vec2(-1.0);
    return vec2( tN, tF );
}

// Smarter fbm calculation - https://www.shadertoy.com/view/msXSR2
float fbm(vec2 p, float h, int layers) {
    float n = fastnoise2(p); 
    float a = 1.;
    
    for (int i = 0; i < layers; i++) {
        if (h > n + a) break;
        
        p *= 2.; a *= .5;
   
        if (i < FAST_LAYERS) 
            n -= a*abs(fastnoise2(p)-n);
        else                
            n -= a*noise2(p);      
    } 
    
    return n;
}

float terrainH(vec3 p, int layers) {    
    float mnt =  smoothstep(0., 1., -sdArc(vec2(p.z, -p.x - 4.), 6. , 1.));
    mnt += 2.2 * smoothstep(0., 2., -sdCircle(p.xz - vec2(-4,0), 22., 5.)); 
    mnt += 4.  * smoothstep(0., 2., -sdCircle(p.xz - vec2(-4,0), 36., 5.));         
    return fbm(p.xz*.5, p.y - mnt, layers) + mnt;
}

vec2 map(vec3 p, int layers, inout vec3 light) {
    float l = length(p.xz);
    // Terrain
    float ground = 1e6;
    if (p.y < 5.) {
        float terrain = terrainH(p, layers);
        ground  = p.y - terrain;
    }
    
    // Trees
    float trees = 1e6;
    if (ground < 1.) {
        float sm  = smoothstep(5.5, 6., l);
        float rep = mix(treeRep, 10., sm);
        vec3  fp  = fract(p*rep)-.5; 
        vec3  id  = floor(p*rep)+.5;
        vec3  r   = hash32(id.xz);
        float fh  = fbm(id.xz*.5/rep, p.y-.1, layers); 

        float h  = 3. + r.y*sm*.4;
        vec3 off = vec3(1.,0.,1.)*r*.4*sm;
        fp.y = (p.y - fh) * rep - h;
        trees = (sdCone(fp - off) + smoothstep(.5, .9, noise2(p.xz))) / rep;  
    }
    
    // Structures
    float shape = 1e6, cables = 1e6;
    if (l < 12.) {
        vec3  sp  = p;
        float an  = 6.283185 / 16.;
        float aid = (round((atan(p.z, p.x)-an/2.)/an)*an)+an/2.;
        vec3  rs  = hash31(aid);
        sp.xz *= rot(-aid);

        shape = sdBox(sp - vec3(8.5,0,0), vec3(.3,3.,.45));
        float hole  = sdBox(sp - vec3(8.5,1.8,0), vec3(.35, .9, .3));
        shape = smax(shape, -hole, .1);

        float center = length(p+vec3(0,.2,0))-.35;
        float doors = sdBox(sp + vec3(0,.2,0), vec3(.4, .25*(sin(iTime*.1)*.5+.5), .04));
        center = smax(center, - doors, .03);
        center = min(center, sdCylinder(sp - vec3(1,-.5,0), .04, .5+rs.z*.2 + sin(.2*iTime+aid*10.)*.06));
        shape  = min(shape, center) - .01;

        // These aren't real objects, their signed distance is always strictly positive. It's only
        // captured in lighting as it increases the iteration count near these phantom cables.
        sp.z = abs(sp.z);
        cables = sdCapsule(sp, vec3(1,0,0), vec3(9,3,.4), -.01-smoothstep(0.4, 0.6, sunCycle));

        // Lighting
        vec3 lc = 0.06 * (vec3(.7,.7,1.) - rs*.2);
        light += lc / (1. + pow(abs(hole), 1.4));
        light += 1.5*lc * vec3(0.447,0.118,0.600) / (1. + pow(abs(center*5.), 1.4));
        light += 1.5*lc * vec3(0.118,0.600,0.522) / (1. + pow(abs(doors*5.), 1.4));
    }
    
    vec2 res = vec2(ground, 0.);
    if (trees < res.x) res = vec2(trees, 1.);
    if (shape < res.x) res = vec2(shape, 2.);
    if (cables < res.x) res = vec2(cables,3.);
    
    return res; 
}

vec3 ltmp;
vec3 getNormal(vec3 p, float d) {
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize(e.xyy*map(p + e.xyy, FBM_LAYERS,ltmp).x + e.yyx*map(p + e.yyx, FBM_LAYERS,ltmp).x + 
					 e.yxy*map(p + e.yxy, FBM_LAYERS,ltmp).x + e.xxx*map(p + e.xxx, FBM_LAYERS,ltmp).x);
}

float getShadow(vec3 ro, vec3 rd, float maxt) {
    float t = 0.1, res = 1., k = 10.;
    for (float i = 0.; i < MAX_ITERATIONS*.7; i++) {
        vec3 p = ro + t*rd;
        float d = map(p, SHADOW_FBM_LAYERS,ltmp).x;
        res = min(res, k*d/t);
        t += d;
        if (t > maxt) return res;
        if (d < EPSILON) return 0.;
    }
    return 0.;
}

vec3 volumeColor(vec3 ro, vec3 rd, float near, float far, vec3 sunDir, vec3 col) {
    vec3 vcol  = vec3(0.);
    float mask = 1.;
    float vstep = (far - near) / VOLUME_STEPS;
    const float dh = 1./VOLUME_DENSITY;

    for (float t = near, i = 0.; t <= far && i < VOLUME_STEPS; t += vstep, i++) {
        vec3 p = ro + t*rd;
        
        float dens = fbm3(p/6.);
        dens = smoothstep(dh, dh+1., dens);

        float prev = mask;
        mask *= exp(-dens * vstep * .3);
        float absorbed = prev - mask;
        
        vec3 light = 1.5-vec3(smoothstep(dh, dh+.6, fbm3((p-sunDir*.1)/6.)));
        vcol += vec3(.9,1.,.7) * sunColor * absorbed * vstep * light * VOLUME_LIGHT;          
    }
    
    return col*mask + min(vcol, vec3(1.));
}

void initRayOriginAndDirection(vec2 uv, inout vec3 ro, inout vec3 rd) {
    vec2 m = iMouse.z == 0. ? vec2(.5) : iMouse.xy/iResolution.xy*2.-1.; 
    float t = iTime*.1, tt = 0.;
    ro = vec3(0., -.1 + cos(t*1.1)*.1, 3. + sin(t*1.2)*.3);
#if ALTERNATE_VIEWS
    tt = step(20., mod(iTime, 35.)); 
#endif
    ro.yz *= rot(cos(t*1.15)*.05-mix(.5, .1, tt));
    ro.zx *= rot(sin(t)*.3-mix(-1.2, 1.2, tt)); 
    vec3 f = normalize(vec3(cos(t)*.01,.5+cos(t)*.02,sin(t)*.015)-ro), r = normalize(cross(vec3(0,1,0), f));
    rd = normalize(f + uv.x*r + uv.y*cross(f, r));
}

void mainImage(out vec4 O, in vec2 F) {
    vec2 uv = (2.*F - iResolution.xy)/iResolution.y;
    vec2 res;
    vec3 ro, rd;

    initRayOriginAndDirection(uv, ro, rd);
    
    bool hitWater = false;
    float t   = 0., i;
    vec3  p   = ro, 
        col   = skyColor, 
      light   = vec3(0.);  
        
    for (i = 0.; i < MAX_ITERATIONS; i++) {
        res = map(p, hitWater ? 5 : FBM_LAYERS, light);
        
        if (p.y < -.33) {
            // Reflect if ray hit water level
            p.y += 2.*abs(p.y+.33);
            rd.y = -rd.y;
            rd = normalize(rd + (noise2(p.xz*80.+iTime*.2)-.5)*.06);
            hitWater = true;
        }
        
        float d = res.x > 0. ? res.x*.9 : res.x*.3;
        t += d;
        p += rd * d;

        if (res.x < EPSILON*(1. + t*RELAXATION) || t > MAX_DISTANCE) break;
    }
    
    float phi = 0.32 * 6.28, the = -0.00 * 3.14 + 1.27 + (1.-sunCycle)*.2;
    vec3 lightDir = normalize(vec3(sin(the)*sin(phi), cos(the), sin(the)*cos(phi)));
    
    if (t < MAX_DISTANCE) {
        // Hit object
        float th = terrainH(p, FBM_LAYERS);
        vec3  id = floor(p*treeRep)+.5;
        vec3   r = hash32(id.xz);
        vec3   n = getNormal(p - rd*EPSILON*4., t);
        float sunLight    = max(.1, dot(n, lightDir));
        float sunShadow   = max(.02, getShadow(p + n*EPSILON*4., lightDir, MAX_DISTANCE));
        float skyLight    = max(.0, n.y);
        float bounceLight = max(.0, dot(n, -lightDir));
        float spec        = max(.0, dot((rd + n)/2., lightDir));

        if (res.y == 0.) {
            // Terrain
            col = vec3(1.);
            col *= .4+smoothstep(.55, .7, skyLight );
            col *= .05 + 1.*sunColor * sunLight * sunShadow;
        } else if (res.y == 1.) {
            // Trees
            col = mix(
                vec3(.2,.6 + (r.y-.5)*.5,.4)*.25, 
                vec3(1.)   + (r.x-.5)*.5, 
                smoothstep(0., .13, p.y - th + t * .0) 
            );
            col *= .25*(sunCycle+.1) + 1.*sunColor * sunLight * sunShadow;  
        } else {
            // Structures
            col = 1. - texture(iChannel1, p.xy*4.).rrr*.4;
            col *= .2 + 1.*sunColor * sunLight * sunShadow;
        }
        
        col *= smoothstep(.2, .4, length(p + vec3(0,.2,0)));

        col += 0.2*skyColor * skyLight;
        col += 0.1*vec3(.4,.2,0.) * bounceLight;
        col += 1.5*pow(spec, 4.)*sunCycle;
    } 
    
    // Clouds
    vec2 hit = boxIntersection(ro - vec3(0, 8, 0), rd, vec3(200., 4., 200.));
    if (hit.x >= 0. && hit.x < t) {
        col = volumeColor(ro, rd, hit.x, min(hit.y, t), lightDir, col);
        t = min(hit.x, t);
    }
    
    // Water occlusion
    if (hitWater) col *= vec3(.7,.7,.9);
    col *= mix(0.4, 1., smoothstep(-.35, -.25, p.y));
    
    // Apply fog
    vec3 fog = exp2(-t*0.07*vec3(1,1.8,4)); 
    col = mix(clamp(skyColor - vec3(1.,1.5,2.)*abs(rd.y)*.3, vec3(0.), vec3(1.)), col, fog);   
    
    // Color adjust
    col = pow(col, vec3(.99,.88,.95));
    col = smoothstep(vec3(0.04), vec3(1), col);
    col = pow(col, vec3(.4545));
    
    // Night lighting
    col += light * smoothstep(.8, 0., sunCycle);
           
    // Accumulate frames
    vec3 ocol = texelFetch( iChannel0, ivec2(F-0.5), 0 ).xyz;
    if(iFrame==0) ocol = col;
    col = mix(ocol, col, 1./MOTION_BLUR);
    O = vec4(col, 1.0);
}