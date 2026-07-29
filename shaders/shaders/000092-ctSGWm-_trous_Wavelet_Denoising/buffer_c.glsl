// Buffer C (buffer) — Àtrous Wavelet Denoising by Mathis
// https://www.shadertoy.com/view/ctSGWm

//Primary rays + Wavelet iteration 2

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    if (DFBox(fragCoord-3.,RES-6.)<0.) {
        //
        //PRIOR FRAME: primary rays
        //
        vec2 SSOffset = SSOffsets[(iFrame)%16];
        float CurrentTime = iTime;
        vec3 Pos = Position(iMouse,CurrentTime,IRES);
        vec3 Eye = normalize(CameraCenter(iMouse,iTime)-Pos);
        vec3 Dir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*CFOV*ASPECT,1.)*TBN(Eye));
        HIT Pixel = Trace(Pos,Dir,CurrentTime);
        Output.w = ((Pixel.M<0.)?-1.:Pixel.D);
        
        
        
        
        //
        //CURRENT FRAME: wavelet iteration 2
        //
        float CurrentFrame = float(iFrame-1);
        SSOffset = SSOffsets[(iFrame-1)%16];
        CurrentTime = texture(iChannel1,vec2(0.5,0.5)*IRES).y;
        vec4 CurrentMouse = texture(iChannel1,vec2(2.5,0.5)*IRES);
        Pos = Position(CurrentMouse,CurrentTime,IRES);
        Eye = normalize(CameraCenter(CurrentMouse,CurrentTime)-Pos);
        vec3 Tan; vec3 Bit = TBN(Eye,Tan);
        mat3 EyeMat = TBN(Eye);
        Dir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*CFOV*ASPECT,1.)*EyeMat);
        float Distance = texture(iChannel1,fragCoord*IRES).w;
        if (Distance>-0.5) {
            //Geometry
            HIT Pixel = Trace(Pos+Dir*(Distance-0.01),Dir,CurrentTime); //Get attributes
            vec3 Normal = normalize(FloatToVec3(texture(iChannel3,fragCoord*IRES).w)*2.-1.);
            vec3 PPos = Pos+Dir*Distance;
            vec4 RefShad = texture(iChannel0,fragCoord*IRES);
            vec2 RandV = ARand23(fragCoord*IRES*(1.+mod(CurrentFrame*7.253,9.234))).xy;
            //Denoisers
            if (Pixel.M<1.) {
                //Non-emissive material
                //Reflections denoiser
                vec3 RefDir = reflect(Dir,Normal);
                float RefCR = Pixel.M*min(1.,tan((HPI-acos(dot(RefDir,Normal)))));
                vec3 Light = FloatToVec3(texture(iChannel1,fragCoord*IRES).y)*ReflConst*2.;
                float W = 2.;
                vec3 CVPos0 = vec3(RefShad.x*RefCR,0.,Distance+RefShad.x)*TBN(Dir);
                vec3 CVPos1 = vec3(-RefShad.x*RefCR,0.,Distance+RefShad.x)*TBN(Dir);
                vec3 LVPos0 = vec3(dot(CVPos0,Tan),dot(CVPos0,Bit),dot(CVPos0,Eye));
                vec3 LVPos1 = vec3(dot(CVPos1,Tan),dot(CVPos1,Bit),dot(CVPos1,Eye));
                vec2 Luv0 = ((LVPos0.xy/LVPos0.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                vec2 Luv1 = ((LVPos1.xy/LVPos1.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                float MaxRadius = min(8.,length(Luv0-Luv1)*0.5);
                for (float x=-2.; x<2.5; x+=1.) {
                    for (float y=-2.; y<2.5; y+=1.) {
                        if (x==0. && y==0.) continue;
                        vec2 Offset2 = normalize(vec2(x,y))*max(abs(x),abs(y))*(MaxRadius*0.5);
                        vec2 SUV = floor(fragCoord+Offset2)+0.5;
                        float SDist = texture(iChannel1,SUV*IRES).w;
                        vec3 SDir = normalize(vec3(((SUV+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
                        if (SDist<-0.5 || abs(dot(Pos+SDir*SDist-PPos,Normal))>0.1 || DFBox(SUV-3.,RES-6.)>0.) continue;
                        vec3 SNor = FloatToVec3(texture(iChannel3,SUV*IRES).w)*2.-1.;
                        //Reflection direction
                        vec4 SRefShad = texture(iChannel0,SUV*IRES);
                        if (SRefShad.x<-0.5) continue;
                        vec2 SRand = ARand23(SUV*IRES*(1.+mod(CurrentFrame*7.253,9.234))).xy;
                        vec3 SRefDir = reflect(SDir,SNor);
                        float SCR = Pixel.M*min(1.,tan((HPI-acos(dot(RefDir,Normal))))); //Måste ray-tracea för Hit.y annars
                        vec3 SRDir = normalize(RandSampleCos(SRand)*TBN(SRefDir)*SCR+SRefDir);
                        vec3 HitP = Pos+SDir*SDist+SNor*0.0015+SRDir*SRefShad.x;
                        if (dot(HitP-PPos,Normal)<=0.) continue;
                        if (sqrt(1./dot(normalize(HitP-PPos),RefDir)-1.)<=RefCR) {
                            Light += FloatToVec3(texture(iChannel1,SUV*IRES).y)*ReflConst;
                            W += 1.;
                        }
                    }
                }
                Light = Light/W;
                Output.xy = vec2(Vec2ToFloat(Light.xy*IReflConst),Light.z);
                //Shadow denoiser
                CVPos0 = vec3(RefShad.y*SunCR,0.,Distance+RefShad.y)*TBN(Dir);
                CVPos1 = vec3(-RefShad.y*SunCR,0.,Distance+RefShad.y)*TBN(Dir);
                LVPos0 = vec3(dot(CVPos0,Tan),dot(CVPos0,Bit),dot(CVPos0,Eye));
                LVPos1 = vec3(dot(CVPos1,Tan),dot(CVPos1,Bit),dot(CVPos1,Eye));
                Luv0 = ((LVPos0.xy/LVPos0.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                Luv1 = ((LVPos1.xy/LVPos1.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                MaxRadius = min(8.,length(Luv0-Luv1)*0.5);
                float CShadow = texture(iChannel1,fragCoord*IRES).z*2.;
                float ShadW = 2.;
                for (float x=-2.; x<2.5; x+=1.) {
                    for (float y=-2.; y<2.5; y+=1.) {
                        if (x==0. && y==0.) continue;
                        vec2 Offset2 = normalize(vec2(x,y))*max(abs(x),abs(y))*(MaxRadius*0.5);
                        vec2 SUV = floor(fragCoord+Offset2)+0.5;
                        vec4 SRefShad = texture(iChannel1,SUV*IRES);
                        float SDistance = SRefShad.w;
                        vec3 SDir = normalize(vec3(((SUV+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
                        if (SDistance<-0.5 || abs(dot(Pos+SDir*SDistance-PPos,Normal))>0.1 || DFBox(SUV-3.,RES-6.)>0.) continue;
                        float RayDist = texture(iChannel0,SUV*IRES).y;
                        if (RayDist<-0.5) continue;
                        vec2 SRand = ARand23(SUV*IRES*(1.+mod(CurrentFrame*7.253,9.234))).xy;
                        vec3 HitP = Pos+SDir*SDistance+normalize(RandSampleCos(SRand.xy)*TBN(SunDir)*SunCR+SunDir)*RayDist;
                        if (dot(HitP-PPos,Normal)<=0.) continue;
                        CShadow += SRefShad.z;
                        ShadW += 1.;
                    }
                }
                Output.z = CShadow/ShadW;
            }
        } else {
            //Sky
        }
    }
    fragColor = Output;
}