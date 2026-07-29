// Buf A (buffer) — 2d Verlet Physics Stunt Car Game by demofox
// https://www.shadertoy.com/view/Msy3WD

// game speed in ticks per second
const float c_tickRate = 16.0;

// what factor to slow the game down by when it's game over
const float c_tickRateGameOver = 0.0;

// how long the game over state slows down the simulation for
const float c_gameOverSlowdownDuration = 3.0;

// how many simulation steps to do per tick.  More = more costly, but better simulations.
const int c_numSimulationSteps = 1;

// simulation constants
const vec2 c_gravityAcceleration = vec2(0.0, -5.0);  // -9.8 is real life values, but 1 unit != 1 meter in our sim.
const float c_rotationMultiplier = 0.1; // how much rotation done
const float c_throttleAcceleration = 4.0;
const float c_fuelBurnRate = 10.0;
const float c_checkPointDistance = 5.0; // in world units, distance between checkpoints.

// derived values
const float c_tickDeltaTime = 1.0 / c_tickRate;
const float c_tickDeltaTimeSq = c_tickDeltaTime*c_tickDeltaTime;

// keys
const float KEY_SPACE = 32.5/256.0;
const float KEY_LEFT  = 37.5/256.0;
const float KEY_UP    = 38.5/256.0;
const float KEY_RIGHT = 39.5/256.0;
const float KEY_DOWN  = 40.5/256.0;

//============================================================
// SHARED CODE BEGIN
//============================================================

#define PI 3.14159265359
#define PIOVERTWO (PI * 0.5)
#define TWOPI (PI * 2.0)

const float c_wheelRadius = 0.04;
const float c_wheelDistance = 0.125;

const float c_fuelCanDistance = 20.0;
const float c_fuelCanRadius = 0.075;

// variables
const vec2 txState = vec2(0.0,0.0);
// x = timer to handle fixed rate gameplay
// y = queued input.  0.0 = left, 1.0 = right, 0.5 = none
// zw = camera center
#define VAR_FRAME_PERCENT state.x
#define VAR_QUEUED_INPUT state.y
#define VAR_CAMERA_CENTER state.zw
const vec2 txState2 = vec2(1.0,0.0);
// x = camera scale
// y = back wheel is on the ground (1.0 or 0.0)
// z = front wheel is on the ground (1.0 or 0.0)
// w = game is over (1.0) or not (0.0)
#define VAR_CAMERA_SCALE state2.x
#define VAR_BACKWHEEL_ONGROUND state2.y
#define VAR_FRONTWHEEL_ONGROUND state2.z
#define VAR_GAMEOVER state2.w
const vec2 txState3 = vec2(2.0,0.0);
// x = used to slowdown simulation only right when you hit game over state
// y = last collected fuel orb distance
// z = spedometer
// w = fuel remaining
#define VAR_SIMSLOWDOWN state3.x
#define VAR_LASTFUELORB state3.y
#define VAR_SPEDOMETER state3.z
#define VAR_FUELREMAINING state3.w
// these are used by check points.  We always restore to the older check point so
// the player doesn't get stuck in a shitty check point.
const vec2 txFrontWheelCP1 = vec2(3.0,0.0);
const vec2 txFrontWheelCP2 = vec2(4.0,0.0);
const vec2 txBackWheelCP1 = vec2(5.0,0.0);
const vec2 txBackWheelCP2 = vec2(6.0,0.0);
const vec2 txState4 = vec2(7.0,0.0);
// x = fuel at CP1
// y = fuel at CP2
// z = last CP hit
// w = unused
#define VAR_FUELREMAININGCP1 state4.x
#define VAR_FUELREMAININGCP2 state4.y
#define VAR_LASTCPHIT state4.w

// simulated points
// format: xy = location this frame. zw = location last frame
const vec2 txBackWheel = vec2(8.0, 0.0);
const vec2 txFrontWheel = vec2(9.0, 0.0);

const vec2 txVariableArea = vec2(10.0, 1.0);

float GroundHeightAtX (float x, float scale)
{
    
    //return 0.0;
    
    /*
    float frequency = 2.0 * frequencyScale;
    float amplitude = 0.1 * scale;
    return sin(x*frequency) * amplitude +
           sin(x*frequency*2.0) * amplitude / 2.0
           + sin(x*frequency*3.0) * amplitude / 3.0
           + sin(x*1.0) * amplitude * 5.0;
    */
    
    #define ADDWAVE(frequency, start, easein, amplitude, scalarFrequency) ret += sin(x * frequency) * clamp((x-start)/easein, 0.0, 1.0) * amplitude * (sin(x*scalarFrequency) * 0.5 + 0.5);
    
    x *= scale;
    
    // add several sine waves together to make the terrain
    // frequency and amplitudes increase over distance    
    float ret = 0.0;
    
    // have a low frequency, low amplitude sine wave
    ADDWAVE(0.634, 0.0, 0.0, 0.55, 0.1);
    
    // a slightly higher frequency adds in amplitude over time
    ADDWAVE(1.0, 0.0, 50.0, 0.5, 0.37);
    
    // at 75 units in, start adding in a higher frequency, lower amplitude wave
    ADDWAVE(3.17, 75.0, 50.0, 0.1, 0.054); 
    
    // at 150 units, add in higher frequency waves
    ADDWAVE(9.17, 150.0, 50.0, 0.05, 0.005);
    
    // at 225 units, add another low frequency, medium amplitude sine wave
    ADDWAVE(0.3, 225.0, 10.0, 0.9, 0.01);    
    
    // add an explicit envelope to the starting area
    ret *= smoothstep(x / 2.0, 0.0, 1.0);
    
    return ret * scale;  
}

float GroundFunction (vec2 p, float scale)
{
    return GroundHeightAtX(p.x, scale) - p.y;
}

vec2 AsyncPointPos (in vec4 point, in float frameFraction)
{
    return mix(point.zw, point.xy, frameFraction);
}

vec2 AsyncBikePos (in vec4 backWheel, in vec4 frontWheel, in float frameFraction)
{
    return (AsyncPointPos(backWheel, frameFraction)+AsyncPointPos(frontWheel, frameFraction)) * 0.5;
}

vec2 GroundFunctionGradiant (in vec2 coords, float scale)
{
    vec2 h = vec2( 0.01, 0.0 );
    return vec2( GroundFunction(coords+h.xy, scale) - GroundFunction(coords-h.xy, scale),
                 GroundFunction(coords+h.yx, scale) - GroundFunction(coords-h.yx, scale) ) / (2.0*h.x);
}

float EstimatedDistanceFromPointToGround (in vec2 point, float scale)
{
    float v = GroundFunction(point, scale);
    vec2  g = GroundFunctionGradiant(point, scale);
    return v/length(g);
}

float EstimatedDistanceFromPointToGround (in vec2 point, float scale, float frequencyScale, out vec2 gradient)
{
    float v = GroundFunction(point, scale);
    gradient = GroundFunctionGradiant(point, scale);
    return v/length(gradient);
}

//============================================================
// SHARED CODE END
//============================================================



//============================================================
// save/load code from IQ's shader: https://www.shadertoy.com/view/MddGzf

float isInside( vec2 p, vec2 c ) { vec2 d = abs(p-0.5-c) - 0.5; return -max(d.x,d.y); }
float isInside( vec2 p, vec4 c ) { vec2 d = abs(p-0.5-c.xy-c.zw*0.5) - 0.5*c.zw - 0.5; return -max(d.x,d.y); }

vec4 loadValue( in vec2 re )
{
    return texture( iChannel0, (0.5+re) / iChannelResolution[0].xy, -100.0 );
}

void storeValue( in vec2 re, in vec4 va, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( isInside(fragCoord,re) > 0.0 ) ? va : fragColor;
}

void storeValue( in vec4 re, in vec4 va, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( isInside(fragCoord,re) > 0.0 ) ? va : fragColor;
}

//============================================================
vec2 RotatePoint (vec2 point, float theta)
{
    return vec2(point.x * cos(theta) - point.y * sin(theta), point.y * cos(theta) + point.x * sin(theta));
}

//============================================================
vec2 RotatePointAroundPoint (vec2 point, vec2 origin, float theta)
{
    return RotatePoint(point-origin, theta) + origin;
}

//============================================================
void VerletIntegrate (inout vec4 point, in vec2 acceleration)
{
	vec2 currentPos = point.xy;
    vec2 lastPos = point.zw;

    vec2 newPos = currentPos + currentPos - lastPos + acceleration * c_tickDeltaTimeSq;
    
    point.xy = newPos;
    point.zw = currentPos;
}

//============================================================
void ResolveGroundCollision (inout vec2 point, inout bool pointTouchingGround)
{
    vec2 gradient;
    float dist = EstimatedDistanceFromPointToGround (point, 1.0, 1.0, gradient) * -1.0;
    if (dist < c_wheelRadius)
    {
        float distanceAdjust = c_wheelRadius - dist;
        point -= normalize(gradient) * distanceAdjust;
        pointTouchingGround = true;
    }
}

//============================================================
void ResolveDistanceConstraint (inout vec2 pointA, inout vec2 pointB, float distance)
{
    // calculate how much we need to adjust the distance between the points
    // and cut it in half since we adjust each point half of the way
    float halfDistanceAdjust = (distance - length(pointB-pointA)) * 0.5;
    
    // calculate the vector we need to adjust along
    vec2 adjustVector = normalize(pointB-pointA);
    
    // adjust each point half of the adjust distance, along the adjust vector
    pointA -= adjustVector * halfDistanceAdjust;
    pointB += adjustVector * halfDistanceAdjust;
}

//============================================================
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if (fragCoord.x > txVariableArea.x || fragCoord.y > txVariableArea.y)
        discard;
    
    //----- Load State -----    
    vec4 state         = loadValue(txState);
    vec4 state2        = loadValue(txState2);
    vec4 state3        = loadValue(txState3);
    vec4 state4        = loadValue(txState4);
    vec4 backWheel     = loadValue(txBackWheel);   
    vec4 frontWheel    = loadValue(txFrontWheel);  
    vec4 frontWheelCP1 = loadValue(txFrontWheelCP1);
    vec4 frontWheelCP2 = loadValue(txFrontWheelCP2);
    vec4 backWheelCP1  = loadValue(txBackWheelCP1);
    vec4 backWheelCP2  = loadValue(txBackWheelCP2);
    
    //----- Initialize -----
    // init on frame 0 or if we are in the game over state and the space bar is pressed
    if (iFrame == 0)
    {
        state = vec4(0.0);
        state2 = vec4(0.0);
        state3 = vec4(0.0);
        state4 = vec4(0.0);
        backWheel = vec4(0.0);
        frontWheel = vec4(0.0);
        backWheelCP1 = vec4(0.0);
        frontWheelCP1 = vec4(0.0);    
        backWheelCP2 = vec4(0.0);
        frontWheelCP2 = vec4(0.0);        
        
        VAR_FRAME_PERCENT = 0.0;
        VAR_QUEUED_INPUT = 0.5;
        VAR_CAMERA_CENTER = vec2(0.0);
        
        VAR_CAMERA_SCALE = 2.0;
        VAR_BACKWHEEL_ONGROUND = 0.0;
        VAR_FRONTWHEEL_ONGROUND = 0.0;
        VAR_GAMEOVER = 0.0;
            
        VAR_SIMSLOWDOWN = 1.0;
        VAR_SPEDOMETER = 0.0;
        VAR_LASTFUELORB = 0.0;
        VAR_FUELREMAINING = 1.0;
        
        backWheel = vec4(-c_wheelDistance*0.5, c_wheelRadius, -c_wheelDistance*0.5, c_wheelRadius);
        frontWheel = vec4( c_wheelDistance*0.5, c_wheelRadius, c_wheelDistance*0.5, c_wheelRadius);   

        // initialize checkpoint data to the starting line state
        backWheelCP1 = backWheel;
        backWheelCP2 = backWheel;
        
        frontWheelCP1 = frontWheel;
        frontWheelCP2 = frontWheel;
        
        VAR_FUELREMAININGCP1 = VAR_FUELREMAINING;
        VAR_FUELREMAININGCP2 = VAR_FUELREMAINING;
        VAR_LASTCPHIT  = 0.0;
    }
    
	// if it's game over and the user presses space bar, restore from the oldest checkpoint
    if (VAR_GAMEOVER == 1.0 && texture(iChannel1, vec2(KEY_SPACE,0.25)).x > 0.1)
    {
        frontWheel = frontWheelCP2;
        backWheel = backWheelCP2;
        
        // make sure you have at least half a tank of gas at a checkpoint. 
        // Your welcome (;
        VAR_FUELREMAINING = max(VAR_FUELREMAININGCP2, 0.5);
        
		VAR_GAMEOVER = 0.0;
        
        VAR_BACKWHEEL_ONGROUND = 0.0;
        VAR_FRONTWHEEL_ONGROUND = 0.0;
        
        VAR_LASTFUELORB = 0.0;
        
        // make sure that we reset CP1 to CP2, so that when we hit CP1 again
        // it doesn't fill in CP1, making it so restarting restarts us at CP1
        // which might be an unsafe checkpoint.  This shows itself as the problem
        // where sometimes some people reset to a checkpoint and they are flipped over
        // with no possible way to survive
        VAR_LASTCPHIT = floor(backWheel.x / c_checkPointDistance) * c_checkPointDistance;
        VAR_FUELREMAININGCP1 = VAR_FUELREMAININGCP2;
        frontWheelCP1 = frontWheelCP2;
        backWheelCP1 = backWheelCP2;        
    }
    
    // make  camera be centered on the bike
	VAR_CAMERA_CENTER = AsyncBikePos(backWheel, frontWheel, VAR_FRAME_PERCENT);    
    
    //----- Input -----
    // input seems backwards in code, but makes sense when playing.
    // Left = accelerate
    // Right = break;
    if (texture(iChannel1, vec2(KEY_RIGHT,0.25)).x > 0.1 || texture(iChannel1, vec2(KEY_UP,0.25)).x > 0.1)
    {
        VAR_QUEUED_INPUT = 1.0;
    }
    else if (texture(iChannel1, vec2(KEY_LEFT,0.25)).x > 0.1 || texture(iChannel1, vec2(KEY_DOWN,0.25)).x > 0.1)
    {
        VAR_QUEUED_INPUT = 0.0;
    }
    
    //----- Simulate -----
    if (VAR_GAMEOVER == 1.0)
    {
        VAR_SIMSLOWDOWN += iTimeDelta / c_gameOverSlowdownDuration;
        VAR_SIMSLOWDOWN = min(VAR_SIMSLOWDOWN, 1.0);
    }
    else
    {
        VAR_SIMSLOWDOWN = 1.0;
    }
    
    // slow down the simulation if it's game over
    VAR_FRAME_PERCENT += iTimeDelta * mix(c_tickRateGameOver, c_tickRate, pow(VAR_SIMSLOWDOWN, 2.0));
    if (VAR_FRAME_PERCENT > 1.0)
    {
        // reset our tick timer
        VAR_FRAME_PERCENT = fract(VAR_FRAME_PERCENT);
        
        vec2 frontWheelRelativeToBackWheel = frontWheel.xy - backWheel.xy;
        
        // if both wheels are on the ground, and the front wheel is behind the back wheel,
        // that means we are upside down and it's game over.
        if (VAR_GAMEOVER != 1.0 && VAR_BACKWHEEL_ONGROUND == 1.0 && VAR_FRONTWHEEL_ONGROUND == 1.0 && dot(frontWheelRelativeToBackWheel, vec2(-1.0,0.0)) > 0.0)
        {
            VAR_GAMEOVER = 1.0;
            VAR_SIMSLOWDOWN = 0.0;
        }
        
        // if we are in the game over state, stop accepting input
        if (VAR_GAMEOVER == 1.0)
            VAR_QUEUED_INPUT = 0.5;
        
        // burn fuel.  Game over when out of fuel!
        if (VAR_QUEUED_INPUT != 0.5)
        {
            VAR_FUELREMAINING -= 1.0 / (c_tickRate * c_fuelBurnRate);
            
            if (VAR_FUELREMAINING < 0.0)
            {
                VAR_GAMEOVER = 1.0;
                VAR_SIMSLOWDOWN = 0.0;
                VAR_FUELREMAINING = 0.0;
                VAR_QUEUED_INPUT = 0.5;
            }
        }        
        
        // if not game over, and we've passed a new checkpoint, store the info
        if (VAR_GAMEOVER == 0.0 && (backWheel.x - VAR_LASTCPHIT) > c_checkPointDistance)
        {
            VAR_LASTCPHIT = floor(backWheel.x / c_checkPointDistance) * c_checkPointDistance;            
            VAR_FUELREMAININGCP2 = VAR_FUELREMAININGCP1;
            VAR_FUELREMAININGCP1 = VAR_FUELREMAINING;
            frontWheelCP2 = frontWheelCP1;
            frontWheelCP1 = frontWheel;
            backWheelCP2 = backWheelCP1;
            backWheelCP1 = backWheel;
        }
        
        // calculate our acceleration - only accelerate if the back wheel is on the ground
        vec2 acceleration = c_gravityAcceleration +
               ((VAR_BACKWHEEL_ONGROUND == 1.0)
                  ? vec2(VAR_QUEUED_INPUT * 2.0 - 1.0, 0.0) * c_throttleAcceleration
                  : vec2(0.0));
        
        // calculate spin amount
        float spin = (VAR_QUEUED_INPUT * 2.0 - 1.0) * c_rotationMultiplier;
        
        // clear queued input
        VAR_QUEUED_INPUT = 0.5;
        
        // move the simulated points
        VerletIntegrate(backWheel, acceleration);
        VerletIntegrate(frontWheel, acceleration);
        
        // apply spin as rotation of the front wheel around the back wheel
        frontWheel.xy = RotatePointAroundPoint(frontWheel.xy, backWheel.xy, spin);
        
        // resolve physical constraints
        bool backWheelOnGround = false;
        bool frontWheelOnGround = false;
        for (int i = 0; i < c_numSimulationSteps; ++i)
        {
        	ResolveGroundCollision(backWheel.xy, backWheelOnGround);
        	ResolveGroundCollision(frontWheel.xy, frontWheelOnGround);
            
            ResolveDistanceConstraint(backWheel.xy, frontWheel.xy, c_wheelDistance);
        }
        
        // remember whether our wheels are on the ground or not
        VAR_BACKWHEEL_ONGROUND = backWheelOnGround ? 1.0 : 0.0;
        VAR_FRONTWHEEL_ONGROUND = frontWheelOnGround ? 1.0 : 0.0;
        
        // cheat code teleportation
        if (backWheel.x < -50.0)
        {
        	backWheel = vec4(3000.0 + -c_wheelDistance*0.5, 0.5, 3000.0 + -c_wheelDistance*0.5, 0.5);
        	frontWheel = vec4(3000.0 + c_wheelDistance*0.5, 0.5, 3000.0 + c_wheelDistance*0.5, 0.5);   
        	VAR_CAMERA_CENTER = AsyncBikePos(backWheel, frontWheel, VAR_FRAME_PERCENT);
            VAR_FUELREMAINING = 9999.0;
        }
    }
    
    // if the bike is close to a fuel orb, replenish fuel
    // Do it ouside of the tick since we interpolate position so could otherwise miss it
    // We could also do a swept shape test but this is quicker
    vec2 asyncBikePos = AsyncBikePos(backWheel, frontWheel, VAR_FRAME_PERCENT);
    vec2 uvFuel;
    uvFuel.x = mod(asyncBikePos.x, c_fuelCanDistance) - c_fuelCanDistance * 0.5;
    uvFuel.y = GroundHeightAtX(floor(asyncBikePos.x / c_fuelCanDistance) * c_fuelCanDistance + c_fuelCanDistance * 0.5, 1.0);
    uvFuel.y += c_fuelCanRadius*1.1;
    if ( VAR_LASTFUELORB < asyncBikePos.x && length(asyncBikePos - vec2(uvFuel.x+asyncBikePos.x, uvFuel.y)) < c_fuelCanRadius * 2.0)
    {
        VAR_FUELREMAINING = max(VAR_FUELREMAINING, 1.0);
        VAR_LASTFUELORB = floor(asyncBikePos.x / c_fuelCanDistance) * c_fuelCanDistance + c_fuelCanDistance * 0.5 + c_fuelCanRadius*2.0;
    }    
    
    //----- Update Spedometer -----
    float spedTarget = 1.2 * (length(backWheel.xy - backWheel.zw) + length(frontWheel.xy - frontWheel.zw)) * 0.5;
	VAR_SPEDOMETER += (spedTarget - VAR_SPEDOMETER) * 3.0 * iTimeDelta;
    
    //----- Update Camera -----
    // The camera is always centered on the bike
    VAR_CAMERA_CENTER = asyncBikePos;
    // The camera zooms out as you go faster
    float distAboveGround = asyncBikePos.y - GroundHeightAtX(asyncBikePos.x, 1.0);
    float targetZoom = 0.0;//clamp(distAboveGround * 4.0, 2.0, 6.0);
    targetZoom = max(targetZoom, VAR_SPEDOMETER * 4.0 + 2.0);
    
    VAR_CAMERA_SCALE = mix(VAR_CAMERA_SCALE, targetZoom, iTimeDelta * mix(c_tickRateGameOver, c_tickRate, pow(VAR_SIMSLOWDOWN, 2.0)) / 25.0); 
    VAR_CAMERA_SCALE = clamp(VAR_CAMERA_SCALE, 2.0, 6.0);
    
    
    //----- Save State -----
    fragColor = vec4(0.0);
    storeValue(txState, state, fragColor, fragCoord);
    storeValue(txState2, state2, fragColor, fragCoord);
    storeValue(txState3, state3, fragColor, fragCoord);
    storeValue(txState4, state4, fragColor, fragCoord);
    storeValue(txBackWheel , backWheel , fragColor, fragCoord);
    storeValue(txFrontWheel, frontWheel, fragColor, fragCoord);
    storeValue(txBackWheelCP1, backWheelCP1, fragColor, fragCoord);
    storeValue(txBackWheelCP2, backWheelCP2, fragColor, fragCoord);
    storeValue(txFrontWheelCP1, frontWheelCP1, fragColor, fragCoord);
    storeValue(txFrontWheelCP2, frontWheelCP2, fragColor, fragCoord);
}