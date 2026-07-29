// Image (image) — Minimal Fluidish Simulacre by leon
// https://www.shadertoy.com/view/7dGfWw


// Minimal Fluidish Simulacre

// found by accident that shifting pixels
// on a height map with the slope direction
// calculated by sampling neighbors at random long range
// produces somehow turbulent fluid movement

// i'm amazed that it produces such organic patterns
// when there is no perlin noise, no gyroid, no force fields
// just white grainy noise and slope movement

// this accident is dedicated to Cornus Ammonis
// which works inspired me in so many ways
// and because this shader looks like a drunken version of his work

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    fragColor = texture(iChannel0, uv);
}