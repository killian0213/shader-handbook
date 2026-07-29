// Buf C (buffer) — rain water ripple by zguerrero
// https://www.shadertoy.com/view/Mt33DH

//Turbulence Buffer
//Just noise generated from sinus functions

vec2 speed = vec2(5.0,-2.0);
float v = 30.0;
float dist = 0.3;
float random1 = 1.0;
float random2 = 2.0;

float hash(float n)
{
   return fract(sin(dot(vec2(n,n) ,vec2(12.9898,78.233))) * 43758.5453);  
}  

vec2 turbulence(vec2 uv)
{
    vec2 turb;
    turb.x = sin(uv.x);
    turb.y = cos(uv.y);
    
    for(int i = 0; i < 10; i++)
    {
        float ifloat = 1.0 + float(i);
        float ifloat1 = ifloat + random1;
        float ifloat2 = ifloat + random2; 
        
        float r1 = hash(ifloat1)*2.0-1.0;
        float r2 = hash(ifloat2)*2.0-1.0;
        
        vec2 turb2;
        turb2.x = sin(uv.x*(1.0 + r1*v) + turb.y*dist*ifloat + iTime*speed.x*r2);
        turb2.y = cos(uv.y*(1.0 + r1*v) + turb.x*dist*ifloat + iTime*speed.y*r2);
        
        turb.x = mix(turb.x, turb2.x, 0.5);
        turb.y = mix(turb.y, turb2.y, 0.5);
    }
    
    return turb;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float ratio = iResolution.x/iResolution.y;
    vec2 uv = fragCoord.xy/iResolution.xy;
    uv.x *= ratio;
    
    vec4 buff = texture(iChannel0, fragCoord.xy/iResolution.xy)*2.0-1.0;
    vec2 turb = turbulence(uv+buff.xy*0.1)*0.5+0.5;
    
    fragColor = vec4(turb.x, turb.y, 0.0, 0.0);
      
}