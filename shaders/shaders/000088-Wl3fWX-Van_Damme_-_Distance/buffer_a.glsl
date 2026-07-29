// Buffer A (buffer) — Van Damme - Distance by Flyguy
// https://www.shadertoy.com/view/Wl3fWX

//Input image, stencil is generated from the alpha channel.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec3 col = texture(iChannel0,uv,0.0).rgb;
    
    float d = clamp(3.0*(col.g-max(col.r,col.b)),0.0,1.0);

    fragColor = vec4(col.rgb, d-0.8);
}