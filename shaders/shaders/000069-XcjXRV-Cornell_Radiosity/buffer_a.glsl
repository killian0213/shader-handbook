// Buffer A (buffer) — Cornell Radiosity by Mathis
// https://www.shadertoy.com/view/XcjXRV

//Patches: attributes

void UpdateMouse(inout vec4 Output, vec4 Mouse) {
    //Updates the last frame mouse
    if (Mouse.z>0.) {
        if (Output.w==0.) {
            Output.w = 1.;
            Output.xy = Mouse.zw;
        }
    } else Output.w = 0.;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    //Actual mouse logic
    vec4 CurrentMouse = texture(iChannel0,vec2(1.5,64.5)*IRES);
    UpdateMouse(CurrentMouse,iMouse);
    //Animation mouse
    vec4 Mouse4 = texture(iChannel0,vec2(0.5,64.5)*IRES);
    vec2 Mouse;
    if (CurrentMouse.w==0.) {
        Mouse4.z += iTimeDelta;
        float AT = max(0.,Mouse4.z+4.);
        Mouse = vec2(cos(AT*0.17)*0.5+0.5,cos((cos(AT*0.6+1.95)*0.5+0.5)*PI)*0.286+0.5)*RES;
    } else {
        Mouse = iMouse.xy;
    }
    //Output
    if (length(fragCoord-vec2(1.5,64.5))<0.7) {
        //Actual mouse
        Output = ((iFrame<2)?vec4(0.):CurrentMouse);
    } else if (length(fragCoord-vec2(0.5,64.5))<0.7) {
        //Animation mouse
        Output.xyz = vec3(Mouse,Mouse4.z);
    } else if (DFBox(fragCoord,vec2(64.*2.,64.))<0.) {
        //Patch attributes
        Output = vec4(-1.);
        vec2 UV = vec2(mod(fragCoord.x,64.),fragCoord.y);
        //Patch
        vec3 PatchP = vec3(0.);
        vec3 PatchN = vec3(0.);
        vec3 PatchC = vec3(0.98);
        vec3 PatchL = vec3(0.); //Not initialized
        
        //Floor
        if (DFBox(UV,vec2(24.))<0.) {
            //Ground
            PatchP = vec3(UV.x*I24,0.,UV.y*I24);
            PatchN = vec3(0.,1.,0.);
        } else if (DFBox(UV-vec2(24.,0.),vec2(24.))<0.) {
            //Ceiling
            PatchP = vec3((UV.x-24.)*I24,1.,UV.y*I24);
            PatchN = vec3(0.,-1.,0.);
            if (Mouse.x>RES.x*0.75) {
                if (DFBox(vec2(UV.x-24.,UV.y)-8.,vec2(8.,cos(iTime)*0.+8.))<0.)
                    PatchL = vec3(5.5*min(1.,(Mouse.x*IRES.x-0.75)*16.));
            }
        } else if (DFBox(UV-vec2(0.,24.),vec2(24.))<0.) {
            //X = 0
            PatchP = vec3(0.,(UV.y-24.)*I24,UV.x*I24);
            PatchN = vec3(1.,0.,0.);
            float Interp = max(0.,1.-abs(Mouse.x*IRES.x-5.*0.125)*8.);
            PatchC = mix(vec3(0.98,0.15,0.15),vec3(1.,0.2,0.05),Interp);
            PatchL = vec3(5.*Interp);
        } else if (DFBox(UV-vec2(24.,24.),vec2(24.))<0.) {
            //X = 1
            PatchP = vec3(1.,(UV.y-24.)*I24,(UV.x-24.)*I24);
            PatchN = vec3(-1.,0.,0.);
            float Interp = max(0.,1.-abs(Mouse.x*IRES.x-3.*0.125)*8.);
            PatchC = mix(vec3(0.2,0.98,0.2),vec3(0.3,1.,0.3),Interp);
            PatchL = vec3(2.*Interp);
        } else if (DFBox(UV-vec2(48.,0.),vec2(16.,24.))<0.) {
            //Z = 1
            PatchP = vec3((UV.x-48.+8.)*I24,UV.y*I24,1.);
            PatchN = vec3(0.,0.,-1.);
        }
        if (DFBox(UV-vec2(48.,24.),vec2(16.,31.))<0.) {
            //Sphere diffuse
            vec2 SUV = UV-vec2(48.,24.);
            float theta = floor(SUV.x)/15.*PI;
            float circum = ceil(30.*sin(theta))+1.;
            if (SUV.y<circum) {
                float phi = (SUV.y/circum)*2.*PI;
                PatchN = vec3(vec2(-sin(phi),-cos(phi))*sin(theta),cos(theta)).xzy;
                PatchP = DSP+PatchN*0.2;
            }
        }
        if (DFBox(UV-vec2(0.,48.),vec2(12.,16.))<0.) {
            //Rotated box Z front
            PatchN = vec3(0.7173560909,0.,-0.69670670934);
            vec3 PatchTan = vec3(-PatchN.z,0.,PatchN.x);
            PatchP = vec3(4.*I24,0.,13.*I24)+PatchTan*(UV.x*I24)+vec3(0.,(UV.y-48.)*I24,0.);
        }
        if (DFBox(UV-vec2(12.,48.),vec2(12.,16.))<0.) {
            //Rotated box Z back
            PatchN = vec3(-0.7173560909,0.,0.69670670934);
            vec3 PatchTan = vec3(PatchN.z,0.,-PatchN.x);
            PatchP = vec3(4.*I24,0.,13.*I24)+PatchN*I24*2.+PatchTan*((UV.x-12.)*I24)+vec3(0.,(UV.y-48.)*I24,0.);
        }
        if (DFBox(UV-vec2(24.,48.),vec2(2.,16.))<0.) {
            //Rotated box Z side
            PatchN = vec3(-0.69670670934,0.,-0.7173560909);
            vec3 PatchTan = vec3(PatchN.z,0.,-PatchN.x);
            PatchP = vec3(4.*I24,0.,13.*I24)+PatchTan*((UV.x-24.)*I24)+vec3(0.,(UV.y-48.)*I24,0.);
        }
        if (DFBox(UV-vec2(26.,48.),vec2(2.,12.))<0.) {
            //Rotated box Y top
            PatchN = vec3(-0.7173560909,0.,0.69670670934);
            vec3 PatchTan = vec3(PatchN.z,0.,-PatchN.x);
            PatchP = vec3(4.*I24,16.*I24,13.*I24)+PatchN*((UV.x-26.)*I24)+PatchTan*((UV.y-48.)*I24);
            PatchN = vec3(0.,1.,0.);
        }
        
        //Output
        if (fragCoord.x>64.) {
            Output.xyz = PatchP;
        } else {
            Output = vec4(vec3ToFloat(PatchP),
                          vec3ToFloat(PatchN*0.5+0.5),
                          vec3ToFloat(PatchC),
                          vec3ToFloat(PatchL*0.125));
        }
    } else discard;
    fragColor = Output;
}