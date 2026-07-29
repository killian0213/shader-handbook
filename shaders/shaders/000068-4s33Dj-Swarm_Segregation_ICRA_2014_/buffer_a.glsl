// Buf A (buffer) — Swarm Segregation (ICRA 2014) by vgs
// https://www.shadertoy.com/view/4s33Dj

/* Simulation Logic */

// If the simulation is too fast/slow, decrease/increase the values of ALPHA and DT
// This happens because the simulation currently depends on the frame rate...
// I'll try to fix this soon...

// ALPHA controls the magnitude of the pairwise force
// dAA relates to the spacing between robots in the same team
// dAB relates to the spacing between robots in different teams
// DT is the delta time of the simulation
// HINT: if you switch the values of dAA and dAB the swarm will aggregate instead of segregate
#define ALPHA 12.5
#define dAA 4.0
#define dAB 7.0
#define DT 0.01


vec2 hash(vec2 p);
vec4 initState(in vec2 id) {    
    vec2 r = 2.0 * hash(id) - 1.0;
    return vec4(10.0 * r, 0.0, 0.0);    
}

vec4 loadState(in vec2 id) {
    vec2 uv = (id + 0.5) / iChannelResolution[0].xy;
    return texture(iChannel0, uv);
}

vec4 updateState(in vec2 id, in int teams) {
    int RPT = 100 / teams;
    
    vec2 u = vec2(0.0);
    vec4 qi = loadState(id);
        
    for (int i = 0; i < 10; ++i) {
    	for (int j = 0; j < 10; ++j) {        	
        
        	vec4 qj = loadState(vec2(i, j));
        	vec2 qij = qi.xy - qj.xy;
        	float mqij = length(qij);
        	float dij = ((10*i+j)/RPT == int(10.0*id.x+id.y)/RPT) ? dAA : dAB;
        
        	if (mqij < 1e-2) continue;
    
        	// Control equation (eq. 2 in the paper)
        	u -= ALPHA * (mqij - dij + 1.0/mqij - dij/(mqij*mqij)) * qij / mqij;
        	u -= qi.zw - qj.zw;        
    	}
	}

    // Simple ODE solver.
    qi.xy += qi.zw * DT + 0.5 * u * DT * DT;
    qi.zw += u * DT;
    return qi;
}

// Hash by Dave Hoskins ( https://www.shadertoy.com/view/4djSRW )
vec2 hash(vec2 p) {
	p  = fract(p * vec2(5.3983, 5.4427));
    p += dot(p.yx, p.xy +  vec2(21.5351, 14.3137));
	return fract(vec2(p.x * p.y * 95.4337, p.x * p.y * 97.597));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{        
    fragCoord = floor(fragCoord);    
    if (fragCoord.x > 10.0 || fragCoord.y > 10.0) discard;
    
    vec4 state = vec4(0.0), data = state;
    
    if (iFrame == 0) {
    	data = vec4(5.0, 0.0, 0.0, 0.0);
    	state = initState(fragCoord);
    } else {
    	data = loadState(vec2(10.0));
   		state = updateState(fragCoord, int(data.x));
    }
        
    float space = texture(iChannel1, vec2(32.5/256.0,0.25)).x;
    if (space > 0.5 && (iTime - data.y) > 0.5) {
      	data.y = iTime;
       	if (data.x == 2.0) data.x = 4.0;
       	else if (data.x == 4.0) data.x = 5.0;
       	else if (data.x == 5.0) data.x = 10.0;
       	else data.x = 2.0;
    }            
    
    fragColor = fragCoord != vec2(10.0) ? state : data;    
}