// Buf B (buffer) — Ink Ghost by zguerrero
// https://www.shadertoy.com/view/4t3GDj

float sampleDistance = 30.0;
float diffusion = 1.0;
float turbulence = 0.2;
float fluidify = 0.1;
float attenuate = 0.005;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord.xy/iResolution.xy);
    
    vec4 baseColor = texture(iChannel0, uv);
    
    vec2 sDist = sampleDistance/iResolution.xy;
    
    vec4 newColor = texture(iChannel1, uv);
    vec2 turb = (texture(iChannel3, uv).xy*2.0-1.0);

    vec4 newColor1 = texture(iChannel1, uv + vec2(1.0,0.0)*sDist);
    vec4 newColor2 = texture(iChannel1, uv + vec2(-1.0,0.0)*sDist);
    vec4 newColor3 = texture(iChannel1, uv + vec2(0.0,1.0)*sDist);
    vec4 newColor4 = texture(iChannel1, uv + vec2(0.0,-1.0)*sDist);
    
    vec4 newColor5 = texture(iChannel1, uv + vec2(1.0,1.0)*sDist);
    vec4 newColor6 = texture(iChannel1, uv + vec2(-1.0,1.0)*sDist);
    vec4 newColor7 = texture(iChannel1, uv + vec2(1.0,-1.0)*sDist);
    vec4 newColor8 = texture(iChannel1, uv + vec2(-1.0,-1.0)*sDist);
     
    vec2 t = (newColor1.x+newColor1.y+newColor1.z)/3.0 * vec2(1.0,0.0);
    t += (newColor2.x+newColor2.y+newColor2.z)/3.0 * vec2(-1.0,0.0);
    t += (newColor3.x+newColor3.y+newColor3.z)/3.0 * vec2(0.0,1.0);
    t += (newColor4.x+newColor4.y+newColor4.z)/3.0 * vec2(0.0,-1.0);
    
    t += (newColor5.x+newColor5.y+newColor5.z)/3.0 * vec2(1.0,1.0);
    t += (newColor6.x+newColor6.y+newColor6.z)/3.0 * vec2(-1.0,1.0);
    t += (newColor7.x+newColor7.y+newColor7.z)/3.0 * vec2(1.0,-1.0);
    t += (newColor8.x+newColor8.y+newColor8.z)/3.0 * vec2(-1.0,-1.0);
    
    t /= 8.0;
	vec2 m = iMouse.xy/iResolution.xy;
    vec2 dir = vec2(t+turb*turbulence)*iTimeDelta*diffusion*(m.x*2.0-1.0);
    
    vec4 res = texture(iChannel1, uv + dir);
    
    if(iFrame < 10 || texture(iChannel2, vec2(32.5/256.0, 0.5) ).x > 0.5)
    {
    	fragColor =  baseColor;
    }
    else
    {
    	fragColor = mix(res, baseColor, clamp(baseColor.a*fluidify + attenuate,0.0,1.0));
    }
}