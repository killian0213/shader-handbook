// Image (image) — Towers of Life by Polygon
// https://www.shadertoy.com/view/MsXfRH

/* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* 

	Towers of Life  -  By Polygon

	I'm really happy to finally have this in a presentable state! I would say it's my most
	clever and complex toy yet (not sayimg much, I know, but someday I'll get there.)

	It's based off of this really cool video:  https://www.youtube.com/watch?v=iiEQg-SHY1g


	*****************************************************************************
	*   If it reaches a resting state, press ENTER to reset it.					*
	*																			*
	*   You can move the camera with the mouse.									*
	*																			*
	*   Drag the mouse to the top of the screen to see a regular 2d rendering.	*
	*****************************************************************************


	Right now the game wraps around - if a cell is on the edge of the game board, it will
	wrap around to the other side of the board while checking for living cells. I might
	add an option to disable this in the future.

/* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /* /*/



//Width and length of rendered area. If you change them, I recommend you also change them in Buf A.
#define width 64
#define height 64

//Change this to 1 if you want it to go on forever, rather than be confined in a box.
#define REPEAT 0

//Distance of 224 ensures that nothing will be missed if the width and height are both 64.
//To ensure nothing will be missed, set DISTANCE to width + height + 96. Anything bigger than that will have no improvement.
#define DISTANCE 224

#define FOV 100.0

//Don't mess with these.
#define pi 3.14159265
#define d2r 0.0174533

//Un-comment the next line for a smoother look but lower framerate.
// #define ANTIALIAS

bool check(vec3 pos);
void render (vec2 i, inout vec4 o);

void mainImage( out vec4 fragColor, in vec2 fragCoord) {
    
    #ifdef ANTIALIAS
    vec4 buf;
    render(fragCoord + vec2(.25, .25), buf);
    fragColor += buf;
    render(fragCoord + vec2(-.25, .25), buf);
    fragColor += buf;
    render(fragCoord + vec2(-.25, -.25), buf);
    fragColor += buf;
    render(fragCoord + vec2(.25, -.25), buf);
    fragColor += buf;
    fragColor /= 4.;
    
    #else
    render(fragCoord, fragColor);
    
    #endif
}

void render(vec2 i, inout vec4 o) {
    vec2 uv = i.xy / iResolution.xy;
    vec2 uvM = iMouse.xy / iResolution.xy;
    
    float maxRes = max(iResolution.x, iResolution.y);
    
    vec2 s = i.xy / maxRes - vec2(0.5 * iResolution.x / maxRes, 0.5 * iResolution.y / maxRes);
    
    vec2 rot = vec2(iTime / 3. + pi,
               0.6 + 0.75 * sin(iTime / 4.));
    vec3 pos = vec3(float(width) * sin(iTime / 3.) * cos(rot.y) + float(width) / 2.,
               -0.707 * float(width) * sin(rot.y),
               float(height) * cos(iTime / 3.) * cos(rot.y) + float(height) / 2.);
    
    if (iMouse.z > 0.0) {
        rot = vec2(6.5 * (uvM.x - .5),
               -pi / 6. + (pi / 2. + pi / 6.) * min(uvM.y / .8, 1.));
        rot.x *= smoothstep(.95, .8, uvM.y * (0.5 + 0.5 * sign(iMouse.z)));
    	pos = vec3(float(width) * -sin(rot.x) * cos(rot.y) + float(width) / 2.,
               -1.0 / (tan(d2r * FOV / 2.)) * max(float(height) * iResolution.x / iResolution.y, float(width)) / 2.0 * sin(rot.y),
               float(height) * -cos(rot.x) * cos(rot.y) + float(height) / 2.);
    }
    
    //pos.y += float(texelFetch(iChannel1, ivec2(0), 0).y != 1.0) *
    //    texelFetch(iChannel1, ivec2(0), 0).z * (texelFetch(iChannel1, ivec2(0), 0).x - iTime + texelFetch(iChannel1, ivec2(0), 0).w)
    //    * smoothstep(.95, .8, uvM.y * (0.5 + 0.5 * sign(iMouse.z)));
    
    //Direction of ray
    vec3 d = vec3(2.0 * s.x * tan(d2r * FOV / 2.0), -2.0 * s.y * tan(d2r * FOV / 2.0), 1.0);
    d = normalize(d);
    
    //Rotations of screen
    d = vec3(d.x, d.y * cos(rot.y) + d.z * sin(rot.y), d.z * cos(rot.y) - d.y * sin(rot.y));
    d = vec3(d.x * cos(rot.x) + d.z * sin(rot.x), d.y, d.z * cos(rot.x) - d.x * sin(rot.x));
    
    
    //0 = x, 1 = y, 2 = z
    int directionHit;
    
    vec4 sky = vec4(0.5 - 0.5 * sin(d.y), 0.7 - 0.3 * sin(d.y),1.0,0.0);
    o = sky - smoothstep(.8, .95, uvM.y * (0.5 + 0.5 * sign(iMouse.z)));
    
    #if REPEAT == 0
    vec3 bounderies = vec3(width, 96., height) * (0.5 - 0.5 * sign(d));
    vec3 t = (bounderies - pos) / d;
    
    vec3 mask = vec3(greaterThanEqual(t.xyz, max(t.yzx, t.zxy)));
    vec3 nextPlane = (1. - mask) * (floor(pos + d * dot(t, mask)) + 0.5 + 0.5 * sign(d))   +   mask * bounderies;
    #else
    vec3 nextPlane;
    if (pos.y > 0.)
        nextPlane = floor(pos) + 0.5 + 0.5 * sign(d);
    else {
        float t = -pos.y / d.y;
        if (t < 0.)
            return;
        nextPlane = floor(pos + d * t) + .5 + .5 * sign(d);
        nextPlane.y = 0.;
    }
    #endif
    
    
    
    
    for (int j = 0; j < DISTANCE; j++) {
        
        vec3 distToNext;
        distToNext = (nextPlane - pos) / d;
        
        vec3 mask = vec3(lessThanEqual(distToNext.xyz, min(distToNext.yzx, distToNext.zxy)));
        

        nextPlane += sign(d)*mask;
        directionHit = int(dot(mask,vec3(0.0,1.0,2.0)));
        
        #if REPEAT == 0
        if (nextPlane.x > float(width) || nextPlane.x < 0.0
           || nextPlane.y > 96. || nextPlane.y < 0.0
           || nextPlane.z > float(height) || nextPlane.z < 0.0)
            break;
        #else
        if (nextPlane.y > 96. || nextPlane.y < 0.)
            break;
        #endif
        
        #if REPEAT == 0
        if (check((nextPlane - 0.5 - 0.5 * sign(d)).xzy)) {
        #else
        if (check(vec3(mod((nextPlane - 0.5 - 0.5 * sign(d)).xz, vec2(width, height)), (nextPlane - 0.5 - 0.5 * sign(d)).y ))) {
        #endif
            vec3 endPos = pos + d * distToNext;
            
            o = vec4(1.0,0.2,1.0,1.0) * 0.8 + dot(mask, vec3(0.13333333, 0.2, 0.06666666)) * dot(sign(d),mask);

            float dist = distance(pos, endPos);
            o.xyz /= (dist * dist / float(width) / float(height) + 1.0);
            
            o = (sky * max(0., endPos.y - 48.) + o * (48. - max(0., endPos.y - 48.))) / 48.;
            
            #if REPEAT == 0
            o -= smoothstep(.8, .95, uvM.y * (0.5 + 0.5 * sign(iMouse.z)));
            
            if (endPos.y == 0.0 && directionHit == 1) {
                o = vec4(1., 0.6, 1., 1.) + vec4(smoothstep(.8, .95, uvM.y * (0.5 + 0.5 * sign(iMouse.z))));
            }
            
            #else
            float multiplier = ((endPos.x - pos.x) * (endPos.x - pos.x) + (endPos.z - pos.z) * (endPos.z - pos.z)) / 4. / float(width + height) / float(width + height);
            o = o * (1. - min(multiplier, 1.)) + sky * min(multiplier, 1.);
            o -= smoothstep(.8, .95, uvM.y * (0.5 + 0.5 * sign(iMouse.z)));
            
            if (endPos.y == 0.0 && directionHit == 1) {
                o = vec4(1., 0.6, 1., 1.) * (1. - min(multiplier, 1.)) + sky * min(multiplier, 1.) + vec4(smoothstep(.8, .95, uvM.y * (0.5 + 0.5 * sign(iMouse.z))));
            }
            #endif
            
        	break;
     	}
    }
}


bool check(vec3 pos) {
    int b = 1 << (int(pos.z) % 24);
    vec4 mask = vec4(lessThan(pos.zzz, vec3(24.,48.,72.)),1.0);
    mask.yzw -= mask.xyz;
    int xy = int(dot(mask,texelFetch(iChannel0, ivec2(pos.xy),0)));
    
    return ((xy & b) == b);
}
