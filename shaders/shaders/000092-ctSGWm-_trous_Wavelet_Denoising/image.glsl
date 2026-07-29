// Image (image) — Àtrous Wavelet Denoising by Mathis
// https://www.shadertoy.com/view/ctSGWm

/*
Some notes:
    TAA
        Uses catmull-rom for moving pixels -> produces blur for moving pixels
        The city is not actual rendered geometry, so the reprojection is incorrect -> ghosting
    Since normals are not computed from the geometry, lighting and shadows are simplified inside reflections
    Anistropic surfaces are over-denoised/blurred -> can be reduced by projecting samples on the normal plane
    Screen space normals results in false smooth edges and "noisy" normals
        A possible improvement is to search in the whole 3x3 box around the pixel
        More expensive + Tan and Bit can be parallel
    EPIC CAMERA ANIMATIONS
*/

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float YOffset = floor(fragCoord.x*I1024)*1024.+floor(fragCoord.y*I1024)*3072.;
    vec3 Color = textureCube(mod(fragCoord,1024.)+vec2(0.,YOffset)).xyz;
        
        
        //DEBUG (if you find it interesting)
        //Color = vec3(texture(iChannel2,fragCoord*IRES).w*0.1);
        //Color = FloatToVec3(texture(iChannel2,fragCoord*IRES).w); //Normals
            //Color = FloatToVec3(texture(iChannel0,fragCoord*IRES).z)*ReflConst; //Raw reflections
                //Color = texture(iChannel0,fragCoord*IRES).www; //Raw shadows
            //Color = texture(iChannel2,fragCoord*IRES).zzz; //Denoised shadows (B)
                //Color = FloatToVec3(texture(iChannel1,fragCoord*IRES).y)*ReflConst; //Denoised reflections (B)
        //vec2 sc = texture(iChannel2,fragCoord*IRES).xy;
        //Color = vec3(FloatToVec2(sc.x)*ReflConst,sc.y); //Buffer C Reflection light
        
        
    fragColor = vec4(pow(1.-exp(-1.2*Color),vec3(0.45)),1.);
}