// Buffer B (buffer) — Minecraft + LPV GI by Mathis
// https://www.shadertoy.com/view/ctV3WG

//Denoising pass 1

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(-1.);
    if (iFrame>1 && DFBox(fragCoord-1.,RES-2.)<0.) {
        //G-Buffer
        float CurrentFrame = float(iFrame);
        vec2 SSOffset = ARand23(vec2(CurrentFrame*0.2673,CurrentFrame*0.1736)).xy-0.5;
        vec3 SunDir = texture(iChannel0,vec2(5.5,0.5)*IRES).xyz;
        vec3 Pos = texture(iChannel0,vec2(3.5,0.5)*IRES).xyz;
        vec3 Eye = texture(iChannel0,vec2(2.5,0.5)*IRES).xyz;
        vec3 Tan; vec3 Bit = TBN(Eye,Tan);
        mat3 EyeMat = TBN(Eye);
        vec3 Dir = normalize(vec3(((fragCoord+SSOffset)*IRES*2.-1.)*(ASPECT*CFOV),1.)*EyeMat);
        //Sample attributes
        vec4 CAttr = texture(iChannel0,fragCoord*IRES);
        if (min(CAttr.w,CAttr.z)>-0.5) {
            //Geometry
            vec3 Normal = FloatToVec3(CAttr.z)*2.-1.;
            float Dist = CAttr.w;
            vec3 PPos = Pos+Dir*Dist+Normal*0.0001;
            
            
            //
            //Reflections denoising
            //
            vec4 RefC = vec4(FloatToVec3(CAttr.x)*LightCoeff*2.,2.);
            vec3 RefDir = reflect(Dir,Normal);
            float RefCR = 0.2*min(1.,tan((HPI-acos(dot(RefDir,Normal)))));
            vec3 CVPos0 = vec3(CAttr.y*RefCR,0.,CAttr.y+CAttr.w)*TBN(Dir);
            vec3 CVPos1 = vec3(-CAttr.y*RefCR,0.,CAttr.y+CAttr.w)*TBN(Dir);
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
                    if (min(SC.w,SC.z)<-0.5 || DFBox(SUV-vec2(0.,1.),RES-vec2(0.,1.))>0.) continue;
                    vec2 SRand = ARand23(SUV*IRES*(1.+mod(CurrentFrame*7.253,9.234))).xy;
                    vec3 SRefDir = reflect(SDir,SNormal);
                    float SCR = 0.2*min(1.,tan((HPI-acos(dot(RefDir,Normal)))));
                    vec3 SRDir = normalize(RandSampleCos(SRand)*TBN(SRefDir)*SCR+SRefDir);
                    vec3 HitP = Pos+SDir*SC.w+SNormal*0.0001+SRDir*SC.y;
                    if (dot(HitP-PPos,Normal)<=0.) continue;
                    if (sqrt(1./dot(normalize(HitP-PPos),RefDir)-1.)<=RefCR) RefC += vec4(FloatToVec3(SC.x)*LightCoeff,1.);
                }
            }
            Output.xyz = RefC.xyz /= RefC.w;
        }
    }
    fragColor = Output;
}