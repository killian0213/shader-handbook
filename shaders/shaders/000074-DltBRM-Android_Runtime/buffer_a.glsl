// Buffer A (buffer) — Android Runtime by shau
// https://www.shadertoy.com/view/DltBRM

// Created by SHAU - 2023
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------

#define T iTime*4.0

vec3 moveJoint(vec3 joint, float r)
{
    joint.xy *= rot(r);
    return joint;
}

struct Arm
{
    vec4 shoulder;
    vec4 elbow;
    vec4 wrist;
    vec4 knuckle;
    vec4 finger;
};

Arm moveArm(vec3 back, float t, float side)
{
    Arm arm = Arm(vec4(0.0),
                  vec4(0.0),
                  vec4(0.0),
                  vec4(0.0),
                  vec4(0.0));
                  
    vec3 elbow = vec3(0.0,-3.0,-1.4*side),
         wrist = vec3(3.0,0.0,S(0.0,-1.0,sin(t))*side*1.8),
         knuckle = vec3(1.4,0.0,-0.4*side),
         finger = vec3(1.0,0.0,0.3*side);
              
    elbow.xy *= rot(0.4 + sin(t)*0.6);
    wrist.xy *= rot(0.8+sin(t)*1.0);
    knuckle.xy *= rot(0.6+sin(t)*1.2);
    finger.xy *= rot(0.6+sin(t)*1.2);
    
    arm.shoulder.xyz = back+vec3(sin(t-PI)*0.3,sin(t)*0.3,-2.4*side);
    arm.elbow.xyz = arm.shoulder.xyz + elbow;
    arm.wrist.xyz = arm.elbow.xyz + wrist;
    arm.knuckle.xyz = arm.wrist.xyz + knuckle;
    arm.finger.xyz = arm.knuckle.xyz + finger;
    
    //muscle contraction
    float x = sin(t);
    arm.shoulder.w = 0.4 + S(-0.4,0.6,-x)*0.1;;
    arm.elbow.w = 0.3 + S(-0.3,0.8,-x)*0.06;
    
    return arm;
}

struct Leg
{
    vec4 hip;
    vec4 knee;
    vec4 ankle;
    vec4 foot;
    vec4 toe;
};

Leg moveLeg(vec3 origin, float t, float side)
{
    Leg leg = Leg(vec4(0.0),
                  vec4(0.0),
                  vec4(0.0),
                  vec4(0.0),
                  vec4(0.0));
    
    vec3 knee = vec3(0.0,-4.7,0.0),
         ankle = vec3(0.0,-4.5,0.0),
         foot = vec3(1.9,0.0,0.0),
         toe = vec3(0.9,0.0,0.0);

    float x = sin(t),
          xp5 = abs(sin((t+0.6)*0.5)),
          yy = mod((t+0.6),PI*2.0);

    leg.hip.xyz = origin + vec3(sin(t)*0.2,cos(t)*0.2,-1.5*side);
    leg.knee.xyz = leg.hip.xyz + moveJoint(knee,x*0.5);
    //leg.ankle = leg.knee + moveJoint(ankle,x+xp5*0.7+xp5*yy*0.25);
    leg.ankle.xyz = leg.knee.xyz + moveJoint(ankle,x*0.5+xp5*yy*0.5);
    
    foot.xy *= rot( mix(0.2+xp5,1.2+xp5,S(0.3,0.6,xp5)));
    toe.xy *= rot( mix(0.2+xp5,1.2+xp5,S(0.1,0.4,xp5)));
    toe = mix(vec3(0.7,0.0,0.0),toe,S(0.2,1.0,xp5)); 
    leg.foot.xyz = leg.ankle.xyz + foot;
    leg.toe.xyz = leg.foot.xyz + toe;
    
    //muscle contraction
    leg.hip.w = 0.5 + S(-0.4,0.6,-x)*0.2;
    leg.knee.w = 0.5 + S(-0.3,0.8,-x)*0.1;    
    
    return leg;
}

void mainImage(out vec4 C, vec2 U) 
{
    float at = T, at2 = mod(at*0.1,PI*6.0);
    C = vec4(0.0);
    
    vec4 cam  = vec4(60.0*cos(at2),3.0,-20.0*sign(sin(at2)),1.4),
         la = vec4(0.0,6.0,0.0,0.0);
    if ((at2>PI*0.5&&at2<PI*2.5) || (at2>PI*3.5&&at2<PI*5.5))
    {
        cam  = vec4(0.0,cam.y,-20.0,1.4);
        cam.xz *= rot(at2-PI*0.5);
        
    }
    cam.y += (1.0+cos(T*0.131))*12.0*S(40.0,0.0,abs(cam.x));
    cam.z *= S(45.0,10.0,abs(cam.x));
    
    vec3 origin = vec3(0.0,4.0+abs(sin(at))*0.8,0.0),    
         back = origin + vec3(0.0,6.0,0.0),
         head = vec3(0.0,3.5,0.0);

    back.xy *= rot(0.02+cos(at*2.0)*0.03);
    head.xy *= rot(0.36+cos(at*2.0)*0.04);
    head += back;
    
    Leg rightLeg = moveLeg(origin,at,RIGHT);
    Leg leftLeg = moveLeg(origin,at-PI,LEFT);

    Arm rightArm = moveArm(back,at-PI,RIGHT);
    Arm leftArm = moveArm(back,at,LEFT);

    if (U==CAM)
    {
        C = cam;
    }
    if (U==LA)
    {
        C = la;
    }

    if (U==B_SPINE)
    {
        C = vec4(origin,0.0);  
    }
    if (U==R_HIP)
    {
        C = rightLeg.hip;    
    }
    if (U==R_KNEE)
    {
        C = rightLeg.knee; 
    }
    if (U==R_ANKLE)
    {
        C = rightLeg.ankle;    
    }
    if (U==R_FOOT)
    {
        C = rightLeg.foot;    
    }
    if (U==R_TOE)
    {
        C = rightLeg.toe;    
    }
    if (U==L_HIP)
    {
        C = leftLeg.hip;    
    }    
    if (U==L_KNEE)
    {
        C = leftLeg.knee; 
    }
    if (U==L_ANKLE)
    {
        C = leftLeg.ankle;    
    }
    if (U==L_FOOT)
    {
        C = leftLeg.foot;    
    }
    if (U==L_TOE)
    {
        C = leftLeg.toe;    
    }
    if (U==T_SPINE)
    {
        C = vec4(back,0.0);    
    }
    if (U==R_SHOULDER)
    {
        C = rightArm.shoulder;    
    }
    if (U==R_ELBOW)
    {
        C = rightArm.elbow;
    }
    if (U==R_WRIST)
    {
        C = rightArm.wrist;
    }
    if (U==R_KNUCKLE)
    {
        C = rightArm.knuckle;
    }
    if (U==R_FINGER)
    {
        C = rightArm.finger;
    }
    if (U==L_SHOULDER)
    {
        C = leftArm.shoulder;    
    }
    if (U==L_ELBOW)
    {
        C = leftArm.elbow;
    }
    if (U==L_WRIST)
    {
        C = leftArm.wrist;
    }
    if (U==L_KNUCKLE)
    {
        C = leftArm.knuckle;
    }
    if (U==L_FINGER)
    {
        C = leftArm.finger;
    }
    if (U==HEAD)
    {
        C = vec4(head,0.0);
    }
}