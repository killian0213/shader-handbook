// Buffer A (buffer) — Analytic Direct Illumination by Mathis
// https://www.shadertoy.com/view/NttSW7

//Stores the scene

vec2 NearestPoint(vec2 UV) {
    vec2 Index = vec2(-1.);
    vec4 linep; float Len1,Len2;
    for (float i=0.; i<NObjects; i++) {
        linep = texture(iChannel0,vec2(1.5+i,0.5)*IRES);
        if (LineDF(UV,linep.xy,linep.zw)<InteractRadius) {
            //Click in the middle
            Index = vec2(i*2.,1.);
        }
        Len1 = length(UV-linep.xy);
        if (Len1<InteractRadius) {
            Index = vec2(i*2.,0.);
        }
        Len2 = length(UV-linep.zw);
        if (Len2<InteractRadius && Len2<Len1) {
            Index = vec2(i*2.+1.,0.);
        }
    }
    return Index;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = texture(iChannel0,fragCoord*IRES);
    if (fragCoord.y<1. && fragCoord.x<1.) {
        //Object and mouse position
        if (iFrame<2) {
            Output = vec4(-1.,-1.,iMouse.xy);
        } else {
            if (Output.x<-0.5) {
                vec2 OID = NearestPoint(iMouse.xy);
                if (iMouse.z>0.) {
                    Output.xy = OID;
                }
            } else if (iMouse.z<0.)
                Output.x = -1.;
            //Mouse position
            Output.zw = iMouse.xy;
        }
    } else if (fragCoord.y<1. && fragCoord.x<16.) {
        //Objects
        float Obj = floor(fragCoord.x)-1.;
        if (iFrame<2 || texelFetch(iChannel1,ivec2(82,1),0).x>0.) {
            //Initial scene geometry
            if (Obj<0.5) Output = vec4(0.1*RES.x,0.0999*RES.y,0.9*RES.x,0.3*RES.y); //Floor
            else if (Obj<1.5) Output = vec4(0.1*RES.x,0.1*RES.y,0.05*RES.x,0.95*RES.y); //Vertical wall
            else if (Obj<2.5) Output = vec4(0.05*RES.x,0.95*RES.y,0.4*RES.x,0.8*RES.y); //Small ceiling
            else if (Obj<3.5) Output = vec4(0.5*RES.x,0.77*RES.y,0.9*RES.x,0.4*RES.y); //Ceiling higher up
            else if (Obj<4.5) Output = vec4(0.25*RES.x,0.75*RES.y,0.25*RES.x,0.5*RES.y); //Wall in front of emissive
            else if (Obj<5.5) Output = vec4(0.15*RES.x,0.8*RES.y,0.125*RES.x,0.65*RES.y); //Emissive red
        } else {
            //Move objects
            vec4 OID = texture(iChannel0,vec2(0.5)*IRES);
            if (OID.x>-0.5 && OID.y<0.5) {
                //Change endpoints
                if (abs(Obj-floor(OID.x*0.5))<0.5) {
                    if (mod(OID.x,2.)==0.) Output.xy += iMouse.xy-OID.zw;
                    else Output.zw += iMouse.xy-OID.zw;
                }
            } else if (OID.x>-0.5) {
                //Move entire line
                if (abs(Obj-floor(OID.x*0.5))<0.5) {
                    Output.xy += iMouse.xy-OID.zw;
                    Output.zw += iMouse.xy-OID.zw;
                }
            }
        }
        if (texelFetch(iChannel1,ivec2(65,2),0).x<=0.) {
            //Animation
            if (abs(Obj-4.)<0.5) {
                vec2 Middle = 0.5*(Output.xy+Output.zw);
                vec2 sincos = vec2(sin(iTimeDelta*2.),cos(iTimeDelta*2.));
                vec2 Offset = Output.xy-Middle;
                Output.xy = Middle+vec2(Offset.x*sincos.y-Offset.y*sincos.x,Offset.x*sincos.x+Offset.y*sincos.y);
                Offset = Output.zw-Middle;
                Output.zw = Middle+vec2(Offset.x*sincos.y-Offset.y*sincos.x,Offset.x*sincos.x+Offset.y*sincos.y);
            }
        }
    } else if (fragCoord.y<2. && fragCoord.x<16.) {
        //Last frame copy of attributes
        Output = texture(iChannel0,(fragCoord+vec2(0.,-1.))*IRES);
    }
    fragColor = Output;
}

/*
//Scattering approach: sorting visible geometry
//Super long compilation times, so I implemented a gathering approach instead


void Delete(inout GeoInt SI[NVA], int Start, int Index) {
    for (int j=Start; j<=Index-1; j++) {
        SI[j]=SI[j+1];
    }
}

void Move(inout GeoInt SI[NVA], int Start, int Offset, int Index) {
    for (int j=Index-Offset-1; j>=Start; j=j-1) {
        SI[j+Offset]=SI[j];
    }
}

void Insert(vec2 UV, inout GeoInt SI[NVA], GeoInt cg) {
    //Insert the visible geometry into a sorted list SI (Scatter)
    vec2 PIP; GeoInt sg; GeoInt CG=cg;
    for (int i=0; i<NVA; i++) {
        sg=SI[i];
        if (sg.a0<-0.5 ) {
            //New geometry (big angle)
            SI[i]=CG;
            break;
        }
        if (CG.a0>=sg.a1) continue; //No geometry is occluded
        if (CG.a1<=sg.a0) {
            //New geometry (small angle)
            Move(SI,i,1,NVA);
            SI[i]=CG;
            break;
        } else { //No test for plane intersection
            //No plane intersektion
            vec2 LTan=sg.p.xy-sg.p.zw;
            vec2 LNorm=vec2(LTan.y,-LTan.x);
            LNorm=LNorm*sign(dot(UV-sg.p.xy,LNorm));
            float CompDot=dot(CG.p.xy-sg.p.xy,LNorm);
            if (sign(CompDot)!=sign(dot(CG.p.zw-sg.p.xy,LNorm))) {
                //Test sg against CG instead
                LTan=CG.p.xy-CG.p.zw;
                LNorm=vec2(LTan.y,-LTan.x);
                LNorm=LNorm*sign(dot(UV-CG.p.xy,LNorm));
                CompDot=-dot(sg.p.xy-CG.p.xy,LNorm);
            }
            if (CompDot>=0.) {
                //CG är framför sg
                if (CG.a0>sg.a0 && CG.a1<sg.a1) {
                    //Vi occludar mitten av geometri
                    Move(SI,i,2,NVA);
                    PIP=UV+(CG.p.xy-UV)*LineRI(UV,CG.p.xy-UV,sg.p);
                    SI[i]=GeoInt(sg.a0,CG.a0,vec4(sg.p.xy,PIP),sg.E);
                    SI[i+1]=CG;
                    PIP=UV+(CG.p.zw-UV)*LineRI(UV,CG.p.zw-UV,sg.p);
                    SI[i+2]=GeoInt(CG.a1,sg.a1,vec4(PIP,sg.p.zw),sg.E);
                    //SI[0].E=vec3(1.,0.,0.); CG.E=vec3(1.,0.5,0.5);
                    i=NVA;
                } else if (CG.a0>sg.a0 && CG.a1>=sg.a1) {
                    //Blockerar senare delen av sg och potentiellt mer
                    PIP=UV+(CG.p.xy-UV)*LineRI(UV,CG.p.xy-UV,sg.p);
                    SI[i]=GeoInt(sg.a0,CG.a0,vec4(sg.p.xy,PIP),sg.E);
                    //SI[0].E=vec3(0.,1.,1.); CG.E=vec3(0.,1.,1.);
                } else if (CG.a1<sg.a1 && CG.a0<=sg.a0) {
                    //Blockerar första delen av sg
                    Move(SI,i,1,NVA);
                    PIP=UV+(CG.p.zw-UV)*LineRI(UV,CG.p.zw-UV,sg.p);
                    SI[i]=CG;
                    SI[i+1]=GeoInt(CG.a1,sg.a1,vec4(PIP,sg.p.zw),sg.E);
                    //SI[0].E=vec3(1.,1.,0.); CG.E=vec3(1.,1.,0.);
                    i=NVA;
                } else {
                    //Blockerar hela geometrin
                    Delete(SI,i,NVA);
                    i=i-1;
                    //CG.E=vec3(0.,1.,0.);
                }
            } else {
                //Bakom sg, dvs CG är helt blockad
                if (CG.a0>=sg.a0 && CG.a1<=sg.a1) {
                    //CG är helt blockerad
                    i=NVA;
                } else if (sg.a0<=CG.a0 && sg.a1<CG.a1) {
                    //Undre delen av CG är blockerad
                    PIP=UV+(sg.p.zw-UV)*LineRI(UV,sg.p.zw-UV,CG.p);
                    CG=GeoInt(sg.a1,CG.a1,vec4(PIP,CG.p.zw),CG.E);
                    //SI[0].E=vec3(0.,1.,1.); CG.E=vec3(0.,1.,1.);
                } else if (CG.a0<sg.a0 && CG.a1<=sg.a1) {
                    //Övre delen av CG är blockerad
                    Move(SI,i,1,NVA);
                    PIP=UV+(sg.p.xy-UV)*LineRI(UV,sg.p.xy-UV,CG.p);
                    SI[i]=GeoInt(CG.a0,sg.a0,vec4(CG.p.xy,PIP),CG.E);
                    //SI[0].E=vec3(1.,1.,0.); CG.E=vec3(1.,1.,0.);
                    i=NVA;
                } else {
                    //sg är i mitten av CG
                    Move(SI,i,1,NVA);
                    PIP=UV+(sg.p.xy-UV)*LineRI(UV,sg.p.xy-UV,CG.p);
                    SI[i]=GeoInt(CG.a0,sg.a0,vec4(CG.p.xy,PIP),CG.E);
                    SI[i+1]=sg;
                    PIP=UV+(sg.p.zw-UV)*LineRI(UV,sg.p.zw-UV,CG.p);
                    CG=GeoInt(sg.a1,CG.a1,vec4(PIP,CG.p.zw),CG.E);
                    //SI[0].E=vec3(1.,0.4,0.4); CG.E=vec3(1.,0.4,0.4);
                    i=i+1;
                }
            }
        }
    }
}

void DivideIntegral(vec2 UV, inout GeoInt SI[NVA]) {
    //Divide the rendering integral into smaller integrals (Scatter)
    float LInters; vec2 a; vec4 linep; vec3 Emissive=vec3(1.)*1.;
    for (float o=0.; o<NObjects; o++) {
        if (o==0.) Emissive=vec3(1.,1.,0.3)*1.5; else Emissive=vec3(0.);
        linep=texture(iChannel0,vec2(1.5+o,0.5)*IRES);
        a=vec2(atan(UV.y-linep.y,UV.x-linep.x)+PI,atan(UV.y-linep.w,UV.x-linep.z)+PI);
        if (a.x>a.y) { a=a.yx; linep=linep.zwxy; } //Order the points of the line
        if (a.y-a.x>PI) {
            //The geometry crosses the 2PI - 0 angle
            vec2 InterP=LineXI(UV,linep.xy,linep.zw);
            Insert(UV,SI,GeoInt(0.,a.x,vec4(InterP,linep.xy),Emissive));
            Insert(UV,SI,GeoInt(a.y,PI2,vec4(linep.zw,InterP),Emissive));
        } else {
            //Normal angles
            Insert(UV,SI,GeoInt(a.x,a.y,linep,Emissive));
        }
    }
}
*/