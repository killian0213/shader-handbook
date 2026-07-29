// Image (image) — LEGO Sanctuary by Mathis
// https://www.shadertoy.com/view/slByR1

/*
I like LEGO


Some info:
    My initial attempt traced the 3D brick-geometry directly
        Performance was good but the compilation time was too long
        Isometric projection solves this since it samples pre-rendered images instead
    An octree (128^3) is used to accelerate primary rays
        It stores brick index, offsets, colors and other attributes
        I might have used some illegal building techniques to reduce compilation time :)
    PBR
        No
    Secondary rays are traced in screen space
        A quadtree is used to accelerate secondary rays
            It has a fixed depth to simplify sampling offsets
                This means supersampling only happens every 6th frame
            It's THICC, rays are accelerated behind geometry as well
        Black geometry are placed in the scene to reduce light leaking




Logo by zduny (thank you):
    https://www.shadertoy.com/view/3tBczt




Controls:
    Press R to reset the path tracer
    Uncomment "#define Clay" in the Common-tab to enable a clay render
*/

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec3 Color = texture(iChannel2,fragCoord*IRES).xyz;
    //Exponential color space
    Color = 1.-exp(-1.2*Color);
    
    //
    //Uncomment to view the cubemap (octrees and prerendered images)
    //Use the mouse to scroll
    //
    /*
    vec2 CMUV = fragCoord*2.+vec2(0.,iMouse.y*IRES.y*1024.*7.);
    if (DFBox(CMUV,vec2(1024.,1024.*6.))<0.) {
        vec4 CMS = textureCube(CMUV);
        Color = CMS.xyz;
        if (CMUV.y>2370. && CMUV.y<5120. && DFBox(CMUV-vec2(0.,2370.),vec2(256.,128.))>0.) {
            if (CMS.w<9999.) Color = CMS.xyz*0.5+0.5;
            else Color = vec3(fract((CMUV-vec2(0.,2370.))*I128)*0.1,0.);
        }
        
    }
    //*/
    
    //Gamma correction
    fragColor = vec4(pow(Color,vec3(0.45)),1.0);
}