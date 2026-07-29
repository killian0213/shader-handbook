// Image (image) — Luminous Darkly Cloud by leon
// https://www.shadertoy.com/view/NsVBzt


// Luminous Darkly Cloud
//
// - inadequat volumetric rendering
// - incorrect ambien occlusion
// - overloading gyroid fbm noise
// - fake lightning
// - random point of view
//
// "but with the right numbers, it looks nice!"

// globals
const vec3 cloudColor = vec3(0.702,0.776,1.000);
const vec3 lightColor = vec3(1.000,0.812,0.400);
float glow, cycle, noise, columns, index;
vec3 target;
bool flash;

// signed distance function
float map(vec3 p)
{
    noise = fbm(p+vec3(0,0,iTime*.2));
    
    // cloud
    float dist = length(p*vec3(1,2,1))-1.;
    dist -= noise*.5;
    dist *= .3;
    
    if (flash) {
        // mouse control
        if (iMouse.z > 0.5) {
            p.yz *= rot(1.5);
            p.xy *= rot(-target.x*2.);
            p.yz *= rot(target.y*2.);
        }

        // lightning
        float fade = smoothstep(3.,0.,p.y);
        p -= fbm(p+cycle)*.3*fade;
        float c = pModPolar(p.xz, columns);
        p.x += .5*min(0.,max(-p.y,0.)-2.);
        float shape = max(p.y+1., length(p.xz)*2.);
        glow += .02/shape;
        dist = min(dist, shape);
    }
    
    return dist;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // salt
    vec3 rng = hash33(vec3(fragCoord, iFrame));
    
    // coordinates
    vec2 uv = (fragCoord-iResolution.xy/2.)/iResolution.y;
    vec3 color = vec3(0);
    vec3 pos = vec3(0,-1,5);
    vec3 ray = lookAt(pos, vec3(0), uv, 1.);
    
    // timeline
    float time = iTime*5.;
    float anim = fract(time);
    index = floor(time);
    float alea = step(.9, hash11(index));
    cycle = index;
    columns = 1.+floor(6.*hash11(index+186.));
    glow = 0.;
    flash = alea > .01;
    
    // mouse interaction
    if (iMouse.z > 0.) {
        vec2 mouse = (iMouse.xy-iResolution.xy/2.)/iResolution.y;
        target = vec3(floor(mouse*10.)/10.,0);
        cycle = hash12(iMouse.xy);
        columns = ceil(5.*hash12(iMouse.xy+76.));
        flash = true;
        anim = 0.;
    }
    
    // raymarch
    float maxDist = 10.;
    const float count = 30.;
    float steps = 0.;
    float total = 0.;
    float dense = 0.;
    for (steps = count; steps > 0.; --steps) {
        float dist = map(pos);
        dist *= 0.7+0.3*rng.x;
        // sort of volumetric march
        if (dist < .1) {
            dense += .02;
            dist = .02;
        }
        total += dist;
        if (dense >= 1. || total > maxDist) break;
        pos += ray * dist;
    }
    
    // cloud color
    color = cloudColor;
    #define getAO(dir,k) smoothstep(-k,k,map(pos+dir*k)-map(pos-dir*k))
    color *= .5+.5*getAO(vec3(0,1,0),.5);
    color *= .5+.5*getAO(vec3(0,1,0),2.);
    color *= dense;
    
    // lightning color
    color += lightColor * pow(glow, 2.) * (1.-anim);
    color = clamp(color, 0., 1.);
    
    fragColor = vec4(color, 1);
}