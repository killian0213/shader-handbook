// Image (image) — Reintegration visualization by michael0884
// https://www.shadertoy.com/view/WlSfWD

// Fork of "Paint streams" by michael0884. https://shadertoy.com/view/WtfyDj
// 2020-08-31 20:06:54

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 mixN(vec3 a, vec3 b, float k)
{
    return sqrt(mix(a*a, b*b, clamp(k,0.,1.)));
}

vec4 V(vec2 p)
{
    return pixel(ch1, p);
}

void mainImage( out vec4 col, in vec2 pos )
{
	R = iResolution.xy; time = iTime;
    pos = R*0.495 + pos*0.03; //zoom in
    ivec2 p = ivec2(pos + 0.5);
    
    float rho = 0.; float varr = 0.;
    range(i, -1, 1) range(j, -1, 1)
    {
        vec2 ij = vec2(i,j);
        vec4 data = texel(ch0, vec2(p) + ij);
        particle P0 = getParticle(data, vec2(p) + ij);
        rho += P0.M.x*smoothstep(0.1, 0.09, distance(pos,P0.X)); 
    	float rad = dif/2.;
        varr += P0.M.x*smoothstep(0.03, 0.01, sdArrow(pos, P0.X, P0.X+20.*P0.V));
        varr += P0.M.x*smoothstep(0.03, 0.01, sdBox(pos - P0.X - P0.V*dt, vec2(rad)));
    }
    
    float sdgrid = sdBox(mod(pos + 0.5, vec2(1.0)), vec2(1.0));
   
    vec3 particles = vec3(0.2)*(rho + varr);
    vec3 cellcol = vec3(1.);
   	vec3 grid = cellcol*smoothstep(0.0, -0.1, sdgrid);
    // Output to screen
    col.xyz = grid - particles;
    col.xyz = col.xyz;
}