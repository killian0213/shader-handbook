// Image (image) — Enhanced Sphere Tracing by patu
// https://www.shadertoy.com/view/4tVXRV

/* 

	
	http://bit.ly/shadertoy-plugin
 


*/


// getNormalHex or getNormalCube
#define getNormal getNormalCube

#define FAR 570.
#define INFINITY 1e32
#define t iTime

#define FOV 80.0
#define FOG 1.

#define PI 3.14159265
#define TAU (2*PI)
#define PHI (1.618033988749895)

vec3 fromRGB(int r, int g, int b) {
 	return vec3(float(r), float(g), float(b)) / 255.;   
}

float hash12(vec2 p) {
	float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}

// 3d noise
float noise_3(in vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);	
	vec3 u = f*f*(3.0-2.0*f);
    
    vec2 ii = i.xy + i.z * vec2(5.0);
    float a = hash12( ii + vec2(0.0,0.0) );
	float b = hash12( ii + vec2(1.0,0.0) );    
    float c = hash12( ii + vec2(0.0,1.0) );
	float d = hash12( ii + vec2(1.0,1.0) ); 
    float v1 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
    
    ii += vec2(5.0);
    a = hash12( ii + vec2(0.0,0.0) );
	b = hash12( ii + vec2(1.0,0.0) );    
    c = hash12( ii + vec2(0.0,1.0) );
	d = hash12( ii + vec2(1.0,1.0) );
    float v2 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
        
    return max(mix(v1,v2,u.z),0.0);
}

float fbm(vec3 x)
{
    float r = 0.0;
    float w = 1.0, s = 1.0;
    for (int i=0; i<5; i++)
    {
        w *= 0.5;
        s *= 2.0;
        r += w * noise_3(s * x);
    }
    return r;
}

vec3 
    light = vec3(0.0), 
    p,
    lightColour = normalize(vec3(1.8, 1.0, 0.3)); 

vec3 saturate(vec3 a) { return clamp(a, 0.0, 1.0); }
vec2 saturate(vec2 a) { return clamp(a, 0.0, 1.0); }
float saturate(float a) { return clamp(a, 0.0, 1.0); }

vec3 opRep( vec3 p, vec3 c )
{
    return mod(p,c)-0.5*c;
}

// Repeat only a few times: from indices <start> to <stop> 
float pModInterval1(inout float p, float size, float start, float stop) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p+halfsize, size) - halfsize;
	if (c > stop) { //yes, this might not be the best thing numerically.
		p += size*(c - stop);
		c = stop;
	}
	if (c <start) {
		p += size*(c - start);
		c = start;
	}
	return c;
}

void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

float opU2( float d1, float d2 ) {
    if (d1 < d2) return d1;
    return d2;
}

vec3 opU2( vec3 d1, vec3 d2 ) {
    if (d1.x < d2.x) return d1;
    return d2;
}

vec3 opS2( vec3 d1, vec3 d2 )
{	
    if (-d2.x > d1.x) return -d2;
    return d1;
}

vec3 opI2( vec3 d1, vec3 d2 ) {
 	if (d1.x > d2.x) return d1;
    return d2;
}

// Maximum/minumum elements of a vector
float vmax(vec2 v) {
	return max(v.x, v.y);
}

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

float vmax(vec4 v) {
	return max(max(v.x, v.y), max(v.z, v.w));
}

// Sign function that doesn't return 0
float sgn(float x) {
	return (x<0.)?-1.:1.;
}

vec2 sgn(vec2 v) {
	return vec2((v.x<0.)?-1.:1., (v.y<0.)?-1.:1.);
}


// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p + halfsize, size) - halfsize;
	return c;
}

// Repeat in two dimensions
vec2 pMod2(inout vec2 p, vec2 size) {
	vec2 c = floor((p + size*0.5)/size);
	p = mod(p + size*0.5,size) - size*0.5;
	return c;
}

// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout vec2 p, float repetitions) {
	float angle = 2.*PI/repetitions;
	float a = atan(p.y, p.x) + angle/2.;
	float r = length(p);
	float c = floor(a/angle);
	a = mod(a,angle) - angle/2.;
	p = vec2(cos(a), sin(a))*r;
	// For an odd number of repetitions, fix cell index of the cell in -x direction
	// (cell index would be e.g. -5 and 5 in the two halves of the cell):
	if (abs(c) >= (repetitions/2.)) c = abs(c);
	return c;
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
float pMirror (inout float p, float dist) {
	float s = sgn(p);
	p = abs(p)-dist;
	return s;
}

vec2 pMirrorOctant (inout vec2 p, vec2 dist) {
	vec2 s = sgn(p);
	pMirror(p.x, dist.x);
	pMirror(p.y, dist.y);
	if (p.y > p.x)
		p.xy = p.yx;
	return s;
}

// Box: correct distance to corners
float fBox(vec3 p, vec3 b) {
	vec3 d = abs(p) - b;
	return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

// Same as above, but in two dimensions (an endless box)
float fBox2Cheap(vec2 p, vec2 b) {
	return vmax(abs(p)-b);
}

float fSphere(vec3 p, float r) {
	return length(p) - r;
}

vec3 map(vec3 o) {
  
    p = o;

    p.y += 30. ;
    
    vec3 floor = vec3(
        fBox2Cheap(p.xy, vec2(1000., 1.)),
        2.,
        0.
    );
    
    p.y -= 30.;
    
    vec3 sphereS = vec3(
        fSphere(p, 20.),
        2.,
        0.
    );

    vec3 
        obj = vec3(FAR, -1.0, 0.0),
        obj2 = obj;

    pModPolar(p.zy, 5.);
    pModPolar(p.zx, 4.);

    pMirrorOctant(p.zy, vec2(min(t, 22.), min(t, 16.) ));
    pMirrorOctant(p.xz, vec2(min(t, 16.), min(t, 16.) ));
    
    pR(p.zy, 1.2 );
    
    float pmp = pModPolar(p.xz, 5.);
    
	pMirrorOctant(p.zy, vec2(4.5, 5.));
    pMirrorOctant(p.xy, vec2(6., 4.));
    
    p.zy += 2.;
    
    pModPolar(p.xy, 5.);

    obj = vec3(
        fBox2Cheap(p.xy, vec2(2.4, .5) + vec2(sin(t) * 2., .5 + cos(t * 2.2) / 4.)),
        2.0,
        0.
    );
    
    p.z -= 2.;
    
    obj2 = vec3(
        fSphere(p, 2.),
        1.,
        0.
    );
    
    obj = opU2(obj, obj2);
    obj = opU2(obj, floor);
    obj = opS2(obj, sphereS);
    
    return obj;
}


// http://erleuchtet.org/~cupe/permanent/enhanced_sphere_tracing.pdf

float t_min = 0.001;
float t_max = FAR;
const int MAX_ITERATIONS = 90;

vec3 trace(vec3 o, vec3 d) {
    float omega = 1.3;
    float t = t_min;
    float candidate_error = INFINITY;
    float candidate_t = t_min;
    float previousRadius = 0.;
    float stepLength = 0.;
    float pixelRadius = 0.001;
    float functionSign = map(o).x < 0. ? -1. : 1.;
    vec3 mp;
    
    for (int i = 0; i < MAX_ITERATIONS; ++i) {
        mp = map(d * t + o);
        float signedRadius = functionSign * mp.x;
        float radius = abs(signedRadius);
        bool sorFail = omega > 1. &&
        (radius + previousRadius) < stepLength;
        if (sorFail) {
            stepLength -= omega * stepLength;
            omega = 1.;
        } else {
        stepLength = signedRadius * omega;
        }
        previousRadius = radius;
        float error = radius / t;
        if (!sorFail && error < candidate_error) {
            candidate_t = t;
            candidate_error = error;
        }
        if (!sorFail && error < pixelRadius || t > t_max) break;
        t += stepLength;
   	}
    if (
        (t > t_max || candidate_error > pixelRadius)
    	) return vec3(INFINITY, 0., 0.);
    
    return vec3(candidate_t, mp.yz);
}


float softShadow(vec3 ro, vec3 lp, float k) {
    const int maxIterationsShad = 20;
    vec3 rd = (lp - ro); // Unnormalized direction ray.

    float shade = .9;
    float dist = 0.25;
    float end = max(length(rd), 0.001);
    float stepDist = end / float(maxIterationsShad);

    rd /= end;
    for (int i = 0; i < maxIterationsShad; i++) {
        float h = map(ro + rd * dist).x;
        shade = min(shade, k*h/dist);
       
        dist += min(h, stepDist * 2.); 
        if (h < 0.001 || dist > end) break;
    }
    return min(max(shade, 0.7), 1.0);
}

#define EPSILON .001
vec3 getNormalHex(vec3 pos)
{
	float d=map(pos).x;
	return normalize(
        vec3(
            map(
                pos+vec3(EPSILON,0,0)).x-d,
                map(pos+vec3(0,EPSILON,0)).x-d,
                map(pos+vec3(0,0,EPSILON)).x-d 
        	)
    	);
}

#define delta vec3(.001, 0., 0.)
vec3 getNormalCube(vec3 pos)   
{    
   	return normalize(vec3( 
   		map( pos + delta.xyy ).x - map( pos - delta.xyy ).x,
   		map( pos + delta.yxy ).x - map( pos - delta.yxy ).x,
   		map( pos + delta.yyx ).x - map( pos - delta.yyx ).x
   ));
}


float getAO(vec3 hitp, vec3 normal, float dist)
{

    float sdist = map(hitp + normal * dist).x;
    return clamp(sdist / dist, 0.1, 1.0);
}

vec3 clouds(vec3 rd) {
    float ctime = t / 14.;
    vec2 uv = rd.xz / (rd.y + 0.6);

    vec3 clouds = vec3(
        fbm(
            vec3(
                uv.yx * 1.4 + vec2(ctime, 0.), ctime
            ) 
        ) * 1.5
    );
    
 
    clouds = pow(clouds, vec3(4.));

    return clamp(clouds * rd.y, 0., 1.);
}

vec3 Sky(in vec3 rd, bool showSun, vec3 lightDir)
{
   
    float sunSize = 3.;
    float sunAmount = max(dot(rd, lightDir), .5);
    float v = pow(1. - max(rd.y, .5), 4.);
    vec3 sky = fromRGB(200,200,200) * v;
    
    sky += lightColour * sunAmount * sunAmount 
        + lightColour * min(pow(sunAmount, 12.0) * sunSize, sunSize);

    return clamp(sky, 0.0, 1.0);
}

vec3 getObjectColor(vec3 p, vec3 n, vec3 obj) {
    vec3 col = vec3(1.0);
    
    if (obj.y == 2.0) 
        col = vec3(1., .5, 0.) + clamp(mod(-t + p.z, 1.) - .5, 0.0, 0.75 ) * mod(t * 4., 1.);
              
    return col;
}

vec3 doColor( in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, vec3 obj) {
	vec3 sceneCol = vec3(0.0);
    
    vec3 ld = lp - sp; // Light direction vector.
    float lDist = max(length(ld / 2.), 0.001); // Light to surface distance.
    ld /= lDist; // Normalizing the light vector.

    // Attenuating the light, based on distance.
    float atten = 1.0 / (1.0 + lDist * 0.025 + lDist * lDist * 0.02);

    // Standard diffuse term.
    float diff = max(dot(sn, ld), .1);
    // Standard specualr term.
    float spec = pow(max(dot(reflect(-ld, sn), -rd), 1.2), 2.0);

    // Coloring the object. You could set it to a single color, to
    // make things simpler, if you wanted.
    vec3 objCol = getObjectColor(sp, sn, obj);

    // Combining the above terms to produce the final scene color.
    sceneCol += (objCol * (diff + .15) * spec * 1.) * atten;

    // Return the color. Done once every pass... of which there are
    // only two, in this particular instance.
    
    return sceneCol;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    
    vec2 uv = fragCoord.xy / iResolution.xy - .5;

    uv *= tan(radians (FOV) / 2.0) * 1.1;
    
    float t2 = t;
    float 
        sk = sin(-t2 * .1) * 82.0, 
        ck = cos(-t2 * .1) * 82.0,
    	sh,
        ao,
        fog;
    
    light = vec3(20., 4., -10.);        
    
    vec3 
        vuv = vec3(0., 1., -0.), // up
    	ro = vec3(ck, -20., sk) + vec3(iMouse.x / 20.,iMouse.y / 10. - 1., 1.), // pos
    	vrp =  vec3(0., 0., 0.),
    	vpn = normalize(vrp - ro),
    	u = normalize(cross(vuv, vpn)),
    	v = cross(vpn, u),
    	vcv = (ro + vpn),
    	scrCoord = (vcv + uv.x * u * iResolution.x/iResolution.y + uv.y * v),
    	rd = normalize(scrCoord - ro),
    	sceneColor = rd,
    	tr = trace(ro, rd),
        p2,
        sn,
        sky;
    
    ro += rd * tr.x;
    
    p2 = p;
    
    sn = getNormal(ro);	
    

    fog = smoothstep(FAR * FOG, 0., tr.x) * 1.,
    sh = softShadow(ro, light, 12.),
    ao = getAO(ro, sn, 1.2);
	
    ao *= 1. + saturate(getAO(ro + sn * .2, sn, 0.5));
    ao *= saturate(getAO(ro + sn * 1.03, sn, 14.05));
    
    ro = p2; 
    
    sky = Sky(rd, true, normalize(light));
    
    if (tr.x < FAR) { 
        sceneColor = saturate(doColor(ro, rd, sn, light, tr));
        sceneColor *= ao;
        sceneColor *= sh;
        sceneColor = mix(sceneColor, sky, saturate(tr.x * 4.2 / FAR));
    } else {
        sceneColor = sky + clouds(rd);
    }

    fragColor = vec4(clamp(sceneColor, 0., 1.), 1.);
}
