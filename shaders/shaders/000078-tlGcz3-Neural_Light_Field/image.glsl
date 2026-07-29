// Image (image) — Neural Light Field by blackle
// https://www.shadertoy.com/view/tlGcz3

//CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/
//To the extent possible under law, Blackle Mori has waived all copyright and related or neighboring rights to this work.

//a neural network that represents a light field.
//the network takes in the x and y coordinates of a plane, and the x,y,z coordinates of a view direction at that point
//it then returns the colour of the scene given that direction
//this can be used to construct a "portal" you can see the scene through.
//the scene itself was rendered with blender and then trained into the neural network with a modified siren network
//see: https://vsitzmann.github.io/siren/
//the main modification was adding skip connections so the network can be deep instead of wide

//see the common tab for the network itself and a switch to enable a larger, higher quality model

vec3 plane_intersect(vec3 p, vec3 d, vec3 q, vec3 n) {
    return p + d*dot(q-p, n)/dot(d, n);
}

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p, ax)*ax, p, cos(ro)) + cross(ax,p)*sin(ro);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-iResolution.xy*.5)/iResolution.y;
    vec2 mouse = (iMouse.xy-0.5*iResolution.xy)/iResolution.y;

    vec3 cam = normalize(vec3(uv, 1));
    vec3 init = vec3(0,0,-cos(iTime/3.)*3.-2.);
    init.x += cos(iTime/2.)*.5;
    
    float yrot = cos(iTime)*.5;
    float xrot = sin(iTime/5.)*.5;
    
    if (iMouse.z > 0.) {
        xrot = -3.*mouse.y;
        yrot = 3.*mouse.x;
    }
    
    cam = erot(cam, vec3(1,0,0), xrot);
    init = erot(init, vec3(1,0,0), xrot);
    cam = erot(cam, vec3(0,1,0), yrot);
    init = erot(init, vec3(0,1,0), yrot);
    
    vec3 sect = plane_intersect(init, cam, vec3(0), vec3(0,0,-1));
    float border = max(abs(sect.x),abs(sect.y));
    if ((border > 1. && init.z < 0.) || cam.z < 0.) {
        fragColor = vec4(smoothstep(-.5,.5,sin(exp(-border)*200.))*.05+.1);
        return;
    }
    vec3 f = lightfield(sect.xy, cam);


    // Output to screen
    fragColor = vec4(f, 1.);
}