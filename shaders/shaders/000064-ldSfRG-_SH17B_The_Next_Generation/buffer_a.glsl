// Buf A (buffer) — [SH17B] The Next Generation by Klems
// https://www.shadertoy.com/view/ldSfRG


#define PI 3.14159265359
#define SQ 0.70710678118
#define BACKGROUND_SS 2
#define rot(a) mat2(cos(a + PI*0.25*vec4(0,6,2,0)))

// scenes parameters
vec4 sunPosition = vec4(0);
vec3 sunStrength = vec3(0);
float time = 0.0;

// using during warp scenes
float warp = 0.0;

// camera controls
vec3 sceneFrom = vec3(0);
vec3 shipFrom = vec3(0);
vec3 forward = vec3(0);
vec3 up = vec3(0);

// used for the travelling stars
float starsX = 0.0;

// current sequence
int sequence = 0;


bool intSphere( in vec4 sp, in vec3 ro, in vec3 rd, out float t, out vec3 n ) {
    vec3  d = ro - sp.xyz;
    float b = dot(rd,d);
    float c = dot(d,d) - sp.w*sp.w;
    float tt = b*b-c;
    if ( tt > 0.0 ) {
        t = -b-sqrt(tt);
        n = (ro+rd*t-sp.xyz)/sp.w;
        if (t>0.0) return true;
    }
    return false;
}

bool intPlane( in vec4 pl, in vec3 ro, in vec3 rd, out float t ) {
    float tt = -(dot(pl.xyz,ro)+pl.w)/dot(pl.xyz,rd);
    if (tt > 0.0) {
        t = tt;
        return true;
    }
    return false;
}

// smooth 3D noise
float noise( in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = texture( iChannel0, (uv+0.5) / 256.0 ).yx;
    return mix( rg.x, rg.y, f.z );
}

// like abs but with a rounded corner instead
float smoothAbs(float x, float radius) {
    float ab = abs(x);
    if ( ab > SQ*radius ) return ab;
    float xCirc = x/radius;
    return 2.0*SQ*radius - sqrt(1.0 - xCirc*xCirc)*radius;
}

float smin( in float a, in float b, in float r ) {
    return (a + b - smoothAbs(a - b, r*2.0))*.5;
}

float smax( in float a, in float b, in float r ) {
    return (a + b + smoothAbs(a - b, r*2.0))*.5;
}

// approximation of the distance to an ellipsoid
float sdEllipsoid( in vec3 p, in vec3 r ) {
    return (length(p/r)-1.0) * min(min(r.x,r.y),r.z);
    //return (length(p/r)-1.0) / length(normalize(p)/r);    
}

// distance to a box
float sdBox( in vec3 p, in vec3 b ) {
	vec3 d = abs(p) - b;
	return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float hash11(float p) {
    #define HASHSCALE1 .1031
	vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p3){
    #define HASHSCALE3 vec3(.1031, .1030, .0973)
	p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

// NCC-1701-D
float ncc( in vec2 uv ) {
    const ivec2 ncc1701d[] = ivec2[](ivec2(14,11),ivec2(3,11),ivec2(3,11),ivec2(13,13),ivec2(1,12),
                                     ivec2(7,12),ivec2(0,12),ivec2(1,12),ivec2(13,13),ivec2(4,11));
    uv += vec2(5.0, 0.5);
    float letter = 0.0;
    ivec2 iuv = ivec2(floor(uv));
    vec2 fuv = fract(uv);
    if( iuv.x>=0 && iuv.x<=9 && iuv.y==0 ) {
        fuv = 0.5 + vec2(0.5,1.0)*(fuv-0.5);
        float te = texture( iChannel1, ( vec2(ncc1701d[iuv.x]*64) + fuv*64.0 )/1024.0 ).w;
        letter = smoothstep( 0.02, 0.0, te-0.5 );
    }
    return letter;
}

// USS ENTERPRISE
float enterprise( in vec2 uv ) {
    const ivec2 ncc1701d[] = ivec2[](ivec2(5,10),ivec2(3,10),ivec2(3,10), ivec2(0,13),
                                     ivec2(5,11),ivec2(14,11),ivec2(4,10),ivec2(5,11),ivec2(2,10),
                                     ivec2(0,10),ivec2(2,10),ivec2(9,11),ivec2(3,10),ivec2(5,11));
    uv += vec2(7.0, 0.5);
    float letter = 0.0;
    ivec2 iuv = ivec2(floor(uv));
    vec2 fuv = fract(uv);
    if( iuv.x>=0 && iuv.x<=13 && iuv.y==0 ) {
        fuv = 0.5 + vec2(0.5,1.0)*(fuv-0.5);
        float te = texture( iChannel1, ( vec2(ncc1701d[iuv.x]*64) + fuv*64.0 )/1024.0 ).w;
        letter = smoothstep( 0.02, 0.0, te-0.5 );
    }
    return letter;
}


// window texture
void windows( in vec2 inWindow, float noWindow, inout vec4 diffuse, inout vec4 emissive) {
	vec2 window = floor(inWindow)+0.5;
    inWindow -= window;

    float border = smoothstep(0.95, 1.0, abs(sin((inWindow.x)*PI)))*noWindow;
    float win = noWindow*(1.0-border);

    vec4 rnd = texture(iChannel0, window/iChannelResolution[0].xy);
    float spec = 0.0;
    if (rnd.x < 0.7) {
        // add windows
        float deWin = sdBox( vec3(inWindow, 0), vec3(0.1, 0.1, 1) ) - 0.1;
        float winScale = smoothstep(0.1, 0.0, deWin)*win;
        spec = winScale;
        diffuse.rgb = mix(diffuse.rgb, diffuse.rgb*.2, winScale);
        // lights on some windows
        if (rnd.y < 0.4) {
            emissive.rgb += smoothstep(0.0, -0.1, deWin)*winScale*vec3(1, 1, 0.7);
        }
    }

    diffuse = mix(diffuse, diffuse*0.8, border);
    diffuse.a = mix(diffuse.a, 0.8, spec);
}

// secondary hull
float hullDE( in vec3 p, in bool doColor, out vec4 diffuse, out vec4 emissive  ) {
    
    vec3 inBot = p-vec3(13, 0, -2.5);
    inBot.z = max(0.0, abs(inBot.z)+1.0)*sign(inBot.z);
    if (inBot.z > 0.0) inBot.z = max(1.0, inBot.z-0.5);
    vec3 botDim = vec3(6.0 + smoothstep(0.0, -2.0, inBot.x)*8.0, 6, 3);
    float bot = sdEllipsoid(inBot, botDim);
    
    vec3 inCo = p-vec3(10.5, 0, 1);
    float co = sdBox(inCo, vec3(10, 5.0, 3));
    vec3 inHoles = inCo;
    inHoles.x -= 10.0;
    inHoles.y = abs(inHoles.y)-5.3;
    inHoles.z += 3.0;
    float holes = sdEllipsoid(inHoles, vec3(20, 5, 7));
    co = max(co, -holes);
    
    float coBack = dot(normalize(vec3(-1, 0, 1.2)), inCo)-1.0;
    float coFront = dot(normalize(vec3(2.1, 0, -1.0)), inCo)-7.0;
    co = max(co, coBack);
    
    float de = bot;
    de = smin(de, co, 1.0);
    de = max(de, coFront);
    
    // deflector dish
    const vec3 dishDim = vec3(2, 4, 1.2);
    vec3 inDish = p-vec3(17, 0, -2.5);
    float dish = sdEllipsoid(inDish, dishDim);
    de = max(de, -dish);
    
    if (doColor) {
        
        diffuse = vec4(0.5, 0.6, 0.7, 0.2);
        emissive = vec4(0);
        
        vec2 inWindow = vec2(0);
        float noWindow = 1.0;
        
        if (co > bot) {
            vec3 inSecon = inBot/botDim;
            float theta = atan(inSecon.x, inSecon.y);
            inWindow = vec2(theta/PI*17.0, inSecon.z*13.0);
        } else {
            inWindow = p.xz*1.5;
            noWindow = smoothstep(0.0, -0.2, coBack);
        }
        
        noWindow *= smoothstep(0.0, -0.2, coFront);
        noWindow *= smoothstep(0.4, 0.5, abs(inCo.z+3.25));
        noWindow *= smoothstep(0.1, 0.2, dish);
        
        float trans = smoothstep(0.02, 0.09, abs(co-bot));
        noWindow *= trans;
        
        windows( inWindow, noWindow, diffuse, emissive);
        diffuse.a *= (0.8+trans*0.2);
        
        // do the dish
        float dishFX = inDish.x+3.0;
        inDish.x = 0.0;
        dishFX = max(sdEllipsoid(inDish, dishDim), -dishFX);
        dishFX = smoothstep(0.1, -0.3, dishFX);
        // remove some diffuse
        diffuse.rgb = mix(diffuse.rgb, diffuse.rgb*vec3(0.1, 0.2, 0.3), dishFX);
        
        // don't light in the center
        float lenFX = length(inDish.yz/dishDim.yz);
        dishFX *= smoothstep(0.1, 0.2, abs(lenFX-0.7));
        dishFX *= smoothstep(0.3, 0.4, lenFX);
        
        emissive.rgb += dishFX*vec3(0.01, 0.05, 1.0)*20.0;
    }
    
	return de;
}

// saucer section
float saucerDE( in vec3 p, in bool doColor, out vec4 diffuse, out vec4 emissive  ) {
    
    // saucer section
    const vec3 sauDim = vec3(15, 18, 3);
    vec3 inSau = p-vec3(26, 0, 3.5);
    float sauPlane = -inSau.z;
    
    vec2 inSau2D = inSau.xy/sauDim.xy;
    float inSau2DL = length(inSau2D);
    float rim = smoothstep(0.1, 0.12, abs(inSau2DL-.6)+.1);

    inSau.z = max(0.0, abs(inSau.z)+1.0)*sign(inSau.z);
    if (inSau.z > 0.0) inSau.z = max(1.0, inSau.z-0.5);
    float saucer = sdEllipsoid(inSau, vec3(15, 18, 3));
    float saucer2 = saucer;
    saucer = max(saucer, sauPlane);
    saucer = smin(saucer, saucer2+0.7, 0.1);
    
    // add the bridge
    vec3 inBridge = inSau - vec3(0, 0, 3);
    float bridge = sdEllipsoid(inBridge, vec3(2.5, 3.2, 3));
    // blend it with the shuttle bay
    vec3 inShuttle = inSau - vec3(-5.0, 0, 2);
    inShuttle.y = smoothAbs(inShuttle.y, 1.0);
    inShuttle.xy *= rot(-0.1);
    inShuttle.xz *= rot(0.1);
    float shuttle = sdBox(inShuttle, vec3(4, 2, 1))-0.1;
    bridge = smin(bridge, shuttle, 0.5);
    bridge = smax(bridge, inBridge.z-0.3, 0.1);
    // add the rim on the top
    if (inSau.z > 0.0) saucer += rim*0.1*smoothstep(0.0, 1.0, bridge) - 0.1;
    // add the saucer with the bridge
    saucer = smin(saucer, bridge, 0.3);
    
    if (doColor) {
        
        diffuse = vec4(0.5, 0.6, 0.7, 0.2);
        emissive = vec4(0);
                
        vec2 inWindow = vec2(atan(inSau2D.y, inSau2D.x)/PI*50.0, inSau2DL*10.0+1.0);
        float noWindow = rim;
        noWindow *= smoothstep(0.92, 0.91, inSau2DL);
        noWindow *= smoothstep(1.9, 2.0, bridge);
        if (inSau.z < 0.0) noWindow *= smoothstep( 0.09, 0.08, abs(inSau2DL-0.6) );
        
        // do some checkered panels
        vec2 panels = floor(inWindow*vec2(0.2, 0.5));
        float check = mod(panels.x+panels.y, 2.0);
        check *= smoothstep(0.9, 1.0, bridge);
        diffuse *= (check*.1+.9);
        
        float letter = 0.0;
        
        vec2 inLetter = inWindow;
        if (inSau.z > 0.0) {
            inLetter -= vec2(0, 5.5);
            inLetter *= vec2(0.5, -0.8);
            noWindow *= smoothstep(0.0, 0.1, sdBox(vec3(inLetter-vec2(0, 1), 0), vec3(5.5, 1.5, 1)));
            vec2 inEnt = inLetter-vec2(0, 0.7);
            letter += enterprise(inEnt*vec2(1.7, 2.0));
        } else {
            inLetter -= vec2(0, 5.5);
            inLetter *= vec2(0.5, 0.8);
            
        }
        
        letter += ncc(inLetter);
        windows( inWindow, noWindow, diffuse, emissive);
        diffuse.rgb = mix(diffuse.rgb, vec3(0.15, 0.02, 0.02), letter);
    }
	    
    return saucer;
}

// arms connecting the nacelles to the stardrive section
float armsDE( in vec3 p, in bool doColor, out vec4 diffuse, out vec4 emissive ) {
    
    // start with the nacelles arms
    float arms = sdBox(p, vec3(6, 7.5, 0.5))-2.0;
    arms = max(arms, 2.0-sdBox(p-vec3(0, 0, 1), vec3(99, 7, 1)));
    
    vec3 inHoles = p-vec3(6, 0, -4.0);
    inHoles.y = abs(inHoles.y)-8.0;
    float holes = sdEllipsoid(inHoles, vec3(4, 5, 5));
    
    float by = abs(p.y);
    float backLen = 1.0 + smoothstep(1.0, 7.0, by)*0.7;
    float back = dot(normalize(vec3(1, 0, -0.7)), p) + backLen;
   	arms = max(arms, -back);
    arms = max(arms, -holes);
    arms = max(arms, p.z-0.5);
    
    if (doColor) {
        vec3 inCheck = p;
        inCheck.x += backLen;
       	inCheck = floor(inCheck*0.5);
        float check = mod(inCheck.x+inCheck.y+inCheck.z, 2.0);
        
        diffuse = vec4(0.5, 0.6, 0.7, 0.2);
        diffuse *= check*.1+.9;
        emissive = vec4(0);
    }
    
    return arms;
}

// nacelles
float nacellesDE( in vec3 p, in bool doColor, out vec4 diffuse, out vec4 emissive  ) {
    
    p -= vec3(2.5, 0, 1);
    p.y = abs(p.y)-9.25;
    
    float s = smoothstep(0.0, 20.0, abs(p.x+2.0));
    float de = sdBox(p, vec3(8, 1.0 - s * 1.0, 0.3-s*.5))-1.0;
    float blues = sdBox(p-vec3(-4, 0, 0), vec3(8, 20, 0.0 + 0.6*smoothstep(0.0, 3.0, p.x)))-0.5;
    float blueLight = smoothstep(0.0, -0.2, blues);
    float red = sdBox(p-vec3(+8, 0, 0), vec3(2, 20, 0))-1.1;
    float redLight = smoothstep(0.0, -0.2, red);
    
    de += blueLight*.1;
    de += redLight*.1;
    
    if (doColor) {
        diffuse = vec4(0.5, 0.6, 0.7, 0.2);
        emissive = vec4(0);
        
        diffuse = mix(diffuse, diffuse*vec4(0.1, 0.2, 0.3, 0.0), blueLight);
        diffuse = mix(diffuse, diffuse*vec4(0.3, 0.1, 0.1, 0.0), redLight);
        
        
        float more = smoothstep(0.0, 2.0, warp);
        
        emissive.rgb += smoothstep(0.1, -1.0, blues)*vec3(0.01, 0.05, 1.0)*(20.0+more*150.0);
        emissive.rgb += smoothstep(0.05, -1.0, red)*vec3(1.0, 0.02, 0.01)*5.0;
        
    }
    
    return de;
    
}


// distance/color function to a galaxy class starship
float de( in vec3 p, in bool doColor, out vec4 diffuse, out vec4 emissive ) {
    
    // flip the ship
    //p.xyz = p.yxz;
    
    float multX = 1.0;
    if (sequence == 1) {
        // change shape during warp
        multX = 1.0 + (smoothstep(2.0, 2.3, warp) - smoothstep(2.3, 3.0, warp))*1.5;
        p.x /= multX;
    }
    
    // don't go through the expensive distance field when far away from the object
    diffuse = emissive = vec4(-1);
    float bbBox = sdBox(p, vec3(25.0*multX, 18, 7));
    if (bbBox > 1.0) return bbBox;
    
    // recenter the ship around the box
    diffuse = emissive = vec4(0);
    p += vec3(17, 0, 1);
    
    // start with the secondary hull
    float de = hullDE(p, doColor, diffuse, emissive);
    vec4 newDiff = vec4(0), newEmissive = vec4(0);
    
    // then the saucer section
    float saucer = saucerDE(p, doColor, newDiff, newEmissive);
    if (saucer < de) {
        diffuse = newDiff;
        emissive = newEmissive;
        de = smin(de, saucer, 0.5);
    }
    
    // the arms connecting the nacelles to the secondary hull
    float arms = armsDE(p, doColor, newDiff, newEmissive);
    if (arms < de) {
        diffuse = newDiff;
        emissive = newEmissive;
        de = smin(de, arms, 0.3);
    }
    
    // the nacelles
    float nacelles = nacellesDE(p, doColor, newDiff, newEmissive);
    if (nacelles < de) {
        diffuse = newDiff;
        emissive = newEmissive;
        de = nacelles;
    }
    
    // thrusters
    vec3 inThrust = p - vec3(12.5, 0, 4);
    inThrust.y = abs(inThrust.y)-6.7;
    float thrust = sdBox(p - vec3(9, 0, 0.5), vec3(1, 1.5, 0.4))-0.2;
    vec3 inSecThrust = inThrust - vec3(1.5, -0.7, -0.25);
    float secThrust = sdBox(inSecThrust, vec3(1.0, 1.5, 0.0))-0.2;
    float thrustHole = sdBox(inThrust, vec3(1, 1.5, 1));
    
    de = max(de, -thrustHole);

    if (doColor) {
        if ( thrust < de || secThrust < de) {
        	
            diffuse = vec4(0.5, 0.6, 0.7, 0.2)*0.5;
        	emissive = vec4(0);
            
            
            float red = 0.0;
            
            if (thrust < secThrust) {
                red = inThrust.x+4.5;
            } else {
                red = inSecThrust.x+1.0;
            }
            
            diffuse = mix(diffuse, diffuse*vec4(0.3, 0.1, 0.1, 0.0), smoothstep(0.0, -0.1, red));
            emissive += smoothstep(-0.05, -1.0, red)*vec4(1.0, 0.02, 0.01, 0.0)*120.0;

    	}
    }

    de = min(de, thrust);
    de = min(de, secThrust);

    return de/multX;
} 

// normal function
vec3 normal(vec3 p) {
    const vec3 e = vec3(0.0, 0.001, 0.0);
    vec4 dummy = vec4(0);
    float d = de(p, false, dummy, dummy);
	return normalize(vec3(
		d-de(p-e.yxx, false, dummy, dummy),
		d-de(p-e.xyx, false, dummy, dummy),
		d-de(p-e.xxy, false, dummy, dummy)));	
}

// shadows function
float shadows( vec3 p, vec3 dir, float sinTheta ) {
    vec4 dummy = vec4(0);
    float totdist = 0.0;
    float opa = 1.0;
    for (int i = 0 ; i < 50 ; i++) {
        vec3 here = p+dir*totdist;
        float d = de(here, false, dummy, dummy);
        float prox = d / (sinTheta*totdist);
        float alpha = clamp(prox * -0.5 + 0.5, 0.0, 1.0);
        opa = min(opa, 1.0-alpha);
        //opa *= 1.0-alpha;
        if (opa < 0.01) break;
      	totdist += max(0.3, d);
    }
    return opa;
}

// filtered starfield
vec3 starfield( in vec3 dir, float position, float speed ) {
    dir.xyz = dir.yxz; // i'm lazy
    vec3 ret = vec3(0);
    vec2 dim = vec2(0.15, 0.15+speed)*0.01;
    for (float radius = 1.0 ; radius < 7.5 ; radius ++) {
        float x = atan(dir.x, dir.z)/PI;
        float scale = (radius / length(dir.xz));
        float y = dir.y * scale + position;
        vec2 uv = vec2(x, y)*vec2(6.0*radius, 1);
        vec2 cen = floor(uv)+0.5;
        vec3 rnd = hash33(vec3(cen, radius));
        cen += (2.0*rnd.xy-1.0) * (0.5 - dim);
        vec2 inStar = uv-cen;
        float dist = sdEllipsoid(vec3(inStar, 0), vec3(dim, 1));
        // get derivative, correct with the atan
        float delta = length(fwidth(abs(uv)));
        ret += smoothstep(delta/scale*2.0, 0.0, dist) / (scale*scale);
    }
    return ret;
}

// raytrace to a sun
float traceSun( in vec3 from, in vec3 dir, in vec4 sun ) {
    vec3 sunPos = sun.xyz;
    float sunRadius = sun.w;
    vec3 inSun = from-sunPos;
    float distToSun = inversesqrt(dot(inSun, inSun));
    float theta = acos(dot(-dir, inSun*distToSun));
    float maxTheta = atan(sunRadius*distToSun);
    return exp((maxTheta-theta)/sunRadius/distToSun);
}

// planets palette
vec3 pal( in float t ) {
    const vec3 a = vec3(0.3,0.2,0.1);
    const vec3 b = vec3(0.2,0.1,0.1);
    const vec3 c = vec3(0.4,2.7,4.2);
    return a + b*cos( 6.28318*(c*t) );
}

// raytrace to a planet
void tracePlanet( inout float maxDist, inout vec3 rgb,
                 in vec3 from, in vec3 dir, in vec4 planet, in float seed ) {
    float dist = 0.0;
    vec3 norm = vec3(0);
    
    if ( intSphere(planet, from, dir, dist, norm) ) {
        if (dist < maxDist) {
            maxDist = dist;
            
            // change color
            vec3 toSun = normalize(sunPosition.xyz-(from+dir*dist));
            
            float perl = 0.0;
            perl += noise(norm*1.0)*2.0;
            perl += noise(norm*3.0)*1.0;
            perl += noise(norm*6.0)*1.0;
            perl += noise(norm*12.0)*0.5;
            perl /= 4.5;
            vec3 baseColor = pal(seed+perl*0.4);
            
            // add spiral clouds
            vec3 inClouds = norm;
            inClouds.xy *= rot(inClouds.z*2.0+time*0.2);
            float clouds = 1.0;
            clouds *= sin(atan(inClouds.x, inClouds.y)*5.0)*0.5+0.5;
            clouds *= smoothstep(1.0, 0.9, abs(inClouds.z));
            clouds *= noise(inClouds*5.0);
            
            baseColor = mix(baseColor, vec3(1), clouds*0.5);
            
            // lighting
            rgb = baseColor * vec3(max(0.0, dot(toSun, norm)))*sunStrength;
            
        }
    }
}


// introduction background
vec3 background01( in vec3 from, in vec3 dir ) {
    vec3 base = starfield( dir, 0.0, 0.0 );
    base += traceSun(from, dir, vec4(0, 0, 0, 1)) * vec3(1.0, 0.8, 0.7) * 3.0;
    base += traceSun(from, dir, vec4(-5, -80, -10, 0.5)) * vec3(0.35, 0.3, 1.0) * 2.0;
    
    // add a nebula
    dir.yz *= rot(-0.2);
    dir.xy *= rot(0.7);
    
    vec2 inNebula = dir.xz;
    float radNeb = 1.0 + sin(atan(inNebula.x, inNebula.y)*8.0)*0.05;
    float nebulaDist = length(inNebula/vec2(0.07, 0.4)) - radNeb;
    float nebula = exp(-1.0-nebulaDist*3.0);
    
    float perl = 0.0;
    perl += noise(dir*10.0)*3.0;
    perl += noise(dir*30.0)*1.0;
    perl += noise(dir*60.0)*0.5;
    perl /= 4.5;
    
    vec3 newDir = dir;
    newDir.z *= 0.2;
    newDir.z += time*0.01;
    
    float perl2 = 0.0;
    perl2 += noise(newDir*32.0)*2.0;
    perl2 += noise(newDir*80.0)*1.0;
    perl2 /= 3.0;
    
    perl *= perl2;
    
    vec3 nebColor = mix(vec3(0.2, 0.15, 0.5), vec3(0.15, 0.3, 0.7), noise(dir*20.0));
    
    base += nebula*perl*nebColor;
    base += exp(-4.0-nebulaDist*6.0)*vec3(0.17, 0.15, 0.3);
    
    return base;
}

vec3 glare( in vec3 dir ) {
    // add a glare during warp
    vec2 inGlare = dir.yz;
    float radGl = 0.07 + sin(atan(inGlare.x, inGlare.y)*8.0)*0.01;
    inGlare.x *= 3.0;
    inGlare *= 1.3;
    float glareDist = length(inGlare)-radGl;
    
    float glare = exp(-glareDist*20.0);
    
    glare *= smoothstep(4.2, 4.6, warp);
    glare *= smoothstep(7.0, 5.0, warp);
    
    return glare*vec3(0.55, 0.5, 1.0);
}



// second background, enterprise goes to warp
vec3 background02( in vec3 from, in vec3 dir ) {
    
    float dist = 9e9;
    vec3 base = starfield( dir, 0.0, 0.0 );
    
    base += traceSun(from, dir, sunPosition)*sunStrength*15.0;
    
    const vec4 gasGiant = vec4(3, 0, 0, 5);
    tracePlanet( dist, base, from, dir, gasGiant, -0.1 );
    tracePlanet( dist, base, from, dir, vec4(12, -44, 0, 2), 1.0 );
    tracePlanet( dist, base, from, dir, vec4(25, -57, 3, 2.5), 2.0 );
    
    // trace rings around the first planet
    float distRing = 0.0;
    vec3 dirPlane = normalize(vec3(0.2, -0.3, 1));
    
    bool hitRing = intPlane( vec4(dirPlane, -dot(dirPlane, gasGiant.xyz)), from, dir, distRing );
    if (hitRing && distRing < dist) {
        
        vec3 onRing = from+dir*distRing;
        float len = length(onRing - gasGiant.xyz);
        
        float ringAlpha = smoothstep(6.0, 6.5, len) * smoothstep(10.5, 10.0, len);
        vec3 baseColor = vec3(0.9);
        baseColor = mix(vec3(0.3, 0.2, 0.1), vec3(0.1, 0.0, 0.0), 
                        (sin(len*5.0)+sin(len*12.13))*0.3+.5 );
        baseColor *= sunStrength;
        ringAlpha = ringAlpha*smoothstep(0.0, 0.1, (sin(len*3.124)*0.5+0.5));
        
        float dummy1 = 0.0;
        vec3 dummy2 = vec3(0);
        if ( intSphere(gasGiant, onRing, normalize(sunPosition.xyz-onRing), dummy1, dummy2) ) {
            baseColor *= 0.0;
        }
        
        base = mix(base, baseColor, ringAlpha);
    }
    
    // add a glare during warp
	base += glare(dir);
    
    return base;
}

// third background, moving stars
vec3 background03( in vec3 from, in vec3 dir ) {
    vec3 base = starfield( dir, starsX, 0.3 + smoothstep(1.0, 3.0, warp) );
    
    // add a glare during warp
	base += glare(dir);
    
    return base;
}


// handle camera positions, background, lightsources, etc
int sequencer( in float time ) {
    
    int sequence = 0;
    
    if (time < 9.0) {
        sequence = 0;
    } else if (time < 52.0) {
        sequence = 1;
    } else if (time < 58.0) {
        sequence = 2;
    } else if (time < 62.0) {
        sequence = 3;
    } else if (time < 67.0) {
        sequence = 4;
    } else {
        sequence = 5;
    }
    
    if (sequence == 0) {
        
        // introduction with fading into star
        shipFrom = vec3(0, 1000, 0);
        sceneFrom = vec3(0, -200, 0);
        sceneFrom.y += time*22.5;
        forward = vec3(0, 1, 0);
        forward.xy*=rot(smoothstep(0.0, 9.0, time)*0.7-0.7);
        forward.xz*=rot(smoothstep(0.0, 9.0, time)*0.9-0.9);
        up = vec3(0, 0.5, 1);
        
    } else if (sequence == 1) {
        
        // planetary system + camera moving toward the ship + warp speed
        
        // add the main lightsource
        sunPosition = vec4(60, -35, 2, 0.5);
		sunStrength = vec3(1.5, 1.5, 1.9)*2.0;
    	
        shipFrom = vec3(80, -45, -5);
        sceneFrom = vec3(7, -70, 7);
        sceneFrom.y += smoothstep(9.0, 35.0, time)*60.0;
        
        forward = vec3(0, 1, 0);
        
        forward.xy*=rot(0.8 - smoothstep(9.0, 27.0, time)*0.6);
        forward.xz*=rot(0.3 + smoothstep(9.0, 27.0, time)*1.2);
        
        // rotate toward the ship
        forward.xy *= rot(-smoothstep(28.0, 35.0, time)*1.0);
        forward.xz *=rot(smoothstep(27.0, 34.0, time)*0.3);
        // travel alongside it
        shipFrom.x -= smoothstep(33.0, 48.0, time)*130.0;
        shipFrom.z += smoothstep(37.0, 47.0, time)*15.0;
        shipFrom.y += smoothstep(40.0, 47.5, time)*34.0;
        
        // turn to match the ship
        forward.yz *= rot(smoothstep(35.0, 48.0, time)*0.4);
        forward.xy *= rot(smoothstep(36.0, 48.0, time)*2.4);
        
        // set the warp value
        warp = max(0.0, time - 44.75);
        float pos = max(0.0, warp-2.0);
        shipFrom.x -= (pos*pos*500.0);
        
        up = vec3(0, 0, 1);
        
    } else if (sequence == 2) {
        
        // first flyby
        shipFrom = vec3(230, -15, -5);
        sceneFrom = vec3(0);
        shipFrom.x -= (time-52.0)*53.0;
        starsX += time*2.0;
        forward = vec3(-1, 0, 0);
        up = vec3(0, 0, 1);
        forward.xy *= rot(smoothstep(51.0, 60.0, time)*0.3);
        forward.yz *= rot(smoothstep(51.0, 59.0, time)*-0.3);
        
    } else if (sequence == 3) {
        
        // second flyby
        shipFrom = vec3(150, 10, 20);
        sceneFrom = vec3(0);
        shipFrom.x -= (time-58.0)*44.0;
        starsX += time*2.0;
        forward = vec3(-1, 0, 0);
        up = vec3(0, 0, 1);
        forward.xy *= rot(smoothstep(56.0, 65.0, time)*-0.4);
        forward.xz *= rot(-0.1+smoothstep(56.0, 65.0, time)*-0.5);
        
    } else if (sequence == 4) {
        
        // third flyby
        shipFrom = vec3(150, -5, -20);
        sceneFrom = vec3(0);
        shipFrom.x -= (time-62.0)*43.0;
        starsX += time*2.0;
        forward = vec3(-1, 0, 0);
        up = vec3(0, 0, 1);
        forward.xy *= rot(smoothstep(60.0, 68.0, time)*0.3);
        forward.xz *= rot(0.1-smoothstep(61.0, 68.0, time)*-1.0);
        
        
    } else if (sequence == 5) {
        
        // look at the ship, go behind it then warp
        shipFrom = vec3(-150, -8, 20);
        sceneFrom = vec3(0);
        
        // go toward the ship, then rotate around it
        shipFrom.x += smoothstep(65.0, 75.0, time)*100.0;
        shipFrom.x += smoothstep(75.0, 90.0, time)*30.0;
        shipFrom.xy *= rot(-smoothstep(68.0, 92.0, time)*2.0*PI);
        
        // go behind the ship while preparing for warpspeed
        shipFrom = mix(shipFrom, vec3(-40, -4, 5), smoothstep(80.0, 95.0, time));
        
        // set the warp value
        warp = max(0.0, time - 93.0);
        float pos = max(0.0, warp-2.0);
        shipFrom.x -= (pos*pos*500.0);
        
        starsX += time*2.0 + max(0.0, warp-2.0)*8.0;
        
        forward = normalize(-shipFrom);
        up = vec3(0, 0, 1);
        
    }

    return sequence;
    
}

// direction fonction, from forward/right/up and uv
vec3 getDir( in vec2 fragCoord ) {
    vec2 uv = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
	uv.x *= iResolution.x / iResolution.y;
    
    //get direction
    vec3 right = normalize(cross(up, forward));
    up = cross(forward, right);
    vec3 dir = normalize(forward*3.0 - right*uv.x + up*uv.y);
    
    return dir;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    // get sequence
    time = iChannelTime[3];
    sequence = sequencer(time);
    
    // get direction
    vec3 dir = getDir(fragCoord);

    vec3 rnd = hash33(vec3(fragCoord, iFrame));
    vec4 dummy = vec4(0);
	vec3 p = vec3(0);
    float totdist = 0.0;
    vec4 diffuse = vec4(-1);
    vec4 emissive = vec4(-1);

    // trace to the ship
    for (int steps = 0 ; steps < 250 ; steps++) {
        p = shipFrom + totdist * dir;
        float d = de(p, false, dummy, dummy)*1.0;
        totdist += d*0.9;
        if (d < 0.001) {
            break;
        }
    }

    // pick color
    p = shipFrom + totdist * dir;
    de(p, true, diffuse, emissive);
    
    // supersample the background
    fragColor.rgb = vec3(0);
    for (int x = 0 ; x < BACKGROUND_SS ; x++) {
        for (int y = 0 ; y < BACKGROUND_SS ; y++) {
            vec2 offset = (vec2(x, y) + 0.5) / float(BACKGROUND_SS) - 0.5;
            vec3 ssDir = getDir(fragCoord.xy + offset);
            if (sequence == 0) {
                fragColor.rgb += background01(sceneFrom, ssDir);
            } else if (sequence == 1) {
                fragColor.rgb += background02(sceneFrom, ssDir);
            } else {
                fragColor.rgb += background03(sceneFrom, ssDir);
            }
        }
    }
    
    fragColor.rgb /= float(BACKGROUND_SS*BACKGROUND_SS);

    
    // diffuse color is positive, we found the ship
    if (diffuse.r > 0.0) {
        
        fragColor.rgb = vec3(0.0);
        vec3 n = normal(p);
    
        // add 2 lights
        vec3 dir1 = normalize(vec3(-7, -8, 4));
        
        float cos1 = dot(dir1, n);
        float vis = cos1>0.0?shadows(p+n*.1, dir1, 0.01):0.0;
        fragColor.rgb += diffuse.rgb*max(0.0, cos1)*vec3(1.5, 1.5, 1.9)*vis*.8;

        float refl = pow(max(0.0, dot(reflect(dir, n), dir1)), 1.0/diffuse.a);
        fragColor.rgb += diffuse.rgb*vec3(1.5, 1.5, 1.9)*refl*vis;

        vec3 dir2 = normalize(vec3(6, 2, -3));
        fragColor.rgb += diffuse.rgb*max(0.0, dot(dir2, n))*vec3(0.0, 0.1, 0.3)*.1;

        fragColor.rgb += diffuse.rgb*vec3(0.1, 0.1, 0.15)*0.1;

        // add the emissive
        fragColor.rgb += emissive.rgb;
        
    }
    
    // dithering 
    fragColor.rgb += (rnd-0.5)/255.0*0.375;
    fragColor.rgb = max(vec3(0), fragColor.rgb);
    
    // fade the picture
    fragColor.rgb = mix(fragColor.rgb, vec3(1), smoothstep(1.0, 0.2, abs(time-9.0)));
    fragColor.rgb = mix(fragColor.rgb, vec3(0), smoothstep(1.0, 0.0, time));
    fragColor.rgb = mix(fragColor.rgb, vec3(0), smoothstep(99.0, 100.0, time));
    
    fragColor.a = 1.0;

}