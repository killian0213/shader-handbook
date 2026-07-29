// Buffer A (buffer) — Romanesco Broccoli by Klems
// https://www.shadertoy.com/view/XlcfRs

#define PI 3.14159265359
#define PHI 1.61803398875
#define rot(a) mat2(cos(a + PI*0.5*vec4(0,1,3,0)))
#define Z min(0, iFrame)

// fab's polar mod
vec2 polarRep( in vec2 p, in float n ) {
    n = PI*0.5/n;
    float a = atan(p.y, p.x);
    float r = length(p);
    a = mod(a + n/2.0, n) - n/2.0;
    p = r * vec2(cos(a), sin(a));
    return 0.5 * (p+p-vec2(1,0));
}

// iq's integer hash https://www.shadertoy.com/view/XlXcW4
const uint k = 1103515245U;
vec3 hash( uvec3 x ) {
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    return vec3(x)*(1.0/float(0xffffffffU));
}

// iq's box distance function
float sdBox( in vec2 p, in vec2 b ) {
	vec2 d = abs(p) - b;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// iq's smooth minimum
float smin( in float a, in float b, const in float s ) {
    float h = clamp( 0.5 + 0.5*(b-a)/s, 0.0, 1.0 );
    return mix(b, a, h) - h*(1.0-h)*s;
}

// iq's version of Keinert et al's inverse Spherical Fibonacci Mapping code
// https://www.shadertoy.com/view/lllXz4
vec3 inverseSF( in vec3 p, const in float n ) {
    float m = 1.0-1.0/n;
    float phi = min(atan(p.y,p.x),PI);
    float k = max(2.,floor(log(n*PI*sqrt(5.)*(1.-p.z*p.z))/log(PHI+1.)));
    float Fk = pow(PHI,k)/sqrt(5.0);
    vec2 F = vec2(round(Fk),round(Fk*PHI));
    vec2 ka = 2.0*F/n;
    vec2 kb = 2.0*PI*(fract((F+1.0)*PHI)-(PHI-1.0));    
    mat2 iB = mat2(ka.y,-ka.x,kb.y,-kb.x)/(ka.y*kb.x-ka.x*kb.y);
    vec2 c = floor(iB*vec2(phi,p.z-m));
    float d = 8.0;
    vec3 res = vec3(0);
    for(int s = Z ; s < 4 ; s++) {
        vec2 uv = vec2(float(s-2*(s/2)),float(s/2));
        float i = dot(F,uv+c);
        float phi = 2.0*PI*fract(i*PHI);
        float cT = m-2.0*i/n;
        float sT = sqrt(1.0-cT*cT);
        vec3 q = vec3(cos(phi)*sT, sin(phi)*sT,cT);
        float sqDist = dot(q-p,q-p);
        if (sqDist < d) {
            d = sqDist;
            res = q;
        }
    }
    return res;
}

// parameters of the rounded cone
#define CONE_THETA 0.7
#define CONE_RADIUS 0.3

// sub-parameters defined from above
#define CONE_LBOT (PI*0.5+CONE_THETA)
#define CONE_LFLAT ((tan(PI*0.5-CONE_THETA))*(1.0-CONE_RADIUS))
#define CONE_LTOP ((PI*0.5-CONE_THETA)*CONE_RADIUS)
#define CONE_L (CONE_LBOT+CONE_LFLAT+CONE_LTOP)
#define CONE_SLOPE vec2(cos(CONE_THETA), sin(CONE_THETA))
#define CONE_CSLOPE (CONE_SLOPE.yx*vec2(-1, 1))
#define CONE_HEIGHT length(vec2(1.0-CONE_RADIUS, CONE_LFLAT))

// remap a 2D rounded cone to a circle
vec2 remap( in vec2 p ) {
    // flip coordinates so they're easier to work with
    // we'll flip them back before returning it
    float sig = p.x > 0.0 ? +1.0: -1.0;
    p.x = abs(p.x);
    // go to polar coordinates
    float theta = 0.0;
    float radius = 0.0;
    // do the bottom part
    float botPos = atan(p.x, -p.y) / (PI*0.5+CONE_THETA);
    if (botPos < 1.0) {
        theta = (botPos * CONE_LBOT) / CONE_L;
        radius = length(p);
    } else {
        // do the flat part
        float pos = dot(p, CONE_CSLOPE);
        float flatPos = pos / CONE_LFLAT;
        if (flatPos < 1.0) {
            theta = (CONE_LBOT + flatPos*CONE_LFLAT) / CONE_L;
            radius = dot(p, CONE_SLOPE);
        } else {
            // do the top part
            p.y -= CONE_HEIGHT;
            float topPos = (atan(p.y, p.x) - CONE_THETA) / (PI*0.5-CONE_THETA);
            theta = (CONE_LBOT + CONE_LFLAT + topPos*CONE_LTOP) / CONE_L;
            radius = length(p) + (1.0 - CONE_RADIUS);
        }
    }
    // squeeze the angle toward the top of the broccoli
    theta *= theta;
    // go back to cartesian, flip the sign and return
    theta = theta * sig * PI;
    return vec2(sin(theta), -cos(theta))*radius;
}

// deform a 3D sphere to match a cone
vec3 deform( in vec3 p ) {
    // go to cylindrical coordinates
    vec2 dir = p.xy;
    float dirLen = length(dir);
    vec2 cyl = vec2(dirLen, -p.z);
    // remap a circle here to a rounded cone
    cyl = remap(cyl);
    // then go back to 3D coordinates
    return vec3(dir/dirLen*cyl.x, cyl.y);
}

// remap a sphere to a plane
vec3 deformLeaf( in vec3 p ) {
    vec2 dir = p.xy;
    float len = length(dir);
    float theta = atan(len, p.z);
    return vec3(dir/len*theta, length(p)-1.0);
}

// leaf distance function
float leaf( in vec3 p, out float c, const in bool doColor ) {
    p.z += 0.3;
    float noise = smoothstep(-1.0, 1.0, p.x);
    // deform the leaf around a sphere
    p = deformLeaf(p);
    // repeat the leaf 5 times
    p.xy = polarRep(p.xy, 1.25);
    // add a stem
    vec2 stemDim = vec2(0.85+noise*0.4, 0.0);
    float stem = sdBox( vec2(p.x, length(p.yz)), stemDim ) - 0.01;
    // twist the leaf a bit
    p.z += (1.0-cos(p.y*6.0))*0.06;
    // change its shape
    vec2 dim = vec2(0.6+noise*0.5, 0.1);
    dim.y += sin(p.x*14.0)*0.05;
    dim.y += cos(p.x*61.0)*0.02;
	// add the leaf
    float d = sdBox(p.xy, dim)-0.2;
    // flatten it
    d = max(d, abs(p.z)-0.001);
    // then smooth the stem in
    d = smin(d, stem, 0.05);
    // add veins when coloring
    if (doColor) {
        c = smoothstep(0.05, -0.02, stem);
        float tex = 1.0-textureLod(iChannel2, p.xy*vec2(1.4, 0.7), 0.0).r;
        tex *= tex; tex *= tex;
        c = min(c+tex, 1.0);
    }
    return d;
}

// parameters of the fractal formula
#define FRACTAL_LEVELS 2
#define FIBO_COUNT 100.0

// main distance function
float de( in vec3 p, out vec3 color, const in bool doColor ) {
	
    p.z = -p.z;
    vec3 pp = p;
    p = deform(p);
    float c = 1.0;
    float de = length(p)-1.0;
    float s = 1.0;
    
    for (int i = Z ; i < FRACTAL_LEVELS ; i++) {
        float f = smoothstep(-1.0, 1.5, p.z);
        vec3 onSurf = inverseSF(normalize(p), FIBO_COUNT);
        p -= onSurf;
        
        // re-orient p to aim toward the normal
        vec3 t = normalize(cross(onSurf, vec3(0, 0, 1)));
        vec3 ct = cross(onSurf, t);
        p = vec3(dot(p, t), dot(p, ct), -dot(p, onSurf));
        
        // change scale with height
        float scale = mix(3.0, 7.0, f);
        p *= scale;
        p.xy *= mix(1.5, 1.0, f);
        p = deform(p);
        
        // accumulate distance
        s *= scale;
        float deNew = (length(p)-1.0)/s;
        
        // add some fake ass AO
        if (doColor) {
            c *= mix(c, 0.5, smoothstep(0.1, 0.0, de-deNew));
        }
        
        // then accumulate distance and continue to next level
        de = smin(de, deNew, 0.1);
    }
    
    // add the leaf
    float cLeaf = 0.0;
    float deLeaf = leaf(pp*0.5, cLeaf, doColor)/0.5;
    if (de > deLeaf) {
        de = deLeaf;
        c = cLeaf;
    }
    
    // set color
    if (doColor) {
        color = mix(vec3(0.2, 0.4, 0.05), vec3(0.7, 0.8, 0.2), c);
    }
    
    // add the floor
    float deFloor = 1.4-pp.z;
    if (de > deFloor) {
        de = deFloor;
        if (doColor) {
            color = textureLod(iChannel1, pp.xy*0.1, 0.0).rgb;
            color *= color;
        }
    }
    
    return de;
}

// don't return color while raymarching or retrieving the normal
float de( in vec3 p ) {
    vec3 dummy = vec3(0);
    return de(p, dummy, false);
}

// normal function, call de() in a for loop for faster compile times.
vec3 getNormal( in vec3 p ) {
    vec4 n = vec4(0);
    for (int i = Z ; i < 4 ; i++) {
        vec4 s = vec4(p, 0);
        s[i] += 0.0001;
        n[i] = de(s.xyz);
    }
    return normalize(n.xyz-n.w);
}

// trace function, return true if we hit the sky
bool trace(in vec3 from, in vec3 dir, const in bool doNormal,
           out vec3 pos, out vec3 norm, out vec3 diff ) {
    
    float totdist = 0.0;
    bool set = false;
	for (int steps = Z ; steps < 200 ; steps++) {
		vec3 p = from + totdist * dir;
        float dist = de(p)*0.5;
		totdist += dist;
		if (dist < 0.0001) {
            set = true;
            break;
		}
	}
    
    // we've hit the sky
    if (!set) return true;
    
    // we've hit a surface
    pos = from + totdist * dir;
    if (doNormal) norm = getNormal(pos);
    de(pos, diff, true);
    return false;
}

// background color
#define colorSun vec4(1.0, 1.0, 0.8, 100000.0)
#define colorAmbient vec4(0.6, 0.7, 0.9, 1.0)
#define sunDir normalize(vec3(-3, 2, -3))
#define sunAngle 0.01
#define sunCosAngle cos(sunAngle)
vec3 getBackground( in vec3 dir ) {
    float d = dot(dir, -sunDir);
    vec3 base = colorAmbient.rgb;
    base.rgb = mix(base.rgb, colorSun.rgb, smoothstep(0.5, 1.0, d)*0.5);
    base = mix(base, colorSun.rgb, smoothstep(sunCosAngle,
                                              sunCosAngle+0.001, d));
    base = mix(base, vec3(0), step(dir.z, 0.0));
    return base.rgb;
}

// trace to a random light source
vec3 traceLight( in vec3 from, in vec3 norm, in uvec3 seed ) {
    vec3 pos = vec3(0);
    vec3 diff = vec3(0);
    vec3 dummyNorm = vec3(0);
    
    // create a random dir in a hemisphere
    vec3 rand = hash(seed);
    float dirTemp1 = 2.0*PI*rand.x;
    float dirTemp2 = sqrt(1.0-rand.y*rand.y);
    vec3 dir = vec3(
        cos(dirTemp1)*dirTemp2,
        sin(dirTemp1)*dirTemp2,
        rand.y);
    dir.z = abs(dir.z);
    
    // pick the sun more often (importance sampling)
    const float sunContrib = colorSun.a*2.0*PI*(1.0 - sunCosAngle);
    const float ambientContrib = colorAmbient.a*2.0*PI;
    const float sumContrib = sunContrib+ambientContrib;
    
    float a = sunContrib / sumContrib;
    float b = a + ambientContrib / sumContrib;
    
    if (rand.z < a) {
        const vec3 sunDirTan = normalize(cross(sunDir, vec3(0, 0, 1)));
        const vec3 sunDirCoTan = cross(sunDir, sunDirTan);
        float rot = 2.0*PI*rand.x;
        float the = acos(1.0 - rand.y*(1.0 - cos(sunAngle)));
        float sinThe = sin(the);
        dir = sunDirTan*sinThe*cos(rot) +
            sunDirCoTan*sinThe*sin(rot) - sunDir*cos(the);
    }
    
    if (trace(from, dir, false, pos, dummyNorm, diff)) {
        vec3 back = getBackground(dir);
        float l = max(0.0, dot(dir, norm));
        return back*l*sumContrib;
    } else {
        return vec3(0);
    }
}

// util function to get a different seed
uvec3 getSeed( in uvec3 seed, const in int i ) {
    seed.z = seed.z * 10U + uint(i);
    return seed;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    // initialize color from the previous frame
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    
    // reinitialize rendering when needed
    bool loaded = iChannelResolution[1].x > 0.0 && iChannelResolution[2].x > 0.0;
    if (iFrame == 0 || !loaded || iMouse.z > 0.0) fragColor = vec4(0);
    
    // decouple rendering, it can get a bit unresponsive
  	vec2 gridSize = vec2(128, 128); // increase these for good GPUs
    vec2 gridCount = floor(iResolution.xy / gridSize) + 1.0;
    vec2 inGrid = floor(fragCoord.xy / gridSize);
    float gridPos = inGrid.x + inGrid.y * gridCount.x;
    float gridPosMax = gridCount.x*gridCount.y;
    if ( mod(float(iFrame), gridPosMax) != gridPos ) return;

    // random stuff
    uvec3 seed = uvec3(fragCoord, iFrame);
    
    // apply depth of field by changing the forward vector randomly
    const float dof = 0.02;
    const vec3 up = normalize(vec3(0, 0.3, 1));
    const vec3 forwardVector = normalize(vec3(4, 2, -2));
    const vec3 forwardTan = normalize(cross(forwardVector, up));
    const vec3 forwardCoTan = cross(forwardVector, forwardTan);
    vec3 rand1 = hash(getSeed(seed, 0));
    float dofRot = 2.0*PI*rand1.x;
    float dofThe = acos(1.0 - rand1.y*(1.0 - cos(dof)));
    vec3 forward = forwardTan*sin(dofThe)*cos(dofRot) +
        forwardCoTan*sin(dofThe)*sin(dofRot) + forwardVector*cos(dofThe);
    
    // get camera
    vec3 right = normalize(cross(forward, up));
    vec3 top = cross(right, forward);
    vec3 focus = vec3(-0.55, -0.6, 1.07);
    // do antialiasing
    vec3 alias = hash(getSeed(seed, 1));
    vec2 pixelCoord = fragCoord + alias.xy - 0.5;
    vec2 uv = (pixelCoord - iResolution.xy*0.5) / iResolution.y;
    vec3 dir = normalize(forward*3.5 + right*uv.x + top*uv.y);
    vec3 from = focus - forward*7.0;
	
    // find the first position
    vec3 pos = vec3(0);
    vec3 norm = vec3(0);
    vec3 diff = vec3(0);
    vec3 color = vec3(0);
    trace(from, dir, true, pos, norm, diff);
    
    // add light from the sun/sky
    pos += norm*0.001;
    vec3 sunLight = traceLight(pos, norm, getSeed(seed, 2));
	color += diff.rgb * sunLight.rgb;

    // do bounces (increase this loop if you have a good GPU)
    vec3 acc = diff.rgb;
    for (int i = Z ; i < 2 ; i++) {
        vec3 normTan = normalize(cross(norm, vec3(1, PI, PHI)));
        vec3 normCoTan = cross(norm, normTan);
        vec3 rand = hash(getSeed(seed, 3+i*2));
        float rot = 2.0*PI*rand.x;
        float the = acos(sqrt(rand.y));
        float sinThe = sin(the);
        vec3 bounceDir = normTan*sinThe*cos(rot) +
            normCoTan*sinThe*sin(rot) + norm*cos(the);
        trace(pos, bounceDir, true, pos, norm, diff);
        vec3 bounceLight = traceLight(pos + norm*0.001, norm,
                                      getSeed(seed, 3+i*2+1));
        acc *= diff.rgb; // color keep getting absorbed
        color += acc * bounceLight;
    }
    
    // accumulate samples
    fragColor.rgb += color;
    fragColor.a += 1.0;
}