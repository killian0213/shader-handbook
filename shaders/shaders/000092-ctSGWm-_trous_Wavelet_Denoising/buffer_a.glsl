// Buffer A (buffer) — Àtrous Wavelet Denoising by Mathis
// https://www.shadertoy.com/view/ctSGWm

//Secondary rays

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    if (DFBox(fragCoord-3.,RES-6.)<0.) {
        //
        //CURRENT FRAME: secondary rays
        //
        float CurrentFrame = float(iFrame-1);
        vec2 SSOffset = SSOffsets[(iFrame-1)%16];
        float CurrentTime = texture(iChannel1,vec2(0.5,0.5)*IRES).x;
        vec4 CurrentMouse = texture(iChannel1,vec2(1.5,0.5)*IRES);
        vec3 Pos = Position(CurrentMouse,CurrentTime,IRES);
        vec3 Eye = normalize(CameraCenter(CurrentMouse,CurrentTime)-Pos);
        vec3 Dir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*CFOV*ASPECT,1.)*TBN(Eye));
        float Distance = texture(iChannel2,fragCoord*IRES).w;
        if (Distance>-0.5) {
            //Geometry
            HIT Pixel = Trace(Pos+Dir*(Distance-0.01),Dir,CurrentTime); //Get attributes
            vec3 Normal = normalize(FloatToVec3(texture(iChannel3,fragCoord*IRES).w)*2.-1.);
            vec3 PPos = Pos+Dir*Distance+Normal*0.002;
            vec3 RandV = ARand23(fragCoord*IRES*(1.+mod(CurrentFrame*7.253,9.234)));
            vec4 REF = vec4(0.,0.,0.,-1.);
            vec2 SHAD = vec2(0.,-1.);
            if (Pixel.M<2.5) {
                //Reflections
                vec3 RefDir = reflect(Dir,Normal);
                float RefCR = Pixel.M*min(1.,tan((HPI-acos(dot(RefDir,Normal)))));
                vec3 RefSample = normalize(RandSampleCos(RandV.xy)*TBN(RefDir)*RefCR+RefDir);
                HIT RefHit = Trace(PPos,RefSample,CurrentTime);
                if (RefHit.M>-0.5) {
                    //Geometry
                    REF.w = RefHit.D;
                    if (RefHit.M>2.5) {
                        REF.xyz = SampleWindow(PPos,RefSample,RefHit.M);
                    } else if (PPos.x+RefSample.x*RefHit.D<3.99) {
                        //Direct
                        vec3 sPPos = PPos+RefSample*(RefHit.D-0.01);
                        if (Trace(sPPos,SunDir,CurrentTime).M>2.5)
                            REF.xyz = SunLight*RefHit.DC*(dot(-RefSample,SunDir)*0.5+0.5);
                        //Indirect
                        sPPos = PPos+RefSample*RefHit.D;
                        vec3 IL = vec3(0.);
                        if (!(sPPos.y<0.001 && -RefSample.y>0.99)) {
                            IL += vec3(0.2,0.1,0.04)*1.5*
                                    (SolidAngle(sPPos,-RefSample,vec3(4.,0.,2.),vec3(4.,0.,1.),vec3(2.,0.,2.))+
                                    SolidAngle(sPPos,-RefSample,vec3(1.8,0.,1.),vec3(0.,0.,1.2),vec3(0.,0.,4.))+
                                    SolidAngle(sPPos,-RefSample,vec3(2.,0.,4.),vec3(0.,0.,1.2),vec3(0.,0.,4.))
                                    );
                        }
                        if (!(sPPos.z>3.999 && -RefSample.z<-0.99)) {
                            IL += vec3(1.,0.2,0.2)*0.7*
                                    (SolidAngle(sPPos,-RefSample,vec3(1.,0.,4.),vec3(0.,0.,4.),vec3(1.,1.5,4.)));
                        }
                        REF.xyz += IL/(2.*PI);
                    }
                } else {
                    //Sky
                    REF = vec4(0.,0.,0.,100000.);
                }
                //Shadows
                vec3 ShadSample = normalize(RandSampleCos(RandV.xy)*TBN(SunDir)*SunCR+SunDir);
                if (dot(ShadSample,Normal)>0. && PPos.x<4.01) {
                    HIT ShadHit = Trace(PPos,ShadSample,CurrentTime);
                    SHAD.y = ShadHit.D;
                    if (ShadHit.M>2.5) SHAD.x = 1.;
                }
            }
            //Output
            Output = vec4(REF.w,SHAD.y,Vec3ToFloat(REF.xyz*IReflConst),SHAD.x);
        } else {
            //Sky
            Output = vec4(-1.,-1.,0.,0.);
        }
    }
    fragColor = Output;
}