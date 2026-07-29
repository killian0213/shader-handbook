// Buffer A (buffer) — Aurora Explorer [re] by KylBlz
// https://www.shadertoy.com/view/4dtSzX


#define MAX_ACCELERATION      16.
#define MAX_VELOCITY          4.
#define FRICTION              8.

#define VALUE_VELOCITY        0
#define VALUE_POSITION        1
#define VALUE_ROTATION        2
#define VALUE_MOUSE           3

//half pi
const float pi = 3.1415926,
    		pi_5 = 1.5707963;

const vec2 KEY_W 	 = vec2(87.5 / 256., 0.),
    	   KEY_S 	 = vec2(83.5 / 256., 0.),
    	   KEY_A 	 = vec2(65.5 / 256., 0.),
    	   KEY_D 	 = vec2(68.5 / 256., 0.),
		   KEY_LEFT  = vec2(37.5 / 256., 0.),
		   KEY_UP    = vec2(38.5 / 256., 0.),
		   KEY_RIGHT = vec2(39.5 / 256., 0.),
		   KEY_DOWN  = vec2(40.5 / 256., 0.),
    	   KEY_SHIFT = vec2(16.0 / 256., 0.),
    	   KEY_SPACE = vec2(32.0 / 256., 0.);

const vec4 INIT_POS = vec4(6.5, 1.0, -7., 1.),
    	   INIT_VEL = vec4(0., 0., 0., 1.),
    	   INIT_ROT = vec4(0.15, -0.65, 0., 1.),
    	   INIT_MOU = vec4(0., 0., 0., 1.);

vec3 vRotateY(vec3 p, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec3(c*p.x + s*p.z, p.y, -s*p.x + c*p.z);
}

vec3 getAcceleration() {
    return vec3(
        texture(iChannel1, KEY_D).x - texture(iChannel1, KEY_A).x + texture(iChannel1, KEY_RIGHT).x - texture(iChannel1, KEY_LEFT).x,
        texture(iChannel1, KEY_SPACE).x - texture(iChannel1, KEY_SHIFT).x,
        texture(iChannel1, KEY_W).x - texture(iChannel1, KEY_S).x + texture(iChannel1, KEY_UP).x - texture(iChannel1, KEY_DOWN).x
    );
}

vec4 getValue(int a) {
    vec2 q = vec2(float(a) + 0.5, 0.0) / iResolution.x;
    return texture(iChannel0, q);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    if (fragCoord.y > 1.) discard;
    
    int a = int(fragCoord.x);
    float q = fragCoord.x / iResolution.x;
    vec4 value = texture(iChannel0, vec2(q, 0.));
    
    //set initial values
    if (iFrame == 0) {
        if (a == VALUE_ROTATION) {
            value = INIT_ROT;
        } else if (a == VALUE_MOUSE) {
            value = INIT_MOU;
        } else if (a == VALUE_VELOCITY) {
            value = INIT_VEL;
        } else if (a == VALUE_POSITION) {
            value = INIT_POS;
        }    
    }
    
    if (a == VALUE_ROTATION && iMouse.z > 0.) {
        vec4 mouse = 2.0 * abs(iMouse) / iResolution.y;
        vec4 rot = getValue(VALUE_MOUSE);
        value.y = mouse.x - mouse.z + rot.y;
        value.x = clamp(mouse.y - mouse.w + rot.x, -pi_5, pi_5);
        
    } else if (a == VALUE_MOUSE && iMouse.z < 0.) {
        value = getValue(VALUE_ROTATION);
        
    } else if (a == VALUE_VELOCITY) {
        float rot = getValue(VALUE_ROTATION).y;
        vec3 acc = vRotateY(getAcceleration(), rot);
        value.xyz += acc * MAX_ACCELERATION * iTimeDelta;
        float speed = length(value.xyz);
        //limit speed
        if (speed > MAX_VELOCITY) {
            value.xyz *= MAX_VELOCITY / speed;
        } else if (speed > FRICTION * iTimeDelta) {
            value.xyz *= (speed - FRICTION * iTimeDelta) / speed;
        } else {
            value.xyz = vec3(0.0, 0.0, 0.0);
        }
    } else if (a == VALUE_POSITION) {
        vec3 velocity = getValue(VALUE_VELOCITY).xyz;
        value.xyz += velocity * iTimeDelta;
        //collision detection?
        if (value.y < -10.99) value.y = -10.99;
    }
    
    fragColor = vec4(value);
    return;
}
