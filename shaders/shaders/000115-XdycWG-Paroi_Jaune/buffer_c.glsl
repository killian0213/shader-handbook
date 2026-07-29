// Buffer C (buffer) — Paroi Jaune by XT95
// https://www.shadertoy.com/view/XdycWG

// ---------------------------------------------
// Bilateral blur for the bloom
// ---------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 invRes = vec2(1.) / iResolution.xy;
    
    vec2 uv = fragCoord * invRes;
    vec2 offset = vec2(0.,3.) * invRes;
    
    vec3 col = vec3(0);
    
    for(float i=-6.; i<=6.; i += 1.)
        col += texture( iChannel0, uv+offset*i).rgb;
    
    fragColor = vec4(col/12.,1.0);
}