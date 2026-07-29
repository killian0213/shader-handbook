// Image (image) — Temporal Resolve Pathtracer 3 by granito
// https://www.shadertoy.com/view/4tVSDm

lowp vec3 ACESFilm( vec3 x )
{
    x *= 0.6; 
    lowp float a = 2.51;
    lowp float b = 0.03;
    lowp float c = 2.43;
    lowp float d = 0.59;
    lowp float e = 0.14;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
}

float grayscale(vec3 image) {
    return dot(image, vec3(0.3, 0.59, 0.11));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	lowp vec2 uv = fragCoord.xy / iResolution.xy;

    lowp vec3 result = texture(iChannel0,uv).rgb;    
    lowp vec3 aframe = texture(iChannel1,uv).rgb;
    
    if (iMouse.z > 0.5) result = aframe;

    result = pow( result, vec3(1.25) );
    
    result = ACESFilm(result);

	fragColor = vec4(result,1.);
}

