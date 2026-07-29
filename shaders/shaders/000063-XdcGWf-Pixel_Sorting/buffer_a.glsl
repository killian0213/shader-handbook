// Buf A (buffer) — Pixel Sorting by cornusammonis
// https://www.shadertoy.com/view/XdcGWf

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 texel = 1. / iResolution.xy;
    
    float step_y = texel.y;
    vec2 s  = vec2(0.0, -step_y);
    vec2 n  = vec2(0.0, step_y);

    vec4 im_n =  texture(iChannel0, uv+n);
    vec4 im =    texture(iChannel0, uv);
    vec4 im_s =  texture(iChannel0, uv+s);
    
    float len_n = length(im_n);
    float len = length(im);
    float len_s = length(im_s);
    
    if(int(mod(float(iFrame) + fragCoord.y, 2.0)) == 0) {
        if ((len_s > len)) { 
            im = im_s;    
        }
    } else {
        if ((len_n < len)) { 
            im = im_n;    
        }   
    }
    
    // initialize with image
    if(iFrame<10) {
        fragColor = texture(iChannel1, uv);
    } else {
        fragColor = im;
    }
    
}