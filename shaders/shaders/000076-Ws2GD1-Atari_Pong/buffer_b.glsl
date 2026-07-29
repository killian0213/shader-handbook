// Buffer B (buffer) — Atari Pong by Belocio
// https://www.shadertoy.com/view/Ws2GD1

const float Thickness = 0.001;

const vec3 BallColor = vec3(1.0, 1.0, 1.0);
const vec3 PaddleColor = vec3(1.0, 1.0, 1.0);
const vec3 BorderColor = vec3(1.0, 1.0, 1.0);

// Digit data by P_Malin (https://www.shadertoy.com/view/4sf3RN)
const int[] font = int[](0x75557, 0x22222, 0x74717, 0x74747, 0x11574, 0x71747, 0x71757, 0x74444, 0x75757, 0x75747);
const int[] powers = int[](1, 10, 100, 1000, 10000);
float PrintInt( in vec2 uv, in int value )
{
    const int maxDigits = 2;
    if( abs(uv.y-0.5)<0.5 )
    {
        int iu = int(floor(uv.x));
        if( iu>=0 && iu<maxDigits )
        {
            int n = (value/powers[maxDigits-iu-1]) % 10;
            uv.x = fract(uv.x);//(uv.x-float(iu)); 
            ivec2 p = ivec2(floor(uv*vec2(4.0,5.0)));
            return float((font[n] >> (p.x+p.y*4)) & 1);
        }
    }
    return 0.0;
}

float sdSquare(in vec2 p, in vec2 pos, in vec2 size)
{
    vec2 d = abs(p - pos) - size;
  	return length(max(d,0.0));
}

vec3 RenderBall(vec2 pos, vec2 ballPos, vec3 col)
{
    float t = sdSquare(pos, ballPos, vec2(BallRadius, BallRadius));
    return mix(BallColor, col, smoothstep(0.0, Thickness, t));
}

vec3 RenderPaddle(vec2 pos, vec2 paddlePos, vec3 col)
{
    //float t = SegmentMask(pos, paddlePos - vec2(0.0, PaddleHalfSize.y), paddlePos + vec2(0.0, PaddleHalfSize.y), PaddleHalfSize.x);
    float t = sdSquare(pos, paddlePos, PaddleHalfSize);
    
    return mix(PaddleColor, col, smoothstep(0.0, Thickness, t));
}

vec3 RenderBorders(in vec2 pos, in float distToCenter, in vec3 col)
{
    float t = abs(abs(pos.y) - distToCenter) / HalfWallWidth;
    
    return mix(BorderColor, col, smoothstep(0.0, Thickness, t - 1.0));
}

vec3 RenderScore(in vec2 score, in vec2 fragCoord, in vec3 col)
{
    const vec2 displacement = vec2(0.3, -0.65);
    vec2 uv = (2.0*fragCoord-iResolution.xy) / iResolution.y;
    
    col = mix(col, vec3(1.0, 1.0, 1.0), PrintInt((uv + displacement) * vec2(10.0, 7.0), int(score.x)));
    col = mix(col, vec3(1.0, 1.0, 1.0), PrintInt((uv + displacement * vec2(-0.4, 1.0)) * vec2(10.0, 7.0), int(score.y)));
    
    return col;
}

vec3 RenderCenterLine(in vec2 pos, in float limitsDistToCenter, in vec3 col)
{
    float t = abs(pos.x) - 0.003;
    float dashT = step(0.0, sin(pos.y * 200.0));
    float limitsT = (abs(pos.y) - limitsDistToCenter);
    
    col = mix(vec3(1.0, 1.0, 1.0), col, smoothstep(0.0, Thickness, max(t, limitsT) + dashT));
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  	vec2 pos = (fragCoord.xy / iResolution.xy) * 2.0 - 1.0;
    pos.y *= iResolution.y / iResolution.x;  
    
     // load game state
    vec2 playerPaddlePos = LoadValue(iChannel0, txPlayerPaddlePos).xy;
    vec2 gpuPaddlePos = LoadValue(iChannel0, txGPUPaddlePos).xy;
    vec2 ballPos = LoadValue(iChannel0, txBallPosDir).xy;
    vec2 score = LoadValue(iChannel0, txScore).xy;
    
    vec3 col = vec3(0.0, 0.0, 0.0);
    
    col = RenderBall(pos, ballPos, col);
    col = RenderPaddle(pos, playerPaddlePos, col);
    col = RenderPaddle(pos, gpuPaddlePos, col);
    col = RenderBorders(pos, HalfFieldHeight, col);
    col = RenderCenterLine(pos, HalfFieldHeight, col);
    col = RenderScore (score, fragCoord, col);
    
    
    fragColor = vec4(col, 1.0);
}