// Buffer A (buffer) — LEGO Denoising by Mathis
// https://www.shadertoy.com/view/msG3zG

//Storage, primary rays and diffuse rays

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
}

vec4 SampleMB(vec2 uv, vec3 PPos, vec3 Normal, vec3 LPos, mat3 LEyeMat) {
    //A weighted sample for a bilinear mix
    vec4 C = texture(iChannel0,clamp(uv,vec2(0.5,1.5),RES-0.5)*IRES);
    vec3 SDir = normalize(vec3((uv*IRES*2.-1.)*(ASPECT*CFOV),1.)*LEyeMat);
    float W = max(0.0001,float(dot(Normal,LPos+SDir*C.w-PPos)<0.2)*0.+float(C.w>-0.5))*
              max(0.01,dot(Normal,normalize(FloatToVec3(C.z)*2.-1.))*5.-4.);
    return vec4(vec3(FloatToVec2(C.x)*LightCoeff,C.y)*W,W);
}

vec4 ManualBilinear(vec2 uv, vec3 PPos, vec3 Normal, vec3 LPos, mat3 LEyeMat) {
    //Returns weighted RGB sum + weight sum
    vec2 Fuv = floor(uv-0.499)+0.5;
    vec4 S0 = SampleMB(Fuv,PPos,Normal,LPos,LEyeMat);
    vec4 S1 = SampleMB(Fuv+vec2(1.,0.),PPos,Normal,LPos,LEyeMat);
    vec4 S2 = SampleMB(Fuv+vec2(0.,1.),PPos,Normal,LPos,LEyeMat);
    vec4 S3 = SampleMB(Fuv+vec2(1.),PPos,Normal,LPos,LEyeMat);
    vec2 fuv = fract(uv-0.499);
    float MixedWeight = mix(mix(S0.w,S1.w,fuv.x),mix(S2.w,S3.w,fuv.x),fuv.y);
    return vec4(mix(mix(S0.xyz,S1.xyz,fuv.x),mix(S2.xyz,S3.xyz,fuv.x),fuv.y)/MixedWeight,MixedWeight);
}

float SampleSDF(vec3 sp) {
    //Samples the volume SDF
    float SVal = (sp.y/6.4)*80.;
    vec2 UVmod = 0.5+(sp.zx/vec2(21.,8.))*vec2(252.,96.);
    vec2 UVSlice0 = vec2(min(floor(mod(SVal,4.)),3.)*253.,min(floor(SVal/4.),20.)*97.);
    vec4 TexC = textureCube(UVmod+UVSlice0);
    return mix(TexC.x,TexC.z,fract(SVal));
}


HIT Trace(vec3 P, vec3 D, float Time) {
    HIT OUT = HIT(100000.,vec3(0.),vec3(-1.),vec3(0.));
    //SDF ray tracing
    vec2 bb = ABox(P,1./D,vec3(0.),vec3(8.,6.399,21.));
    float FAR = bb.y;
    float t = 0.; float dfs = 10000.;
    if (P.y>6.399) {
        if (bb.x>0. && bb.y>bb.x) t = bb.x+0.01;
        else return OUT;
    }
    for (int i=0; i<512; i++) {
        vec3 sp = P+D*t;
        dfs = SampleSDF(sp);
        t += dfs;
        if (min(FAR-t,dfs-0.001)<0.) break;
    }
    if (dfs<0.001) {
        vec3 sp = P+D*t;
        float SVal = (sp.y/6.4)*80.+0.5;
        vec2 UVmod = 0.5+floor((sp.zx/vec2(21.,8.))*vec2(252.,96.)+0.5);
        vec2 UVSlice0 = vec2(min(floor(mod(SVal,4.)),3.)*253.,min(floor(SVal/4.),20.)*97.);
        return HIT(t,normalize(vec3(SampleSDF(sp+eps.xyy)-SampleSDF(sp-eps.xyy),
                   SampleSDF(sp+eps.yxy)-SampleSDF(sp-eps.yxy),
                   SampleSDF(sp+eps.yyx)-SampleSDF(sp-eps.yyx))),
                   BrickColorArray[int(floor(textureCube(UVmod+UVSlice0).y))],vec3(0.));
    }
    //Return
    return OUT;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = texture(iChannel0,fragCoord.xy*IRES);
    if (iFrame==0) {
        //Initialization
        if (fragCoord.x<10. && fragCoord.y<1.) { //Store vars
            if (fragCoord.x<1.) Output = vec4(0.,0.,0.,0.); //Mouse
            else if (fragCoord.x<2.) Output = vec4(-0.69,2.55,0.,0.); //Player Eye (Angles)
            else if (fragCoord.x<3.) Output = vec4(0.,0.,0.,1.); //Player Eye (Vector)
            else if (fragCoord.x<4.) Output = vec4(1.4,6.,18.9,1.); //Player Pos
            else if (fragCoord.x<5.) Output = vec4(0.75,-5.,0.,0.); //Sun angles
            else if (fragCoord.x<6.) Output = vec4(0.,0.,0.,0.); //Sun direction
        }
    } else {
        //Update
		if (fragCoord.x<16. && fragCoord.y<1.) {
            //Update vars
            if (fragCoord.x<1.) { //Mouse
                if (iMouse.z>0.) {
                    if (Output.w==0.) {
                    	Output.w = 1.;
                    	Output.xy = iMouse.zw;
                    }
                } else Output.w = 0.;
            } else if (fragCoord.x<2.) {
                //Player Eye (Angles)
                vec4 LMouse = texture(iChannel0,vec2(0.5,0.5)*IRES);
                if (LMouse.w==0.)  Output.zw = Output.xy;
                if (LMouse.w==1.) {
                	//Y led
                	Output.x = Output.z+(iMouse.y-LMouse.y)*IRES.y*5.;
                	Output.x = clamp(Output.x,-2.8*0.5,2.8*0.5);
                	//X led
                	Output.y = Output.w-(iMouse.x-LMouse.x)*IRES.x*10.;
               		Output.y = mod(Output.y,3.1415926*2.);
                }
            } else if (fragCoord.x<3.) {
                //Player Eye (Vector)
                vec3 Angles = texture(iChannel0,vec2(1.5,0.5)*IRES).xyz;
                Output.xyz = normalize(vec3(cos(Angles.x)*sin(Angles.y),
                  			   			sin(Angles.x),
                  			   			cos(Angles.x)*cos(Angles.y)));
            } else if (fragCoord.x<4.) {
                //Player Pos
                float Speed = iTimeDelta*2.;
                	if (texelFetch(iChannel1,ivec2(32,0),0).x>0.) Speed = 6.*iTimeDelta;
                vec3 Eye = texture(iChannel0,vec2(2.5,0.5)*IRES).xyz;
                vec3 Tan = normalize(cross(vec3(Eye.x,0.,Eye.z),vec3(0.,1.,0.)));
                vec3 NEye = -Eye;
                vec3 NTan = -Tan;
                //Next position
                vec3 NPos = Output.xyz;
                if (texelFetch(iChannel1,ivec2(87,0),0).x>0.) NPos += Eye*Speed; //W
                if (texelFetch(iChannel1,ivec2(83,0),0).x>0.) NPos += NEye*Speed; //S
                if (texelFetch(iChannel1,ivec2(65,0),0).x>0.) NPos += NTan*Speed; //A
                if (texelFetch(iChannel1,ivec2(68,0),0).x>0.) NPos += Tan*Speed; //D
                //SDF collisions
                if (DFBox(NPos-vec3(0.),vec3(8.,6.4,21.))<0.) {
                    float LoneSample = SampleSDF(NPos-eps.yxy);
                    if (LoneSample<0.1) {
                        vec3 SDFGradient = normalize(vec3(SampleSDF(Output.xyz+eps.xyy)-SampleSDF(Output.xyz-eps.xyy),
                                                          SampleSDF(Output.xyz+eps.yxy)-SampleSDF(Output.xyz-eps.yxy),
                                                          SampleSDF(Output.xyz+eps.yyx)-SampleSDF(Output.xyz-eps.yyx)));
                        Eye += SDFGradient*max(0.,-dot(SDFGradient,Eye));
                        Tan += SDFGradient*max(0.,-dot(SDFGradient,Tan));
                        NEye += SDFGradient*max(0.,-dot(SDFGradient,NEye));
                        NTan += SDFGradient*max(0.,-dot(SDFGradient,NTan));
                    }
                }
                if (texelFetch(iChannel1,ivec2(87,0),0).x>0.) Output.xyz += Eye*Speed; //W
                if (texelFetch(iChannel1,ivec2(83,0),0).x>0.) Output.xyz += NEye*Speed; //S
                if (texelFetch(iChannel1,ivec2(65,0),0).x>0.) Output.xyz += NTan*Speed; //A
                if (texelFetch(iChannel1,ivec2(68,0),0).x>0.) Output.xyz += Tan*Speed; //D
                //Clamping the position
                Output.xyz = clamp(Output.xyz,vec3(0.2),vec3(7.8,10.,20.8));
            } else if (fragCoord.x<5.) {
                //Sun angle
                if (texelFetch(iChannel1,ivec2(77,0),0).x>0.) Output.y += iTimeDelta*0.75;
                if (texelFetch(iChannel1,ivec2(78,0),0).x>0.) Output.y -= iTimeDelta*0.75;
                Output.z = Output.y; //Sunangle last frame
            } else if (fragCoord.x<6.) {
                //Sun direction
                vec2 Angles = texture(iChannel0,vec2(4.5,0.5)*IRES).xy;
                Output = vec4(normalize(vec3(cos(Angles.y)*cos(Angles.x)
                	,sin(Angles.x),sin(Angles.y)*cos(Angles.x))),1.);
            } else if (fragCoord.x<7.) {
                //Last frame dir
                Output = texture(iChannel0,vec2(2.5,0.5)*IRES);
            } else if (fragCoord.x<8.) {
                //Last frame position
                Output = texture(iChannel0,vec2(3.5,0.5)*IRES);
            } else if (fragCoord.x<9.) {
                //Last frame SunDir
                Output = texture(iChannel0,vec2(5.5,0.5)*IRES);
            } else if (fragCoord.x<10.) {
                //Last last frame dir
                Output = texture(iChannel0,vec2(6.5,0.5)*IRES);
            } else if (fragCoord.x<11.) {
                //Last last frame position
                Output = texture(iChannel0,vec2(7.5,0.5)*IRES);
            }
        }
    }
    //Rendering
    if (fragCoord.y>1. && iFrame>3+BuildFrames) {
        //G-Buffer
        float CurrentFrame = float(iFrame);
        vec2 SSOffset = SSOffsets[iFrame%16];
        vec3 SunDir = texture(iChannel0,vec2(5.5,0.5)*IRES).xyz;
        vec3 Pos = texture(iChannel0,vec2(3.5,0.5)*IRES).xyz;
        vec3 Eye = texture(iChannel0,vec2(2.5,0.5)*IRES).xyz;
        mat3 EyeMat = TBN(Eye);
        vec3 LPos = texture(iChannel0,vec2(7.5,0.5)*IRES).xyz;
        vec3 LEye = texture(iChannel0,vec2(6.5,0.5)*IRES).xyz;
        mat3 LEyeMat = TBN(LEye);
        vec3 LTan; vec3 LBit = TBN(LEye,LTan);
        vec3 Dir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
        //Render scene
        HIT Pixel = Trace(Pos,Dir,iTime);
        if (Pixel.C.x>=0.) {
            //Geometry
            vec3 PPos = Pos+Dir*Pixel.D;
            Output.w = Pixel.D;
            Output.z = Vec3ToFloat(Pixel.N*0.5+0.5);


            //
            //Indirect diffuse light accumulation
            //
            vec3 IDLight = vec3(0.);
            vec3 RandV = ARand23(fragCoord*IRES*(1.+mod(CurrentFrame*7.253,9.234)));
            vec3 RandDir = RandSampleCos(RandV.xy)*TBN(Pixel.N);
            HIT Sample = Trace(PPos+Pixel.N*0.01,RandDir,iTime);
            if (Sample.C.x>=0.) {
                //Geometry
                RandV = ARand23(fragCoord*IRES*(1.+mod(CurrentFrame*7.253,3.234)));
                vec3 SunRandDir = normalize(RandSampleCos(RandV.xy)*TBN(SunDir)*SunCR+SunDir);
                if (dot(Sample.N,SunRandDir)>0.)
                    IDLight += Sample.C*SunLight*(dot(Sample.N,SunRandDir)*
                               float(Trace(PPos+RandDir*Sample.D+Sample.N*0.01,SunRandDir,iTime).C.x<0.));
                #ifdef SecondBounce
                    //World space sampling
                    vec3 PPos2 = PPos+RandDir*Sample.D+Sample.N*0.01;
                    RandV.xy = clamp(ARand23(fragCoord*I1024*(1.+mod(float(iFrame)*6.63839,27.2734))).xy,vec2(0.001),vec2(0.999));
                    RandDir = RandSampleCos(RandV.xy)*TBN(Sample.N);
                    HIT Sample2 = Trace(PPos2,RandDir,iTime);
                    if (Sample2.C.x>=0.) {
                        RandV = ARand23(fragCoord*IRES*(1.+mod(CurrentFrame*8.553,13.234)));
                        SunRandDir = normalize(RandSampleCos(RandV.xy)*TBN(SunDir)*SunCR+SunDir);
                        if (dot(Sample2.N,SunRandDir)>0.)
                            IDLight += Sample.C*Sample2.C*SunLight*(dot(Sample2.N,SunRandDir)*
                                    float(Trace(PPos2+RandDir*Sample2.D+Sample2.N*0.01,SunRandDir,iTime).C.x<0.));
                    } else {
                        //Sky
                        IDLight += SampleSky(RandDir,SunDir,iTime);
                    }
                #else
                    //Screen space sampling
                    vec3 SSPos = PPos+RandDir*Sample.D-LPos;
                    SSPos = vec3(dot(SSPos,LTan),dot(SSPos,LBit),dot(SSPos,LEye));
                    vec2 Luv = ((SSPos.xy/SSPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                    if (SSPos.z>0. && DFBox(Luv-vec2(0.,1.),RES-vec2(0.,1.))<0.) {
                        vec4 SSC = texture(iChannel0,(floor(Luv)+0.5)*IRES);
                        float Weight = float(SSC.w>-0.5)*float(dot(normalize(FloatToVec3(SSC.z)*2.-1.),Sample.N)>0.8);
                        IDLight += Sample.C*vec3(FloatToVec2(SSC.x)*LightCoeff,SSC.y)*Weight;
                    }
                #endif
                
            } else {
                //Sky
                IDLight += SampleSky(RandDir,SunDir,iTime);
            }
            //Reprojection
            vec3 LVPos = PPos-LPos;
            LVPos = vec3(dot(LVPos,LTan),dot(LVPos,LBit),dot(LVPos,LEye));
            vec2 Luv = ((LVPos.xy/LVPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES-SSOffsets[(iFrame-1)%16];
            if (DFBox(Luv,RES)<0.) {
                //Inside screen -> reprojection exists
                vec4 LFrame = ManualBilinear(Luv,PPos,Pixel.N,LPos,LEyeMat);
                float Confidence = LFrame.w; //Confidence in our sample from last frame
                IDLight = (IDLight+LFrame.xyz*(23.*Confidence))/(1.+23.*Confidence);
            }
            Output.xy = vec2(Vec2ToFloat(IDLight.xy*ILightCoeff),min(IDLight.z,LightCoeff));
        } else {
            //Sky
            Output = vec4(-1.);
        }
    } else if (fragCoord.y>1.) {
        //Initial frames
        Output = vec4(0.);
    }
    fragColor = Output;
}