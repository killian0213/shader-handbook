// Buffer A (buffer) — Noise Flow Lines by Shane
// https://www.shadertoy.com/view/lsyfDV

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    // Some of the noie values are accessed 300 times, so precalculation
    // is necessary.
    
    vec2 uv = fragCoord/iResolution.xy;

    // A bit of layers noise. The top is for the main flowing lines, and
    // and the other is for a bit of coloring.    
    float c = fBm(uv, 6., iTime/1.5);
    float c2 = fBm(uv, 6.*2., 0.);
    
    // Angle, noise value, and noise color value.
    fragColor = vec4((c - .5)*6.2831*2., c, c2, 1.0);
}