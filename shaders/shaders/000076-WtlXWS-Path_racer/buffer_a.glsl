// Buffer A (buffer) — Path racer by XT95
// https://www.shadertoy.com/view/WtlXWS

// Created by anatole duprat - XT95/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


//Physic engine pass

const float G = 9.81;

void simulation() {
    
    // keyboard input
    const int KEY_LEFT  = 37;
    const int KEY_UP    = 38;
    const int KEY_RIGHT = 39;
    const int KEY_DOWN  = 40;
    const int KEY_W     = 87;
    const int KEY_S     = 83;
    
    vec3 keyDir = vec3(0.);
    keyDir.z += texelFetch( iChannel1, ivec2(KEY_W,0), 0 ).x;
    keyDir.z -= texelFetch( iChannel1, ivec2(KEY_S,0), 0 ).x;
    keyDir.y += texelFetch( iChannel1, ivec2(KEY_DOWN,0), 0 ).x;
    keyDir.y -= texelFetch( iChannel1, ivec2(KEY_UP,0), 0 ).x;
    keyDir.x += texelFetch( iChannel1, ivec2(KEY_LEFT,0), 0 ).x;
    keyDir.x -= texelFetch( iChannel1, ivec2(KEY_RIGHT,0), 0 ).x;
    
    // TODO : support iDeltaTime
    float dt = 1. / 60.;
    
    
    if (data.touchStart.z == 1.) {
        keyDir.z += clamp((iMouse.y - data.touchStart.y)/10., -1., 1.);
        keyDir.x -= clamp((iMouse.x - data.touchStart.x)/50., -1., 1.);
    }
    
    // acceleration
    data.shipAccel += keyDir * dt * vec3(15.,20.,20.);
    data.shipAccel *= .8;
    data.shipTheta -= data.shipAccel.x * dt *3.;

    // velocity
    data.shipVelocity += data.shipDirection * (data.shipAccel.z-data.shipAccel.y*.1)*120.;
    data.shipVelocity.y += data.shipAccel.y*50.;
    
    // gravity
    data.shipVelocity.y += -G*20.;
    
    // world feedback 
    float d = level(data.shipPos-vec3(0.,0.,-1.5)) - 1.5; // bounding sphere for free :))!
    vec3 n = normalLevel(data.shipPos, 0.01);
    data.shipVelocity += n*G / abs(exp(d)) * 50.;
    data.shipVelocity.xyz *= .9;
    
    
    // update position
    data.shipLastPos = data.shipPos;
    data.shipPos += data.shipVelocity * dt * dt;
}
    

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 invRes = vec2(1.)/ iResolution.xy;
    vec2 uv = fragCoord * invRes;
    
    // init global
    time = iTime;
    if (iFrame == 0) { 
        data.shipPos = vec3(50., 2., 5.);
        data.shipAccel = vec3(0.);
        data.shipVelocity = vec3(0.);
        data.shipDirection = vec3(0., 0., 1.);
        data.shipTheta = 0.;
        data.touchStart = vec3(0.,0.,0.);
    } else {
        data = readGameData(iChannel0, invRes);
    }
    
    // physic simulation
    simulation();
    
    
    // touch for shadertoy phone app
    if (iMouse.z > 0. && data.touchStart.z == 0.) {
        data.touchStart = iMouse.xyz;
        data.touchStart.z = 1.;
    } else if (iMouse.z <= 0.01) {
        data.touchStart.z = 0.;
    }
    
    // write game data
    vec4 col = vec4(0.);
    col = writeGameData(col, fragCoord.xy, data);
    fragColor = col;
}