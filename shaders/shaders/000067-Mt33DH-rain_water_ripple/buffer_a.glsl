// Buf A (buffer) — rain water ripple by zguerrero
// https://www.shadertoy.com/view/Mt33DH

//Generate water ripple and normal

float nsize = 5.0;
float nstrenght = 1.0;
float turbInfluence = 0.025;
float rippleSpeed = 10.0;
float rippleFreq = 20.0;
float size = 0.8;
float dropSpeed = 1.0;
float dropSize = 0.7;
float pi = 3.14159265359;

float hash(float n)
{
   return fract(sin(dot(vec2(n,n) ,vec2(12.9898,78.233))) * 43758.5453);  
} 

float brush(vec2 uv, float tile)
{            
    uv *= tile;
    float mouseRipple;

    if(iMouse.z > 0.5)
    {     
        vec2 mPos = iMouse.xy/iResolution.xy;
        mPos.x *= iResolution.x/iResolution.y; 
		mPos *= tile;
        
        float l = 1.0 - length(uv - mPos);
        
        mouseRipple = smoothstep(size, 1.0, l);
    }
    else
    {
    	mouseRipple = 0.0; 
    }
     
    float dropRipple;
    
    const int iter = 10;
    for (int i = 0; i < iter; i++)
    {
        float ifloat = float(i)+1.0;
        float phase = (ifloat/float(iter))*dropSpeed;
        float t = iTime*dropSpeed + phase;
        float rX = hash(floor(t)+ifloat);
		float rY = hash(floor(t)*0.5+ifloat);
        
        vec2 rPos = vec2(rX,rY)*tile; 
        rPos.x *= iResolution.x/iResolution.y; 
        float rl = 1.0 - length(uv - rPos);
        float fTime = fract(t);
        float rRipple = sin(rl*rippleFreq + fTime*rippleSpeed)*0.5+0.5;
        float rB = smoothstep((1.0 - fTime)*dropSize, 1.0, rl);
        dropRipple += rB*rRipple*(1.0 - fTime);
    }
    
	return dropRipple + mouseRipple;
}
    
vec3 calculateNormals(vec2 uv, float tile)
{
    float offsetX = nsize/iResolution.x;
    float offsetY = nsize/iResolution.y;
	vec2 ovX = vec2(0.0, offsetX);
	vec2 ovY = vec2(0.0, offsetY);
    
	float X = (brush(uv - ovX.yx, tile) - brush(uv + ovX.yx, tile)) * nstrenght;
    float Y = (brush(uv - ovY.xy, tile) - brush(uv + ovY.xy, tile)) * nstrenght;
    float Z = brush(uv, tile);
    
	return vec3(X,Y,Z);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float ratio = iResolution.x/iResolution.y;
   	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec2 uvR = uv;
    uvR.x *= ratio;
    
    vec4 tex = mix(vec4(0.0,0.0,1.0,0.0), texture(iChannel0, uv)*2.0-1.0, turbInfluence);
    
    
    //Mask border to avoid artefacts
    //Normaly would use repeat texture mode for this, but it seams not possible with buffer textures
    float maskX = sin(uv.x*pi);
    float maskY = sin(uv.y*pi);
    float mask = smoothstep(0.3, 0.0, maskX*maskY);
    
    vec3 n = vec3(0.0,0.0,0.0);
    
    n = calculateNormals(uvR, 2.0); 
    
    fragColor = mix(vec4(vec3(tex.x + n.x,tex.y + n.y,0.0)*0.5+0.5, n.z), vec4(0.5,0.5,1.0,0.0), mask);
}