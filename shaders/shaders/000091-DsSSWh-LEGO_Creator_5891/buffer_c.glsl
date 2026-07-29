// Buffer C (buffer) — LEGO Creator 5891 by Mathis
// https://www.shadertoy.com/view/DsSSWh

//Secondary rays

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
}

vec4 Trace(vec3 P, vec3 D) {
    //Traces a ray through the scene
    vec3 IDir = 1./D;
    vec4 OUT = vec4(100000.,-10.,-1.,-1.);
    //32x32 brick
    vec2 bb = box(P,IDir,vec3(0.),vec3(32.,0.4*8.,32.));
    bool Inside32 = (DFBox(P,vec3(32.,0.4*8.,32.))<=0.);
    if ((bb.x>0. && bb.y>bb.x) || Inside32) {
        //Bottom brick
        float dft; float dfdist = ((Inside32)?0.:bb.x); float dfFAR = min(bb.y,OUT.x);
        for (int i=0; i<356; i++) {
            if (dfdist>dfFAR) break;
            dft = DF32x32(P+D*dfdist);
            if (dft<0.0005) {
                OUT = vec4(dfdist,-1.,-1.,-1.);
                if (P.y+D.y*dfdist>0.199) OUT.zw = fract(P.xz+D.xz*dfdist);
                break;
            }
            dfdist = dfdist+dft;
        }
    }
    //Dynamic bricks
    float t = 0.;
    bb = box(P,IDir,vec3(-48.001,0.001,-48.001),vec3(79.999,51.199,79.999));
    float bbDF = DFBox(P-vec3(-48.001,0.001,-48.001),vec3(127.998,51.198,127.998));
    float FAR = min(OUT.x,bb.y);
    float LFar = FAR; vec3 cp,fp,Normal; vec4 C;
    float LOD = 0.;
    vec3 LS = vec3(1.,0.4,1.);
    vec3 ILS = vec3(1.,2.5,1.);
    fp = floor(P*ILS)*LS;
    //Iterations
    for (int i=0; i<112; i++) {
        if (t>FAR) break;
        cp = P+D*t;
        C = textureCube(vec2(fp.x+floor(mod(fp.y*2.5+0.5,8.))*128.,fp.z+floor((fp.y*2.5+0.5)*0.125)*128.)+48.5);
        bb = box(P,IDir,fp,fp+LS);
        bbDF = DFBox(cp-fp,LS);
        if (C.x>0. && ((bb.x>=0. && bb.y>bb.x) || bbDF<=0.)) {
            if (LOD==0.) {
                float GCDist = 100000.; int GCBrickArrayIndex = -1;
                vec2 GCBrickUV; vec3 GCX,GCY,GCZ; vec2 StudUV;
                for (int ColorIndex = 0; ColorIndex<4; ColorIndex++) {
                    float CBrickArrayIndex = floor(C[ColorIndex]);
                    if (CBrickArrayIndex<-0.5) break;
                    vec2 CBrickUV = vec2(mod(CBrickArrayIndex+0.5,26.),floor((CBrickArrayIndex+0.5)*I26)+27.5);
                    vec4 CBrick0 = texture(iChannel0,CBrickUV*IRES);
                    vec4 CBrick1 = texture(iChannel0,vec2(CBrickUV.x+26.,CBrickUV.y)*IRES);
                    float CBrickIndexf = floor(CBrick0.w);
                    int CBrickIndex = int(CBrickIndexf);
                    vec3 CBrickSize = vec3(0.);
                    if (CBrickIndex<28)
                        CBrickSize = vec3(BrickADim[CBrickIndex%7],0.8+0.8*floor(CBrick0.w/14.),1.+mod(floor(CBrick0.w/7.),2.));
                    else if (CBrickIndex<56)
                        CBrickSize = vec3(BrickADim[CBrickIndex%7],0.8+0.8*floor((CBrick0.w-28.)/14.),
                                          1.+mod(floor((CBrick0.w-28.)/7.),2.));
                    else
                        CBrickSize = BrickDim[CBrickIndex-56];
                    //Semi-quaternion
                    vec3 CX = CBrick1.xyz;
                    vec2 sincos = vec2(sin(CBrick1.w),cos(CBrick1.w));
                    vec3 RefCZ = normalize(cross(CX,vec3(0.,1.,0.)));
                    vec3 RefCY = cross(RefCZ,CX);
                    vec3 CY = sincos.y*RefCY+sincos.x*RefCZ;
                    vec3 CZ = -sincos.x*RefCY+sincos.y*RefCZ;
                    vec3 BRPos = cp-CBrick0.xyz;
                    BRPos = BRPos.x*vec3(CX.x,CY.x,CZ.x)+BRPos.y*vec3(CX.y,CY.y,CZ.y)+BRPos.z*vec3(CX.z,CY.z,CZ.z);
                    vec3 BRDir = D.x*vec3(CX.x,CY.x,CZ.x)+D.y*vec3(CX.y,CY.y,CZ.y)+D.z*vec3(CX.z,CY.z,CZ.z);
                    //Unified SDF
                    float biFAR = min(FAR,bb.y)-t;
                    vec3 DS = vec3(100000.,0.,0.);
                    if (CBrickIndex<28) DS = TraceBrick(BRPos,BRDir,CBrickSize,biFAR); //(1,2,3,4,6,8,10)x(0.4,1.2)x(1,2) = 7*2*2
                    else if (CBrickIndex<56) DS = TraceBrick_NoStud(BRPos,BRDir,CBrickSize,biFAR);
                    else if (CBrickIndex==56) DS = TraceGrate(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex<=59) DS = TraceCorner(BRPos,BRDir,CBrickIndexf-56.,biFAR);
                    else if (CBrickIndex==60) DS = TraceRound111(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex==61) DS = TraceRound131(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex==62) DS = TraceCone131(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex<=70) DS = TraceSlope(BRPos,BRDir,CBrickIndexf-62.,biFAR);
                    else if (CBrickIndex==71) DS = TraceSlope331(BRPos,BRDir,CBrickIndexf-62.,biFAR);
                    else if (CBrickIndex<=73) DS = TraceISlope(BRPos,BRDir,CBrickIndexf-71.,biFAR);
                    else if (CBrickIndex==74) DS = TraceOnlySlope(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex==75) DS = TraceHeadLight(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex==76) DS = TraceHose(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex<=81) DS = TraceDoubleSlope(BRPos,BRDir,CBrickIndexf-76.,biFAR);
                    else if (CBrickIndex==83) DS = TraceRound232(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex==84) DS = TracePanel(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex<=86) DS = TraceWindow(BRPos,BRDir,CBrickIndexf-84.,biFAR);
                    else if (CBrickIndex==87) DS = TraceWindowFrame(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex==88) DS = TraceBrickHole(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex==89) DS = TraceDoor(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex<=91) DS = TraceHandle(BRPos,BRDir,CBrickIndexf-90.,biFAR);
                    else if (CBrickIndex==92) DS = TraceGrip(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex<=94) DS = TraceDisk(BRPos,BRDir,CBrickIndexf-92.,biFAR);
                    else if (CBrickIndex==95) DS = TraceSlopeCross(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex==96) DS = TraceDoubleSlopeInverse(BRPos,BRDir,CBrickIndexf,biFAR);
                    else if (CBrickIndex==97) DS = TraceWindowOblique(BRPos,BRDir,CBrickIndexf,biFAR);
                    if (DS.x<biFAR && GCDist>DS.x) {
                        GCX = CX; GCY = CY; GCZ = CZ;
                        GCBrickUV = CBrickUV;
                        GCBrickArrayIndex = int(CBrickArrayIndex);
                        GCDist = DS.x;
                        StudUV = DS.yz;
                    }
                }
                //Intersection test
                if (GCDist<99990.) return vec4(t+GCDist,GCBrickArrayIndex,StudUV);
            }
        }
        vec3 farNormal = boxfarNormal(P,IDir,fp,fp+LS);
        fp += farNormal*LS;
        t = bb.y;
    }
    //Return
    return OUT;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 Color = vec3(0.);
    //Set up camera
    float Frame = float(iFrame);
    vec2 RMoved = texture(iChannel0,vec2(8.5,0.5)*IRES).xy;
    vec2 SSOffset = (texture(iChannel2,vec2(Frame*I1024)).zx-0.5)*float(RMoved.x<0.5);
    vec3 SunDir = texture(iChannel0,vec2(5.5,0.5)*IRES).xyz;
    vec3 Pos = texture(iChannel0,vec2(3.5,0.5)*IRES).xyz;
    vec3 Eye = texture(iChannel0,vec2(2.5,0.5)*IRES).xyz;
    mat3 EyeMat = TBN(Eye);
    vec3 VDir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.));
    vec3 Dir = VDir*EyeMat;
    //Render scene
    vec4 GBSample = texture(iChannel1,fragCoord*IRES);
    if (GBSample.y>-5.5) {
        //Geometry
        HIT Pixel;
        Pixel.D = GBSample.x;
        Pixel.P = Pos+Dir*Pixel.D;
        float CBrickArrayIndex = floor(GBSample.y);
        vec2 CBrickUV = vec2(mod(CBrickArrayIndex+0.5,26.),floor((CBrickArrayIndex+0.5)*I26)+27.5);
        if (GBSample.y>-0.5) Pixel.C = texture(iChannel0,vec2(CBrickUV.x+52.,CBrickUV.y)*IRES).xyz;
        else if (GBSample.y>-1.5) Pixel.C = vec3(0.15,0.99,0.15);
        else Pixel.C = vec3(1./(1.-Pixel.P.y));
        vec3 RealNormal = vec3(0.,1.,0.);
        if (GBSample.z>-0.5) {
            //Stud normal map
            Pixel.N = texture(iChannel0,(GBSample.zw*128.+vec2(128.,53.))*IRES).zyx;
            if (GBSample.y>-0.5) {
                //Brick
                vec4 CBrick1 = texture(iChannel0,vec2(CBrickUV.x+26.,CBrickUV.y)*IRES);
                vec3 CX = CBrick1.xyz;
                vec2 sincos = vec2(sin(CBrick1.w),cos(CBrick1.w));
                vec3 RefCZ = normalize(cross(CX,vec3(0.,1.,0.)));
                vec3 RefCY = cross(RefCZ,CX);
                vec3 CY = sincos.y*RefCY+sincos.x*RefCZ;
                vec3 CZ = -sincos.x*RefCY+sincos.y*RefCZ;
                Pixel.N = vec3(0.,Pixel.N.y,0.)+CX*Pixel.N.x+CZ*Pixel.N.z;
            }
            if (dot(Dir,Pixel.N)>0.) Pixel.N = normalize(Pixel.N-1.01*Dir*dot(Dir,Pixel.N));
        } else {
            //Normal from depth
            vec3 PixelVP = VDir*Pixel.D;
            vec3 Tan = vec3(0.,0.,0.);
            vec3 Bit = vec3(0.,0.,0.);
            vec4 XD = vec4(texture(iChannel1,(fragCoord+vec2(1.,0.))*IRES).xy,texture(iChannel1,(fragCoord+vec2(-1.,0.))*IRES).xy);
            vec3 XP0 = normalize(vec3(((fragCoord+vec2(1.,0.)+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.))*XD.x;
            vec3 XP1 = normalize(vec3(((fragCoord-vec2(1.,0.)+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.))*XD.z;
            if (XD.y>-5.5) Tan = XP0-PixelVP;
            if (XD.w>-5.5 && (length(Tan)==0. || length(Tan)>length(XP1-PixelVP))) Tan = XP1-PixelVP;
            vec4 YD = vec4(texture(iChannel1,(fragCoord+vec2(0.,1.))*IRES).xy,texture(iChannel1,(fragCoord+vec2(0.,-1.))*IRES).xy);
            vec3 YP0 = normalize(vec3(((fragCoord+vec2(0.,1.)+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.))*YD.x;
            vec3 YP1 = normalize(vec3(((fragCoord-vec2(0.,1.)+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.))*YD.z;
            if (YD.y>-5.5) Bit = YP0-PixelVP;
            if (YD.w>-5.5 && (length(Bit)==0. || length(Bit)>length(YP1-PixelVP))) Bit = YP1-PixelVP;
            Pixel.N = normalize(cross(Bit,Tan))*EyeMat;
            Pixel.N *= sign(dot(Pixel.N,-Dir));
            RealNormal = Pixel.N;
        }
        vec3 PPos = Pixel.P+RealNormal*0.005;
        if (RMoved.x>0.5) {
            //Edge detection
            float AO = 0.;
            for (float x=-1.; x<1.5; x++) {
                for (float y=-1.; y<1.5; y++) {
                    if (x==0. && y==0.) continue;
                    vec2 SUV = fragCoord+vec2(x,y);
                    vec2 SD = texture(iChannel1,SUV*IRES).xy;
                    if (SD.y<-5.5) { AO += 0.5; continue; }
                    vec3 XP0 = Pos-Pixel.P+normalize(vec3(((SUV+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat)*SD.x;
                    float SDot = dot(XP0,Pixel.N);
                    AO += max(0.,SDot-0.01);
                }
            }
            Color = Pixel.C*((Pixel.N.y*0.5+0.5)*0.5+0.5)/(1.+AO*150.);
        } else {
            //GGX Path Tracing
            vec2 RM = vec2(0.01,0.5);
            Color = vec3(0.);
            vec3 Rand3 = (texture(iChannel2,(fragCoord+Frame*vec2(279.267,199.123))*I1024).xyz+
                          texture(iChannel2,(fragCoord*1.12+Frame*vec2(179.267,239.123))*I1024).xyz*255.)/256.;
            vec3 NB,NT,TDir,RDir,Reflectance;
            if (Rand3.z<RM.y) { //Roughness
                //GGX
                NB = TBN(Pixel.N,NT);
                TDir = -vec3(dot(Dir,NT),dot(Dir,NB),dot(Dir,Pixel.N)); //Negative direction in tangent space 
                ImportanceSampleGGX(Rand3.xy,TDir,RM.x,vec3(0.075),RDir,Reflectance);
                RDir = normalize(RDir*TBN(Pixel.N));
            } else {
                //Diffuse
                RDir = RandSampleCos(Rand3.xy)*TBN(Pixel.N);
            }
            if (dot(RDir,RealNormal)<0.) RDir = reflect(RDir,RealNormal);
            //Ray trace
            vec4 RHit = Trace(PPos,RDir);
            if (RHit.y>-5.5) {
                float RHI = floor(RHit.y);
                CBrickUV = vec2(mod(RHI+0.5,26.),floor((RHI+0.5)*I26)+27.5);
                vec3 RHC;
                if (RHit.y>-0.5) {
                    RHC = texture(iChannel0,vec2(CBrickUV.x+52.,CBrickUV.y)*IRES).xyz;
                } else {
                    RHC = vec3(0.15,0.99,0.15);
                }
                if (Rand3.z>=RM.y) Color += Pixel.C*RHC*0.5*(1.-exp(-RHit.x*0.05)); //Fake multibounce integrand
            } else {
                //Sky
                Color = SampleSky(RDir,SunDir)*((Rand3.z<RM.y)?Reflectance:Pixel.C);
            }
            //Nan test
            bvec3 test = isnan(Color);
            if (test.x || test.y || test.z) Color = vec3(0.);
        }
    } else {
        //Sky
        Color = SampleSky(Dir,SunDir);
    }
    
    
    //DEBUG
    /*
    vec2 CMUV = floor(fragCoord+vec2(0.,max(0.,iMouse.y*IRES.y*1024.*7.-1024.)))+0.5;
    if (CMUV.y<1024.*6.) Color = textureCube(floor(CMUV)+0.5).xyz;
    //*/
    //Color = texture(iChannel0,fragCoord*0.25*IRES).xyz;
    
    
    fragColor = vec4(Color,1.);
}