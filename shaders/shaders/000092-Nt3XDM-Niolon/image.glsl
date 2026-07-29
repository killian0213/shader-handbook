// Image (image) — Niolon by XT95
// https://www.shadertoy.com/view/Nt3XDM

// ---------------------------------------------------------------------------------
// Compositing pass
// ---------------------------------------------------------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 invRes = vec2(1.) / iResolution.xy;
    vec2 uv = fragCoord * invRes;

    // Chromatic aberration
    vec2 offset = (uv*2.-1.)/iResolution.xy*0.5;
    vec4 col = vec4(0.);
    col.r = texture(iChannel0, uv/SCALE_FACTOR+offset).r;
    col.g = texture(iChannel0, uv/SCALE_FACTOR-offset).g;
    col.b = texture(iChannel0, uv/SCALE_FACTOR-offset).b;

    // Light scattering
    col += texture(iChannel1,uv*.5);

    // Vignetting
    col *= (pow( uv.x * uv.y * (1.-uv.x) * (1.-uv.y)*100., .2 ));
    
    // Gamma correction
    fragColor = pow(col*2., vec4(1./2.2));
}