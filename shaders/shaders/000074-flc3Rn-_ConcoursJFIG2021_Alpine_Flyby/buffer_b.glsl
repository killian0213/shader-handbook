// Buffer B (buffer) — [ConcoursJFIG2021] Alpine Flyby by loicvdb
// https://www.shadertoy.com/view/flc3Rn

const vec3 lDir = normalize(vec3(-1, .3, -1));
const vec3 lCol = vec3(5, 4.7, 4);
const vec3 fCol = vec3(.7, .8, 1.);
const float fExt = 30.;
const float fDensity = 1.5;
const float fStep = .7;
const float fAnis = .3;
const float tScale = 2000.;
const float tHeight = 4. / tScale;
const float vDensity = 2.5 * tScale;
const float vStep = .6 / tScale;


struct Intersection {
    float t;
    vec3 albedo;
    bool volumetric;
};


vec2 heightDensityMap(vec2 p) {

    return texture(iChannel0, p).xy;
    
}


float terrainSdf(vec3 p) {

    return p.y - heightDensityMap(p.xz).x;
    
}


vec4 terrainNormal(vec2 p) {

    float e = heightDensityMap(p).x;
    vec3 k = vec3(1./iChannelResolution[0].xy, 0);
    return vec4(normalize(vec3((e - vec2(heightDensityMap(p + k.xz).x, heightDensityMap(p + k.zy).x))/k.xy, 1.).xzy), e);
    
}


vec3 sky(vec3 rd) {

    return mix(vec3(1., 1.4, 2.), vec3(.7, 1.2, 2.5), smoothstep(-.2, 2., dot(rd, vec2(.1, 3.).xyx)));
    
}


vec3 skyAmbient() {

    return vec3(.8, 1.3, 2.3);
    
}


vec4 treeVolume(vec3 p) {

    p *= tScale;
    
    float cHash = 0., d = 1000.;
    
    for(int j = 0; j < 2; j++) {
        for(int i = 0; i < 2; i++) {
        
            ivec2 c = ivec2(floor(p.xz - .5)) + ivec2(i, j);
            float hash = fhash2(c);
            
            vec2 u = vec2(c) + vec2(fract(hash * 12345.), fract(hash * 54321.));
            vec2 e = heightDensityMap(u / tScale);
            vec3 t = vec3(u.x, e.x * tScale, u.y);
            
            float h = 2. + 1.5 * fract(hash * 23154.);
            t.y += h / 2.;
            t   -= p;
            t.y /= h;
            float m = dot(t, t);
            
            // using mix to avoid branching
            float f = step(1. - fract(hash * 35142.), e.y) * step(m, d);
            cHash = mix(cHash, hash, f);
            d = mix(d, m, f);
        }
    }
    
    d = sqrt(d) - .6 + .7 * (texture(iChannel2, .15 * p).r - .5);
    
    return vec4(vec3(.08, .08, .03) + vec3(.03, .07, .03) * cHash, step(d, 0.));
    
}


float shadow(vec3 p) {
    
    // == tree shadows =========================================

    p += lDir * vStep * random();
    
    float o = 0., m = -log(random()) / (vDensity * vStep);
    
    for(int i = 0; i < 8 && o < m; i++) {
        o += treeVolume(p).a;
        p += lDir * vStep;
    }
    
    if(o > m) return 0.;

    // == terrain soft shadows ==================================
    
    const float lRad = .07;
    float sTheta = lRad;
    
    float t = .0001, d = .002;
    
    for(int i = 0; i < 64 && d > 0. && d < .2; i++) {
    
        d = terrainSdf(p + t*lDir) + .002;
        sTheta = min(d / t, sTheta);
        
        t += fStep * d;
        
    }
    
    return clamp(sTheta / lRad, 0., 1.);
}


Intersection trace(vec3 ro, vec3 rd) {

    const Intersection noInt = Intersection(-1., vec3(0), false);
    const vec3 center = vec3(.5, 0.45, .5);
    
    
    // == bounding box intersection ===========================
    
    rd += (1. - abs(sign(rd))) * .0000001;   // avoids div/0
    
    vec3 cv = (center - ro - sign(rd) * .5) / rd;
    vec3 fv = (center - ro + sign(rd) * .5) / rd;
    
    float cPlane = max(max(max(cv.x, cv.y), cv.z), 0.);
    float fPlane = min(min(fv.x, fv.y), fv.z);
    
    if(fPlane < cPlane) return noInt;
    
    
    // == terrain intersection =================================
    
    float t = cPlane;
    float ld = terrainSdf(ro + t * rd);
    
    if(ld < 0.) return noInt;
    
    float td = ld < tHeight ? t : -1., ls = ld * fStep;
    
    for(int i = 0; i < 256; i++) {
    
        t += ls;
        
        float d = terrainSdf(ro + rd * t);
        
        if(d < tHeight && td < 0.) {
            // interpolated tree height intersection
            td = t - ls * (tHeight - d) / (ld - d);
        }
        
        if(abs(d) < .0001 || t >  fPlane) break;
        
        ls = d * fStep;
        ld = d;
        
    }
    
    if(t > fPlane) t = -1.;
    
    if(td < 0.) return noInt;
    

    // == trees intersection =================================
    
    td += vStep * random();
    
    vec4 vol = vec4(0.);
    float oDepth = 0.;
    float thresh = -log(random()) / vDensity;
    float wt = -ro.y / rd.y;
    float far = t < 0. ? fPlane : (wt < t && wt > 0.) ? min(wt, fPlane) : t;
    
    for(int i = 0; i < 256 && oDepth < thresh && td < far; i++) {
    
        vec3 p = ro + rd * td;
        
        vol = treeVolume(p);
        
        float ss = max(vStep, (terrainSdf(p) - tHeight) * fStep);
        oDepth += vol.a * ss;
        
        td += ss;
        
    }
    
    if(oDepth >= thresh && td < far) return Intersection(td, vol.rgb, true);
    
    if(t < 0.) return noInt;
    
    
    // == terrain texturing =================================
    
    vec3 p = ro + rd * t;
    vec4 n = terrainNormal(p.xz);
    vec3 tex = texture(iChannel3, p.xz * 50.).rgb;
    
    vec3 sCol = mix(vec3(.15, .10, .05), vec3(.30, .25, .15), tex.x);
    vec3 gCol = mix(vec3(.10, .20, .00), vec3(.40, .30, .10), tex.x) * tex.y;
    vec3 rCol = vec3(.50, .45, .40) * tex * tex;
    
    float fbm = fbm(p.xz * 200.);
    
    vec3 albedo = sCol;
    albedo = mix(albedo, gCol, smoothstep(.2, .5, .5 * fbm + 1000. * n.w));
    albedo = mix(albedo, rCol, smoothstep(.2, .3, .2 * fbm + 1.-n.y));
    
    return Intersection(t, albedo, false);
    
}


void fog(vec3 ro, vec3 rd, float depth, inout vec3 col, inout float att) {
    
    // == bounding sphere intersection ================================
    
    vec3 p = ro - vec3(.5, 0., .5);
    float b = -dot(p, rd);
    float d = b * b - dot(p, p) + .5;
    
    if(d < .0) return;
    
    float s = sqrt(d);
    vec2 cp = vec2(max(b - s, 0.), b + s);
    
    if(cp.x >= cp.y) return;
    
    ro += rd * cp.x;
    depth = clamp(depth, cp.x, cp.y) - cp.x;
    
    // == volume integration =======================================
    
    float hS = fExt * (ro.y + depth * rd.y);
    float hE = fExt * (ro.y);
    
    // analytical volume integration for density = fDensity*exp(-fExt*height)
    float denom = fExt * rd.y;
    float oDepth = (denom == 0.) ? exp(ro.y) * depth : (exp(-hE) - exp(-hS)) / denom;
    
    float e = exp(-fDensity * oDepth);
    float hg = .25 * (1. - fAnis * fAnis) / pow(1. + fAnis * (fAnis - 2. * dot(rd, lDir)), 1.5);
    col = col * e + att * (1. - e) * fCol * (skyAmbient() * .25 + lCol * hg);
    att *= e;
    
}


float waterDisplacement(vec2 p) {

    float e = heightDensityMap(p).x;
    
    float swell = sin(pow(.03 - min(e * 25., 0.), .1) * 200. - p.y * 500. + iTime * 1.5) * .000005;
    float chop = fbm(p * 1000.+iTime*.1) * .00001;
    
    return chop + swell;
    
}


// This function is messy, but necessary to be able to skip reflections tracing on DX11 (ifs don't work, you need a return)

bool reflection(inout vec3 ro, inout vec3 rd, inout Intersection t, inout float depth, inout vec3 col, inout float att) {

    float wt = rd.y < 0. ? -ro.y/rd.y : -1.;
    
    if(!(wt > 0. && (t.t < 0. || wt < t.t))) return false;
    
    depth += wt;
    
    // == fog before reflections =================================
    
    fog(ro, rd, wt, col, att);
    
    
    // == water normal ===========================================
    
    ro += rd * wt;
    
    vec2 k = vec2(.00001, 0);
    float wd = waterDisplacement(ro.xz);
    vec3 wn = normalize(vec3(wd - vec2(waterDisplacement(ro.xz + k.xy), waterDisplacement(ro.xz + k.yx)), k.x).xzy);
    
    
    // == foam ===================================================
    
    float e = heightDensityMap(ro.xz).x;
    
    if(all(lessThan(abs(ro.xz - .5), vec2(.5))) && e < 0.) {
    
        float foam = clamp(.8 + 20000. * wd + 800. * e, 0., 1.);
        
        vec3 dLight = lCol * max(0., dot(lDir, wn));
        vec3 aLight = skyAmbient();
        
        col += att * foam * vec3(.25) * (aLight + dLight);
        att *= 1.-foam;
        
    }
    
    
    // == fresnel ================================================
    
    const float r0 = .02;
    
    float nol = 1. + dot(wn, rd);
    float fresnel = r0 + (1.-r0) * nol*nol*nol*nol*nol;
    
    
    // == underwater =============================================
    
    const vec3 wCol = vec3(0.027,0.051,0.051);
    const float wExt = 200.;
    
    vec3 uCol = vec3(0);
    
    if(t.t > 0.) {
    
        // underwater terrain
        vec4 n = terrainNormal(ro.xz+rd.xz*(t.t-wt));
        float fLight = r0 + (1.-r0) * lDir.y*lDir.y*lDir.y*lDir.y*lDir.y;
        vec3  dLight = exp(wExt*n.w / lDir.y) * lCol * max(0., dot(lDir, n.xyz)) * fLight;
        vec3  aLight = exp(wExt*n.w) * skyAmbient();
        
        float wScattering = exp(wExt * (wt - t.t));
        
        uCol = (1. - wScattering) * wCol * skyAmbient() + wScattering * t.albedo * (dLight + aLight);
        
    } else {
    
        // no underwater terrain
        uCol =  wCol * skyAmbient();
        
    }
    
    col += att * (1. - fresnel) * uCol;
    
    
    // == reflection of the ray ==================================
    
    att *= fresnel;
    rd = reflect(rd, wn);
    
    t = trace(ro + vec3(0.0, 0.0001, 0.0), rd);
    
    return true;
}


void mainImage(out vec4 o, vec2 u) {

    INIT_NOISE;
    
    vec2 aa = (vec2(random(), random()) - .5) * .15;
    vec2 uv = (u - iResolution.xy * .5 + aa) / iResolution.y;
    
    vec3 rd = getMat3(0) * normalize(vec3(uv, FocalLength));
    vec3 ro = getVec3(3);
    vec3 pro = ro;
    vec3 prd = rd;
    
    vec3 col = vec3(0);
    float att = 1.;
    
    
    // == raytracing =============================================
    
    float depth = 0.;
    Intersection t = trace(ro, rd);
    bool reflection = reflection(ro, rd, t, depth, col, att);
    
    
    // == shading ================================================
    
    if(t.t >= 0.) {
    
        vec3 p = ro + t.t * rd;
        
        vec2 e = heightDensityMap(p.xz);
        vec3 aLight = skyAmbient() * exp(min(p.y - e.x - tHeight, 0.) * vDensity * e.y * .15);
        vec3 dLight = shadow(p) * lCol;
        
        if(t.volumetric) {
            // shade the trees
            col += att * t.albedo * (aLight + dLight) * .25;
        } else {
            // shade the terrain
            vec4 n = terrainNormal(p.xz);
            col += att * t.albedo * (aLight + dLight*max(dot(n.xyz, lDir), 0.));
        }
        
    } else {
    
        col += att * sky(rd);
        
    }
    
    depth += att * (t.t < 0. ? 10. : t.t);
    
    
    // == fog ====================================================
    
    fog(ro, rd, t.t < 0. ? 10. : t.t, col, att);
    
    
    // == reprojection ===========================================
    
    o = vec4(col, depth > 0. ? depth : 1.);
    
    mat3 pCam = getMat3(5);
    vec3 pRo = getVec3(8);
    vec3 p = transpose(pCam) * (pro+o.a*prd-pRo);
    vec2 pUv = FocalLength * p.xy * iResolution.y / p.z + iResolution.xy*.5;
    
    if(clamp(pUv, vec2(0), iResolution.xy) != pUv) return;
    
    vec4 po = texture(iChannel1, pUv/iResolution.xy);
    
    float weight = min(.05 + abs(o.a-po.a)*10., .2);
    
    // stronger weight on sky and reflections to avoid ghosting
    if(reflection || t.t < 0.) weight *= 2.;
    
    o = mix(po, o, weight);
}