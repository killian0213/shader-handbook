// Buffer D (buffer) — Diffuse ReSTIR GI by Mathis
// https://www.shadertoy.com/view/Dll3zs

//Spatial ReSTIR + Shadow denoising + Copy reservoir positions

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    if (DFBox(fragCoord-vec2(1.),RES-2.)<0.) {
        //
        //Copy positions
        //
        Output.xy = texture(iChannel1,fragCoord*IRES).xy;
        float CurrentFrame = float(iFrame);
        vec2 SSOffset = SSOffsets[iFrame%16];
        vec2 UV = fragCoord+SSOffset;
        vec3 SunDir = texture(iChannel0,vec2(8.5,0.5)*IRES).xyz;
        vec3 Pos = texture(iChannel0,vec2(7.5,0.5)*IRES).xyz;
        vec3 Eye = texture(iChannel0,vec2(6.5,0.5)*IRES).xyz;
        vec3 Tan; vec3 Bit = TBN(Eye,Tan);
        mat3 EyeMat = TBN(Eye);
        vec3 LPos = texture(iChannel0,vec2(10.5,0.5)*IRES).xyz;
        vec3 LEye = texture(iChannel0,vec2(9.5,0.5)*IRES).xyz;
        vec3 LTan; vec3 LBit = TBN(LEye,LTan);
        mat3 LEyeMat = TBN(LEye);
        vec3 Dir = normalize(vec3((UV*IRES*2.-1.)*CFOV*ASPECT,1.)*EyeMat);
        vec4 DiffShad = texture(iChannel0,UV*IRES);
        if (DiffShad.x<=FAR) {
            //
            //ReSTIR spatial
            //
            vec3 PPos = Pos+Dir*DiffShad.x;
            vec4 CSDF; vec3 Normal = Gradient(PPos,iTime,CSDF);
            vec4 CR = texture(iChannel2,fragCoord*IRES);
            vec2 CRWM = FloatToVec2WM(CR.w);
            float W = CRWM.x;
            float M = CRWM.y;
            vec3 CRLight = FloatToVec3(CR.x)*LightCoeff;
            float CRRandFloat = CR.y;
            float w = max(0.,dot(CRLight,vec3(0.3333)))*M*W*RandSample(FloatToVec2(CRRandFloat)).z;
            vec3 Rand3 = ARand23(fragCoord*(1.+mod(iTime*18.327,13.9347)));
            int NSamples = 9;
            float SpatialRadius = 1.+Rand3.x //*(RES.x*0.1)
                                  *clamp((2./DiffShad.x)*RES.x*0.1,1.,RES.x*0.1);
            float AngleDelta = 6.28318530718/float(NSamples);
            float CAngle = Rand3.y*AngleDelta;
            float Jacobian,wnew,np_hat; vec2 SUV; vec3 SDir,SPos,SNormal,SRayHit,HitNormal; vec4 SDiffShad,SR,SSDF;
            for (int s=0; s<NSamples; s++) {
                //For all spatial reservoirs
                CAngle += AngleDelta;
                SUV = floor(fragCoord+vec2(sin(CAngle),cos(CAngle))*SpatialRadius)+0.5;
                if (DFBox(SUV-1.,RES-2.)>=0.) continue;
                SDiffShad = texture(iChannel0,SUV*IRES);
                if (SDiffShad.x>FAR) continue; //Sky pixel test
                SDir = normalize(vec3(((SUV-0.5+FloatToVec2(texture(iChannel1,SUV*IRES).y))*IRES*2.-1.)*CFOV*ASPECT,1.)*TBN(Eye));;
                SPos = Pos+SDir*SDiffShad.x;
                SNormal = Gradient(SPos,iTime,SSDF);
                if (!(dot(SNormal,Normal)>0.9 && abs(dot(SPos-PPos,Normal))<0.05)) continue; //Geometric similarity test
                SR = texture(iChannel2,SUV*IRES);
                vec3 SRandDir = (RandSample(FloatToVec2(SR.y))*TBN(SNormal));
                SRayHit = SPos+SR.z*SRandDir;
                HitNormal = Gradient(SRayHit,iTime,SSDF);
                if ((SR.z<FAR && dot(PPos-SRayHit,HitNormal)<=0.) || dot(SRayHit-PPos,Normal)<=0.) continue; //Hemisphere test
                
                //Exact visibility
                    //if (abs(Trace(PPos+Normal*0.001,normalize(SRayHit-PPos),iTime)-length(SRayHit-PPos))>0.05) continue;
                //Screen space ray tracing to approximate visibility
                    bool Visible = true;
                    float SSNSamples = 10.;
                    vec3 SSRayDir = normalize(SRayHit-PPos);
                    for (float di=ARand21(SUV)*0.8+0.1; di<SSNSamples; di++) {
                        //For each sample
                        vec3 SSP = PPos+SSRayDir*(di*0.1);
                        vec3 SSVPos = SSP-Pos;
                        SSVPos = vec3(dot(SSVPos,Tan),dot(SSVPos,Bit),dot(SSVPos,Eye));
                        vec2 SSUV = ((SSVPos.xy/SSVPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                        if (DFBox(SSUV-1.,RES-2.)>0.) break;
                        float SSDepth = texture(iChannel0,SSUV*IRES).x;
                        if (SSDepth+0.02<length(SSVPos)) { Visible = false; break; }
                    }
                    if (!Visible) continue;
                
                //Read reservoir
                vec2 SWM = FloatToVec2WM(SR.w);
                vec3 SRLight = FloatToVec3(SR.x)*LightCoeff;
                //Jacobian
                Jacobian = abs(dot(PPos-SRayHit,HitNormal)*pow(SR.z,3.))/
                           max(0.0001,abs(dot(SPos-SRayHit,HitNormal)*pow(length(PPos-SRayHit),3.)));
                if (SR.z>FAR) Jacobian = 1.; //Sky sample
                np_hat = max(0.,dot(SRLight,vec3(0.3333)));
                wnew = np_hat*SWM.y*SWM.x*RandSample(FloatToVec2(SR.y)).z*max(0.0001,Jacobian);
                w += wnew;
                M += SWM.y;
                float RandV = ARand21(SUV+mod(float(iFrame+s),2048.)*vec2(3.683,4.887));
                if (RandV<wnew/max(0.0001,w)) {
                    CRLight = SRLight;
                    CRRandFloat = SR.y;
                }
            }
            //Bias correction
            float bias_p_hat = max(0.,dot(CRLight,vec3(0.3333)))*RandSample(FloatToVec2(CRRandFloat)).z;
            W = w/max(0.0001,M*bias_p_hat);
            vec3 IndirectDiffuse = CRLight*W*RandSample(FloatToVec2(CRRandFloat)).z;




            //
            //Shadow denoising pass 2
            //
            vec4 RefShad = texture(iChannel0,fragCoord*IRES);
            vec2 CShadow = vec2(0.);
            if (RefShad.w>-0.5) {
                //Surface is pointing towards SunDir
                vec3 CVPos0 = vec3(RefShad.w*SunCR,0.,RefShad.x+RefShad.w)*TBN(Dir);
                vec3 CVPos1 = vec3(-RefShad.w*SunCR,0.,RefShad.x+RefShad.w)*TBN(Dir);
                vec3 LVPos0 = vec3(dot(CVPos0,Tan),dot(CVPos0,Bit),dot(CVPos0,Eye));
                vec3 LVPos1 = vec3(dot(CVPos1,Tan),dot(CVPos1,Bit),dot(CVPos1,Eye));
                vec2 Luv0 = ((LVPos0.xy/LVPos0.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                vec2 Luv1 = ((LVPos1.xy/LVPos1.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                float MaxRadius = min(8.,length(Luv0-Luv1)*0.5); vec4 ssdf;
                CShadow = vec2(texture(iChannel1,fragCoord*IRES).z*2.,2.);
                for (float x=-2.; x<2.5; x+=1.) {
                    for (float y=-2.; y<2.5; y+=1.) {
                        if (x==0. && y==0.) continue;
                        vec2 Offset2 = normalize(vec2(x,y))*max(abs(x),abs(y))*(MaxRadius*0.5);
                        vec2 SUV = floor(fragCoord+Offset2)+0.5;
                        vec4 SRefShad = texture(iChannel0,SUV*IRES);
                        float SDistance = SRefShad.x;
                        vec3 SDir = normalize(vec3(((SUV+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
                        if (DFBox(SUV-1.,RES-2.)>0. || SDistance>FAR || SRefShad.w<-0.5 ||
                            abs(dot(Pos+SDir*SDistance-PPos,Normal))>0.05 ||
                            dot(Gradient(Pos+SDir*SDistance,iTime,ssdf),Normal)<0.9) continue;
                        vec2 SRand = ARand23(SUV*IRES*(1.+mod(CurrentFrame*7.253,9.234))).xy;
                        vec3 HitP = Pos+SDir*SDistance+normalize(RandSampleCos(SRand.xy)*TBN(SunDir)*SunCR+SunDir)*SRefShad.w;
                        if (dot(HitP-PPos,Normal)<=0.) continue;
                        if (sqrt(1./dot(normalize(HitP-PPos),SunDir)-1.)<=SunCR) {
                            CShadow += vec2(texture(iChannel1,SUV*IRES).z,1.);
                        }
                    }
                }
                CShadow.x = CShadow.x/CShadow.y;
            }




            //
            //Composition
            //
            vec3 FinalColor = IndirectDiffuse+CShadow.x*SunLight*max(0.,dot(Normal,SunDir));
            FinalColor *= CSDF.xyz;
            Output.zw = vec2(Vec2ToFloat(FinalColor.xy*0.2),FinalColor.z);
        } else {
            //Sky
            vec3 FinalColor = SampleSky(Dir,iTime);
            Output.zw = vec2(Vec2ToFloat(FinalColor.xy*0.2),FinalColor.z);
        }
    }
    fragColor = Output;
}