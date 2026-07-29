// Buffer A (buffer) — Minecraft + LPV GI by Mathis
// https://www.shadertoy.com/view/ctV3WG

//Storage, primary rays and reflection ray

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
}

void UpdateMouse(inout vec4 Output, vec4 Mouse) {
    //Updates the mouse
    if (Mouse.z>0.) {
        if (Output.w==0.) {
            Output.w = 1.;
            Output.xy = Mouse.zw;
        }
    } else Output.w = 0.;
}

void UpdateEye(inout vec4 Output, vec4 CMouse, vec4 Mouse) {
    //Updates the eye vector
    if (CMouse.w==0.)  Output.zw = Output.xy;
    if (CMouse.w==1.) {
        //Y led
        Output.x = Output.z+(Mouse.y-CMouse.y)*IRES.y*5.;
        Output.x = clamp(Output.x,-2.8*0.5,2.8*0.5);
        //X led
        Output.y = Output.w-(Mouse.x-CMouse.x)*IRES.x*10.;
        Output.y = mod(Output.y,3.1415926*2.);
    }
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
    vec3 wn3 = max(vec3(0.),-N*0.75+0.22);
    return (LXP*wp3.x+LXN*wn3.x+LYP*wp3.y+LYN*wn3.y+LZP*wp3.z+LZN*wn3.z)*0.5;
}

vec3 APositions[10] = vec3[10](
    vec3(13.05,2.2,20.7),
    vec3(13.05,2.2,18.7),
    vec3(10.2,2.5,15.7),
    vec3(5.7,1.15,11.7),
    vec3(13.07,2.1,10.3),
    vec3(15.07,2.1,10.3),
    vec3(23.07,7.9,12.3),
    vec3(18.07,7.1,25.3),
    vec3(16.07,3.9,9.3),
    vec3(16.07,3.8,8.3)
);

vec2 AEyes[10] = vec2[10](
    vec2(0.15,3.),
    vec2(0.175,3.),
    vec2(-0.15,3.9),
    vec2(0.3,2.5),
    vec2(0.1,0.05),
    vec2(0.1,0.05),
    vec2(-0.04,-0.4),
    vec2(0.1,1.8),
    vec2(0.1,0.5),
    vec2(0.01,0.)
);

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = texture(iChannel0,fragCoord.xy*IRES);
    if (iFrame==0) {
        //Initialization
        if (fragCoord.x<10. && fragCoord.y<1.) { //Store vars
            if (fragCoord.x<1.) Output = vec4(0.,0.,0.,0.); //Mouse
            else if (fragCoord.x<2.) Output = vec4(0.15,3.,0.,0.); //Player Eye (Angles)
            else if (fragCoord.x<3.) Output = vec4(0.,0.,0.,1.); //Player Eye (Vector)
            else if (fragCoord.x<4.) Output = vec4(13.05,2.2,20.7,1.); //Player Pos
            else if (fragCoord.x<5.) Output = vec4(0.5,0.97,0.,0.); //Sun angles
            else if (fragCoord.x<6.) Output = vec4(0.,0.,0.,0.); //Sun direction
        }
    } else {
        //Update
		if (fragCoord.x<16. && fragCoord.y<1.) {
            //Update vars
            if (fragCoord.x<1.) { //Mouse
                UpdateMouse(Output,iMouse);
            } else if (fragCoord.x<2.) {
                //Player Eye (Angles)
                if (iTime<36.) {
                    //Cubic interpolation
                    int Index = int(floor(iTime*0.25));
                    float t = fract(iTime*0.25);
                    vec2 e0 = AEyes[max(0,Index-1)];
                    vec2 e1 = AEyes[Index];
                    vec2 e2 = AEyes[min(9,Index+1)];
                    vec2 a2 = (e1-e0)-(e2-e1);
                    vec2 b2 = -(e2-e1)+(e2-e1);
                    Output.xy = (1.-t)*e1+t*e2+t*(1.-t)*((1.-t)*a2+t*b2);
                    Output.zw = Output.xy;
                } else {
                    vec4 CMouse = texture(iChannel0,vec2(0.5,0.5)*IRES);
                    UpdateMouse(CMouse,iMouse);
                    UpdateEye(Output,CMouse,iMouse);
                }
            } else if (fragCoord.x<3.) {
                //Player Eye (Vector)
                vec4 A4;
                if (iTime<36.) {
                    //Cubic interpolation
                    int Index = int(floor(iTime*0.25));
                    float t = fract(iTime*0.25);
                    vec2 e0 = AEyes[max(0,Index-1)];
                    vec2 e1 = AEyes[Index];
                    vec2 e2 = AEyes[min(9,Index+1)];
                    vec2 a2 = (e1-e0)-(e2-e1);
                    vec2 b2 = -(e2-e1)+(e2-e1);
                    A4.xy = (1.-t)*e1+t*e2+t*(1.-t)*((1.-t)*a2+t*b2);
                } else {
                    A4 = texture(iChannel0,vec2(1.5,0.5)*IRES);
                    vec4 CMouse = texture(iChannel0,vec2(0.5,0.5)*IRES);
                    UpdateMouse(CMouse,iMouse);
                    UpdateEye(A4,CMouse,iMouse);
                }
                Output.xyz = normalize(vec3(cos(A4.x)*sin(A4.y),sin(A4.x),cos(A4.x)*cos(A4.y)));
            } else if (fragCoord.x<4.) {
                //Player Pos
                if (iTime<36.) {
                    //Cubic interpolation
                    int Index = int(floor(iTime*0.25));
                    vec3 y0 = APositions[max(0,Index-1)];
                    vec3 y1 = APositions[Index];
                    vec3 y2 = APositions[min(9,Index+1)];
                    float t = fract(iTime*0.25);
                    vec3 a = (y1-y0)-(y2-y1);
                    vec3 b = -(y2-y1)+(y2-y1);
                    Output.xyz = (1.-t)*y1+t*y2+t*(1.-t)*((1.-t)*a+t*b);
                } else {
                    float Speed = iTimeDelta;
                    if (texelFetch(iChannel1,ivec2(32,0),0).x>0.) Speed = 8.*iTimeDelta;
                    //Update eye
                    vec4 CMouse = texture(iChannel0,vec2(0.5,0.5)*IRES);
                    UpdateMouse(CMouse,iMouse);
                    vec4 Eye4 = texture(iChannel0,vec2(1.5,0.5)*IRES);
                    UpdateEye(Eye4,CMouse,iMouse);
                    vec3 Eye = normalize(vec3(cos(Eye4.x)*sin(Eye4.y),sin(Eye4.x),cos(Eye4.x)*cos(Eye4.y)));
                    vec3 Tan = normalize(cross(vec3(Eye.x,0.,Eye.z),vec3(0.,1.,0.)));
                    vec3 NEye = -Eye;
                    vec3 NTan = -Tan;
                    //Next position
                    vec3 NPos = Output.xyz;
                    if (texelFetch(iChannel1,ivec2(87,0),0).x>0.) NPos += Eye*Speed; //W
                    if (texelFetch(iChannel1,ivec2(83,0),0).x>0.) NPos += NEye*Speed; //S
                    if (texelFetch(iChannel1,ivec2(65,0),0).x>0.) NPos += NTan*Speed; //A
                    if (texelFetch(iChannel1,ivec2(68,0),0).x>0.) NPos += Tan*Speed; //D
                    Output.xyz = NPos;
                }
            } else if (fragCoord.x<5.) {
                //Sun angle
                //if (texelFetch(iChannel1,ivec2(77,0),0).x>0.) Output.y += iTimeDelta;
                //if (texelFetch(iChannel1,ivec2(78,0),0).x>0.) Output.y -= iTimeDelta;
                    //LPV uses one sample for sunlight -> flickerng
                    //So moving the sun is disabled
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
    if (DFBox(fragCoord-1.,RES-2.)<0.) {
        Output = vec4(0.);
        if (iFrame>1) {
            //G-Buffer
            float CurrentFrame = float(iFrame);
            vec2 SSOffset = ARand23(vec2(CurrentFrame*0.2673,CurrentFrame*0.1736)).xy-0.5;
            vec3 SunDir = texture(iChannel0,vec2(5.5,0.5)*IRES).xyz;
            //Compensate for 1 frame lag
            vec3 Pos = texture(iChannel0,vec2(3.5,0.5)*IRES).xyz;
            vec4 CMouse = texture(iChannel0,vec2(0.5,0.5)*IRES);
            UpdateMouse(CMouse,iMouse);
            vec4 Eye4 = texture(iChannel0,vec2(1.5,0.5)*IRES);
            UpdateEye(Eye4,CMouse,iMouse);
            vec3 Eye = normalize(vec3(cos(Eye4.x)*sin(Eye4.y),sin(Eye4.x),cos(Eye4.x)*cos(Eye4.y)));
            if (iTime<36.) {
                int Index = int(floor(iTime*0.25));
                //Cubic interpolation
                vec3 y0 = APositions[max(0,Index-1)];
                vec3 y1 = APositions[Index];
                vec3 y2 = APositions[min(9,Index+1)];
                float t = fract(iTime*0.25);
                vec3 a = (y1-y0)-(y2-y1);
                vec3 b = -(y2-y1)+(y2-y1);
                Pos = (1.-t)*y1+t*y2+t*(1.-t)*((1.-t)*a+t*b);
                vec2 e0 = AEyes[max(0,Index-1)];
                vec2 e1 = AEyes[Index];
                vec2 e2 = AEyes[min(9,Index+1)];
                vec2 a2 = (e1-e0)-(e2-e1);
                vec2 b2 = -(e2-e1)+(e2-e1);
                Eye4.xy = (1.-t)*e1+t*e2+t*(1.-t)*((1.-t)*a2+t*b2);
                Eye = normalize(vec3(cos(Eye4.x)*sin(Eye4.y),sin(Eye4.x),cos(Eye4.x)*cos(Eye4.y)));
            } else {
                float Speed = iTimeDelta;
                if (texelFetch(iChannel1,ivec2(32,0),0).x>0.) Speed = 8.*iTimeDelta;
                vec3 Tan = normalize(cross(vec3(Eye.x,0.,Eye.z),vec3(0.,1.,0.)));
                vec3 NEye = -Eye;
                vec3 NTan = -Tan;
                if (texelFetch(iChannel1,ivec2(87,0),0).x>0.) Pos += Eye*Speed; //W
                if (texelFetch(iChannel1,ivec2(83,0),0).x>0.) Pos += NEye*Speed; //S
                if (texelFetch(iChannel1,ivec2(65,0),0).x>0.) Pos += NTan*Speed; //A
                if (texelFetch(iChannel1,ivec2(68,0),0).x>0.) Pos += Tan*Speed; //D
            }
            mat3 EyeMat = TBN(Eye);
            vec3 Dir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
            //Prior frame
            vec3 PriorPos = texture(iChannel0,vec2(3.5,0.5)*IRES).xyz;
            vec3 PriorEye = texture(iChannel0,vec2(2.5,0.5)*IRES).xyz;
            vec3 PriorTan; vec3 PriorBit = TBN(PriorEye,PriorTan);
            mat3 PriorEyeMat = TBN(PriorEye);
            //Render scene
            HIT Pixel = Trace(Pos,Dir,iTime);
            if (Pixel.C.x>1.) {
                //Emissive
                Output = vec4(-2.,-2.,-2.,Pixel.C);
            } else if (Pixel.C.x>=0.) {
                //Geometry
                vec3 PPos = Pos+Dir*Pixel.D+Pixel.N*0.0001;
                Output.w = Pixel.D;
                Output.z = Vec3ToFloat(Pixel.NMN*0.5+0.5);
                
                
                
                //
                //Reflections
                //
                float RefDist = -1.;
                vec3 RefC = vec3(0.);
                vec3 CosRand = RandSampleCos(ARand23(fragCoord*IRES*(7.13+mod(CurrentFrame*7.363,13.64))).xy);
                float RefCR = 0.2*min(1.,tan((HPI-acos(dot(-Dir,Pixel.N)))));
                vec3 RandDir = normalize(CosRand*TBN(reflect(Dir,Pixel.NMN))*RefCR+reflect(Dir,Pixel.NMN));
                if (dot(Pixel.N,RandDir)<0.) RandDir = reflect(RandDir,Pixel.N);
                HIT Hit1 = Trace(PPos,RandDir,iTime);
                if (Hit1.C.x>=0.) {
                    vec3 PPos1 = PPos+RandDir*Hit1.D;
                    RefDist = Hit1.D;
                    //Direct light
                    if (dot(Hit1.N,SunDir)>0.) {
                        if (Trace(PPos1+Hit1.N*0.001,SunDir,iTime).C.x<-0.5) RefC += dot(Hit1.N,SunDir)*SunLight;
                    }
                    //Indirect light
                    RefC += IntegrateLPV(clamp(PPos1+Hit1.N*0.5,vec3(0.51),vec3(31.49)),-Hit1.N);
                    //Albedo
                    RefC *= Hit1.C;
                } else {
                    RefC = SkyLight*(RandDir.y*0.5+0.5);
                    RefDist = 100000.;
                }
                Output.x = Vec3ToFloat(RefC*ILightCoeff);
                Output.y = RefDist;
            } else {
                //Sky
                Output = vec4(Dir.y,0.,0.,-1.);
            }
        }
    }
    fragColor = Output;
}