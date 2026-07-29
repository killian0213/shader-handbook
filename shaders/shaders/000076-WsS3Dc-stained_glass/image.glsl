// Image (image) — stained glass by flockaroo
// https://www.shadertoy.com/view/WsS3Dc

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// multi scale subdivision

// create glass and lead finish

#define iPassIndex (iFrame%NumPasses)

#define Res (iResolution.xy)
#define Res0 vec2(textureSize(iChannel0,0))
#define Res1 vec2(textureSize(iChannel1,0))
#define Res2 vec2(textureSize(iChannel2,0))
#define Res3 vec2(textureSize(iChannel3,0))

#define ColorTex iChannel2

vec4 getRand(vec2 coord)
{
    vec4 c=vec4(0);
    c+=texture(iChannel1,coord+.003*iTime);
    c+=texture(iChannel1,coord/2.+.003*iTime)*2.;
    c+=texture(iChannel1,coord/4.+.003*iTime)*4.;
    c+=texture(iChannel1,coord/8.+.003*iTime)*8.;
    return c/(1.+2.+4.+8.);
}

float getVal(vec2 pos,float lod)
{
    //return textureLod(iChannel0,pos/Res,lod).w;
    vec4 c=textureLod(iChannel0,pos/Res,lod);
    float d=c.z;
    float sc=c.w;
    return clamp(1.-pow(7.5*d*d/sc,1.2),0.,1.);
    //return (1.-70.*d*d*d*d/sc/sc);
}

vec2 getGrad(vec2 pos,float eps)
{
    vec2 d=vec2(eps,0);
    return vec2(
        getVal(pos+d.xy,0.)-getVal(pos-d.xy,0.),
        getVal(pos+d.yx,0.)-getVal(pos-d.yx,0.)
        )/eps/2.;
}

#define PI2 6.28318530718
    
#ifndef RandTex
#define RandTex iChannel1
#endif

vec2 uvSmooth(vec2 uv,vec2 res)
{
    return uv+.6*sin(uv*res*PI2)/PI2/res;
}

vec4 getRandSm(vec2 pos)
{
    vec2 tres=vec2(textureSize(RandTex,0));
    //vec2 fr=fract(pos-.5);
    //vec2 uv=(pos-.7*sin(fr*PI2)/PI2)/tres.xy;
    vec2 uv=pos/tres.xy;
    uv=uvSmooth(uv,tres);
    return textureLod(RandTex,uv,0.);
}

float getValH(vec2 pos, float lod)
{
    return abs(getRandSm(pos*.1).x-getRandSm(pos*.1+vec2(17.5,13.5)).x);
}

vec2 getGradH(vec2 pos,float eps)
{
    vec2 d=vec2(eps,0);
    return vec2(
        getValH(pos+d.xy,0.)-getValH(pos-d.xy,0.),
        getValH(pos+d.yx,0.)-getValH(pos-d.yx,0.)
        )/eps/2.;
}

vec3 getGlassNormal(vec2 pos)
{
    vec3 n = normalize(vec3(getGradH(pos,1.4),.5));
    return n;
}




vec4 getCol(vec2 uv)
{
    #define DRes Res
    #define SRes vec2(textureSize(ColorTex,0))
    uv=(uv-.5)*DRes*min(SRes.x/DRes.x,SRes.y/DRes.y)/SRes+.5;
    return texture(ColorTex,uv);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 cosi=sin(vec2(1.6,0)+.7*iTime);
 	mat3 rot = mat3(cosi.xyy*vec3(1,0,1),vec3(0,1,0),cosi.yyx*vec3(-1,0,1));
    float SC=Res.x/600.;
    float SSC=sqrt(SC);
    
    vec2 scr=fragCoord/Res*2.-1.;
    vec3 vdir=normalize(vec3(scr,-2.));

    vec3 n = normalize(vec3(-getGrad(fragCoord,1.),1));
    vec3 ng = normalize(vec3(
         (texture(iChannel1,fragCoord/Res1/1.4).xy-.5)*1.
        +(texture(iChannel1,fragCoord/Res1/3.).xy-.5)*1.
        +(texture(iChannel1,fragCoord/Res1/6.).xy-.5)*1.
        ,0)
        +vec3(0,0,4.5));
        
    ng=getGlassNormal(fragCoord*3./SSC);
    
    //vec3 backlight=texture(iChannel1,(refract(vdir,ng,1.5).xy-.7*.5*iTime*vec2(1,0))*.021).xxx*.8+.8;
    vec3 backlight=texture(iChannel3,rot*refract(vdir,ng,1.5).xyz,-1.5).xyz*1.+.6;
    //vec3 refl=myenv(vec3(0,0,0.),reflect(vdir,ng).xzy,1.).xyz;
    vec3 refl=texture(iChannel3,rot*reflect(vdir,ng).xyz,-1.5).xyz;
    //vec3 leadrefl=myenv(vec3(0,0,0.),reflect(vdir,n).xzy,1.).xyz;
    
    vec4 col = texture(iChannel0,fragCoord/Res);
    float leadH = getVal(fragCoord,0.);
    float d = col.z;
    float sc = col.w;
    col.xyz = getCol(col.xy).xyz;
    float br=dot(col.xyz,vec3(.3333));
    col.xyz=clamp((col.xyz-br)*1.3+br*1.+.12,0.,1.);

    //vec3 leadcol=textureLod(iChannel1,(reflect(vdir,n).xy+1.*iTime*vec2(1,0))*.015,0.).xyz*.65;
    vec3 leadcol=textureLod(iChannel3,rot*reflect(vdir,n).xyz,5.2).xyz*1.;
    //float lbr=dot(leadcol,vec3(.3333));
    //leadcol=(leadcol-lbr)*.3+lbr;
    vec4 col2=texture(iChannel0,((fragCoord+3.5*vec2(-1,1)*SC+SC*3.*sin(iTime*vec2(2,3)))/Res-.5)*1.+.5,2.7+log2(SC));
    float d2=col2.z;
    backlight*=.7+1.*smoothstep(0.,8.*SC,d2)*.5*(.7+.3*texture(iChannel2,col2.xy).xyz);
    float ao=1.;
    ao*=1.5-.5*clamp(d/(4.*SC),0.,1.);
    ao*=.5+.5*clamp(d/(2.*SC),0.,1.);
    //backlight=vec3(1);
    //leadcol=.5*leadrefl;
    leadcol*=leadH;
    //refl=vec3(clamp(ng.x*-ng.y,0.,1.))*(.8+.2*ng);
    vec3 refl2=vec3(clamp(n.x*-n.y*2.,0.,1.))/**(.8+.2*n)*/;
    fragColor.xyz = mix(col.xyz*ao*backlight+refl*.3,leadcol,clamp(leadH,0.,1.));
    
    //fragColor.xyz=textureLod(iChannel3,rot*reflect(vdir,n).xyz,4.5).xyz;
    //fragColor.xyz=leadcol;
    
    // vignetting
    if(true)
    {
        vec2 scc=(fragCoord-.5*iResolution.xy)/iResolution.x;
        float vign = 1.-.7*dot(scc,scc);
        vign*=1.-.7*exp(-sin(fragCoord.x/iResolution.x*3.1416)*20.);
        vign*=1.-.7*exp(-sin(fragCoord.y/iResolution.y*3.1416)*10.);
        fragColor.xyz *= vign;
    }
    
    fragColor.w=1.;
}

