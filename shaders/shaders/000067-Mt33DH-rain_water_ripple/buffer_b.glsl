// Buf B (buffer) — rain water ripple by zguerrero
// https://www.shadertoy.com/view/Mt33DH

//Fluid Effect Buffer, use normals generated in bufferA to simulate some fake fluid diffusion effect

float sampleDistance = 10.0;
float diffusion = -1.0;
float turbulence = 0.3;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord.xy/iResolution.xy);
    
    vec4 baseColor = texture(iChannel0, uv)*2.0-1.0;
    
    vec2 sDist = sampleDistance/iResolution.xy;
    
    vec4 newColor = texture(iChannel1, uv);
    vec2 turb = (texture(iChannel3, uv).xy*2.0-1.0)*turbulence;

    vec4 newColor1 = texture(iChannel1, uv + vec2(1.0,0.0)*sDist);
    vec4 newColor2 = texture(iChannel1, uv + vec2(-1.0,0.0)*sDist);
    vec4 newColor3 = texture(iChannel1, uv + vec2(0.0,1.0)*sDist);
    vec4 newColor4 = texture(iChannel1, uv + vec2(0.0,-1.0)*sDist);
    
    vec4 newColor5 = texture(iChannel1, uv + vec2(1.0,1.0)*sDist);
    vec4 newColor6 = texture(iChannel1, uv + vec2(-1.0,1.0)*sDist);
    vec4 newColor7 = texture(iChannel1, uv + vec2(1.0,-1.0)*sDist);
    vec4 newColor8 = texture(iChannel1, uv + vec2(-1.0,-1.0)*sDist);
     
    vec2 t = newColor1.xy * 2.0 - 1.0;
    t += newColor2.xy * 2.0 - 1.0;
    t += newColor3.xy * 2.0 - 1.0;
    t += newColor4.xy * 2.0 - 1.0;
    
    t += newColor5.xy * 2.0 - 1.0;
    t += newColor6.xy * 2.0 - 1.0;
    t += newColor7.xy * 2.0 - 1.0;
    t += newColor8.xy * 2.0 - 1.0;
    
    t /= 8.0;

    vec2 dir = vec2(t+turb)*diffusion*iTimeDelta;
    
    vec4 res = texture(iChannel1, uv + dir);
    
    baseColor = baseColor*0.5+0.5;
    
    if(iFrame < 10 || texture(iChannel2, vec2(32.5/256.0, 0.5) ).x > 0.5)
    {
    	fragColor =  baseColor;
    }
    else
    {
    	fragColor = mix(res, baseColor, baseColor.a);
    }
}