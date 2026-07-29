// Buf A (buffer) — JFA Delaunay Video Filter by tomkh
// https://www.shadertoy.com/view/ldV3Wc

// A super simple video source with feature detection

float grayScale(vec4 c) { return c.x*.29 + c.y*.58 + c.z*.13; }

//============================================================
vec4 GenerateSeed (in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec3 dataStep = vec3( vec2(1.) / iChannelResolution[0].xy, 0.);
    
    vec4 fragColor = texture( iChannel0, uv );
    
    float d = grayScale(fragColor);
    float dL = grayScale(texture( iChannel0, uv - dataStep.xz ));
    float dR = grayScale(texture( iChannel0, uv + dataStep.xz ));
    float dU = grayScale(texture( iChannel0, uv - dataStep.zy ));
    float dD = grayScale(texture( iChannel0, uv + dataStep.zy ));
    float scale = abs(sin(iTime*.5));
    float w = float( d*(.99 + scale*.01) > max(max(dL, dR), max(dU, dD)) );
    
    //w = max(w, texture( iChannel1, uv ).w*.9); // get some from previous frame
    
    fragColor.w = w;
    
    return fragColor;
}

//============================================================
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = GenerateSeed(fragCoord);
}

