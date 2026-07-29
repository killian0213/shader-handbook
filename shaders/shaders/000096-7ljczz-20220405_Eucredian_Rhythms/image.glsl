// Image (image) — 20220405_Eucredian Rhythms by 0b5vr
// https://www.shadertoy.com/view/7ljczz

// (c) 2022 0b5vr, MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// constants
const vec3 BACKGROUND_COLOR = vec3( 0.12, 0.13, 0.15 );
const vec3 TICK_COLOR = vec3( 1.0, 0.1, 0.4 );
const vec3 OUTLINE_COLOR = vec3( 0.0, 0.0, 0.0 );

// sdf
float sdcapsule( vec2 p, vec2 tail ) {
    float h = clamp( dot( p, tail ) / dot( tail, tail ), 0.0, 1.0 );
    return length( p - ( tail * h ) );
}

void drawEuclideanCircle( vec2 p, vec3 color, float pulses, float steps, float offset, inout vec4 fragColor ) {
    // early return if the p is not within the circle
    if ( length( p ) > 0.5 ) { return; }
    
    vec2 pt = p;
    
    float phase = iTime * BPS * 4.0 / steps;
    float currentStep = mod( iTime * BPS * 4.0, steps );
    
    // hit effect
    {
        float beat = iTime * TIME2BEAT;
        float t = euclideanRhythmsInteg( pulses, steps, 4.0 * beat - offset ) / 4.0 * BEAT2TIME;

        float radius = mix( 0.15, 0.1, exp( -10.0 * t ) );
        float d = length( p ) - radius;

        float shape = smoothstep( 4.0 / iResolution.y, 0.0, d );
        fragColor.rgb = mix(
            fragColor.rgb,
            color,
            shape * exp( -10.0 * t )
        );
    }
    
    // steps, using polar mod
    {
        pt = pt.yx;
        float angle = atan( pt.y, pt.x );
        float iStep = mod( floor( angle / TAU * steps + 0.5 ), steps );
        pt = pt * rotate2D( iStep / steps * TAU );

        bool isPulse = euclideanRhythms( pulses, steps, iStep - offset );
        
        if ( isPulse ) {
            float elapsed = mod( currentStep - iStep, steps );

            float radius = ( 0.02 + 0.02 * exp( -elapsed ) );
            float d = sdcapsule( pt - vec2( 0.32, 0.0 ), vec2( 0.06, 0.0 ) ) - radius;

            float outline = smoothstep( 4.0 / iResolution.y, 0.0, d - 0.01 );
            float shape = smoothstep( 4.0 / iResolution.y, 0.0, d );
            vec3 colort = mix( color, vec3( 1.0 ), exp( -elapsed ) );
            fragColor.rgb = mix(
                fragColor.rgb,
                mix( OUTLINE_COLOR, colort, shape ),
                outline
            );
        } else {
            float d = length( pt - vec2( 0.35, 0.0 ) ) - 0.015;

            float outline = smoothstep( 4.0 / iResolution.y, 0.0, d - 0.01 );
            float shape = smoothstep( 4.0 / iResolution.y, 0.0, d );
            fragColor.rgb = mix(
                fragColor.rgb,
                mix( OUTLINE_COLOR, color, shape ),
                0.5 * outline
            );
        }
    }
    
    // time tick
    {
        vec2 tail = 0.4 * vec2( sin( phase * TAU ), cos( phase * TAU ) );
        float d = sdcapsule( p, tail ) - 0.005;

        float shadow = smoothstep( 0.05, 0.0, d );
        fragColor.rgb = mix( fragColor.rgb, vec3( 0.0 ), 0.3 * pow( shadow, 2.0 ) );

        float shape = smoothstep( 4.0 / iResolution.y, 0.0, d );
        fragColor.rgb = mix( fragColor.rgb, TICK_COLOR, shape );
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = ( uv * 2.0 - 1.0 ) * vec2( iResolution.x / iResolution.y, 1.0 );
    
    fragColor = vec4( BACKGROUND_COLOR, 1.0 );
    
    drawEuclideanCircle( p - vec2( -1.15, 0.5 ), vec3( 0.9, 0.4, 0.4 ), KICK_PULSES, KICK_STEPS, KICK_OFFSET, fragColor );
    drawEuclideanCircle( p - vec2( -0.15, 0.5 ), vec3( 0.9, 0.7, 0.3 ), HIHAT_PULSES, HIHAT_STEPS, HIHAT_OFFSET, fragColor );
    drawEuclideanCircle( p - vec2( 0.85, 0.5 ), vec3( 0.5, 0.6, 0.8 ), SNARE_PULSES, SNARE_STEPS, SNARE_OFFSET, fragColor );
    drawEuclideanCircle( p - vec2( -0.85, -0.5 ), vec3( 0.5, 0.7, 0.3 ), HITOM_PULSES, HITOM_STEPS, HITOM_OFFSET, fragColor );
    drawEuclideanCircle( p - vec2( 0.15, -0.5 ), vec3( 0.2, 0.7, 0.5 ), LOTOM_PULSES, LOTOM_STEPS, LOTOM_OFFSET, fragColor );
    drawEuclideanCircle( p - vec2( 1.15, -0.5 ), vec3( 0.5, 0.8, 0.8 ), RIM_PULSES, RIM_STEPS, RIM_OFFSET, fragColor );
}
