// Buffer A (buffer) — Diffuse ReSTIR GI by Mathis
// https://www.shadertoy.com/view/Dll3zs

//Storage + Depth + Secondary rays

vec3 Sample_L(vec3 RayP, vec3 RayD, vec3 SunDir, vec2 Rand2, out float SampleD) {
    //Returns 1 or 1+2 bounced lighting
    vec3 L = vec3(0.);
    //First bounce
    SampleD = Trace(RayP,RayD,iTime);
    if (SampleD<=FAR) {
        //Geometry hit
        vec3 SampleP = RayP+RayD*SampleD;
        vec4 SampleSDF; vec3 SampleN = Gradient(SampleP,iTime,SampleSDF);
        if (SampleSDF.x>1.) {
            //Emissive
            L += EmissiveStrength*vec3(SampleSDF.x-1.,SampleSDF.yz);
        } else {
            //Diffuse
            vec3 Rand3 = clamp(ARand23(Rand2*9.234),vec3(0.0001,0.0001,0.),vec3(0.9999,0.9999,1.));
            vec3 RandDir = normalize(RandSampleCos(Rand3.xy)*TBN(SunDir)*SunCR+SunDir);
            if (dot(SampleN,RandDir)>0.) {
                if (Trace(SampleP+SampleN*0.001,RandDir,iTime)>FAR) L += SunLight*SampleSDF.xyz*max(0.,dot(SampleN,RandDir));
            }
            //Second bounce
            vec3 RayD2 = RandSample(Rand3.xy)*TBN(SampleN);
            float SampleD2 = Trace(SampleP+SampleN*0.001,RayD2,iTime);
            if (SampleD2<=FAR) {
                //Geometry hit
                vec3 SampleP2 = SampleP+SampleN*0.001+RayD2*SampleD2;
                vec4 SampleSDF2; vec3 SampleN2 = Gradient(SampleP2,iTime,SampleSDF2);
                if (SampleSDF2.x>1.) L += EmissiveStrength*SampleSDF.xyz*vec3(SampleSDF2.x-1.,SampleSDF2.yz);
                else {
                    //Diffuse
                    Rand3 = clamp(ARand23(Rand2*3.234),vec3(0.0001,0.0001,0.),vec3(0.9999,0.9999,1.));
                    RandDir = normalize(RandSampleCos(Rand3.xy)*TBN(SunDir)*SunCR+SunDir);
                    if (dot(SampleN2,RandDir)>0.) {
                        if (Trace(SampleP2+SampleN2*0.001,RandDir,iTime)>FAR)
                            L += SunLight*SampleSDF.xyz*SampleSDF2.xyz*max(0.,dot(SampleN2,RandDir));
                    }
                }
            } else {
                //Sky hit
                L += SampleSky(RayD2,iTime)*SampleSDF.xyz;
            }
        }
    } else {
        //Sky hit
        L += SampleSky(RayD,iTime);
    }
    return L;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = texture(iChannel0,fragCoord.xy*IRES);
    if (iFrame==0) { //Initialization
        if (fragCoord.x<10. && fragCoord.y<1.) { //Store vars
            if (fragCoord.x<1.) Output = vec4(0.,0.,0.,0.); //Mouse
            else if (fragCoord.x<2.) Output = vec4(0.,-0.7,0.,0.); //Player Eye (Angles)
            else if (fragCoord.x<3.) Output = vec4(0.,0.,0.,1.); //Player Eye (Vector)
            else if (fragCoord.x<4.) Output = vec4(5.5,1.7,0.5,1.); //Player Pos
            else if (fragCoord.x<5.) Output = vec4(0.4,-2.15,0.,0.); //Sun angles
            else if (fragCoord.x<6.) Output = vec4(0.,0.,0.,0.); //Sun direction
        }
    } else { //Update
		if (fragCoord.x<16. && fragCoord.y<1.) { //Update vars
            if (fragCoord.x<1.) { //Mouse
                if (iMouse.z>0.) { //Börjat klicka
                    if (Output.w==0.) {
                    	Output.w = 1.;
                    	Output.xy = iMouse.zw;
                    }
                } else Output.w = 0.;
            } else if (fragCoord.x<2.) { //Player Eye (Angles)
                vec4 LMouse = texture(iChannel0,vec2(0.5,0.5)*IRES);
                if (LMouse.w==0.)  Output.zw = Output.xy;
                if (LMouse.w==1.) {
                	//Y led
                	Output.x = Output.z+(iMouse.y-LMouse.y)*0.01;
                	Output.x = clamp(Output.x,-2.8*0.5,2.8*0.5);
                	//X led
                	Output.y = Output.w-(iMouse.x-LMouse.x)*0.02;
               		Output.y = mod(Output.y,3.1415926*2.);
                }
            } else if (fragCoord.x<3.) { //Player Eye (Vector)
                vec3 Angles = texture(iChannel0,vec2(1.5,0.5)*IRES).xyz;
                Output.xyz = normalize(vec3(cos(Angles.x)*sin(Angles.y),
                  			   			sin(Angles.x),
                  			   			cos(Angles.x)*cos(Angles.y)));
            } else if (fragCoord.x<4.) { //Player Pos
                float Speed = iTimeDelta;
                	if (texelFetch(iChannel1,ivec2(32,0),0).x>0.) Speed = 5.*iTimeDelta;
                vec3 Eye = texture(iChannel0,vec2(2.5,0.5)*IRES).xyz;
                if (texelFetch(iChannel1,ivec2(87,0),0).x>0.) Output.xyz += Eye*Speed; //W
                if (texelFetch(iChannel1,ivec2(83,0),0).x>0.) Output.xyz -= Eye*Speed; //S
                vec3 Tan = normalize(cross(vec3(Eye.x,0.,Eye.z),vec3(0.,1.,0.)));
                if (texelFetch(iChannel1,ivec2(65,0),0).x>0.) Output.xyz -= Tan*Speed; //A
                if (texelFetch(iChannel1,ivec2(68,0),0).x>0.) Output.xyz += Tan*Speed; //D
            } else if (fragCoord.x<5.) { //Sun angle
                if (texelFetch(iChannel1,ivec2(77,0),0).x>0.) Output.y += iTimeDelta*1.5;
                if (texelFetch(iChannel1,ivec2(78,0),0).x>0.) Output.y -= iTimeDelta*1.5;
                Output.z = Output.y; //Sunangle last frame
            } else if (fragCoord.x<6.) { //Sun direction
                vec2 Angles = texture(iChannel0,vec2(4.5,0.5)*IRES).xy;
                Output = vec4(normalize(vec3(cos(Angles.y)*cos(Angles.x)
                	,sin(Angles.x),sin(Angles.y)*cos(Angles.x))),1.);
            } else if (fragCoord.x<7.) { //Last frame dir
                Output = texture(iChannel0,vec2(2.5,0.5)*IRES);
            } else if (fragCoord.x<8.) { //Last frame position
                Output = texture(iChannel0,vec2(3.5,0.5)*IRES);
            } else if (fragCoord.x<9.) { //Last frame SunDir
                Output = texture(iChannel0,vec2(5.5,0.5)*IRES);
            } else if (fragCoord.x<10.) { //Last last frame dir
                Output = texture(iChannel0,vec2(6.5,0.5)*IRES);
            } else if (fragCoord.x<11.) { //Last last frame position
                Output = texture(iChannel0,vec2(7.5,0.5)*IRES);
            }
        } else if (DFBox(fragCoord-vec2(1.),RES-2.)<0.) {
            vec2 SSOffset = SSOffsets[iFrame%16];
            float CurrentFrame = float(iFrame);
            vec2 UV = fragCoord+SSOffset;
            vec3 SunDir = texture(iChannel0,vec2(5.5,0.5)*IRES).xyz;
            vec3 Pos = texture(iChannel0,vec2(3.5,0.5)*IRES).xyz;
            vec3 Eye = texture(iChannel0,vec2(2.5,0.5)*IRES).xyz;
            vec3 Tan; vec3 Bit = TBN(Eye,Tan);
            vec3 LPos = texture(iChannel0,vec2(7.5,0.5)*IRES).xyz;
            vec3 LEye = texture(iChannel0,vec2(6.5,0.5)*IRES).xyz;
            vec3 LTan; vec3 LBit = TBN(LEye,LTan);
            mat3 LEyeMat = TBN(LEye);
            vec3 Dir = normalize(vec3((UV*IRES*2.-1.)*CFOV*ASPECT,1.)*TBN(Eye));
            float PixelD = Trace(Pos,Dir,iTime);
            if (PixelD<=FAR) {
                //Geometry
                vec3 PPos = Pos+Dir*PixelD;
                vec4 PixelSDF; vec3 Normal = Gradient(PPos,iTime,PixelSDF);
                
                
                
                
                //
                //Diffuse ray
                //
                vec3 RandV = ARand23(fragCoord*IRES*(1.+mod(CurrentFrame*7.253,9.234)));
                RandV.xy = (floor(RandV.xy*2048.)+0.5)*I2048;
                vec2 ShadowRandV = RandV.xy;
                float DiffuseDist;
                vec3 DPPos = PPos+Normal*0.001;
                vec3 DNormal = Normal;
                if (iFrame%3==0) {
                    //Re-trace ray
                    vec3 CVPos = PPos-LPos;
                    vec3 LVPos = vec3(dot(CVPos,LTan),dot(CVPos,LBit),dot(CVPos,LEye));
                    vec2 LuvCenter = floor(((LVPos.xy/LVPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES);
                    float SmallestDistance = 1000.; vec2 LResUV = vec2(-1.);
                    vec3 RayStartPos = vec3(-1.); vec3 RayNormal = vec3(-1.);
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
                            float LRUVDist = length(fragCoord-LRUV);
                            if (LRSample.x<FAR && DFBox(LRUV-1.,RES-2.)<0. && abs(dot(Normal,LRPPos-PPos))<0.05
                                && dot(Normal,LRNormal)>0.9 && LRUVDist<SmallestDistance) {
                                SmallestDistance = LRUVDist;
                                LResUV = LRluv;
                                RayStartPos = LRPPos+LRNormal*0.001;
                                RayNormal = LRNormal;
                            }
                        }
                    }
                    if (DFBox(LResUV-1.,RES-2.)<0.) {
                        //Reprojection coordinate is outside of the last frame screen
                        DPPos = RayStartPos;
                        RandV.xy = FloatToVec2(texture(iChannel2,LResUV*IRES).y);
                        DNormal = RayNormal;
                    }
                }
                
                
                vec3 RandDir = RandSample(RandV.xy)*TBN(DNormal);
                vec3 DiffuseLight = Sample_L(DPPos,RandDir,SunDir,RandV.xy,DiffuseDist);
                
                
                
                
                //
                //Shadow ray
                //
                RandDir = normalize(RandSampleCos(ShadowRandV)*TBN(SunDir)*SunCR+SunDir);
                float ShadowDist = -1.;
                if (dot(Normal,RandDir)>0.) ShadowDist = Trace(DPPos,RandDir,iTime);
                //Output
                Output = vec4(PixelD,Vec3ToFloat(DiffuseLight*ILightCoeff),DiffuseDist,ShadowDist);
            } else {
                //Sky
                Output = vec4(FAR+10.,-1.,-1.,-1.);
            }
        }
    }
    fragColor = Output;
}