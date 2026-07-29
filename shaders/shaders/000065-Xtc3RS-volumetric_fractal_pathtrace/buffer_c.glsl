// Buf C (buffer) — volumetric fractal pathtrace by public_int_i
// https://www.shadertoy.com/view/Xtc3RS

//Ethan Alexander Shulman 2016


//frame of last camera change


#define uv (.5/iResolution.xy)
#define change_epsilon 1e-4

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if (int(floor(fragCoord.x)+floor(fragCoord.y)) > 0) return;
    
    vec4 csamp = texture(iChannel0, uv),
         bsamp = texture(iChannel1, uv);
    
    float hash = fract(length(bsamp)+bsamp.w);
    if (abs(hash-csamp.y) > change_epsilon) {
     	csamp.y = hash;
        csamp.x = float(iFrame)/4096.;
    }
    
    fragColor = csamp;
}