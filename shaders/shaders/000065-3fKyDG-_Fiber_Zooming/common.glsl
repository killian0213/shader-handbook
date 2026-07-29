// Common (common) —  Fiber Zooming by leon
// https://www.shadertoy.com/view/3fKyDG


// hornet
// https://www.shadertoy.com/view/MslGR8
// http://advances.realtimerendering.com/s2014/index.html
float InterleavedGradientNoise( vec2 uv )
{
    const vec3 magic = vec3( 0.06711056, 0.00583715, 52.9829189 );
    return fract( magic.z * fract( dot( uv, magic.xy ) ) );
}

// Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

// https://github.com/glslify/glsl-easings/blob/master/sine-in-out.glsl
float sineInOut(float t) {
    return -0.5 * (cos(3.1415 * t) - 1.0);
}

// Inigo Quilez
// https://iquilezles.org/articles/distfunctions2d/
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}