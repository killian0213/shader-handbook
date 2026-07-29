// Buffer A (buffer) — The Mountain by banthar
// https://www.shadertoy.com/view/MdlBWH

const float tau = 6.28318530718;

mat4 rotateX(float a) {
    return mat4(
        1,0,0,0,
		0,cos(a),-sin(a),0,
		0,sin(a),cos(a),0,
		0,0,0,1);
}


mat4 rotateY(float a) {
    return mat4(
		cos(a),0,sin(a),0,
		0,1,0,0,
		-sin(a),0,cos(a),0,
		0,0,0,1
    );
}

mat4 rotateZ(float a) {
    return mat4(
		cos(a),-sin(a),0,0,
		sin(a),cos(a),0,0,
		0,0,1,0,
		0,0,0,1
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragCoord -= 0.5;
    if(fragCoord.x < 3.0 ) {
    if(iFrame == 0) {
        if(fragCoord.x == 0.0 ) {
    		fragColor.rgb = vec3(0,0,0);
        } else {
    		fragColor.rg = vec2(0,-1.9);
        }
        return;
    }
        
        vec3 old_pos = texture(iChannel0, vec2(0.5,0)/iChannelResolution[0].xy).xyz;
        vec2 old_rot = texture(iChannel0, vec2(1.5,0)/iChannelResolution[0].xy).xy;
        vec2 old_abs_rot = texture(iChannel0, vec2(2.5,0)/iChannelResolution[0].xy).xy;

        
        vec2 rot;
        if(iMouse.z >= 0.0) {
        	vec2 mouse = 0.25 * tau * (iMouse.xy-abs(iMouse.zw)) / min(iResolution.x,iResolution.y);
            rot = old_abs_rot + mouse * vec2(-1,1);
            rot.y = clamp(rot.y, -0.5*tau, 0.0);
        } else {
            rot = old_rot;
            old_abs_rot = old_rot;
        }

        
	    vec4 v = vec4(
	    	texture(iChannel1, vec2(68.0/255.0,0)).r - texture(iChannel1, vec2(65.0/255.0,0)).r,
	        0,
            texture(iChannel1, vec2(87.0/255.0,0)).r - texture(iChannel1, vec2(83.0/255.0,0)).r,
            0
    	) * 0.1;
        
        vec3 pos = old_pos + (rotateZ(rot.x)*rotateX(rot.y)*v).xyz;

        
        if(fragCoord.x == 0.0 ) {
    		fragColor.rgb = pos;
        } else if(fragCoord.x == 1.0 ) {
    		fragColor.rg = rot;
        } else if(fragCoord.x == 2.0 ) {
    		fragColor.rg = old_abs_rot;
        }
    }
}