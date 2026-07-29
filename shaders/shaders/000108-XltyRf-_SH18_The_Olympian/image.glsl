// Image (image) — [SH18] The Olympian by Klems
// https://www.shadertoy.com/view/XltyRf

// Common contains the sequencer, camera parameters, and a few useful functions.
// Buffer A contains the music FFT and playback time.
// Buffer B contains the human geometry, as well as skeletal animations.
// It's a regular SDF made of boxes, capsules, ellipsoids and smin.
// The SDF itself is cone traced. RGBA is normal + opacity.
// Image buffer contains the space background, starfield, lighting, planets, etc.
// The space background may look volumetric, but it's completely fake.
// It's essentialy triplanar mapping, but with moving textures instead.
// X and Y has scrolling textures. Z has an infinite zoom effect.
// This gives the impression of movement in the Z direction.
// The starfield uses 6 cylinders raytraced around the camera. No particles
// were used. I used the same technique in my Star Trek shader.
// Planets are raytraced spheres. The atmosphere lighting is done by returning
// the closest point to the planet, and using that for lighting.
// An exponential fallof is used for the atmosphere itself.
// I used a 3D texture to be able to profit from the automatic filtering.
// I used that same texture for the rings as well, for the same reason.

#define PLANETS_COUNT 20
#define PLANETS_COUNT_REFL 5
#define PLANETS_DISTANCE 1000.0
#define PLANETS_SPEED 50.0
#define PLANETS_OFFSET 30.0

// smooth 3D noise
vec4 snoise( in vec3 uv ) {
    const float textureResolution = 32.0;
	uv = uv*textureResolution + 0.5;
	vec3 iuv = floor( uv );
	vec3 fuv = fract( uv );
	uv = iuv + fuv*fuv*(3.0-2.0*fuv);
	uv = (uv - 0.5)/textureResolution;
	return texture( iChannel3, uv );
}

// smooth procedural noise, used when we need better derivatives
vec4 snoiseProc( in vec3 x ) {
    x *= 32.0;
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    return mix(mix(mix( hash43(p+vec3(0,0,0)), 
                        hash43(p+vec3(1,0,0)),f.x),
                   mix( hash43(p+vec3(0,1,0)), 
                        hash43(p+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash43(p+vec3(0,0,1)), 
                        hash43(p+vec3(1,0,1)),f.x),
                   mix( hash43(p+vec3(0,1,1)), 
                        hash43(p+vec3(1,1,1)),f.x),f.y),f.z);
}

// from iq filterable procedurals
float grid( in vec3 p ) {
    const float N = 50.0;
    vec3 dpdx = dFdx(p);
    vec3 dpdy = dFdy(p);
    vec3 w = max(abs(dpdx), abs(dpdy));
    vec3 a = p + 0.5*w;                        
    vec3 b = p - 0.5*w;           
    vec3 i = (floor(a)+min(fract(a)*N,1.0)-
              floor(b)-min(fract(b)*N,1.0))/(N*w);
    return 1.0-(1.0-i.x)*(1.0-i.y)*(1.0-i.z);
}

// planets palette, as HSV
vec3 palette( in vec3 h ) {
    vec3 rgb = cos(2.0*PI*h.x + 2.0*PI/3.0*vec3(3,2,1))*0.5+0.5;
	return h.z * mix(vec3(1.0), rgb, h.y);
}

// used for an infinite zoom effect
vec4 texZoom( in sampler2D sam, in vec2 uv, in float time, in float seed ) {
    float frac = fract(time);
    float id = floor(time);
    float blend = 0.5 - cos(2.0*PI*frac)*0.5;
    vec3 rand = hash32( vec2(id, seed) );
    uv *= rot(rand.x*2.0*PI);
    uv *= frac;
    uv += rand.yz;
    return vec4(texture(sam, uv).rgb, blend);
}

// used for parallax scrolling
vec4 texTrans( in sampler2D sam, in vec2 uv, in float time, in float seed ) {
    vec3 rand = hash31( seed );
    uv.x += time;
    uv *= rot(rand.x*2.0*PI);
    uv += rand.yz;
    return vec4(texture(sam, uv).rgb, 1);
}

// infinite zoom effect
vec3 infiniteZoom(in sampler2D sam, in vec2 uv, in float time, in float seed ) {
    vec4 acc = vec4(0);
    for (int i = 0 ; i < 6 ; i++) {
        float ii = float(i);
        float phase = ii / 6.0;
        vec4 tex = texZoom(sam, uv, time+phase, seed+ii);
        acc.rgb += tex.rgb*tex.a;
        acc.a += tex.a;
    }
    return acc.rgb/acc.a;
}

// parallax scrolling effect
vec3 parallaxScroll(in sampler2D sam, in vec2 uv,
                    in float time, in float seed ) {
    vec4 acc = vec4(0);
    for (int i = 0 ; i < 4 ; i++) {
        float ii = float(i);
        vec4 tex = texTrans(sam, uv, time/(ii+1.0), seed+ii);
        acc.rgb += tex.rgb*tex.a;
        acc.a += tex.a;
    }
    return acc.rgb/acc.a;
}

// flying through space effect
vec3 flythrough( in sampler2D sam, in vec3 dir, in float time, in float freq ) { 
    vec3 colX = parallaxScroll(sam, dir.zy*freq, time*freq, 10.0);
    vec3 colY = parallaxScroll(sam, dir.zx*freq, time*freq, 20.0);
    float sig = step(dir.z, 0.0)*2.0-1.0;
    vec3 colZ = infiniteZoom(sam, dir.xy*3.0*freq, time*sig*0.4, 30.0);
    dir *= dir;
    return (colX*dir.x + colY*dir.y + colZ*dir.z) / (dir.x+dir.y+dir.z);
}

// filtered starfield
vec3 starfield( in vec3 dir, float position, float speed, in bool reflected ) {
    vec3 ret = vec3(0);
    // do less stars when it's reflected off the character
    float maxRadius = 6.5;
    if (reflected)
        maxRadius = 2.5;
    for (float radius = 1.0 ; radius < maxRadius ; radius += 1.0) {
        // raytrace a cylinder
        float x = atan(dir.x, dir.y)/PI;
        float y = dir.z * radius / length(dir.xy);
        // map coordinates around that cylinder
        vec2 uv = vec2(x*3.0*radius, y + position);
        // rotate each sections by a random angle
        uv.x += 3.0*radius*hash12(vec2(radius, floor(uv.y)));
        // use a grid partioning, then add a random offset
        vec2 cen = floor(uv)+0.5;
        cen += (hash23(vec3(cen, radius))-0.5)*0.7;
        // figure out the size of stars, then fix the deformation on y
        vec2 dim = vec2(0.01);
        if (reflected)
            dim *= 4.0;
        dim.y += speed/radius;
        dim.y /= sin(atan(radius/abs(y)));
        // apply a bit of chromatic aberration
        float redshift = 0.01+speed/radius;
        cen.y -= redshift;
        for (int i = 0 ; i < 3 ; i++) {
            cen.y += redshift;
            // now add actual stars
            vec2 inStar = uv-cen;
            float ellipsis = (length(inStar/dim) - 1.0) * dim.y;
            // apply distance based filtering on them
            float dist = (radius*radius+y*y);
            if (reflected)
                dist *= 4.0;
            ret[i] += s(0.02, -0.02, ellipsis) / dist;
        }
    }
    return ret;
}

// raytrace a planet
void raytracePlanet(in vec3 from, in vec3 dir, in vec3 pos,
                    in float radius, in float atmosStrength,
                    out vec3 n, out float atmos, out float aa) {
    // usual raytrace routine
    vec3 d = from - pos;
    float b = dot(dir, d);
    float c = dot(d, d) - radius*radius;
    float t = b*b-c;
    t = -b-sqrt(max(0.0, t));
    
    // do some stuff with the angle
    float dist = length(d);
    float cosAlpha = max(0.0, -b / dist);
    float sinAlpha = sin(acos(cosAlpha));
    // blend atmosphere
    atmos = 0.0;
    if (atmosStrength > 0.0)
    	atmos = min(1.0, exp((radius-sinAlpha*dist)/atmosStrength*5.0));
    // anti-aliasing for planets with no atmosphere
    float aaAngle = length(fwidth(from))*0.1;
    aa = s(0.002+aaAngle, -0.002, sinAlpha-radius/dist);
    
    if (t > 0.0) {
        // we hit the planet, set position on the surface
        n = normalize(from + dir*t - pos);
        // and tweak the atmosphere
        if (atmosStrength > 0.0)
        	atmos *= exp(dot(dir, n)/atmosStrength);
    } else {
        // set the position to the closest point to the surface
        n = normalize(from + dir*cosAlpha*dist - pos);
    }
}

// raytrace a plane, used for ringed planets
float raytracePlane(in vec3 from, in vec3 dir,
                    in vec3 planePos, in vec3 planeNormal ) {
    float originDist = -dot(planePos, planeNormal);
    float t = -(dot(planeNormal, from)+originDist)/dot(planeNormal, dir);
    if ( t > 0.0 )
        return t;
    return -1.0;
}

// colorize planets
vec3 colorizePlanet(in vec3 diffLight, in vec3 specLight,
                    in vec3 planetNormal, in vec3 planetAxis,
                    in float planetRotation, in float atmosphereStrength,
                    in float volcanic, in float water, in float life,
                    in float baseHue, in float seed) {
    // express the planet position around the axis
    const vec3 up = normalize(vec3(1, 2, PI));
    vec3 ortho1 = normalize(cross(planetAxis, up));
    vec3 ortho2 = cross(planetAxis, ortho1);
    vec3 planetPos = vec3(dot(planetAxis, planetNormal),
        dot(ortho1, planetNormal), dot(ortho2, planetNormal));
    vec3 origPos = planetPos;
    planetPos.yz *= rot(planetRotation);
    
    // classic fractal noise
    planetPos += hash31(seed*2.0);
    planetPos *= 0.1;
    vec4 noiseA = snoiseProc(planetPos);
    // add some swirly
    planetPos += (noiseA.yzw-0.5)*0.1;
    planetPos *= 4.0;
    planetPos.xy *= rot(1.974);
    planetPos.yz *= rot(2.131);
    vec4 noiseB = snoise(planetPos);
    planetPos *= 6.0;
    planetPos.xy *= rot(0.312);
    planetPos.yz *= rot(1.037);
    vec4 noiseC = snoise(planetPos);
    vec4 noise = (noiseA + noiseB*0.5 + noiseC * 0.25)/(1.0+0.5+0.25);
    
    // get the color of the planet, mix it with brown when volcanic
    vec3 color = vec3(0);
    color.x = baseHue + (noise.x-0.5)*0.5;
    color.y = mix(0.3, 1.0-noise.x, volcanic);
    color.z = mix(1.0-noise.x*0.8, noise.x*0.5, volcanic);
    vec3 planetColor = palette(color);
    
    // add lava on the surface
    float n = noiseB.y*noiseC.y;
    vec3 volcanColor = mix(vec3(0.95, 0.06, 0.03), vec3(0.95, 0.75, 0.06),
                           s(0.8-volcanic*0.3, 1.0, n));
    vec3 emissive = s(0.6-volcanic*0.5, 1.0, n)*volcanColor*volcanic*0.5;
    
    // add water
    vec4 noiseW = (noiseA.x+noiseB*0.5)/(1.0+0.5);
    float waterLevel = s(1.0-water, 1.2-water, noiseW.x);
    vec3 waterColor = palette(vec3(baseHue, 0.9, 0.7));
    planetColor = mix(planetColor, waterColor, waterLevel);
    
    // add life
    if (life > 0.0) {
        float lifeLevel = s(0.0+life, -0.2+life, noise.x);
        lifeLevel = s(0.7*life+0.1, 0.0, noise.x);
        lifeLevel *= 1.0 - waterLevel;
        planetColor = mix(planetColor, vec3(0, 1, 0), lifeLevel);
        // add intelligent life
        float extend = clamp(1.0-(life-0.9)/0.1, 0.0, 1.0);
        float smartLife = s(1.0-extend, 0.8-extend, noiseW.x);
        smartLife *= grid(planetPos*15.0);
        smartLife *= s(0.5, 0.4, waterLevel);
        smartLife *= s(0.3, 0.0, length(diffLight)); // HACK!
        smartLife = clamp(smartLife, 0.0, 1.0);
        emissive += vec3(0.99, 0.7, 0.4)*smartLife;
    }
    
    // add polar caps
    float polar = s(1.1-water*0.3, 1.15-water*0.3,
                    abs(origPos.x) + (noiseW.x-0.5)*0.1);
    planetColor = mix(planetColor, vec3(2), polar);
    
    // and add specular
    float specular = mix(waterLevel, 1.0, polar);
    
    // now do final lighting calculations
    planetColor *= diffLight;
    planetColor += specLight*specular;
    planetColor += emissive;
    
    // and finally, add clouds on top of the whole thing
    if (atmosphereStrength > 0.0) {
        vec3 cloudPos = origPos;
        cloudPos.yz *= rot(planetRotation*0.5);
        cloudPos.yz *= rot(cloudPos.x*1.5);
        float cloudsStrips = sin(8.0*atan(cloudPos.y, cloudPos.z))*0.5+0.5;
        cloudsStrips *= s(1.0, 0.9, abs(cloudPos.x));
        cloudPos += hash31(seed*2.0+1.0);
        cloudPos *= 0.01;
        cloudPos += (snoiseProc(cloudPos).xyz-0.5)*0.3;
        cloudPos *= 4.0;
        vec4 cloudsN = snoise(cloudPos)*(noiseA*0.5+0.5);
        float clouds = s(0.3, 1.5, cloudsN.x*1.3+cloudsStrips*0.2);
        clouds = clamp(clouds*atmosphereStrength*1.5, 0.0, 1.0);
        vec3 cloudsColor = palette(vec3(baseHue, 0.2, 1.0));
        cloudsColor *= 1.0 - volcanic*0.8;
        planetColor = mix(planetColor, cloudsColor*diffLight*2.5, clouds);
    }
    
    // return the color
    return planetColor;
}

// colorize atmosphere
vec3 colorizeAtmosphere(in vec3 atmosLight, in vec3 planetNormal,
                    	in float atmosphereStrength,
                    	in float volcanic, in float baseHue) {
    // volcanic planets tend to have a reddish atmosphere
    vec3 atmosColor = palette(vec3(baseHue, 1, 1));
    atmosColor = mix(atmosColor, vec3(0.95, 0.26, 0.13), volcanic*0.8);
    atmosColor *= atmosLight;
    return atmosColor;
}

// colorize rings, return rings color and alpha
vec4 colorizeRings(in float ringsDist, in float planetRadius,
                   in float baseHue, in float seed) {
    // this is to avoid filtering issues
    if (ringsDist > planetRadius*4.0)
        return vec4(0);
    vec4 ringsColor = vec4(0);
    // use a texture to profit from the filtering
    vec2 rndPos = hash21(seed);
    vec4 rndRings3 = texture(iChannel3, vec3(ringsDist*0.1, rndPos));
    // colorize the rings
    float hue = baseHue + (rndRings3.x-0.5)*0.2;
    vec3 color = vec3(hue, 0.2+rndRings3.y*0.6, 0.2+rndRings3.z*0.6);
    ringsColor.rgb = palette(color);
    // then the alpha
    float d = fwidth(ringsDist)*0.5;
    ringsColor.a = s(planetRadius*1.1+0.2-d, planetRadius*1.1+0.4+d, ringsDist);
    ringsColor.a *= s(planetRadius*2.0+0.2+d, planetRadius*2.0-d, ringsDist);
    // randomize it a bit
    ringsColor.a *= rndRings3.w*0.4+0.6;
    return ringsColor;
}

// blend in a planet in font of a background
vec3 addPlanet(in vec3 from, in vec3 dir, in vec3 backColor,
               in vec3 lightColor, in vec3 lightDir,
               in vec3 planetPos, in float planetRadius, 
               in vec3 planetAxis, in float planetRotation,
               in float atmosphereStrength, in bool hasRings,
               in float volcanic, in float water, in float life,
               in float baseHue, in float seed, in float baseAlpha) {
    
    vec3 toPlanet = planetPos-from;
    float toPlanetSq = dot(toPlanet, toPlanet);
    
    // starts by doing some computations on the rings
    bool doRings = hasRings;
    bool ringsBehind = false;
    vec3 ringsColor = vec3(0);
    float ringsAlpha = 0.0;
    
    if (hasRings) {
        float distToRings = raytracePlane(from, dir, planetPos, planetAxis);
        if (distToRings > 0.0) {
            vec3 onRings = from+dir*distToRings;
            float ringsDist = length(onRings-planetPos);
            ringsBehind = distToRings*distToRings > toPlanetSq;
            // raytrace the planet from the rings, for the shadows
            vec3 dump1 = vec3(0);
            float dumpAtmos = 0.0;
            float dumpAA = 0.0;
            raytracePlanet(onRings, lightDir, planetPos, planetRadius,
                           atmosphereStrength, dump1, dumpAtmos, dumpAA);
            float ringsShadows = (1.0 - dumpAtmos)*(1.0 - dumpAA);
            // get rings color and alpha
            vec4 newColor = colorizeRings(ringsDist, planetRadius,
                                          baseHue, seed);
            // light the rings, and set the values
            ringsColor = newColor.rgb;
            ringsColor *= ringsShadows * lightColor;
            ringsAlpha = newColor.a;
        } else {
            // can't see the rings
            doRings = false;
        }
    }
    
    // blend in the rings behind the planet
    if (doRings && ringsBehind) {
        backColor = mix(backColor, ringsColor, ringsAlpha*baseAlpha);
    }
    
    // now raytrace the planet, getting its atmosphere and all
    vec3 planetNormal = vec3(0);
    float planetAtmos = 0.0;
    float planetAA = 0.0;
    raytracePlanet(from, dir, planetPos, planetRadius, atmosphereStrength,
                   planetNormal, planetAtmos, planetAA);
    
    // compute the shadows from the rings
    float ringsShadows = 1.0;
    if (hasRings) {
        vec3 onPlanet = planetPos + planetNormal*planetRadius;
        float distToRings = raytracePlane(onPlanet, lightDir,
                                          planetPos, planetAxis);
        if (distToRings > 0.0) {
            vec3 onRings = onPlanet + lightDir*distToRings;
            float ringsDist = length(onRings-planetPos);
            ringsShadows *= 1.0 - colorizeRings(ringsDist, planetRadius,
                                                baseHue, seed).a;
        }
    }
    
    // do lighting calculations
    float baseLight = dot(planetNormal, lightDir);
    float atmosLight = baseLight*0.5+0.5;
    atmosLight *= atmosLight;
    atmosLight *= atmosLight;
    baseLight = max(0.0, baseLight);
    float specTerm = max(0.0, dot(lightDir, reflect(dir, planetNormal)));
    vec3 diffuse = baseLight * lightColor * ringsShadows;
    vec3 atmosphere = atmosLight * lightColor;
    vec3 specular = pow(specTerm, 10.0) * lightColor * ringsShadows * baseLight;
    vec3 planetColor = vec3(0);
    vec3 atmosColor = vec3(0);
    
    // colorize planets
    if (planetAA > 0.001) {
        planetColor = colorizePlanet(diffuse, specular, planetNormal,
                                     planetAxis, planetRotation,
                                     atmosphereStrength, volcanic,
                                     water, life, baseHue, seed);
    }
    
    // and their atmosphere
    if (planetAtmos > 0.001) {
        atmosColor = colorizeAtmosphere(atmosphere, planetNormal,
                                        atmosphereStrength,
                                        volcanic, baseHue);
    }
    
    // add the planet
    backColor = mix(backColor, planetColor, planetAA*baseAlpha);
    // then the atmosphere
    backColor = mix(backColor, atmosColor, planetAtmos*baseAlpha);
    
    // and finally blend in the rings in front of the planet
    if (doRings && !ringsBehind) {
        backColor = mix(backColor, ringsColor, ringsAlpha*baseAlpha);
    }
    
    return backColor;
}

// add random planets passing by
vec3 addRandomPlanets( in vec3 dir, in float time,
                      in vec3 backColor, in bool reflected ) {
    const float delta = PLANETS_DISTANCE / float(PLANETS_COUNT);
    float posi = time / (PLANETS_DISTANCE/PLANETS_SPEED);
    posi *= float(PLANETS_COUNT);
    float frac = fract(posi);
    float floo = floor(posi);
    
    // render less planets in the reflection
    int start = 0;
    if (reflected)
        start = PLANETS_COUNT-PLANETS_COUNT_REFL;
    
    // add a bunch of planets
    for (int i = start ; i < PLANETS_COUNT ; i++) {
        int temp = PLANETS_COUNT - i;
        if (i % 2 == 0)
            temp = -temp+1;
        
        float ii = float(temp)+1.0;
        float dist = ii*delta;
        dist -= frac*delta*2.0;
        float seed = ii + floo*2.0;
        // fade in/out the planets
        float alpha = s(PLANETS_DISTANCE, PLANETS_DISTANCE*0.8, abs(dist));
        
        // get a bunch of random numbers
        vec4 rnd1 = hash41(seed*3.0+0.0);
        vec4 rnd2 = hash41(seed*3.0+1.0);
        vec4 rnd3 = hash41(seed*3.0+2.0);
        
        // base hue
        float hue = rnd1.x;
        // get a random radius
        float radius = 1.0 + rnd1.y*8.0;
        // get a random offset
        float angle = rnd1.z*2.0*PI;
        vec2 off = vec2(cos(angle), sin(angle));
        off *= PLANETS_OFFSET*rnd1.w+radius*1.5;
        vec3 planetPos = vec3(off, dist);
        // random axis, tilt it slightly horizontally
        vec3 planetAxis = vec3(0, 1, 0);
        planetAxis.xz += (rnd2.xy-0.5)*0.5;
        planetAxis.z -= 0.5;
        planetAxis = normalize(planetAxis);
        // random rotation
        float rota = time*(0.2+rnd2.z*0.2);
        // random atmosphere
        float atmos = rnd2.w;
        if (atmos < 0.2)
            atmos = 0.0;
        if (radius < 3.0)
            atmos = 0.0;
        
        // random stuff
        bool hasRings = false;
        float volcanic = 0.0;
        float water = 0.0;
        if (rnd3.x < 0.3) {
            // small chance of a volcanic planet
            volcanic = rnd3.y;
        } else {
            // if the planet isn't volcanic, it may have water
            water = rnd3.z;
            if (water < 0.2)
                water = 0.0;
            if (atmos < 0.3)
                water = 0.0;
        }
        
        // when the planet isn't too volcanic or too small, it may have rings
        if (volcanic < 0.5 && radius > 3.0)
            hasRings = rnd3.w < 0.3;
        
    	const vec3 lightDir = normalize(vec3(6, 4, -2));
        backColor = addPlanet(vec3(0), dir, backColor, vec3(1), lightDir,
                              planetPos, radius, planetAxis, rota, atmos,
                              hasRings, volcanic, water, 0.0, hue,
                              seed, alpha);
    }
    
    return backColor;
    
}

// colored cloud/nebula
vec3 cloud( in vec3 dir, in float hue ) {
    // deformed circle
    vec2 ab = dir.xy;
    ab.x *= (abs(ab.y)+0.1)*5.0;
    ab.y *= abs(step(ab.y, 0.0)*0.7+0.7);
    
    // use the fft from the soundtrack to add more flavor
    const vec2 df1 = vec2(0.02, 0);
    const vec2 df2 = vec2(0.1, 0);
    float ffta = textureGrad(iChannel0, vec2(abs(dir.x)*2.0, 0), df1, df1).r;
    float fftb = textureGrad(iChannel0, vec2(abs(ab.y)*2.0, 0), df2, df2).r;
    
    // base formula from an exponential
    float len = length(ab);
    float base = exp(-len*8.0 + 5.0 )*0.1;
    base *= s(0.3, -0.3, dir.z);
    base *= ffta;
    base *= fftb;
    
    // and return a color from the palette
    return palette(vec3(hue+base*0.04, 0.8, 1.0))*base;
}

// get the background color, with nebulas/stars/planets passing by
vec3 getBackground(in vec3 dir, in bool reflected,
                   in int seqID, in float seqTime, in float time) {
    
    float position = time*0.1;
    float speed = 0.0;
    
    if (seqID == 1 || seqID == 3 || seqID == 6) {
        // flying through space
        position = time*1.5;
        speed = 0.04;
    } else if (seqID == 2) {
        // closeup
        position = time*3.0;
        speed = 0.08;
    }
    
    // weird shapes flying around
    vec3 nebula = flythrough(iChannel2, dir, position*0.2, 0.2);
    nebula = 1.0 - nebula;
    nebula *= nebula;
    nebula *= nebula;
    // colorize those shapes
    vec3 colPos = dir*0.07;
    colPos.z += position*0.01;
    colPos.xy *= rot(0.741);
    colPos.yz *= rot(1.164);
    vec3 color = snoise(colPos).rgb;
    color = color*1.3+0.2;
    color *= color;
    // compositing
    vec3 baseColor = nebula*color*0.3;
    baseColor *= baseColor;
    // add stars passing by
    baseColor += starfield(dir, position, speed, reflected)*2.0;
    
    // add nebulas/clouds reacting to music
    vec3 dirA = dir;
    dirA.xz *= rot(0.3);
    dirA.yz *= rot(0.1);
    float cloudA = 0.0;
    vec3 dirB = dir;
    dirB.xz *= rot(-0.2);
    float cloudB = 0.0;
    if (seqID == 0) {
        cloudB = 1.0;
    } else if (seqID == 1) {
        cloudA = s(18.0, 20.0, seqTime)-s(20.0, 22.0, seqTime);
        cloudB = s(22.0, 24.0, seqTime)-s(24.0, 26.0, seqTime);
    } else if (seqID == 4) {
        dirA = dir;
        cloudA = 1.0;
    } else if (seqID == 6) {
        dirB = dir;
        dirB.z = -dirB.z;
        cloudB = 1.0;
    }
    
	// lower tone
    baseColor += cloud( dirA, 0.6 )*0.15*cloudA;
    // higher tone
    baseColor += cloud( dirB, 0.9 )*0.2*cloudB;
    
    if (seqID == 0) {
        // do nothing
    } else if (seqID == 3) {
        // zig zag between planets
        vec3 from = vec3(0, 0.5, 0);
        from.x += sin(seqTime*0.5)*4.0;
        from.z += seqTime*10.0;
        const vec3 axis = normalize(vec3(-2, 15, -1));
        const vec3 lightDir = normalize(vec3(6, 4, -2));
        baseColor = addPlanet(from, dir, baseColor, vec3(1), lightDir,
                              vec3(0, 0, PI*50.0), 2.0, axis, seqTime*0.6,
                              0.2, false, 0.8, 0.0, 0.0, 0.1, 0.0, 1.0);
        baseColor = addPlanet(from, dir, baseColor, vec3(1), lightDir,
                              vec3(0, 0, PI*30.0), 3.0, axis, seqTime*0.6,
                              0.5, true, 0.0, 0.7, 0.0, 0.3, 1.0, 1.0);
        baseColor = addPlanet(from, dir, baseColor, vec3(1), lightDir,
                              vec3(0, 0, PI*10.0), 1.5, axis, seqTime*0.6,
                              0.5, false, 0.0, 0.0, 0.0, 0.6, 2.0, 1.0);
    } else if (seqID == 4) {
        // add a single ringed planet
        const vec3 axis = normalize(vec3(-2, 15, -1));
        const vec3 lightDir = normalize(vec3(-10, 4, 16));
        vec3 planetPos = vec3(10, -1, 0);
        baseColor = addPlanet(vec3(0), dir, baseColor, vec3(1), lightDir,
                              planetPos, 7.0, axis, seqTime*0.1,
                              0.8, true, 0.0, 0.0, 0.0, 0.65, 3.0, 1.0);
    } else if (seqID == 5) {
        // add a sun
        float sun = s(11.0, 6.0, seqTime);
        vec3 sunColor = mix(vec3(0.99, 0.9, 0.8), vec3(0.99, 0.3, 0.2), sun);
        vec3 sunPos = vec3(2, 1, 5);
        vec3 sunPosN = normalize(sunPos);
        // make the sun look a bit more interesting
        vec3 sunPosNA = normalize(cross(sunPosN, vec3(0, 1, 0)));
        vec3 sunPosNB = cross(sunPosN, sunPosNA);
        float a = dot(dir, sunPosNA);
        float b = dot(dir, sunPosNB);
        vec2 ab = vec2(a, b);
        ab = exp(-abs(ab)*20.0)*(sun*0.9+0.1);
        float sunA = acos(dot(sunPosN, dir));
        sunA = exp(-sunA*10.0 + ab.x + ab.y + 1.3)*0.2;
        baseColor += sunA*sunColor;
        // add a earth like planet
        const vec3 axis = normalize(vec3(2, 8, -4));
        vec3 planetPos = vec3(-2.5, 0, 3);
        vec3 lightDir = normalize(sunPos-planetPos);
        float rota = seqTime*0.1;
        // earth gets colder, then water and life appear
        float volc = s(20.0, 10.0, seqTime);
        float water = s(14.0, 24.0, seqTime)*0.6;
        float life = s(24.0, 38.0, seqTime);
        baseColor = addPlanet(vec3(0), dir, baseColor, sunColor, lightDir,
                              planetPos, 1.6, axis, rota, 0.3,
                              false, volc, water, life, 0.6, 3.0, 1.0);
    } else {
        // otherwise, add planets passing by
    	baseColor = addRandomPlanets(dir, position, baseColor, reflected);
    }
    
    return baseColor;
}

// lighting/highlight color for the dude
vec3 getLighting( in vec3 dir ) {
    const vec3 ori1 = normalize(vec3(1, 2, -3));
    const vec3 ori2 = normalize(vec3(1, -2, 2));
    float lig1 = dot(dir, ori1)*0.5+0.5;
    float lig2 = dot(dir, ori2)*0.5+0.5;
    vec3 ret = vec3(0);
    ret += vec3(0.95, 0.6, 0.1)*pow(lig1+0.25, 12.0);
    ret += vec3(0.6, 0.1, 0.9)*pow(lig2+0.08, 48.0);
    return ret;
}

// apply direction deformation
vec2 deformDir( in vec2 uv, in int seqID, in float seqTime ) {
    
    // do some bubble deformation in the intro
    if (seqID == 0) {
        float len = length(uv);
        vec2 dir = uv / len;
        float f = fract(seqTime*2.0);
        f = s(0.0, 0.8, f) - s(0.8, 1.0, f);
        f *= seqTime/7.0;
        f *= step(seqTime, 7.0);
        float b = s(6.5, 7.5, seqTime) - s(8.0, 8.2, seqTime);
        uv += dir*sqrt(len)*f*0.2;
        uv -= dir*sqrt(len)*b*0.5;
    }
    
    // otherwise do nothing
    return uv;
}

// do some funky effects when the dude appears
float deformAlpha( in vec2 uv, in int seqID, in float seqTime ) {
    
    // spiral like apparition in the intro
    if (seqID == 0) {
        float move = s(6.5, 9.5, seqTime);
        float len = length(uv);
        float base = cos(len*120.0)*0.5+0.5;
        base *= move;
        base *= len;
        base += s(1.0, 0.0, len+4.0-move*6.0);
        base = clamp(base, 0.0, 1.0);
        return base;
    }
    
    // otherwise do nothing
    return 1.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    // fetch the playback time
    float time = texelFetch(iChannel0, ivec2(0), 0).a;
    // get the sequence and the time in it
    int seqID = 0;
    float seqTime = 0.0;
    getSequence(time, seqID, seqTime);
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord-iResolution.xy*0.5;
    uv /= iResolution.y;
    uv = deformDir(uv, seqID, seqTime);
    // get the direction and position
    vec3 dir = vec3(0);
    vec3 from = vec3(0);
    getCamera(uv, seqID, seqTime, dir, from);
    fragColor = vec4(deformAlpha(uv, seqID, seqTime));
    
    // get our dude in front of the background
    vec4 dude = texelFetch(iChannel1, ivec2(fragCoord), 0);
    dude.a *= deformAlpha(uv, seqID, seqTime);
    
    // blend between the reflected dir, and the actual direction
    vec3 normal = dude.xyz;
    vec3 backDir = reflect(dir, normal);
    backDir = mix(dir, backDir, dude.a);
    
    // get background color from direction
    fragColor.rgb = getBackground(backDir, dude.a > 0.5, seqID, seqTime, time);
    
    // mix our dude with the background, add some lighting
    vec3 lighting = getLighting(backDir);
    float fresnel = max(0.0, -dot(normal, dir));
    fresnel *= fresnel;
    vec3 baseColor = mix(lighting, fragColor.rgb, fresnel);
    baseColor *= fresnel;
    fragColor.rgb = mix(fragColor.rgb, baseColor, dude.a);
    
    // gamma correction, dithering, vignette, etc
    fragColor.rgb = pow( fragColor.rgb, vec3(1.0/2.2) );
    fragColor.rgb += (hash33(vec3(fragCoord, iFrame))-0.5)*0.02;
    fragColor.rgb = clamp(fragColor.rgb, 0.0, 1.0);
    vec2 vig = (fragCoord-iResolution.xy*0.5)/iResolution.xy;
    fragColor.rgb = mix(fragColor.rgb, vec3(0), dot(vig, vig)*0.2);
    
    // fade in/out
    float fadeIn = s(0.0, 2.0, time);
    fragColor.rgb = mix(vec3(0), fragColor.rgb, fadeIn);
    float fadeOut = s(153.0, 157.0, time);
    fragColor.rgb = mix(fragColor.rgb, vec3(0), fadeOut);
    
    fragColor.a = 1.0;
}