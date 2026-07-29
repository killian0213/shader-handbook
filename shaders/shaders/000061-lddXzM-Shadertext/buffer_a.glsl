// Buffer A (buffer) — Shadertext by Andre
// https://www.shadertoy.com/view/lddXzM

//======Start shared code for state
#define pz_stateYOffset 0.0
#define pz_stateBuf 0
#define pz_stateSample(x) texture(iChannel0,x)
vec2 pz_realBufferResolution;
vec2 pz_originalBufferResolution;

void pz_initializeState() {
    pz_realBufferResolution     = iChannelResolution[pz_stateBuf].xy;
    pz_originalBufferResolution = pz_stateSample(.5/pz_realBufferResolution).xy;
}

vec2 pz_nr2vec(float nr) {
    return vec2(mod(nr, pz_originalBufferResolution.x)
                      , pz_stateYOffset+floor(nr / pz_originalBufferResolution.x))+.5;
}

vec4 pz_readState(float nr) {
    return pz_stateSample(pz_nr2vec(nr)/pz_realBufferResolution);
}

float pz_resetCount() {
    return pz_readState(1.).z;
}

vec3 pz_position() {
    return pz_readState(3.).xyz;
}

vec2 pz_initializeState(vec2 fragCoord) {
    pz_initializeState();
    
    vec3 position = pz_position();
    fragCoord -= 0.5*iResolution.xy;
    fragCoord *= position.z;
    fragCoord += (0.5 + position.xy) * iResolution.xy ;
    return fragCoord;
}
//======End shared code for state

//======Defines for state behaviour
#define pz_resetOnMove 1
#define pz_kinetic 0.9

bool pz_checkCell(float nr, vec2 coord) {
    return distance(pz_nr2vec(nr),coord)<=0.5;
}

// Keyboard constants definition
const float KEY_BSP   = 8.5/256.0;
const float KEY_SP    = 32.5/256.0;
const float KEY_LEFT  = 37.5/256.0;
const float KEY_UP    = 38.5/256.0;
const float KEY_RIGHT = 39.5/256.0;
const float KEY_DOWN  = 40.5/256.0;
const float KEY_A     = 65.5/256.0;
const float KEY_B     = 66.5/256.0;
const float KEY_C     = 67.5/256.0;
const float KEY_D     = 68.5/256.0;
const float KEY_E     = 69.5/256.0;
const float KEY_F     = 70.5/256.0;
const float KEY_G     = 71.5/256.0;
const float KEY_H     = 72.5/256.0;
const float KEY_I     = 73.5/256.0;
const float KEY_J     = 74.5/256.0;
const float KEY_K     = 75.5/256.0;
const float KEY_L     = 76.5/256.0;
const float KEY_M     = 77.5/256.0;
const float KEY_N     = 78.5/256.0;
const float KEY_O     = 79.5/256.0;
const float KEY_P     = 80.5/256.0;
const float KEY_Q     = 81.5/256.0;
const float KEY_R     = 82.5/256.0;
const float KEY_S     = 83.5/256.0;
const float KEY_T     = 84.5/256.0;
const float KEY_U     = 85.5/256.0;
const float KEY_V     = 86.5/256.0;
const float KEY_W     = 87.5/256.0;
const float KEY_X     = 88.5/256.0;
const float KEY_Y     = 89.5/256.0;
const float KEY_Z     = 90.5/256.0;
const float KEY_COMMA = 188.5/256.0;
const float KEY_PER   = 190.5/256.0;
const float KEY_ADD   = 107.5/256.0;
const float KEY_SUBS  = 109.5/256.0;
const float KEY_EQUAL = 187.5/256.0;
const float KEY_MINUS = 189.5/256.0;

bool checkKey(float key)
{
	return texture(iChannel1, vec2(key, 0.25)).x > 0.5;
}

bool checkKey(float key1, float key2)
{
    return checkKey(key1) || checkKey(key2);
}

bool checkKey(float key1, float key2, float key3)
{
    return checkKey(key1) || checkKey(key2) || checkKey(key3);
}

void pz_mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    pz_initializeState();
    fragColor = pz_stateSample(fragCoord/pz_realBufferResolution);
    if (fragCoord.x < 1. 
     && fragCoord.y < 1.) {
        //Lets store the initial buffersize at pos0 and use that for addressing
        if (pz_originalBufferResolution.x == 0.0)
            fragColor = vec4(pz_realBufferResolution,1.0,1.0);
        
    } else if (pz_checkCell(1.,fragCoord)) {
        
        // Use postion 1 to trigger screen size changes so we can clear other buffers on going fullscreen
        if (distance(fragColor.xy,pz_realBufferResolution)>1.0 
#if pz_resetOnMove            
            || pz_readState(3.).w > 0.0
#endif            
           ) {
            fragColor.xy = pz_realBufferResolution;
            fragColor.z = 60.0;
        } else {
            if (fragColor.z > 0.0)
                fragColor.z -= 1.0;
        }
        
    } else if (pz_checkCell(2.,fragCoord)) {
        // Store mouse delta if keydown
        if (iMouse.w>0.5) {
            if (fragColor.x>0.0) {
                fragColor.zw = fragColor.xy - iMouse.xy;
            } else {
                fragColor.zw = vec2(0.0);
            }
            fragColor.xy = iMouse.xy;
        } else {
            
            fragColor.xy = vec2(-1.,-1.);
#ifdef pz_kinetic
            fragColor.zw = length(fragColor.zw)>0.1?fragColor.zw*pz_kinetic:vec2(0.0,0.0);
#else                             
            fragColor.zw = vec2(0.0,0.0);
#endif                             
        }
        
    } else if (pz_checkCell(3.,fragCoord)) { 
        // Handle keyboard moves
        vec2 delta = vec2( checkKey(KEY_LEFT ,KEY_A,KEY_Q)?-0.02:
                           checkKey(KEY_RIGHT,KEY_D      )? 0.02:0.0
                         , checkKey(KEY_DOWN ,KEY_S      )?-0.02:
                           checkKey(KEY_UP   ,KEY_W,KEY_Z)? 0.02:0.0);
        float factor = checkKey(KEY_SUBS, KEY_MINUS)?1.01:
                       checkKey(KEY_ADD , KEY_EQUAL)?0.99:1.0;
        if (fragColor.z<0.0000001)
            fragColor.z = 1.0;
        
        //Update transform state
        vec2 mouseDelta = pz_readState(2.).zw;
        fragColor.z *= factor;
        fragColor.xy += delta *  fragColor.z; //Add keyboard move
        fragColor.xy += mouseDelta / iResolution.xy *  fragColor.z; //Add mouse delta
        
        //Store movement in w
        fragColor.w = abs(factor-1.0)*3. + length(delta) + length(mouseDelta);
                
    } else
        fragColor = vec4(0.,0.,0.,1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    pz_mainImage( fragColor, fragCoord );
    
    // Add multiple state handlers here
}
