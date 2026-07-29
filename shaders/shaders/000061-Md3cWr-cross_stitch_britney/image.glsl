// Image (image) — cross stitch britney by flockaroo
// https://www.shadertoy.com/view/Md3cWr

// created by florian berger (flockaroo) - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// cross stitch

// mixing, lighting, ssao, color bleeding

// configured for green-screen background.
// uncomment your prefered bg in BufA from line 178 on

#ifdef SHADEROO
#define CrossSize floor((18.*sqrt(iResolution.x/650.))/(1.-.0003*iMouseData.z))
#else
#define CrossSize floor(18.*sqrt(iResolution.x/650.))
#endif

float getVal(vec2 coord)
{
    return texture(iChannel0,coord/iResolution.xy).w;
}

vec2 getGrad(vec2 coord,float eps)
{
    vec2 d=vec2(eps,0);
    return vec2(
        getVal(coord+d.xy)-getVal(coord-d.xy),
        getVal(coord+d.yx)-getVal(coord-d.yx)
        )/eps/2.;
}

vec4 getRand(vec2 coord)
{
    vec2 rres=vec2(textureSize(iChannel1,0));
    return texture(iChannel1,coord/rres);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 rnd=texture(iChannel1,fragCoord/iResolution.xy*.04);
    vec4 rnd2=texture(iChannel1,fragCoord/iResolution.xy*.08);
    vec4 col=texture(iChannel0,fragCoord/iResolution.xy);
    // FIXME: +log(iResolution.x/600.) is not right because ao spread should be proportional 
    // to pixel size which scales by sqrt(res) ...
    vec4 col1=texture(iChannel0,fragCoord/iResolution.xy,1.+log(CrossSize/20.)/log(2.));
    vec4 col2=texture(iChannel0,fragCoord/iResolution.xy,3.+log(CrossSize/20.)/log(2.));
    vec3 n=normalize(vec3(-getGrad(fragCoord,.1)-2.*getGrad(fragCoord,2.)+.75*(rnd.xy-.5)+.3*(rnd2.xy-.5),1.5));
    //fragColor.xyz=vec3(1)*col.w*mix(vec3(1,.9,.8),vec3(1),step(.7,col.x));
    float diff = clamp(dot(n,normalize(vec3(.5,.05,1.))),0.,1.);
    float amb=0.5;
    fragColor.xyz=mix(((col1.xyz-.5)*2.+.5)*amb,(.15*col.xyz+.55*col1.xyz+.3*col2.xyz),diff)*(.5+.5*sqrt(col.w));
    vec2 sc=(fragCoord/iResolution.xy-.5)*2.;
    vec2 ds=((fragCoord-iResolution.xy*.5)/iResolution.x);
    // color bleeding
    fragColor.xyz=mix(fragColor.xyz,col2.xyz,.2);
    // ssao
    fragColor.xyz*=vec3(clamp(1.-(.75*(col2.w-col1.w)-.25*(col1.w-col.w))*.2,0.,1.));
    //fragColor.xyz=pow(fragColor.xyz,vec3(.8));
    fragColor.xyz*=(1.-1.5*dot(ds,ds))*1.1
    *(1.-smoothstep(.9,1.4,abs(sc.x)))
    *(1.-smoothstep(.9,1.4,abs(sc.y)));
    //fragColor.xyz=vec3(texture(iChannel0,fragCoord/iResolution.xy).w);
    fragColor.w=1.;
}

