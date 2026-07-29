// Buffer C (buffer) — Marble Marcher: SE by michael0884
// https://www.shadertoy.com/view/3lKyDR

//TAA

vec3 encodePalYuv(vec3 rgb)
{
    return vec3(
        dot(rgb, vec3(0.299, 0.587, 0.114)),
        dot(rgb, vec3(-0.14713, -0.28886, 0.436)),
        dot(rgb, vec3(0.615, -0.51499, -0.10001))
    );
}

vec3 decodePalYuv(vec3 yuv)
{
    return vec3(
        dot(yuv, vec3(1., 0., 1.13983)),
        dot(yuv, vec3(1., -0.39465, -0.58060)),
        dot(yuv, vec3(1., 2.03211, 0.))
    ); 
}

vec3 mul3( in mat3 m, in vec3 v ){return vec3(dot(v,m[0]),dot(v,m[1]),dot(v,m[2]));}

vec3 mul3( in vec3 v, in mat3 m ){return mul3(m,v);}

vec3 srgb2oklab(vec3 c) {
    
    mat3 m1 = mat3(
        0.4122214708,0.5363325363,0.0514459929,
        0.2119034982,0.6806995451,0.1073969566,
        0.0883024619,0.2817188376,0.6299787005
    );
    
    vec3 lms = mul3(m1,c);
    
    lms = pow(lms,vec3(1./3.));

    mat3 m2 = mat3(
        +0.2104542553,+0.7936177850,-0.0040720468,
        +1.9779984951,-2.4285922050,+0.4505937099,
        +0.0259040371,+0.7827717662,-0.8086757660
    );
    
    return mul3(m2,lms);
}

vec3 oklab2srgb(vec3 c)
{
    mat3 m1 = mat3(
        1.0000000000,+0.3963377774,+0.2158037573,
        1.0000000000,-0.1055613458,-0.0638541728,
        1.0000000000,-0.0894841775,-1.2914855480
    );

    vec3 lms = mul3(m1,c);
    
    lms = lms * lms * lms;
  
    mat3 m2 = mat3(
        +4.0767416621,-3.3077115913,+0.2309699292,
        -1.2684380046,+2.6097574011,-0.3413193965,
        -0.0041960863,-0.7034186147,+1.7076147010
    );
    return mul3(m2,lms);
}

vec3 enc_color(vec3 x)
{
    return srgb2oklab(x);
}

vec3 dec_color(vec3 x)
{
    return oklab2srgb(x);
}

void mainImage( out vec4 c, in vec2 p )
{
    rng_initialize(p, iFrame);
    load_scene(iChannel2, iTime, iResolution.xy);
    vec2 jitter = halton(iFrame%16) - 0.5; 
    vec4 bufB = texture(iChannel0, (p-jitter)/iResolution.xy);
    
    vec4 col = vec4(bufB.xyz, 1.);
    
    vec2 uv = (p  - 0.5*iResolution.xy)/iResolution.y;
    vec4 ro = vec4(campos, bufB.w);    
    vec3 rd = normalize(cam*vec3(1, FOV*uv));
    ro.xyz += ro.w*rd;
    vec4 X = ro;
    material mat = getMaterial(X);
    ro.xyz -= mat.velocity;
    
    vec3 reprj = reproject(pcam, pcampos, pResolution.xy, ro.xyz);
    vec2 puv = reprj.xy/iResolution.xy;
    vec2 dpuv = abs(puv - vec2(0.5));

    vec3 prev_col = texture_Bicubic(iChannel1, puv).xyz;
    
    //neighborhood clamping
    vec3 minc = vec3(1e10); 
    vec3 maxc = vec3(0.);
    for(int i = -NEIGHBOR_CLAMP_RADIUS; i < NEIGHBOR_CLAMP_RADIUS; i++)
        for(int j = -NEIGHBOR_CLAMP_RADIUS; j < NEIGHBOR_CLAMP_RADIUS; j++)
    {
        vec3 pix = enc_color(texelFetch(iChannel0, ivec2(p) + ivec2(i,j), 0).xyz);
        minc = min(pix, minc);
        maxc = max(pix, maxc);
    }
    
    vec3 preclamp = enc_color(prev_col);
    prev_col = clamp(preclamp, minc, maxc);
    float delta = distance(prev_col, preclamp);
    prev_col = dec_color(prev_col);
     
    
    vec2 v = decode(texelFetch(iChannel1, ivec2(puv*iResolution.xy), 0).w);
    
    vec4 prev = vec4(prev_col, 1.0)*v.y;
    float prev_td = 2.0/v.x;
    
    vec3 prev_pos = normalize(ro.xyz - pcampos)*prev_td + pcampos;
    float ang_distance = distance(normalize(prev_pos - campos),normalize(ro.xyz - campos));
    
    if(iFrame < 2) prev*=0.0;
    //prev*=mix(1.0, smoothstep(0.6, 0.5, delta), 0.1);
    prev*=mix(1.0, step(ang_distance, DISOCCLUSION_REJECTION), DISOCCLUSION_REJECTION_STR);
    float dist = distance(prev.xyz/prev.w, col.xyz/col.w);
    prev*=mix(1.0, smoothstep(CAMERA_MOVEMENT_REJECTION, 0., distance(campos, pcampos)),0.05);
    

    //prev*=mix(1.0, smoothstep(0.7, 0.6, dist),1.0);
    col += prev*REPROJECTION*step(dpuv.x, 0.5)*step(dpuv.y, 0.5); 
    
    c.xyz = 1.*col.xyz/col.w + 0.*ang_distance;
    c.w = encode(vec2(2.0/ro.w, col.w));
}