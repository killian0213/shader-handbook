// Buffer A (buffer) — Sea the Night by crocidb
// https://www.shadertoy.com/view/ssG3Wt

#define AA 1

#define ZERO (min(iFrame,0))
#define MAX_STEPS			200
#define MAX_DIST			25.0
#define SURFACE_DIST		0.001

#define Time iTime
#define clamp01(x) max(min(x, 1.0), 0.0)

vec3 ro;

vec2 map(vec3 p, bool complete)
{
    vec2 v = vec2(MAX_DIST, 0.0);
    
    // water
    float final = getwaves(p.xz * .35, 20, iTime * .5) * (getwaves(p.xz * .15 + vec2(2.2, 2.2), 3, iTime * .5) * 1.5 + .4) * 1.05;
    float f = dot(p, vec3(0.0, 1.0, 0.0)) - final;
    v = vec2(f, 1.0);
    
    return v;
}

vec3 calcNormal(vec3 p)
{
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+0.0001*e, true).x;
    }
    return normalize(n);
}

vec2 rayMarch(vec3 ro, vec3 rd)
{
    float t = 0.0;
    vec3 p;
    vec2 obj;
    for (int i = 0; i < MAX_STEPS; i++)
    {
        p = ro + t * rd;
       	
        obj = map(p, true);
        
        if (abs(obj.x) < SURFACE_DIST || abs(t) > MAX_DIST) break;
        
        t += obj.x;
    }
    
    obj.x = t;
    return obj;
}

// Lighting
float ambientOcclusion(vec3 p, vec3 n)
{
	float stepSize = 0.0026f;
	float t = stepSize;
	float oc = 0.0f;
	for(int i = 0; i < 10; ++i)
	{
		vec2 obj = map(p + n * t, true);
		oc += t - obj.x;
		t += pow(float(i), 1.85) * stepSize;
	}

	return 1.0 - clamp(oc * 0.5, 0.0, 1.0);
}

float getVisibility(vec3 p0, vec3 p1, float k)
{
	vec3 rd = normalize(p1 - p0);
	float t = 10.0f * SURFACE_DIST;
	float maxt = length(p1 - p0);
	float f = 1.0f;
	while(t < maxt || t < MAX_DIST)
	{
		vec2 o = map(p0 + rd * t, false);

		if(o.x < SURFACE_DIST)
			return 0.0f;

		f = min(f, k * o.x / t);

		t += o.x;
	}

	return f;
}

// Renderer
vec4 render(vec2 obj, vec3 p, vec3 rd, vec2 uv)
{
    vec3 col;
    
    vec3 normal = calcNormal(p);
    
    const vec3 background_color = vec3(0.0, 0.01, 0.02);
    vec3 background = background_color;
    
    vec2 pos = uv - vec2(0.0, 0.2) - vec2(0.0, 0.2) * sin(iTime * 0.5) * 0.1;
    background += pow(clamp01(1.0 - length(pos * 1.5)), 1.9) * background * 20.0;
    background += pow(clamp01(1.0 - length(pos * 6.5)), 3.9) * background * 80.0;
    
    float n = fbm_2(vec3(pos * 52.0 + iTime * 0.1, 1.0)) * 1.8;
    n = smoothstep(0.72, 0.78, n) * 8.5;
    
    background += n * background_color;
    float c = 1.0;
    
    if (obj.x >= MAX_DIST)
    {
        col = background;
    }
    else
    {
        vec3 albedo = vec3(0.0, 0.0, 0.0);
        
        float a = pow(1.0 - clamp(dot(-rd, normal), 0.0, 1.0), 2.6);
        float m = pow(length(ro - p) * 0.2, 1.4) * 0.8;

        c = pow(clamp01(1.0 - length((uv - vec2(0.0, -0.4)) * .4)), 5.0) * 3.0;

        float diff_mask = a * m * c;
        float ambient_mask = a * m + .06;
        albedo = vec3(0.0, 0.044, 0.09) * 10.0;
        float spec_power = 80.0;
        float spec_mask = 6.7 * m;
        
        // Moon Light
        #if 1
        {
            const vec3 light_pos = vec3(-0.0, 40.0, 100.4);
            const vec3 light_col = vec3(0.2, 0.2, 0.2);
			vec3 refd = reflect(rd, normal);
            vec3 light_dir = normalize(light_pos - p);
            
            float diffuse = dot(light_dir, normal);
            float visibility = getVisibility(p, light_pos, 10.0);
        	float spec = pow(max(0.0, dot(refd, light_dir)), spec_power);

            col += diff_mask * diffuse * albedo * visibility * light_col * 1.86;
            col += spec * (light_col * albedo) * spec_mask * visibility * c;
        }
        #endif
        
        // Fill Light
        #if 1
        {
            const vec3 light_pos = vec3(0.0, 100.0, 0.0);
            const vec3 light_col = vec3(0.0, 0.4, 0.2);
			vec3 refd = reflect(rd, normal);
            vec3 light_dir = normalize(light_pos - p);
            
            float diffuse = dot(light_dir, normal);
            float visibility = getVisibility(p, light_pos, 10.0);
        	float spec = pow(max(0.0, dot(refd, light_dir)), spec_power);

            col += diff_mask * diffuse * albedo * visibility * light_col * .1;
            col += spec * (light_col * albedo) * spec_mask * visibility * .03;
        }
        #endif
        
        
        // Ambient light
        #if 1
        col += albedo * 0.2 * ambient_mask;
        #endif
    }
    
    return vec4(col, obj.x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    float v = 1.7 + sin(iTime * 0.5) * 0.5;
    const vec3 ta = vec3(0.0, 0.0, 20.0);
    vec3 ro = vec3(
        0.0,
        v,
        0.0
    );

    vec4 tot = vec4(0.0);
#if AA>1
    for(int m=ZERO; m<AA; m++)
    for(int n=ZERO; n<AA; n++)
    {
        vec2 o = vec2(float(m), float(n)) / float(AA) - 0.5;
        vec2 uv = (2.0 * (fragCoord + o) - iResolution.xy) / iResolution.y;
#else    
    	vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
#endif       
        // Ray direction
        vec3 ww = normalize(ta - ro);
        vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
        vec3 vv = normalize(cross(uu, ww));
        
        vec3 rd = normalize(uv.x * uu + uv.y * vv + 2.3 * ww);
        
        // render	
        vec2 obj = rayMarch(ro, rd);
        vec3 p = ro + obj.x * rd;
    
   		vec4 col = render(obj, p, rd, uv);
        
        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif

    fragColor = vec4(tot);
}