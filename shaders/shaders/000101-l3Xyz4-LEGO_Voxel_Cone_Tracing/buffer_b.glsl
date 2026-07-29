// Buffer B (buffer) — LEGO Voxel Cone Tracing by Mathis
// https://www.shadertoy.com/view/l3Xyz4

//Voxel cone tracing

vec4 textureCube(vec2 uv, float lod) {
    //Samples the cubemap
    float tcSign = -mod(floor(uv.y*I1024), 2.)*2. + 1.;
    vec3 tcD = vec3(vec2(uv.x, mod(uv.y, 1024.))*I512 - 1., tcSign);
    if (uv.y > 4096.) tcD = tcD.xzy;
    else if (uv.y > 2048.) tcD = tcD.zxy;
    return textureLod(iChannel3, tcD, lod);
}

vec4 vct_sample0(vec3 vp5, vec3 dir, vec3 dirSqr, float fwd) {
    //Samples VCT volume - LOD 0
    vec3 vp5c = clamp(vp5, vec3(0.5), vec3(79.5, 31.5, 31.5));
    vec2 vUV0 = vec2(vp5c.x + floor(mod(vp5c.y - 0.5, 12.))*80., vp5c.z + floor((vp5c.y - 0.5)/12.)*32.);
    vec2 vUV1 = vec2(vp5c.x + floor(mod(vp5c.y + 0.5, 12.))*80., vp5c.z + floor((vp5c.y + 0.5)/12.)*32.);
    float offsetX = max(0., -sign(dir.x)*96.);
    vec4 vSampleX = mix(textureCube(vUV0 + vec2(0., 4480. + offsetX), 0.),
                        textureCube(vUV1 + vec2(0., 4480. + offsetX), 0.), fract(vp5c.y + 0.5));
    float offsetY = max(0., -sign(dir.y)*96.);
    vec4 vSampleY = mix(textureCube(vUV0 + vec2(0., 4672. + offsetY), 0.),
                        textureCube(vUV1 + vec2(0., 4672. + offsetY), 0.), fract(vp5c.y + 0.5));
    float offsetZ = max(0., -sign(dir.z)*96.);
    vec4 vSampleZ = mix(textureCube(vUV0 + vec2(0., 4864. + offsetZ), 0.),
                        textureCube(vUV1 + vec2(0., 4864. + offsetZ), 0.), fract(vp5c.y + 0.5));
    vec4 vSample = (dirSqr.x*vSampleX + dirSqr.y*vSampleY + dirSqr.z*vSampleZ)*
                   clamp(1. - DFBox(vp5 - 0.5, vec3(79., 31., 31.)), 0., 1.);
    return vSample + textureCube(clamp(vp5.xz + vec2(29., 49.), vec2(0.5), vec2(127.5)) + vec2(512., 5120.), 0.)*
           clamp(1. - DFBox(vp5 - vec3(-29., 0.05, -49.), vec3(128., 0., 128.)), 0., 1.)*fwd*(1. - vSample.w);
}

vec4 vct_sample1(vec3 vp5, vec3 dir, vec3 dirSqr, float fwd) {
    //Samples VCT volume - LOD 1
    vec3 vp5c = clamp(vp5*0.5, vec3(0.5), vec3(39.5, 15.5, 15.5));
    vec2 vUV0 = vec2(vp5c.x + floor(mod(vp5c.y - 0.5, 6.))*40., vp5c.z + floor((vp5c.y - 0.5)/6.)*16.);
    vec2 vUV1 = vec2(vp5c.x + floor(mod(vp5c.y + 0.5, 6.))*40., vp5c.z + floor((vp5c.y + 0.5)/6.)*16.);
    float offsetX = max(0., -sign(dir.x)*96.);
    vec4 vSampleX = mix(textureCube(vUV0 + vec2(0., 5120. + offsetX), 0.),
                        textureCube(vUV1 + vec2(0., 5120. + offsetX), 0.), fract(vp5c.y + 0.5));
    float offsetY = max(0., -sign(dir.y)*96.);
    vec4 vSampleY = mix(textureCube(vUV0 + vec2(0., 5120. + offsetY), 0.),
                        textureCube(vUV1 + vec2(0., 5120. + offsetY), 0.), fract(vp5c.y + 0.5));
    float offsetZ = max(0., -sign(dir.z)*96.);
    vec4 vSampleZ = mix(textureCube(vUV0 + vec2(0., 5120. + offsetZ), 0.),
                        textureCube(vUV1 + vec2(0., 5120. + offsetZ), 0.), fract(vp5c.y + 0.5));
    vec4 vSample = (dirSqr.x*vSampleX + dirSqr.y*vSampleY + dirSqr.z*vSampleZ)*
                   clamp(1. - DFBox(vp5*0.5 - 0.5, vec3(39., 15., 15.)), 0., 1.);
    return vSample + textureCube(clamp(vp5.xz + vec2(29., 49.), vec2(1.), vec2(127.)) + vec2(512., 5120.), 1.)*
           clamp(1. - DFBox(vp5 - vec3(-29., 0.05, -49.), vec3(128., 0., 128.))*0.5, 0., 1.)*fwd*(1. - vSample.w);
}

vec4 vct_sample2(vec3 vp5, vec3 dir, vec3 dirSqr, float fwd) {
    //Samples VCT volume - LOD 2
    vec3 vp5c = clamp(vp5*0.25, vec3(0.5), vec3(19.5, 7.5, 7.5));
    vec2 vUV0 = vec2(vp5c.x + floor(vp5c.y - 0.5)*20., vp5c.z);
    vec2 vUV1 = vec2(vp5c.x + floor(vp5c.y + 0.5)*20., vp5c.z);
    float offsetX = max(0., -sign(dir.x)*96.);
    vec4 vSampleX = mix(textureCube(vUV0 + vec2(0., 5168. + offsetX), 0.),
                        textureCube(vUV1 + vec2(0., 5168. + offsetX), 0.), fract(vp5c.y + 0.5));
    float offsetY = max(0., -sign(dir.y)*96.);
    vec4 vSampleY = mix(textureCube(vUV0 + vec2(0., 5168. + offsetY), 0.),
                        textureCube(vUV1 + vec2(0., 5168. + offsetY), 0.), fract(vp5c.y + 0.5));
    float offsetZ = max(0., -sign(dir.z)*96.);
    vec4 vSampleZ = mix(textureCube(vUV0 + vec2(0., 5168. + offsetZ), 0.),
                        textureCube(vUV1 + vec2(0., 5168. + offsetZ), 0.), fract(vp5c.y + 0.5));
    vec4 vSample = (dirSqr.x*vSampleX + dirSqr.y*vSampleY + dirSqr.z*vSampleZ)*
                   clamp(1. - DFBox(vp5*0.25 - 0.5, vec3(19., 7., 7.)), 0., 1.);
    return vSample + textureCube(clamp(vp5.xz + vec2(29., 49.), vec2(2.), vec2(126.)) + vec2(512., 5120.), 2.)*
           clamp(1. - DFBox(vp5 - vec3(-29., 0.05, -49.), vec3(128., 0., 128.))*0.25, 0., 1.)*fwd*(1. - vSample.w);
}

vec4 vct_sample3(vec3 vp5, vec3 dir, vec3 dirSqr, float fwd) {
    //Samples VCT volume - LOD 3
    vec3 vp5c = clamp(vp5*0.125, vec3(0.5), vec3(9.5, 3.5, 3.5));
    vec2 vUV0 = vec2(vp5c.x + floor(vp5c.y - 0.5)*10., vp5c.z);
    vec2 vUV1 = vec2(vp5c.x + floor(vp5c.y + 0.5)*10., vp5c.z);
    float offsetX = max(0., -sign(dir.x)*96.);
    vec4 vSampleX = mix(textureCube(vUV0 + vec2(0., 5176. + offsetX), 0.),
                        textureCube(vUV1 + vec2(0., 5176. + offsetX), 0.), fract(vp5c.y + 0.5));
    float offsetY = max(0., -sign(dir.y)*96.);
    vec4 vSampleY = mix(textureCube(vUV0 + vec2(0., 5176. + offsetY), 0.),
                        textureCube(vUV1 + vec2(0., 5176. + offsetY), 0.), fract(vp5c.y + 0.5));
    float offsetZ = max(0., -sign(dir.z)*96.);
    vec4 vSampleZ = mix(textureCube(vUV0 + vec2(0., 5176. + offsetZ), 0.),
                        textureCube(vUV1 + vec2(0., 5176. + offsetZ), 0.), fract(vp5c.y + 0.5));
    vec4 vSample = (dirSqr.x*vSampleX + dirSqr.y*vSampleY + dirSqr.z*vSampleZ)*
                   clamp(1. - DFBox(vp5*0.125 - 0.5, vec3(9., 3., 3.)), 0., 1.);
    return vSample + textureCube(clamp(vp5.xz + vec2(29., 49.), vec2(4.), vec2(124.)) + vec2(512., 5120.), 3.)*
           clamp(1. - DFBox(vp5 - vec3(-29., 0.05, -49.), vec3(128., 0., 128.))*0.125, 0., 1.)*fwd*(1. - vSample.w);
}

vec4 vct_sample4(vec3 vp5, vec3 dir, vec3 dirSqr, float fwd) {
    //Samples VCT volume - LOD 4
    vec3 vp5c = clamp(vp5*I16, vec3(0.5), vec3(4.5, 1.5, 1.5));
    vec2 vUV0 = vec2(vp5c.x + floor(vp5c.y - 0.5)*5., vp5c.z);
    vec2 vUV1 = vec2(vp5c.x + floor(vp5c.y + 0.5)*5., vp5c.z);
    float offsetX = max(0., -sign(dir.x)*96.);
    vec4 vSampleX = mix(textureCube(vUV0 + vec2(0., 5180. + offsetX), 0.),
                        textureCube(vUV1 + vec2(0., 5180. + offsetX), 0.), fract(vp5c.y + 0.5));
    float offsetY = max(0., -sign(dir.y)*96.);
    vec4 vSampleY = mix(textureCube(vUV0 + vec2(0., 5180. + offsetY), 0.),
                        textureCube(vUV1 + vec2(0., 5180. + offsetY), 0.), fract(vp5c.y + 0.5));
    float offsetZ = max(0., -sign(dir.z)*96.);
    vec4 vSampleZ = mix(textureCube(vUV0 + vec2(0., 5180. + offsetZ), 0.),
                        textureCube(vUV1 + vec2(0., 5180. + offsetZ), 0.), fract(vp5c.y + 0.5));
    vec4 vSample = (dirSqr.x*vSampleX + dirSqr.y*vSampleY + dirSqr.z*vSampleZ)*
                   clamp(1. - DFBox(vp5*I16 - 0.5, vec3(4., 1., 1.)), 0., 1.);
    return vSample + textureCube(clamp(vp5.xz + vec2(29., 49.), vec2(8.), vec2(120.)) + vec2(512., 5120.), 4.)*
           clamp(1. - DFBox(vp5 - vec3(-29., 0.05, -49.), vec3(128., 0., 128.))*I16, 0., 1.)*fwd*(1. - vSample.w);
}

vec4 vct_sample(vec3 vp5, vec3 dir, vec3 dirSqr, float fwd, float lod) {
    //Sample VCT volume with manual LOD interpolation
    if (lod < 1.) return mix(vct_sample0(vp5, dir, dirSqr, fwd), vct_sample1(vp5, dir, dirSqr, fwd), lod);
    else if (lod < 2.) return mix(vct_sample1(vp5, dir, dirSqr, fwd), vct_sample2(vp5, dir, dirSqr, fwd), lod - 1.);
    else if (lod < 3.) return mix(vct_sample2(vp5, dir, dirSqr, fwd), vct_sample3(vp5, dir, dirSqr, fwd), lod - 2.);
    else if (lod < 4.) return mix(vct_sample3(vp5, dir, dirSqr, fwd), vct_sample4(vp5, dir, dirSqr, fwd), lod - 3.);
    return vct_sample4(vp5, dir, dirSqr, fwd);
}

vec3 traceCone45(vec3 pos, vec3 dir) {
    //Traces a cone with const CR -> no LOD interpolation
    vec4 vOUT = vec4(0.);
    vec3 vp5, vp5c;
    vec4 vSample = vec4(0.);
    float floorWeightDir = -max(0., -dir.y)*dir.y;
    vec3 dirSqr = dir*dir;
    vp5 = pos*5. + dir*0.5;
    vOUT = vct_sample0(vp5, dir, dirSqr, floorWeightDir);
    vp5 += dir;
    vOUT += vct_sample1(vp5, dir, dirSqr, floorWeightDir)*(1. - vOUT.w);
    vp5 += dir*2.;
    vOUT += vct_sample2(vp5, dir, dirSqr, floorWeightDir)*(1. - vOUT.w);
    vp5 += dir*4.;
    vOUT += vct_sample3(vp5, dir, dirSqr, floorWeightDir)*(1. - vOUT.w);
    vp5 += dir*8.;
    vOUT += vct_sample4(vp5, dir, dirSqr, floorWeightDir)*(1. - vOUT.w);
    return vOUT.xyz + mix(vec3(0.1, 0.13, 0.16), vec3(0.16, 0.08, 0.02), dir.x*0. + 0.)*((dir.y*0.5 + 0.5)*(1. - vOUT.w));
}

vec3 traceCone(vec3 pos, vec3 dir, float cr) {
    //Traces a cone with LOD interpolation
    vec4 vOUT = vec4(0.);
    float floorWeightDir = -max(0., -dir.y)*dir.y;
    vec3 dirSqr = dir*dir;
    float vt = 0.;
    vec3 vp;
    for (int i = 0; i < 24; i++) {
        vp = pos + dir*vt;
        vec3 vp5 = vp*5.;
        float vRadius = max(1., cr*vt*5.);
        float vLod = log2(vRadius);
        vOUT += vct_sample(vp5, dir, dirSqr, floorWeightDir, vLod)*(1. - vOUT.w);
        vt += vRadius*0.2;
    }
    return vOUT.xyz + vec3(0.13, 0.18, 0.24)*((dir.y*0.5 + 0.5)*(1. - vOUT.w));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    vec2 SSOffset = fract(vec2(0.61803398875, 0.38196601125)*float(iFrame % 16))*0.8 - 0.5;
    vec3 Eye = texture(iChannel0, vec2(2.5, 0.5)*IRES).xyz;
    vec3 Pos = vec3(7. - Eye.x*2., 2., 3.) - Eye*13.;
    mat3 EyeMat = TBN(Eye);
    vec3 PriorPos = texture(iChannel0, vec2(7.5, 0.5)*IRES).xyz;
    vec3 PriorEye = texture(iChannel0, vec2(6.5, 0.5)*IRES).xyz;
    vec3 PriorTan; vec3 PriorBit = TBN(PriorEye, PriorTan);
    mat3 PriorEyeMat = TBN(PriorEye);
    vec3 Dir = normalize(vec3(((fragCoord + SSOffset)*IRES*2. - 1.)*CFOV*ASPECT, 1.)*EyeMat);
    vec4 cAttr = texture(iChannel0, fragCoord*IRES);
    if (cAttr.w > -0.5) {
        //Geometry
        vec3 pPos = Pos + Dir*cAttr.w;
        vec3 pNor = normalize(FloatToVec3(cAttr.y)*2. - 1.);
        
        //Direct diffuse light
        vec3 diffuseLight = vec3(0.);
        vec3 smPos = pPos - SUN_TARGET;
        float spotWeight = pow(max(0., (dot(normalize(smPos - SUN_DIR*32.), -SUN_DIR) - 1. + 0.01)/0.01), 2.);
        vec2 smUV = vec2(dot(smPos, SUN_TAN)/(SUN_SM_SIZE*ASPECT.x)*0.5 + 0.5, dot(smPos, SUN_BIT)/SUN_SM_SIZE*0.5 + 0.5);
        if (DFBox(smUV, vec2(1.)) < 0.) {
            //Inside shadow map
            float smDepth = texture(iChannel2, smUV).x;
            if (smDepth + 0.03 > dot(pPos - SUN_TARGET - SUN_DIR*32., -SUN_DIR)) {
                diffuseLight = vec3(max(0., dot(pNor, SUN_DIR))*2.*spotWeight);
            }
        } else {
            //Outside
            diffuseLight = vec3(max(0., dot(pNor, SUN_DIR))*2.*spotWeight);
        }
        
        //Indirect diffuse light
        mat3 nMat = TBN(pNor);
        diffuseLight += (traceCone45(pPos + pNor*0.1, pNor).xyz + (
                       traceCone45(pPos + pNor*0.1, vec3(0.707, 0., 0.707)*nMat).xyz +
                       traceCone45(pPos + pNor*0.1, vec3(-0.707, 0., 0.707)*nMat).xyz +
                       traceCone45(pPos + pNor*0.1, vec3(0., 0.707, 0.707)*nMat).xyz +
                       traceCone45(pPos + pNor*0.1, vec3(0., -0.707, 0.707)*nMat).xyz)*0.707)*0.2;
        
        //Hardcoded materials
        if (pPos.y < 0.051) {
            //Floor
            vec3 refDir = normalize(reflect(Dir, pNor));
            float checker_cr = ((mod(floor((pPos.z + pPos.x)*0.707*0.4) +
                                     floor((pPos.z - pPos.x)*0.707*0.4) + 0.5, 2.) < 1.)?0.1:0.3);
            Output.xyz += mix(diffuseLight, traceCone(pPos + pNor*0.1, refDir, checker_cr).xyz,
                              SchlickFresnel(vec3(0.5), max(0., dot(pNor, -Dir))));
        } else {
            //Car
            Output.xyz = diffuseLight;
        }
        
        //Emissive
        vec3 symPos = vec3(pPos.xy, 3. + abs(pPos.z - 3.));
        if (DFBox(symPos - vec3(11.81, 1.5, 4.), vec3(1., 0.95, 1.)) < 0.) {
            Output.xyz = vec3(3., 1.5, 0.5);
        }
        if (min(DFBox(symPos - vec3(2., 2.2, 4.81), vec3(2., 0.95, 0.2)),
                DFBox(symPos - vec3(0.99, 2.2, 3.05), vec3(0.2, 0.95, 3.))) < 0.) {
            Output.xyz = vec3(3., 0.25, 0.25);
        }
    } else {
        //Sky
        Output.xyz = vec3(0.13, 0.18, 0.24)*(Dir.y*0.5 + 0.5);
    }
    fragColor = Output;
}