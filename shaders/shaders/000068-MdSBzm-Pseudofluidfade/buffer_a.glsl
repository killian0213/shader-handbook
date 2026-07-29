// Buf A (buffer) — Pseudofluidfade by noby
// https://www.shadertoy.com/view/MdSBzm

float hash12(vec2 p){
	vec3 p3  = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 9.0);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 x){
    vec2 f = fract(x)*fract(x)*(3.0-2.0*fract(x));
	return mix(mix(hash12(floor(x)),
                   hash12(floor(x)+vec2(1,0)),f.x),
               mix(hash12(floor(x)+vec2(0,1)),
                   hash12(floor(x)+vec2(1)),f.x),f.y);
}

vec4 circle(vec2 uv, vec2 pos, float sz){
    // draw a circle at mouse coordinates
    float s = (3.0+0.0*pow(noise(vec2(iTime*0.5)),2.0))/sz;
    uv += pos+vec2(1.0/s);
    float val = clamp(1.0-length(s*uv-1.0), 0.0, 1.0);
    val = pow(5.0*val, 1.0);
	return vec4(clamp(val, 0.0, 1.0));
}

vec2 hash21(float p){
	vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
	vec2 uv = fragCoord.xy / iResolution.yy;
    float brightness = 1.0;//0.6+0.4*noise(vec2(iTime*2.9));
    fragColor = circle(uv, -vec2(0.888888, 0.35), 1.0)-circle(uv, -vec2(0.888888, 0.35), 0.88);
    //fragColor = texture(iChannel0, uv)*circle(uv, -vec2(0.888888, 0.35))*clamp(1.0, 0.0, 1.0);
}