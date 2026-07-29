// Buffer A (buffer) — Atari Pong by Belocio
// https://www.shadertoy.com/view/Ws2GD1

//#define TWO_PLAYERS

const int KEY_SPACE = 32;
const int KEY_UP  = 38;
const int KEY_DOWN = 40;
const int KEY_W  = 87;
const int KEY_S = 83;

const float InputSpeed = 1.0;
const float BallSpeed = 1.5;
const float BallSpeedIncreasePerSecond = 0.2;
const float SpeedLimit = 3.0;

const float PlayerPaddleXPos = -0.85;
const float GpuPaddleXPos = 0.85;

float Hash( in float n )
{
    return fract(sin(n)*138.5453123);
}

void StoreValue( in ivec2 txPos, in vec4 value, inout vec4 fragColor, in ivec2 fragPos )
{
    fragColor = (fragPos==txPos) ? value : fragColor;
}

bool KeyPressed(int key)
{ 
    return texelFetch( iChannel1, ivec2(key,0.0), 0 ).x > 0.5;
}

void UpdatePaddlePos(in float moveUp, in float moveDown, float limits, float totalHalfPaddleHeight, inout vec2 paddlePos)
{
    paddlePos.y += iTimeDelta * InputSpeed * (moveUp - moveDown);
    paddlePos.y = clamp(paddlePos.y, -limits + totalHalfPaddleHeight, limits - totalHalfPaddleHeight);
}

float GetSpeed(in float pointStartTime)
{
    return clamp(0.0, SpeedLimit, BallSpeed + (iTime - pointStartTime) * BallSpeedIncreasePerSecond);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 iCurPixel = ivec2(fragCoord-0.5);
 
    // don't compute gameplay outside of the data area
    if( fragCoord.x > 5.0 || fragCoord.y > 1.0 ) discard;
    
    // load game state
    vec2 playerPaddlePos = LoadValue(iChannel0, txPlayerPaddlePos).xy;
    vec2 gpuPaddlePos = LoadValue(iChannel0, txGPUPaddlePos).xy;
    vec4 ballPosDir = LoadValue(iChannel0, txBallPosDir);
    vec2 score = LoadValue(iChannel0, txScore).xy;
    vec3 state = LoadValue(iChannel0, txState).xyz;
    
    if(iFrame == 0)
    {
        ballPosDir = vec4(0.0, 0.0, 0.0, 0.0);
		playerPaddlePos = vec2(PlayerPaddleXPos, 0.0);
    	gpuPaddlePos = vec2(GpuPaddleXPos, 0.0);
    	state.x = -1.0;
        state.z = 1.0;
        score = vec2(0, 0); 
    }
    
    if(state.x < -0.5)
    {
        if(KeyPressed(KEY_SPACE))
        {
            ballPosDir.xy = vec2(0.0, 0.0);
            ballPosDir.zw = normalize(vec2(state.z, Hash(float(iFrame) * 1.5) * 0.25));
            state.x = 0.0;
            state.y = iTime;    
            gpuPaddlePos.y = 0.0;
            playerPaddlePos.y = 0.0;
        }
    }
    else
    {        
        float limits = HalfFieldHeight - HalfWallWidth;
        float totalHalfPaddleHeight = PaddleHalfSize.y;
        
        // Update player paddle position
        float moveUp = texelFetch(iChannel1, ivec2(KEY_UP, 0), 0).x;
		float moveDown  = texelFetch(iChannel1, ivec2(KEY_DOWN, 0), 0).x;
        UpdatePaddlePos(moveUp, moveDown, limits, totalHalfPaddleHeight, playerPaddlePos);
        
        // Update GPU paddle position
        #ifdef TWO_PLAYERS
        moveUp = texelFetch(iChannel1, ivec2(KEY_W, 0), 0).x;
		moveDown  = texelFetch(iChannel1, ivec2(KEY_S, 0), 0).x;
        #else
        moveUp = step(0.0, ballPosDir.y - (gpuPaddlePos.y + totalHalfPaddleHeight));
        moveDown = step(0.0, (gpuPaddlePos.y - totalHalfPaddleHeight) - ballPosDir.y);
        #endif
        
        UpdatePaddlePos(moveUp, moveDown, limits, totalHalfPaddleHeight, gpuPaddlePos);
        
        // Update ball position
        //@{
        ballPosDir.xy += ballPosDir.zw * GetSpeed(state.y) * iTimeDelta;
        
        // Bound with limits
        if(ballPosDir.y + BallRadius >= limits)
        {
            ballPosDir.y = limits - BallRadius;
            ballPosDir.w *= -1.0;
        }
        else if(ballPosDir.y - BallRadius <= -limits)
        {
            ballPosDir.y = BallRadius - limits;
            ballPosDir.w *= -1.0;
        }
        
        if(ballPosDir.x + BallRadius >= (gpuPaddlePos.x - PaddleHalfSize.x))
        {
            if(abs(ballPosDir.y - gpuPaddlePos.y) <= totalHalfPaddleHeight + BallRadius)
            {
                ballPosDir.x = gpuPaddlePos.x - PaddleHalfSize.x - BallRadius;
                ballPosDir.z *= -1.0;
                ballPosDir.w += (ballPosDir.y - gpuPaddlePos.y) * 5.0;
                ballPosDir.zw = normalize(ballPosDir.zw);
            }
        }
        else if(ballPosDir.x - BallRadius <= playerPaddlePos.x + PaddleHalfSize.x)
        {
            if(abs(ballPosDir.y - playerPaddlePos.y) <= totalHalfPaddleHeight + BallRadius)
            {
                ballPosDir.x = playerPaddlePos.x + PaddleHalfSize.x + BallRadius;
                ballPosDir.z *= -1.0;
                ballPosDir.w += (ballPosDir.y - playerPaddlePos.y) * 5.0;
                ballPosDir.zw = normalize(ballPosDir.zw);
            }
        }
        //@} 
           
        // Check score
        if(ballPosDir.x - BallRadius > gpuPaddlePos.x)
        {
            score.x += 1.0;
            state.x = -1.0;
            state.z = -1.0;
        }
        else if(ballPosDir.x + BallRadius < playerPaddlePos.x)
        {
            score.y += 1.0;
            state.x = -1.0;
            state.z = 1.0;
        }
    }
    
    fragColor = vec4(0.0);
    
    StoreValue(txPlayerPaddlePos, vec4(playerPaddlePos, 0.0, 0.0), fragColor, iCurPixel);
    StoreValue(txGPUPaddlePos, vec4(gpuPaddlePos, 0.0, 0.0), fragColor, iCurPixel);
    StoreValue(txBallPosDir, ballPosDir, fragColor, iCurPixel);
    StoreValue(txScore, vec4(score, 0.0, 0.0), fragColor, iCurPixel);
    StoreValue(txState, vec4(state, 0.0), fragColor, iCurPixel);    
}