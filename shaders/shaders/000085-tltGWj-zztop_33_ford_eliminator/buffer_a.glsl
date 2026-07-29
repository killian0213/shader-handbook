// Buffer A (buffer) — zztop '33 ford eliminator by flockaroo
// https://www.shadertoy.com/view/tltGWj

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// some minimal driving sim (not much physics involved here, just simple driving/steering)

#ifdef SHADEROO
#include Include_A.glsl
#endif

#define keyTex iChannel1
#define KEY_I (texture(keyTex,vec2((105.5-32.0)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_A (texture(keyTex,vec2((65.5+ 0.)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_W (texture(keyTex,vec2((65.5+22.)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_R (texture(keyTex,vec2((65.5+17.)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_S (texture(keyTex,vec2((65.5+18.)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_D (texture(keyTex,vec2((65.5+ 3.)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_F (texture(keyTex,vec2((65.5+ 5.)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_PLUS  (texture(keyTex,vec2((187.5)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_MINUS (texture(keyTex,vec2((189.5)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_LEFT  (texture(keyTex,vec2(( 37.5)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_RIGHT (texture(keyTex,vec2(( 39.5)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_DOWN  (texture(keyTex,vec2(( 40.5)/256.0,(0.5+0.0)/3.0)).x)
#define KEY_UP    (texture(keyTex,vec2(( 38.5)/256.0,(0.5+0.0)/3.0)).x)

void mainImage( out vec4 fragColor, vec2 fragCoord )
{
    #ifdef ZZT_AS_TEX
    vec2 uv = fragCoord.xy / Res0;
    fragColor = zztop((uv*2.-.75)*11.,-1.);
    #endif

    vec3 pos  =texelFetch(iChannel0,ivec2(0,0),0).xyz;
    vec3 vel  =texelFetch(iChannel0,ivec2(1,0),0).xyz;
    vec3 omega=texelFetch(iChannel0,ivec2(2,0),0).xyz;
    vec4 quat =texelFetch(iChannel0,ivec2(3,0),0);
    float SteerAng =texelFetch(iChannel0,ivec2(4,0),0).x;
    float camDist =texelFetch(iChannel0,ivec2(4,0),0).y;
    vec4 wheelRot =texelFetch(iChannel0,ivec2(5,0),0);
    float phi=quat.x;
    
    float dt=iTimeDelta;
    
    float axDist=3.5;
    vec3 rearAxPos = vec3(0,1.7,0);
    
    //quat=vec4(0,0,0,1);
    vec3 bx=transformVecByQuat(vec3(1,0,0),quat);
    vec3 by=transformVecByQuat(vec3(0,1,0),quat);
    
    vel+=KEY_W*by*.25;
    vel-=KEY_S*by*.25;
    vel+=KEY_UP*by*.25;
    vel-=KEY_DOWN*by*.25;
    vel*=.99;
    if(vel!=vec3(0)) vel-=normalize(vel)*.05;
    if(length(vel)<.1) vel=vec3(0);
    SteerAng*=.91;
    SteerAng-=KEY_A*.05;
    SteerAng+=KEY_D*.05;
    SteerAng-=KEY_LEFT*.05;
    SteerAng+=KEY_RIGHT*.05;
    camDist*=(1.-.02*KEY_PLUS);
    camDist*=(1.+.02*KEY_MINUS);
    
    vec3 dax=transformVecByQuat(rearAxPos,quat);

    bool noSteer =  (abs(SteerAng)<.0001);
    float r=axDist/tan(SteerAng);
    if(noSteer) r=10000.;
    vec3 c=pos-dax+bx*r;
    vec3 ang=cross(-vel*dt,pos-c)/dot(pos-c,pos-c);
    vec4 dquat=angVec2Quat(ang);
    float wheelRadius=0.3;
    wheelRot+=-dot(vel,by)*dt/wheelRadius;
    
    if(isnan(dquat.x)) dquat=vec4(0,0,0,1);
    if(isnan(dquat.y)) dquat=vec4(0,0,0,1);
    if(isnan(dquat.z)) dquat=vec4(0,0,0,1);
    if(isnan(dquat.w)) dquat=vec4(0,0,0,1);
    if(noSteer) dquat=vec4(0,0,0,1);
    pos=c+transformVecByQuat(pos-c,dquat);
    if(noSteer) pos+=vel*dt;
    vel=transformVecByQuat(vel,dquat);
    quat=multQuat(quat,dquat);
    
    if(iFrame==0)
    {
        pos=vec3(0,0,0);
        vel=vec3(0,0,0);
        quat=vec4(0,0,0,1);
        SteerAng=0.;
        wheelRot=vec4(0);
        camDist=1.;
    }
    
    if (ivec2(fragCoord)==ivec2(0,0)) fragColor = vec4(pos,1.0);
    if (ivec2(fragCoord)==ivec2(1,0)) fragColor = vec4(vel,1.0);
    if (ivec2(fragCoord)==ivec2(2,0)) fragColor = vec4(omega,1.0);
    if (ivec2(fragCoord)==ivec2(3,0)) fragColor = vec4(quat);
    if (ivec2(fragCoord)==ivec2(4,0)) fragColor = vec4(SteerAng,camDist,0,1);
    if (ivec2(fragCoord)==ivec2(5,0)) fragColor = vec4(wheelRot);
}

