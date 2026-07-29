// Cube A (cubemap) — Quadtree ReSTIR GI by Mathis
// https://www.shadertoy.com/view/DslSDM

//Scene storage

void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir) {
    vec4 Output = texture(iChannel3,rayDir);
    float Frame = texture(iChannel0,vec2(2.5,0.5)*IRES).y;
    vec4 Inter = texture(iChannel0,vec2(1.5,0.5)*IRES);
    vec2 UV; vec3 aDir = abs(rayDir);
    if (aDir.x>aDir.y) {
        //X-side
        UV = floor(((rayDir.yz/aDir.x)*0.5+0.5)*1024.)+0.5;
        vec2 SUV = UV*IRES.y;
        float LDF,df;
        if (rayDir.x>0. && BoxDF(UV,iChannelResolution[0].xy)<0.) {
            //Scene
            if (Frame<1.5 || length(iChannelResolution[0].xy-texture(iChannel0,vec2(3.5,0.5)*IRES).zw)>0.5) {
                //Static geometry
                Output = vec4(0.);
                //Content round box
                if (BoxDF(SUV-vec2(0.125,0.55),vec2(0.075,0.02))-IRES.y*3.<0.) Output = vec4(vec3(0.99,0.1,0.1),1.);
                    if (length(SUV-vec2(0.2,0.5))<0.03) Output = vec4(3.6,2.4,1.6,1.);
                //Normal curve emissive and diffuse
                float fx = SUV.x-(IRES.y/IRES.x)*0.5;
                float fy = SUV.y-0.02;
                df = abs(0.2*exp(-fx*fx*12.)-fy);
                if (df<IRES.y*2.) Output = vec4(1.01+mix(vec3(0.,0.5,2.),vec3(2.,0.7,0.),1.-UV.x*IRES.x),1.);
                df = abs(0.04+0.2*exp(-fx*fx*12.)-fy);
                if (df<IRES.y*2. && abs(fract(SUV.x*7.)-0.5)>0.2) Output = vec4(vec3(0.5),1.);
                //Mandelbrot
                vec4 MOutput = vec4(0.);
                fx = (SUV.x-0.9)*3.;
                fy = (SUV.y-0.7)*3.;
                float tmpz = fx;
                float rfx = 0.707*(fx+fy);
                float rfy = 0.707*(-tmpz+fy);
                tmpz = 0.;
                float zr = 0.;
                float zi = 0.;
                for (int Iter=0; Iter<100; Iter++) {
                    if (zr*zr+zi*zi>4.) break;
                    tmpz = zr;
                    zr = zr*zr-zi*zi+rfx;
                    zi = 2.*zi*tmpz+rfy;
                }
                if (zr*zr+zi*zi<4.) {
                    MOutput = vec4(vec3(0.9),1.);
                }
                //Carving the mandelbrot
                MOutput.w *= float(BoxDF(vec2(fx,fy)-vec2(-0.4,-0.4),vec2(0.5))-0.07>0.);
                if (length(vec2(fx+0.15,fy+0.15))<0.06) Output = vec4(vec3(1.6,2.5,1.6),1.);
                if (MOutput.w>0.5) Output = MOutput;
                //Red/Green box
                if (max(BoxDF(SUV-vec2(1.2,0.3),vec2(0.3)),-BoxDF(SUV-vec2(1.21,0.31),vec2(0.28,0.5)))<0.)
                    Output = vec4(vec3(0.99),1.);
                if (BoxDF(SUV-vec2(1.3,0.325),vec2(0.1,0.01))<0.) Output = vec4(vec3(3.),1.); //Emissive
                    if (BoxDF(SUV-vec2(1.21,0.31),vec2(0.01,0.29))<0.) Output = vec4(vec3(0.99,0.1,0.1),1.); //Red
                    if (BoxDF(SUV-vec2(1.48,0.31),vec2(0.01,0.29))<0.) Output = vec4(vec3(0.05,0.99,0.05),1.); //Green
                    if (LineDF(SUV,vec2(1.3,0.4),vec2(1.4,0.5))<0.015) Output = vec4(vec3(0.99),1.);
                        if (LineDF(SUV,vec2(1.35,0.55),vec2(1.425,0.425))<0.015) Output = vec4(vec3(0.99),1.);
                        if (LineDF(SUV,vec2(1.25,0.6),vec2(1.45,0.6))<0.005) Output = vec4(vec3(0.99),1.);
                //Randomness
                if (BoxDF(SUV-vec2(1.15,0.675),vec2(0.5,0.4))<0.025) {
                    vec2 Rand2 = texture(iChannel2,(SUV-vec2(1.15,0.65))*0.05).yz;
                    if (Rand2.x>0.55) Output = vec4(vec3(0.99)+((Rand2.y>0.89)?0.:0.),1.);
                    if (length(SUV-vec2(1.3,0.815))<0.01) Output = vec4(vec3(3.,1.2,1.2),1.);
                        if (length(SUV-vec2(1.44,0.835))<0.01) Output = vec4(vec3(1.1,3.2,3.2),1.);
                }
            } else {
                //Update scene
                if (Inter.w>0.) {
                    //Dynamic geometry
                    //Circle with holes (small)
                    df = length(SUV-vec2(0.85,0.65))-0.04;
                    if (df>0. && df<IRES.y*3.) {
                        if (fract(atan(SUV.x-0.85,SUV.y-0.65)*0.95+0.25+Inter.w)<0.5) Output.w = 1.;
                        else Output = vec4(0.);
                    }
                    //Round box
                    float tmpx = 0.3+sin(Inter.w*1.5)*0.125;
                    if (abs(BoxDF(SUV-vec2(0.1,0.5),vec2(0.4))-0.05)<IRES.y*2.) Output = vec4(vec3(0.99),1.);
                    if (abs(SUV.x-tmpx)<0.05 && abs(SUV.y-0.95)<IRES.y*3.) Output = vec4(0.);
                    //Rotating round box
                    vec2 RUV = SUV-vec2(0.3,0.725); RUV = Rotate(RUV,Inter.w);
                    if (length(RUV)<0.075+IRES.y*5.) {
                        if (LineDF(RUV,vec2(-0.075,0.),vec2(0.075,0.))-IRES.y*5.<0.) Output = vec4(vec3(0.99),1.);
                        else Output = vec4(0.);
                    }
                }
                float Radius = 4.;
                if (iMouse.z>0.) {
                    LDF = LineDF(UV,texture(iChannel0,vec2(0.5)*IRES).zw,iMouse.xy);
                    if (LDF<Inter.z) {
                        if (Inter.x<0.5) {
                            //Remove geometry
                            Output = vec4(0.);
                        } else {
                            //Diffuse or emissive
                            Output = vec4(((Inter.x<1.5)?vec3(0.99):vec3(2.)),1.);
                        }
                    }
                }
            }
        } else {
            //Copy of scene
            Output = texture(iChannel3,vec3(-rayDir.x,rayDir.yz));
        }
    }
    fragColor = Output;
}