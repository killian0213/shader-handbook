// Image (image) — Diffuse ReSTIR GI by Mathis
// https://www.shadertoy.com/view/Dll3zs

/*
Notes:
    Performance
        Analytic intersections are used instead of ray marching a SDF
        Normals are computed by sampling a SDF-version of the scene
        Many iterations will sample "Gradient" -> poor performance
    Scene
        Very high quality scene which is extremely artistic
    ReSTIR
        All meaningful attributes are stored together with reservoir positions to improve reprojection quality
    Reprojection
        Based on nearest neighbour gathering
            Search in a 3x3 pixel area inside the last frame screen to find good reservoirs
            To completely remove smearing/distortion a scattering approach is better
                A 3x3 search area is enough
                The main cost is increased noise, which can be reduced with an additional spatial pass
        No motion vectors
    Adaptivity
        Old rays are retraced every third frame to remove stale samples when lights/geometry have moved
    Spatial reservoirs
        Visibility is approximated with a screen space ray marcher
            It is bad because 2D samples are not uniformly distributed in screen space, just in world space
            It also assumes pixels have infinite thickness behind their depths
    Shadows are denoised using a two pass filter
    TAA
        Only reprojection and color clamping is used

Controls:
    WASD to move the camera
    Mouse to rotate the camera
    M/N to rotate the sun
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
    fragColor=vec4(pow(1.-exp(-1.2*Color),vec3(0.45)),1.);
}