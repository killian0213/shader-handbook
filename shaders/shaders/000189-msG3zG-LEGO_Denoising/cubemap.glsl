// Cube A (cubemap) — LEGO Denoising by Mathis
// https://www.shadertoy.com/view/msG3zG

//SDF volume and TAA

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
}

vec4 sampleLevel0(vec2 PriorUV) {
    float YOffset = 2048.+floor(PriorUV.x*I1024)*1024.+floor(PriorUV.y*I1024)*2048.;
    return textureCube(mod(PriorUV,1024.)+vec2(0.,YOffset));
}

void MIN(inout vec2 Out, vec2 In) {
    Out = ((Out.x<In.x)?Out:In);
}

vec4 SampleTextureCatmullRom(vec2 uv) {
    vec2 samplePos = uv;
    vec2 texPos1 = floor(samplePos - 0.5) + 0.5;
    vec2 f = samplePos - texPos1;
    vec2 w0 = f * ( -0.5 + f * (1.0 - 0.5*f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5*f);
    vec2 w2 = f * ( 0.5 + f * (2.0 - 1.5*f) );
    vec2 w3 = f * f * (-0.5 + 0.5 * f);
    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / w12;
    vec2 texPos0 = texPos1 - vec2(1.0);
    vec2 texPos3 = texPos1 + vec2(2.0);
    vec2 texPos12 = texPos1 + offset12;
    vec4 result = vec4(0.);
    result += sampleLevel0( vec2(texPos0.x,  texPos0.y)) * w0.x * w0.y;
    result += sampleLevel0( vec2(texPos12.x, texPos0.y)) * w12.x * w0.y;
    result += sampleLevel0( vec2(texPos3.x,  texPos0.y)) * w3.x * w0.y;
    result += sampleLevel0( vec2(texPos0.x,  texPos12.y)) * w0.x * w12.y;
    result += sampleLevel0( vec2(texPos12.x, texPos12.y)) * w12.x * w12.y;
    result += sampleLevel0( vec2(texPos3.x,  texPos12.y)) * w3.x * w12.y;
    result += sampleLevel0( vec2(texPos0.x,  texPos3.y)) * w0.x * w3.y;
    result += sampleLevel0( vec2(texPos12.x, texPos3.y)) * w12.x * w3.y;
    result += sampleLevel0( vec2(texPos3.x,  texPos3.y)) * w3.x * w3.y;
    return max(vec4(0.,0.,0.,1.),result);
}

void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir) {
    vec4 Output = texture(iChannel3,rayDir);
    vec2 UV; vec3 aDir = abs(rayDir);
    if (aDir.z>max(aDir.x,aDir.y)) {
        //Z-side
        UV = floor(((rayDir.xy/aDir.z)*0.5+0.5)*1024.)+0.5;
        if (rayDir.z<0.) UV.y += 1024.;
    } else if (aDir.x>aDir.y) {
        //X-side
        UV = floor(((rayDir.yz/aDir.x)*0.5+0.5)*1024.)+0.5;
        if (rayDir.x>0.) UV.y += 2048.;
        else UV.y += 3072.;
    } else {
        //Y-side
        UV = floor(((rayDir.xz/aDir.y)*0.5+0.5)*1024.)+0.5;
        if (rayDir.y>0.) UV.y += 4096.;
        else UV.y += 5120.;
    }
    //SDF volume
    if (DFBox(UV,vec2(1012.,2037.))<0.) {
        //SDF
        vec3 Pos1 = vec3(floor(mod(UV.y,97.))/96.,(floor(UV.x/253.)+4.*floor(UV.y/97.))/80.
                        ,floor(mod(UV.x,253.))/252.)*vec3(8.,6.4,21.);
        //Brick injection
        if (iFrame<2) {
            Output = vec4(1000.);
        } else if (iFrame<2+BuildFrames) {
            for (int bi=(iFrame-2)*32; bi<(iFrame-1)*32; bi++) {
                BRICK CBrick;
                if (bi<128)
                    CBrick = BrickArray0[bi];
                else
                    CBrick = BrickArray1[bi-128];
                //Offset hacking for more bricks
                CBrick.P.y -= 0.32;
                //Read brick attributes
                float ColorIndex = float(CBrick.C)+0.5;
                float CBrickIndexf = float(CBrick.I);
                int CBrickIndex = CBrick.I;
                vec3 CBrickSize = vec3(0.);
                if (CBrickIndex<28)
                    CBrickSize = vec3(BrickADim[CBrickIndex%7],0.8+0.8*floor(CBrickIndexf/14.),1.+mod(floor(CBrickIndexf/7.),2.));
                else if (CBrickIndex<56)
                    CBrickSize = vec3(BrickADim[CBrickIndex%7],0.8+0.8*floor((CBrickIndexf-28.)/14.),
                                      1.+mod(floor((CBrickIndexf-28.)/7.),2.));
                else
                    CBrickSize = BrickDim[CBrickIndex-56];
                //Semi-quaternion
                vec4 Q = vec4(CBrick.Q,0.);
                Q = vec4(normalize(vec3(Q.x,fract(abs(Q.y))*sign(Q.y),Q.z)),floor(abs(Q.y))*ToRadians);
                vec3 CX = Q.xyz;
                vec2 sincos = vec2(sin(Q.w),cos(Q.w));
                vec3 RefCZ = normalize(cross(CX,vec3(0.,1.,0.)));
                vec3 RefCY = cross(RefCZ,CX);
                vec3 CY = sincos.y*RefCY+sincos.x*RefCZ;
                vec3 CZ = -sincos.x*RefCY+sincos.y*RefCZ;
                
                //Pos1
                vec3 BRPos = Pos1-CBrick.P;
                BRPos = BRPos.x*vec3(CX.x,CY.x,CZ.x)+BRPos.y*vec3(CX.y,CY.y,CZ.y)+BRPos.z*vec3(CX.z,CY.z,CZ.z);
                //Sample SDF
                if (CBrickIndex<28)       MIN(Output.xy,vec2(DFBrick(BRPos,CBrickSize),ColorIndex));
                else if (CBrickIndex<56)  MIN(Output.xy,vec2(DFBrick_NoStud(BRPos,CBrickSize),ColorIndex));
                else if (CBrickIndex==56) MIN(Output.xy,vec2(DFGrate(BRPos),ColorIndex));
                else if (CBrickIndex==60) MIN(Output.xy,vec2(DFRound111(BRPos),ColorIndex));
                else if (CBrickIndex==61) MIN(Output.xy,vec2(DFRound131(BRPos),ColorIndex));
                else if (CBrickIndex==62) MIN(Output.xy,vec2(DFCone131(BRPos),ColorIndex));
                else if (CBrickIndex<=70) MIN(Output.xy,vec2(10000.,ColorIndex));
                else if (CBrickIndex==71) MIN(Output.xy,vec2(10000.,ColorIndex));
                else if (CBrickIndex<=73) MIN(Output.xy,vec2(DFISlope(BRPos,CBrickSize.z),ColorIndex));
                else if (CBrickIndex==74) MIN(Output.xy,vec2(DFOnlySlope(BRPos),ColorIndex));
                else if (CBrickIndex==75) MIN(Output.xy,vec2(DFHeadLight(BRPos),ColorIndex));
                else if (CBrickIndex==76) MIN(Output.xy,vec2(DFHose(BRPos),ColorIndex));
                else if (CBrickIndex<=81) MIN(Output.xy,vec2(10000.,ColorIndex));
                else if (CBrickIndex==83) MIN(Output.xy,vec2(10000.,ColorIndex));
                else if (CBrickIndex==84) MIN(Output.xy,vec2(DFPanel(BRPos),ColorIndex));
                else if (CBrickIndex<=86) MIN(Output.xy,vec2(10000.,ColorIndex));
                else if (CBrickIndex==87) MIN(Output.xy,vec2(10000.,ColorIndex));
                else if (CBrickIndex==88) MIN(Output.xy,vec2(10000.,ColorIndex));
                else if (CBrickIndex==89) MIN(Output.xy,vec2(DFDoor(BRPos),ColorIndex));
                else if (CBrickIndex<=91) MIN(Output.xy,vec2(DFHandle(BRPos,CBrickIndexf-91.),ColorIndex));
                else if (CBrickIndex==92) MIN(Output.xy,vec2(DFGrip(BRPos),ColorIndex));
                else if (CBrickIndex<=94) MIN(Output.xy,vec2(DFDisk(BRPos),ColorIndex));
                else if (CBrickIndex==95) MIN(Output.xy,vec2(10000.,ColorIndex));
                else if (CBrickIndex==96) MIN(Output.xy,vec2(10000.,ColorIndex));
                else if (CBrickIndex<=100) MIN(Output.xy,vec2(DFPanelWall(BRPos,CBrickSize),ColorIndex));
            }
        } else if (iFrame<3+BuildFrames) {
            //Copy next layer for output.zw
            vec2 tmpUV = vec2(mod(UV.x+253.,1012.),UV.y+float(UV.x+253.>1012.)*97.);
            Output.zw = textureCube(tmpUV).xy;
        }
    } else if (UV.y>2048.) {
        //TAA
        vec2 RESOffset = vec2((mod(floor((UV.y-2048.)*I1024)+0.5,2.)-0.5)*1024.,
                              floor((UV.y-2048.)*I1024*0.5)*1024.);
        vec2 CUV = mod(UV,1024.)+RESOffset;
        if (DFBox(CUV-3.,RES-6.)<0.) {
            //Inside the screen
            vec2 BCRef = texture(iChannel2,CUV*IRES).xy;
            vec3 FinalColor = vec3(FloatToVec2(BCRef.x)*10.,BCRef.y);
            //Reprojection
            float CurrentFrame = float(iFrame);
            vec2 SSOffset = SSOffsets[iFrame%16];
            vec3 Pos = texture(iChannel0,vec2(7.5,0.5)*IRES).xyz;
            vec3 Eye = texture(iChannel0,vec2(6.5,0.5)*IRES).xyz;
            vec3 Tan; vec3 Bit = TBN(Eye,Tan);
            mat3 EyeMat = TBN(Eye);
            vec3 PriorPos = texture(iChannel0,vec2(10.5,0.5)*IRES).xyz;
            vec3 PriorEye = texture(iChannel0,vec2(9.5,0.5)*IRES).xyz;
            vec3 PriorTan; vec3 PriorBit = TBN(PriorEye,PriorTan);
            mat3 PriorEyeMat = TBN(PriorEye);
            vec3 Dir = normalize(vec3(((CUV+SSOffset)*IRES*2.-1.)*CFOV*ASPECT,1.)*EyeMat);
            vec4 CAttr = texture(iChannel0,CUV*IRES);
            float Distance = CAttr.w;
            if (Distance<-0.5) Distance = 100000.; //Sky pixel
            vec3 PPos = Pos+Dir*Distance;
            vec3 Normal = normalize(FloatToVec3(CAttr.z)*2.-1.);
            //Color multiplication
            if (Distance<9999.) {
                float SVal = (PPos.y/6.4)*80.+0.5;
                vec2 UVmod = 0.5+floor((PPos.zx/vec2(21.,8.))*vec2(252.,96.)+0.5);
                vec2 UVSlice0 = vec2(min(floor(mod(SVal,4.)),3.)*253.,min(floor(SVal/4.),20.)*97.);
                FinalColor *= BrickColorArray[int(floor(textureCube(UVmod+UVSlice0).y))];
            }
            //Prior position
            vec3 PriorVPos = vec3(dot(PPos-PriorPos,PriorTan),dot(PPos-PriorPos,PriorBit),dot(PPos-PriorPos,PriorEye));
            vec2 PriorUV = ((PriorVPos.xy/PriorVPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
            if (DFBox(PriorUV-3.,RES-6.)<0.) {
                //Valid reprojection
                vec4 LFinalColor;
                if (length(PriorUV-CUV-SSOffset)>0.02) {
                    //Catmull-rom sampling
                    PriorUV -= SSOffsets[(iFrame-1)%16];
                    LFinalColor = SampleTextureCatmullRom(PriorUV);
                } else {
                    //Nearest neighbour sampling
                    PriorUV = floor(PriorUV)+0.5;
                    float YOffset = 2048.+floor(PriorUV.x*I1024)*1024.+floor(PriorUV.y*I1024)*2048.;
                    LFinalColor = textureCube(mod(PriorUV,1024.)+vec2(0.,YOffset));
                }
                //Clamping
                vec3 FMIN = vec3(1000.);
                vec3 FMAX = vec3(0.);
                for (float x=-1.; x<1.5; x+=1.) {
                    for (float y=-1.; y<1.5; y+=1.) {
                        BCRef = texture(iChannel2,(CUV+vec2(x,y))*IRES).xy;
                        vec3 Sample = vec3(FloatToVec2(BCRef.x)*10.,BCRef.y);
                        //Color
                        vec3 SDir = normalize(vec3(((CUV+vec2(x,y)+SSOffset)*IRES*2.-1.)*CFOV*ASPECT,1.)*EyeMat);
                        vec4 SAttr = texture(iChannel0,(CUV+vec2(x,y))*IRES);
                        if (SAttr.w>-0.5) {
                            vec3 SPPos = Pos+SDir*SAttr.w;
                            float SVal = (SPPos.y/6.4)*80.+0.5;
                            vec2 UVmod = 0.5+floor((SPPos.zx/vec2(21.,8.))*vec2(252.,96.)+0.5);
                            vec2 UVSlice0 = vec2(min(floor(mod(SVal,4.)),3.)*253.,min(floor(SVal/4.),20.)*97.);
                            Sample *= BrickColorArray[int(floor(textureCube(UVmod+UVSlice0).y))];
                        }
                        //Clamp
                        FMIN = min(FMIN,Sample);
                        FMAX = max(FMAX,Sample);
                    }
                }
                LFinalColor.xyz = clamp(LFinalColor.xyz,FMIN,FMAX);
                //Output
                Output = vec4((FinalColor+LFinalColor.xyz*LFinalColor.w)/(LFinalColor.w+1.),min(31.,LFinalColor.w+1.));
            } else {
                //Invalid reprojection
                Output = vec4(FinalColor,1.);
            }
        }
    }
    //Output
    fragColor = Output;
}