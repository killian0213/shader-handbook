// Buffer D (buffer) — LEGO Sanctuary by Mathis
// https://www.shadertoy.com/view/slByR1

//DOF

vec3 Fog(vec3 P, vec3 C) {
    //Adds fog
    float Density=0.27*exp(-max(0.,P.y-3.));
    return mix(C,vec3(0.1,0.4,1.)*Density*Density,Density);
}

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign=-mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D=vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D=D.xzy;
    else if (UV.y>2048.) D=D.zxy;
    return texture(iChannel3,D);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output=texture(iChannel1,fragCoord*IRES);
    if (iFrame>15) {
       //Complete init
        #ifdef DOF
            vec4 CSample=texture(iChannel0,fragCoord*IRES);
            vec2 Offset=textureCube(vec2(mod(fragCoord+vec2(CSample.w*351.,floor(CSample.w*I64)*323.),vec2(1024.))+vec2(0.,5120.))).zx;
            Offset.x*=2.*3.141592653;
            Offset=vec2(sin(Offset.x),cos(Offset.x))*sqrt(1.-Offset.y*Offset.y);
            float DOF_Radius=max(0.,length(fragCoord*IRES-0.5)-0.25)*iChannelResolution[0].x*0.012;
            vec2 SUV=fragCoord+Offset*DOF_Radius;
            //Reset
            if (CSample.w==1.) {
                Output=vec4(CSample.xyz,1.);
                float D=texture(iChannel2,fragCoord*IRES).w;
                vec2 PixelUV=(fragCoord-HRES)*IRES.x*2.*IsoWidth;
                Output.xyz=Fog(IsoPos+IsoDir*D+IsoTan*PixelUV.x+IsoBit*PixelUV.y,Output.xyz);
            } else {
                float D=texture(iChannel2,SUV*IRES).w;
                vec2 PixelUV=(SUV-HRES)*IRES.x*2.*IsoWidth;
                vec3 NLight=Fog(IsoPos+IsoDir*D+IsoTan*PixelUV.x+IsoBit*PixelUV.y,texture(iChannel0,SUV*IRES).xyz);
                Output=vec4((Output.xyz*Output.w+NLight)/(Output.w+1.),Output.w+1.);
            }
        #else
            Output=texture(iChannel0,fragCoord*IRES);
            float D=texture(iChannel2,fragCoord*IRES).w;
            vec2 PixelUV=(fragCoord-HRES)*IRES.x*2.*IsoWidth;
            Output.xyz=Fog(IsoPos+IsoDir*D+IsoTan*PixelUV.x+IsoBit*PixelUV.y,Output.xyz);
        #endif
    } else {
        //Black screen
        Output=vec4(0.);
    }
    //Return
    fragColor=Output;
}