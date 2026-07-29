// Cube A (cubemap) — LEGO Sanctuary by Mathis
// https://www.shadertoy.com/view/slByR1

//Storage

float Spiral(vec3 p, vec2 sp, float H, float dHdr, float R, float MaxAngle) {
    //Returns the height of a spiral (max 3 turns)
    float Rate=0.4;
    float r=length(p.xz-sp);
    float angle=atan(p.x-sp.x,p.z-sp.y)+3.141592653;
    float sr0=R*pow(Rate,angle/6.283185306);
    float dr=abs(sr0-r); 
    float dr1=abs(sr0*Rate-r);
    if (dr1<dr) { dr=dr1; angle+=6.283185306; }
    dr1=abs(sr0*Rate*Rate-r);
    if (dr1<dr) { dr=dr1; angle+=6.283185306; }
    return max(0.,H-dHdr*dr)*pow(max(0.,1.-angle/MaxAngle),0.5);
}

vec3 HMC[7]=vec3[7](vec3(2.,9.,2.),vec3(3.,7.,3.),vec3(1.,5.,1.),vec3(7.),vec3(5.),vec3(3.),vec3(2.));

float HM(vec3 p) {
    //Samples the heightfield
    float H=3.;
    //Plateau
    float PB=DFBox(p.xz-vec2(48.,44.),vec2(28.,32.));
    H+=max(0.,12.-3.*max(0.,PB));
    //Spirals +Z
    H+=Spiral(p,vec2(66.,98.),8.,3.5,22.,11.);
    //Spirals -Z
    H+=Spiral(p,vec2(66.,31.),10.,3.,15.,14.);
    //Spirals -X
    H=max(H,3.+Spiral(p,vec2(39.,54.),9.,6.,10.,10.)); //Small
    H=max(H,3.+Spiral(p,vec2(46.,84.),9.,3.,16.,11.)); //Epic corner
    //Spirals +X
    H=max(H,3.+Spiral(p,vec2(98.,64.),10.,5.,24.,15.)); //Epic positive
    H=max(H,3.+Spiral(p,vec2(86.,88.),7.,4.,20.,13.)); //Smaller positive >Z
    H+=Spiral(p,vec2(88.,42.),7.,4.,14.,13.); //Smaller positive <Z
    //Noise
    if (PB>0.) H+=pow(texture(iChannel2,p.xz*I1024).z,1.7)*2.;
    //Return
    return H;
}

void AddBrick(inout vec4 Output, vec3 P, vec3 LCP, int Index, float Rot, float Mat, vec3 RGB9) {
    //Adds a brick to the octree
    vec3 LDim=BrickDim[Index];
    if (!(LDim.y>3. && P.y-LCP.y>LDim.y-1. && Output.w>9.99) &&
        !((Index<=5 || Index==14 || Index==15) && P.y-LCP.y>1. && Output.w>9.99)) {
        //No stud overwriting
        if (Rot>0.5) {
            //Rotation
            LDim=LDim.zyx;
            if (DFBox(P-LCP,LDim)<0.) {
                vec3 PDiff=floor(P-LCP).zyx;
                Output=vec4(11.+100.*Mat,RGB9.x+RGB9.y*10.+RGB9.z*100.,PDiff.x+10.*PDiff.y,PDiff.z+10.*float(Index));
            }
        } else {
            //No rotation
            if (DFBox(P-LCP,LDim)<0.) {
                vec3 PDiff=floor(P-LCP);
                Output=vec4(1.+100.*Mat,RGB9.x+RGB9.y*10.+RGB9.z*100.,PDiff.x+10.*PDiff.y,PDiff.z+10.*float(Index));
            }
        }
    }
}

void ColorVoxel(inout vec4 Output, vec3 P, vec3 LCP, vec3 RGB9) {
    //Modifies the color of a voxel
    if (DFBox(P-LCP,vec3(1.))<0.) {
        Output.y=RGB9.x+RGB9.y*10.+RGB9.z*100.;
    }
}

void HMBrickify(inout vec4 Output, vec3 P) {
    //Brickifies a heightmap
    float H=HM(P);
    float HI=floor(H*I3)*3.;
    float FPY=floor(P.y*I3)*3.;
    if (P.y<HI) {
        //Fill bricks under the heightmap
        if (DFBox(P.xz-vec2(48.,44.),vec2(28.,32.))<0.)
            AddBrick(Output,P,vec3(floor(P.x),min(floor(P.y*I3)*3.,HI-3.),floor(P.z)),8,0.,0.,vec3(1.,6.,1.)+floor(texture(iChannel2,P.xz*I1024).y*2.5));
        else
            AddBrick(Output,P,vec3(floor(P.x),min(floor(P.y*I3)*3.,HI-3.),floor(P.z)),8,0.,0.,vec3(4.));
    } else { 
        vec4 H4=floor(vec4(HM(P+vec3(1.,0.,0.)),HM(P+vec3(-1.,0.,0.)),HM(P+vec3(0.,0.,1.)),HM(P+vec3(0.,0.,-1.)))-H+0.5);
        float H4Max=max(max(H4.x,H4.y),max(H4.z,H4.w));
        for (float h=HI; h<H; h++) {
            AddBrick(Output,P,vec3(floor(P.x),h,floor(P.z)),2,0.,0.,HMC[int(max(0.,min(6.,floor(H4Max)-1.)))]);
        }
        if (H4Max>=2.) {
            //Slope
            if (max(H4.x,H4.y)>max(H4.z,H4.w)) {
                //Slope in x
                if (H4.x<H4.y) {
                    //Slope 2 rotated
                    AddBrick(Output,P,vec3(floor(P.x),ceil(H),floor(P.z)),15,0.,0.,HMC[int(min(6.,floor(H4.y)))]);
                } else {
                    //Slope
                    AddBrick(Output,P,vec3(floor(P.x),ceil(H),floor(P.z)),14,0.,0.,HMC[int(min(6.,floor(H4.x)))]);
                }
            } else {
                //Slope in z
                if (H4.z<H4.w) {
                    //Slope 2
                    AddBrick(Output,P,vec3(floor(P.x),ceil(H),floor(P.z)),15,1.,0.,HMC[int(min(6.,floor(H4.w)))]);
                } else {
                    //Slope rotated
                    AddBrick(Output,P,vec3(floor(P.x),ceil(H),floor(P.z)),14,1.,0.,HMC[int(min(6.,floor(H4.z)))]);
                }
            }
        } else {
            float CeilH=ceil(H);
            if ((floor(H)+1.-P.y)<1. && DFBox(P.xz-vec2(48.,60.),vec2(28.,16.))>0.) {
                //Yellow flowers
                if (texture(iChannel2,P.zx*I1024).y>0.92) {
                    AddBrick(Output,P,vec3(floor(P.x),CeilH,floor(P.z)),1,0.,0.,vec3(9.,9.,1.));
                    CeilH+=1.;
                }
            }
            //Flower field
            float CLen=length(P.xz-vec2(26.,64.));
            if (CLen<12.) {
                vec2 Noise=texture(iChannel2,P.zx*I1024).xz;
                Noise.x=floor(Noise.x*pow(1.-CLen/12.,0.707)*7.5);
                if (Noise.y>0.45) {
                    float CH3=floor(Noise.x*I3)*3.;
                    if (CH3>=3.) {
                        AddBrick(Output,P,vec3(floor(P.x),CeilH+
                                        clamp(floor((P.y-CeilH)*I3)*3.,0.,CH3-3.),floor(P.z)),6,0.,0.,vec3(9.,2.,0.));
                        AddBrick(Output,P,vec3(floor(P.x),
                                        clamp(floor(P.y),CeilH+CH3,CeilH+Noise.x),floor(P.z)),1,0.,0.,vec3(9.,6.,1.));
                    } else {
                        AddBrick(Output,P,vec3(floor(P.x),clamp(floor(P.y),CeilH,CeilH+Noise.x),floor(P.z)),1,0.,0.,vec3(9.,3.,1.));
                    }
                }
            }
        }
    }
}

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign=-mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D=vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D=D.xzy;
    else if (UV.y>2048.) D=D.zxy;
    return texture(iChannel3,D);
}

void RenderStud(inout vec4 Output, vec3 StudPos, vec2 PixelUV) {
    //Renders a stud positioned at StudPos
    vec2 UV=((PixelUV-vec2(dot(StudPos,IsoTan),dot(StudPos,IsoBit)))*Sqrt2*0.5+0.5)*128.;
    if (DFBox(UV,vec2(128.))<0.) {
        vec4 A=textureCube(vec2(256.,2370.)+UV);
        A.w+=dot(StudPos,IsoDir);
        if (A.w<9999. && A.w<Output.w) Output=A;
    }
}

void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir) {
    vec4 Output=vec4(0.,0.,0.,10000.);
    vec2 UV; vec3 aDir=abs(rayDir);
    if (aDir.z>max(aDir.x,aDir.y)) {
        //Z-side
        UV = floor(((rayDir.xy/aDir.z)*0.5+0.5)*1024.)+0.5;
        if (rayDir.z<0.) UV.y+=1024.;
    } else if (aDir.x>aDir.y) {
        //X-side
        UV = floor(((rayDir.yz/aDir.x)*0.5+0.5)*1024.)+0.5;
        if (rayDir.x>0.) UV.y+=2048.;
        else UV.y+=3072.;
    } else {
        //Y-side
        UV = floor(((rayDir.xz/aDir.y)*0.5+0.5)*1024.)+0.5;
        if (rayDir.y>0.) UV.y+=4096.;
        else UV.y+=5120.;
    }
    //Octree
    if (DFBox(UV,vec2(1024.,2048.))<0.) {
        //LOD 0
        if (iFrame>3 && texelFetch(iChannel0,ivec2(iChannelResolution[0].xy-1.),0).x<=0.) {
            //Skip brickification
            fragColor=texture(iChannel3,rayDir);
            return;
        } else {
            //Brickification
            Output=vec4(0.); vec2 sfp;
            vec3 Pos=vec3(mod(UV.x,128.),floor(UV.x*I128)+8.*floor(UV.y*I128)+0.5,mod(UV.y,128.));
            //Heightmap
            HMBrickify(Output,Pos);
            //House
            if (Pos.y<35.) {
                //Lower part of the house
                //Foundation and ceiling
                    if (DFBox(Pos.xz-vec2(60.,60.),vec2(16.,16.))<0.) {
                        sfp=vec2(floor(Pos.x*0.25)*4.,floor(Pos.z*0.5)*2.);
                        AddBrick(Output,Pos,vec3(sfp.x,15.,sfp.y),5,0.,0.,vec3(6.));
                    }
                    if (DFBox(Pos.xz-vec2(48.,64.),vec2(12.,12.))<0.) {
                        sfp=vec2(floor(Pos.x*0.25)*4.,floor(Pos.z*0.5)*2.);
                        AddBrick(Output,Pos,vec3(sfp.x,15.,sfp.y),5,0.,0.,vec3(6.));
                    }
                //Door wall
                    if (DFBox(Pos.xz-vec2(48.,63.),vec2(12.,2.))<0.) {
                        //Y15
                        AddBrick(Output,Pos,vec3(51.,15.,63.),2,0.,0.,vec3(5.));
                            AddBrick(Output,Pos,vec3(56.,15.,63.),2,0.,0.,vec3(5.));
                        AddBrick(Output,Pos,vec3(59.,15.,63.),6,0.,0.,vec3(3.)); //Rund3
                        //Y16
                        AddBrick(Output,Pos,vec3(48.,16.,64.),10,0.,0.,vec3(9.)); //431
                            AddBrick(Output,Pos,vec3(56.,16.,64.),10,0.,0.,vec3(9.)); //431
                        AddBrick(Output,Pos,vec3(51.,16.,63.),16,1.,0.,vec3(9.)); //Headlight
                            AddBrick(Output,Pos,vec3(56.,16.,63.),16,1.,0.,vec3(9.)); //Headlight
                        //Y19
                        AddBrick(Output,Pos,vec3(51.,19.,63.),12,1.,0.,vec3(7.)); //Slope
                            AddBrick(Output,Pos,vec3(56.,19.,63.),12,1.,0.,vec3(7.)); //Slope
                        AddBrick(Output,Pos,vec3(57.,19.,64.),10,0.,0.,vec3(9.)); //431
                            AddBrick(Output,Pos,vec3(48.,19.,64.),10,0.,0.,vec3(9.)); //431
                        //Y22
                        AddBrick(Output,Pos,vec3(56.,22.,64.),5,0.,0.,vec3(4.)); //412
                            AddBrick(Output,Pos,vec3(48.,22.,64.),5,0.,0.,vec3(4.)); //412
                        //Y23
                        AddBrick(Output,Pos,vec3(57.,23.,64.),10,0.,0.,vec3(9.)); //431
                            AddBrick(Output,Pos,vec3(48.,23.,64.),10,0.,0.,vec3(9.)); //431
                        AddBrick(Output,Pos,vec3(56.,23.,64.),16,1.,0.,vec3(9.)); //Headlight
                            AddBrick(Output,Pos,vec3(51.,23.,64.),16,1.,0.,vec3(9.)); //Headlight
                        //Y26
                        AddBrick(Output,Pos,vec3(56.,26.,64.),10,0.,0.,vec3(9.)); //431
                            AddBrick(Output,Pos,vec3(48.,26.,64.),10,0.,0.,vec3(9.)); //431
                        //Y29
                        AddBrick(Output,Pos,vec3(56.,29.,64.),10,0.,0.,vec3(9.)); //431
                            AddBrick(Output,Pos,vec3(48.,29.,64.),10,0.,0.,vec3(9.)); //431
                        //Y32
                        AddBrick(Output,Pos,vec3(floor(Pos.x*0.25)*4.,31.,64.),10,0.,0.,vec3(9.)); //431
                        AddBrick(Output,Pos,vec3(59.,32.,63.),13,1.,0.,vec3(9.)); //ISlope
                            AddBrick(Output,Pos,vec3(48.,32.,63.),13,1.,0.,vec3(9.)); //ISlope
                    }
                //Small Ortho Door wall
                    if (DFBox(Pos.xz-vec2(60.,60.),vec2(1.,5.))<0.) {
                        //Y16
                        AddBrick(Output,Pos,vec3(60.,16.,61.),10,1.,0.,vec3(9.)); //431
                        //Y19
                        AddBrick(Output,Pos,vec3(60.,19.,60.),10,1.,0.,vec3(9.)); //431
                        //Y22
                        AddBrick(Output,Pos,vec3(60.,22.,61.),5,1.,0.,vec3(4.)); //411
                        //Y23
                        AddBrick(Output,Pos,vec3(60.,23.,60.),10,1.,0.,vec3(9.)); //431
                        //Y26
                        AddBrick(Output,Pos,vec3(60.,26.,61.),10,1.,0.,vec3(9.)); //431
                        //Y29
                        AddBrick(Output,Pos,vec3(60.,29.,60.),10,1.,0.,vec3(9.)); //431
                        //Y32
                        AddBrick(Output,Pos,vec3(60.,32.,60.),10,1.,0.,vec3(9.)); //431
                    }
                //Flower wall
                    if (DFBox(Pos.xz-vec2(60.,59.),vec2(16.,2.))<0. && DFBox(Pos-vec3(66.,23.,60.),vec3(4.,9.,1.))>0.) {
                        //Y15 (Spotlights)
                        AddBrick(Output,Pos,vec3(62.,15.,59.),1,0.,1.,vec3(9.,7.,7.)); //Rund
                        AddBrick(Output,Pos,vec3(73.,15.,59.),1,0.,1.,vec3(9.,7.,7.)); //Rund
                        //Y16
                        AddBrick(Output,Pos,vec3(floor(Pos.x*0.25)*4.,16.,60.),10,0.,0.,vec3(9.)); //431
                        AddBrick(Output,Pos,vec3(clamp(floor(Pos.x),67.,68.),16.,60.),16,1.,0.,vec3(9.)); //Headlight
                            AddBrick(Output,Pos,vec3(69.,16.,60.),8,0.,0.,vec3(9.)); //131
                        //Y19
                        if (Pos.x>62. && Pos.x<74.) {
                            AddBrick(Output,Pos,vec3(2.+floor(Pos.x*0.25-0.5)*4.,19.,60.),10,0.,0.,vec3(9.)); //431
                        }
                        AddBrick(Output,Pos,vec3(61.,19.,60.),8,0.,0.,vec3(9.)); //131
                            AddBrick(Output,Pos,vec3(74.,19.,60.),8,0.,0.,vec3(9.)); //131
                        AddBrick(Output,Pos,vec3(66.,19.,59.),13,1.,0.,vec3(7.)); //ISlope
                            AddBrick(Output,Pos,vec3(69.,19.,59.),13,1.,0.,vec3(7.)); //ISlope
                        //Y22
                        AddBrick(Output,Pos,vec3(66.,22.,59.),5,0.,0.,vec3(4.,2.,2.)); //411 (Under flowers)
                            AddBrick(Output,Pos,vec3(66.,23.+clamp(floor(Pos.y-23.),0.,1.),59.),1,0.,0.,vec3(9.,4.,2.));
                            AddBrick(Output,Pos,vec3(67.,23.,59.),1,0.,0.,vec3(2.,7.,2.));
                            AddBrick(Output,Pos,vec3(68.,23.,59.),1,0.,0.,vec3(0.,9.,0.));
                            AddBrick(Output,Pos,vec3(69.,23.+clamp(floor(Pos.y-23.),0.,2.),59.),1,0.,0.,vec3(9.,7.,2.));
                        AddBrick(Output,Pos,vec3(floor(Pos.x*0.25)*4.,22.,60.),5,0.,0.,vec3(4.)); //411
                        //Y23
                        if (Pos.x>62. && Pos.x<74.) {
                            AddBrick(Output,Pos,vec3(2.+floor(Pos.x*0.25-0.5)*4.,23.,60.),10,0.,0.,vec3(9.)); //431
                        }
                        AddBrick(Output,Pos,vec3(61.,23.,60.),8,0.,0.,vec3(9.)); //131
                            AddBrick(Output,Pos,vec3(74.,23.,60.),8,0.,0.,vec3(9.)); //131
                        //Y26
                        AddBrick(Output,Pos,vec3(floor(Pos.x*0.25)*4.,26.,60.),10,0.,0.,vec3(9.)); //431
                        //Y29
                        if (Pos.x>62. && Pos.x<74.) {
                            AddBrick(Output,Pos,vec3(2.+floor(Pos.x*0.25-0.5)*4.,29.,60.),10,0.,0.,vec3(9.)); //431
                        }
                        AddBrick(Output,Pos,vec3(61.,29.,60.),8,0.,0.,vec3(9.)); //131
                            AddBrick(Output,Pos,vec3(74.,29.,60.),8,0.,0.,vec3(9.)); //131
                        //Y32
                        if (Pos.x>62. && Pos.x<74.) {
                            AddBrick(Output,Pos,vec3(2.+floor(Pos.x*0.25-0.5)*4.,32.,60.),10,0.,0.,vec3(9.)); //431
                        }
                        AddBrick(Output,Pos,vec3(61.,32.,59.),13,1.,0.,vec3(9.)); //ISlope
                            AddBrick(Output,Pos,vec3(65.,32.,59.),13,1.,0.,vec3(9.)); //ISlope
                            AddBrick(Output,Pos,vec3(70.,32.,59.),13,1.,0.,vec3(9.)); //ISlope
                            AddBrick(Output,Pos,vec3(74.,32.,59.),13,1.,0.,vec3(9.)); //ISlope
                        //131 for window
                        AddBrick(Output,Pos,vec3(70.,22.+clamp(floor((Pos.y-22.)*I3),0.,2.)*3.,60.),8,0.,0.,vec3(9.));
                    }
                //Wall orth/behind flower wall
                    if (DFBox(Pos.xz-vec2(75.,60.),vec2(1.,16.))<0.) {
                        //Y16
                        AddBrick(Output,Pos,vec3(75.,16.+clamp(floor((Pos.y-16.)*I3),0.,5.)*3.,
                                                 floor(Pos.z*0.25)*4.),10,1.,0.,vec3(9.)); //431
                        ColorVoxel(Output,Pos,vec3(75.,22.,60.),vec3(4.));
                    }
                //Wall ortho/behind door
                    if (DFBox(Pos.xz-vec2(48.,65.),vec2(1.,11.))<0.) {
                        //Y16
                        AddBrick(Output,Pos,vec3(48.,16.,floor(Pos.z*0.25)*4.),10,1.,0.,vec3(9.)); //431
                        //Y19
                        AddBrick(Output,Pos,vec3(48.,19.,2.+floor(Pos.z*0.25-0.5)*4.),10,1.,0.,vec3(9.)); //431
                        //Y22
                        AddBrick(Output,Pos,vec3(48.,22.,floor(Pos.z*0.25)*4.),5,1.,0.,vec3(5.)); //412
                        //Y23
                        AddBrick(Output,Pos,vec3(48.,23.,floor(Pos.z*0.25)*4.),10,1.,0.,vec3(9.)); //431
                        //Y26
                        AddBrick(Output,Pos,vec3(48.,26.,2.+floor(Pos.z*0.25-0.5)*4.),10,1.,0.,vec3(9.)); //431
                        //Y29
                        AddBrick(Output,Pos,vec3(48.,29.,floor(Pos.z*0.25)*4.),10,1.,0.,vec3(9.)); //431
                        //Y32
                        AddBrick(Output,Pos,vec3(48.,32.,2.+floor(Pos.z*0.25-0.5)*4.),10,1.,0.,vec3(9.)); //431
                    }
                //Railing on +X side
                    if (DFBox(Pos.xz-vec2(62.,44.),vec2(14.,16.))<0.) {
                        AddBrick(Output,Pos,vec3(75.,15.,2.+floor((Pos.z-2.)*I3)*3.),7,0.,0.,vec3(6.)); //Kon
                            AddBrick(Output,Pos,vec3(75.,18.,floor(Pos.z*0.5)*2.),3,1.,0.,vec3(9.)); //211
                            AddBrick(Output,Pos,vec3(75.,19.,2.+floor((Pos.z-2.)*I3)*3.),3,1.,0.,vec3(9.,9.,4.)); //211
                        AddBrick(Output,Pos,vec3(floor(Pos.x*I3)*3.,15.,44.),7,0.,0.,vec3(6.)); //Kon
                            AddBrick(Output,Pos,vec3(floor(Pos.x*0.5)*2.,18.,44.),3,0.,0.,vec3(9.)); //211
                            AddBrick(Output,Pos,vec3(2.+floor((Pos.x-2.)*I3)*3.,19.,44.),3,0.,0.,vec3(9.,9.,4.)); //211
                    }
            }
            if (Pos.y>=35.) {
                //Upper part of the house
                //Floor
                    if (DFBox(Pos.xz-vec2(60.,59.),vec2(16.,18.))<0.) {
                        sfp=vec2(floor(Pos.x*0.25)*4.,1.+floor(Pos.z*0.5-0.5)*2.);
                        AddBrick(Output,Pos,vec3(sfp.x,35.,sfp.y),5,0.,0.,vec3(6.));
                    }
                    if (DFBox(Pos.xz-vec2(48.,63.),vec2(12.,13.))<0.) {
                        sfp=vec2(floor(Pos.x*0.25)*4.,1.+floor(Pos.z*0.5-0.5)*2.);
                        AddBrick(Output,Pos,vec3(sfp.x,35.,sfp.y),5,0.,0.,vec3(6.));
                    }
                //Sloped ceiling
                    if (DFBox(Pos.xz-vec2(59.,59.),vec2(18.,9.))<0.) {
                        sfp.y=floor((Pos.y-36.)*I3);
                        AddBrick(Output,Pos,vec3(mod(sfp.y,2.)+1.+floor(Pos.x*0.5-0.5-mod(sfp.y,2.)*0.5)*2.,
                                36.+max(0.,sfp.y*3.),59.+sfp.y),4,1.,0.,vec3(9.,0.,0.)); //2Slope
                        sfp.y=floor((Pos.y-39.)*I6)*2.;
                        AddBrick(Output,Pos,vec3(59.,39.+max(0.,sfp.y*3.),60.+sfp.y),12,1.,0.,vec3(9.,0.,0.)); //Slope
                    }
                    if (DFBox(Pos.xz-vec2(59.,68.),vec2(16.,9.))<0.) {
                        sfp.y=floor((Pos.y-36.)*I3);
                        AddBrick(Output,Pos,vec3(1.+floor(Pos.x*0.5-0.5)*2.,
                                36.+max(0.,sfp.y*3.),75.-sfp.y),11,1.,0.,vec3(9.,0.,0.)); //2Slope
                    }
                //Wall patio
                    if (DFBox(Pos-vec3(59.,36.,61.),vec3(2.,24.,14.))<0. && DFBox(Pos-vec3(60.,36.,67.),vec3(1.,15.,4.))>0.) {
                        //Y36
                        AddBrick(Output,Pos,vec3(60.,36.,61.+floor((Pos.z-61.)*0.25)*4.),10,1.,0.,vec3(9.)); //431
                        //Y39
                        if (Pos.z>62. && Pos.z<74.)
                            AddBrick(Output,Pos,vec3(60.,39.,62.+floor((Pos.z-62.)*0.25)*4.),10,1.,0.,vec3(9.)); //431
                        //Y42
                        if (Pos.z>63. && Pos.z<73.)
                            AddBrick(Output,Pos,vec3(60.,42.,63.+floor((Pos.z-63.)*0.25)*4.),10,1.,0.,vec3(9.)); //431
                        //Y45
                        if (Pos.z>64. && Pos.z<72.)
                            AddBrick(Output,Pos,vec3(60.,45.,floor(Pos.z*0.25)*4.),10,1.,0.,vec3(9.)); //431
                            //Lamp
                            AddBrick(Output,Pos,vec3(59.,45.,71.),12,0.,0.,vec3(9.,6.,6.));
                                AddBrick(Output,Pos,vec3(59.,42.,71.),6,0.,1.,vec3(9.,9.,4.));
                        //Y48
                        if (Pos.z>65. && Pos.z<71.)
                            AddBrick(Output,Pos,vec3(60.,48.,65.+floor((Pos.z-65.)*0.5)*2.),9,1.,0.,vec3(9.)); //231
                        //Y51
                        AddBrick(Output,Pos,vec3(60.,51.,66.),10,1.,0.,vec3(9.)); //431
                        //Y54
                        AddBrick(Output,Pos,vec3(60.,54.,67.),9,1.,0.,vec3(9.)); //231
                        //131 for door
                        AddBrick(Output,Pos,vec3(60.,36.+clamp(floor((Pos.y-36.)*I3),0.,4.)*3.,71.),8,0.,0.,vec3(9.));
                    }
                //Patio
                    if (DFBox(Pos.xz-vec2(48.,63.),vec2(11.,13.))<0.) {
                        //Y36
                        AddBrick(Output,Pos,vec3(floor(Pos.x*0.5)*2.,36.,63.),7,0.,0.,vec3(9.,7.,2.)); //Kon131
                            AddBrick(Output,Pos,vec3(floor(Pos.x*0.5)*2.,36.,75.),7,0.,0.,vec3(9.,7.,2.)); //Kon131
                            AddBrick(Output,Pos,vec3(48.,36.,1.+floor(Pos.z*0.5-0.5)*2.),7,0.,0.,vec3(9.,7.,2.)); //Kon131
                        //Y39
                        AddBrick(Output,Pos,vec3(floor(Pos.x*0.5)*2.,39.,63.),3,0.,0.,vec3(9.)); //211
                            AddBrick(Output,Pos,vec3(floor(Pos.x*0.5)*2.,39.,75.),3,0.,0.,vec3(9.)); //211
                            AddBrick(Output,Pos,vec3(48.,39.,1.+floor(Pos.z*0.5-0.5)*2.),3,1.,0.,vec3(9.)); //211
                    }
            }
        }
    } else if (DFBox(UV-vec2(0.,2048.),vec2(1024.,256.))<0.) {
        //LOD 1
        Output=vec4(0.);
        vec2 CUV=vec2(UV.x,UV.y-2048.);
        vec3 Pos=floor(vec3(mod(CUV.x,64.),floor(CUV.x*I64)+16.*floor(CUV.y*I64),mod(CUV.y,64.)))*2.+0.5;
        vec2 LUV1=vec2(Pos.x+128.*mod(floor(Pos.y),8.),Pos.z+128.*floor(Pos.y*0.125));
        vec2 LUV2=vec2(Pos.x+128.*mod(floor(Pos.y)+1.,8.),Pos.z+128.*floor((Pos.y+1.)*0.125));
        Output.x=float(textureCube(LUV1).x>0.);
        Output.x+=float(textureCube(LUV1+vec2(1.,0.)).x>0.);
        Output.x+=float(textureCube(LUV1+vec2(0.,1.)).x>0.);
        Output.x+=float(textureCube(LUV1+vec2(1.)).x>0.);
        Output.x+=float(textureCube(LUV2).x>0.);
        Output.x+=float(textureCube(LUV2+vec2(1.,0.)).x>0.);
        Output.x+=float(textureCube(LUV2+vec2(0.,1.)).x>0.);
        Output.x+=float(textureCube(LUV2+vec2(1.)).x>0.);
        Output.x*=0.125;
    } else if (DFBox(UV-vec2(0.,2304.),vec2(1024.,32.))<0.) {
        //LOD 2
        Output=vec4(0.);
        vec2 CUV=vec2(UV.x,UV.y-2304.);
        vec3 Pos=floor(vec3(mod(CUV.x,32.),floor(CUV.x*I32),mod(CUV.y,32.)))*2.+0.5;
        vec2 LUV1=vec2(Pos.x+64.*mod(floor(Pos.y),16.),Pos.z+64.*floor(Pos.y*I16)+2048.);
        vec2 LUV2=vec2(Pos.x+64.*mod(floor(Pos.y)+1.,16.),Pos.z+64.*floor((Pos.y+1.)*I16)+2048.);
        Output=0.125*(textureCube(LUV1)+textureCube(LUV1+vec2(1.,0.))+textureCube(LUV1+vec2(0.,1.))+textureCube(LUV1+vec2(1.))+
                      textureCube(LUV2)+textureCube(LUV2+vec2(1.,0.))+textureCube(LUV2+vec2(0.,1.))+textureCube(LUV2+vec2(1.)));
    } else if (DFBox(UV-vec2(0.,2336.),vec2(256.,32.))<0.) {
        //LOD > 2
        Output=vec4(0.);
        float POW=floor(log2(2368.-UV.y));
        float S=pow(2.,POW);
        float IS=pow(0.5,POW);
        if (UV.x<S*S) {
            vec2 CUV=vec2(UV.x,UV.y-2368.+2.*S);
            vec3 Pos=floor(vec3(mod(CUV.x,S),floor(CUV.x*IS),mod(CUV.y,S)))*2.+0.5;
            vec2 LUV1=vec2(Pos.x+2.*S*floor(Pos.y),Pos.z+2368.-4.*S);
            vec2 LUV2=vec2(Pos.x+2.*S*(floor(Pos.y)+1.),Pos.z+2368.-4.*S);
            Output=0.125*(textureCube(LUV1)+textureCube(LUV1+vec2(1.,0.))+textureCube(LUV1+vec2(0.,1.))+textureCube(LUV1+vec2(1.))+
                      textureCube(LUV2)+textureCube(LUV2+vec2(1.,0.))+textureCube(LUV2+vec2(0.,1.))+textureCube(LUV2+vec2(1.)));
        }
    } else if (UV.y>5120.) {
        Output=texture(iChannel2,vec2(UV.x,UV.y-2368.)*I1024);
    }
    //Logo
    if (DFBox(UV-vec2(0.,2370.),vec2(128.))<0.) {
        //LEGO logo SVG
        if (iFrame > 0) {
            fragColor=texture(iChannel3,rayDir);
            return;
        } else {
            vec2 fragCoord=UV-vec2(0.,2370.);
            float normalizer = float(samples * samples);  
            float step = 1.0 / float(samples);
            for (int sx = 0; sx < samples; sx++) {
                for (int sy = 0; sy < samples; sy++) {  
                    vec2 uv = (fragCoord + vec2(float(sx), float(sy)) * step)*I128;
                    uv *= 2.0;
                    uv -= vec2(1.0);
                    uv *= 2.24;
                    if (inPath(uv)) {
                        fragColor += vec4(1.0);
                    }
                }
            }
            Output=vec4(fragColor.xyz/normalizer,1.);
        }
    } else if (DFBox(UV-vec2(128.,2370.),vec2(128.))<0.) {
        //LEGO logo gradient
        if (iFrame > 1) {
            fragColor=texture(iChannel3,rayDir);
            return;
        } else {
            for (float i=-2.; i<2.5; i++) {
                for (float j=-2.; j<2.5; j++) {
                    if (i==0. && j==0.) continue;
                    Output.xy+=normalize(vec2(i,j))*textureCube(UV-vec2(128.,0.)+vec2(i,j)).x;
                }
            }
            Output=vec4(normalize(vec3(-Output.y/45.,0.5,-Output.x/45.)),1.);
        }
    }
    //Pre-rendering
    vec2 IsoUV=vec2(UV.x,UV.y-2370.); vec2 IsoPos;
    float AASize=max(1.,256.*IsoWidth*Sqrt05/iChannelResolution[0].x); //Not used
    vec2 AAOff=vec2(0.); //Not used
    if (IsoUV.y<128.) {
        if (DFBox(IsoUV-vec2(256.,0.),vec2(128.))<0.) {
            //Stud
            vec2 PixelUV=(vec2(IsoUV.x-256.,IsoUV.y)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(1.,0.,1.)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=TraceStud(Pos,IsoDir,IsoDistance+10.);
            vec3 llp=Pos+IsoDir*Output.w;
            if (Output.w>0. && llp.y>0.199) {
                //Samples the gradient
                Output.xyz=textureCube(vec2(fract(llp.z),fract(llp.x))*128.+vec2(128.,2370.)).xyz;
            }
        } else if (DFBox(IsoUV-vec2(384.,0.),vec2(128.))<0.) {
            //Rund
            vec2 PixelUV=(vec2(IsoUV.x-384.,IsoUV.y)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(1.,0.,1.)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=TraceRund(Pos,IsoDir,IsoDistance+10.);
            RenderStud(Output,vec3(0.,0.4,0.),PixelUV);
        } else if (DFBox(IsoUV-vec2(512.,0.),vec2(128.))<0.) {
            //111
            vec2 PixelUV=(vec2(IsoUV.x-512.,IsoUV.y)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(1.,0.,1.)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=Trace111(Pos,IsoDir,IsoDistance+10.);
            RenderStud(Output,vec3(0.,0.4,0.),PixelUV);
        } else if (DFBox(IsoUV-vec2(640.,0.),vec2(256.,128.))<0.) {
            //211
            vec2 PixelUV=(vec2(IsoUV.x-640.,IsoUV.y)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(2.,0.,0.)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=Trace211(Pos,IsoDir,IsoDistance+10.);
            RenderStud(Output,vec3(-1.,0.4,1.),PixelUV);
            RenderStud(Output,vec3(0.,0.4,1.),PixelUV);
        }
    }
    if (DFBox(IsoUV-vec2(0.,128.),vec2(256.))<0.) {
        //2Slope
        vec2 PixelUV=(vec2(IsoUV.x,IsoUV.y-128.)+AAOff-64.)*I64*Sqrt05;
        vec3 Pos=vec3(1.5,0.,0.5)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
        Output=Trace2Slope(Pos,IsoDir,IsoDistance+10.);
        RenderStud(Output,vec3(0.5,1.2,0.5),PixelUV);
        RenderStud(Output,vec3(0.5,1.2,1.5),PixelUV);
    } else if (DFBox(IsoUV-vec2(256.,128.),vec2(512.,256.))<0.) {
        //412
        vec2 PixelUV=(vec2(IsoUV.x-256.,IsoUV.y-128.)+AAOff-64.)*I64*Sqrt05;
        vec3 Pos=vec3(3.5,0.,-1.5)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
        Output=Trace412(Pos,IsoDir,IsoDistance+10.);
        RenderStud(Output,vec3(-2.5,0.4,2.5),PixelUV); RenderStud(Output,vec3(-1.5,0.4,2.5),PixelUV);
        RenderStud(Output,vec3(-0.5,0.4,2.5),PixelUV); RenderStud(Output,vec3(0.5,0.4,2.5),PixelUV);
        RenderStud(Output,vec3(-2.5,0.4,3.5),PixelUV); RenderStud(Output,vec3(-1.5,0.4,3.5),PixelUV);
        RenderStud(Output,vec3(-0.5,0.4,3.5),PixelUV); RenderStud(Output,vec3(0.5,0.4,3.5),PixelUV);
    } else if (DFBox(IsoUV-vec2(768.,128.),vec2(128.,256.))<0.) {
        //Rund131
        vec2 PixelUV=(vec2(IsoUV.x-768.,IsoUV.y-128.)+AAOff-64.)*I64*Sqrt05;
        vec3 Pos=vec3(1.,0.,1.)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
        Output=TraceRund131(Pos,IsoDir,IsoDistance+10.);
    } else if (DFBox(IsoUV-vec2(896.,0.),vec2(128.,256.))<0.) {
        //Kon131
        vec2 PixelUV=(vec2(IsoUV.x-896.,IsoUV.y)+AAOff-64.)*I64*Sqrt05;
        vec3 Pos=vec3(1.,0.,1.)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
        Output=TraceKon131(Pos,IsoDir,IsoDistance+10.);
    } else if (DFBox(IsoUV-vec2(896.,256.),vec2(128.,256.))<0.) {
        //131
        vec2 PixelUV=(vec2(IsoUV.x-896.,IsoUV.y-256.)+AAOff-64.)*I64*Sqrt05;
        vec3 Pos=vec3(1.,0.,1.)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
        Output=Trace131(Pos,IsoDir,IsoDistance+10.);
        RenderStud(Output,vec3(0.,1.2,0.),PixelUV);
    }
    if (IsoUV.y>384.) {
        if (DFBox(IsoUV-vec2(0.,384.),vec2(256.))<0.) {
            //231
            vec2 PixelUV=(vec2(IsoUV.x,IsoUV.y-384.)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(1.5,0.,0.5)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=Trace231(Pos,IsoDir,IsoDistance+10.);
            RenderStud(Output,vec3(0.5,1.2,0.5),PixelUV); RenderStud(Output,vec3(-0.5,1.2,0.5),PixelUV);
        } else if (DFBox(IsoUV-vec2(256.,384.),vec2(512.,256.))<0.) {
            //431
            vec2 PixelUV=(vec2(IsoUV.x-256.,IsoUV.y-384.)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(3.5,0.,-1.5)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=Trace431(Pos,IsoDir,IsoDistance+10.);
            RenderStud(Output,vec3(-2.5,1.2,2.5),PixelUV); RenderStud(Output,vec3(-1.5,1.2,2.5),PixelUV);
            RenderStud(Output,vec3(-0.5,1.2,2.5),PixelUV); RenderStud(Output,vec3(0.5,1.2,2.5),PixelUV);
        } else if (DFBox(IsoUV-vec2(768.,512.),vec2(256.))<0.) {
            //2Slope2
            vec2 PixelUV=(vec2(IsoUV.x-768.,IsoUV.y-512.)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(1.5,0.,0.5)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=Trace2Slope2(Pos,IsoDir,IsoDistance+10.);
            RenderStud(Output,vec3(-0.5,1.2,0.5),PixelUV);
            RenderStud(Output,vec3(-0.5,1.2,1.5),PixelUV);
        }
    }
    if (IsoUV.y>640. && IsoUV.y<896.) {
        if (DFBox(IsoUV-vec2(0.,640.),vec2(256.))<0.) {
            //Slope
            vec2 PixelUV=(vec2(IsoUV.x,IsoUV.y-640.)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(1.5,0.,0.5)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=TraceSlope(Pos,IsoDir,IsoDistance+10.);
            RenderStud(Output,vec3(0.5,1.2,0.5),PixelUV);
        } else if (DFBox(IsoUV-vec2(256.,640.),vec2(256.))<0.) {
            //Inverse slope
            vec2 PixelUV=(vec2(IsoUV.x-256.,IsoUV.y-640.)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(1.5,0.,0.5)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=TraceISlope(Pos,IsoDir,IsoDistance+10.);
            RenderStud(Output,vec3(0.5,1.2,0.5),PixelUV);
        } else if (DFBox(IsoUV-vec2(512.,640.),vec2(128.,256.))<0.) {
            //Only slope
            vec2 PixelUV=(vec2(IsoUV.x-512.,IsoUV.y-640.)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(1.,0.,1.)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=TraceOnlySlope(Pos,IsoDir,IsoDistance+10.);
        } else if (DFBox(IsoUV-vec2(640.,640.),vec2(128.,256.))<0.) {
            //Only slope 2
            vec2 PixelUV=(vec2(IsoUV.x-640.,IsoUV.y-640.)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(1.,0.,1.)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=TraceOnlySlope2(Pos,IsoDir,IsoDistance+10.);
        }
    }
    if (IsoUV.y>896. && IsoUV.y<1152.) {
        if (DFBox(IsoUV-vec2(0.,896.),vec2(128.,256.))<0.) {
            //Headlight
            vec2 PixelUV=(vec2(IsoUV.x,IsoUV.y-896.)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(1.,0.,1.)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=TraceHeadLight(Pos,IsoDir,IsoDistance+10.);
            RenderStud(Output,vec3(0.,1.2,0.),PixelUV);
        } else if (DFBox(IsoUV-vec2(256.,896.),vec2(256.))<0.) {
            //Inverse slope 2
            vec2 PixelUV=(vec2(IsoUV.x-256.,IsoUV.y-896.)+AAOff-64.)*I64*Sqrt05;
            vec3 Pos=vec3(1.5,0.,0.5)-IsoDir*IsoDistance+IsoTan*PixelUV.x+IsoBit*PixelUV.y;
            Output=TraceISlope2(Pos,IsoDir,IsoDistance+10.);
            RenderStud(Output,vec3(-0.5,1.2,0.5),PixelUV);
        }
    }
    //Output
    fragColor=Output;
}