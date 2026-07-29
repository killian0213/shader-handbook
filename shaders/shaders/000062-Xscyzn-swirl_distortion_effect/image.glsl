// Image (image) — swirl distortion effect by laserdog
// https://www.shadertoy.com/view/Xscyzn

#define PI 3.14159

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float effectRadius = .5;
    float effectAngle = 2. * PI;
    
    vec2 center = iMouse.xy / iResolution.xy;
    center = center == vec2(0., 0.) ? vec2(.5, .5) : center;
    
    vec2 uv = fragCoord.xy / iResolution.xy - center;
    
    float len = length(uv * vec2(iResolution.x / iResolution.y, 1.));
    float angle = atan(uv.y, uv.x) + effectAngle * smoothstep(effectRadius, 0., len);
    float radius = length(uv);

    fragColor = texture(iChannel0, vec2(radius * cos(angle), radius * sin(angle)) + center);
}