// Buffer B (buffer) — Quadtree ReSTIR GI by Mathis
// https://www.shadertoy.com/view/DslSDM

//Temporal ReSTIR

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
    vec3 NLight = vec3(0.);
    float Frame = texture(iChannel0,vec2(2.5,0.5)*IRES).y;
    if (Frame>0.5 && max(fragCoord.x,fragCoord.y)<1024.) {
        //Inside the scene
        vec4 Attr = texture(iChannel3,vec3(1.,fragCoord*I512-1.));
        if (Attr.w>0.5) {
            //Geometry
            Output = vec4(Attr.xyz,-1.);
        } else {
            //Air pixels
            vec2 RUV;
            vec4 LR = texture(iChannel1,fragCoord*IRES);
            if (iFrame%3==0) {
                //Sample validation
                vec2 MA = FloatToMAngle(LR.z);
                vec2 RDir = vec2(cos(MA.y),sin(MA.y));
                vec4 RHit = TraceQuadTree(fragCoord,RDir,RUV);
                float PTDist = 10000.;
                if (RHit.w>-0.5) {
                    //Geometry
                    PTDist = RHit.w;
                    if (RHit.x>1.) {
                        //Emissive
                        NLight += RHit.xyz-1.;
                    } else {
                        //Second bounce
                        #ifdef SecondBounce
                        vec2 SNor = boxNormal(fragCoord,1./RDir,RUV-0.5,RUV+0.5);
                        float SRA = texture(iChannel2,(RUV+MA.y*157.1278)*I1024).y*PI;
                        vec2 SRDir = normalize(sin(SRA)*SNor+cos(SRA)*vec2(-SNor.y,SNor.x));
                        vec2 SRUV;
                        vec4 SRHit = TraceQuadTree(RUV+SNor,SRDir,SRUV);
                        if (SRHit.w>-0.5) NLight += ((SRHit.x>1.)?SRHit.xyz-1.:vec3(0.))*0.5;
                        else NLight += SampleSky(SRDir)*0.5;
                        NLight *= RHit.xyz;
                        #endif
                    }
                } else {
                    //Sky
                    NLight += SampleSky(RDir);
                }
                //Sample test
                if (length(FloatToVec3(LR.x,ReservoirScale)-NLight)>0.1) {
                    //Invalid sample
                    Output = vec4(Vec3ToFloat(NLight,IReservoirScale),PTDist,MAngleToFloat(vec2(1.,MA.y))*0.+LR.y,LR.w);
                } else {
                    //Valid sample
                    Output = LR;
                }
            } else {
                //Temporal ReSTIR
                vec2 RandUV = (fragCoord+Frame*vec2(67.293,73.475))*I1024;
                float RA = (texture(iChannel2,RandUV).y*255.+texture(iChannel2,RandUV).x)*I256*PI2;
                vec2 RDir = vec2(cos(RA),sin(RA));
                vec4 RHit = TraceQuadTree(fragCoord,RDir,RUV);
                float PTDist = 10000.;
                if (RHit.w>-0.5) {
                    //Geometry
                    PTDist = RHit.w;
                    if (RHit.x>1.) {
                        //Emissive
                        NLight += RHit.xyz-1.;
                    } else {
                        //Second bounce
                        #ifdef SecondBounce
                        vec2 SNor = boxNormal(fragCoord,1./RDir,RUV-0.5,RUV+0.5);
                        float SRA = texture(iChannel2,(RUV+RA*157.1278)*I1024).y*PI;
                        vec2 SRDir = normalize(sin(SRA)*SNor+cos(SRA)*vec2(-SNor.y,SNor.x));
                        vec2 SRUV;
                        vec4 SRHit = TraceQuadTree(RUV+SNor,SRDir,SRUV);
                        if (SRHit.w>-0.5) NLight += ((SRHit.x>1.)?SRHit.xyz-1.:vec3(0.))*0.5;
                        else NLight += SampleSky(SRDir)*0.5;
                        NLight *= RHit.xyz;
                        #endif
                    }
                } else {
                    //Sky
                    NLight += SampleSky(RDir);
                }
                //Update reservoir
                if (LR.w<-0.5) {
                    //New reservoir
                    LR = vec4(Vec3ToFloat(NLight,IReservoirScale),PTDist,MAngleToFloat(vec2(1.,RA)),1.);
                } else {
                    //Old reservoir
                    float Rand1 = (texture(iChannel2,RandUV).z*255.+texture(iChannel2,RandUV*1.478).z)/256.;
                    float w = max(0.,dot(NLight,vec3(0.3333))); //Target pdf
                    vec2 MA = FloatToMAngle(LR.z);
                    MA.x = min(MA.x,M_CLAMP_T-1.); //Clamping
                    vec3 LLight = FloatToVec3(LR.x,ReservoirScale);
                    float Rw = max(0.,dot(LLight,vec3(0.3333)))*MA.x*LR.w+w; //R.w += w
                    if (Rand1<w/max(0.0001,Rw)) {
                        //New sample
                        LLight = NLight;
                        MA.y = RA;
                        LR.x = Vec3ToFloat(NLight,IReservoirScale);
                        LR.y = PTDist;
                    }
                    MA.x += 1.; //M += 1
                    float p_hat = max(0.,dot(LLight,vec3(0.3333))); //p hat
                    LR.w = Rw/max(0.0001,MA.x*p_hat); //Update W
                    LR.z = MAngleToFloat(MA);
                }
                //Output
                Output = LR;
            }
        }
    } else Output = vec4(0.,0.,0.,-1.);
    //Return
    fragColor = Output;
}