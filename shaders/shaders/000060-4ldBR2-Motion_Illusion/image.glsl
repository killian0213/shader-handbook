// Image (image) — Motion Illusion by P_Malin
// https://www.shadertoy.com/view/4ldBR2

// Motion Illusion - @P_Malin
// https://www.shadertoy.com/view/4ldBR2

// Lunchtime hacked version of that motion illusion image.
// Sorry, I don't know the original source.
// Update: perhaps by Yurii Perepadia https://www.instagram.com/p/BqVQ1fjBF2E/ or @BeauDeeley 
// https://stock.adobe.com/fr/images/optical-motion-illusion-illustration-a-sphere-are-rotation-around-of-a-moving-hyperboloid-abstract-fantasy-in-a-surreal-style/131366127?fbclid=IwAR1sFHeKn93GoVRJrhmOYQTmCPr8Gi_Rwu2ZuKIeYIg9Uz2B

// Code loosely based on https://www.shadertoy.com/view/XsdcDr

#define HEX_PATTERN 1

#define ENABLE_AA 1

#define REVERSE_DIRECTION 0


float MAX_DIST = 1000.0;

#define PI 3.141592654
#define TAU  (PI * 2.0)

vec2 GetWindowCoord( const in vec2 vUV )
{
	vec2 vWindow = vUV * 2.0 - 1.0;
	vWindow.x *= iResolution.x / iResolution.y;

	return vWindow;	
}

vec3 GetCameraRayDir( const in vec2 vWindow, const in vec3 vCameraPos, const in vec3 vCameraTarget )
{
	vec3 vForward = normalize(vCameraTarget - vCameraPos);
	vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
	vec3 vUp = normalize(cross(vForward, vRight));
							  
    float fPersp = 3.0;
	vec3 vDir = normalize(vWindow.x * vRight + vWindow.y * vUp + vForward * fPersp);

	return vDir;
}

vec4 Scene_SphereA( vec3 vPos )
{
    float xPos = -0.5;
    //flost xPos = -0.5 * sin(iTime)
    vec3 vSphereDomain = vPos - vec3( xPos, 0.0, 2.0 );
    float fSphereRadius = 0.4;
    float fSphereDist = length( vSphereDomain ) - fSphereRadius;
    vec3 vSphereDir = vSphereDomain / fSphereRadius;
    //vec2 vSphereUV = vec2( vSphereDir.y, atan( vSphereDir.z, vSphereDir.x )) * 2.0;
    // Sphere UV code from 	wj
    vec2 vSphereUV = vec2(acos(vSphereDir.y / length(vSphereDir)), atan( vSphereDir.z, vSphereDir.x ))*2.0 ;
    vec4 vSphereResult = vec4( fSphereDist, vSphereUV, 2.0 );    
    
    return vSphereResult;
}

vec4 Scene_Pillar( vec3 vPos )
{
    float fPillarRadius = 1.0 - cos( vPos.y * 2.0 );
    fPillarRadius = 0.4 + fPillarRadius * fPillarRadius * 0.5;
    vec2 vPillarOffset = vPos.xz - vec2(0.0, 3.0);
    float fPillarDist = length( vPillarOffset ) - fPillarRadius;
    vec2 vPillarUV = vec2( vPos.y * 4.0, 2.5 * atan( vPillarOffset.y, vPillarOffset.x ) );
    vec4 vPillarResult = vec4( fPillarDist, vPillarUV, 1.0 );
    
    return vPillarResult;
}

vec4 Scene_GetDistance( vec3 vPos )
{
	vec4 vResult = vec4( MAX_DIST, 0.0, 0.0, 0.0 );

    vec2 vWallUV = vec2(vPos.y, -vPos.x) * 1.5;
    vec4 vWallResult = vec4( -vPos.z + 5.0, vWallUV, 0.0 );
    
    if ( vWallResult.x < vResult.x )
    {
        vResult = vWallResult;
    }

	vec4 vPillarResult = Scene_Pillar( vPos );
    
    if ( vPillarResult.x < vResult.x )
    {
        vResult = vPillarResult;
    }
    
	vec4 vSphereResult = Scene_SphereA( vPos );
    
    if ( vSphereResult.x < vResult.x )
    {
        vResult = vSphereResult;
    }

    return vResult;
}

vec3 Scene_GetNormal( const in vec3 vPos )
{
    const float fDelta = 0.0001;
    vec2 e = vec2( -1, 1 );
    
    vec3 vNormal = 
        Scene_GetDistance( e.yxx * fDelta + vPos ).x * e.yxx + 
        Scene_GetDistance( e.xxy * fDelta + vPos ).x * e.xxy + 
        Scene_GetDistance( e.xyx * fDelta + vPos ).x * e.xyx + 
        Scene_GetDistance( e.yyy * fDelta + vPos ).x * e.yyy;
    
    return normalize( vNormal );
}   

vec4 Scene_Trace( vec3 vRayOrigin, vec3 vRayDir, float minDist, float maxDist )
{	
    vec4 vResult = vec4(0);
    
	float t = minDist;
	const int kRaymarchMaxIter = 128;
	for(int i=0; i<kRaymarchMaxIter; i++)
	{		
        float epsilon = 0.0001 * t;
		vResult = Scene_GetDistance( vRayOrigin + vRayDir * t );
        if ( abs(vResult.x) < epsilon )
		{
			break;
		}
                        
        if ( t > maxDist )
        {
	        t = maxDist;
            break;
        }               
        
        t += vResult.x;
	}
    
    vResult.x = t;
    
    return vResult;
}    


#if HEX_PATTERN

// Returns vec4( distance to edge, distance to centre, vec2( hexagon co-ordinate ) )
// hexagon co-ordinate integer part is hexagon I.D.
// hexagon co-ordinate fractional part is uv within the hexagon
vec4 Hexagon( vec2 pos ) 
{
    vec2 vScale = vec2( 1.0, sqrt(3.0) );
    
    vec2 p = pos * vScale;
      
    // :
    // :
    // o--+--+--+--+--+--o
    // |  : /:  |  :\ :  |
    // |  :/ :  |  : \:  |
    // +--+--+--o--+--+--+
    // |  :\ :  |  : /:  |
    // |  : \:  |  :/ :  |
    // o--+--+--+--+--+--o - - - - 
    
    vec2 f = fract( p );
    
    vec2 index = floor( p );
    index.x *= 2.0;
    
    vec2 c;    
    
    vec2 t = abs( f - vec2(0.5, 0.5) );

    // get hexagon center and index
    
    // (6.0, 2.0) = dimensions of repeating grid above
    if ( t.x * 6.0 < -t.y * 2.0 + 2.0 )
    {
        c = vec2(0.5);        
    }
    else
    {
        if ( f.x > 0.5 )
        {
            c.x = 1.0; 

            index.x += 1.0;
        }
        else
        {
            index.x -= 1.0;
            c.x = 0.0;
        }
        
        if ( f.y > 0.5 )
        {
            c.y = 1.0;            
            index.y += 1.0;
        }
        else
        {
            c.y = 0.0;
        }
    }
            
    vec2 offset = (f - c) / vScale;
    float d = length( offset );
    
    vec2 vDir[3] = vec2[3]( 
        vec2(  0.0, 				1.0 ), 
        vec2( -sqrt(3.0) / 2.0,	1.0 / 2.0 ),
        vec2(  sqrt(3.0) / 2.0,	1.0 / 2.0 ) );    
    
    float s = 10000.0;
    
    for ( int i=0; i<3; i++ )
    {
        float d = 1.0 - abs( dot( offset, vDir[i] ) ) * 2.0 * sqrt(3.0);
        s = min( s, d );
    }
    
    vec2 vUV = index + offset * 1.5 + 0.5;
    
    return vec4(s, d, vUV );
}


vec3 HexPattern( vec2 vUV, vec3 colInner, vec3 colEdge )
{
    // uncomment to actually scroll :P
    //vUV.y -= iTime * 0.01;
    
    vec4 hex = Hexagon( vUV );
    
    float edgeShade = step( fract(hex.w), 0.5 );

    vec3 col = colInner; 
    col = mix( col, vec3(edgeShade), step(hex.x, 0.3) ); // black / white edge
    col = mix( col, colEdge, step(hex.x, 0.15) ); ; // Yellow Surround
        
    return col;
}


#endif



vec3 MotionTextureGradient( float f )
{
#if 0
    vec3 cols[] = vec3[](
        vec3(1,0,0),
        vec3(1,0,1),
        vec3(0.95,0,1) * 0.75
        );

    f *= float( cols.length() );    

    int c1 = int( floor(f) ) % cols.length();
    int c2 = (c1 + 1) % cols.length();
    float b = clamp( f - float(c1), 0.0, 1.0 );
    
    //b = smoothstep(0.0,1.0,b);
    return mix( cols[c1], cols[c2], b );    
#else    
    vec3 vColA = vec3( 253, 27, 32 ) / 255.0;
	vec3 vColB = vec3( 198, 48, 249 ) / 255.0;
    
    //vec3 vColA = vec3(1,1,0);
    //vec3 vColB = vec3(1,.1,0);
        
    float fCol = sin(f * TAU) * 0.5 + 0.5;
    float fLum = sin((f + 0.25) * TAU) * 0.5 + 0.5;
        
    float fLumA = 0.9;
    float fLumB = 1.0;

    return mix( vColA, vColB, fCol ) * mix( fLumA, fLumB, fLum );
#endif    
}

vec3 MotionTexture( vec2 vUV, float obj )
{
#if HEX_PATTERN
    
    
    vec3 innerCol = vec3(1.0);

    if ( obj < 0.5 )
    {
        innerCol = vec3(70, 30, 123) / 255.;
    }
    else
    if ( obj < 1.5 )
    {
        innerCol = vec3(113, 36, 132) / 255.;
    }
    else
    if ( obj < 2.5 )
    {
        innerCol = vec3(133, 39, 76) / 255.;
    }
    
    return HexPattern( vUV * 1.0 + 0.1, innerCol, vec3(198, 161, 57) / 255. );
#else
    float x = fract( vUV.x );

    float fOffset = floor( x * 2.0 ) / 2.0;
    float y = fract( vUV.y + fOffset );
    
	return MotionTextureGradient( y );
#endif    
}

vec3 GetSceneColour( const in vec3 vRayOrigin,  const in vec3 vRayDir )
{
    float theta = atan(vRayDir.x, vRayDir.y);
    vec4 vScene = Scene_Trace( vRayOrigin, vRayDir, 0.0, MAX_DIST );
    float fDist = vScene.x;
	vec3 vPos = vRayOrigin + vRayDir * fDist;
	
    vec3 vNormal = Scene_GetNormal( vPos );
    vec2 vUV = vScene.yz; 
    
    
    if ( fDist > 350.0 )
    {
        vUV = vec2(0);
    }   

#if REVERSE_DIRECTION
    vUV.y = 1.0 - vUV.y;
#endif    
    
    vec3 vTex = MotionTexture(vUV + 0.25, vScene.w );
    
    vTex = vTex * vTex;
    
    
    
    vec3 vResult = vTex;
    
    // Hacked darkening
    if ( vScene.w == 0.0 )
    {
        // darken back wall
        vResult *= 1.0 - (0.6 / (0.2 + Scene_Pillar( vPos ).x));
        vResult *= 1.0 - (0.43 / (0.25 + Scene_SphereA( vPos ).x));
        vResult *= 0.8;
    }
    
    if ( vScene.w == 1.0 )
    {
        // darken pillar
        vResult *= 1.0 - (0.43 / (0.25 + Scene_SphereA( vPos ).x));
        vResult *= max(0.0, -vNormal.z) * 0.8 + 0.2;
        vResult *= 1.5;
    }

    if ( vScene.w == 2.0 )
    {
        
        vResult *= max(0.0, -vNormal.z);
    }

    
    vResult *= 1.5;

    return sqrt(vResult);
}

void mainImageNoAA( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 vUV = fragCoord.xy / iResolution.xy;

	vec3 vCameraPos = vec3(0.0, 0.0, 0.0);
	vec3 vCameraTarget = vec3(0.0, 0.0, 10.0);
    
	vec3 vRayOrigin = vCameraPos;
	vec3 vRayDir = GetCameraRayDir( GetWindowCoord(vUV), vCameraPos, vCameraTarget );
	
	vec3 vResult = GetSceneColour(vRayOrigin, vRayDir);
    	    
	fragColor = vec4(vResult, 1.0);
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
#if ENABLE_AA
    fragColor = vec4(0);
    float count = 0.0;

    float AA_Size = 4.0;
    
    for ( float aaY = 0.; aaY < AA_Size; aaY++ )
    {
        for ( float aaX = 0.; aaX < AA_Size; aaX++ )
        {
            vec4 vSample;
            mainImageNoAA( vSample, fragCoord + vec2(aaX, aaY) / AA_Size );
            
            fragColor += vSample;
        	count += 1.0;
        }	
    }
    
    fragColor /= count;
#else    
    mainImageNoAA(fragColor, fragCoord);
#endif
}
