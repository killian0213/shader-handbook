// Buffer B (buffer) — Volume Path Tracing on Bunny by SebH
// https://www.shadertoy.com/view/7dVGWR


// Manage keyboard and mouse input for setting up the scene and camera
// the state data are stored into BufferB.

#define PIX_ARE_EQUAL(a, b)  (int(a.x)==int(b.x) && int(a.y)==int(b.y) ? true : false)

void mainImage( out float4 fragColor, in float2 fragCoord )
{
	float2 uv = fragCoord.xy / iResolution.xy;
    float time = iTime;
	float2 MouseUV = iMouse.xy / iResolution.xy;
	float2 MouseClickUV = iMouse.zw / iResolution.xy;
    
    float3 PrevCamPos = texelFetch(iChannel0, ivec2(PIX_CAMPOS), 0).xyz;
    float2 PrevMousePos = texelFetch(iChannel0, ivec2(PIX_MOUSEPOS), 0).xy;
	float2 PrevMouseUV = PrevMousePos / iResolution.xy;
    
    float2 CamYawPitch = texelFetch(iChannel0, ivec2(PIX_CAMYP), 0).xy;
    
    bool bFullReset = FullReset;
    
    // View diretion in camera space
    float3 viewDir = normalize(float3((fragCoord.xy - iResolution.xy*0.5) / iResolution.y, 1.0));
    
    // Reset accumulation by default
    bool ResetAccum = bFullReset || (int(iMouse.x)!=int(PrevMousePos.x) && int(iMouse.y)!=int(PrevMousePos.y)) || texelFetch(iChannel1, ivec2(KEY_UP,0), 0).x > 0.0;
    
    // Sun light control
    float SunPower = 4.0f;
    float4 SunDirPow = bFullReset ? float4(normalize(float3(0,0.1,1)), SunPower) : texelFetch(iChannel0, ivec2(PIX_SUNDIRPOW), 0).xyzw;
    bool bControlSun = texelFetch(iChannel1, ivec2(KEY_LEFT,0), 0).x > 0.0;
    if(bControlSun)
    {
        ResetAccum = true;
        float HorizonAngle = MouseUV.x*2.0*PI;
        float VerticalAngle = (MouseUV.y-0.05)*PI;
        SunDirPow = float4(normalize(float3(cos(HorizonAngle)*cos(VerticalAngle), sin(VerticalAngle), sin(HorizonAngle)*cos(VerticalAngle))), SunPower);
    }
    
    
    
    // Compute camera properties
    float  camDist = 3.3;
    float  CamHeight= 0.0;
    float3 camUp = float3(0, 1.0, 0);
    if(bFullReset)
    {
        CamYawPitch.x = 0.0;
        CamYawPitch.y = 0.5;
    }
    if(!bControlSun)
    {
        CamYawPitch.x += (MouseUV.x - PrevMouseUV.x) * 10.0;
        CamYawPitch.y += (MouseUV.y - PrevMouseUV.y) * 5.0;
        
        CamYawPitch.y = clamp(CamYawPitch.y, -PI*0.45, PI*0.45);
    }
    float HorizonAngle = CamYawPitch.x; //MouseUV.x*2.0*PI;
    float VerticalAngle = CamYawPitch.y;//-(MouseUV.y-0.5)*PI;
    float3 camPos = float3(camDist*cos(HorizonAngle)*cos(VerticalAngle), CamHeight+camDist*sin(VerticalAngle), camDist*sin(HorizonAngle)*cos(VerticalAngle));
    float3 camTarget = float3(0, -0.0, 0);
    
    // And from them evaluated ray direction in world space
    float3 forward = normalize(camTarget - camPos);
    float3 left = normalize(cross(forward, camUp));
    float3 up = cross(left, forward);
    
    fragColor = float4(0.0);
    
    if(PIX_ARE_EQUAL(PIX_MOUSEPOS, fragCoord.xy))
    {
        fragColor = float4(iMouse.xy, 0.0, 0.0);
    }
    if(PIX_ARE_EQUAL(PIX_RESETACCUM, fragCoord.xy))
    {
        fragColor = float4(ResetAccum ? 1.0 : 0.0, 0.0, 0.0, 0.0);
    }
    
    if(PIX_ARE_EQUAL(PIX_CAMPOS, fragCoord.xy))
    {
        fragColor = float4(camPos, 0.0);
    }
    if(PIX_ARE_EQUAL(PIX_CAMUP, fragCoord.xy))
    {
        fragColor = float4(up, 0.0);
    }
    if(PIX_ARE_EQUAL(PIX_CAMLEFT, fragCoord.xy))
    {
        fragColor = float4(left, 0.0);
    }
    if(PIX_ARE_EQUAL(PIX_CAMFORWARD, fragCoord.xy))
    {
        fragColor = float4(forward, 0.0);
    }

    if(PIX_ARE_EQUAL(PIX_SUNDIRPOW, fragCoord.xy))
    {
        fragColor = SunDirPow;
    }

    if(PIX_ARE_EQUAL(PIX_CAMYP, fragCoord.xy))
    {
        fragColor = float4(CamYawPitch, 0.0, 0.0);
    }

}
