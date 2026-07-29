// Buf B (buffer) — Ray Marching Demo For Beginner by Trashe725
// https://www.shadertoy.com/view/4dKyRz


// bufA
// vec2(0 ~ 0.5, 0 ~ 0.5)
// 		r : draw map  (check box)
// 		g : draw start (check box)
// 		b : show end pos (check box)
//      a : fixed origin point (check box)

// bufB
// vec2(0.5 ~ 1, 0 ~ 0.5)
//		r : step count
//		g : fixed target point(check box)
//		b : key event
//		a : iMouse.z

// bufC
// vec2(0 ~ 0.5, 0.5 ~ 1)
//      r : key drag flag
//      g : map number
//      b : 
//      a :

// bufD
// vec2(0.5 ~ 1, 0.5 ~ 1)
//      r : origin.x
//      g : origin.y
//      b : target.x
//      a : target.y

#define KEY_DOWN 1
#define KEY_UP 2
#define KEY_HOLD 3
#define KEY_DRAG 4

vec4 bufA;
vec4 bufB;
vec4 bufC;
vec4 bufD;

float asp;

int inbox(vec2 uv, vec2 pos, vec2 range)
{
	if(uv.x > pos.x-range.x && uv.x < pos.x+range.x)
        if(uv.y > pos.y-range.y && uv.y < pos.y+range.y)
            return 1;
    return 0;
}

void keydown_event()
{
	vec2 uv = (-iResolution.xy + 2. * iMouse.xy) / iResolution.y;
    float asp = iResolution.x/iResolution.y;
    
    //draw map check box
    if(inbox(uv, vec2(-asp*0.9, 0.9), vec2(asp*0.0144)) > 0)
    {
    	SET_DRAW_MAP(GET_DRAW_MAP > 0. ? 0.:1.);
    }
    
    //draw start check box
    else if(inbox(uv, vec2(-asp*0.9, 0.78), vec2(asp*0.0144)) > 0)
    {
    	SET_DRAW_START(GET_DRAW_START > 0. ? 0.:1.);
    }
    
    //show target point check box
    else if(inbox(uv, vec2(-asp*0.9, 0.66), vec2(asp*0.0144)) > 0)
    {
    	SET_SHOW_TAR(GET_SHOW_TAR > 0. ? 0.:1.);
    }
    
    //fix origin point check box
    else if(inbox(uv, vec2(-asp*0.9, 0.54), vec2(asp*0.0144)) > 0)
    {
    	FIX_ORI = FIX_ORI > 0. ? 0.:1.;
    }
    
    //fix target point check box
    else if(inbox(uv, vec2(-asp*0.9, 0.42), vec2(asp*0.0144)) > 0)
    {
    	FIX_TAR = FIX_TAR > 0. ? 0.:1.;
    }
    
    //increase step count
    else if(inbox(uv, vec2(-asp*0.9, 0.30), vec2(asp*0.0144)) > 0)
    {
    	SET_STEP_COUNT(clamp(GET_STEP_COUNT+1., MIN_STEP_COUNT, MAX_STEP_COUNT));
    }
    
    //decrease step count
    else if(inbox(uv, vec2(-asp*0.77, 0.30), vec2(asp*0.0144)) > 0)
    {
    	SET_STEP_COUNT(clamp(GET_STEP_COUNT-1., MIN_STEP_COUNT, MAX_STEP_COUNT));
    }
    
    //increase map count
    else if(inbox(uv, vec2(-asp*0.9, 0.18), vec2(asp*0.0144)) > 0)
    {
    	SET_MAP_NUM(clamp(GET_MAP_NUM+1., MIN_MAP_COUNT, MAX_MAP_COUNT));
    }
    
    //decrease map count
    else if(inbox(uv, vec2(-asp*0.77, 0.18), vec2(asp*0.0144)) > 0)
    {
    	SET_MAP_NUM(clamp(GET_MAP_NUM-1., MIN_MAP_COUNT, MAX_MAP_COUNT));
    }
    
    //move point
    else if(!(uv.x < -asp*0.5 && uv.y > 0.1))
    {
        if(!is(FIX_ORI) && !is(FIX_TAR)){
            uv = clamp(uv, vec2(-asp*0.5, -asp), vec2(asp, asp));
            SET_ORIGIN(uv);
            SET_TARGET(uv);
        }
        KEY_DRAG_FLAG = 1.0;
    }
}

void keyup_event()
{
    KEY_DRAG_FLAG = 0.0;
}

void keydrag_event()
{
    vec2 uv = (-iResolution.xy + 2. * iMouse.xy) / iResolution.y;
    if(!is(FIX_ORI) && !is(FIX_TAR))  //drag target
    {
    	SET_TARGET(uv);
    }
	if(is(FIX_ORI) && !is(FIX_TAR))  //drag target
    {
        SET_TARGET(uv);
    }
    else if(!is(FIX_ORI) && is(FIX_TAR))  //drag origin
    {
    	SET_ORIGIN(uv);
    }
}

//key down = 1 , key up = 2 , other = 0
int handle_click(vec4 bufB)
{
	if(P_MOUSE_Z < 0.5 && iMouse.z > 0.5)
        return KEY_DOWN;
    
    if(P_MOUSE_Z > 0.5 && iMouse.z < 0.5)
        return KEY_UP;
    
    if(P_MOUSE_Z > 0.5, iMouse.z > 0.5)
        return KEY_HOLD;
    
    return 0;
}


void initBuffer()
{
	if(iTime < 0.05)
    {
        //buf A
		DRAW_MAP = 0.;
		DRAW_START = 0.;
		SHOW_TAR = 0.;
		FIX_ORI = 0.;

		//buf B
		STEP_COUNT = 0.;
		FIX_TAR = 0.;
		KEY_EVENT = 0.;
		P_MOUSE_Z = 0.;

		//buf C
		KEY_DRAG_FLAG = 0.;
        MAP_NUM = 0.;
        bufC.ba = vec2(0.);

		//buf D
		ORIGIN = vec2(0.);
		TARGET = vec2(0.);
    }
    else
    {
    	// get previous state
    	bufA = texture(iChannel0, vec2(0.0, 0.0));
    	bufB = texture(iChannel0, vec2(1.0, 0.0));
    	bufC = texture(iChannel0, vec2(0.0, 1.0));
    	bufD = texture(iChannel0, vec2(1.0, 1.0));
    }

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    asp = iResolution.x/iResolution.y;
    vec2 uv = (-iResolution.xy + 2. * fragCoord.xy) / iResolution.y;
    
    initBuffer();
    
    //get click event
    int click = handle_click(bufB);
    if(click == KEY_DOWN)
    {
    	keydown_event();
    }
    else if(click == KEY_UP)
    {
    	keyup_event();
    }
    else if(is(KEY_DRAG_FLAG))
    {
    	keydrag_event();
    }
    
    KEY_EVENT = float(click);
    P_MOUSE_Z = iMouse.z;
    
    if(uv.x < 0.0 && uv.y < 0.0)
    	fragColor = bufA;
    else if(uv.x > 0.0 && uv.y < 0.0)
        fragColor = bufB;
    else if(uv.x < 0.0 && uv.y > 0.0)
        fragColor = bufC;
    else
        fragColor = bufD;
}