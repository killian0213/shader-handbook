// Image (image) —  Fiber Zooming by leon
// https://www.shadertoy.com/view/3fKyDG

// Fiber Zooming
// Leon Denise 07/12/2025

// inspired by a motion design clip in an episode of "Kurzgesagt"
// "Trees Are So Weird" https://youtu.be/ZSch_NgZpQs?t=193

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    float rng = InterleavedGradientNoise(fragCoord);
    vec3 color = texture(iChannel0, uv, 2.+rng*5.).rgb;
    fragColor = vec4(color*5.*(abs(uv.x-.5)+.5), 1);
}