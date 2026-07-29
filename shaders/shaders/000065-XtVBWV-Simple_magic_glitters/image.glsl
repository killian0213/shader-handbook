// Image (image) — Simple magic glitters by berrymoor
// https://www.shadertoy.com/view/XtVBWV

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.x;
    vec2 uv2 = uv;
    uv.y += iTime / 10.0;
    uv.x -= (sin(iTime/10.0)/2.0);
    
    
    uv2.y += iTime / 14.0;
    uv2.x += (sin(iTime/10.0)/9.0);
    float result = 0.0;
    result += texture(iChannel0, uv * 0.6 + vec2(iTime*-0.003)).r;
    result *= texture(iChannel0, uv2 * 0.9 + vec2(iTime*+0.002)).b;
    result = pow(result, 15.0);
    fragColor = vec4(18.0)*result;
}