// Buffer A (buffer) — Turbo Rainbow Dissolver by leon
// https://www.shadertoy.com/view/NdVfRh


// fractal brownian motion https://thebookofshaders.com/13/
// with a "abs(sin(value))" twist 
vec3 fbm (vec3 p)
{
    vec3 result = vec3(.0);
    float a = .5;
    for (float i = 0.; i < 3.; ++i) {
        result += abs(sin(texture(iChannel1, p/a).xyz*6.))*a;
        a /= 2.;
    }
    return result;
}

// signed distance function
float map(vec3 p)
{
    float dist = 100.;
    
    // timing
    float time = iTime;
    float anim = fract(time);
    float index = floor(time);
    
    // noise animation
    float scale = .1-anim*.05;
    vec3 seed = p * scale + index * .12344;
    vec3 noise = fbm(seed);
    
    // shapes and distortions
    float size = .5*pow(anim,.2);
    float type = mod(index, 3.);
    dist = type > 1.5 ? sdTorus(p, vec2(size, .1)) :
           type > .5 ? sdBox(p,vec3(size*.7)) :
           length(p)-size;
    dist -= anim * noise.x * .2;
    dist += pow(anim, 3.) * noise.y;
    
    // scale field when highly distorted to avoid artefacts
    return dist * (1.-anim*.7);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-iResolution.xy/2.)/iResolution.y;
    
    // background
    vec3 color = vec3(.5)*smoothstep(2.,.5,length(uv));
    
    // coordinates
    vec3 pos = vec3(0,0,-1.5);
    pos.xz *= rot(iTime*.1);
    pos.zy *= rot(sin(iTime*.2));
    vec3 ray = lookAt(pos, vec3(0), uv, 1.5);
    
    // noise
    vec3 blue = texture(iChannel0, fragCoord/1024.).xyz;
    
    // raymarch
    const float count = 30.;
    float steps = 0.;
    float total = 0.;
    for (steps = count; steps > 0.; --steps) {
        float dist = map(pos);
        if (dist < total/iResolution.y || total > 3.) break;
        dist *= 0.9+0.1*blue.z;
        pos += ray * dist;
        total += dist;
    }
    
    // coloring
    float shade = steps/count;
    if (shade > .001 && total < 3.) {
    
        // NuSan https://www.shadertoy.com/view/3sBGzV
        vec2 noff = vec2(.02,0);
        vec3 normal = normalize(map(pos)-vec3(map(pos-noff.xyy), map(pos-noff.yxy), map(pos-noff.yyx)));
        
        color = vec3(.1);
        float light = dot(reflect(ray, normal), vec3(0,1,0))*.5+.5;
        float rainbow = dot(normal, -normalize(pos))*.5+.5;
        color += vec3(0.5)*pow(light, 4.5);
        
        // Inigo Quilez color palette https://iquilezles.org/articles/palettes/
        color += (.5+.5*cos(vec3(0.,.3,.6)*6.+uv.y*3.+iTime))*pow(rainbow,4.);
        color *= pow(shade,.5);
    }
    
    fragColor = vec4(color, 1);
}