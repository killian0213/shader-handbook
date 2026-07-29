// Buffer B (buffer) — Alice by SL0ANE
// https://www.shadertoy.com/view/4fjSDy

# define RECOVER_TIME 2.0
# define SENSITIVE 1.0

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 curRot = load(POINTER_ROT);
    float time = load(POINTER_TIME).x;
    float press = load(POINTER_PRESS).x;
    vec4 mouse = load(POINTER_MOUSE);
    if(curRot == vec4(0.0)) curRot = vec4(0.0, 0.0, 0.0, 1.0);
    
    if(iMouse.z > 0.0)
    {
        if(press < 1.0)
        {
            press = 1.0;
            mouse = iMouse;
        }
        
        vec2 curAng = vec2(PI * SENSITIVE * (iMouse.x - mouse.x) / iResolution.x, PI * SENSITIVE * (mouse.y - iMouse.y) / iResolution.x);
        time = 0.0;
        curRot = quaternionMul(vec4(sin(curAng.y / 2.0), 0.0, 0.0, cos(curAng.y / 2.0)), vec4(0.0, sin(curAng.x / 2.0), 0.0, cos(curAng.x / 2.0)));

    }
    else
    {
        press = 0.0;
        curRot = quaternionLerp(curRot, vec4(0.0, 0.0, 0.0, 1.0), clamp(time / RECOVER_TIME, 0.0, 1.0));
        time += iTimeDelta;
    }
    
    store(POINTER_ROT, curRot);
    store(POINTER_TIME, vec4(time));
    store(POINTER_PRESS, vec4(press));
    store(POINTER_MOUSE, mouse);
}