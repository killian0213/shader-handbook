// Image (image) — singularity space by latel88
// https://www.shadertoy.com/view/3dlyRN

float calcUV ( const in vec2 uv, const in float m )
{	
	float vig = (0.0 + 1.0 * 16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y));
	
	return max( m, 1.0 - pow( vig, 0.175 ) );

}

vec2 getDistortion ( const in CheckerCoord cd )
{
   	return restoreCheckerBuffer( iChannel0, cd ).ba;
    
}

float getDepth ( const in CheckerCoord cd )
{
    return restoreCheckerBuffer( iChannel0, cd ).g;
    
}

vec3 getColor ( const in CheckerCoord cd )
{
    float col = restoreCheckerBuffer( iChannel0, cd ).r;
    
    return vec3(col / 1.5, col / 1.75, col);  
    
}

vec3 blur ( const in int count, const in float radius, const in vec2 uv, const in CheckerCoord cd )
{
    if (count <= 1)
    {
        return getColor( cd );

    }

	float f = float(count);
	
    vec3 color =  vec3(0.0);
	float totalw = 0.0;
	
	for (int x = 0, len = max( 0, count - 1 ); x < len; x++)
	{
		vec2 p = uv;
		float fi1 = float(x) / f;
		float dir = fi1 * CIRCLE;

        p += vec2(sin( dir ), cos( dir )) * radius;
        
        vec2 u = p * iResolution.xy;

        if (hasInResolution( u, iResolution.xy ))
        {
            CheckerCoord cd = getBufferCheckerCoord( u, iResolution.xy );
            color += getColor( cd );
            totalw += 1.0;

        }


	}

	return color / totalw;

}

void mainImage ( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 resolution = iResolution.xy;
    vec2 coord = fragCoord;
    
    vec2 uv = coord.xy / resolution.xy;
    
    CheckerCoord cd = getBufferCheckerCoord( coord, resolution );
    
    vec2 distortion = getDistortion( cd );
        
    #ifdef EFFECT
        float vig = clamp( calcUV( uv, 0.125 ), 0.0, 1.0 );
        vec2 u = uv;

        u.xy += distortion * 0.0125;
        
        float par = max( vig, max( getDepth( cd ), max( abs( distortion.x ), abs( distortion.y ) ) ) );

    	vec3 color = blur( int(ceil( mix( 0.0, 50.0, clamp( par, 0.0, 1.0 ) ) )),  0.0125 * par, u, cd );
    #else
        vec3 color = getColor( uv * iResolution.xy );
    
    #endif
    
    if (distortion.x != 0.0 || distortion.y != 0.0)
    {
        Singularity singularity = getSingularity(iTime);

        color += (1.0 - singularity.radius / SINGULARITY_RADIUS) * vec3(0.75, 0.75, 1.0);
    }

    #ifdef DEBUG_LIST
        fragColor = texture(iChannel1, uv);

    #else
    	fragColor = vec4(color, 0.0);
   	#endif
    
}