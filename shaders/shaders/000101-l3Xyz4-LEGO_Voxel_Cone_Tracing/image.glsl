// Image (image) — LEGO Voxel Cone Tracing by Mathis
// https://www.shadertoy.com/view/l3Xyz4

/*
Voxel Cone Tracing with LEGO

VCT
    Uses 2 volumes, one for LEGO and one for the floor
        LOD 0 (LEGO) is isotropic and the mipmaps are anisotropic
            Temporally computed so lighting/geometry is static here
        Floor uses hardware mipmaps, works since light is assumed to only travel "upwards"
    Diffuse cones do not interpolate between mipmaps to save performance -> fixed cone ratio
        Glossy cone uses normal voxel cone tracing
    Light injection
        Shadow map computed in Buffer D to avoid RT in cubemap

SDF
    Represented inside a volume, one textureFetch is needed for trilinear interpolation

TAA
    Glues it together

Performance
    Many interpolations must be done manually, forcing more texture-fetches
    Some code can also be "simplified" (leads to more code and better performance) which I have not done



Controls:
    Mouse to rotate the camera
*/

vec3 acesFilm(vec3 x) {
    //Aces film curve
    return clamp((x*(2.51*x + 0.03))/(x*(2.43*x + 0.59) + 0.14), 0., 1.);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 Color = texture(iChannel0, fragCoord*IRES).xyz;
    fragColor = vec4(pow(acesFilm(max(vec3(0.), Color)), vec3(0.45)), 1.);
}