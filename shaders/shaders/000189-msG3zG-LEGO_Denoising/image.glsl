// Image (image) — LEGO Denoising by Mathis
// https://www.shadertoy.com/view/msG3zG

/*
Notes:
    Transparent windows:
        The blue panels should actually be transparent, but compilation time...
            Original idea was to use checkerboard rendering or render them at a separate pass
    Bricks
        Are injected into a SDF volume to increase performance and reduce compilation time
            Max buffer size for this volume is 2048x1024
            Trilinear sampling is optimized to only need one texture lookup
        Color/material index is interpolated in the volume -> color bleeding when objects share a SDF volume point
        Lower geometric quality and removal of the logo
        My door model does not exist as an actual brick
    Denoising
        SVGF
            Slightly modified SVGF denoiser with 3 passes
            Ordinary reprojection with weighted bilinear sampling
                Relaxed weights since variance updating is delayed with one frame
                    This results in some white ghosting when disocclusion happens
        Shadow and reflection denoisers
            Wavelet filters
    Reflections
        Should be more mirrorlike, but glossy reflections are cooler
    Secondary bounce
        Sampling screen space information is on by default, which introduces the usual artifacts
            Alternatively a second ray can be traced for second bounce diffuse light
        Reflections will also sample screen space information
            Direct light is traced with hard shadows
            It has no other information about indirect light
    I like feedback 



Controls:
    WASD and mouse to move around
        Camera collides against the SDF, so you have to move around it :)
    M/N to rotate the sun
    Remove the commented "#define SecondBounce" in the Common tab to replace
        screen space sampling to second bounce diffuse light

*/

vec3 acesFilm(vec3 x) {
    //Aces film curve
    return clamp((x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14),0.,1.);
}

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float YOffset = 2048.+floor(fragCoord.x*I1024)*1024.+floor(fragCoord.y*I1024)*2048.;
    vec3 Color = textureCube(mod(fragCoord,1024.)+vec2(0.,YOffset)).xyz;
    fragColor = vec4(pow(acesFilm(max(vec3(0.),Color)),vec3(0.45)),1.0);
}