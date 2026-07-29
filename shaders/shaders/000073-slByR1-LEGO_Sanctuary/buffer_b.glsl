// Buffer B (buffer) — LEGO Sanctuary by Mathis
// https://www.shadertoy.com/view/slByR1

//Quadtree

vec2 MinMax2x2_0(vec2 FUV, vec2 GRES) {
    //Computes min/max
    vec2 S=texture(iChannel0,FUV*IRES).ww+vec2(0.,0.2);
    vec2 O=S;
    if (DFBox(FUV+vec2(1.,0.),GRES)<0.) {
        S=texture(iChannel0,vec2(FUV.x+1.,FUV.y)*IRES).ww+vec2(0.,0.2);
        O=vec2(min(O.x,S.x),max(O.y,S.y));
    }
    if (DFBox(FUV+vec2(0.,1.),GRES)<0.) {
        S=texture(iChannel0,vec2(FUV.x,FUV.y+1.)*IRES).ww+vec2(0.,0.2);
        O=vec2(min(O.x,S.x),max(O.y,S.y));
    }
    if (DFBox(FUV+1.,GRES)<0.) {
        S=texture(iChannel0,(FUV+1.)*IRES).ww+vec2(0.,0.2);
        O=vec2(min(O.x,S.x),max(O.y,S.y));
    }
    return O;
}

vec2 MinMax2x2(vec2 FUV, vec2 UVOffset, vec2 GRES) {
    //Computes min/max
    vec2 S=texture(iChannel1,(UVOffset+FUV)*IRES).xy;
    vec2 O=S;
    if (DFBox(FUV+vec2(1.,0.),GRES)<0.) {
        S=texture(iChannel1,(UVOffset+vec2(FUV.x+1.,FUV.y))*IRES).xy;
        O=vec2(min(O.x,S.x),max(O.y,S.y));
    }
    if (DFBox(FUV+vec2(0.,1.),GRES)<0.) {
        S=texture(iChannel1,(UVOffset+vec2(FUV.x,FUV.y+1.))*IRES).xy;
        O=vec2(min(O.x,S.x),max(O.y,S.y));
    }
    if (DFBox(FUV+1.,GRES)<0.) {
        S=texture(iChannel1,(UVOffset+FUV+1.)*IRES).xy;
        O=vec2(min(O.x,S.x),max(O.y,S.y));
    }
    return O+vec2(-0.25,0.25);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output=texture(iChannel1,fragCoord*IRES); vec2 SUV;
    //Key input
    if (DFBox(fragCoord-iResolution.xy+1.,vec2(1.))<0.) {
        Output.x=float(texelFetch(iChannel3,ivec2(82,1),0).x>0.);
    }
    //Quadtree
    vec2 CHRES=ceil(HRES);
    if (fragCoord.y<CHRES.y && fragCoord.x<CHRES.x) {
        //LOD 1
        Output.xy=MinMax2x2_0(floor(fragCoord)*2.+0.5,iChannelResolution[0].xy);
    }
    vec2 CHRES2=ceil(CHRES*0.5);
    if (DFBox(fragCoord-vec2(0.,CHRES.y),CHRES2)<0.) {
        //LOD 2
        Output.xy=MinMax2x2(floor(fragCoord-vec2(0.,CHRES.y))*2.+0.5,vec2(0.),CHRES);
    }
    vec2 CHRES3=ceil(CHRES2*0.5);
    if (DFBox(fragCoord-CHRES,CHRES3)<0.) {
        //LOD 3
        Output.xy=MinMax2x2(floor(fragCoord-CHRES)*2.+0.5,vec2(0.,CHRES.y),CHRES2);
    }
    vec2 CHRES4=ceil(CHRES3*0.5);
    if (DFBox(fragCoord-vec2(CHRES.x,0.),CHRES4)<0.) {
        //LOD 4
        Output.xy=MinMax2x2(floor(fragCoord-vec2(CHRES.x,0.))*2.+0.5,CHRES,CHRES3);
    }
    vec2 CHRES5=ceil(CHRES4*0.5);
    if (DFBox(fragCoord-vec2(0.,iChannelResolution[0].y-CHRES5.y),CHRES5)<0.) {
        //LOD 5
        SUV=floor(vec2(fragCoord.x,iChannelResolution[0].y-fragCoord.y))*2.+0.5;
        Output.xy=MinMax2x2(SUV,vec2(CHRES.x,0.),CHRES4);
    }   
    //Copy quadtree when it is complete
    if (mod(float(iFrame),5.)>3.5) {
        Output.zw=Output.xy;
    }
    //Return
    fragColor=Output;
}