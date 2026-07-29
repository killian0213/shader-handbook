// Image (image) — [SH16B] Mach 1 by P_Malin
// https://www.shadertoy.com/view/MttGz4


///////////////////////////
// PostFX
///////////////////////////

vec3 PostFX_ApplyVignetting( const in vec2 vUV, const in vec3 vInput, float fStrength )
{
	vec2 vOffset = (vUV - 0.5) * sqrt(2.0);
	
	float fDist = dot(vOffset, vOffset);
	
	float fShade = mix( 1.0, 1.0 - fStrength, fDist );	

	return vInput * fShade;
}

vec3 PostFX_ApplyTonemap( const in vec3 vLinear, float fExposure )
{
	return 1.0 - exp2( vLinear * -fExposure );	
}

vec3 PostFX_ApplyGamma( const in vec3 vLinear, float fGamma )
{
	return pow( vLinear, vec3(1.0/fGamma) );	
}

vec3 PostFX_Apply( vec3 vColor, vec2 vUV, float fExposure, float fVignetteStrength, float fGamma )
{
    vColor = PostFX_ApplyVignetting( vUV, vColor, fVignetteStrength );
    vColor = PostFX_ApplyTonemap( vColor, fExposure );
    vColor = PostFX_ApplyGamma( vColor, fGamma );
    return vColor;
}

///////////////////////////////////////////////

///////////////////////////////////////////////
float Blueprint_Grid( vec2 vGridUV, float fSpacing )
{   
    vec2 vScaledUV = vGridUV * fSpacing;
    
    vec2 vGridLinePos = fract( vScaledUV - 0.5 ) - 0.5;
    
    vec2 vToLine = abs(vGridLinePos) / fSpacing;
    
    float fAmount = min( vToLine.x, vToLine.y );
    
    fAmount = 1.0 - fAmount * 400.0;
    
    return clamp( fAmount, 0.0, 1.0);
}

float Blueprint_SampleDepth( vec2 vUV )
{
    return min( textureLod( iChannel0, vUV, 0.0 ).a, 10.0 );
}

vec3 Blueprint( const vec2 vUV )
{
    vec3 vColor = vec3(1.0);
    
    vec2 vPixelSize = 1.0 / iResolution.xy;
    vec3 vDelta = vec3( -1.0, 0.0, 1.0 );
    
	float fSample_tl = Blueprint_SampleDepth( vUV + vDelta.xx * vPixelSize );
	float fSample_tc = Blueprint_SampleDepth( vUV + vDelta.xy * vPixelSize );
	float fSample_tr = Blueprint_SampleDepth( vUV + vDelta.xz * vPixelSize );
    
	float fSample_cl = Blueprint_SampleDepth( vUV + vDelta.yx * vPixelSize );
	float fSample_cc = Blueprint_SampleDepth( vUV + vDelta.yy * vPixelSize );
	float fSample_cr = Blueprint_SampleDepth( vUV + vDelta.yz * vPixelSize );

    float fSample_bl = Blueprint_SampleDepth( vUV + vDelta.zx * vPixelSize );
	float fSample_bc = Blueprint_SampleDepth( vUV + vDelta.zy * vPixelSize );
	float fSample_br = Blueprint_SampleDepth( vUV + vDelta.zz * vPixelSize );
    
    vec2 edge;
    edge.x = fSample_tl * -1.0 + fSample_tr * 1.0
    	 	 + fSample_cl * -2.0 + fSample_cr * 2.0
        	 + fSample_bl * -1.0 + fSample_br * 1.0;
    
    edge.y = fSample_tl * -1.0 + fSample_tc * -2.0 + fSample_tr * -1.0
        	 + fSample_bl *  1.0 + fSample_bc * 2.0 + fSample_br * 1.0;
    
    float amount = clamp( (sqrt(length(edge))- 1.5) * 2.0 , 0.0, 1.0);

    vec2 vGridUV = vUV;
    vGridUV.x *= iResolution.x / iResolution.y;
    amount += Blueprint_Grid(vGridUV, 8.0) * 0.2;
    amount += Blueprint_Grid(vGridUV, 16.0) * 0.05;
    amount += Blueprint_Grid(vGridUV, 80.0) * 0.05;
    
    vColor = mix( vec3(0.1,0.1,.25), vec3(.9,1,1), amount );
    
    return vColor;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 gBloomSize = min( vec2(320.0, 240.0), iChannelResolution[1].xy );
    
	vec2 vUV = fragCoord.xy / iResolution.xy;

    // Show environment map
	//fragColor = texture( iChannel3, vUV ).rgba; return;    
    
    // Show raw scene render
	//fragColor = texture( iChannel0, vUV ).rgba; return;    
    
    // Show bloom buffer
    //fragColor = texture( iChannel1, vUV ).rgba; return;    
    
	vec4 vImageSample = textureLod( iChannel0, vUV, 0.0 ).rgba;
	vec4 vBloomSample = textureLod( iChannel1, vUV * gBloomSize / iResolution.xy, 0.0 ).rgba;

    const float fBloomAmount = 0.2;
    
    vec3 vResult = mix( vImageSample.rgb, vBloomSample.rgb, fBloomAmount );
    
    vResult += textureLod( iChannel1, (0.5 + (vUV - 0.5) * 0.6) * gBloomSize / iResolution.xy, 0.0 ).rgb * 0.00015 * vec3(1,1,0);
    
    vResult += textureLod( iChannel1, (0.5 + (vUV - 0.5) * -0.5) * gBloomSize / iResolution.xy, 0.0 ).rgb * 0.0015 * vec3(1,0,0);
    vResult += textureLod( iChannel1, (0.5 + (vUV - 0.5) * -0.525) * gBloomSize / iResolution.xy, 0.0 ).rgb * 0.0015 * vec3(0,1,0);
    vResult += textureLod( iChannel1, (0.5 + (vUV - 0.5) * -0.55) * gBloomSize / iResolution.xy, 0.0 ).rgb * 0.0015 * vec3(0,0,1);

    float fExposure = 3.0;
    
    float fBlend = clamp( (iTime - 64.0) * 0.1 , 0.0, 1.0 );
    if ( iTime > 78.0 )
    {
        fBlend = 0.0;
    }
    fExposure *= 1.0 - fBlend;

    vec3 vFinal = PostFX_Apply( vResult.rgb, vUV, fExposure, 0.9, 1.2 );   
    
    vec3 vBlueprintScene = vec3(0);
    
    {
        vec2 vSceneUV = vUV; 

        vSceneUV -= 0.5;
		vSceneUV.x *= iResolution.x / iResolution.y;

        vSceneUV *= 1.2;
        float p = 0.1;
        vSceneUV *= mat2( cos(p), sin(p), -sin(p), cos(p) );
        
        vSceneUV *= (0.3 + exp2( iTime) * 0.03) ;
        
        vSceneUV += 0.5;
        
        vec2 vPageUV = vSceneUV;        
        //float t = 0.1;
        //vPageUV -= 0.5;
        //vPageUV *= mat2( cos(t), sin(t), -sin(t), cos(t) );
        //vPageUV += 0.5;
        //vPageUV.x += sin(iTime);

        vPageUV -= 0.5;
		vPageUV.x /= iResolution.x / iResolution.y;
        vPageUV += 0.5;        
        
        if ( any( greaterThan( vPageUV, vec2(1))) || any( lessThanEqual( vPageUV, vec2(0))) )
        {
            vBlueprintScene.rgb = textureLod( iChannel2, vSceneUV, 0.0 ).rgb;
            vBlueprintScene.rgb *= textureLod( iChannel2, vSceneUV * 0.01, 0.0 ).rgb;
            vBlueprintScene.rgb = sqrt( vBlueprintScene.rgb );
            
            vec2 vShadowPos = vPageUV + vec2(-0.001, 0.05);
            vec2 vClosest = clamp( vShadowPos, vec2(0), vec2(1) );
            float fDist = length( vClosest - vShadowPos );
            vBlueprintScene.rgb *= clamp( fDist * 30.0, 0.0, 1.0) * 0.5 + 0.5;
        }
        else
        {
            vBlueprintScene = Blueprint( vPageUV );
        }
    }

    float fBlueprint = step(iTime, 8.0);//step( 0.5, fract( (vUV.x + vUV.y * .5) * 0.1 + iTime ) ) ;
    vFinal.rgb = mix( vFinal, vBlueprintScene, fBlueprint);

    // Draw depth
    //vFinal = vec3( 1.0 - exp2( abs(vImageSample.a) * -0.02 ) ); 
    
	fragColor = vec4(vFinal, 1.0);
}
