// Image (image) — The door at the end of the world by leon
// https://www.shadertoy.com/view/fdVBRw


// The door at the end of the world
// revisiting Smell of Burning Plastic https://www.shadertoy.com/view/7dyBRm

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec3 blue = texture(iChannel1, fragCoord/1024.).rgb;
    vec3 color = vec3(0);
    
    // masks
    float shade = texture(iChannel0, uv).r;
    float flame = pow(shade, 3.);
    float smoke = pow(shade, .5);
    float height = flame;
    
    // normal
    float range = 30.*blue.x;
    vec3 unit = vec3(range/iResolution.xy,0);
    vec3 normal = normalize(vec3(
        TEX(uv + unit.xz)-TEX(uv - unit.xz),
        TEX(uv - unit.zy)-TEX(uv + unit.zy),
        height));
        
    // lighting
    vec3 tint = .5+.5*cos(vec3(1,2,3)-flame*5.-4.);
    vec3 dir = normalize(vec3(0,-.5,0.5));
    float light = dot(normal, dir)*.5+.5;
    light = pow(light,.5);
    light *= (uv.y+.5); 
    color += tint * flame;
    color += vec3(.5) * light;
    color *= smoke;
    color -= .1*blue.x;
    color += smoothstep(.1,.0,1.-shade);
    
    // show layers
    if (iMouse.z > 0.5) {
        if (iMouse.x < 20.) {
            if (uv.y < .25) {
                color = vec3(shade);
            } else if (uv.y < .5) {
                color = normal;
            } else if (uv.y < .75) {
                color = tint;
            } else {
                color = vec3(.5)*light;
            }
        }
    }
    
    fragColor = vec4(color,1.0);
}