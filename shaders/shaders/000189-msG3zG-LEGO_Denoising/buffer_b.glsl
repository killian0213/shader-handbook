// Buffer B (buffer) — LEGO Denoising by Mathis
// https://www.shadertoy.com/view/msG3zG

//Denoising + tracing reflections and shadows

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
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
    float FAR = ABox(P,1./D,vec3(0.),vec3(8.,6.4,21.)).y;
    float t = 0.; float dfs = 10000.;
    //if (P.y>6.399) {
    //    if (D.y>=0.) return OUT;
    //    t = -(P.y-6.399)/D.y;
    //}
    for (int i=0; i<384; i++) {
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
            //
            //Shadows
            //
            float ShadowLen = -1.;
            vec3 RandV = ARand23(fragCoord*IRES*(1.+mod(CurrentFrame*7.253,9.234)));
            vec3 RandDir = normalize(RandSampleCos(RandV.xy)*TBN(SunDir)*SunCR+SunDir);
            if (dot(Normal,RandDir)>0.) {
                HIT ShadHit = Trace(PPos+Normal*0.01,RandDir,iTime);
                ShadowLen = ((ShadHit.C.x<0.)?10000.:ShadHit.D);
            }
            Output.y = ShadowLen;
            //
            //Reflections
            //
            vec3 RefC = vec3(0.);
            float RefDist = -1.;
            vec3 RefDir = reflect(Dir,Normal);
            float RefCR = RefMaterial*min(1.,tan((HPI-acos(dot(RefDir,Normal)))));
            RandDir = normalize(RandSampleCos(RandV.xy)*TBN(RefDir)*RefCR+RefDir);
            if (dot(RandDir,Normal)<0.) RandDir = reflect(RandDir,Normal);
            HIT Sample = Trace(PPos+Normal*0.01,RandDir,iTime);
            if (Sample.C.x>=0.) {
                //Geometry
                RefDist = Sample.D;
                //Screen space test
                vec3 SSPos = PPos+RandDir*Sample.D-LPos;
                SSPos = vec3(dot(SSPos,LTan),dot(SSPos,LBit),dot(SSPos,LEye));
                vec2 Luv = ((SSPos.xy/SSPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES-SSOffsets[(iFrame-1)%16];
                float Weight = 0.;
                vec3 SSLight = vec3(0.);
                float SSDF = DFBox(Luv-vec2(0.,1.),RES-vec2(0.,1.));
                if (SSPos.z>0. && SSDF<0.) {
                    SSPos = PPos+RandDir*Sample.D-Pos;
                    SSPos = vec3(dot(SSPos,Tan),dot(SSPos,Bit),dot(SSPos,Eye));
                    vec2 CUV = ((SSPos.xy/SSPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
                    vec4 SSC = texture(iChannel0,(floor(CUV)+0.5)*IRES);
                    Weight = max(0.,dot(normalize(FloatToVec3(SSC.z)*2.-1.),Sample.N)*10.-9.)*
                             clamp(1.-SSDF*0.1,0.,1.)*float(length(SSPos)-SSC.w<0.2);
                    vec2 SSC2 = texture(iChannel2,(floor(Luv)+0.5)*IRES).xy;
                    SSLight = Sample.C*vec3(FloatToVec2(SSC2.x)*10.,SSC2.y);
                }
                vec3 WLight = vec3(0.);
                if (dot(Sample.N,SunDir)>0.)
                    WLight = Sample.C*SunLight*(dot(Sample.N,SunDir)*
                            float(Trace(PPos+RandDir*Sample.D+Sample.N*0.01,SunDir,iTime).C.x<0.));
                RefC += mix(WLight,SSLight,Weight);
            } else {
                //Sky
                RefDist = 10000.;
                RefC += SampleSky(RandDir,SunDir,iTime);
            }
            Output.z = Vec3ToFloat(RefC*ILightCoeff);
            Output.w = RefDist;
            //
            //SVGF denoising
            //
            vec2 Moments;
            vec3 LVPos0 = PPos-LPos;
            LVPos0 = vec3(dot(LVPos0,LTan),dot(LVPos0,LBit),dot(LVPos0,LEye));
            vec2 MoLuv = ((LVPos0.xy/LVPos0.z)*0.5/(ASPECT*CFOV)+0.5)*RES-SSOffsets[(iFrame-1)%16];
            if (DFBox(MoLuv-vec2(0.,1.),RES-vec2(0.,1.))>0.) {
                Moments = vec2(10.,0.);
            } else {
                Moments = texture(iChannel2,MoLuv*IRES).zw;
            }
            float Variance = abs(Moments.y-Moments.x*Moments.x);
            vec3 CLight = vec3(FloatToVec2(CAttr.x)*LightCoeff,CAttr.y);
            vec4 IDLight = vec4(CLight*2.,2.);
            for (float x=-2.; x<2.5; x+=1.) {
                for (float y=-2.; y<2.5; y+=1.) {
                    if (x==0. && y==0.) continue;
                    vec2 SUV = floor(fragCoord+vec2(x,y)*16.)+0.5;
                    vec4 SC = texture(iChannel0,SUV*IRES);
                    vec3 SNormal = normalize(FloatToVec3(SC.z)*2.-1.);
                    vec3 SDir = normalize(vec3(((SUV+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
                    if (SC.w<-0.5 || DFBox(SUV-vec2(0.,1.),RES-vec2(0.,1.))>0.) continue;
                    vec3 SLight = vec3(FloatToVec2(SC.x)*LightCoeff,SC.y);
                    float SWeight = float(abs(dot(Pos+SDir*SC.w-PPos,Normal))<0.05)*
                                   max(0.,dot(SNormal,Normal)*2.-1.)*exp(-length(CLight-SLight)/(0.1+VarCoeff*Variance));
                    IDLight += vec4(SLight,1.)*SWeight;
                }
            }
            IDLight.xyz /= IDLight.w;
            Output.x = Vec3ToFloat(IDLight.xyz*ILightCoeff);
        }
    }
    //Output
    fragColor = Output;
}