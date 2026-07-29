// Buffer B (buffer) — grass with wind by kev7774
// https://www.shadertoy.com/view/4dBcDV

// Free fly by Tempally: https://www.shadertoy.com/view/MtGSzD

// [A]=65 ... [Z]=90, [0]=48 ... [9]=57, [space]=32, [<]=37, [^]=38, [>]=39, [v]=40

#define KEY_LEFT 0.146484375
#define KEY_RIGHT 0.154296875
#define KEY_DOWN 0.158203125
#define KEY_UP 0.150390625


//Use these defines for WASD controls (not the default because not everyone has a qwerty keyboard)
/*
#define KEY_LEFT 0.255859375
#define KEY_RIGHT 0.267578125
#define KEY_DOWN 0.326171875
#define KEY_UP 0.341796875
*/

//change velocity per frame:
#define ACCEL .02
#define BRAKE .9;

const vec2 mouseSens = vec2(-.6, 1.); //mouse sensivity, change signs to invert axis 

float getKey(float key) {return texture(iChannel1, vec2(key, .25)).x;}

vec4 getVar(int key) {return texture(iChannel0, vec2(.05 + float(key), .5)/iResolution.xy);}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    if (fragCoord.y > .9) discard;
    int idx=int(fragCoord.x);
    if (idx <= 1) // orientation
    {
        fragColor = getVar(0);
        fragColor.xy += (float(fragColor.w>.0) - float(iMouse.z>.0 && idx==0)) * 
                        (iMouse.yx/iResolution.yx - .5) * mouseSens;
        vec4 cr = fragColor*6.28318530718;
        if (idx == 0) fragColor.w = iMouse.z; 
        else fragColor = vec4(cos(cr.x), cos(cr.y), sin(cr.x), sin(cr.y));
    }
    else if (idx == 2) // velocity
    {
        vec4 camV = getVar(idx--);
        vec4 tm = getVar(idx);
        camV.xyz += ACCEL * (
          			(getKey(KEY_UP) - getKey(KEY_DOWN)) * vec3(tm.x*tm.w, -tm.z, tm.x*tm.y) +
          			(getKey(KEY_RIGHT) - getKey(KEY_LEFT)) * vec3(tm.y, 0, -tm.w) );
        fragColor = camV * BRAKE;
    }
    else if (idx == 3) fragColor = getVar(idx--) + getVar(idx); // position
}