// Common (common) — Dynamic Editable Terrain by fenix
// https://www.shadertoy.com/view/NlyBWm

// Integer Hash - II by iq
// https://www.shadertoy.com/view/XlXcW4
const uint k = 1103515245U;  // GLIB C

vec3 hash( uvec3 x )
{
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    
    return vec3(x)*(1.0/float(0xffffffffU));
}

const float PI = 3.141592653589793;

void fxCalcCamera(in float time, in vec2 mouse, out vec3 cameraLookAt, out vec3 cameraPos, out vec3 cameraFwd, out vec3 cameraLeft, out vec3 cameraUp)
{
    time *= 0.1;
    
    cameraLookAt = vec3(time + 0.5*sin(time), 1.0 + 0.6 * sin(time*0.6), time + 0.5*cos(time));
    cameraPos = vec3(time-0.1 + 0.5*sin(time-0.1), 1.1 + 0.6 * sin(time*0.6-0.02), time-0.1 + 0.5*cos(time-0.1));

    cameraFwd  = normalize(cameraLookAt - cameraPos);
    cameraLeft = -normalize(cross(cameraFwd, vec3(0.0,1.0,0.0)));
    cameraUp   = normalize(cross(cameraLeft, cameraFwd)) * 0.5;
}

vec3 fxCalcRay(in vec2 fragCoord, in vec3 iResolution, in vec3 cameraFwd, in vec3 cameraUp, in vec3 cameraLeft)
{
	vec2 screenPos = (fragCoord.xy / iResolution.xy) * 1.0 - 0.5;
	return normalize(cameraFwd - screenPos.x * cameraLeft - screenPos.y * cameraUp);
}

float linePointDist2(in vec2 newPos, in vec2 oldPos, in vec2 fragCoord)
{
    vec2 pDelta = (fragCoord - oldPos);
    vec2 delta = newPos - oldPos;
    float deltaLen2 = dot(delta, delta);

    // Find the closest point on the line segment from old to new
    vec2 closest;
    if (deltaLen2 > 0.0000001)
    {
        float deltaInvSqrt = inversesqrt(deltaLen2);
        vec2 deltaNorm = delta * deltaInvSqrt;
        closest = oldPos + deltaNorm * max(0.0, min(1.0 / deltaInvSqrt, dot(deltaNorm, pDelta)));
    }
    else
    {
        closest = oldPos;
    }

    // Distance to closest point on line segment
    vec2 closestDelta = closest - fragCoord;
    return dot(closestDelta, closestDelta);
}

#define keyClick(ascii)   ( texelFetch(iChannel3,ivec2(ascii,1),0).x > 0.)
#define keyDown(ascii)    ( texelFetch(iChannel3,ivec2(ascii,0),0).x > 0.)

#define KEY_SHIFT 16
#define KEY_SPACE 32
#define KEY_0 48