// Image (image) — Minecraft + LPV GI by Mathis
// https://www.shadertoy.com/view/ctV3WG

/*
Rendering a minecraft scene
    Not official ofc :)

Info:
    LPV
        It is used for diffuse indirect light
        A manual bilinear method is used that prevents interpolated light leaking for all voxel configurations
            Both visibility occlusion and voxel type is used as weights when interpolating
    Normal map
        Calculated from the gradient of the textures
    Reflections
        Wavelet denoiser ( :
    TAA is used as well
    Textures were extracted using matlab and python
        A limited amount of blocks are included

Controls:
    WASD and mouse to move/look around
*/

vec3 acesFilm(vec3 x) {
    //Aces film curve
    return clamp((x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14),0.,1.);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 Color = texture(iChannel0,fragCoord*IRES).xyz;
    fragColor = vec4(pow(acesFilm(max(vec3(0.),Color)),vec3(0.45)),1.);
}