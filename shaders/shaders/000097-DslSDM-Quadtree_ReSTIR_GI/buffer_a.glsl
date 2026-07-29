// Buffer A (buffer) — Quadtree ReSTIR GI by Mathis
// https://www.shadertoy.com/view/DslSDM

//Stores vars

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = texture(iChannel0,fragCoord*IRES);
    if (fragCoord.y<1.) {
        if (fragCoord.x<1.) {
            //Store mouse
            if (iFrame<2) {
                Output = vec4(-1.);
            } else {
                if (iMouse.z>0.) {
                    //Mouse clicked
                    if (Output.x<0.) {
                        //First frame
                        Output = iMouse.xyxy;
                    } else {
                        //Later frames
                        Output = vec4(iMouse.xy,Output.xy);
                    }
                } else {
                    Output=vec4(-1.);
                }
            }
        } else if (fragCoord.x<2.) {
            //Geometry type
            if (iFrame<2) {
                Output = vec4(1.,0.,1.,0.0001);
            } else {
                //Keyboard input
                if (texelFetch(iChannel1,ivec2(69,1),0).x>0.) {
                    //Key E
                    Output.x = 2.;
                } else if (texelFetch(iChannel1,ivec2(68,1),0).x>0.) {
                    //Key D
                    Output.x = 1.;
                } else if (texelFetch(iChannel1,ivec2(82,1),0).x>0.) {
                    //Key R
                    Output.x = 0.;
                }
            }
            //Visualize quadtree
            if (texelFetch(iChannel1,ivec2(86,1),0).x>0.) {
                Output.y = 1.-Output.y;
            }
            //Radius
            if (texelFetch(iChannel1,ivec2(49,1),0).x>0.) {
                Output.z = 1.;
            } else if (texelFetch(iChannel1,ivec2(50,1),0).x>0.) {
                Output.z = 2.;
            } else if (texelFetch(iChannel1,ivec2(51,1),0).x>0.) {
                Output.z = 4.;
            } else if (texelFetch(iChannel1,ivec2(52,1),0).x>0.) {
                Output.z = 8.;
            } else if (texelFetch(iChannel1,ivec2(53,1),0).x>0.) {
                Output.z = 16.;
            }
            //Dynamic geometry bool
            Output.w += ((Output.w>=0.)?iTimeDelta:0.);
            if (texelFetch(iChannel1,ivec2(65,1),0).x>0.) {
                Output.w = -Output.w;
            }
        } else if (fragCoord.x<3.) {
            //Frames
            if (iFrame<1) {
                //Initial frame
                Output = vec4(0.);
            } else if (textureSize(iChannel2,0).x>1) {
                //Texture loaded
                Output = vec4(1.,Output.y+1.,0.,0.);
            }
        } else if (fragCoord.x<4.) {
            //Resolution
            Output = vec4(iChannelResolution[0].xy,Output.xy);
        }
    }
    fragColor = Output;
}