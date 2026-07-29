// Buffer B (buffer) — Diffuse ReSTIR GI by Mathis
// https://www.shadertoy.com/view/Dll3zs

//Reprojection of the reservoir positions + Shadow denoising

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    if (DFBox(fragCoord-vec2(1.),RES-2.)<0.) {
        vec4 RefShad = texture(iChannel0,fragCoord*IRES);
        if (RefShad.x<=FAR) {
            //
            //Normal
            //
            vec2 SSOffset = SSOffsets[iFrame%16];
            float CurrentFrame = float(iFrame);
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
            vec3 PPos = Pos+Dir*RefShad.x;
            vec4 PSDF; vec3 Normal = Gradient(PPos,iTime,PSDF);
            Output.w = Vec3ToFloat(Normal*0.5+0.5);
            
            
            
            
            //
            //Reservoir position
            //
            vec3 CVPos = PPos-LPos;
            vec3 LVPos = vec3(dot(CVPos,LTan),dot(CVPos,LBit),dot(CVPos,LEye));
            vec2 Luv = ((LVPos.xy/LVPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
            vec2 LuvCenter = floor(Luv);
            float SmallestDistance = 1000.; float WSDist; vec2 ResUV;
            for (float x = -1.; x<1.5; x++) {
                for (float y = -1.; y<1.5; y++) {
                    vec4 LRSample = texture(iChannel3,(LuvCenter+0.5+vec2(x,y))*IRES);
                    vec2 LRluv = LuvCenter+vec2(x,y)+FloatToVec2(LRSample.y);
                    vec3 LRDir = normalize(vec3((LRluv*IRES*2.-1.)*CFOV*ASPECT,1.)*LEyeMat);
                    vec3 LRPPos = LPos+LRDir*LRSample.x;
                    vec4 LRSDF; vec3 LRNormal = Gradient(LRPPos,iTime,LRSDF);
                    //Reprojection on current screen space
                    vec3 RVPos = LRPPos-Pos;
                    RVPos = vec3(dot(RVPos,Tan),dot(RVPos,Bit),dot(RVPos,Eye));
                    vec2 LRUV = ((RVPos.xy/RVPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                    float LRUVDist = length(UV*0.+fragCoord-LRUV);
                    if (LRSample.x<FAR && DFBox(LRUV-1.,RES-2.)<0. && abs(dot(Normal,LRPPos-PPos))<0.05
                        && dot(Normal,LRNormal)>0.9 && LRUVDist<SmallestDistance) {
                        SmallestDistance = LRUVDist;
                        WSDist = length(LRPPos-Pos);
                        ResUV = LRUV;
                    }
                }
            }
            vec2 UVResidual = ResUV-floor(fragCoord);
            if (DFBox(UVResidual,vec2(1.))<=0.) {
                //Inside current pixel -> keep position
                Output.xy = vec2(WSDist,Vec2ToFloat(UVResidual));
            } else {
                //Outside current pixel -> new positions
                Output.xy = vec2(RefShad.x,Vec2ToFloat(SSOffset+0.5));
            }
            
            
            

            //
            //Shadow denoising pass 1
            //
            if (RefShad.w>-0.5) {
                //Surface is pointing towards SunDir
                vec3 CVPos0 = vec3(RefShad.w*SunCR,0.,RefShad.x+RefShad.w)*TBN(Dir);
                vec3 CVPos1 = vec3(-RefShad.w*SunCR,0.,RefShad.x+RefShad.w)*TBN(Dir);
                vec3 LVPos0 = vec3(dot(CVPos0,Tan),dot(CVPos0,Bit),dot(CVPos0,Eye));
                vec3 LVPos1 = vec3(dot(CVPos1,Tan),dot(CVPos1,Bit),dot(CVPos1,Eye));
                vec2 Luv0 = ((LVPos0.xy/LVPos0.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                vec2 Luv1 = ((LVPos1.xy/LVPos1.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                float MaxRadius = min(32.,length(Luv0-Luv1)*0.5); vec4 ssdf;
                vec2 CShadow = vec2(float(RefShad.w>FAR)*2.,2.);
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
                            CShadow += vec2(float(SRefShad.w>FAR),1.);
                        }
                    }
                }
                Output.z = CShadow.x/CShadow.y;
            } else Output.z = -1.;
        } else Output = vec4(FAR+10.,-1.,-1.,-1.);
    }
    //Output
    fragColor = Output;
}