// Image (image) — Bracketing by huwb
// https://www.shadertoy.com/view/NddcDr

// 'Bracketing' technique maps a texture to a plane using any arbitrary 2D vector field to give orientation
// Copyright Huw Bowles May 2022
// MIT license

// Explanation: https://twitter.com/hdb1/status/1528761299701841921

// A problem I've had working on water systems is having waves travel in arbitrary directions on a 2D plane, for example to align to
// shorelines. While one can create a custom UV mapping that tracks a shoreline, this can easily break down if shoreline is non trivial
// shape (high curvature, concave, small islands very close to shore). What we ideally want is to be able to map a texture onto
// any arbitrary vector field, for example a vector to nearest coastline position.

// A brute force approach would simply construct a UV coordinate frame directly from the vector field and use this to calculate
// UVs, which is shown in the right pane). Unfortunately this breaks down badly. The problem is that the UVs vary
// wildly across pixels and feeding these UVs directly as input to a function like texture sampling creates crazy high frequencies
// and distortions in the function output.

// Instead of feeding in wild varying UV input into the function, we snap the vector field direction to a set of canonical directions
// (for example every 15 degrees), evaluate the function at the snapped angle and the other nearby snapped angle, and then
// blend the outputs of the function based on the angle. So the function does it's thing on stable inputs, and we blend the outputs.
// To make this snapping obvious, set AngleDelta below to PI/5.0 and inspect the vector field which blends directions using this
// approach.

// The result tends to be very robust. The vector field I use below from iChannel1 is very bad quality, see the left side of the screen.
// Click the mouse to apply a circular vector field which is high quality, but exhibits extreme distortion without our bracketing method
// (again compare with left hand side).

// Blending artifacts are visible, and result is blurred. There are ways to combat this blurring such as histogram. But if the function
// is animated the blending may not be noticeable at all. This approach has been very effective in the Crest Ocean System.

// The worst remaining issues are where the vector field is divergent - when nearby directions vary strongly such as a sink/source. This
// can potentially be masked out (enable MaskOutDivergence) or an extra sample can re-add in using a given frame which can work (enable
// ReplaceDivergence).

// As a final bonus, one can animate the UVs to create a "flow" effect as shown here. However this only supports flow which has a fixed
// global speed rather than varying flow speeds. The flow technique could be applied on top of this.


// Defined in Common tab
//const float PI = 3.141592654;

const float RightPaneSize = 0.3;
const bool ShowVectorField = true;
const bool ShowBruteForceMethod = true;
const bool ColouriseSamples = false;

// In diverging areas, take one more sample to get "something". For waves, blending in this additional sample
// in the wind direction works well.
const bool ReplaceDivergence = true;
const bool MaskOutDivergence = false;

const float UVSpeedTexture = 1.0 / 160.0;
const float UVSpeedVectorField = 1.0 / 2000.0;

// Parameter for bracketing - bracket size in radians. Large values create noticeable linear structure,
// small values prone to simply replicating the issues with the brute force approach. In my use cases it
// was quick and easy to find a sweet spot.
const float AngleDelta = PI / 20.0;
const mat2x2 RotateByAngleDelta = mat2x2(cos(AngleDelta), sin(AngleDelta), -sin(AngleDelta), cos(AngleDelta));

vec2 CalculateUV(vec2 vAxis, vec2 position)
{
    vec2 uAxis = vec2(-vAxis.y, vAxis.x);
    vec2 uv = vec2( dot(position, uAxis), dot(position, vAxis) );
    // Animate
    uv.y -= iTime * UVSpeedTexture;
    return uv;
}

// This should return the normal to the field, which the texture will orient to.
// This can be a normalized vector, but does not need to be. This shader
// uses the length of the normal to mask out divergences. This is a mechanism
// to hint that there is a divergence.
vec2 Normal(vec2 position)
{
    vec2 aspect = vec2( iResolution.x / iResolution.y, 1.0 );
    
    if (iMouse.z > 0.0)
    {
        vec2 uvMouse = aspect * iMouse.xy / iResolution.xy;
        return position - uvMouse;
    }
    else
    {
        // Sample normal from texture 1. This gives a very bad quality vector field, which
        // helps to demonstrate the robustness of this technique.
        vec2 posScaled = position / 8.0 + vec2(0.4, 0.5);
        posScaled -= (iTime+35.0) * vec2(1.0, 1.33) * UVSpeedVectorField;
        float lodBias = 4.0;
        float v = textureLod(iChannel1, posScaled, lodBias).x;;
        vec2 dx_0 = vec2(0.2, 0.0);
        float v_x = textureLod(iChannel1, posScaled + dx_0.xy, lodBias).x;;
        float v_y = textureLod(iChannel1, posScaled + dx_0.yx, lodBias).x;;
        vec2 normal = vec2(v_x, v_y) - v;
        
        // If we don't normalize, the grad vector will go to 0 at divergent points.
        // This term can be used as a mask.
        if(!MaskOutDivergence && !ReplaceDivergence)
        {
            normal = normalize(normal);
        }
        return normal;
    }
}

// This is whatever 2D function we want to map on the plane, such as sampling a texture
vec4 Function(vec2 uv)
{
    return textureLod(iChannel0, uv, 1.0);
}

// Vector field direction is used to drive UV coordinate frame, but instead
// of directly taking the vector directly, take two samples of the texture
// using coordinate frames at snapped angles, and then blend them based on
// the angle of the original vector.
void Bracketing(vec2 normal, out vec2 vAxis0, out vec2 vAxis1, out float blendAlpha)
{
    // Heading angle of the original vector field direction
    float angle = atan(normal.y, normal.x) + 2.0*PI;

    // Snap to a first canonical direction by subtracting fractional angle
    float fractional = mod(angle, AngleDelta);
    float angle0 = angle - fractional;
    
    // Compute one V axis of UV frame. Given angle0 is snapped, this could come from LUT, but would
    // need testing on target platform to verify that a LUT is faster.
    vAxis0 = vec2(cos(angle0), sin(angle0));

    // Compute the next V axis by rotating by the snap angle size
    vAxis1 = RotateByAngleDelta * vAxis0;

    // Blend to get final result, based on how close the vector was to the first snapped angle
    blendAlpha = fractional / AngleDelta;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 aspect = vec2( iResolution.x / iResolution.y, 1.0 );
    
    vec2 uvPixel = aspect * fragCoord / iResolution.xy;
    
    // Normal is vector field direction, used to create UV coordinate frame
    vec2 normal = Normal(uvPixel);
    
    // Demo things
    float tNormalised = fract(iTime / 6.0);
    bool vectorFieldOn = ShowVectorField && tNormalised > 0.5; // fragCoord.y/iResolution.y<0.3
    bool bruteForceMethod = ShowBruteForceMethod && fragCoord.x/iResolution.x>(1.0-RightPaneSize);
    
    float uvScale = 4.0;
    // Blur a bit to see vector field easier
    //float lodBias = vectorFieldOn ? 3.0 : 1.0;

    if (!bruteForceMethod)
    {
        ////////////////// Technique for texturing using UVs from vector field starts here! //////////////////
        
        vec2 vAxis0, vAxis1;
        float blendAlpha;
        Bracketing(normal, vAxis0, vAxis1, blendAlpha);
        
        // Compute the function for the two canonical directions
        vec2 uv0 = uvScale * CalculateUV(vAxis0, uvPixel);
        vec2 uv1 = uvScale * CalculateUV(vAxis1, uvPixel);
        
        // Now sample function/texture
        vec4 sample0 = Function(uv0);
        vec4 sample1 = Function(uv1);
        
        if (ColouriseSamples)
        {
            sample0.xy *= 0.5;
            sample1.yz *= 0.5;
        }
        
        // Blend to get final result, based on how close the vector was to the first snapped angle
        fragColor = mix( sample0, sample1, blendAlpha );
        
        ////////////////// Technique for texturing using UVs from vector field ends here! //////////////////
    }
    else
    {
        fragColor = Function(uvScale * CalculateUV(normalize(normal), uvPixel));
    }
    
    // Moar visualisation - colourise background based on vector field
    if( false )
    {
        fragColor = vec4(0.5 + 0.35 * normalize(normal), 0.5, 1.0);
    }
    
    if (!bruteForceMethod)
    {
    
        // Apply patch
        if (ReplaceDivergence)
        {
            float strength = smoothstep(0.0, 0.2, length(normal)*3.0);
            vec2 arbitraryDirection = -vec2(cos(0.5),sin(0.5));
            fragColor = mix(Function(uvScale * CalculateUV(arbitraryDirection, uvPixel)), fragColor, strength);
        }
        else if (MaskOutDivergence)
        {
            fragColor = mix(vec4(0.0, 1.0, 0.0, 1.0), fragColor, smoothstep(0.0, 0.2, length(normal)*3.0)); 
        }
    }
    

    if (ShowBruteForceMethod && abs(fragCoord.x/iResolution.x - (1.0 - RightPaneSize)) < 2.0/iResolution.x)
    {
        fragColor = vec4(1.0);
    }

    if( vectorFieldOn )
    {
#if 0
        // Output vector field directly
        fragColor = max(0.8*fragColor, 0.9*arrow(uvPixel*iResolution.xy/aspect, normal*70.));
#else
        // Blend based on bracketing to show what is being used for the UV frame
        vec2 arrowCenterUV = arrowTileCenterCoord(uvPixel*iResolution.xy/aspect)*aspect/iResolution.xy;
        vec2 vAxis0, vAxis1;
        float blendAlpha;
        vec2 normalForArrow = Normal(arrowCenterUV);
        Bracketing(normalForArrow, vAxis0, vAxis1, blendAlpha);
        
        float arrowVal = mix( arrow(uvPixel*iResolution.xy/aspect, vAxis0*70.), arrow(uvPixel*iResolution.xy/aspect, vAxis1*70.), blendAlpha);
        
        // Boost a bit
        arrowVal = sqrt(arrowVal);
        
        if(MaskOutDivergence)
        {
            //arrowVal *= smoothstep(0.0, 0.2, length(normalForArrow)*3.0);
        }
        fragColor = max(0.8*fragColor, arrowVal);
#endif
    }
}
