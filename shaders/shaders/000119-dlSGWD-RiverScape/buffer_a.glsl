// Buffer A (buffer) — RiverScape by XT95
// https://www.shadertoy.com/view/dlSGWD

// ---------------------------------------------
// Sky
// ---------------------------------------------
float phaseFunction(float lightDotView)
{
    const float k = .9;
	float v = 1.0 - k * k;
	v /= (4.0 * PI * pow(1.0 + k * k - (2.0 * k)*lightDotView, 1.5));
	return v;
}
vec3 skyColor(vec3 rd, vec3 sundir)
{
    rd.y += .05;
    float yd = min(rd.y, 0.);
    rd.y = max(rd.y, 0.);
    
    vec3 col = vec3(0.);
    
    col += vec3(.4, .4 - exp( -rd.y*20. )*.15, .0) * exp(-rd.y*9.); // Red / Green 
    col += vec3(.3, .4, .6) * (1. - exp(-rd.y*8.) ) * exp(-rd.y*.9) ; // Blue
    
    col = mix(col*1.2, vec3(.3),  1.-exp(yd*100.)); // Fog
    
    
    return min(col,vec3(1.));
    
}







// ---------------------------------------------
// Distance field 
// ---------------------------------------------
float slice(vec3 p, vec3 dir, float offset, float smoothEdge, float baseD) {
    //p *= .75;
    float y = dot(p, dir);
    float id = floor(y+.5);
    offset *= max(0.,sign(hash(id)*100.-50.));
    
    float ksmooth = smoothEdge;
    
    float d =  smax(baseD + hash(id)*offset, abs(y-id)-.5, ksmooth);
    d =  min(d, smax(baseD + hash(id+1.)*offset, abs(y-id-1.)-.5, ksmooth));
    d =  min(d, smax(baseD + hash(id-1.)*offset, abs(y-id+1.)-.5, ksmooth));
    
    return d;
}


#define ROCKITERATION 7
float fractal(in vec3 pos)
{
    const float scale = 2.8;
    const float minRad2 = .822;
    const vec4 scaled8 = vec4(3.51);

    vec4 p = vec4(pos,1.), p0 = p;
    float r2;
    for (int i=0; i<ROCKITERATION; i++)
    {
        p.xz = rot(-p.y*.1) * p.xz;
        p.xy = rot(-p.z*.1) * p.xy;
        p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;
        r2 = dot(p.xyz, p.xyz);
        p *= clamp(max(minRad2/r2, minRad2), 0.0, 1.0);

        p = p*scaled8 + p0;
    }
  	return ((length(p.xyz) - abs(scale - 1.0)) / p.w - pow(scale, float(1-ROCKITERATION)));
}

float displacement( vec3 p )
{
    // more cool tricks -> https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch01.html
    vec3 pp = p;
    float mgn = .5;
    float d = 0.;
    for(int i=0; i<4; i++)
    {
        vec4 rnd = noised(p+10.);
        d += rnd.w * mgn;
        
        p *= 2.;
        p += rnd.xyz*.4;
        mgn *= .5;
        
    }
    
    
    return d;
}


#define SLICE_SIZE 25.
float rock(vec3 p) {
    vec3 pp = p;
    p.xz = mod(p.xz-2.,4.)-2.;
    p.xz = rot(pp.x*.05) * p.xz;
    

   // float r = length(pp.yz)-1.;
    //r = min(length(pp.yz-vec2(.5,-2.3))-1., r);
    float r = fractal(p);
    float d = smin(r, p.y+.1, .1);//smin(r, p.y+.3, .2);
    d = max(d,p.y-1.2);
    if (r<.3) {
        d = mix(d*1.5, displacement(pp*25.+1.3)*.02-0.002, smoothstep(-1.,-1.3, p.z)*.25+.25);

        d = slice(p*SLICE_SIZE, normalize(vec3(0.0,3.,2.+cos(p.x*5.)*.2)), 0.03,.3*smoothstep(0.8,0.3,noise(p*5.+1.1))*smoothstep(-.3,0.,p.y)*step(0.,length(p.xz-vec2(-.4,-1.))-.15), d*SLICE_SIZE)/SLICE_SIZE;
    }
    r = d;
    
    
    return r;
}

float traceIn = 1.;

float water(vec3 p) {
    if (traceIn < 0.) return 9999.;
    const mat2 mw = mat2(1.6,1.2,-1.2,1.6);
    float d = p.y;
    p *= 15.;
    float amp = .005;
    p.xz *= mw;
    
    // Add detail only if we are closed of the surface
    if (d < .2) {
        for(int i=0; i<3; i++)
        {
            d -= (1.-abs(sin(noise(p.xz)))) * amp;
            amp *= .5;
            p.xz *= mw;
        }
    }
    return d;
}

float map(vec3 p) {
    float d = min(rock(p), water(p));
    return d;
}









// ---------------------------------------------
// Ray tracing 
// ---------------------------------------------
float trace(vec3 ro, vec3 rd, vec2 nf) {
    traceIn = (ro+rd*nf.x).y < 0. ? -1. : 1.;
    float t = nf.x;
    for(int i=min(0,iFrame); i<128; i++) {
        float d = map(ro+rd*t);
        if (t > nf.y || abs(d)<0.001) break;
        t += d;
    }
    
    return t;
}
float trace2(vec3 ro, vec3 rd, vec2 nf) {
    traceIn = ro.y < 0. ? -1. : 1.;
    float t = nf.x;
    for(int i=min(0,iFrame); i<64; i++) {
        float d = rock(ro+rd*t);
        if (t > nf.y || abs(d)<0.001) break;
        t += d;
    }
    
    return t;
}
vec3 normal(vec3 p, float t) {
    traceIn = p.y < 0. ? -1. : 1.;

    vec2 eps = vec2(0.0001,0.0);
    float d = map(p);
    vec3 n;
    n.x = d - map(p - eps.xyy);
    n.y = d - map(p - eps.yxy);
    n.z = d - map(p - eps.yyx);
    n = normalize(n);
    return n;
}




// ---------------------------------------------
// Raw Frame
// ---------------------------------------------
#define sundir normalize( vec3(-5.,5.5,-5.))
#define suncolor vec3(1.,.45,.25)

// ---------------------------------------------
// BRDFs
// ---------------------------------------------
float moisture(vec3 p) {
    return smoothstep(0.0,.1, abs(p.y)+(noise(p*10.)-.5)*.0);
}
vec3 rock_albedo(vec3 p, vec3 n) {
    float t = moisture(p);
    float c = displacement(p*vec3(15.));
    
    vec3 col = mix(vec3(1.,.6,.4)*.7, vec3(1.,.7,.5), smoothstep(0.1,.3, abs(cos(p.y*15.-p.x*3.+c*.5))))*.2;
    
    if (p.y > 0.)
    col *= smoothstep(0.05,.13, abs(p.y))*.75+.25;
    
    col = mix(vec3(1.,.5,.8)*.05, col, saturate(t+.25));
    return col;
}
vec4 sampleRockBRDF(vec3 v, vec3 n, vec3 p, out vec3 l) {
    l = cosineSampleHemisphere(n);
    
    float refl = 1.-moisture(p);
    if (frand() < refl)
        l = reflect(-v,n);
    return vec4(rock_albedo(p, n), 1.);
}

vec4 sampleWaterBSDF(vec3 v, vec3 n, out vec3 l, inout bool isRefracted) {
    
    const float ior = 1.01;
    float dielF = Fresnel(1., ior, abs(dot(v,n)), 0., 1.);
    
    
    vec4 brdf = vec4(.6,.8,1.,1.);
    if (frand() < dielF) {
        l = reflect(-v,n);
        brdf.a = dielF;
    } else {
        isRefracted = true;
        l = refract(-v,n, 1./ior);
        brdf.a = 1.-dielF;
    }
    l = normalize(l + (frand3()*2.-1.)*.01);
    return brdf;
}


// ---------------------------------------------
// Pathtracing
// ---------------------------------------------
vec4 pathtrace(vec3 ro, vec3 rd) {
    
    float firstDepth = 0.;
    vec3 acc = vec3(0.);
    vec3 abso = vec3(1.);
    
    for(int i=min(0,iFrame); i<3; i++) {
        // trace
        float t = trace(ro,rd, vec2(0.01, 100.));
        vec3 p = ro + rd * t;
        if (i == 0) firstDepth = t;
        
        // sky intersection ?
        if (t >= 100.) {
            //acc += vec3(1.) * abso;
            acc += skyColor(rd,sundir)*2. * abso;
            break;
        }
        
        // info at intersection point
        vec3 n = normal(p, t);
        
        // sample BRDF
        bool isWater = (map(p) == water(p));
        vec3 outDir;
        bool isRefracted = false;
        vec4 bsdf;
        if (isWater) {
            bsdf = sampleWaterBSDF(-rd, n, outDir, isRefracted);
        } else {
            vec3 bump = vec3(0.);
            bump += noised(p*1550.).xyz;
            bump += noised(p*600.).xyz;
            bump += noised(p*1200.).xyz;
            bump = mix(noised(p*450.).xyz*1., bump, moisture(p));
            n  = normalize(n+bump*.3 );
            bsdf = sampleRockBRDF(-rd, n, p, outDir);
        }
        
        // medium absorption
        traceIn = 1.;
        if (water(p) < 0. && t > 0.3) {
            abso *= exp(-t * (vec3(3.,1.5,1.)) * 1.5 );
        }
        
        // sun light
        if (!isWater)
        {
            vec3 srd = normalize(sundir + (hash3(p)*2.-1.)*.05);
            float tt = trace2(p+n*.0, srd, vec2(0.01, 20.));
            acc += suncolor*12.5 * max(dot(n,srd),0.) * step(20., tt) * rock_albedo(p, n) * abso;
        }
        
        // brdf absorption
        if ( bsdf.a > 0.)
            abso *= bsdf.rgb;
        
        
        // next direction
        ro = p;
        rd = outDir;
        if (isRefracted) {
            ro -= n*0.01;
        } else {
            ro += n*0.01;
        }
    }

    return vec4(acc, firstDepth);
}


// ---------------------------------------------
// Entrypoint
// ---------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    if (fragCoord.x >= RESOLUTION.x || fragCoord.y >= RESOLUTION.y) {
        fragColor = vec4(0.);
        return;
    }
    vec2 invRes = vec2(1.) / RESOLUTION;
    srand(ivec2(fragCoord), iFrame);
    
    // setup ray
    vec2 uv = (fragCoord + frand2()-.5) * invRes;
    vec3 ro = normalize(vec3(cos(-0.9), 0.1, sin(-0.9)))*1.5;
    vec2 v = uv*2.-1.;
    v.x *= RESOLUTION.x * invRes.y;
    
    // setup camera
    const vec3 up = vec3(0.,1.,0.);
    vec3 fw = normalize(vec3(0.,0.2,-1.1)-ro);
    vec3 uu = normalize(cross(fw, up));
    vec3 vv = normalize(cross(uu, fw));
    vec3 er = normalize(vec3(v,6.8));
    vec3 rd = uu * er.x + vv * er.y + fw * er.z;
    
    // depth of field
    float focusDistance = 1.;
    float blurAmount = 0.003;
    vec3 go = blurAmount*vec3( normalize(frand2()*2.-1.)*sqrt(frand()), 0.0 );
    vec3 gd = normalize( er*focusDistance - go );
    ro += go.x*uu + go.y*vv;
    rd += gd.x*uu + gd.y*vv;
    rd = normalize(rd);
    
    
    // pathtrace
    vec4 col = pathtrace(ro, rd);
    col.rgb = mix(col.rgb, vec3(.6,.8,1.)*.5, smoothstep(00.,30., col.a));

    // light scattering
    vec3 acc = vec3(0.);
    float phase = phaseFunction(dot(sundir,rd));
    vec3 p = ro + rd * col.a * frand();
    vec3 srd = normalize(sundir + (hash3(p)*2.-1.)*.05);
    float tt = trace2(p, srd, vec2(0., 20.));
    acc += vec3(1.,.7,.5)*phase*2. * step(20., tt);
    
    fragColor = vec4(min(col.rgb+acc,vec3(10.)),1.);
    fragColor += texture(iChannel0, fragCoord/iResolution.xy);
}