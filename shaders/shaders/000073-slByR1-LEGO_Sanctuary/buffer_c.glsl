// Buffer C (buffer) — LEGO Sanctuary by Mathis
// https://www.shadertoy.com/view/slByR1

//Accumulation

float Spotlight(vec3 P, vec3 N, vec3 LPos, vec3 LDir, float LCosAngle) {
    float Len=length(P-LPos);
    return max(0.,(dot(P-LPos,LDir)/Len-LCosAngle)/(1.-LCosAngle))*max(0.,dot(N,LPos-P)/Len);;
}

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign=-mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D=vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D=D.xzy;
    else if (UV.y>2048.) D=D.zxy;
    return texture(iChannel3,D);
}

vec4 ScreenSpaceRay(vec3 P, vec3 D, float FAR) {
    //Traces a ray
    vec4 Output=vec4(0.,0.,0.,10000.);
    vec3 IsoP=P-IsoPos;
    IsoP=vec3(dot(IsoP,IsoTan),dot(IsoP,IsoBit),dot(IsoP,IsoDir));
    vec3 IsoD=vec3(dot(D,IsoTan),dot(D,IsoBit),dot(D,IsoDir));
    //Quadtree ray tracing
    float t=0.; float LFar=FAR; vec3 IID=1./IsoD; vec2 IID2=IID.xy; vec2 CHRES=ceil(HRES); vec2 fp,bb,bb2,suv; vec3 sp; vec4 S;
    vec2 QUVOffsets[6]=vec2[6](vec2(0.),vec2(0,CHRES.y),CHRES,vec2(CHRES.x,0.),
                      vec2(0.,iChannelResolution[0].y),vec2(CHRES.x,iChannelResolution[0].y));
    int LOD=5; float fLOD=float(LOD);
    float Lod2=pow(2.,fLOD);
    float Lod05=1./Lod2;
    vec2 LodSize=IsoWidth*2.*Lod2*IRES.xx;
    vec2 ILodSize=1./LodSize;
    for (int i=0; i<256; i++) {
        if (t>FAR) break;
        if (t>LFar && LOD<5) {
            LOD+=1;
            LodSize*=2.;
            ILodSize*=0.5;
            Lod2*=2.;
            Lod05*=0.5;
            fp.xy=floor(sp.xy*ILodSize)*LodSize;
            LFar=ABoxfar(IsoP.xy,IID2,fp,fp+LodSize);
        }
        sp=IsoP+IsoD*t;
        fp=floor(sp.xy*ILodSize)*LodSize;
        suv=(((fp.xy+LodSize*0.5)*vec2(1.,Aspect.x)/IsoWidth)*0.5+0.5)*Lod05;
        if (LOD==0) {
            S=texture(iChannel0,suv);
            bb=ABox(IsoP,IID,vec3(fp,S.w),vec3(fp+LodSize,S.w+0.2));
        } else if (LOD<5) {
            S=texture(iChannel1,suv+QUVOffsets[LOD-1]*IRES);
            bb=ABox(IsoP,IID,vec3(fp,S.z),vec3(fp+LodSize,S.w));
        } else {
            S=texture(iChannel1,vec2(suv.x,-suv.y)+QUVOffsets[LOD-1]*IRES);
            bb=ABox(IsoP,IID,vec3(fp,S.z),vec3(fp+LodSize,S.w));
        }
        bb2=ABox(IsoP.xy,IID2,fp,fp+LodSize);
        if (bb.x>0. && bb.y>bb.x) {
            if (LOD==0) {
                vec3 SN=normalize(vec3(fract(S.y)*I09*2.-1.,floor(S.y)*0.001*2.-1.,S.z));
                Output=vec4(texture(iChannel2,suv).xyz*max(float(S.x>999.5),max(0.,sign(dot(SN,-D)))*float(S.w<9000.)),bb.x);
                break;
            } else {
                LFar=bb2.y;
                LOD-=1;
                LodSize*=0.5;
                ILodSize*=2.;
                Lod2*=0.5;
                Lod05*=2.;
                continue;
            }
        } else if (DFBox(sp-vec3(fp.xy,S.z),vec3(LodSize,S.w-S.z))<=0. && LOD>0) {
            LFar=bb2.y;
            LOD-=1;
            LodSize*=0.5;
            ILodSize*=2.;
            Lod2*=0.5;
            Lod05*=2.;
            continue;
        }
        t=bb2.y+0.0025;
    }
    //Black geometry
    vec3 ID=1./D;
    bb=ABox(P,ID,vec3(75.,6.4,60.),vec3(76.,50.,76.));
    if (bb.x>0. && bb.y>bb.x && bb.x<Output.w) {
        if (dot(P.yz+D.yz*bb.x-vec2(15.6,76.),vec2(-0.707))>0. &&
            dot(P.yz+D.yz*bb.x-vec2(15.6,60.),vec2(0.707,-0.707))<0.) return vec4(0.,0.,0.,bb.x);
    }
    bb=ABox(P,ID,vec3(48.,6.4,75.),vec3(76.,14.4,76.));
    if (bb.x>0. && bb.y>bb.x && bb.x<Output.w) { return vec4(0.,0.,0.,bb.x); }
    bb=ABox(P,ID,vec3(60.,14.4,60.),vec3(76.,14.41,76.));
    if (bb.x>0. && bb.y>bb.x && bb.x<Output.w) { return vec4(0.,0.,0.,bb.x); }
    vec3 tmps=vec3(0.,-0.707,-0.707);
    if (dot(tmps,D)<0.) {
        bb.x=-dot(tmps,P-vec3(60.,15.6,77.2))/dot(tmps,D);
        if (bb.x<Output.w && DFBox(P.xz+D.xz*bb.x-vec2(60.5,69.),vec2(15.,8.))<0.) { return vec4(0.,0.,0.,bb.x); }
    }
    //Return
    if (Output.w>9999.) {
        //Sky
        return vec4(SampleSky(D)*float(D.y>=0. || DFBox(P.xz-D.xz*P.y/D.y,vec2(128.))>0.),10000.);
    } else {
        //Geometry
        return Output;
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output=texture(iChannel2,fragCoord*IRES)*float(iFrame>InitialFrames);
    vec4 Attr=texture(iChannel0,fragCoord*IRES);
    vec3 N=normalize(vec3(fract(Attr.y)*I09*2.-1.,floor(Attr.y)*0.001*2.-1.,Attr.z));
    float Mat=float(Attr.x>999.5);
    vec3 NLight=vec3(0.);
    if (Attr.w<9999.) {
        if (Mat>0.5) {
            //Emissive
            Attr.x=mod(Attr.x,1000.);
            vec3 AC=vec3(fract(Attr.x*0.1),0.,floor(Attr.x*0.01)*0.1);
            AC.y=fract(Attr.x*0.01-AC.z*10.);
            NLight=AC*3.;
        } else {
            //Brick
            vec2 PixelUV=(fragCoord-HRES)*IRES.x*2.*IsoWidth;
            vec3 PPos=IsoPos+IsoTan*PixelUV.x+IsoBit*PixelUV.y+IsoDir*Attr.w;
            vec2 RUV=vec2(mod(fragCoord+Output.w*vec2(55.,35.),vec2(1024.))+vec2(0.,5120.)); vec3 RDir;
            vec4 BNValues=textureCube(RUV);
            //Diffuse integration
            RDir=RandSample(BNValues.xy)*TBN(N);
            NLight+=ScreenSpaceRay(PPos+N*0.05,RDir,10000.).xyz;
            //Spotlights
            if (DFBox(PPos-vec3(60.,0.,59.),vec3(16.,14.,1.1))<0.) {
                //Pixel is potentially not shadowed
                NLight+=vec3(1.,0.5,0.25)*Spotlight(PPos,N,vec3(62.5,6.4,58.5),SPOT_DIR,0.8)*8.;
                NLight+=vec3(1.,0.5,0.25)*Spotlight(PPos,N,vec3(73.5,6.4,58.5),SPOT_DIR,0.8)*8.;
            }
            //Color
            #ifndef CLAY
                Attr.x=mod(Attr.x,1000.);
                vec3 AC=vec3(fract(Attr.x*0.1),0.,floor(Attr.x*0.01)*0.1);
                AC.y=fract(Attr.x*0.01-AC.z*10.);
                NLight*=min(vec3(1.),AC*I09);
            #endif
            //Glossy integration
            vec3 RefDir=reflect(IsoDir,N);
            RDir=normalize(RandSample(BNValues.xz)*TBN(RefDir)*0.04+RefDir);
            NLight=mix(NLight,ScreenSpaceRay(PPos+N*0.05,RDir,10000.).xyz,Schlick(0.2,-dot(IsoDir,N)));
        }
    }
    //Accumulation
    NLight=clamp(NLight,vec3(0.),vec3(C_MAX));
    if (texelFetch(iChannel1,ivec2(iResolution.xy-1.),0).x>0.) {
        //Reset
        Output=vec4(NLight,1.);
    } else if (iFrame>15) {
        //Accumulation
        Output=vec4((Output.xyz*Output.w+NLight)/(Output.w+1.),Output.w+1.);
    }
    //Return
    fragColor=Output;
}