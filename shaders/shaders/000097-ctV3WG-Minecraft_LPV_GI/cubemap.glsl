// Cube A (cubemap) — Minecraft + LPV GI by Mathis
// https://www.shadertoy.com/view/ctV3WG

//SDF volume and TAA

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
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
    if (UV.y<32.) {
        //2x2 chunk, y-axis clamped to 32 voxels
        if (iFrame>2 && false) {
            fragColor = Output;
            return;
            discard; //Adding this makes me feel safe
            float X = 5.; //Wat
        } else {
            Output = vec4(-1.);
            vec3 sp = vec3(mod(UV.x,32.),floor(UV.x*I32)+0.5,UV.y);
            vec3 rsp = vec3(16.-abs(16.-sp.x),sp.y,mod(sp.z,7.));
            vec3 syp = vec3(rsp.x,sp.yz);
            //Floor
            if (DFBox(sp,vec3(32.,1.,32.))<0.) Output.x = 1.;
            
            //Staircase
            if (sp.y>1. && sp.y<6. && DFBox(syp.xz-vec2(8.-(sp.y-4.5)*2.,26.),vec2(3.,2.))<0.) Output.x = 4.; //Bridge
                if (sp.y>3. && sp.y<7. && syp.x>7. &&
                    DFBox(syp.xz-vec2(8.-(sp.y-5.5)*2.,25.),vec2(3.,1.))<0.) Output.x = 0.; //Railing
                if (sp.y>2. && sp.y<7. && DFBox(syp.xz-vec2(8.-(sp.y-5.5)*2.,28.),vec2(3.,1.))<0.) Output.x = 5.; //Railing
                    if (sp.z>24. && sp.z<26. && DFBox(syp.xy-vec2(14.,1.),vec2(1.,sp.z-22.5))<0.) Output.x = 4.; //Stairs rail
                if (DFBox(sp-vec3(15.,2.,26.),vec3(2.,1.,2.))<0.) Output.x = 4.;
            
            //Lower level books
            if (abs(sp.y-2.5)<1.6 && abs(length(vec2(rsp.x-9.,rsp.z-4.))-4.5)<0.8 && rsp.x<7. && sp.z>7. && sp.z<29.) Output.x = 3.;
                if (DFBox(rsp-vec3(7.,1.,0.),vec3(1.,3.,1.))<0.) Output.x = 2.; //Column
                if (DFBox(rsp-vec3(7.,4.,0.),vec3(1.,1.,1.))<0.) Output.x = 200.; //Emissive
            
            //Upper level
            if (DFBox(syp-vec3(0.,4.,7.),vec3(7.,1.,22.))<0.) Output.x = 4.; //Wood base
                 if (DFBox(syp-vec3(6.,5.,7.),vec3(2.,1.,22.))<0.) Output.x = 4.; //Wood walkway
                     if (DFBox(syp-vec3(7.,6.,7.),vec3(1.,1.,18.))<0.) Output.x = 8.; //Glass support
                     if (abs(sp.y-5.5)<0.1 && length(rsp.xz-vec2(6.,4.))<2.) Output.x = 4.;
                //Books
                    if (abs(sp.y-6.5)<1.6 && abs(length(vec2(rsp.x-5.,rsp.z-4.))-4.5)<0.8
                    && rsp.x<4. && sp.z>7. && sp.z<29.) Output.x = 3.;
                        if (DFBox(rsp-vec3(3.,4.,0.),vec3(1.,4.,1.))<0.) Output.x = 2.; //Column
                        if (DFBox(rsp-vec3(3.,8.,0.),vec3(1.,1.,1.))<0.) Output.x = 100.; //Emissive
            
            //Building
                //Front
                    if (abs(DFLine(sp,vec3(16.,-100.,17.),vec3(16.,8.,17.))-14.5)<0.7 && sp.z>28.) Output.x = 5.;
                        if (DFBox(syp-vec3(0.,0.,28.),vec3(8.,14.,1.))<0.) Output.x = 5.; //Sides
                    if (abs(sp.z-29.5)<0.1 && abs(length(sp.xy-vec2(16.,11.))-2.2)<0.4) Output.x = 100.; //Emissive
                        if (abs(sp.z-29.5)<0.1 && syp.x>10. && sp.y<9. && 
                            abs(dot(syp.xy-vec2(15.5,4.5),vec2(2.,1.)))<0.5) Output.x = 100.;
                        if (abs(sp.z-29.5)<0.1 && syp.x>10. &&
                            sp.y<9. && abs(dot(syp.xy-vec2(15.5,3.5),vec2(2.,1.)))<0.5) Output.x = 100.;
                //Roof over books
                    if (DFLine(rsp,vec3(4.,9.,-1000.),vec3(4.,9.,1000.))<5. && sp.y>8. && rsp.x<9. && 
                    DFLine(rsp,vec3(32.,15.,4.),vec3(4.,8.5,4.))>3.8 && sp.z>7. && sp.z<28.) Output.x = 5.;
                        //Round window
                        if ((length(rsp.zy-vec2(4.,10.))<2.1 && sp.z<28.) || (false && sp.y>8. && rsp.x<1.)) Output.x = -1.;
                        if (length(rsp.zy-vec2(4.,10.))<2.1 && sp.z>7. && sp.z<28. && abs(rsp.x-0.5)<0.1) Output.x = 8.;
                //Back
                    if (sp.z<7.) Output.x = -1.; //Remove voxels
                    //Glass blocks
                        if (DFBox(sp-vec3(5.,1.,6.),vec3(22.,13.,1.))<0.) Output.x = 0.;
                            if (DFBox(sp-vec3(15.,4.,6.),vec3(2.,1.,1.))<0.) Output.x = 2.;
                            if (DFBox(sp-vec3(15.,2.,6.),vec3(2.,2.,1.))<0.) Output.x = -1.; //Door
                    //Back of upper walkway
                        if (DFBox(syp-vec3(4.,5.,7.),vec3(3.,1.,1.))<0.) Output.x = 4.;
                    //Entrance wall
                        if (DFBox(syp-vec3(0.,0.,6.),vec3(7.,14.,1.))<0.) Output.x = 5.; //Sides
                        if (abs(sp.z-6.5)<0.1) {
                            if (sp.y<1.) Output.x = 2.; //Wood ground
                            //Two circles
                            if (abs(dot(syp.xy-vec2(9.,1.),vec2(0.707,-0.707)))<1.4) Output.x = 5.;
                            if (abs(dot(syp.xy-vec2(3.,1.),vec2(0.707,-0.707)))<1.4) Output.x = 5.;
                        }
                        if (abs(sp.z-7.5)<0.1 && abs(dot(syp.xy-vec2(9.,1.),vec2(0.707,-0.707)))<0.4) Output.x = 5.;
                        if (abs(sp.z-7.5)<0.1 && abs(dot(syp.xy-vec2(3.,1.),vec2(0.707,-0.707)))<0.4) Output.x = 5.;
                //Roof
                    if (sp.z>7.) {
                        if (syp.x>6. && abs(syp.y-(12.5+(syp.x-5.)/11.*4.))<0.5) Output.x = 0.;
                        if (DFLine(rsp,vec3(5.,12.,0.5),vec3(16.,16.,0.5))<1.1) Output.x = 5.;
                        if (DFLine(rsp,vec3(5.,12.,7.5),vec3(16.,16.,7.5))<1.1) Output.x = 5.;
                    }
            //Middle ground walkway
            if (sp.y<2. && length(sp.xz-vec2(16.,18.))<6.) Output.x = 4.; //Circle
                //Entrance
                    if (DFBox(sp-vec3(15.,1.,6.),vec3(2.,1.,23.))<0.) Output.x = 4.;
                    if (DFBox(syp-vec3(14.,1.,6.),vec3(1.,4.,1.))<0.) Output.x = 5.;
                //Middle decor
                    if (sp.y<2. &&  length(sp.xz-vec2(16.,18.))<0.8) Output.x = 1.;
                    if (abs(sp.y-1.5)<0.1 &&  abs(length(sp.xz-vec2(16.,18.))-1.5)<0.3) Output.x = 100.;
                    if (abs(sp.y-2.5)<0.1 &&  abs(length(sp.xz-vec2(16.,18.))-1.5)<0.3) Output.x = 0.;
                        if (length(sp-vec3(16.5,2.5,18.5))<0.1) Output.x = 9.;
                        if (length(sp-vec3(15.5,2.5,17.5))<0.1) Output.x = 9.;
                        if (length(sp-vec3(16.5,2.5,17.5))<0.1) Output.x = 10.;
                        if (length(sp-vec3(15.5,2.5,18.5))<0.1) Output.x = 10.;
        }
    } else if (UV.y<63. && UV.x<256.) {
        //Mipmaps
        Output = vec4(0.);
        float LOD = 4.-floor(-log2(1.-(UV.y-32.)*I32));
        float LRES = pow(2.,LOD);
        if (UV.x<LRES*LRES) {
            vec2 CUV = vec2(floor(mod(UV.x,LRES))*2.+0.5,floor(UV.y-(64.-LRES*2.))*2.+0.5);
            CUV.x += floor(UV.x/LRES)*LRES*4.; //Y Offset
            CUV.y += (64.-LRES*4.); //Mipmap resampling offset
            Output.x = max(max(max(textureCube(CUV).x,textureCube(vec2(CUV.x+1.,CUV.y)).x),
                           max(textureCube(CUV+1.).x,textureCube(vec2(CUV.x,CUV.y+1.)).x)),
                           max(max(textureCube(vec2(CUV.x+LRES*2.,CUV.y)).x,textureCube(vec2(CUV.x+LRES*2.+1.,CUV.y)).x),
                           max(textureCube(vec2(CUV.x+LRES*2.+1.,CUV.y+1.)).x,textureCube(vec2(CUV.x+LRES*2.,CUV.y+1.)).x)));
        }
    } else if (DFBox(UV-vec2(0.,64.),vec2(1024.,192.))<0.) {
        //LPV
        vec3 SunDir = texture(iChannel0,vec2(5.5,0.5)*IRES).xyz;
        bool InsideGeo = false;
        vec2 CUV = UV-vec2(0.,64.);
        vec3 VPos = vec3(mod(CUV.x,32.),floor(CUV.x*I32)+0.5,mod(CUV.y,32.));
        vec3 VNor = ((CUV.y<64.)?vec3(((CUV.y<32.)?-1.:1.),0.,0.):((CUV.y<128.)?
                    vec3(0.,((CUV.y<96.)?-1.:1.),0.):vec3(0.,0.,((CUV.y<160.)?-1.:1.))));
        //Voxelize from mipmap 0
        float GeoIndex = textureCube(vec2(CUV.x,mod(CUV.y,32.))).x;
        InsideGeo = (abs(GeoIndex-3.5)<2.6);
        if (GeoIndex>50.) {
            //Emissive
            Output = vec4(2.5,1.5,1.5,0.);
        } else if (InsideGeo) {
            //Inside geometry
            Output = vec4(0.,0.,0.,0.);
            //Sunlight
            vec3 sPos = VPos+VNor;
            if (dot(VNor,SunDir)>0. && abs(textureCube(vec2(sPos.x+floor(sPos.y)*32.,sPos.z)).x-3.)>3.1) {
                float Visibility = 1.;
                float t = 0.;
                for (float y=0.; y<48.5; y++) {
                    vec3 sp = floor(sPos+t*SunDir);
                    if (DFBox(sp+0.5,vec3(32.))>0.) break;
                    if (abs(textureCube(vec2(sp.x+0.5+sp.y*32.,sp.z+0.5)).x-3.5)<2.6) {
                        Visibility = 0.;
                        break;
                    }
                    t = ABoxfar(sPos,1./SunDir,sp,sp+1.)+0.001;
                }
                Output.xyz = SunLight*dot(VNor,SunDir)*Visibility*0.8; //Magic number
            }
        } else {
            //Outside geometry
            Output.w = 1.;
            vec3 sPos = VPos-VNor;
            //Propagation
            if (DFBox(sPos,vec3(32.))<0.) {
                //Inside volume
                vec2 sUV = vec2(sPos.x+floor(sPos.y)*32.,sPos.z+64.);
                vec3 UVOff = ((CUV.y<64.)?vec3(64.,128.,0.):((CUV.y<128.)?vec3(128.,0.,64.):vec3(0.,64.,128.)));
                float ForwardOff = ((CUV.y<64.)?max(0.,sign(VNor.x))*32.:
                                  ((CUV.y<128.)?max(0.,sign(VNor.y))*32.:max(0.,sign(VNor.z))*32.));
                vec4 ForwardSample = textureCube(sUV+vec2(0.,UVOff.z+ForwardOff));
                Output.xyz = ForwardSample.xyz*mix(1.,LPVForward,ForwardSample.w);
                Output.xyz += (textureCube(sUV+vec2(0.,UVOff.x)).xyz+textureCube(sUV+vec2(0.,UVOff.x+32.)).xyz+
                               textureCube(sUV+vec2(0.,UVOff.y)).xyz+textureCube(sUV+vec2(0.,UVOff.y+32.)).xyz)*LPVSide
                               *ForwardSample.w;
                //Bounce light
                vec2 vUV = vec2(VPos.x+floor(VPos.y)*32.,VPos.z);
                if (abs(textureCube(vec2(sUV.x,sUV.y-64.)).x-3.5)<2.6) {
                    //Geometry behind - magic albedo
                    Output.xyz += textureCube(vUV+vec2(0.,64.+UVOff.z+32.-ForwardOff)).xyz*0.9; //Another magic number
                }
            } else if (VNor.y<-0.9) {
                //Outside volume
                Output.xyz = vec3(0.);
            }
            //Skylight
            if (VNor.y<-0.9) {
                float Visibility = 1.;
                for (float y=floor(VPos.y); y<31.5; y++) {
                    if (abs(textureCube(vec2(VPos.x+y*32.,VPos.z)).x-3.5)<2.6) {
                        Visibility = 0.;
                        break;
                    }
                }
                Output.xyz += SkyLight*0.1*Visibility; //The final magic number
            }
        }
    } else if (DFBox(UV-vec2(0.,256.),vec2(176.,16.))<0.) {
        //Textures
        if (iFrame>2) {
            fragColor = Output;
            return;
            discard;
        } else {
            ivec2 iUV = ivec2(floor(UV.x),floor(UV.y-256.));
            int Index = iUV.x%16+iUV.y*16;
            Output = vec4(0.99);
            if (UV.x<16. || (UV.x>128. && UV.x<144.)) Output = TexGlass[Index];
            else if (UV.x<32.) Output = TexStone[Index];
            else if (UV.x<48.) Output = TexWoodTree[Index];
            else if (UV.x<64.) Output = TexBooks[Index];
            else if (UV.x<80.) Output = TexWood[Index];
            else if (UV.x<128.) Output = TexBricks[Index];
            else if (UV.x>144. && UV.x<160.) Output = TexSapling1[Index];
            else if (UV.x>160. && UV.x<176.) Output = TexSapling2[Index];
        }
    } else {
        fragColor = Output;
        return;
        discard;
    }
    //Output
    fragColor = Output;
}