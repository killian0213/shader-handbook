// Buffer B (buffer) — Niolon by XT95
// https://www.shadertoy.com/view/Nt3XDM

// ---------------------------------------------------------------------------------
// Raytracing pass
// ---------------------------------------------------------------------------------




// ---------------------------------------------------------------------------------
// Signed Distance Field
// ---------------------------------------------------------------------------------
float terrain(vec3 p) {
    
    float d = length(abs(p.xy)+vec2(-220.,50.))-200.;
    d = min(d, length(p.zy-vec2(-10.,60.))-50.+cos(p.x*.04)*10.);
    d = min(d, length(p.zy-vec2(-400.,0.))-150.);
    d = min(d, length(p.zy-vec2(400.,0.))-150.);
    d = d*.2  + noise(p*.04-.9)*10. - noise(p*.2)*0.9+.5;
    d = min(d, p.y*.5 + d);
    return d;
}
float water(vec3 p) {
#if RAYTRACED_WATER
    return p.y - texture(iChannel2,p.xz*.01-.5).r;
#else
    return p.y;
#endif
}

float map(vec3 p) {
    float d1 = terrain(p);
    float d2 = water(p);
    float d = min(d1,d2);
    return d;
    
}


// ---------------------------------------------------------------------------------
// Raytracing toolbox
// ---------------------------------------------------------------------------------
#define ZERO (min(iFrame,0)) // skip unroll loop

vec3 raymarch(vec3 ro, vec3 rd, const vec2 nf) {
    vec3 p = ro + rd * nf.x;
    float l = 0.;
    for(int i=ZERO; i<180; i++) {
        float d = map(p)*2.;
        l += d;
        p += rd * d;
        
        if(abs(d)<.05 || l > nf.y)
            break;
    }
    
    return p;
}

vec3 normal( vec3 p )
{
    const float h = 0.1;
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*h);
    }
    return normalize(n);
}


vec3 raymarchUnderwater(vec3 ro, vec3 rd, const vec2 nf) {
    vec3 p = ro + rd * nf.x;
    float l = 0.;
    for(int i=ZERO; i<64; i++) {
        float d = terrain(p)*2.;
        l += d;
        p += rd * d;
        
        if(abs(d)<.05 || l > nf.y)
            break;
    }
    
    return p;
}
// Simplified version of https://www.shadertoy.com/view/4sdGWN - http://www.aduprat.com/portfolio/?page=articles/hemisphericalSDFAO
float ambientOcclusion( in vec3 p, in vec3 n, in float maxDist, in float falloff )
{
    const int nbIte = 6;
    const float nbIteInv = 1./float(nbIte);
    const float rad = 1.-1.*nbIteInv;
    
    float ao = 0.0;
    
    for( int i=ZERO+1; i<nbIte; i++ )
    {
        float l = float(i)/float(nbIte)*maxDist;
        vec3 rd = cosineDirection(p,n)*l;
        
        ao += (l - max(terrain( p + rd ),0.)) / maxDist * falloff;
    }
    
    return clamp( 1.-ao*nbIteInv, 0., 1.);
}
// iq Soft Shadow - https://iquilezles.org/articles/rmshadows
float shadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    for( float t=mint; t<maxt; )
    {
        float h = terrain(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}

// ---------------------------------------------------------------------------------
// Shading
// ---------------------------------------------------------------------------------
vec3 sky( in vec3 rd )
{
    return mix(vec3(1.), vec3(0.2,.6,1.)*.5, 1.-exp(-rd.y*3.));
}

vec3 shade(vec3 ro, vec3 rd, vec3 p, vec3 n) {
    float d = map(p);
    
    if (d > 3.) return sky(rd);
    
    vec3 albedo = tex3D(iChannel1,p*0.05,n)*.5;
    //albedo = mix(albedo, vec3(1.)*sqrt(dot(albedo,albedo)), 0.2);
    albedo *= mix(vec3(1.), vec3(1.,1.,0.3), smoothstep(0.6,1.,n.y)*smoothstep(0.0,2.,p.y));
    n = bumpMapping(iChannel1,p*.05,n,.08);

    // inspired by https://iquilezles.org/articles/outdoorslighting
    float shad = shadow(p,sundir, .5,150., 50.);
    float ao = pow(ambientOcclusion(p,n, 40.,2.7),1.25);
    
    vec3 diff = vec3(1.,.7,.3) * max(dot(n,sundir),0.) * pow(vec3(shad),vec3(1.0,1.2,1.7));
    vec3 skyl = vec3(0.1,0.2,0.3) * (n.y*.5+.5) * ao;
    vec3 bounce = vec3(1.,.7,.3) * max(dot( n, normalize(sundir*vec3(-1.0,0.0,-1.0))), 0.0) * ao;
    vec3 caustic = vec3(1.) * texture(iChannel2,p.xz*0.02).g * smoothstep(50.,0.,p.y) * smoothstep(-.5,-1.,n.y) *(ao*.5+.5);
    
    return albedo * (diff*3. + skyl*6. + bounce*1. + caustic*2.);
}

vec3 calcPixel(vec3 ro, vec3 rd, float seed, inout vec3 firstP) {
    
    // Raytracing primary ray
    vec3 p = raymarch(ro,rd, vec2(.1,600.));
    firstP = p;
    vec3 n = normal(p);
    float d = map(p);
    
    
    vec3 col;
    if (terrain(p) == d) {
        col = shade(ro,rd, p, n);
    } else {
    
#if !RAYTRACED_WATER
        n = bumpMapping(iChannel2, p*0.01-.7, n, 0.5/length(ro-p));
#endif
        
        // Reflection
        vec3 rro = p;
        vec3 rrd = reflect(rd,n);
        rrd = normalize(hash3(p+rand())*2.-1.+reflect(rd,n)*3000.);
        
        vec3 rp = raymarch(rro,rrd, vec2(.1,600.));
        vec3 rn = normal(p);

        vec3 reflectedCol = shade(rro,rrd, rp, rn);
        
        // Refraction
        rro = p;
        rrd = refract(rd,n, 1./1.33);
        
        rp = raymarchUnderwater(rro,rrd, vec2(.1,500.));
        rn = normal(p);
        vec3 refractedCol = shade(rro,rrd, rp, rn);
        refractedCol += vec3(0.5) * pow(texture(iChannel2,rp.xz*0.02).g,2.) * smoothstep(0.,-30.,rp.y);// Add more fake caustics
        refractedCol *= exp( -vec3(1.,.2,.1) * length(rp-p)*0.2); // Beer law for absorption! great blog post -> https://blog.demofox.org/2017/01/09/raytracing-reflection-refraction-fresnel-total-internal-reflection-and-beers-law/
        
        // Mix it with fresnel
        float fre = pow( saturate( 1.0 + dot(n,rd)), 8.0 );
        col = mix(refractedCol, reflectedCol , fre);
    }
    
    return col;
}

// ---------------------------------------------------------------------------------
// Entrypoint
// ---------------------------------------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 invRes = vec2(1.) / iResolution.xy;
    vec2 uv = fragCoord * invRes * SCALE_FACTOR;
    
    if(uv.x>1. || uv.y>1. )
    {
        fragColor = vec4(0.);
        return;
    } 
    
    seed = iTime + iResolution.y * fragCoord.x / iResolution.x + fragCoord.y / iResolution.y;
    vec2 jitt = vec2(0.);
    jitt = vec2(rand()-.5, rand()-.5) * invRes;
    vec2 v = -1.0+2.0*(uv+jitt);
    v.x *= iResolution.x/iResolution.y;
    
    
    // Camera ray
    vec3 ro = vec3(0.,10.,185.-time*0.1);
    vec3 rd = normalize( vec3(v.x, v.y, -4.) );
    
    // Depth of field
    float focusDistance = 80.3;
    float blurAmount = 0.1;
    vec3 go = blurAmount*vec3( vec2(rand(),rand())*2.-1., 0.0 );
    vec3 gd = normalize( rd*focusDistance - go );
    vec3 uu = vec3(1.,0.,0.);
    vec3 vv = vec3(0.,1.,0.);
    ro += go.x*uu + go.y*vv;
    rd += gd.x*uu + gd.y*vv;
    
    // Comput color
    vec3 p;
    vec3 col = calcPixel(ro, rd, seed, p);
    
    
    // Output with temporal accumulation
    vec4 lastCol = texture(iChannel0,uv/SCALE_FACTOR);
    fragColor = mix(lastCol, vec4(saturate(col), length(ro-p)), .15);
}