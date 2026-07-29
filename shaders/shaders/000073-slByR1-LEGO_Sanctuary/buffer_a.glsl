// Buffer A (buffer) — LEGO Sanctuary by Mathis
// https://www.shadertoy.com/view/slByR1

//Rendering

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign=-mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D=vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D=D.xzy;
    else if (UV.y>2048.) D=D.zxy;
    return texture(iChannel3,D);
}

HIT TraceOctree(vec3 P, vec3 D) {
    //Traces a ray through the lego octree
    int Index; float Rotation,Material; float I=0.; vec2 rr,CD,IsoUV; vec3 Color,PosOffset; vec4 DFHit,IsoT;
    //Check intersection
    vec3 IDir=1./D;
    vec2 NearFar=ABox(P,IDir,vec3(0.),vec3(128.,51.2,128.));
    float FAR=NearFar.y;
    float t=0.; 
    if ((NearFar.x>0. && NearFar.y>NearFar.x) || DFBox(P,vec3(128.,51.2,128.))<0.) {
        //The ray intersects the octree
        t=max(0.,NearFar.x+0.001);
    } else {
        //Misses the octree
        return HIT(10000.,vec3(0.),vec3(0.),vec3(0.),0.);
    }
    float LFar=FAR; vec2 CUV; vec3 cp,fp; vec2 bb; vec4 C;
    float LOD=6.;
    vec3 LS=vec3(1.,0.4,1.)*pow(2.,LOD);
    vec3 ILS=vec3(1.,2.5,1.)*pow(0.5,LOD);
    float PS=2.;
    float YOffset=2364.;
    for (int i=0; i<128; i++) {
        if (t>FAR) break;
        if (t>LFar && LOD<6.) {
            LOD=LOD+1.;
            YOffset+=PS;
            LS*=2.;
            ILS*=0.5;
            PS*=0.5;
            fp=floor(cp*ILS)*LS;
            LFar=ABoxfar(P,IDir,fp,fp+LS);
        }
        cp=P+D*t;
        fp=floor(cp*ILS)*LS;
        if (LOD==0.) {
            CUV=vec2(fp.x*ILS.x+128.*mod(floor(fp.y*ILS.y),8.)+0.5,fp.z*ILS.z+128.*floor(fp.y*ILS.y*0.125)+0.5);
        } else if (LOD==1.) {
            CUV=vec2(fp.x*ILS.x+64.*mod(floor(fp.y*ILS.y),16.)+0.5,fp.z*ILS.z+64.*floor(fp.y*ILS.y*I16)+2048.5);
        } else {
            CUV=vec2(fp.x*ILS.x+PS*floor(fp.y*ILS.y)+0.5,fp.z*ILS.z+0.5+YOffset);
        }
        C=textureCube(CUV);
        bb=ABox(P,IDir,fp,fp+LS);
        if (C.x>0. && ((bb.x>=0. && bb.y>bb.x) || DFBox(cp-fp,fp+LS)<=0.)) {
            if (LOD==0.) {
                /*
                //Voxel visualisation
                vec3 bbN; bb=ABoxN(P,IDir,fp,fp+LS,sign(D),bbN);
                return HIT(bb.x,P+D*bb.x,bbN,vec3(C.y,0.,0.),floor(C.x*0.01));
                //*/
                PosOffset=floor(vec3(fract(C.z*0.1)*10.,floor(C.z*0.1),fract(C.w*0.1)*10.)+0.001)*vec3(1.,0.4,1.);
                Index=int(floor(C.w*0.1));
                Material=floor(C.x*0.01);
                Rotation=floor(mod((C.x-Material)*0.1,10.));
                vec3 HitP=P+D*bb.x;
                vec3 BO3=BrickOffset3[Index];
                if (Rotation>0.5) {
                    IsoUV=(vec2(dot(IsoTan,HitP.zyx+PosOffset-fp.zyx-BO3),dot(IsoBit,HitP+PosOffset-fp-BO3))*Sqrt2*0.5+0.5)*128.;
                    IsoT=textureCube(IsoUV+BrickOffset2[Index]+vec2(0.,2370.)).zyxw;
                } else {
                    IsoUV=(vec2(dot(IsoTan,HitP+PosOffset-fp-BO3),dot(IsoBit,HitP+PosOffset-fp-BO3))*Sqrt2*0.5+0.5)*128.;
                    IsoT=textureCube(IsoUV+BrickOffset2[Index]+vec2(0.,2370.));
                }
                float IsoD=IsoT.w+dot(D,fp-PosOffset-IsoCenter+BO3);
                if (IsoD<bb.y) {
                    return HIT(IsoD,P+D*IsoD,IsoT.xyz,vec3(C.y,0.,0.),Material);
                }
            } else if (LOD>0.) {
                LFar=bb.y;
                LOD-=1.;
                YOffset-=PS*2.;
                LS*=0.5;
                ILS*=2.;
                PS*=2.;
                continue;
            }
        }
        t=bb.y+0.0025;
        I++;
    }
    //Return
    return HIT(10000.,vec3(0.),vec3(0.),vec3(0.),float(I)*0.04);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output=texture(iChannel0,fragCoord*IRES)*float(iFrame>InitialFrames);
    //Camera
    vec2 AAOffset=textureCube(mod(vec2(floor(float(iFrame)*0.2)+0.5,0.5),vec2(1024.))+vec2(0.,5120.)).yx-0.5;
    vec2 PixelUV=(fragCoord+AAOffset-HRES)*IRES.x*2.*IsoWidth;
    vec3 Pos=IsoPos+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
    //Trace
    HIT Pixel=TraceOctree(Pos,IsoDir);
    //Seperate bricks
    vec4 SepHit=TraceDoor(Pos-vec3(52.,6.4,64.),IsoDir,100.); //Yellow door
    if (SepHit.w<9999. && SepHit.w<Pixel.D) { Pixel=HIT(SepHit.w,vec3(0.),SepHit.xyz,vec3(199.,0.,0.),0.); }
    SepHit=TraceDoorRot(Pos-vec3(60.,14.4,67.),IsoDir,100.); //Orange door
    if (SepHit.w<9999. && SepHit.w<Pixel.D) { Pixel=HIT(SepHit.w,vec3(0.),SepHit.xyz,vec3(139.,0.,0.),0.); }
    SepHit=TraceWindow(Pos-vec3(66.,9.2,60.),IsoDir,100.); //Black window
    if (SepHit.w<9999. && SepHit.w<Pixel.D) { Pixel=HIT(SepHit.w,vec3(0.),SepHit.xyz,vec3(444.,0.,0.),0.); }
    //Output
    Output=vec4(Pixel.C.x+1000.*Pixel.M,(Pixel.N.x*0.5+0.5)*0.9+floor((Pixel.N.y*0.5+0.5)*1000.),Pixel.N.z,Pixel.D);
    fragColor=Output;
}