// Image (image) — Primitive Portrait by yx
// https://www.shadertoy.com/view/ts2cWm

mat2 rotate(float a){
    float c=cos(a),s=sin(a);
    return mat2(c,-s,s,c);
}

float sdRect(vec2 p, vec2 r)
{
    p=abs(p)-r;
    return max(p.x,p.y);
}

float sdf(vec2 p)
{
    float d=1e9;
    d=min(d,sdRect(p-vec2(3),vec2(7,1)));
    d=min(d,sdRect(p-vec2(3),vec2(1,7)));
    d=min(d,sdRect(p+vec2(3),vec2(1,7)));
    d=min(d,sdRect(p+vec2(6,3),vec2(4,1)));
    d=min(d,sdRect(p+vec2(9),vec2(1)));
    d=min(d,sdRect(p-vec2(9),vec2(1)));
    return d;
}

void mainImage(out vec4 fragColor, vec2 fragCoord)
{
	vec2 uv=fragCoord.xy/iResolution.xy;
	vec4 tex=texelFetch(iChannel0,ivec2(fragCoord),0);

	// divide by sample-count
	vec3 color=tex.rgb/tex.a;
    
    // each grayscale light is in a separate color channel
    // so I can adjust the balance in post here
    // comment this out for pretty debug colors
    vec3 weights = vec3(1.5,.2,.2);
    weights /= dot(weights,vec3(1));
    color = vec3(dot(color,weights));
    
	// vignette to darken the corners
	uv-=.5;
	color *= 1.-dot(uv,uv)*.8;

    // exposure and tonemap
    color *= 2.5;
    color = 1.-exp(color*-2.);

	// gamma correction
	color = pow(color, vec3(.45));
    
    // raise the black level slightly
    color = color*.98+.02;

    // "final" color
    fragColor = vec4(vec3(color),1);
    
	// set up for logo overlay
    uv.x*=iResolution.x/iResolution.y;
    uv -= vec2(.8888,-.5); // assumes 16:9
    uv *= 720.;
    uv += vec2(20,-20);
	float threshold = abs(dFdx(uv.x)*.5);
	uv+=vec2(8,0);
    uv*=rotate(acos(-1.)*.25);

    // logo overlay
	fragColor.rgb *= smoothstep(-threshold,threshold,sdf(uv))*.2+.8;
}