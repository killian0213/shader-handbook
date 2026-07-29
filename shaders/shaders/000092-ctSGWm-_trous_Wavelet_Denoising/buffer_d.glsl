// Buffer D (buffer) — Àtrous Wavelet Denoising by Mathis
// https://www.shadertoy.com/view/ctSGWm

//Normals + Temporal accumulation + Composition

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    if (DFBox(fragCoord-3.,RES-6.)<0.) {
        //
        //PRIOR FRAME: normals
        //
        vec2 SSOffset = SSOffsets[(iFrame)%16];
        float CurrentTime = iTime;
        vec3 Pos = Position(iMouse,CurrentTime,IRES);
        vec3 Eye = normalize(CameraCenter(iMouse,iTime)-Pos);
        vec3 VDir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*CFOV*ASPECT,1.));
        mat3 EyeMat = TBN(Eye);
        vec3 Dir = VDir*EyeMat;
        //Compute normal
        vec3 PixelVP = VDir*texture(iChannel2,fragCoord*IRES).w;
        vec3 Tan = vec3(0.,0.,0.);
        vec3 Bit = vec3(0.,0.,0.);
        vec2 XD = vec2(texture(iChannel2,(fragCoord+vec2(1.,0.))*IRES).w,texture(iChannel2,(fragCoord+vec2(-1.,0.))*IRES).w);
        vec3 XP0 = normalize(vec3(((fragCoord+vec2(1.,0.)+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.))*XD.x;
        vec3 XP1 = normalize(vec3(((fragCoord-vec2(1.,0.)+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.))*XD.y;
        if (XD.x>-0.5) Tan = XP0-PixelVP;
        if (XD.y>-0.5 && (XD.x<-0.5 || length(Tan)>length(XP1-PixelVP))) Tan = XP1-PixelVP;
        vec2 YD = vec2(texture(iChannel2,(fragCoord+vec2(0.,1.))*IRES).w,texture(iChannel2,(fragCoord+vec2(0.,-1.))*IRES).w);
        vec3 YP0 = normalize(vec3(((fragCoord+vec2(0.,1.)+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.))*YD.x;
        vec3 YP1 = normalize(vec3(((fragCoord-vec2(0.,1.)+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.))*YD.y;
        if (YD.x>-0.5) Bit = YP0-PixelVP;
        if (YD.y>-0.5 && (YD.x<-0.5 || length(Bit)>length(YP1-PixelVP))) Bit = YP1-PixelVP;
        vec3 Normal = normalize(cross(Bit,Tan))*EyeMat;
        Normal *= sign(dot(Normal,-Dir));
        Output.w = Vec3ToFloat(Normal*0.5+0.5);
        
        
        
        
        //
        //CURRENT FRAME: Temporal accumulation + TAA + Composition
        //
        float CurrentFrame = float(iFrame-1);
        SSOffset = SSOffsets[(iFrame-1)%16];
        CurrentTime = texture(iChannel1,vec2(0.5,0.5)*IRES).y;
        vec4 CurrentMouse = texture(iChannel1,vec2(2.5,0.5)*IRES);
        Pos = Position(CurrentMouse,CurrentTime,IRES);
        Eye = normalize(CameraCenter(CurrentMouse,CurrentTime)-Pos);
        Bit = TBN(Eye,Tan);
        EyeMat = TBN(Eye);
        Dir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*CFOV*ASPECT,1.)*EyeMat);
        float Distance = texture(iChannel1,fragCoord*IRES).w;
        if (Distance>-0.5) {
            //Geometry
            HIT Pixel = Trace(Pos+Dir*(Distance-0.01),Dir,CurrentTime); //Get attributes
            vec3 Normal = normalize(FloatToVec3(texture(iChannel3,fragCoord*IRES).w)*2.-1.);
            vec3 PPos = Pos+Dir*Distance;
            vec4 RefShad = texture(iChannel0,fragCoord*IRES);
            //Denoisers
            if (Pixel.M>2.5) {
                //Emissive
                vec3 WindowLight = SampleWindow(Pos,Dir,Pixel.M);
                Output.xyz = vec3(Vec2ToFloat(WindowLight.xy*IReflConst),Vec2ToFloat(vec2(WindowLight.z*IReflConst,0.)),0.);
            } else if (Pixel.M<1.) {
                //Non-emissive material
                vec3 BCRef = texture(iChannel2,fragCoord*IRES).xyz;
                vec3 ReflectionLight = vec3(FloatToVec2(BCRef.x)*ReflConst,BCRef.y);
                float Shadow = BCRef.z;
                vec3 FinalColor = vec3(0.);
                //Reprojection
                float PriorTime = texture(iChannel1,vec2(0.5,0.5)*IRES).z;
                vec4 PriorMouse = texture(iChannel1,vec2(3.5,0.5)*IRES);
                vec3 PriorPos = Position(PriorMouse,PriorTime,IRES);
                vec3 PriorEye = normalize(CameraCenter(PriorMouse,PriorTime)-PriorPos);
                vec3 PriorTan; vec3 PriorBit = TBN(PriorEye,PriorTan);
                vec3 PriorVPos = vec3(dot(PPos-PriorPos,PriorTan),dot(PPos-PriorPos,PriorBit),dot(PPos-PriorPos,PriorEye));
                vec2 PriorUV = ((PriorVPos.xy/PriorVPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                if (DFBox(PriorUV-3.,RES-6.)<0.) {
                    //
                    //Reflections
                    //
                    vec3 LReflectionLight = FloatToVec3(texture(iChannel3,PriorUV*IRES).z)*ReflConst;
                    //Clamping
                    vec3 RMIN = vec3(1000.);
                    vec3 RMAX = vec3(0.);
                    for (float x=-1.; x<1.5; x+=1.) {
                        for (float y=-1.; y<1.5; y+=1.) {
                            BCRef.xy = texture(iChannel2,(fragCoord+vec2(x,y))*IRES).xy;
                            vec3 Sample = vec3(FloatToVec2(BCRef.x)*ReflConst,BCRef.y);
                            RMIN = min(RMIN,Sample);
                            RMAX = max(RMAX,Sample);
                        }
                    }
                    LReflectionLight = clamp(LReflectionLight,RMIN,RMAX);
                    //Output
                    ReflectionLight = (ReflectionLight+LReflectionLight*15.)/16.;
                    
                    
                    
                    
                    //
                    //Shadows
                    //
                    float LShadow = FloatToVec2(texture(iChannel3,PriorUV*IRES).y).y;
                    //Clamping
                    float SMIN = 1000.;
                    float SMAX = 0.;
                    for (float x=-1.; x<1.5; x+=1.) {
                        for (float y=-1.; y<1.5; y+=1.) {
                            BCRef.x = texture(iChannel2,(fragCoord+vec2(x,y))*IRES).z;
                            SMIN = min(SMIN,BCRef.x);
                            SMAX = max(SMAX,BCRef.x);
                        }
                    }
                    LShadow = clamp(LShadow,SMIN,SMAX);
                    //Output
                    Shadow = (Shadow+LShadow*15.)/16.;
                }
                
                
                
                
                //
                //Indirect diffuse
                //
                vec3 IndirectDiffuse = vec3(0.);
                if (!(PPos.y<0.001 && Normal.y>0.99)) {
                    IndirectDiffuse += vec3(0.2,0.1,0.04)*1.5*
                            (SolidAngle(PPos,Normal,vec3(4.,0.,2.),vec3(4.,0.,1.),vec3(2.,0.,2.))+
                            SolidAngle(PPos,Normal,vec3(1.8,0.,1.),vec3(0.,0.,1.2),vec3(0.,0.,4.))+
                            SolidAngle(PPos,Normal,vec3(2.,0.,4.),vec3(0.,0.,1.2),vec3(0.,0.,4.))
                            );
                }
                if (!(PPos.z>3.999 && Normal.z<-0.99)) {
                    IndirectDiffuse += vec3(1.,0.2,0.2)*0.7*
                            (SolidAngle(PPos,Normal,vec3(1.,0.,4.),vec3(0.,0.,4.),vec3(1.,1.5,4.)));
                }
                IndirectDiffuse /= (2.*PI);
                
                
                
                
                //
                //Composition
                //
                vec3 DiffuseLight = SunLight*Shadow*max(0.,dot(SunDir,Normal));
                DiffuseLight = max(vec3(0.),DiffuseLight)*Pixel.DC+IndirectDiffuse*Pixel.DC;
                vec3 FresnelTerm = SchlickFresnel(vec3(Pixel.Specular),dot(Normal,-Dir));
                FinalColor = DiffuseLight*(1.-Pixel.Metal)+Pixel.Metal*mix(DiffuseLight,ReflectionLight,FresnelTerm);
                
                
                
                
                //
                //Output
                //
                Output.xyz = vec3(Vec2ToFloat(FinalColor.xy*IReflConst),
                                  Vec2ToFloat(vec2(FinalColor.z*IReflConst,Shadow)),
                                  Vec3ToFloat(ReflectionLight*IReflConst));
            }
        } else {
            //Sky
            Output.xyz = vec3(0.);
            Output.xyz = vec3(Vec2ToFloat(Output.xy*IReflConst),
                                  Vec2ToFloat(vec2(Output.z*IReflConst,0.)),0.);
        }
    }
    fragColor = Output;
}