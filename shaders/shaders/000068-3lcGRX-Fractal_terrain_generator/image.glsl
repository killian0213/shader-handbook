// Image (image) — Fractal terrain generator by michael0884
// https://www.shadertoy.com/view/3lcGRX

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized centered pixel coordinates 
    vec2 pos = (fragCoord - iResolution.xy*0.5)/max(iResolution.x,iResolution.y);
    
    LOD = 1.5/max(iResolution.x,iResolution.y);
    vec2 angles = vec2(2.*PI, PI)*(iMouse.xy/iResolution.xy - 0.5);

    if(iMouse.z < 1.)
    {
        angles = vec2(PI/5., 0.);
    }
    vec3 ray = getRay(angles, pos);
    vec4 cpos = vec4(iTime*0.8,11.5,iTime,1.);
    vec4 dir = vec4(ray.xzy,0.);
    
   	float de = DE(cpos.xyz);
    
    cpos.y -= de*0.98;
    
    vec3 col = render_ray(cpos, dir, LOD);
    
    // Output to screen
    fragColor = vec4(HDRmapping(col, 0.5),1.0);
}