// Buf C (buffer) — Candy Crush by ciberxtrem
// https://www.shadertoy.com/view/XdtSDH

// Store the cell with the most adjacent cells saved from Buffer B

const float xCells = 10.;
const float yCells = 8.;

float IsInside(vec2 memPos, in vec2 fragCoord)
{
    vec2 res = abs(fragCoord -0.5 -memPos) -0.5; return -max(res.x, res.y);
}
void Save(vec2 memPos, vec4 value, in vec2 fragCoord, inout vec4 fragColor)
{
    fragColor = IsInside(memPos, fragCoord) > 0.0 ? value : fragColor;
}
vec4 Load(vec2 memPos, sampler2D sampler, vec2 resolution)
{
    return texture(sampler, (memPos+0.5)/resolution, -100.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //if(fragCoord.x > 2.0 || fragCoord.y > 2.0) return;
    
    float maxDist = 0.;
    float maxDistY = 0.;
    float minY = 99.;
    float maxY = -99.;
    
    for(float y=0.; y<yCells-0.5;++y) {
        for(float x=0.; x<xCells-0.5;++x) 
        {

            vec4 data = Load(vec2(x,y), iChannel1, iChannelResolution[1].xy);
            float dist = data.x;
            maxDist = max(maxDist, dist);
            if(dist > 0.5)
            {
               minY = min(minY, data.y); 
               maxY = max(maxY, data.z);
               maxDistY = max(maxDistY, data.z-data.y);
            }
        }
    }
    
    fragColor = vec4(maxDist, minY, maxY, maxDistY);
}
