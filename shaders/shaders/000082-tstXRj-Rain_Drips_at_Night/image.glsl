// Image (image) — Rain Drips at Night by granito
// https://www.shadertoy.com/view/tstXRj

#define heightMap iChannel0
#define heightMapResolution iChannelResolution[0]
#define textureOffset 1.0
#define pixelToTexelRatio (iResolution.xy/heightMapResolution.xy)

float bnoise (vec2 uv)
{
    return texture(iChannel3, uv).x * 2. - 1.;
}

vec2 texNormalMap(in vec2 uv)
{
    vec2 s = 1.0/heightMapResolution.xy;
    
    float p = texture(heightMap, uv).z;
    float h1 = texture(heightMap, uv + s * vec2(textureOffset,0)).z;
    float v1 = texture(heightMap, uv + s * vec2(0,textureOffset)).z;
       
   	return (p - vec2(h1, v1));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 res = iResolution.xy;
    vec2 invres = 1.0/res; 
    vec2 uv = fragCoord/res;
    uv = ((uv - 0.5) * (0.85 + sin(iTime*0.33) * 0.05)) + 0.5;
    vec2 uvoffset = vec2(sin(iTime * 0.2), cos(iTime * 0.4)) * 0.02;
    uvoffset += vec2(cos(iTime * 0.5), sin(iTime * 0.3)) * 0.01;
    uv += uvoffset;
    float noise = bnoise(fragCoord / vec2(1024.));
    vec4 bufB = texture(iChannel0, uv);
    bufB.xy *= -1.0;
   
    vec2 bguv = ((fragCoord/res - 0.5) * 0.85  + 0.5) ;
    
    //setup passes
    
    vec2 windowN = texNormalMap(uv) / (invres.x * 2000.) ;
    
    vec3 drops = texture(iChannel1, bguv + bufB.xy * -.1 + windowN, 2.).xyz; //drops on glass

    vec3 hazyglass = multisample( iChannel1, bguv  + windowN, (1.- bufB.w ) * 5., 0.05 + 0.0006 * noise).xyz; //hazy glass
    
    float spec = saturate( dot( normalize(vec3( -vec2(bufB.xy * -.1 + windowN)*10., 1.0)) , normalize(vec3((uv-vec2(sin(iTime*0.3)*2.+0.5,.2))*vec2(1.0,0.5),1.)) ));
    spec = pow(smoothstep(0.9,1.,spec),bufB.w * 100. + 60.);
    spec *= bufB.w + 0.1;
    
    //hazyglass *= (1.0-smoothstep(0.3, 0.5, bufB.w)) * 0.2 + .8; //highlight streaks

    if ( DEBUG != 1 ) //Output
    {
        float vignette = distance(fragCoord/res, vec2(0.5)) * 2.0 + 0.5;
    	fragColor.rgb = pow( mix(hazyglass, drops, smoothstep(0.8, 0.9, bufB.w) ), vec3(1.2,1.3,2.5) * vignette  ); //put passes together
        fragColor.rgb += spec*vec3(0.5,0.,0.);
    }
    else //Debug views
    {
        float time = fract(iTime * 0.25);
        if (time < 0.25)
        {
        	fragColor.rgb = buildnormalz(bufB.xy) * vec3(0.5) + vec3(0.5);
        }
        else if (time < 0.5)
        {
            fragColor.rgb = buildnormalz(texture(iChannel2, uv).xy) * vec3(0.5) + vec3(0.5);
        }
        else if (time < 0.75)
        {
			fragColor.rgb = vec3(bufB.w);
        }
        else
        {
            fragColor.rgb = vec3(texture(iChannel2, uv).w);        
        }      
    }
    //fragColor.rgb = vec3(spec);
    
}