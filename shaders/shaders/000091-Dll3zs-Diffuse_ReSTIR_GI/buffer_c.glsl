// Buffer C (buffer) — Diffuse ReSTIR GI by Mathis
// https://www.shadertoy.com/view/Dll3zs

//Temporal ReSTIR

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    //Diffuse temporal ReSTIR
    if (DFBox(fragCoord-vec2(1.),RES-2.)<0.) {
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
            //Geometry pixel
            vec3 PPos = Pos+Dir*DiffShad.x;
            vec4 CSDF; vec3 Normal = Gradient(PPos,iTime,CSDF);
            vec3 L = vec3(0.);
            //Reprojection
            vec3 CVPos = PPos-LPos;
            vec3 LVPos = vec3(dot(CVPos,LTan),dot(CVPos,LBit),dot(CVPos,LEye));
            vec2 Luv = ((LVPos.xy/LVPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
            vec2 LuvCenter = floor(Luv);
            //Find reprojection pixel
            float SmallestDistance = 1000.; vec2 LResUV,ResUV;
            for (float x = -1.; x<1.5; x++) {
                for (float y = -1.; y<1.5; y++) {
                    vec4 LRSample = texture(iChannel3,(LuvCenter+0.5+vec2(x,y))*IRES);
                    vec2 LRluv = LuvCenter+vec2(x,y)+FloatToVec2(LRSample.y);
                    vec3 LRDir = normalize(vec3((LRluv*IRES*2.-1.)*CFOV*ASPECT,1.)*LEyeMat);
                    vec3 LRPPos = LPos+LRDir*LRSample.x;
                    vec4 LRSDF; vec3 LRNormal = Gradient(LRPPos,iTime-iTimeDelta,LRSDF);
                    //Reprojection on current screen space
                    vec3 RVPos = LRPPos-Pos;
                    RVPos = vec3(dot(RVPos,Tan),dot(RVPos,Bit),dot(RVPos,Eye));
                    vec2 LRUV = ((RVPos.xy/RVPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                    float LRUVDist = length(UV*0.+fragCoord-LRUV);
                    if (LRSample.x<FAR && DFBox(LRUV-1.,RES-2.)<0. && abs(dot(Normal,LRPPos-PPos))<0.05
                        && dot(Normal,LRNormal)>0.9 && LRUVDist<SmallestDistance) {
                        SmallestDistance = LRUVDist;
                        ResUV = LRUV;
                        LResUV = LRluv;
                    }
                }
            }
            vec2 UVResidual = ResUV-floor(fragCoord);
            if (SmallestDistance>900.) {// || DFBox(UVResidual,vec2(1.))>0.) {
                //No valid reprojection on the last frame -> new pixel
                vec3 Rand3 = ARand23(fragCoord*IRES*(1.+mod(CurrentFrame*7.253,9.234)));
                Rand3.xy = (floor(Rand3.xy*2048.)+0.5)*I2048;
                Output = vec4(DiffShad.y,Vec2ToFloat(Rand3.xy),DiffShad.z,Vec2ToFloatWM(vec2(1.)));
            } else {
                //Old pixel
                vec4 LR = texture(iChannel2,LResUV*IRES);
                vec2 LRWM = FloatToVec2WM(LR.w);
                float M = LRWM.y;
                vec2 Rand2 = FloatToVec2(LR.y);
                vec3 RLight = FloatToVec3(LR.x)*LightCoeff;
                float RDist = LR.z;
                float w = max(0.,dot(RLight,vec3(0.3333)))*M*LRWM.x;
                float W = w/max(0.0001,M*dot(RLight,vec3(0.3333))); //Update W
                if (iFrame%3==0) {
                    //Sample validation
                    L = FloatToVec3(DiffShad.y)*LightCoeff;
                    if (length(RLight-L)>0.1) {
                        //Invalid sample
                        Output = vec4(Vec3ToFloat(L*ILightCoeff),LR.y,DiffShad.z,LR.w);
                    } else {
                        //Valid sample
                        Output = LR;
                    }
                } else {
                    //Temporal ReSTIR
                    vec3 Rand3 = ARand23(fragCoord*IRES*(1.+mod(CurrentFrame*7.253,9.234)));
                    Rand3.xy = (floor(Rand3.xy*2048.)+0.5)*I2048;
                    vec3 SRD = RandSample(Rand3.xy)*TBN(Normal);
                    float SampleD = DiffShad.z;
                    L = FloatToVec3(DiffShad.y)*LightCoeff;
                    float wnew = max(0.,dot(L,vec3(0.3333)))*dot(SRD,Normal); //Target pdf
                    M = min(M,M_CLAMP_T-1.); //Clamping
                    w = max(0.,dot(RLight,vec3(0.3333)))*RandSample(Rand2.xy).z*M*W+wnew; //R.w += w
                    if (Rand3.z<wnew/max(0.0001,w)) {
                        //New sample
                        RLight = L;
                        Rand2 = Rand3.xy;
                        RDist = SampleD;
                    }
                    M += 1.; //R.M += 1
                    float p_hat = max(0.,dot(RLight,vec3(0.3333)))*RandSample(Rand2.xy).z; //p hat
                    W = w/max(0.0001,M*p_hat); //Update W
                    //Output
                    Output = vec4(Vec3ToFloat(RLight*ILightCoeff),
                                  Vec2ToFloat(Rand2),
                                  RDist,
                                  Vec2ToFloatWM(vec2(W,M)));
                }
            }
        } else {
            //Sky pixel
            Output = vec4(0.,0.,0.,-1.);
        }
    }
    fragColor = Output;
}