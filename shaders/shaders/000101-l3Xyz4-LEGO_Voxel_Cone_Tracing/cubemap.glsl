// Cube A (cubemap) — LEGO Voxel Cone Tracing by Mathis
// https://www.shadertoy.com/view/l3Xyz4

//LEGO model and voxels

vec4 textureCube(vec2 uv) {
    //Samples the cubemap
    float tcSign = -mod(floor(uv.y*I1024), 2.)*2. + 1.;
    vec3 tcD = vec3(vec2(uv.x, mod(uv.y, 1024.))*I512 - 1., tcSign);
    if (uv.y > 4096.) tcD = tcD.xzy;
    else if (uv.y > 2048.) tcD = tcD.zxy;
    return textureLod(iChannel3, tcD, 0.);
}

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
    return vOUT.xyz + vec3(0.1, 0.13, 0.16)*((dir.y*0.5 + 0.5)*(1. - vOUT.w));
}

float vSDF(vec3 sp) {
    //Samples a volume SDF
    float sVal = sp.x*20.;
    vec2 uvMod = 0.5 + sp.zy*20.;
    vec2 uvSlice0 = vec2(floor(mod(sVal, 8.))*120., floor(sVal/8.)*128.);
    vec4 texC = textureCube(uvMod + uvSlice0);
    return mix(texC.x, texC.y, fract(sVal));
}

void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir) {
    vec4 Output = texture(iChannel3, rayDir);
    vec2 UV; vec3 aDir = abs(rayDir);
    if (aDir.z > max(aDir.x, aDir.y)) {
        //Z-side
        UV = floor(((rayDir.xy/aDir.z)*0.5 + 0.5)*1024.) + 0.5;
        if (rayDir.z < 0.) UV.y += 1024.;
    } else if (aDir.x > aDir.y) {
        //X-side
        UV = floor(((rayDir.yz/aDir.x)*0.5 + 0.5)*1024.) + 0.5;
        if (rayDir.x > 0.) UV.y += 2048.;
        else UV.y += 3072.;
    } else {
        //Y-side
        UV = floor(((rayDir.xz/aDir.y)*0.5 + 0.5)*1024.) + 0.5;
        if (rayDir.y > 0.) UV.y += 4096.;
        else UV.y += 5120.;
    }
    if (DFBox(UV - vec2(512., 5120.), vec2(128.)) < 0.) {
        //VCT - floor voxels
        vec2 vUV = vec2(UV.x - 512., UV.y - 5120.);
        Output = vec4(0., 0., 0., 1.);
        vec3 vPos = vec3(vUV.x - 29., 0., vUV.y - 49.)*0.2;
        vec3 planep = vPos - vec3(-5., 0., 3.);
        if (DFBox(vec2(planep.x + planep.z, planep.x - planep.z)*0.707, vec2(16.)) < 0.) {
            //Inside -> sample shadow map
            vec3 smPos = vPos - SUN_TARGET;
            float spotWeight = pow(max(0., (dot(normalize(smPos - SUN_DIR*32.), -SUN_DIR) - 1. + 0.01)/0.01), 2.);
            vec2 smUV = vec2(dot(smPos, SUN_TAN)/(SUN_SM_SIZE*ASPECT.x)*0.5 + 0.5, dot(smPos, SUN_BIT)/SUN_SM_SIZE*0.5 + 0.5);
            if (DFBox(smUV, vec2(1.)) < 0.) {
                //Inside shadow map
                float smDepth = texture(iChannel2, smUV).x;
                if (smDepth > dot(vPos - SUN_TARGET - SUN_DIR*32., -SUN_DIR)) {
                    Output.xyz += vec3(2.*spotWeight);
                }
            } else {
                //Outside
                Output.xyz += vec3(2.*spotWeight);
            }
            
            //Emissive
            //Output.xyz += clamp((0.6 - length(vPos.xz - vec2(7., 3.)))*5., 0., 1.)
            //              *vec3(1.2, 3.5, 0.7);
        }
    } else if (UV.y > 4480. && UV.y < 4480. + 96.*6. && UV.x < 960.) {
        //VCT - isotropic LOD 0
        vec2 vUV = vec2(UV.x, UV.y - 4480.);
        vec2 modUV = vec2(vUV.x, mod(vUV.y, 96.));
        vec3 vPos = vec3(mod(vUV.x, 80.), floor(modUV.x/80.) + floor(modUV.y/32.)*12. + 0.5, mod(modUV.y, 32.))*0.2;
        float vWeight = clamp(-vSDF(vPos)*10. + 0.5, 0., 1.)*float(DFBox(vPos, vec3(13., 0.4*16., 6.)) < 0.);
        if (iFrame < 4) Output = vec4(0.);
        vec3 vLight = vec3(0.);
        if (vWeight > 0.) {
            //Shadow map
            vec3 smPos = vPos - SUN_TARGET;
            float spotWeight = pow(max(0., (dot(normalize(smPos - SUN_DIR*32.), -SUN_DIR) - 1. + 0.01)/0.01), 2.);
            vec2 smUV = vec2(dot(smPos, SUN_TAN)/(SUN_SM_SIZE*ASPECT.x)*0.5 + 0.5, dot(smPos, SUN_BIT)/SUN_SM_SIZE*0.5 + 0.5);
            if (DFBox(smUV, vec2(1.)) < 0.) {
                //Inside shadow map
                float smDepth = texture(iChannel2, smUV).x;
                if (smDepth + 0.3 > dot(vPos - SUN_TARGET - SUN_DIR*32., -SUN_DIR)) {
                    vLight += vec3(2.*spotWeight);
                }
            }
            
            //Diffuse indirect (just bruteforce 5 cones)
            vec3 vNor = normalize(vec3(vSDF(vPos + epsv.xyy) - vSDF(vPos - epsv.xyy),
                                       vSDF(vPos + epsv.yxy) - vSDF(vPos - epsv.yxy),
                                       vSDF(vPos + epsv.yyx) - vSDF(vPos - epsv.yyx)));
            mat3 vMat = TBN(vNor);
            vLight += (max(vec3(0.), traceCone45(vPos + vNor*0.2, vNor).xyz) + (
                       max(vec3(0.), traceCone45(vPos + vNor*0.2, vec3(0.707, 0., 0.707)*vMat).xyz) +
                       max(vec3(0.), traceCone45(vPos + vNor*0.2, vec3(-0.707, 0., 0.707)*vMat).xyz) +
                       max(vec3(0.), traceCone45(vPos + vNor*0.2, vec3(0., 0.707, 0.707)*vMat).xyz) +
                       max(vec3(0.), traceCone45(vPos + vNor*0.2, vec3(0., -0.707, 0.707)*vMat).xyz))*0.707)*0.2;
        }
        
        //Emissive
        vec3 symPos = vec3(vPos.xy, 3. + abs(vPos.z - 3.));
        if (DFBox(symPos - vec3(11.81, 1.5, 4.), vec3(1., 0.95, 1.)) < 0.) {
            vLight = vec3(3., 1.5, 0.5);
        }
        if (min(DFBox(symPos - vec3(2., 2.2, 4.81), vec3(2., 0.95, 0.2)),
                DFBox(symPos - vec3(0.99, 2.2, 3.05), vec3(0.2, 0.95, 3.))) < 0.) {
            vLight = vec3(3., 0.25, 0.25);
        }
        
        //Weight
        Output = vec4(vLight*vWeight, vWeight);
    } else if (DFBox(UV - vec2(0., 5120.), vec2(245., 96.*6.)) < 0.) {
        //VCT - anisotropic LOD
        Output = vec4(0.);
        vec2 vUV = vec2(UV.x, UV.y - 5120.);
        vec2 mUV = vec2(vUV.x, mod(vUV.y, 96.));
        float uvWidth, uvYSize;
        vec2 lastUV;
        vec2 uvTan, uvBit, uvNor;
        if (vUV.y < 192.) {
            //X
            uvTan = vec2(80., 0.);
            uvBit = vec2(0., 1.);
            uvNor = vec2(1., 0.);
        } else if (vUV.y < 384.) {
            //Y
            uvTan = vec2(1., 0.);
            uvBit = vec2(0., 1.);
            uvNor = vec2(80., 0.);
        } else {
            //Z
            uvTan = vec2(1., 0.);
            uvBit = vec2(80., 0.);
            uvNor = vec2(0., 1.);
        }
        float uvYOffset = floor(vUV.y/96.)*96.;
        if (mod(vUV.y, 192.) > 96.) {
            //Integrating in negative direction
            uvNor *= -1.;
        }
        //LOD attributes
        if (DFBox(mUV, vec2(240., 48.)) < 0.) {
            //LOD 1
            lastUV = floor(mUV)*2. + vec2(0.5 + floor(mUV.x/40.)*80. + max(0., -uvNor.x), 0.5);
            lastUV = vec2(mod(lastUV.x, 960.), lastUV.y + floor(lastUV.x/960.)*32. + 4480. + uvYOffset);
            uvWidth = 960.;
            uvYSize = 32.;
        } else if (DFBox(vec2(mUV.x, mUV.y - 48.), vec2(160., 8.)) < 0.) {
            //LOD 2
            uvNor.x = sign(uvNor.x)*min(abs(uvNor.x), 40.);
            uvTan.x = min(uvTan.x, 40.);
            uvBit.x = min(uvBit.x, 40.);
            mUV.y -= 48.;
            lastUV = floor(mUV)*2. + vec2(0.5 + floor(mUV.x/20.)*40. + max(0., -uvNor.x), 0.5);
            lastUV = vec2(mod(lastUV.x, 240.), lastUV.y + floor(lastUV.x/240.)*16. + 5120. + uvYOffset);
            uvWidth = 240.;
            uvYSize = 16.;
        } else if (DFBox(vec2(mUV.x, mUV.y - 56.), vec2(40., 4.)) < 0.) {
            //LOD 3
            uvNor.x = sign(uvNor.x)*min(abs(uvNor.x), 20.);
            uvTan.x = min(uvTan.x, 20.);
            uvBit.x = min(uvBit.x, 20.);
            mUV.y -= 56.;
            lastUV = floor(mUV)*2. + vec2(0.5 + floor(mUV.x/10.)*20. + max(0., -uvNor.x), 5168.5 + uvYOffset);
            uvWidth = 10000.; //IGNORE -> No x-modulus
            uvYSize = 0.; //IGNORE -> No y-layers
        } else if (DFBox(vec2(mUV.x, mUV.y - 60.), vec2(10., 2.)) < 0.) {
            //LOD 4
            uvNor.x = sign(uvNor.x)*min(abs(uvNor.x), 10.);
            uvTan.x = min(uvTan.x, 10.);
            uvBit.x = min(uvBit.x, 10.);
            mUV.y -= 60.;
            lastUV = floor(mUV)*2. + vec2(0.5 + floor(mUV.x/5.)*10. + max(0., -uvNor.x), 5176.5 + uvYOffset);
        }
        //Integrate
        vec2 suv = lastUV;
        vec4 firstVoxel = textureCube(suv);
        Output += firstVoxel + textureCube(suv + uvNor)*(1. - firstVoxel.w);
        suv += uvTan;
        firstVoxel = textureCube(suv);
        Output += firstVoxel + textureCube(suv + uvNor)*(1. - firstVoxel.w);
        suv += uvBit;
        firstVoxel = textureCube(suv);
        Output += firstVoxel + textureCube(suv + uvNor)*(1. - firstVoxel.w);
        suv = lastUV + uvBit;
        firstVoxel = textureCube(suv);
        Output += firstVoxel + textureCube(suv + uvNor)*(1. - firstVoxel.w);
        Output *= 0.25;
    } else if (UV.x < 960. && UV.y < 4480.) {
        //SDF volume
        vec3 WPos = vec3(floor(UV.x/120.)*0.05 + floor(UV.y*I128)*0.4,
                         floor(mod(UV.y, 128.))*0.05,
                         floor(mod(UV.x, 120.))*0.05);
        if (iFrame <= 1) {
            //Initial frame
            Output = vec4(1000.);
        } else if (iFrame <= 8) {
            //Building frames
            for (int brick_index = (iFrame - 2)*16; brick_index < min((iFrame - 1)*16, 99); brick_index++) {
                //For each new index
                BRICK CBrick = Bricks[brick_index];
                vec4 CBrick0 = vec4(CBrick.P, 0.);
                vec4 CBrick1 = CBrick.Q;
                vec3 CX = CBrick1.xyz;
                vec2 sincos = vec2(sin(CBrick1.w), cos(CBrick1.w));
                vec3 RefCZ = normalize(cross(CX, vec3(0., 1., 0.)));
                vec3 RefCY = cross(RefCZ, CX);
                vec3 CY = sincos.y*RefCY + sincos.x*RefCZ;
                vec3 CZ = -sincos.x*RefCY + sincos.y*RefCZ;
                vec3 CXT = vec3(CX.x, CY.x, CZ.x);
                vec3 CYT = vec3(CX.y, CY.y, CZ.y);
                vec3 CZT = vec3(CX.z, CY.z, CZ.z);
                //New sample position
                vec3 VPos = (WPos.x - CBrick.P.x)*CXT + (WPos.y - CBrick.P.y)*CYT + (WPos.z - CBrick.P.z)*CZT;
                if (CBrick.I == 0) {
                    //OnlySlope
                    Output.x = min(Output.x, DFOnlySlope(VPos));
                } else if (CBrick.I == 1) {
                    //Round111
                    Output.x = min(Output.x, DFRound111(VPos));
                } else if (CBrick.I == 2) {
                    //Round131
                    Output.x = min(Output.x, DFRound131(VPos));
                } else if (CBrick.I == 3) {
                    //Brick111
                    Output.x = min(Output.x, DFBrick(VPos, vec3(1., 0.8, 1.)));
                } else if (CBrick.I == 4) {
                    //Grate
                    Output.x = min(Output.x, DFGrate(VPos));
                } else if (CBrick.I == 5) {
                    //Brick411
                    Output.x = min(Output.x, DFBrick(VPos, vec3(4., 0.8, 1.))); //Brick skapar weird lines
                } else if (CBrick.I == 6) {
                    //Brick412
                    Output.x = min(Output.x, DFBrick(VPos, vec3(4., 0.8, 2.)));
                } else if (CBrick.I == 7) {
                    //HeadLight
                    Output.x = min(Output.x, DFHeadLight(VPos));
                } else if (CBrick.I == 8) {
                    //Inverse Slope
                    Output.x = min(Output.x, DFISlope(VPos, 1.));
                } else if (CBrick.I == 9) {
                    //Grip
                    Output.x = min(Output.x, DFGrip(VPos));
                } else if (CBrick.I == 10) {
                    //Handle
                    Output.x = min(Output.x, DFHandle(VPos, 0.));
                } else if (CBrick.I == 11) {
                    //Brick211
                    Output.x = min(Output.x, DFBrick(VPos, vec3(2., 0.8, 1.)));
                } else if (CBrick.I == 12) {
                    //Tire
                    float tmpCylDF = length(VPos.xy - vec2(1.));
                    float DF = max(VPos.z - 0.88461538461, max(0.11538461539 - VPos.z, tmpCylDF - 0.9));
                    vec3 rp = VPos-vec3(1., 1., 0.); rp.xy = Repeat(rp.xy, 16.);
                    DF = -smin(-DF, DFBox(rp - vec3(-0.1282, 0.771795, -2.), vec3(0.1282, 2., 2.46)) - 0.02, 0.05);
                    rp = VPos - vec3(1., 1., 0.); rp.xy = Rotate(rp.xy, 0.19634954); rp.xy = Repeat(rp.xy, 16.);
                    DF = -smin(-DF, DFBox(rp - vec3(-0.1282, 0.771795, 0.54), vec3(0.1282, 2., 5.)) - 0.02, 0.05);
                    DF = -smin(-DF, tmpCylDF - 0.51282, 0.1);
                    //Output
                    Output.x = min(Output.x, DF);
                } else if (CBrick.I == 13) {
                    //Tire Center
                    float tmpCylDF = length(VPos.xy-vec2(1.));
                    float DF = max(VPos.z-0.88461538461,max(0.11538461539-VPos.z,tmpCylDF-0.51282));
                        DF = -smin(-DF,length(VPos-vec3(1.,1.,-0.1))-0.45,0.05);
                        DF = -smin(-DF,tmpCylDF-0.26,0.05);
                    DF = smin(DF,max(VPos.z-0.3,max(0.11538461539-VPos.z,tmpCylDF-0.192)),0.05);
                        DF = smin(DF,DFBox(VPos-vec3(0.9359,0.5,0.13),vec3(0.1282,0.87,0.1282)),0.05);
                        DF = smin(DF,DFBox(VPos-vec3(0.5,0.9359,0.13),vec3(0.87,0.1282,0.1282)),0.05);
                    //Output
                    Output.x = min(Output.x, DF);
                } else if (CBrick.I == 14) {
                    //Steering Wheel
                    float tmpCylDF = max(length(VPos.xz-vec2(1.)), -VPos.y);
                    float DF = max(VPos.y-0.6,max(0.001-VPos.z,tmpCylDF-0.38461538461));
                    DF = min(DF,length(vec2(length(VPos.xz-vec2(1.))-0.87179,VPos.y-0.6))-0.141);
                    vec3 rp = VPos-vec3(1.,0.6,1.); rp.xz = Repeat(rp.xz,3.);
                    DF = min(DF,DFBox(rp-vec3(-0.16,-0.1,0.),vec3(0.32,0.1,0.87179)));
                    rp = VPos-vec3(1.,0.6,1.); rp.xz = Rotate(rp.xz,1.0471975512); rp.xz = Repeat(rp.xz,3.);
                    DF = max(DF,-DFBox(rp-vec3(-0.2,-0.3,0.3),vec3(0.4,1.,0.3)));
                    DF = max(DF,-tmpCylDF+0.1923);
                    //Output
                    Output.x = min(Output.x, DF);
                } else if (CBrick.I == 15) {
                    //Lever Base (no interior)
                    float tmpCylDF = length(VPos.xz-vec2(0.5));
                    float DF = min(max(max(tmpCylDF-0.397, VPos.y-0.25), -VPos.y),length(VPos-vec3(0.5,0.25,0.5))-0.397);
                    DF = max(DF,-DFBox(VPos-vec3(-1.,0.3,0.4),vec3(4.,4.,0.2)));
                    //Output
                    Output.x = min(Output.x, DF);
                } else if (CBrick.I == 16) {
                    //Lever
                    float DF = DFLine(VPos,vec3(0.5,0.5,0.5),vec3(2.423,0.5,0.5))-0.096;
                    DF = min(DF,max(max(length(VPos.xy-0.5)-0.2564,0.4-VPos.z),VPos.z-0.6));
                    DF = min(DF,length(VPos-vec3(2.423,0.5,0.5))-0.16);
                    //Output
                    Output.x = min(Output.x, DF);
                } else if (CBrick.I == 17) {
                    //Rotating Brick Base
                    float DF = DFBox(VPos-vec3(0.04),vec3(1.92,1.12,0.92))-0.04;
                    DF = -smin(-DF,DFBox(VPos-vec3(0.1,0.2,0.1),vec3(1.8,2.,2.)),0.05);
                        DF = -smin(-DF,DFBox(VPos-vec3(-1.,0.6,0.2),vec3(5.,2.,2.)),0.05);
                    DF = smin(DF,DFBox(VPos-vec3(0.1,0.2,0.1),vec3(1.8,0.2,0.8)),0.05);
                    DF = smin(DF,DFBox(VPos-vec3(0.9,0.4,0.1),vec3(0.2,0.3,0.8)),0.05);
                    Output.x = min(Output.x, DF);
                } else if (CBrick.I == 18) {
                    //Rotating Brick Piece
                    float DF = DFBox(VPos-vec3(0.04,1.04,0.04),vec3(1.92,0.12,0.92))-0.04;
                    DF = min(DF,DFBox(VPos-vec3(0.1,0.4,0.55),vec3(1.8,0.7,0.1)));
                    DF = min(DF,DFBox(VPos-vec3(0.1,0.4,0.1),vec3(0.1,0.7,0.75)));
                        DF = min(DF,DFBox(VPos-vec3(1.8,0.4,0.1),vec3(0.1,0.7,0.75)));
                    Output.x = min(Output.x, DF);
                } else if (CBrick.I == 19) {
                    //Long Handle
                    float DF = DFBrick(VPos,vec3(2.,0.8,1.));
                    vec3 syp = vec3(VPos.xy,abs(VPos.z-0.5));
                    float tmpCyl = length(VPos.xy-vec2(2.5,0.3));
                    DF = min(DF,DFBox(syp-vec3(0.04,0.04,0.24),vec3(2.46,0.32,0.22))-0.04);
                    DF = min(DF,-smin(smin(-tmpCyl+0.3,0.5-syp.z,0.04),syp.z-0.2,0.04));
                    DF = min(DF,max(max(tmpCyl-0.2,0.05-VPos.z),VPos.z-0.95));
                    //Output
                    Output.x = min(Output.x, DF);
                } else if (CBrick.I == 20) {
                    //Studgrip
                    float DF = DFBrick(VPos,vec3(1.,0.8,1.));
                    DF = smin(DF,DFBox(VPos-vec3(1.,0.,0.244),vec3(0.5,0.4,0.512)),0.05);
                    float tmpCyl = length(VPos.xy-vec2(1.5,0.35));
                    DF = min(DF,max(max(tmpCyl-0.4,0.244-VPos.z),VPos.z-0.756));
                    DF = min(DF,max(max(tmpCyl-0.3,0.01-VPos.z),VPos.z-0.99));
                    DF = -smin(-DF,tmpCyl-0.2,0.05);
                    Output.x = min(Output.x, DF);
                } else if (CBrick.I == 21) {
                    //Vertical Grip
                    float DF = DFBox(VPos-vec3(0.04),vec3(0.92,0.32,0.92))-0.04;
                    DF = min(DF,max(max(DFLine(VPos,vec3(0.5,-1.,0.5),vec3(0.5,0.6,0.5))-0.5,0.307-VPos.z),VPos.z-0.692));
                    DF = max(DF,-length(VPos.xy-vec2(0.5,0.6923))+0.1923);
                    DF = -smin(-DF,-VPos.y+0.9,0.2);
                    DF = max(DF,-DFBox(VPos-vec3(0.35,0.6,-1.),vec3(0.3,5.,4.)));
                    Output.x = min(Output.x, DF);
                }
            }
        }
        vec2 NextUV = 0.5 + WPos.zy*20. + vec2(floor(mod(WPos.x*20. + 1.5, 8.))*120., floor((WPos.x*20. + 1.5)/8.)*128.);
        Output.y = textureCube(NextUV).x;
    }
    //Output
    fragColor = Output;
}