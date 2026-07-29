// Image (image) — Super Shader GUI 98 by P_Malin
// https://www.shadertoy.com/view/Xs2cR1

#define iChannelUI iChannel0

float UI_GetFloat( int iData )
{
    return texelFetch( iChannelUI, ivec2(iData,0), 0 ).x;
}

bool UI_GetBool( int iData )
{
    return UI_GetFloat( iData ) > 0.5;
}

vec3 UI_GetColor( int iData )
{
    return texelFetch( iChannelUI, ivec2(iData,0), 0 ).rgb;
}


void UI_Compose( vec2 fragCoord, inout vec3 vColor, out int windowId, out vec2 vWindowCoord, out float fShadow )
{
    vec4 vUISample = texelFetch( iChannelUI, ivec2(fragCoord), 0 );
    
    if ( fragCoord.y < 2.0 )
    {
        // Hide data
        vUISample = vec4(1.0, 1.0, 1.0, 1.0);
    }
    
    vColor.rgb = vColor.rgb * (1.0f - vUISample.w) + vUISample.rgb;    
    
    windowId = -1;
    vWindowCoord = vec2(0);
    
    fShadow = 1.0f;
    if ( vUISample.a < 0.0 )
    {
        vWindowCoord = vUISample.rg;
        windowId = int(round(vUISample.b));
        
        fShadow = clamp( -vUISample.a - 1.0, 0.0, 1.0);
    }
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 vUV = fragCoord.xy / iResolution.xy;
    vec3 vResult = UI_GetColor( DATA_BG_COLOR );

    if ( UI_GetBool(DATA_BACKGROUND_IMAGE) )
    {
    	vResult.rgb = textureLod( iChannel1, vUV * UI_GetFloat(DATA_BACKGROUND_SCALE), 0.0 ).rgb * UI_GetFloat( DATA_BACKGROUND_BRIGHTNESS );
    }
    
    int windowId;
    vec2 vWindowCoord;
    float fShadow;
    UI_Compose( fragCoord, vResult, windowId, vWindowCoord, fShadow );
        
    if ( windowId == IDC_WINDOW_IMAGEA )
    {
        vResult.rgb = texelFetch( iChannel2, ivec2(vWindowCoord.xy), 0 ).rgb * UI_GetFloat( DATA_IMAGE_BRIGHTNESS );
	    vResult *= fShadow;
    }

    if ( windowId == IDC_WINDOW_IMAGEB )
    {
        vResult.rgb = textureLod( iChannel3, vWindowCoord.xy, 0.0 ).rgb * UI_GetColor( DATA_IMAGE_COLOR );
	    vResult *= fShadow;
    }
        
	fragColor = vec4(vResult,1.0);
}