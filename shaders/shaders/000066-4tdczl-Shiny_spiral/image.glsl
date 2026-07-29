// Image (image) — Shiny spiral by Plento
// https://www.shadertoy.com/view/4tdczl


vec2 sp(vec2 uv){ // spiral
    float r = length(uv);
    float angle = atan(uv.x, uv.y);
    uv *= cos(15.0 * r - 1.0 * angle - iTime * 0.8 );
    return uv;
}
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = vec2(fragCoord.xy - 0.5*iResolution.xy)/iResolution.y;
    vec2 sv = sp(uv); // warping uv space to spiral
    vec3 bg = texture(iChannel0, sv - 0.5).xyz; // get background texture
    // mix between the warped uv and the warped background. then the dot of the two interpolates it
    vec3 col = mix(vec3(sv, 0.0), bg, dot(vec3(sv, 1.05), bg)) * 1.88; 
    fragColor = vec4(col, 1.0) ;
}