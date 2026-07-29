// Image (image) — Malmousque by XT95
// https://www.shadertoy.com/view/fldSRB

// ---------------------------------------------------------------------------------
// Compositing pass
// ---------------------------------------------------------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 invRes = vec2(1.) / iResolution.xy;
    vec2 uv = fragCoord * invRes;

    // Chromatic aberration
    vec2 offset = (uv*2.-1.)/iResolution.xy*.75;
    vec4 col = vec4(0.);
    col.r = texture(iChannel0, uv+offset).r;
    col.g = texture(iChannel0, uv-offset).g;
    col.b = texture(iChannel0, uv+offset).b;

    // Vignetting & color grading
    col *= pow( uv.x * uv.y * (1.-uv.x) * (1.-uv.y)*100., .15 );
    col = pow(col, vec4(1.0,1.05,1.1, 1.));
    
    // Gamma correction
    fragColor = pow(col*3., vec4(1./2.2));
}