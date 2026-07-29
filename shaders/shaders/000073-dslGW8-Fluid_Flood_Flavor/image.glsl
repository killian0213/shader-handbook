// Image (image) — Fluid Flood Flavor by leon
// https://www.shadertoy.com/view/dslGW8


// Fluid Flood Flavor
//
// variation of "Fire Fighter Fever" https://shadertoy.com/view/msf3WH

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    
    // normal
    float rng = hash13(vec3(fragCoord, iFrame));
    vec3 unit = vec3(vec2(.001), 0.);
    vec3 normal = normalize(vec3(T(uv-unit.xz)-T(uv+unit.xz),
                                 T(uv-unit.zy)-T(uv+unit.zy),
                                 .0001));
    
    // distort
    fragColor = texture(iChannel1, uv+.1*normal.xy);
    
    // debug art
    if (iMouse.z > 0. && iMouse.x/R.x < .2)
    {
        vec4 data = texture(iChannel0, uv);
        if (uv.x > .66) fragColor = vec4(normal*.5+.5, 1);
        else if (uv.x > .33) fragColor = vec4(vec3(sin(data.r*6.28*2.)*.5+.5), 1);
        else fragColor = vec4(data.yz*.5+.5,.5, 1);
    }
}