// Buf B (buffer) — volumetric fractal pathtrace by public_int_i
// https://www.shadertoy.com/view/Xtc3RS

//Ethan Alexander Shulman 2016

//camera move and look



#define uv (.5/iResolution.xy)
#define camerarange 256.
#define pi 3.1415926
#define pi2 (pi*2.0)


#define mouse_sensitivity 0.025 * 60.0
#define movement_sensitivity 0.2 * 60.0



float encodeRot(vec2 r) {
    return fract(r.x/pi2)+floor(.5+fract(r.y/pi2)*2048.);
}
vec2 decodeRot(float r) {
    return vec2(r-floor(r),
                floor(r)/2048.0)*pi2;
}


vec2 rot(in vec2 v, in float ang) {
    float si = sin(ang);
    float co = cos(ang);
    return v*mat2(si,co,-co,si);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if (int(floor(fragCoord.x)+floor(fragCoord.y)) > 0) return;
    
    if (iFrame < 10) {
     	//set default camera
        vec3 camPos = vec3(60., -5., 20.),
             camRot = vec3(3.5, 3.14/3.0, 0.0);
        
        fragColor = vec4(camPos+camerarange, encodeRot(mod(camRot.xy,pi2)));
        return;
    }
        
   	vec4 samp = texture(iChannel0, uv);
    vec3 camPos = samp.xyz,
             camRot = decodeRot(samp.w).xyy;
    
    //movement
    float movementA = texture(iChannel1, vec2(38.5, 25.5)/255.).x-
                                 texture(iChannel1, vec2(40.5, 25.5)/255.).x;
    if (movementA != 0.) {
        vec3 rdB = vec3(0.,0.,1.);    
        rdB.yz = rot(rdB.yz,camRot.y);
        rdB.xz = rot(rdB.xz,camRot.x);
    	camPos.xyz += movementA*rdB*iTimeDelta*movement_sensitivity;
    }
    float movementB = texture(iChannel1, vec2(37.5, 25.5)/255.).x-
                      texture(iChannel1, vec2(39.5, 25.5)/255.).x;
    if (movementB != 0.) {
         vec3 rdB = vec3(1.,0.,0.);    
         rdB.yz = rot(rdB.yz,camRot.y);
         rdB.xz = rot(rdB.xz,camRot.x);
         camPos.xyz += movementB*rdB*iTimeDelta*movement_sensitivity;
    }
                
    //rotation
    if (iMouse.w > 0.) {
    	vec2 muv = (iMouse.xy/iResolution.xy)-.5;
        camRot.xy += muv*vec2(1.,-1.)*mouse_sensitivity*iTimeDelta;
    }

    fragColor = vec4(max(camPos, 0.0), encodeRot(mod(camRot.xy,pi2)));
}