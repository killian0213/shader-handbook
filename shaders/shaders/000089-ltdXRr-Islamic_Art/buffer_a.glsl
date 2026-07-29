// Buffer A (buffer) — Islamic Art by Klems
// https://www.shadertoy.com/view/ltdXRr

#define PI 3.14159265359
#define PHI 1.61803398875
#define rot(a) mat2(cos(a + PI*0.5*vec4(0,3,1,0)))
#define Z min(0, iFrame)

// size of a carpet, also the dimensions of 4 pillars
const vec2 carpetSize = vec2(PHI, 1);
// number of pillars
const vec2 pillarsSize = vec2(8, 4);
// distance from axis to windows
const float lenWind = carpetSize.y*(pillarsSize.y-1.0)*0.5;
// colors
const vec3 lightWalls = vec3(1.0, 0.9, 0.85);
const vec3 darkWalls = vec3(0.7, 0.65, 0.6);
const vec3 darkRed = vec3(0.1, 0.01, 0.01);

// iq's integer hash https://www.shadertoy.com/view/XlXcW4
const uint k = 1103515245U;
vec3 hash( uvec3 x ) {
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    return vec3(x)*(1.0/float(0xffffffffU));
}

// iq's functions
float smin( in float a, in float b, in float s) {
    float h = clamp( 0.5 + 0.5*(b-a)/s, 0. , 1.);
    return mix(b, a, h) - h*(1.0-h)*s;
}

float smax( in float a, in float b, in float s ) {
    float h = clamp( 0.5 + 0.5*(a-b)/s, 0., 1.);
    return mix(b, a, h) + h*(1.0-h)*s;
}

float sdBox( in vec3 p, in vec3 b ) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
	rgb = rgb*rgb*(3.0-2.0*rgb);
	return c.z * mix( vec3(1.0), rgb, c.y);
}

// arch distance
float arch( in vec2 p ) {
    const float d = 0.2;
    float base = length(abs(p) + vec2(d, 0)) - d;
    return base;
}

// wall tiles deformation
float tileBump( in vec3 p ) {
    const vec3 tileSize = vec3(0.2, 0.2, 0.072);
    p /= tileSize;
    p += PHI*vec3(1, 2, 6);
    p.xy += mod(floor(p.z), 5.0)/3.0;
    vec3 inTile = (fract(p) * 2.0 - 1.0);
    vec3 bump = smoothstep(0.9, 1.0, abs(inTile));
   	return max(max(bump.x, bump.y), bump.z);
}

// window recess
float window( in vec3 p ) {
    vec3 inArch = p - vec3(0.0, 0.0, 1.1);
    inArch.z = max(0.0, inArch.z);
    float dist = arch(inArch.xz)-0.6;
    dist = max(dist, abs(p.y)-0.4);
    dist = max(dist, -p.z);
    return dist;
}

// pillar
float pillar( in vec3 p, out vec4 color, in bool doColor ) {
    
    // cylindrical pillar
    float cyl = length(p.xy) - 0.12;
    
    // add spiral grooves
    float theta = atan(p.y, p.x) * 27.0;
    theta += smin(smax(p.z, 0.1, 0.02), 0.75, 0.02)*200.0;
    float grooves = (sin(theta)*0.5+0.5)*smoothstep(0.85, 0.82, p.z);
	cyl += grooves*0.008;
    cyl = max(cyl, p.z-0.93);
    
    // add a box
    float cube = sdBox(p-vec3(0, 0, 6.2), vec3(vec2(0.15), 5.2));
    float de = smin(cube, cyl, 0.2);
    
    // color with grooves
    if (doColor) {
        color = mix(vec4(lightWalls, 0.4), vec4(darkWalls, 0.2), grooves);
    }
        
    return de;
}

// roof texture (fractal+border)
float roof( in vec3 p, out vec4 color, in bool doColor ) {
    
    // base plane
    float distCube = -p.z;
    
    // add archs
    float le1 = arch(p.xz)-carpetSize.x*0.5+0.15;
    float le2 = arch(p.yz)-carpetSize.y*0.5+0.15;
    float le3 = -p.z+0.01;
    
    float seed = step(le2, le1);
    float border = smoothstep(0.022, 0.02, min(max(le1, le2), -le3));
	
    float de = max(distCube, -min(le1, le2));
    
    // add fractal tiles
    if (doColor) {
        
        float scale = 0.0;
        vec2 uv = p.xy;
        
    	// accumulated alpha and color
    	float alpha = 0.0;
        color = vec4(vec3(0), 0.7);
        uv *= 0.05;

        for (int i = 0 ; i < 10 ; i++) {
            float s = 2.0;
            uv = 1.0 - abs(s*fract(uv-0.5)-s*0.5);
            float theta = float(i) * PI * 0.125;
            theta += seed * PI * 0.172;
            uv.xy *= rot(theta);
            scale *= s;
            
            if (i < 5) continue;
            
            vec2 ab = abs(uv);
			float tileDist = length(uv)-0.3;
            tileDist = min(tileDist, min(ab.x, ab.y)-0.1);

            if (doColor) {
                vec3 c = hsv2rgb(vec3(float(i)*0.02 + seed*0.06+0.9, 0.9, 0.8));
                c = mix(c, vec3(0.02), smoothstep(0.008, 0.02, tileDist));
                float f = smoothstep(0.05, 0.04, tileDist);
                c *= f;

                color.rgb = (1.0-alpha)*c+color.rgb;
        		alpha = (1.0-alpha)*f+alpha;
            }
        }
        
        color.rgb = mix(vec3(0.4, 0.01, 0.01), color.rgb, alpha);

        // remove tiles, add a rim
        color = mix(color, vec4(darkRed, 0.4), border);
        de -= border*0.002;
    }
    
    return de;
}

// floor texture
vec4 carpetFloor( in vec3 p, in float bump ) {
    
    vec3 carpetCenter = vec3(floor( p.xy / carpetSize + 0.5 ), 0.0);
    carpetCenter.y = min(1.0, carpetCenter.y);
    carpetCenter.xy *= carpetSize;
    float seed = cos(dot(carpetCenter.xy, vec2(123.331, 442.341)))*0.5+0.5;
    
    vec3 inCarpet = p - carpetCenter;
    inCarpet.xy *= rot(seed*0.03);
    
    // add a border
    vec2 inBorder = abs(inCarpet.xy) - carpetSize*0.5 + vec2(0.17, 0.03);
    float border = max(inBorder.x, inBorder.y);
        
    // fractal formula
    float scale = 1.0;
    // accumulated alpha
    float alpha = 0.0;
    // accumulated color
    vec3 color = vec3(0);
    
    // fractal patterns
    vec2 uv = inCarpet.xy;
    uv *= 0.1;
    for (int i = 0 ; i < 11 ; i++) {
        float s = 2.0;
        uv = 1.0 - abs(s*fract(uv-0.5)-s*0.5);
        float theta = float(i) * PI * PHI + seed*0.1;
        uv *= rot(theta);
        scale *= s;
        
        if (i < 5) continue;
        
        vec2 ab = abs(uv);
        float helix = length(uv) - sin(atan(uv.y, uv.x)* 6.0)*0.1-0.5;
        float dist = min(min(ab.x, ab.y)+0.1, helix);
        float f = smoothstep(0.2, 0.18, dist);
        vec3 c = hsv2rgb(vec3(float(i)*0.03 - 0.15 - seed*0.04, 0.9, 0.9));
        c = mix(c, darkRed, smoothstep(0.12, 0.15, dist));
        
        c *= f;
        
        color = (1.0-alpha)*c+color;
        alpha = (1.0-alpha)*f+alpha;
    }

    vec4 carpetColor = vec4(mix(vec3(0.3, 0.01, 0.01), color, alpha), 0.0);
    // add a border
    carpetColor.rgb = mix(carpetColor.rgb, darkRed, smoothstep(-0.06, -0.04, border));
    // mix carpet color with white border
    carpetColor = mix(carpetColor, vec4(vec3(0.9), 0.0), smoothstep(-0.04, -0.03, border));
    // and mix with floor
    vec4 floorColor = mix(vec4(darkWalls, 0.4), vec4(darkWalls*0.5, 0.3), bump);
    carpetColor = mix(carpetColor, floorColor, smoothstep(0.0, 0.01, border));
    
    return carpetColor;
    
}

// main distance function
float de( in vec3 p, out vec4 color, in bool doColor ) {
    
    float stepWind = smoothstep(lenWind-0.09, lenWind-0.05, p.y);
    float stepFloor = smoothstep(0.02, 0.01, p.z);

    // borders of the room
    vec3 inRoom = abs(p - vec3(0, 0, 1.5)) - vec3(carpetSize*(pillarsSize-vec2(1)), 3)*0.5;
    float distRoom = -max(max(inRoom.x, inRoom.y), inRoom.z);
    float bump = tileBump(p);
    distRoom += bump*0.004*(1.0-stepWind)*(1.0-stepFloor);
    // add windows
    vec3 pWindow = p - vec3(0, lenWind, 0);
    vec3 windowCenter = vec3(floor( pWindow.x / carpetSize.x + 0.5) * carpetSize.x, 0.0, 0.0);
    float distWindow = window(pWindow - windowCenter);
    distRoom = max(distRoom, -distWindow);
    
    // center of the nearest pillar
    vec3 pPillar = p + vec3(carpetSize*0.5, 0);
    vec3 pillarCenter = vec3(floor( pPillar.xy / carpetSize + 0.5 ) * carpetSize, 0.0);
    vec4 pillarColor = vec4(0);
    float distPillar = pillar(pPillar - pillarCenter, pillarColor, doColor);
    
    // roof
    vec3 roofCenter = vec3(floor( p.xy / carpetSize + 0.5) * carpetSize, 1.1);
    vec4 roofColor = vec4(0);
    float distRoof = roof( p - roofCenter, roofColor, doColor );
    
    float de = min(distPillar, distRoom);
    de = min(de, distRoof);
    
    if (doColor) {
        if (de == distPillar) {
            color = pillarColor;
        } else if (de == distRoom) {
            color = vec4(darkWalls, 0.6);
            color = mix(color, vec4(0.0), (bump*bump)*0.5),
            color = mix(color, vec4(lightWalls, 0.2), stepWind);
            color = mix(color, carpetFloor(p, bump), stepFloor);
        } else {
            color = roofColor;
            // blend with borders
            color.rgb = mix(color.rgb, darkRed, smoothstep(-0.04, -0.03, abs(p.y)-lenWind));
        }
    }
    
    return de;
    
}

// stained glass texture
vec4 glass( in vec3 p ) {
    
    // get distance to the scene to add wood borders first
    vec4 dummyColor = vec4(0);
    float borderDist = de(p, dummyColor, false)-0.04;
    borderDist = min(borderDist, p.z-0.2);
    
    // transform uv to a grid domain
    vec2 sizeBorder = vec2(0.28, 0.8);
    vec2 uv = p.xz;
    uv.x = mod(uv.x-carpetSize.x*0.5, carpetSize.x)-carpetSize.x*0.5;
    float seed = 0.0;
    
    if (uv.y > 1.0) {
        sizeBorder = vec2(sizeBorder.x*2.0, 0.5);
        seed = 15.0+floor(abs(uv.x) / sizeBorder.x + 0.5);
        uv.x = mod(uv.x, sizeBorder.x);
        uv += vec2(sizeBorder.x*0.5, 1.0);
    } else {
        seed = floor(abs(uv.x) / sizeBorder.x);
        uv.x = mod(uv.x, sizeBorder.x);
        uv += vec2(0.0, 0.6);
    }
    
    seed += floor(p.x / carpetSize.x + 0.5) * 100.0;
    uv = mod(uv, sizeBorder) - sizeBorder*0.5;
    
    // create border
    vec2 grid = abs(uv) - sizeBorder*0.5;
    float borderGrid = -max(grid.x, grid.y);
    borderDist = min(borderDist, borderGrid);
   	float border = step(borderDist, 0.03);
    vec3 bb = mix(vec3(0.2, 0.05, 0.05), vec3(0.05), smoothstep(0.00, 0.018, borderDist));
    float borderShadows = clamp(exp(-borderDist*16.0)*0.6, border, 1.0);
	vec4 borderColor = vec4(bb, borderShadows);
    
    // fractal patterns
    float scale = 1.0;
    vec3 color = vec3(0.0);
    uv *= 0.15;
    for (int i = 0 ; i < 7 ; i++) {
        float s = 2.0;
        uv = 1.0 - abs(s*fract(uv-0.5)-s*0.5);
        float theta = float(i) * PI / PHI + seed*0.26;
        uv.x = abs(uv.x);
        uv *= rot(theta);
        scale *= s;
    }
    
    float d = mod(floor(uv.x*3.0), 3.0);
    vec3 hsv = vec3(fract(seed*0.442)*0.52 + d*0.1 - 0.1, 0.97, 0.97);
    color = hsv2rgb( hsv );

    // add border and shadows to the glass
    color = mix(color, borderColor.rgb, borderColor.a);
    return vec4(color, border);
}


// normal function
vec3 normal( in vec3 p ) {
    vec4 dummyColor = vec4(0);
	vec3 e = vec3(0.0, 0.0001, 0.0);
    float d = de(p, dummyColor, false);
	return normalize(vec3(
		d-de(p-e.yxx, dummyColor, false),
		d-de(p-e.xyx, dummyColor, false),
		d-de(p-e.xxy, dummyColor, false)));	
}

// trace function, return true if we hit the light source
bool trace( in vec3 from, in vec3 dir, in bool doNormal, out vec3 pos, out vec3 norm, out vec4 diff ) {
    
    // raymarch to the scene
    float totdist = 0.0;
	bool set = false;
	for (int steps = Z ; steps < 150 ; steps++) {
		if (set) continue;
		vec3 p = from + totdist * dir;
		float dist = de(p, diff, false)*0.95;
		totdist += dist;
		if (dist < 0.0001) {
			set = true;
		}
	}
    
    // raytrace to the lighting source (windows)
    float yWind = lenWind + 0.2 - from.y;
    float distWind = yWind / dir.y;
    if (distWind < totdist && distWind > 0.0) {
        pos = from + distWind * dir;
        if (doNormal) norm = vec3(0, -1, 0);
        diff = glass(pos);
        return true;
    }
    
    // otherwise we hit the scene
    pos = from + totdist * dir;
    if (doNormal) norm = normal(pos);
    de(pos, diff, true);
    
    return false;
}

// background color
const vec4 colorSun = vec4(1.0, 1.0, 0.8, 100000.0);
const vec4 colorAmbient = vec4(0.6, 0.7, 0.9, 1.0);
const vec4 colorGround = vec4(0.3, 0.2, 0.2, 0.5);
const vec3 sunDir = normalize(vec3(0.25, -1.0, -0.98));
const float sunAngle = 0.01;
const float sunCosAngle = cos(sunAngle);
vec3 getBackground( in vec3 dir ) {
    float d = dot(dir, -sunDir);
    vec3 base = colorAmbient.rgb;
    base.rgb = mix(base.rgb, colorSun.rgb, smoothstep(0.5, 1.0, d)*0.5);
    base = mix(base, colorSun.rgb, smoothstep(sunCosAngle, sunCosAngle+0.001, d));
    base = mix(base, colorGround.rgb, step(dir.z, 0.0));
    return base.rgb;
}

// trace to a random light source (the sky)
vec3 traceLight( in vec3 from, in vec3 norm, in uvec3 seed ) {
    
    vec3 pos = vec3(0);
    vec4 diff = vec4(0);
    vec3 dummyNorm = vec3(0);
    
    // create a random dir in a hemisphere
    vec3 rand = hash(seed);
    float dirTemp1 = 2.0*PI*rand.x;
    float dirTemp2 = sqrt(1.0-rand.y*rand.y);
    vec3 dir = vec3(
        cos(dirTemp1)*dirTemp2,
        sin(dirTemp1)*dirTemp2,
        rand.y);
    dir.y = abs(dir.y);
    
    // pick the sun more often (priority sampling)
    const float sunContrib = colorSun.a*2.0*PI*(1.0 - sunCosAngle);
    const float ambientContrib = colorAmbient.a*2.0*PI;
    const float groundContrib = colorGround.a*2.0*PI;
    const float sumContrib = sunContrib+ambientContrib+groundContrib;
    
    float a = sunContrib / sumContrib;
    float b = a + ambientContrib / sumContrib;
    
    if (rand.z < a) {
        const vec3 sunDirTan = normalize(cross(sunDir, vec3(0, 0, 1)));
        const vec3 sunDirCoTan = cross(sunDir, sunDirTan);
        float rot = 2.0*PI*rand.x;
        float the = acos(1.0 - rand.y*(1.0 - cos(sunAngle)));
        float sinThe = sin(the);
        dir = sunDirTan*sinThe*cos(rot) + sunDirCoTan*sinThe*sin(rot) - sunDir*cos(the);
    } else if (rand.z < b) {
        dir.z = abs(dir.z);
    } else {
        dir.z = -abs(dir.z);
    }
    
    if (trace(from, dir, false, pos, dummyNorm, diff)) {
        vec3 back = getBackground(dir);
        vec3 color = back.rgb * diff.rgb * (1.0 - diff.a);
        float l = dot(norm, norm) > 0.0 ? max(0.0, dot(dir, norm)) : 1.0;
        return color*l*sumContrib;
    } else {
        return vec3(0);
    }
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    // initialize color
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    if (iFrame == 0 || iMouse.z > 0.0) fragColor = vec4(0);
    
    // decouple rendering, it can get a bit unresponsive
  	vec2 gridSize = vec2(256, 256); // increase these number if you have a good GPU
    vec2 gridCount = floor(iResolution.xy / gridSize) + 1.0;
    vec2 inGrid = floor(fragCoord.xy / gridSize);
    float gridPos = inGrid.x + inGrid.y * gridCount.x;
    float gridPosMax = gridCount.x*gridCount.y;
    if ( mod(float(iFrame), gridPosMax) != gridPos ) return;
    
    
    // seed
    uvec3 seed = uvec3(fragCoord.xy, iFrame*20);
    vec3 rand = hash(seed);
    
    // cylindrical projection
    vec2 alias = rand.xy - 0.5;
    vec2 uv = (fragCoord.xy+alias) / iResolution.xy * 2.0 - 1.0;
	uv.y *= iResolution.y / iResolution.x;
    float theta = (PI*0.5 + uv.x)*1.5;
    vec2 dirPos = vec2(cos(theta), sin(theta));
	vec3 dir = normalize(vec3(dirPos.xy, uv.y*1.8));
	dir.xy *= rot(1.2);
    
    vec3 from = vec3(-0.1, -0.5, 0.5);
    
    // find the first position
    vec3 pos = vec3(0);
    vec3 norm = vec3(0);
    vec4 diff = vec4(0);
    vec3 color = vec3(0);
    if (trace(from, dir, true, pos, norm, diff)) {
        // direct lighting
        color += diff.rgb*(1.0-diff.a)*1.5;
    }
    
    // add light from the sun/sky
    pos += norm*0.001;
    vec3 sunLight = traceLight(pos, norm, seed+uvec3(0, 0, 1));
	color += diff.rgb * sunLight.rgb;
    
    // add volumetrics
    vec3 posVol = from + (pos-from)*rand.z;
    vec3 sunLightVol = traceLight(posVol, vec3(0), seed+uvec3(0, 0, 2));
    color += sunLightVol*0.1; // super fake (the fog is emissive)
    
    // do bounces (increase this loop if you have a good GPU)
    vec3 acc = diff.rgb;
    for (int i = Z ; i < 4 ; i++) {
        vec3 normTan = normalize(cross(norm, vec3(1, PI, PHI)));
        vec3 normCoTan = cross(norm, normTan);
        vec3 rand = hash(seed+uvec3(0, 0, 3+2*i));
        float rot = 2.0*PI*rand.x;
        float the = acos(sqrt(rand.y));
        float sinThe = sin(the);
        vec3 bounceDir = normTan*sinThe*cos(rot) + normCoTan*sinThe*sin(rot) + norm*cos(the);

        trace(pos, bounceDir, true, pos, norm, diff);
        vec3 bounceLight = traceLight(pos + norm*0.001, norm, seed+uvec3(0, 0, 3+2*i+1));
        acc *= diff.rgb; // color keep getting absorbed
        color += acc * bounceLight;
    }
    
    // accumulate color
    fragColor.rgb += color;
    fragColor.a += 1.0;

}