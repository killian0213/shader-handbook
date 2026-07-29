// Cube A (cubemap) — LEGO Creator 5891 by Mathis
// https://www.shadertoy.com/view/DsSSWh

//Acceleration structure

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
}

vec4 UpdateOutput(vec4 Output, int bi, vec3 VPos, inout int WriteIndex) {
    //Updates Output
    float CBrickArrayIndex = float(bi);
    vec2 CBrickUV = vec2(mod(CBrickArrayIndex+0.5,26.),floor((CBrickArrayIndex+0.5)*I26)+27.5);
    vec4 CBrick0 = texture(iChannel0,CBrickUV*IRES);
    vec4 CBrick1 = texture(iChannel0,vec2(CBrickUV.x+26.,CBrickUV.y)*IRES);
    vec3 CBrickSize;
    float cbfi = floor(CBrick0.w);
    int cbint = int(cbfi);
    if (cbint<28)
        CBrickSize = vec3(BrickADim[cbint%7],0.8+0.8*floor(cbfi/14.),1.+mod(floor(cbfi/7.),2.));
    else if (cbint<56)
        CBrickSize = vec3(BrickADim[cbint%7],0.8+0.8*floor((cbfi-28.)/14.),1.+mod(floor((cbfi-28.)/7.),2.));
    else
        CBrickSize = BrickDim[cbint-56];
    //Quaternion coordinate system
    vec3 CX = CBrick1.xyz;
    vec2 sincos = vec2(sin(CBrick1.w),cos(CBrick1.w));
    vec3 RefCZ = normalize(cross(CX,vec3(0.,1.,0.)));
    vec3 RefCY = cross(RefCZ,CX);
    vec3 CY = sincos.y*RefCY+sincos.x*RefCZ;
    vec3 CZ = -sincos.x*RefCY+sincos.y*RefCZ;
    vec3 CXT = vec3(CX.x,CY.x,CZ.x);
    vec3 CYT = vec3(CX.y,CY.y,CZ.y);
    vec3 CZT = vec3(CX.z,CY.z,CZ.z);
    //Rotate brick
    bool Intersects = true;
    vec3 BVP = VPos-vec3(0.5,0.2,0.5)-CBrick0.xyz;
    BVP = BVP.x*CXT+BVP.y*CYT+BVP.z*CZT;
    //Plane separation test
    float CBrickDFSample = DFBox(BVP+(CXT*0.5+CYT*0.2+CZT*0.5),CBrickSize);
    if (CBrickDFSample>1.22474487139) {
        Intersects = false;
    } else if (CBrickDFSample>0.) {
        for (int axis=0; axis<3; axis++) {
            //For each axis
            float BVPA = BVP[axis];
            float CXA = CXT[axis];
            float CYA = CYT[axis]*0.4;
            float CZA = CZT[axis];
            float VMin = BVPA+min(min(min(0.,CXA),min(CYA,CXA+CYA)),
                             min(min(CZA,CXA+CZA),min(CYA+CZA,CXA+CYA+CZA)));
            float VMax = BVPA+max(max(max(0.,CXA),max(CYA,CXA+CYA)),
                             max(max(CZA,CXA+CZA),max(CYA+CZA,CXA+CYA+CZA)));
            float BMin = 0.;
            float BMax = CBrickSize[axis];
            if (VMin>=BMax || BMin>=VMax) {
                //No intersection
                Intersects = false; break;
            }
            //Plane in world coordinate system
            BVPA = (CBrick0.xyz-(VPos-vec3(0.5,0.2,0.5)))[axis];
            BMin = 0.;
            BMax = vec3(1.,0.4,1.)[axis];
            CXA = (CX*CBrickSize.x)[axis];
            CYA = (CY*CBrickSize.y)[axis];
            CZA = (CZ*CBrickSize.z)[axis];
            VMin = BVPA+min(min(min(0.,CXA),min(CYA,CXA+CYA)),
                             min(min(CZA,CXA+CZA),min(CYA+CZA,CXA+CYA+CZA)));
            VMax = BVPA+max(max(max(0.,CXA),max(CYA,CXA+CYA)),
                             max(max(CZA,CXA+CZA),max(CYA+CZA,CXA+CYA+CZA)));
            if (VMin>=BMax || BMin>=VMax) {
                //No intersection
                Intersects = false; break;
            }
        }
    }
    if (Intersects) {
        //Brick intersects the current voxel
        bool UniqueIndex = true;
        float OUTf = float(bi)+0.5;
        for (int OutIndex=0; OutIndex<WriteIndex; OutIndex++) {
            if (abs(Output[OutIndex]-OUTf)<0.1) UniqueIndex = false;
        }
        if (UniqueIndex) {
            Output[WriteIndex] = OUTf;
            WriteIndex += 1;
        }
    }
    return Output;
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
    if (iFrame==0) {
        Output = vec4(-1.);
    } else if (UV.y<2048. && iFrame<BuildFrames) {
        //Initial frames
        vec3 VPos = vec3(mod(UV.x,128.)-48.,(floor(UV.x*I128)+floor(UV.y*I128)*8.+0.5)*0.4,mod(UV.y,128.)-48.);
        int WriteIndex = 0;
        for (int lbi=0; lbi<4; lbi++) {
            if (Output[lbi]<-0.5) break;
            WriteIndex += 1;
        }
        for (int lbi=0; lbi<16; lbi++) {
            if (WriteIndex>3) break;
            Output = UpdateOutput(Output,lbi+(iFrame-1)*16,VPos,WriteIndex);
        }
    } else if (UV.y<2048.) {
        //Brick propagation
        vec4 OutputCopy = Output;
        Output = vec4(-1.);
        vec3 VPos = vec3(mod(UV.x,128.)-48.,(floor(UV.x*I128)+floor(UV.y*I128)*8.+0.5)*0.4,mod(UV.y,128.)-48.);
        int WriteIndex = 0;
        //Test the current voxel with its bricks
        for (int axis=0; axis<4; axis++) {
            int CBIndex = int(floor(OutputCopy[axis]));
            if (CBIndex<0) break;
            Output = UpdateOutput(Output,CBIndex,VPos,WriteIndex);
        }
        if (WriteIndex<4) {
            //Inject bricks at building stage
            vec2 RMoved = texture(iChannel0,vec2(8.5,0.5)*IRES).xy;
            float FrameTime = min(iTimeDelta,1./30.);
            float RelativeTimeCoeff = iTimeDelta/FrameTime;
            float RTime = texture(iChannel0,vec2(9.5,0.5)*IRES).x;
            if (RMoved.x>0.5 && RTime>6. && RTime<70.) {
                int BuildBIndex = int(floor((RTime-6.)*8.));
                Output = UpdateOutput(Output,BuildBIndex,VPos,WriteIndex);
            }
            //Propagate
            for (float zoff=-1.; zoff<1.5; zoff++) {
                for (float xoff=-1.; xoff<1.5; xoff++) {
                    for (float yoff=-1.; yoff<1.5; yoff++) {
                        if (WriteIndex>3 || (xoff==0. && yoff==0. && zoff==0.)) continue;
                        vec3 SPos = VPos+vec3(xoff,yoff*0.4,zoff);
                        vec2 SUV = vec2(SPos.x+48.+floor(mod(SPos.y*2.5,8.))*128.,SPos.z+48.+floor(SPos.y*2.5*0.125)*128.);
                        vec4 SC = textureCube(SUV);
                        for (int axis=0; axis<4; axis++) {
                            int CBIndex = int(floor(SC[axis]));
                            if (CBIndex<0 || WriteIndex>3) break;
                            Output = UpdateOutput(Output,CBIndex,VPos,WriteIndex);
                        }
                    }
                }
            }
        }
    }
    //Output
    fragColor = Output;
}