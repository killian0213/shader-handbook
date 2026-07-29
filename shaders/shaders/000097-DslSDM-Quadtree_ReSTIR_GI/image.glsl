// Image (image) — Quadtree ReSTIR GI by Mathis
// https://www.shadertoy.com/view/DslSDM

/*
ReSTIR GI using quadtrees
    There is no spatial denoiser -> the viewport will be a bit noisy
    Maximum resolution is 1024^2, otherwise the scene is scaled to the viewport resolution
        Reset the timer if the resolution is changed
    Rays are accelerated using a quadtree
        Hardware mipmaps are used
        Press V to visualize the LODS
    Dynamic scene
        Paint your own scene using the mouse
            r/d/e defines removal/emissive/diffuse
            1-5 defines the brush radius
        Some geometry are animated: click on a to enable/disable them
    ReSTIR
        Light finally responds fast to changes in the scene
        Reservoirs in 2D are smaller and easier to store
        Color blending problem: W is the average of 3 color channels
            The weights in every color channel are generally different from each
            other which results in colors replacing each other instead of mixing (ex red and green)


Controls:
    Use your mouse to paint new geometry in the scene
    Key R:     Remove geometry
    Key D:     Create geometry: diffuse
    Key E:     Create geometry: emissive
    Key 1-5:   Change painting radius to 2^(n-1)
    Key V:     Visualize quadtree
    Key A:     Disable/enable animated geometry
*/

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 Color = vec3(0.);
    vec4 Inter = texture(iChannel0,vec2(1.5,0.5)*IRES);
    if (max(fragCoord.x,fragCoord.y)<1024.) {
        //Inside the scene
        if (Inter.y==0.) {
            //Visualize path tracing
            vec4 SceneInfo = texture(iChannel3,vec3(-1.,fragCoord*I512-1.));
            if (SceneInfo.w>0.5) {
                //Geometry
                if (SceneInfo.x>1.) {
                    //Emissive
                    Color = SceneInfo.xyz-1.;
                } else {
                    //Diffuse
                    vec4 SC = texture(iChannel2,fragCoord*IRES);
                    Color = SC.xyz;
                }
            } else {
                //Air pixel
                Color = texture(iChannel2,fragCoord*IRES).xyz;
            }
        } else {
            //Visualize the scene and the quadtree
            float CLOD = START_LOD;
            float Size = pow(2.,START_LOD);
            float ISize = pow(0.5,START_LOD);
            //Iteration
            vec2 LUV = (floor(fragCoord*ISize)+0.5)*Size;
            for (float i=0.; i<START_LOD; i++) {
                if (textureLod(iChannel3,vec3(-1.,LUV*I512-1.),CLOD).w==0.) {
                    break;
                }
                CLOD -= 1.;
                Size *= 0.5;
                ISize *= 2.;
                LUV = (floor(fragCoord*ISize)+0.5)*Size;
            }
            //Output
            Color = vec3((START_LOD-CLOD)/9.);
        }
    }
    //Return
    fragColor=vec4(pow(1.-exp(-1.4*Color),vec3(0.45)),1.);
}