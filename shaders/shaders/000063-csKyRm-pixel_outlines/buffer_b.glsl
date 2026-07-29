// Buffer B (buffer) — pixel outlines by UltimateBurrito
// https://www.shadertoy.com/view/csKyRm


float depthOutline(vec2 fragCoord)
{
    float centerDepth = texture(iChannel0,fragCoord / iResolution.xy).w;
    float diff = 0.0;
    
    diff += (texture(iChannel0,(fragCoord + vec2(pixelSize,0)) / iResolution.xy).w-centerDepth);
    diff += (texture(iChannel0,(fragCoord + vec2(-pixelSize,0)) / iResolution.xy).w-centerDepth);
    diff += (texture(iChannel0,(fragCoord + vec2(0,pixelSize)) / iResolution.xy).w-centerDepth);
    diff += (texture(iChannel0,(fragCoord + vec2(0,-pixelSize)) / iResolution.xy).w-centerDepth);
    
    return diff > 0.6 ? 1.0 : 0.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 inColor = texture(iChannel0,fragCoord/iResolution.xy).xyz;
    float outline = depthOutline(fragCoord);
    if(outline == 1.0)
    {
        fragColor = vec4(inColor*0.5,1.0);
    }
    else
    {
        fragColor = vec4(inColor,1.0);
    }
}