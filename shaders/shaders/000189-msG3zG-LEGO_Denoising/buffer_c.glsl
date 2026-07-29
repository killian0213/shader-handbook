// Buffer C (buffer) — LEGO Denoising by Mathis
// https://www.shadertoy.com/view/msG3zG

//Denoising

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    if (fragCoord.y>1.) {
        float CurrentFrame = float(iFrame);
        vec2 SSOffset = SSOffsets[iFrame%16];
        vec3 SunDir = texture(iChannel0,vec2(8.5,0.5)*IRES).xyz;
        vec3 Pos = texture(iChannel0,vec2(7.5,0.5)*IRES).xyz;
        vec3 Eye = texture(iChannel0,vec2(6.5,0.5)*IRES).xyz;
        vec3 Tan; vec3 Bit = TBN(Eye,Tan);
        mat3 EyeMat = TBN(Eye);
        vec3 LPos = texture(iChannel0,vec2(10.5,0.5)*IRES).xyz;
        vec3 LEye = texture(iChannel0,vec2(9.5,0.5)*IRES).xyz;
        vec3 LTan; vec3 LBit = TBN(LEye,LTan);
        vec3 Dir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
        vec4 CAttr = texture(iChannel0,fragCoord*IRES);
        if (CAttr.w>-0.5) {
            //Geometry
            vec3 PPos = Pos+Dir*CAttr.w;
            vec3 Normal = normalize(FloatToVec3(CAttr.z)*2.-1.);
            vec4 LWPass = texture(iChannel1,fragCoord*IRES);
            //
            //Reflections denoising
            //
            vec4 RefC = vec4(FloatToVec3(LWPass.z)*LightCoeff*2.,2.);
            vec3 RefDir = reflect(Dir,Normal);
            float RefCR = RefMaterial*min(1.,tan((HPI-acos(dot(RefDir,Normal)))));
            vec3 CVPos0 = vec3(LWPass.w*RefCR,0.,CAttr.w+LWPass.w)*TBN(Dir);
            vec3 CVPos1 = vec3(-LWPass.w*RefCR,0.,CAttr.w+LWPass.w)*TBN(Dir);
            vec3 LVPos0 = vec3(dot(CVPos0,Tan),dot(CVPos0,Bit),dot(CVPos0,Eye));
            vec3 LVPos1 = vec3(dot(CVPos1,Tan),dot(CVPos1,Bit),dot(CVPos1,Eye));
            vec2 Luv0 = ((LVPos0.xy/LVPos0.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
            vec2 Luv1 = ((LVPos1.xy/LVPos1.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
            float HalfRadius = min(32.,length(Luv0-Luv1)*0.5)*0.5;
            for (float x=-2.; x<2.5; x+=1.) {
                for (float y=-2.; y<2.5; y+=1.) {
                    if (x==0. && y==0.) continue;
                    vec2 Offset2 = normalize(vec2(x,y))*max(abs(x),abs(y))*HalfRadius;
                    vec2 SUV = floor(fragCoord+Offset2)+0.5;
                    vec4 SC = texture(iChannel0,SUV*IRES);
                    vec3 SNormal = normalize(FloatToVec3(SC.z)*2.-1.);
                    vec3 SDir = normalize(vec3(((SUV+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
                    if (SC.w<-0.5 || DFBox(SUV-vec2(0.,1.),RES-vec2(0.,1.))>0.) continue;
                    vec4 SRefShad = texture(iChannel1,SUV*IRES);
                    vec2 SRand = ARand23(SUV*IRES*(1.+mod(CurrentFrame*7.253,9.234))).xy;
                    vec3 SRefDir = reflect(SDir,SNormal);
                    float SCR = RefMaterial*min(1.,tan((HPI-acos(dot(RefDir,Normal)))));
                    vec3 SRDir = normalize(RandSampleCos(SRand)*TBN(SRefDir)*SCR+SRefDir);
                    vec3 HitP = Pos+SDir*SC.w+SNormal*0.01+SRDir*SRefShad.w;
                    if (dot(HitP-PPos,Normal)<=0.) continue;
                    if (sqrt(1./dot(normalize(HitP-PPos),RefDir)-1.)<=RefCR) RefC += vec4(FloatToVec3(SRefShad.z)*LightCoeff,1.);
                }
            }
            RefC.xyz /= RefC.w;
            Output.w = Vec3ToFloat(RefC.xyz*ILightCoeff);
            //
            //Shadow denoising
            //
            vec2 Shad = vec2(float(LWPass.y>999.)*2.,2.);
            CVPos0 = vec3(LWPass.y*SunCR,0.,CAttr.w)*TBN(Dir);
            CVPos1 = vec3(-LWPass.y*SunCR,0.,CAttr.w)*TBN(Dir);
            LVPos0 = vec3(dot(CVPos0,Tan),dot(CVPos0,Bit),dot(CVPos0,Eye));
            LVPos1 = vec3(dot(CVPos1,Tan),dot(CVPos1,Bit),dot(CVPos1,Eye));
            Luv0 = ((LVPos0.xy/LVPos0.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
            Luv1 = ((LVPos1.xy/LVPos1.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
            HalfRadius = max(1.2,min(32.,length(Luv0-Luv1)*0.5)*0.5);
            for (float x=-2.; x<2.5; x+=1.) {
                for (float y=-2.; y<2.5; y+=1.) {
                    if (x==0. && y==0.) continue;
                    vec2 Offset2 = normalize(vec2(x,y))*max(abs(x),abs(y))*HalfRadius;
                    vec2 SUV = floor(fragCoord+Offset2)+0.5;
                    vec4 SC = texture(iChannel0,SUV*IRES);
                    vec3 SNormal = normalize(FloatToVec3(SC.z)*2.-1.);
                    vec3 SDir = normalize(vec3(((SUV+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
                    if (SC.w<-0.5 || DFBox(SUV-vec2(0.,1.),RES-vec2(0.,1.))>0. || abs(dot(Pos+SDir*SC.w-PPos,Normal))>0.19) continue;
                    vec4 SLWPass = texture(iChannel1,SUV*IRES);
                    vec2 SRand = ARand23(SUV*IRES*(1.+mod(CurrentFrame*7.253,9.234))).xy;
                    vec3 HitP = Pos+SDir*SC.w+SNormal*0.01+normalize(RandSampleCos(SRand.xy)*TBN(SunDir)*SunCR+SunDir)*SLWPass.y;
                    if (dot(HitP-PPos,Normal)<=0.) continue;
                    if (sqrt(1./dot(normalize(HitP-PPos),SunDir)-1.)<=SunCR) Shad += vec2(float(SLWPass.y>999.),1.);
                }
            }
            Output.z = Shad.x/Shad.y;
            //
            //SVGF denoising
            //
            vec2 Moments;
            LVPos0 = PPos-LPos;
            LVPos0 = vec3(dot(LVPos0,LTan),dot(LVPos0,LBit),dot(LVPos0,LEye));
            vec2 MoLuv = ((LVPos0.xy/LVPos0.z)*0.5/(ASPECT*CFOV)+0.5)*RES-SSOffsets[(iFrame-1)%16];
            if (DFBox(MoLuv-vec2(0.,1.),RES-vec2(0.,1.))>0.) {
                Moments = vec2(10.,0.);
            } else {
                Moments = texture(iChannel2,MoLuv*IRES).zw;
            }
            float Variance = abs(Moments.y-Moments.x*Moments.x);
            vec3 CLight = FloatToVec3(LWPass.x)*LightCoeff;
            vec4 IDLight = vec4(CLight*2.,2.);
            for (float x=-2.; x<2.5; x+=1.) {
                for (float y=-2.; y<2.5; y+=1.) {
                    if (x==0. && y==0.) continue;
                    vec2 SUV = floor(fragCoord+vec2(x,y)*4.)+0.5;
                    vec4 SC = texture(iChannel0,SUV*IRES);
                    vec3 SNormal = normalize(FloatToVec3(SC.z)*2.-1.);
                    vec3 SDir = normalize(vec3(((SUV+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
                    if (SC.w<-0.5 || DFBox(SUV-vec2(0.,1.),RES-vec2(0.,1.))>0.) continue;
                    vec2 SC2 = texture(iChannel1,SUV*IRES).xy;
                    vec3 SLight = FloatToVec3(SC2.x)*LightCoeff;
                    float SWeight = exp(-abs(dot(Pos+SDir*SC.w-PPos,Normal))*20.)*
                                   max(0.,dot(SNormal,Normal)*2.-1.)*exp(-length(CLight-SLight)/(0.1+VarCoeff*Variance));
                    IDLight += vec4(SLight,1.)*SWeight;
                }
            }
            IDLight.xyz /= IDLight.w;
            Output.xy = vec2(Vec2ToFloat(IDLight.xy*ILightCoeff),IDLight.z);
        }
    }
    //Output
    fragColor = Output;
}