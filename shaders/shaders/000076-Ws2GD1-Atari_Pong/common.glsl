// Common (common) — Atari Pong by Belocio
// https://www.shadertoy.com/view/Ws2GD1

const ivec2 txPlayerPaddlePos = ivec2(0,0);
const ivec2 txGPUPaddlePos = ivec2(1,0);
const ivec2 txBallPosDir = ivec2(2,0);
const ivec2 txScore = ivec2(3,0);
const ivec2 txState = ivec2(4,0);

const vec2 PaddleHalfSize = vec2(0.015, 0.08);
const float HalfWallWidth = 0.01;
const float BallRadius = 0.015;
const float HalfFieldHeight = 0.53;

vec4 LoadValue( in sampler2D iChannel, in ivec2 re )
{
    return texelFetch( iChannel, re, 0 );
}
