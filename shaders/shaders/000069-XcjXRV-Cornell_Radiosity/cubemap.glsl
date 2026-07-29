// Cube A (cubemap) — Cornell Radiosity by Mathis
// https://www.shadertoy.com/view/XcjXRV

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return textureLod(iChannel3,D,0.);
}

vec4 textureCube(vec2 UV, float LOD) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return textureLod(iChannel3,D,LOD);
}

void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir) {
    vec4 Output = texture(iChannel3,rayDir);
    vec2 UV; vec3 aDir = abs(rayDir);
    if (aDir.z>max(aDir.x,aDir.y)) {
        //Z-side
        UV = floor(((rayDir.xy/aDir.z)*0.5+0.5)*1024.)+0.5;
        if (rayDir.z<0.) UV.y += 1024.;
    } else if (aDir.x>aDir.y) {
        //X-side
        UV = floor(((rayDir.yz/aDir.x)*0.5+0.5)*1024.)+0.5;
        if (rayDir.x>0.) UV.y += 2048.;
        else UV.y += 3072.;
    } else {
        //Y-side
        UV = floor(((rayDir.xz/aDir.y)*0.5+0.5)*1024.)+0.5;
        if (rayDir.y>0.) UV.y += 4096.;
        else UV.y += 5120.;
    }
    if (UV.y<4096.) {
        Output = vec4(0.);
        //Patch attributes
        float CurrentFrame = float(iFrame);
        float PatchIndex = floor(UV.x*I32)+floor(UV.y*I32)*32.;
        vec2 PatchUV = vec2(floor(mod(PatchIndex+0.5,64.))+0.5,floor((PatchIndex+0.5)*I64)+0.5);
        vec4 PatchAttr = texture(iChannel0,PatchUV*IRES);
        if (PatchAttr.w>-0.5) {
            //Valid current patch
            vec3 PatchP = texture(iChannel0,(PatchUV+vec2(64.,0.))*IRES).xyz;
            vec3 PatchN = normalize(floatToVec3(PatchAttr.y)*2.-1.);
            vec2 SPatchUVFloor = floor(mod(UV,32.))*2.;
            for (float uvx=0.5; uvx<2.; uvx++) {
                for (float uvy=0.5; uvy<2.; uvy++) {
                    vec3 SLight = vec3(0.);
                    vec2 SPatchUV = SPatchUVFloor+vec2(uvx,uvy);
                    vec4 SPatchAttr = texture(iChannel0,SPatchUV*IRES);
                    if (SPatchAttr.w>-0.5) {
                        vec3 SPatchP = texture(iChannel0,(SPatchUV+vec2(64.,0.))*IRES).xyz;
                        vec3 SPatchN = normalize(floatToVec3(SPatchAttr.y)*2.-1.);
                        vec3 SRP = SPatchP-PatchP;
                        if (dot(SRP,SRP)>0.0005 && min(dot(SRP,PatchN),dot(-SRP,SPatchN))>0.) {
                            //Potentially visible
                            if (Trace(PatchP,normalize(SRP),iTime).v.z<length(SRP)-I1024) {
                                //At least partially occluded
                                continue;
                            }
                            //Direct light
                            SLight += texture(iChannel1,SPatchUV*IRES).xyz;
                            //Temporal indirect light (0.97 factor is used to reduce 1 sample visibility bias)
                            float PixelIndex = floor(SPatchUV.x)+floor(SPatchUV.y)*64.;
                            vec2 PixelIndexUV = vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.;
                            SLight += textureCube(PixelIndexUV,5.).xyz*0.97;
                            //Formfactor
                            vec3 STan; vec3 SBit = TBN(SPatchN,STan);
                            vec3 sp0 = SPatchP+(-STan-SBit)*I48;
                            vec3 sp1 = SPatchP+(STan-SBit)*I48;
                            vec3 sp2 = SPatchP+(STan+SBit)*I48;
                            vec3 sp3 = SPatchP+(-STan+SBit)*I48;
                            sp0 -= PatchN*min(0.,dot(PatchN,sp0-PatchP));
                            sp1 -= PatchN*min(0.,dot(PatchN,sp1-PatchP));
                            sp2 -= PatchN*min(0.,dot(PatchN,sp2-PatchP));
                            sp3 -= PatchN*min(0.,dot(PatchN,sp3-PatchP));
                            float FormFactor = max(0.,IntegrateQuad(PatchP,PatchN,sp0,sp1,sp2,sp3));
                            Output.xyz += SLight*floatToVec3(SPatchAttr.z)*FormFactor;
                        }
                    }
                }
            }
            //Formfactor constant
            Output.xyz *= 1024.*IPI*0.5;
        }
    } else discard;
    //Output
    fragColor = Output;
}