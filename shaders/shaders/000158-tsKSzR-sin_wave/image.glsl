// Image (image) — sin_wave by skaplun
// https://www.shadertoy.com/view/tsKSzR

#define MAX_MARCHING_STEPS 128
#define MIN_FLOAT 1e-6
#define MAX_FLOAT 1e6
#define EPSILON 0.0001

const float PI = acos(-1.);

float heightAtPos(vec3 p){
	float val = cos(clamp(p.x + sin(p.z*.5+iTime) * 3., -PI, PI)) * .5 + .5;
    return pow(abs(val), 4.) * sin(p.z*.5+iTime) * 3.;
}

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }
float world(vec3 p){
    vec3 mp = p;
    float spacing = .2;// + smoothstep(-5., 5., p.z)*.4;
    float v = mod(mp.z, spacing) - spacing * .5;
    return opSubtraction(-p.y + heightAtPos(p), opSubtraction(v + .001, v - .001));
}

float march(vec3 eye, vec3 marchingDirection){
    const float precis = .001;
    float t = 0.0;
	float l = 0.0;
    for(int i=0; i<MAX_MARCHING_STEPS; i++){
	    vec3 p = eye + marchingDirection * t;
        float hit = world(p);
        if(hit < precis) return t;
        t += hit * .25;
    }
    return -1.;
}

vec3 color(vec3 camPos, vec3 rayDir){
    vec3 col = vec3(0.);
    vec3 pos = camPos;
    
    float dis = march(pos, rayDir);
    if(dis >= 0.){
        pos += rayDir * dis;
		float h = heightAtPos(pos);
        col = vec3(smoothstep(.05, 0., distance(pos.y, h - .05)));
    }
    
    return col;
}

vec3 makeClr(vec2 fragCoord){
    vec3 viewDir = rayDirection(60., iResolution.xy, fragCoord);
    vec3 origin = vec3(0., vec2(10.));
    mat4 viewToWorld = viewMatrix(origin, vec3(0.), vec3(0., 1., 0.));
    vec3 dir = (viewToWorld * vec4(viewDir, 1.0)).xyz;
    
    return color(origin, dir);
}

#define AA 1
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    fragColor = vec4(0.);
    for(int y = 0; y < AA; ++y)
        for(int x = 0; x < AA; ++x){
            fragColor.rgb += clamp(makeClr(fragCoord + vec2(x, y) / float(AA)), 0., 1.);
        }
    
    fragColor.rgb /= float(AA * AA);
}