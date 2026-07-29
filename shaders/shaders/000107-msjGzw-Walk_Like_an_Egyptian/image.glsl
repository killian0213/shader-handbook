// Image (image) — Walk Like an Egyptian by XT95
// https://www.shadertoy.com/view/msjGzw

#define sunpos vec2(.5,.25)

float clouds(vec2 uv) {
    uv.x += iTime*.001;
    float d = fbm( vec3(uv*vec2(4.,10.)*1.1+50., iTime*.01) );
    d += abs(cos(uv.x*70.)*.5 + cos(uv.x*160.)*.25)*0.07;
    d += uv.y-1.;
    return d+.2;
}

vec4 background(vec2 uv, vec2 p) {
    vec4 col = vec4(0., 0., 0., 1.);
    
    // greenish sky
    col.rgb = pow( vec3(.5), vec3(5., 2.5*uv.y, 2.*(uv.y*-.1+1.)) );
    
    // clouds
    float c = smoothstep(0.3,.32,clouds(uv));
    float cs = smoothstep(0.3,.32, clouds(uv - normalize(p-sunpos)*.015));
    col.rgb += vec3(.5,.4,.3) * c * (1.-cs);
    col.rgb += vec3(.5,.4,.3)*.75 * c * (cs);
    
    // stars
    col.rgb += vec3(1.) * smoothstep(0.8,1., noise(vec3(uv*500., iTime*.1))) * (1.-c);
    
    
    // sun
    float d = distance(p, sunpos);
    col.rgb += vec3(1.) * smoothstep(0.16,.15,d);
    col.rgb += vec3(1.,1.,.5) * pow(1./(1.+d), 8.)*1.;
    
    return col;
}

vec4 pyramids(vec2 p, float freq, float proba) {
    vec4 col = vec4(0., 0., 0., 0.);

    float seed = floor(p.x*freq-.5);
    float h = fract(p.x*freq);
    float d = -p.y + abs(h-.5)/freq * step(proba,hash1(seed));
    float m = smoothstep(0.,0.01,d) ;
    
    float ds = -p.y + saturate(h-.5)/freq * step(proba,hash1(seed));
    float ms = smoothstep(0.,0.01,ds) ;
    
    col.rgb = vec3(1.,.5,.0) * smoothstep(0.6,.5, fbm(p*vec2(10.,100.)*freq));
    col.rgb = mix(col.rgb, vec3(1.,.5,.0)*.3, ms);
    
    col.rgb *= smoothstep(0.,0.015, abs(d-0.005)); // outline
    
    col.rgb = saturate(col.rgb);
    
    col.a = max(m, ms);
    
    return col * col.a;
}

float moutainsHeight(vec2 p, float amp, float power) {
    float d = - pow(abs(sin(p.x*5.)*.5+ sin(p.x*2.+2.5)*.25 + sin(p.x*4.+2.)*.125), power) * amp;
    return d;
}

vec4 mountains(vec2 p, float amp, float power) {
    vec4 col = vec4(0., 0., 0., 0.);
    
    float h = -p.y + moutainsHeight(p,amp,power);
    float hs = -p.y +moutainsHeight(p + normalize(p-(sunpos*2.-1.))*.05,amp,power);
    float d = smoothstep(0.,0.01,h);
    float ds = smoothstep(0.,0.01,hs);
    
    col = vec4(1.,1., 1., 1.) * d;
    col.rgb *= vec3(1.,.4,.2)*(smoothstep(0.,-1.,ds-d)*.75+.25);
    col.rgb *= smoothstep(0.,0.02,abs(h-.01)); // outline
    //col.rgb *= (sin(d*50.+fbm(p*vec2(5.,50.)))*.5+.5)*.5+.5;
    col.rgb = saturate(col.rgb);
    return col * col.a;
}

vec4 cactus(vec2 p, float freq) {

    vec4 col = vec4(0., 0., 0., 0.);
    
    
    vec2 ip = floor(p*freq);
    vec2 fp = fract(p*freq)-.5;
    float seed = hash1(ip.x);
    fp.y = p.y*2. + (seed)*.4;
    
    if (hash1(ip.x+1000.) > .3) {
        return vec4(0.);
    }
    
    float d = line(fp, vec2(0.,-.3), vec2(0.,.3));
        
    if (hash1(ip.x+100.) > .5) {
        fp.x = -fp.x;
    }
    
    if (seed > .25) {
        d = min(d, line(fp, vec2(0.,0.), vec2(0.3,.0))*1.8);
        d = min(d, line(fp, vec2(0.3,0.015), vec2(0.3,.2))*1.3);
    }
    
    d = min(d, line(fp, vec2(0.,-.15), vec2(-0.3,-.15))*1.8);
    d = min(d, line(fp, vec2(-0.3,-.14), vec2(-0.3,.05))*1.3);
    d = d-p.y*.3 - fbm(p*300.+5.)*.005;
    
    
    col = vec4(vec3(0.4,1.,0.)*.5 * (smoothstep(0.5,.6, fbm(p*vec2(300.,5.)+5.)*.5+.5)*.25+.75), smoothstep(0.1,0.09,d));
    
    col.rgb *= vec3(1.) * smoothstep(0.007,0.012, abs(d-.098)); // outline
    
    return col * col.a;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 invRes = vec2(1.) / iResolution.xy;
    vec2 uv = fragCoord * invRes;
    vec2 p = (2.*fragCoord - iResolution.xy) / iResolution.y;
    vec2 pp = p;
    
    
    // background
    vec4 col = background(uv, pp);
    
    
    // layers
    #define LAYER_SPEED 0.05
    #define LAYER_COUNT 8
    vec4 layer[LAYER_COUNT];
    p.x += iTime*LAYER_SPEED;    layer[0] = mountains(p*vec2(.5,3.)-vec2(0.,.3), .75, 1.2) * vec4(vec3(.25),1.);
    p.x += iTime*LAYER_SPEED;    layer[1] = pyramids(p-vec2(0.,-.4), 1., .6);
    p.x += iTime*LAYER_SPEED;    layer[2] = pyramids(p-vec2(0.,-.39), .5, .6);
    p.x += iTime*LAYER_SPEED;    layer[3] = mountains(p*vec2(.25,2.25)-vec2(10.,-0.5), 1., 1.2);
    p.x += iTime*LAYER_SPEED;    layer[4] = cactus(p*1.5-vec2(0.,-.7),3.)*1.;
    p.x += iTime*LAYER_SPEED;    layer[5] = mountains(p*vec2(.25,2.)-vec2(0.,-0.6), 1., 1.2);
    p.x += iTime*LAYER_SPEED;    layer[6] = mountains(p*vec2(.15,2.)-vec2(1000.,-0.7), 1., 1.2);
    p.x += iTime*LAYER_SPEED;    layer[7] = cactus(p*.2-vec2(0.,-.0),3.);
    
    // merge layers with alpha premultiplied
    for(int i=0; i<LAYER_COUNT; i++) {
        col.rgb = col.rgb * (1.-layer[i].a) + layer[i].rgb * (2./(pow(float(i),2.5)+1.));
    }
    
    // flare
    float d = distance(pp, sunpos);
    col.rgb += vec3(1.,1.,.5) * pow(1./(1.+d), 3.)*.1;
    
    
    // color grading
    col.rgb = pow(col.rgb, vec3(1.0,1.5,1.3));
    
    // vignetting
    col.rgb *= pow( uv.x*uv.y*(1.-uv.x)*(1.-uv.y)*100., .1);

    // gamma correction
    col.rgb = pow(col.rgb, vec3(1./2.2));
    
    // output to the screen
    fragColor = vec4(col.rgb * smoothstep(0.,3., iTime),1.0);
}
