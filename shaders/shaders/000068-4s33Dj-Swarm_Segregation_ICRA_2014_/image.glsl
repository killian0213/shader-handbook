// Image (image) — Swarm Segregation (ICRA 2014) by vgs
// https://www.shadertoy.com/view/4s33Dj

// Created by Vinicius Graciano Santos - vgs/2016
// This shader is an implementation of my ICRA 2014 paper:
// "Segregation of Multiple Heterogeneous Units in a Robotic Swarm"

// If you are interested, the paper can be found in these links:
// http://dx.doi.org/10.1109/ICRA.2014.6906993
// http://viniciusgraciano.com/downloads/icra2014-segregation.pdf

// The controller works in 3D too, as you can see in the end of this video:
// https://www.youtube.com/watch?v=tN6yEOUU00I

vec4 loadState(in vec2 id) {
    vec2 uv = (id + 0.5) / iChannelResolution[0].xy;
    return texture(iChannel0, uv);
}

// https://www.shadertoy.com/view/MsS3Wc (by iq)
vec3 hsv2rgb(in vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0);
	rgb = rgb*rgb*(3.0-2.0*rgb);
	return c.z * mix( vec3(1.0), rgb, c.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{       
    // Center the scene around the centroid of the swarm.
    vec2 c = vec2(0.0);
    for (int i = 0; i < 10; ++i)
        for (int j = 0; j < 10; ++j)
        	c += loadState(vec2(i, j)).xy;    
    
    vec2 uv = 6.0 * (-iResolution.xy + 2.0*fragCoord) / iResolution.y + c/100.0;     
    
    // Render the swarm.
    float dist = 1e10; int id = 0;
    for (int i = 0; i < 10; ++i) {
        for (int j = 0; j < 10; ++j) {
       	 	float d = length(uv - loadState(vec2(i, j)).xy);
        	if (d < dist) {dist = d; id = 10*i+j;}
    	}    
    }
    dist = smoothstep(0.1, 0.2, dist);    
    
    // Select a color for each team.    
    int TEAMS = int(loadState(vec2(10.0)).x), RPT = 100 / TEAMS;
    vec3 col = (1.0 - dist) * hsv2rgb(vec3(float(id/RPT)/float(TEAMS), 1.0, 1.0)) + 0.1;
    
    col = smoothstep(0.0, 1.0, col);
    col = pow(col, vec3(0.4545));
	fragColor = vec4(col, 1.0);
}