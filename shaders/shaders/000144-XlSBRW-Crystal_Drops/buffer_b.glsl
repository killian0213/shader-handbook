// Buffer B (buffer) — Crystal Drops by spolsh
// https://www.shadertoy.com/view/XlSBRW

// Crystal Drops
// by Michal 'spolsh' Klos 2017

#define R iResolution
#define T iTime
#define F gl_FragCoord

vec3 sharpen()
{ // by NickWest (lslGRr)
    vec2 uv = F.xy/R.xy;
  	vec2 step = 1.0/iResolution.xy;
    float scale = 1.5;
	vec3 texA = texture(iChannel0, uv + vec2(-step.x, -step.y) * scale).rgb;
	vec3 texB = texture(iChannel0, uv + vec2( step.x, -step.y) * scale).rgb;
	vec3 texC = texture(iChannel0, uv + vec2(-step.x,  step.y) * scale).rgb;
	vec3 texD = texture(iChannel0, uv + vec2( step.x,  step.y) * scale).rgb;   
    vec3 around = 0.25 *(texA+texB+texC+texD);
	vec3 center = texture(iChannel0, uv).rgb;
	vec3 col = center +(center-around)*1.0;
    return col;
}

float depthToMask(float d)
{
	d *= 100.0;
    d = abs(d -8.5);
    d = pow(d, 6.0);
    d = clamp(d, 0.0, 1.0);    
    return d;
}

vec2 Hash22(vec2 uv)
{
    float f = uv.x + uv.y * 37.0;
    return fract(cos(f)*vec2(10003.579, 37049.7));
}

vec4 bokeh(vec2 uv, float rad)
{ // based on dof by Jochen "Virgill" Feldkötter, Alcatraz / Rhodium 4k Intro liquid carbon
  // simplyfied version of Dave Hoskins blur
  // now bokeh is not cut within dof mask, added alpha blending based on difference of dof mask samples
    const float GA =2.399; 
	const mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));
	vec4 acc = vec4(texture(iChannel0,uv).rgb, rad);
    float d = rad;
    vec2 pixel=0.0002*vec2(5.*R.y/R.x,7.);
	vec2 angle=vec2(0,rad);
	for (int j=0;j<80;j++)
    {  
        rad += 1./rad;
	    angle*=rot;
        vec2 tap_uv = uv+pixel*(rad-1.)*angle;
        if (abs(tap_uv.y*2.-1.) > 0.743) continue; // fix letterbox artifacts
        vec4 col=texture(iChannel0, tap_uv);
      	acc.rgb = max(acc.rgb,col.rgb);
        acc.a = max(acc.a, abs(d-depthToMask(col.w)));
	}
	return acc;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{      
    vec2 uv = F.xy/R.xy;    
    vec2 v = 2.0*(uv-0.5);
    v.x *= R.x/R.y;
        
    float cas = step(abs(v.y)*2.39,R.x/R.y);
    if (cas<0.1) return;
         
    float d = depthToMask(texture(iChannel0, uv).w);
    // fragColor = vec4(d); return; // uncomment to see dof mask
    
    vec3 sharp = sharpen();   
	vec4 dof = bokeh(uv, d);
    fragColor = vec4(mix(sharp, dof.rgb, dof.a), 1.0);
}