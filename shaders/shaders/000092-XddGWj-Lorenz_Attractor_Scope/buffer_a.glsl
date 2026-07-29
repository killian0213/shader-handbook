// Buf A (buffer) — Lorenz Attractor Scope by Flyguy
// https://www.shadertoy.com/view/XddGWj


//https://en.wikipedia.org/wiki/Lorenz_system

//Settings
#define STEPS 96.0
#define VIEW_SCALE 0.015

#define SPEED 0.2
#define INTENSITY 0.1
#define FADE 0.99
#define FOCUS 1.

#define MODE xz

//System Parameters
float O = 10.0;
float P = 28.0;
float B = 8.0/3.0;

//Initial Position
vec3 start = vec3(0.1,0.001,0);

//Calculate the next position 
vec3 Integrate(vec3 cur, float dt)
{
	vec3 next = vec3(0);
    
    next.x = O * (cur.y - cur.x);
    next.y = cur.x * (P - cur.z) - cur.y;
    next.z = cur.x*cur.y - B*cur.z;
    
    return cur + next * dt;
}

//Distance to a line segment,
float dfLine(vec2 start, vec2 end, vec2 uv)
{   
	vec2 line = end - start;
	float frac = dot(uv - start,line) / dot(line,line);
	return distance(start + line * clamp(frac, 0.0, 1.0), uv);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
    vec2 res = iResolution.xy / iResolution.y;
    vec2 uv = fragCoord / iResolution.y;
    uv -= res/2.0;
    uv.y += 0.375;
    float d = 1e6;
    
    vec3 last = texture(iChannel0, vec2(0,0)).xyz;
    vec3 next = vec3(0);
    
    for(float i = 0.0;i < STEPS;i++)
    {
    	next = Integrate(last, 0.016 * SPEED);
        
        d = min(d, dfLine(last.MODE * VIEW_SCALE, next.MODE * VIEW_SCALE, uv));
         
        last = next;
    }
    
    float c = (INTENSITY / SPEED) * smoothstep(FOCUS / iResolution.y, 0.0, d);
	
	c += (INTENSITY/8.5) * exp(-1000.0 * d*d);
    
    //pixel (0,0) saves the current position.
    if(floor(fragCoord) == vec2(0,0))
    {
        if(iFrame == 0) //Setup initial conditions.
    	{
    		fragColor = vec4(start, 0);
    	}
        else //Save current position.
        {
    		fragColor = vec4(next, 0);
        }
    }
    else
    {
        vec3 lc = texture(iChannel0, fragCoord / iResolution.xy).rgb;
        fragColor = vec4(vec3(c) + lc * FADE, 0);
    }
}