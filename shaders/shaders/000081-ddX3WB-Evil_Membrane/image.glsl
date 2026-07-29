// Image (image) — Evil Membrane by leon
// https://www.shadertoy.com/view/ddX3WB


// Evil Membrane
// Another gyroid noise with light and color

#define R iResolution.xy
#define N(x,y,z) normalize(vec3(x,y,z))

float gyroid (vec3 seed)
{
    return dot(sin(seed),cos(seed.yzx));
}

float fbm (vec3 seed)
{
    float result = 0., a = .5;
    for (int i = 0; i < 6; ++i)
    {
        // extra spicy twist
        seed.z += result*.5;
        
        // bounce it with abs
        result += abs(gyroid(seed/a))*a;
        
        a /= 2.;
    }
    return result;
}

float noise (vec2 p)
{
    // improvise 3d seed from 2d coordinates
    vec3 seed = vec3(p, length(p) - iTime * .1) * 1.;
    
    // make it slide along the sin wave
    return sin(fbm(seed)*6.+iTime)*.5+.5;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // coordinates
    vec2 p = (2.*fragCoord-R)/R.y;
    
    // noise grayscale
    float shade = noise(p);
    
    // normal gradient
    vec3 normal = normalize(vec3(shade-vec2(noise(p+vec2(.01,0)), noise(p+vec2(0,.01))), .2));
    
    vec3 color = vec3(0.);
    
    // light from above
    color += .5*pow(dot(normal, N(0,1,1))*.5+.5, 10.);
    
    // tinted light
    vec3 tint = .5+.5*cos(vec3(1,2,3)*5.+shade+p.x+normal.y*2.);
    color += tint*.3*pow(dot(normal, N(0,0,1))*.5+.5, 10.);
    
    // pink light from below
    color += .5*vec3(1.000,0.580,0.580)*pow(dot(normal, N(0,-2,1))*.5+.5, 2.);
    
    fragColor = vec4(color*shade, 1);
}