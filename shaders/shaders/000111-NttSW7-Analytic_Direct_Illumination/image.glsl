// Image (image) — Analytic Direct Illumination by Mathis
// https://www.shadertoy.com/view/NttSW7

/*
Analytic global illumination
    The visibility term creates discontinuity in the integral, so instead of integrating
    over the whole scene, we only integrate over visible geometry
        These integrals are continuous and can be expressed analytically, giving the exact single-bounce solution.
    
Limitations:
    This implementation only works with lines without thickness
    I did not allow intersecting lines, they would make the visibility step more complex




Controls:
    Click near the endpoints of a line to change them
        Click on the middle of a line to move the entire line
        The interact-radius can be changed with the variable "InteractRadius"
    Comment out "#define Sun" to remove the sun
    All colors and sun-attributes can be changed in the Common-tab
    Key "r" to reset the scene
    Key "a" to stop animations
*/

vec3 Integral(vec2 P) {
    //Computes the light integral
    float TotalGeometryAngle = 0.;
    vec3 I = vec3(0.);
    int NVParts; float A1,A2,p0,p1,Len;
    vec2 CX,CY,Tan,UNor,Nor,TanF; vec4 clinep,linep;
    vec3 VParts[int(NObjects)+1];
    //Sky and emissive integration
    for (float i=0.; i<NObjects; i++) {
        //For each line
        NVParts = 1;
        clinep = texture(iChannel0,vec2(1.5+i,0.5)*IRES);
        //Create coordinate system
        Len = length(clinep.zw-clinep.xy);
        TanF = clinep.zw-clinep.xy;
        Tan = TanF/Len;
        UNor = vec2(-Tan.y,Tan.x);
        Nor = vec2(Tan.y,-Tan.x);
        float NorSign = sign(dot(Nor,P-clinep.xy));
        if (NorSign==0.) continue; //Parallel
        Nor *= NorSign;
        //Coordinate system to clinep.xy
        CX = normalize(clinep.xy-P);
        CY = vec2(-CX.y,CX.x);
        CY *= max(0.,sign(dot(CY,clinep.zw-P)))*2.-1.;
        //Emission
        float Emissive = float(i==5.);
        VParts[0] = vec3(0.,Len,Emissive);
        for (float s=0.; s<NObjects; s++) {
            //For each other line
            if (s==i) continue;
            linep = texture(iChannel0,vec2(1.5+s,0.5)*IRES);
            //Order
            A1 = atan(dot(CY,linep.xy-P),dot(CX,linep.xy-P));
            A2 = atan(dot(CY,linep.zw-P),dot(CX,linep.zw-P));
            if (A2<A1) linep = linep.zwxy;
            //Occlusion check
            vec2 LTan = linep.xy-linep.zw;
            vec2 LNorm = vec2(LTan.y,-LTan.x);
            LNorm = LNorm*sign(dot(P-linep.xy,LNorm));
            float CompDot = dot(clinep.xy-linep.xy,LNorm);
            if (CompDot==0. || max(0.,sign(CompDot))!=max(0.,sign(dot(clinep.zw-linep.xy,LNorm)))) {
                //Test linep against clinep instead
                CompDot = -dot(linep.xy-clinep.xy,Nor);
            }
            if (CompDot<0.) {
                //linep might occlude clinep
                float t0 = -dot(P-clinep.xy,Nor)*((dot(linep.xy-P,Nor)==0.)?1000000.:1./dot(linep.xy-P,Nor));
                float t1 = -dot(P-clinep.xy,Nor)*((dot(linep.zw-P,Nor)==0.)?1000000.:1./dot(linep.zw-P,Nor));
                if (t0>0. || t1>0.) {
                    //One of the extended lines have a valid intersection
                    p0 = dot(Tan,P+t0*(linep.xy-P)-clinep.xy);
                    p1 = dot(Tan,P+t1*(linep.zw-P)-clinep.xy);
                    if (t0<0.) {
                        p0 = ((dot(Tan,LNorm)>0.)?-1.:Len+1.);
                    } else if (t1<0.) {
                        p1 = ((dot(Tan,LNorm)>0.)?-1.:Len+1.);
                    }
                    if (p1<p0) { float tmp = p0; p0 = p1; p1 = tmp; }
                    int tmpNVParts = NVParts;
                    for (int vpi=0; vpi<tmpNVParts; vpi++) {
                        //For each visible part
                        vec3 CVP = VParts[vpi];
                        if (CVP.x<0.) continue;
                        if (p0<CVP.x && p1>CVP.y) {
                            //All is occluded
                            VParts[vpi] = vec3(-1.,-1.,0.);
                        } else if (p0>CVP.x && p0<CVP.y && p1>CVP.y) {
                            //Lower part is occluded
                            VParts[vpi] = vec3(CVP.x,p0,Emissive);
                        } else if (p1<CVP.y && p1>CVP.x && p0<CVP.x) {
                            //Upper part is occluded
                            VParts[vpi] = vec3(p1,CVP.y,Emissive);
                        } else if (p1<CVP.y && p0>CVP.x) {
                            //Middle part is occluded
                            VParts[vpi] = vec3(CVP.x,p0,Emissive);
                            VParts[NVParts] = vec3(p1,CVP.y,Emissive);
                            NVParts += 1;
                        }
                    }
                }
            }
        }
        //First integral
        float Y = dot(Nor,P-clinep.xy);
        float Z = dot(Tan,P-clinep.xy);
        for (int ai=0; ai<NVParts; ai++) {
            vec3 VA = VParts[ai];
            if (VA.x<-0.5) continue;
            if (VA.x>VA.y) VA.xy = VA.yx;
            //Total angle
            vec2 lp0 = clinep.xy+Tan*VA.x-P;
            vec2 lp1 = clinep.xy+Tan*VA.y-P;
            vec2 A12 = vec2(atan(-lp0.y,-lp0.x)+PI,atan(-lp1.y,-lp1.x)+PI);
            if (A12.x>A12.y) A12 = A12.yx;
            if (A12.y-A12.x<PI) {
                I.xyz -= SkyIntegral(A12.x,A12.y);
                if (VA.z>0.5) I.xyz += EmissiveColor*(A12.y-A12.x);
            } else {
                I.xyz -= SkyIntegral(0.,A12.x);
                I.xyz -= SkyIntegral(A12.y,PI2);
                if (VA.z>0.5) I.xyz += EmissiveColor*(A12.x+(PI2-A12.y));
            }
            //Emissive
        }
    }
    //Sky integral
    I += SkyIntegral(0.,PI2);
    //Return
    return max(vec3(0.),I/(2.*PI));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    //Integrate
    vec3 Color = Integral(fragCoord);
    //Render geometry
    vec4 GeoC = RenderGeometry(fragCoord,iChannel0,IRES);
    Color = mix(Color,GeoC.xyz,GeoC.w);
    //Return
    fragColor = vec4(pow(1.-exp(-1.2*Color),vec3(0.45)),1.);
}