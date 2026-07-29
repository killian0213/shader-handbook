// Buffer B (buffer) — Àtrous Wavelet Denoising by Mathis
// https://www.shadertoy.com/view/ctSGWm

//Copy depth + Wavelet iteration 1 + Attributes

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    if (DFBox(fragCoord-3.,RES-6.)<0.) {
        //
        //PRIOR FRAME: copy depth
        //
        Output.w = texture(iChannel2,fragCoord*IRES).w; //Copy depth prior frame
        Output.x = texture(iChannel3,fragCoord*IRES).w; //Copy normal
        
        
        
        
        //
        //CURRENT FRAME: wavelet iteration 1
        //
        float CShadow = 0.;
        float ShadW = 1.;
        float CurrentFrame = float(iFrame-1);
        vec2 SSOffset = SSOffsets[(iFrame-1)%16];
        float CurrentTime = texture(iChannel1,vec2(0.5,0.5)*IRES).x;
        vec4 CurrentMouse = texture(iChannel1,vec2(1.5,0.5)*IRES);
        vec3 Pos = Position(CurrentMouse,CurrentTime,IRES);
        vec3 Eye = normalize(CameraCenter(CurrentMouse,CurrentTime)-Pos);
        vec3 Tan; vec3 Bit = TBN(Eye,Tan);
        mat3 EyeMat = TBN(Eye);
        vec3 Dir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*CFOV*ASPECT,1.)*EyeMat);
        float Distance = texture(iChannel2,fragCoord*IRES).w;
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
                vec3 Light = FloatToVec3(RefShad.z)*ReflConst*2.;
                float W = 2.;
                vec3 CVPos0 = vec3(RefShad.x*RefCR,0.,Distance+RefShad.x)*TBN(Dir);
                vec3 CVPos1 = vec3(-RefShad.x*RefCR,0.,Distance+RefShad.x)*TBN(Dir);
                vec3 LVPos0 = vec3(dot(CVPos0,Tan),dot(CVPos0,Bit),dot(CVPos0,Eye));
                vec3 LVPos1 = vec3(dot(CVPos1,Tan),dot(CVPos1,Bit),dot(CVPos1,Eye));
                vec2 Luv0 = ((LVPos0.xy/LVPos0.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                vec2 Luv1 = ((LVPos1.xy/LVPos1.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                float MaxRadius = min(32.,length(Luv0-Luv1)*0.5);
                for (float x=-2.; x<2.5; x+=1.) {
                    for (float y=-2.; y<2.5; y+=1.) {
                        if (x==0. && y==0.) continue;
                        vec2 Offset2 = normalize(vec2(x,y))*max(abs(x),abs(y))*(0.5*MaxRadius);
                        vec2 SUV = floor(fragCoord+Offset2)+0.5;
                        float SDistance = texture(iChannel2,SUV*IRES).w;
                        vec3 SDir = normalize(vec3(((SUV+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
                        if (SDistance<-0.5 || abs(dot(Pos+SDir*SDistance-PPos,Normal))>0.1 || DFBox(SUV-3.,RES-6.)>0.) continue;
                        vec3 SNor = FloatToVec3(texture(iChannel3,SUV*IRES).w)*2.-1.;
                        //Reflection direction
                        vec4 SRefShad = texture(iChannel0,SUV*IRES);
                        if (SRefShad.x<-0.5) continue;
                        vec2 SRand = ARand23(SUV*IRES*(1.+mod(CurrentFrame*7.253,9.234))).xy;
                        vec3 SRefDir = reflect(SDir,SNor);
                        float SCR = Pixel.M*min(1.,tan((HPI-acos(dot(RefDir,Normal))))); //Måste ray-tracea för Hit.y annars
                        vec3 SRDir = normalize(RandSampleCos(SRand)*TBN(SRefDir)*SCR+SRefDir);
                        vec3 HitP = Pos+SDir*SDistance+SNor*0.0015+SRDir*SRefShad.x;
                        if (dot(HitP-PPos,Normal)<=0.) continue;
                        if (sqrt(1./dot(normalize(HitP-PPos),RefDir)-1.)<=RefCR) {
                            Light += FloatToVec3(SRefShad.z)*ReflConst;
                            W += 1.;
                        }
                    }
                }
                Light = Light/W;
                Output.y = Vec3ToFloat(Light*IReflConst);
                //Shadow denoiser
                CVPos0 = vec3(RefShad.y*SunCR,0.,Distance)*TBN(Dir);
                CVPos1 = vec3(-RefShad.y*SunCR,0.,Distance)*TBN(Dir);
                LVPos0 = vec3(dot(CVPos0,Tan),dot(CVPos0,Bit),dot(CVPos0,Eye));
                LVPos1 = vec3(dot(CVPos1,Tan),dot(CVPos1,Bit),dot(CVPos1,Eye));
                Luv0 = ((LVPos0.xy/LVPos0.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                Luv1 = ((LVPos1.xy/LVPos1.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                MaxRadius = min(32.,length(Luv0-Luv1)*0.5);
                CShadow = RefShad.w*2.;
                ShadW = 2.;
                for (float x=-2.; x<2.5; x+=1.) {
                    for (float y=-2.; y<2.5; y+=1.) {
                        if (x==0. && y==0.) continue;
                        vec2 Offset2 = normalize(vec2(x,y))*max(abs(x),abs(y))*(MaxRadius*0.5);
                        vec2 SUV = floor(fragCoord+Offset2)+0.5;
                        float SDistance = texture(iChannel2,SUV*IRES).w;
                        vec3 SDir = normalize(vec3(((SUV+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
                        if (SDistance<-0.5 || abs(dot(Pos+SDir*SDistance-PPos,Normal))>0.1 || DFBox(SUV-3.,RES-6.)>0.) continue;
                        vec4 SRefShad = texture(iChannel0,SUV*IRES);
                        if (SRefShad.y<-0.5) continue;
                        vec2 SRand = ARand23(SUV*IRES*(1.+mod(CurrentFrame*7.253,9.234))).xy;
                        vec3 HitP = Pos+SDir*SDistance+normalize(RandSampleCos(SRand.xy)*TBN(SunDir)*SunCR+SunDir)*SRefShad.y;
                        if (dot(HitP-PPos,Normal)<=0.) continue;
                        CShadow += SRefShad.w;
                        ShadW += 1.;
                    }
                }
                Output.z = CShadow/ShadW;
            }
        } else {
            //Sky
        }
    } else {
        //Boundary: attributes
        if (fragCoord.y<1.) {
            if (fragCoord.x<1.) Output = vec4(iTime,texture(iChannel1,vec2(0.5)*IRES).xy,0.); //Prior frame time, time
            else if (fragCoord.x<2.) Output = iMouse; //Mouse
            else if (fragCoord.x<3.) Output = texture(iChannel1,vec2(1.5,0.5)*IRES); //Prior frame mouse
            else if (fragCoord.x<4.) Output = texture(iChannel1,vec2(2.5,0.5)*IRES); //Prior prior frame mouse
            
        }
    }
    fragColor = Output;
}