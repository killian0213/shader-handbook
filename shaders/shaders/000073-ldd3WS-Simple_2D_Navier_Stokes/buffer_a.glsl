// Buf A (buffer) — Simple 2D Navier Stokes by Wumpf
// https://www.shadertoy.com/view/ldd3WS

// Advection & force

// Magic force within a rectangle.
const vec2 Force = vec2(100.0, 0.0);
const vec2 ForceAreaMin = vec2(0.0, 0.2); 
const vec2 ForceAreaMax = vec2(0.06, 0.8);

// Circular barrier.
const vec2 BarrierPosition = vec2(0.2, 0.5);
const float BarrierRadiusSq = 0.01;

#define VelocityTexture iChannel3

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 inverseResolution = vec2(1.0) / iResolution.xy;
    vec2 uv = fragCoord.xy * inverseResolution;

    // Simple advection by backstep.
    // Todo: Try better methods like MacCormack (http://http.developer.nvidia.com/GPUGems3/gpugems3_ch30.html)
    vec2 oldVelocity = texture(VelocityTexture, uv).xy;
    vec2 samplePos = uv - oldVelocity * iTimeDelta * inverseResolution;
    vec2 outputVelocity = texture(VelocityTexture, samplePos).xy;
    
    // Add force.
    if(uv.x > ForceAreaMin.x && uv.x < ForceAreaMax.x &&
       uv.y > ForceAreaMin.y && uv.y < ForceAreaMax.y)
    {
    	outputVelocity += Force * iTimeDelta;
    }
    
    // Clamp velocity at borders to zero.
    if(uv.x > 1.0 - inverseResolution.x ||
      	uv.y > 1.0 - inverseResolution.y ||
      	uv.x < inverseResolution.x ||
      	uv.y < inverseResolution.y)
    {
        outputVelocity = vec2(0.0, 0.0);
    }
    
    // Circle barrier.
    vec2 toBarrier = BarrierPosition - uv;
    toBarrier.x *= inverseResolution.y / inverseResolution.x;
    if(dot(toBarrier, toBarrier) < BarrierRadiusSq)
    {
        fragColor = vec4(0.0, 0.0, 999.0, 0.0);
    }
    else
    {
        fragColor = vec4(outputVelocity, 0.0, 0.0);
    } 
}