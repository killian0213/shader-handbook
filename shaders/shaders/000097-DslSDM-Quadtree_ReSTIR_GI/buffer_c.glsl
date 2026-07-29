// Buffer C (buffer) — Quadtree ReSTIR GI by Mathis
// https://www.shadertoy.com/view/DslSDM

//Spatial ReSTIR

vec4 TraceQuadTree(vec2 P, vec2 D, inout vec2 UV) {
    //Traces a ray through the quad tree
    vec2 IDir = 1./D;
    float FAR = boxfar2(P,IDir,vec2(0.5),vec2(1023.5));
    float t = 0.; float LFar=FAR; vec2 cp,fp; vec2 bb; vec4 C;
    float LOD = START_LOD;
    float LS = pow(2.,LOD);
    float ILS = pow(0.5,LOD);
    for (int i=0; i<128; i++) {
        if (t>FAR) break;
        if (t>LFar && LOD<START_LOD) {
            LOD = LOD+1.;
            LS *= 2.;
            ILS *= 0.5;
            fp = floor(cp*ILS)*LS;
            LFar = boxfar2(P,IDir,fp,fp+LS);
        }
        cp = P+D*t;
        fp = floor(cp*ILS)*LS;
        C = textureLod(iChannel3,vec3(1.,(fp+0.5*LS)*I512-1.),LOD);
        bb = box2(P,IDir,fp,fp+LS);
        if (C.w>0. && ((bb.x>=0. && bb.y>bb.x) || BoxDF(cp-fp,vec2(LS))<=0.)) {
            if (LOD==0.) {
                UV = fp+0.5;
                return vec4(C.xyz,bb.x);
            } else if (LOD>0.) {
                LFar = bb.y;
                LOD -= 1.;
                LS *= 0.5;
                ILS *= 2.;
                continue;
            }
        }
        t = bb.y+0.01;
    }
    //Return
    return vec4(-1.);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    //Diffuse spatial ReSTIR
    vec4 Attr = texture(iChannel3,vec3(1.,fragCoord*I512-1.));
    if (Attr.w<0.5) {
        //Air pixel
        //Reservoir
        vec4 CR = texture(iChannel1,fragCoord*IRES);
        vec3 CLight = FloatToVec3(CR.x,ReservoirScale);
        vec2 CMA = FloatToMAngle(CR.z);
        float CRw = max(0.,dot(CLight,vec3(0.3333)))*CMA.x*CR.w;
        //Stochastic reprojection
        int NSamples = 8;
        float SpatialRadius = 1.+texture(iChannel2,(fragCoord*(1.+mod(float(iFrame)*3.67,3.768)))*IRES).z*14.;
        float AngleDelta = 6.28318530718/float(NSamples);
        float CAngle = texture(iChannel2,(fragCoord*2.446+mod(float(iFrame)*2.44,512.))*I1024).x*AngleDelta;
        float Jacobian,wnew,np_hat; vec2 SUV,WUV,SRand,MA,SRDir,HitPos; vec3 SLight; vec4 SAttr,SR;
        for (int s=0; s<NSamples; s++) {
            //For all spatial reservoirs
            CAngle += AngleDelta;
            SUV = floor(fragCoord+vec2(sin(CAngle),cos(CAngle))*SpatialRadius)+0.5;
            if (BoxDF(SUV,iResolution.xy)>=0.) continue;
            SAttr = texture(iChannel3,vec3(1.,SUV*I512-1.));
            if (SAttr.w>0.5) continue; //Geometry pixel
            SR = texture(iChannel1,SUV*IRES);
            MA = FloatToMAngle(SR.z);
            SLight = FloatToVec3(SR.x,ReservoirScale);
            //Reservoir visibility
            SRDir = vec2(cos(MA.y),sin(MA.y));
            HitPos = SUV+SRDir*SR.y;
            if (abs(TraceQuadTree(fragCoord,normalize(HitPos-fragCoord),WUV).w-length(HitPos-fragCoord))>0.1) continue;
            //Accumulation
            Jacobian = 1.;
            np_hat = max(0.,dot(SLight,vec3(0.3333)));
            wnew = np_hat*MA.x*SR.w*max(0.0001,Jacobian);
            CRw += wnew;
            vec2 rUV = SUV+mod(float(iFrame),2048.)*vec2(3.683,4.887);
            float Randv = (texture(iChannel2,rUV*1.3*I1024).z*255.+texture(iChannel2,(rUV*2.4)*I1024).z)/256.;
            if (Randv<wnew/max(0.0001,CRw)) {
                CLight = SLight;
                CR.y = SR.y;
                CMA.y = MA.y;
            }
            CMA.x += MA.x;
        }
        //Bias correction
        float Z = CMA.x;
        float bias_p_hat = max(0.,dot(CLight,vec3(0.3333)));
        CR.w = CRw/max(0.0001,Z*bias_p_hat);
        //Output
        Output = vec4(Vec3ToFloat(CLight,IReservoirScale),CR.y,MAngleToFloat(CMA),CR.w);
    } else {
        //Geometry pixel
        Output = vec4(0.,0.,0.,-1.);
    }
    fragColor = Output;
}