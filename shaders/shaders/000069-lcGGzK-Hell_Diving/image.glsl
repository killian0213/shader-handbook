// Image (image) — Hell Diving by leon
// https://www.shadertoy.com/view/lcGGzK


// alternative of Cloud Diving
// https://www.shadertoy.com/view/lcVGzz

float gyroid (vec3 p) { return dot(cos(p),sin(p.yzx)); }

float fbm(vec3 p)
{
    float result = 0.;
    float a = .5;
    for (float i = 0.; i < 9.; ++i)
    {
        p.z += (result+iTime)*.1;
        result += abs(gyroid(p/a)*a);
        a /= 1.5;
    }
    return result;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.*fragCoord-iResolution.xy)/iResolution.y;
    vec3 ray = normalize(vec3(uv,.5));
    vec3 blu = texture(iChannel0, fragCoord/1024.).rgb;
    
    vec3 e = vec3(.1*blu.y*vec2(iResolution.x/iResolution.y), 0.);
    #define T(u) fbm(ray+u)
    vec3 normal = normalize(T(0.)-vec3(T(e.xzz),T(e.zyz),1.));
    vec3 color = 0.2 + 1. * cos(vec3(1,2,3)*5.5 + normal.y);

    fragColor = vec4(color,1.0);
}