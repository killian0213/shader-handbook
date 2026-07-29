// Image (image) — A WEDDING OF WISPS by alro
// https://www.shadertoy.com/view/cdcSDX

/*
    Particles with 3D curl noise. Use mouse to move camera.
    
    Positions are updated in Buffer B based on the curl of a gradient noise field.
    Buffer C renders camera facing dics at a fraction of the canvas resolution.
    
    See Common tab for resolution scaling.

*/

// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x){
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = fragCoord.xy/iResolution.xy;
    
    vec3 col = texture(iChannel0, RENDER_SCALE*uv).rgb;
    
    col = ACESFilm(col);
    col = gamma(col);

    // Output to screen
    fragColor = vec4(col, 1.0);
}