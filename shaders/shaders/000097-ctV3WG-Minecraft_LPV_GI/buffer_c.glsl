// Buffer C (buffer) — Minecraft + LPV GI by Mathis
// https://www.shadertoy.com/view/ctV3WG

//Denoising pass 2 + Composition

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
}

HIT Trace(vec3 P, vec3 D, float Time) {
    //Traces a ray through the quad tree
    HIT OUT = HIT(100000.,vec3(0.),vec3(0.),vec3(-1.));
    vec3 IDir = 1./D;
    float bbDF = DFBox(P,vec3(32.));
    vec2 bb = ABox(P,IDir,vec3(0.0001),vec3(31.9999));
    if (bbDF>0. && (bb.x<0. || bb.y<bb.x)) return OUT;
    float FAR = bb.y;
    float t = ((bbDF<0.)?0.:bb.x+0.001);
    float LFar = FAR; vec3 cp; vec4 C;
    float LOD = 0.;
    float LS = 1.;
    float ILS = 1.;
    vec4 Albedo; vec3 Normal,NTan,NBit; vec2 AUV,AUVOff;
    vec3 fp = floor((P+D*t)*ILS)*LS;
    for (int i=0; i<256; i++) {
        if (t>FAR) break;
        cp = P+D*t;
        C = textureCube(vec2(fp.x+fp.y*32.+0.5,fp.z+0.5));
        if (C.x<-0.5) {
        } else if (C.x>50.) {
            bb = ABox(P,IDir,fp,fp+1.);
            if (bb.x>=0. && bb.y>bb.x) return HIT(bb.x,vec3(0.),vec3(0.),vec3(2.));
        } else if (C.x<8.5) {
            if (C.x<5.5 || C.x>50.) bb = ABox(P,IDir,fp,fp+1.);
            else if (C.x<8.5) bb = ABox(P,IDir,fp+vec3(0.5-I16,0.,0.),fp+vec3(0.5+I16,1.,1.));
            if (bb.x>=0. && bb.y>bb.x) {
                if (C.x<5.5) Normal = ABoxNormal(P,IDir,fp,fp+1.);
                else if (C.x<8.5) Normal = ABoxNormal(P,IDir,fp+vec3(0.5-I16,0.,0.),fp+vec3(0.5+I16,1.,1.));
                vec3 PPos = P+D*bb.x;
                vec3 AN = abs(Normal);
                if (max(AN.x,AN.z)>AN.y) {
                    NBit = vec3(0.,1.,0.);
                    if (AN.x>AN.z) NTan = vec3(0.,0.,1.);
                    else NTan = vec3(1.,0.,0.);
                } else {
                    NTan = vec3(1.,0.,0.);
                    NBit = vec3(0.,0.,1.);
                }
                vec2 aUV = vec2(dot(PPos-fp,NTan),dot(PPos-fp,NBit));
                vec3 AlbedoSample = fp+0.5;
                AUV = clamp(floor(aUV*16.)+0.5,vec2(0.5),vec2(15.5));
                AUVOff = vec2(16.*textureCube(vec2(AlbedoSample.x+floor(AlbedoSample.y)*32.,AlbedoSample.z)).x,256.);
                Albedo = textureCube(AUV+AUVOff);
                if (C.x>50.) Albedo = vec4(2.);
                if (Albedo.w>0.1) {
                    //Non-transparent pixel
                    vec3 NMN = normalize(
                            dot(textureCube(clamp(AUV+vec2(1.,0.),vec2(0.5),vec2(15.5))+AUVOff).xyz-
                                textureCube(clamp(AUV-vec2(1.,0.),vec2(0.5),vec2(15.5))+AUVOff).xyz,vec3(0.1))*NTan+
                            dot(textureCube(clamp(AUV+vec2(0.,1.),vec2(0.5),vec2(15.5))+AUVOff).xyz-
                                textureCube(clamp(AUV-vec2(0.,1.),vec2(0.5),vec2(15.5))+AUVOff).xyz,vec3(0.1))*NBit+
                            Normal);
                    OUT =  HIT(bb.x,Normal,NMN,Albedo.xyz);
                    break;
                }
            }
        } else {
            //First plane
            float t0 = -dot(P.xz-fp.xz-0.5,vec2(0.707))/dot(D.xz,vec2(0.707));
            if (t0>0. && abs(dot(P.xz-fp.xz-0.5+D.xz*t0,vec2(-0.707,0.707)))<0.5 && abs(P.y-fp.y-0.5+D.y*t0)<0.5) {
                vec3 PPos = P+D*t0;
                Normal = vec3(0.70710678,0.,0.70710678);
                Normal *= (max(0.,sign(dot(Normal.xz,-D.xz)))*2.-1.);
                NTan = vec3(Normal.z,0.,-Normal.x);
                NBit = vec3(0.,1.,0.);
                vec2 aUV = vec2(dot(PPos-fp-0.5,NTan)+0.5,PPos.y-fp.y);
                vec3 AlbedoSample = fp+0.5;
                AUV = clamp(floor(aUV*16.)+0.5,vec2(0.5),vec2(15.5));
                AUVOff = vec2(16.*textureCube(vec2(AlbedoSample.x+floor(AlbedoSample.y)*32.,AlbedoSample.z)).x,256.);
                Albedo = textureCube(AUV+AUVOff);
                if (Albedo.w>0.1) {
                    //Non-transparent pixel
                    vec3 NMN = normalize(
                            dot(textureCube(clamp(AUV+vec2(1.,0.),vec2(0.5),vec2(15.5))+AUVOff).xyz-
                                textureCube(clamp(AUV-vec2(1.,0.),vec2(0.5),vec2(15.5))+AUVOff).xyz,vec3(0.1))*NTan+
                            dot(textureCube(clamp(AUV+vec2(0.,1.),vec2(0.5),vec2(15.5))+AUVOff).xyz-
                                textureCube(clamp(AUV-vec2(0.,1.),vec2(0.5),vec2(15.5))+AUVOff).xyz,vec3(0.1))*NBit+
                            Normal);
                    OUT =  HIT(t0,Normal,NMN,Albedo.xyz);
                }
            }
            //Second plane
            t0 = -dot(P.xz-fp.xz-0.5,vec2(-0.707,0.707))/dot(D.xz,vec2(-0.707,0.707));
            if (t0>0. && abs(dot(P.xz-fp.xz-0.5+D.xz*t0,vec2(0.707)))<0.5 &&
                abs(P.y-fp.y-0.5+D.y*t0)<0.5 && (OUT.C.x<-0.5 || t0<OUT.D)) {
                vec3 PPos = P+D*t0;
                Normal = vec3(-0.70710678,0.,0.70710678);
                Normal *= (max(0.,sign(dot(Normal.xz,-D.xz)))*2.-1.);
                NTan = vec3(Normal.z,0.,-Normal.x);
                NBit = vec3(0.,1.,0.);
                vec2 aUV = vec2(dot(PPos-fp-0.5,NTan)+0.5,PPos.y-fp.y);
                vec3 AlbedoSample = fp+0.5;
                AUV = clamp(floor(aUV*16.)+0.5,vec2(0.5),vec2(15.5));
                AUVOff = vec2(16.*textureCube(vec2(AlbedoSample.x+floor(AlbedoSample.y)*32.,AlbedoSample.z)).x,256.);
                Albedo = textureCube(AUV+AUVOff);
                if (Albedo.w>0.1) {
                    //Non-transparent pixel
                    vec3 NMN = normalize(
                            dot(textureCube(clamp(AUV+vec2(1.,0.),vec2(0.5),vec2(15.5))+AUVOff).xyz-
                                textureCube(clamp(AUV-vec2(1.,0.),vec2(0.5),vec2(15.5))+AUVOff).xyz,vec3(0.1))*NTan+
                            dot(textureCube(clamp(AUV+vec2(0.,1.),vec2(0.5),vec2(15.5))+AUVOff).xyz-
                                textureCube(clamp(AUV-vec2(0.,1.),vec2(0.5),vec2(15.5))+AUVOff).xyz,vec3(0.1))*NBit+
                            Normal);
                    OUT =  HIT(t0,Normal,NMN,Albedo.xyz);
                }
            }
            if (OUT.C.x>-0.5) break;
        }
        fp += ABoxfarNormal(P,IDir,fp,fp+LS,t)*LS;
    }
    //Return
    return  OUT;
}

vec3 WeightedLPVSample(vec2 InputUV, float YFrac, float[8] OW) {
    vec3 OUT = vec3(0.);
    float XFrac = fract(InputUV.x);
    float ZFrac = fract(InputUV.y);
    vec2 UV = floor(InputUV)+0.5;
    vec4 C0 = textureCube(UV)*OW[0];
    vec4 C1 = textureCube(UV+vec2(1.,0.))*OW[1];
    vec4 C2 = textureCube(UV+vec2(0.,1.))*OW[4];
    vec4 C3 = textureCube(UV+vec2(1.,1.))*OW[5];
    vec4 CYLow = mix(mix(C0*C0.w,C1*C1.w,XFrac),mix(C2*C2.w,C3*C3.w,XFrac),ZFrac)/
                 (0.05+mix(mix(C0.w,C1.w,XFrac),mix(C2.w,C3.w,XFrac),ZFrac));
    C0 = textureCube(UV+vec2(32.,0.))*OW[2];
    C1 = textureCube(UV+vec2(33.,0.))*OW[3];
    C2 = textureCube(UV+vec2(32.,1.))*OW[6];
    C3 = textureCube(UV+vec2(33.,1.))*OW[7];
    vec4 CYHigh = mix(mix(C0*C0.w,C1*C1.w,XFrac),mix(C2*C2.w,C3*C3.w,XFrac),ZFrac)/
                 (0.05+mix(mix(C0.w,C1.w,XFrac),mix(C2.w,C3.w,XFrac),ZFrac));
    return mix(CYLow.xyz*CYLow.w,CYHigh.xyz*CYHigh.w,YFrac)/(0.05+mix(CYLow.w,CYHigh.w,YFrac));
}

vec3 IntegrateLPV(vec3 P, vec3 N) {
    //Samples the LPV
    vec2 lpvUV = vec2(P.x-0.5+floor(P.y-0.5)*32.,P.z+64.-0.5);
    float YFrac = fract(P.y-0.5);
    //Init weights
    ivec3 FP = ivec3(floor(fract(P-0.5)*2.)); 
    vec3 Diag3 = vec3(1-FP)*2.-1.;
    float OW[8] = float[8](0.,0.,0.,0.,0.,0.,0.,0.);
    OW[FP.x+FP.y*2+FP.z*4] = 1.; //Current voxel
    OW[(FP.x+1)%2+FP.y*2+FP.z*4] = 1.; //Side in X
    OW[FP.x+((FP.y+1)%2)*2+FP.z*4] = 1.; //Side in Y
    OW[FP.x+FP.y*2+((FP.z+1)%2)*4] = 1.; //Side in Z
    //Occlusion check
    vec2 FUV = vec2(floor(P.x)+floor(P.y)*32.+0.5,floor(P.z)+64.5);
    float WallX = textureCube(vec2(FUV.x+Diag3.x,FUV.y)).w;
    float WallY = textureCube(vec2(FUV.x+32.*Diag3.y,FUV.y)).w;
    float WallZ = textureCube(vec2(FUV.x,FUV.y+Diag3.z)).w;
    OW[FP.x+((FP.y+1)%2)*2+((FP.z+1)%2)*4] = max(WallY,WallZ);
    OW[((FP.x+1)%2)+((FP.y+1)%2)*2+FP.z*4] = max(WallX,WallY);
    OW[((FP.x+1)%2)+FP.y*2+((FP.z+1)%2)*4] = max(WallX,WallZ);
    OW[((FP.x+1)%2)+((FP.y+1)%2)*2+((FP.z+1)%2)*4] = max(max(WallX,WallY),WallZ);
    //Sample LPV
    vec3 LXP = WeightedLPVSample(lpvUV,YFrac,OW);
    vec3 LXN = WeightedLPVSample(lpvUV+vec2(0.,32.),YFrac,OW);
    vec3 LYP = WeightedLPVSample(lpvUV+vec2(0.,64.),YFrac,OW);
    vec3 LYN = WeightedLPVSample(lpvUV+vec2(0.,96.),YFrac,OW);
    vec3 LZP = WeightedLPVSample(lpvUV+vec2(0.,128.),YFrac,OW);
    vec3 LZN = WeightedLPVSample(lpvUV+vec2(0.,160.),YFrac,OW);
    //Interpolation
    vec3 wp3 = max(vec3(0.),N*0.75+0.25);
    vec3 wn3 = max(vec3(0.),-N*0.75+0.25);
    return (LXP*wp3.x+LXN*wn3.x+LYP*wp3.y+LYN*wn3.y+LZP*wp3.z+LZN*wn3.z)*0.5;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(-1.);
    if (iFrame>1 && DFBox(fragCoord-1.,RES-2.)<0.) {
        //G-Buffer
        float CurrentFrame = float(iFrame);
        vec2 SSOffset = ARand23(vec2(CurrentFrame*0.2673,CurrentFrame*0.1736)).xy-0.5;
        vec3 SunDir = texture(iChannel0,vec2(5.5,0.5)*IRES).xyz;
        vec3 Pos = texture(iChannel0,vec2(3.5,0.5)*IRES).xyz;
        vec3 Eye = texture(iChannel0,vec2(2.5,0.5)*IRES).xyz;
        vec3 Tan; vec3 Bit = TBN(Eye,Tan);
        mat3 EyeMat = TBN(Eye);
        vec3 Dir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
        //Sample attributes
        vec4 CAttr = texture(iChannel0,fragCoord*IRES);
        if (CAttr.z<-0.5) {
            //Emissive
            Output = vec4(2.5,1.5,1.5,1.);
        } else if (CAttr.w>-0.5) {
            //Geometry
            HIT Pixel = Trace(Pos+Dir*(CAttr.w-0.01),Dir,iTime);
            vec3 Normal = normalize(FloatToVec3(CAttr.z)*2.-1.);
            float Dist = CAttr.w;
            vec3 PPos = Pos+Dir*Dist+Normal*0.0005;
            vec4 RefDiff = texture(iChannel1,fragCoord*IRES);
            
            
            
            //
            //Reflections denoising
            //
            vec4 RefC = vec4(texture(iChannel1,fragCoord*IRES).xyz*2.,2.);
            vec3 RefDir = reflect(Dir,Normal);
            float RefCR = 0.2*min(1.,tan((HPI-acos(dot(RefDir,Normal)))));
            vec3 CVPos0 = vec3(CAttr.y*RefCR,0.,CAttr.y+CAttr.w)*TBN(Dir);
            vec3 CVPos1 = vec3(-CAttr.y*RefCR,0.,CAttr.y+CAttr.w)*TBN(Dir);
            vec3 LVPos0 = vec3(dot(CVPos0,Tan),dot(CVPos0,Bit),dot(CVPos0,Eye));
            vec3 LVPos1 = vec3(dot(CVPos1,Tan),dot(CVPos1,Bit),dot(CVPos1,Eye));
            vec2 Luv0 = ((LVPos0.xy/LVPos0.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
            vec2 Luv1 = ((LVPos1.xy/LVPos1.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
            float HalfRadius = min(8.,length(Luv0-Luv1)*0.5)*0.5;
            for (float x=-2.; x<2.5; x+=1.) {
                for (float y=-2.; y<2.5; y+=1.) {
                    if (x==0. && y==0.) continue;
                    vec2 Offset2 = normalize(vec2(x,y))*max(abs(x),abs(y))*HalfRadius;
                    vec2 SUV = floor(fragCoord+Offset2)+0.5;
                    vec4 SC = texture(iChannel0,SUV*IRES);
                    vec3 SNormal = normalize(FloatToVec3(SC.z)*2.-1.);
                    vec3 SDir = normalize(vec3(((SUV+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
                    if (min(SC.w,SC.z)<-0.5 || DFBox(SUV-vec2(0.,1.),RES-vec2(0.,1.))>0.) continue;
                    vec2 SRand = ARand23(SUV*IRES*(1.+mod(CurrentFrame*7.253,9.234))).xy;
                    vec3 SRefDir = reflect(SDir,SNormal);
                    float SCR = 0.2*min(1.,tan((HPI-acos(dot(RefDir,Normal)))));
                    vec3 SRDir = normalize(RandSampleCos(SRand)*TBN(SRefDir)*SCR+SRefDir);
                    vec3 HitP = Pos+SDir*SC.w+SNormal*0.0001+SRDir*SC.y;
                    if (dot(HitP-PPos,Normal)<=0.) continue;
                    if (sqrt(1./dot(normalize(HitP-PPos),RefDir)-1.)<=RefCR) RefC += vec4(texture(iChannel1,SUV*IRES).xyz,1.);
                }
            }
            vec3 ReflectionLight = RefC.xyz/RefC.w;
            
            
            
            //
            //Direct light
            //
            vec3 DiffuseLight = vec3(0.);
            if (dot(Normal,SunDir)>0.) {
                if (Trace(PPos,SunDir,iTime).C.x<0.) DiffuseLight += SunLight*dot(Normal,SunDir);
            }
            
            
            
            
            //
            //Indirect light denoising
            //
            DiffuseLight += IntegrateLPV(clamp(PPos+Normal*0.5,vec3(0.51),vec3(31.49)),-Normal);
            /*
            //1spp path tracer for fun
                //Could use ReSTIR here, since LPV reduces noise significantly
                //But TAA in cubemap has its limitations
            vec3 CosRand = RandSampleCos(ARand23(fragCoord*IRES*(7.13+mod(CurrentFrame*7.363,13.64))).xy);
            vec3 RandDir = normalize(CosRand*TBN(Normal));
            HIT Hit1 = Trace(PPos,RandDir,iTime);
            if (Hit1.C.x<-1.5) {
                DiffuseLight += vec3(2.5,1.5,1.5);
            } else if (Hit1.C.x>=0.) {
                //Geometry
                vec3 PPos1 = PPos+RandDir*Hit1.D+Hit1.N*0.0001;
                //Sunlight
                CosRand = RandSampleCos(ARand23(fragCoord*IRES*(3.13+mod(CurrentFrame*6.763,13.64))).xy);
                RandDir = SunDir;
                if (dot(Hit1.N,SunDir)>0.) {
                    if (dot(Hit1.N,RandDir)<0.) RandDir = reflect(RandDir,Hit1.N);
                    if (Trace(PPos1,RandDir,iTime).C.x<0.) DiffuseLight += SunLight*dot(Hit1.N,SunDir);
                }
                //LPV cache
                DiffuseLight += IntegrateLPV(clamp(PPos1+Hit1.N*0.5,vec3(0.51),vec3(31.49)),-Hit1.N);
                //Albedo
                DiffuseLight *= Hit1.C;
            } else {
                //Sky
                DiffuseLight += SkyLight*2.*max(0.,RandDir.y);
            }
            //*/
            
            
            //Albedo
            DiffuseLight *= Pixel.C;
            
            
            
            //
            //Composition
            //
            Output.xyz = mix(DiffuseLight,ReflectionLight,SchlickFresnel(vec3(0.2),max(0.,dot(-Dir,Normal))));
        } else {
            Output = vec4(SampleSky(Dir,iTime),-1.);
        }
    }
    fragColor = Output;
}