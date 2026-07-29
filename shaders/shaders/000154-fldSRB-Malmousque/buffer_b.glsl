// Buffer B (buffer) — Malmousque by XT95
// https://www.shadertoy.com/view/fldSRB

// ---------------------------------------------------------------------------------
// Raytracing pass
// ---------------------------------------------------------------------------------

const mat3 mt = mat3(0.33338, 0.56034, -0.71817, -0.87887, 0.32651, -0.15323, 0.15162, 0.69596, 0.61339)*1.93;
const mat2 mw = mat2(1.6,1.2,-1.2,1.6);



// ---------------------------------------------------------------------------------
// Signed Distance Field
// ---------------------------------------------------------------------------------
float terrain(vec3 p) {
    
    float d = length(p.xy-vec2(-4.,0.))-2.;
    d = smin(d, capsule(p, vec3(-5.,0.,7.), vec3(0.,2.,7.), 1.), 1.7);
    d = smin(d, p.y-.1+smoothstep(-3.1,5.,p.x)*2., 0.1);
    
    // Add detail only if we are closed of the surface
    if (d < 1.) {
        // Inspired by many shaders of Shane, the master of the rock.
        float z = 1.;
        for(int i = 0; i < 6; i++)
        {
            d -= dot(tri(p*.5 + tri(p.yzx*.375)), vec3(.4*z));
            z *= -0.55;
            p = p*mt;
        }
    }
    
    return d;
}
float water(vec3 p) {
    float d = p.y;
    
    float amp = .1;
    p.xz *= mw;
    float t = time*.3;
    
    // Add detail only if we are closed of the surface
    if (d < .2) {
        for(int i=0; i<6; i++)
        {
            d -= (1.-abs(sin(noise(p.xz-t)))) * amp;
            amp *= .5;
            p.xz *= mw;
        }
    }
    
    return d;
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
vec3 raymarch(vec3 ro, vec3 rd, const vec2 nf) {
    vec3 p = ro + rd * nf.x;
    float l = 0.;
    for(int i=ZERO; i<70; i++) {
        float d = map(p);
        l += d;
        p += rd * d;
        
        if(abs(d)<.01 || l > nf.y)
            break;
    }
    
    return p;
}

vec3 normal( vec3 p )
{
    const float h = 0.005;
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
    for(int i=ZERO; i<32; i++) {
        float d = terrain(p);
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
    
    for( int i=ZERO; i<nbIte; i++ )
    {
        float l = hash(float(i))*maxDist;
        vec3 rd = normalize(n+randomHemisphereDir(n, l )*rad)*l;
        
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
vec3 skyColor(vec3 rd) {
    return texture(iChannel3, cube2equi(rd)*.25).rgb;
}
vec3 shade(vec3 ro, vec3 rd, vec3 p, vec3 n) {
    vec3 sky = skyColor(rd);
    if (map(p) > .3) return sky;
    
    float wet = smoothstep(.15+fbm(p.xz*30.)*.15,0.15,p.y) * step(0.,water(p));
    
    vec3 albedo = tex3D(iChannel1,p*1.,n)*vec3(.3,.275,.25)* (smoothstep(.1,0.4,p.y)+.1);
    albedo = mix(albedo, vec3(0.09,0.15,0.03)*0.5, saturate(fbm(p.xz*20.2)*2.-.3)*wet*.075);
    albedo = mix(albedo, vec3(0.1,0.03,0.2)*0.5, saturate(fbm(p.xz*20.2+1.)*2.-.6)*wet*.075);
    n = bumpMapping(iChannel1,p*1.,n,.005);

    float shad = shadow(p,sundir, .5,10., 10.);
    float ao = ambientOcclusion(p,n, 5.5,1.7);
    ao *= smoothstep(0.5,5., length(p-vec3(-1.,0.5,4.5)));
    
    vec3 diff = vec3(1.,.5,.3) * saturate(dot(n,sundir)+.1) * pow(vec3(shad),vec3(1.0,1.3,1.8));
    vec3 skyl = vec3(0.2,0.25,0.35) * (n.y*.25+.75) * ao;
    vec3 bounce = vec3(1.,.5,.3) * max(dot( n, normalize(sundir*vec3(-1.0,0.0,-1.0))), 0.0) * ao;
    vec3 spe = vec3(1.,.8,.5) * pow(max(dot(reflect(rd,n),sundir),0.), 80.) * shad * wet;
    
    vec3 col = albedo * ( diff*3.+ skyl*1.3 + bounce*.2 + spe*50. );
    
    return col;
}

vec3 calcPixel(vec3 ro, vec3 rd, float seed, inout vec3 firstP) {
    
    // Raytracing primary ray
    vec3 p = raymarch(ro,rd, vec2(1.,60.));
    firstP = p;
    vec3 n = normal(p);
    float d = map(p);
    vec3 sky = skyColor(rd);
    if (d > .3) return sky;
    
    
    vec3 col;
    
    // Fake foam
    float foam = saturate((fbm(p.xz*70.-time*0.25)+fbm(p.xz*50.+time*0.25))*.5-.34);
    
    if (terrain(p) == d) {
        col = shade(ro,rd, p, n);
        col = mix(col, vec3(.1), smoothstep(.025,.0,water(p))*foam);
    } else {
        
        // Reflection
        vec3 rro = p;
        vec3 rrd = reflect(rd,n);
        rrd = normalize(hash3(p+rand())*2.-1.+reflect(rd,n)*3000.);
        
        vec3 rp = raymarch(rro,rrd, vec2(.1,10.));
        vec3 rn = normal(p);

        vec3 reflectedCol = shade(rro,rrd, rp, rn);
        // hackish sun specular 
        reflectedCol += vec3(1.,.7,.5)*30. * pow(max(dot(reflect(rd,n), sundir), 0.), 1024.);
        
        // Refraction
        rro = p;
        rrd = refract(rd,n, 1./1.33);
        
        rp = raymarchUnderwater(rro,rrd, vec2(.1,10.));
        rn = normal(p);
        vec3 refractedCol = shade(rro,rrd, rp, rn);
        refractedCol *= exp( -vec3(1.,.4,.2) * length(rp-p)*50.2); // Beer law for absorption! great blog post -> https://blog.demofox.org/2017/01/09/raytracing-reflection-refraction-fresnel-total-internal-reflection-and-beers-law/
        
        // Mix it with fresnel
        float fre = pow( saturate( 1.0 + dot(n,rd)), 16.0 );
        col = mix(refractedCol, reflectedCol , fre);
        
        col = mix(col, vec3(.1), smoothstep(.075,.0,terrain(p))*foam);
    }
    col = mix(col, sky, smoothstep(10.,60., length(ro-p)));
    
    return col;
}

// ---------------------------------------------------------------------------------
// Entrypoint
// ---------------------------------------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 invRes = vec2(1.) / iResolution.xy;
    vec2 uv = fragCoord * invRes;
    seed = iTime + iResolution.y * fragCoord.x / iResolution.x + fragCoord.y / iResolution.y;
    vec2 v = -1.0+2.0*(uv);
    v.x *= iResolution.x/iResolution.y;
    
    // Camera ray
    vec3 ro = vec3(-1.,.5,0.);
    vec3 rd = normalize( vec3(v.x, v.y, 5.) );
    
    // Depth of field
    float focusDistance = 1.5;
    float blurAmount = max(0., 0.02*uv.x);
    vec3 go = blurAmount*vec3( normalize(vec2(rand(),rand())*2.-1.)*sqrt(rand()), 0.0 );
    vec3 gd = normalize( rd*focusDistance - go );
    vec3 uu = vec3(1.,0.,0.);
    vec3 vv = vec3(0.,1.,0.);
    ro += go.x*uu + go.y*vv;
    rd += gd.x*uu + gd.y*vv;
    rd = normalize(rd);
    
    
    // Compute color
    vec3 p;
    vec3 col = calcPixel(ro, rd, seed, p);
    
    
    // Output with temporal accumulation
    vec4 lastCol = texture(iChannel0,uv);
    
    // Nice tricks here : more temporal accumulation when we are out of focus :)
    float taaFactor = (1.05-saturate(abs(focusDistance-length(p-ro))/1.)) *0.75;
    if (iFrame == 0) taaFactor = 1.;
    //taaFactor = 1.;
    fragColor = mix(lastCol, vec4(saturate(col), length(ro-p)), taaFactor);
}