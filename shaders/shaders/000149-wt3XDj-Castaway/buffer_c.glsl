// Buffer C (buffer) — Castaway by P_Malin
// https://www.shadertoy.com/view/wt3XDj

//    __  __         _           _____                           _____                   _             
//   |  \/  |       (_)         / ____|                         |  __ \                 | |            
//   | \  / |  __ _  _  _ __   | (___    ___  ___  _ __    ___  | |__) | ___  _ __    __| |  ___  _ __ 
//   | |\/| | / _` || || '_ \   \___ \  / __|/ _ \| '_ \  / _ \ |  _  / / _ \| '_ \  / _` | / _ \| '__|
//   | |  | || (_| || || | | |  ____) || (__|  __/| | | ||  __/ | | \ \|  __/| | | || (_| ||  __/| |   
//   |_|  |_| \__,_||_||_| |_| |_____/  \___|\___||_| |_| \___| |_|  \_\\___||_| |_| \__,_| \___||_|   
//                                                                                                     
//                                                                                                     

#define iChannelState			iChannel0
#define iChannelRockTexture		iChannel1


EnvironmentSettings GetEnvironmentSettings()
{
    EnvironmentSettings env;
    
    env.time = iTime;

    env.sunElevation = (0.2f * PI * 0.5);
    env.sunHeading = (PI * 0.15);
    
#if 1
    // day
    env.skyZenithCol = vec3( 0.005f, 0.1f, 1.0f ) * 0.3;
    env.skyHorizonCol = vec3( 0.1f, 0.4f, 1.0f ) * 1.0;
    
	vec3 sunCol = vec3(1.0f, 0.95f, 0.65f);
    
    env.fogCol =  vec3( 0.6, 0.85, 0.9 ) * 2.0;
    
    env.sunDiscCol = sunCol * 4096.0;
    env.sunLightCol = sunCol * 2.0;
    
#endif
    
#if 0
    // sunset-ish
    env.sunElevation = (0.05f * PI * 0.5);
    
    env.skyZenithCol = vec3(1,0.2,0) * 0.25;
    env.skyHorizonCol = vec3( 1,0,0);
    
	vec3 sunCol = vec3(1.0f, 0.25f, 0.001f);
    
    env.fogCol =  vec3( 1.0, 0.5, 0.0 );
    
    env.sunDiscCol = sunCol * 64.0;
    env.sunLightCol = sunCol * 2.0;
    
#endif
    
#if 0
    // night-ish
    env.skyZenithCol = vec3(0,0,0.001);
    env.skyHorizonCol = vec3( 0,0.01,0.05);
    
	vec3 sunCol = vec3(0.2f);
    env.sunElevation = (0.1f * PI * 0.5);
    
    env.fogCol =  env.skyHorizonCol;
    
    env.sunDiscCol = sunCol * 32.0;
    env.sunLightCol = sunCol;// * 2.0;
    
#endif
    
#if 0
    // Hello darkness my old friend. I've found some bugs with you again.
    env.skyZenithCol = vec3(0);
    env.skyHorizonCol = vec3( 0);
    
	vec3 sunCol = vec3(0.0f);
    env.sunElevation = (0.1f * PI * 0.5);
    
    env.fogCol =  env.skyHorizonCol;
    
    env.sunDiscCol = sunCol * 32.0;
    env.sunLightCol = sunCol;// * 2.0;
    
#endif    
    
    env.ambientCol = (env.skyZenithCol + env.skyHorizonCol) * 0.5 * 0.25;
        
    env.ambientCol =env.fogCol;
    env.fogDensity = 0.001f;
    env.skyFogDensity = 0.00001f;
        
    //env.sunElevation = iMouse.y * PI * 0.5 / iResolution.y;
    //env.sunHeading = iMouse.x * TAU / iResolution.x;

    float se = sin( env.sunElevation );
    float ce = cos( env.sunElevation );
    float sh = sin( env.sunHeading );
    float ch = cos( env.sunHeading );
    
    env.sunDir = normalize( vec3( ce * sh, se, ce * ch ) );
    
    return env;
}


vec3 GetExtinction( vec2 mapPos )
{
// https://aslopubs.onlinelibrary.wiley.com/doi/pdf/10.4319/lo.1997.42.2.0379
// green seawater
    vec3 extA = vec3( 0.29, 0.10, 0.43 );
    
    vec3 extB = vec3( 0.3, 0.11, 0.11 );    
    float blend = SmoothNoise22( mapPos * 0.01 ).x;    
    return mix( extA, extB, blend );
}

vec3 GetSunGlow( EnvironmentSettings env, vec3 dir )
{
	float VdotL = dot( dir, env.sunDir );
    
    VdotL = VdotL * 0.5 + 0.5;
        
    float gf = 1.0 - VdotL;
    
    float scale = (1.0 / (gf * 150.0 + 0.45));
    
    //float scale = (1.0 / (gf * 1000.0 + 1.0));

    vec3 redGlow = pow(VdotL,8.0) * vec3(1.0, 0.2, 0.05) * 0.2;
    return env.sunLightCol * (scale + redGlow);    
}


vec2 GetShorelineWaves( vec2 pos, float water_terrain_dh )
{
    //return vec2(0);
    water_terrain_dh = max( 0.0f, water_terrain_dh );
    float p = water_terrain_dh * 8.0 + iTime * 1.5;
    //float p = pos.y;
    //p *= water_terrain_dh * 0.05 + 1.0;
    //p += iTime * 2.0;
    
    vec2 noise = SmoothNoise22( pos * 0.1 );
    
    p = p + noise.x * 4.0;
    
    float waveMag = exp( -water_terrain_dh * 0.7);
    
    
    float sw = sin( p + cos(p) * (1.0 - waveMag) ) * -0.5 + 0.5;    
    
    //float chop = 3.0 - waveMag * 3.0;
    //sw = pow ( 1.0 - sw, chop );    
    
    float fm = (sin( p - PI * 0.85 ) * 0.5 + 0.5);
        
    return vec2( sw * sqrt( waveMag ), fm * waveMag ) * noise.y ;
}


float Water_WaveShape( vec2 uv, float chop )
{
	uv += SmoothNoise22( uv * 0.6) * 2.0;
    
    vec2 w = sin(uv * 2.0) * 0.5 + 0.5;
    
    w = 1.0 - pow ( 1.0 - w, vec2(chop) );
    
    float h = (w.x + w.y) * 0.5;
    
    return h;//pow( h, 0.1 );
}

float Water_GetWaves( vec2 mapPos, int waterOctaves, float time )
{
    float a = 1.0f;
    
    float h = 0.0f;
    
    float tot = 0.0;
    
    float r = 2.5f;
    mat2 rm = mat2( cos(r), -sin(r), sin(r), cos(r) ) * 2.1f;
    
    vec2 aPos = mapPos;
    
    float waveTime = time;
    
    float chopA = 0.7;
    float chopB = 0.9;
    
    int maxOctaveCount = 8;
        
    for ( int octave = 0; octave < maxOctaveCount; octave++ )
    {            
        if ( octave > waterOctaves )
            break;

        float chop = mix(chopA, chopB, float(octave) / float(waterOctaves-1));
        
        h += Water_WaveShape( aPos + waveTime , chop ) * a;
        tot += a;
                
        aPos = aPos * rm;
                
        a *= .3;
        
        waveTime *= 1.6;
        
    }
    
    return h / tot;    
}

float Water_GetHeight( vec2 origMapPos, int waterOctaves, float time )
{
    
#if EQUIRECTANGULAR_PROJECTION    
    return -1000.0;
#endif    
    vec2 mapPos = origMapPos / 4.0;
            
	float h = Water_GetWaves( mapPos, waterOctaves, time );
    
    bool detail = false;
    float terrainHeight = Terrain_GetHeight( iChannelRockTexture, origMapPos, false, true );
    float waveScale = smoothstep( 0.0, -2.0, terrainHeight ) * 0.8 + 0.2;
    //waveScale = 0.0f;
    
    //waveScale *= 1.0 - smoothstep( 1.8f, 1.9f, terrainHeight );
    
    //waveScale = 1.0f;
    
    float result = h * waveScale;

    float shorelineWaves = GetShorelineWaves(origMapPos, -terrainHeight).x * waveScale * 1.5;
    
    float water_terrain_dh = result - terrainHeight;
#if 0
    float foamFactor = smoothstep( 0.3, 0.0f, water_terrain_dh );
    
    float t= ( foamFactor * foamFactor *  foamFactor ) *  1.5;
    float bump = 3.0 * t * t - 2.0f * t * t * t;
    result += bump * 0.1;
#endif  
    
#if 1
    float edge = (water_terrain_dh+shorelineWaves*0.5+0.02)*5.;
    edge = clamp(1.0-edge, 0.0, 1.0);    
    edge = sqrt( 1.0 - edge * edge );
    //edge = smoothstep( 0.0, 1.0, edge );
    result += edge * 0.1;
#endif
    
    //result = 0.0f;
    
    result += shorelineWaves;
    
    return result;
}

struct MapHeight
{
    float height;
    int objectId;
};

MapHeight Map_GetHeight( vec2 mapPos, int waterOctaves, bool detail )
{
    float groudHeight = Terrain_GetHeight( iChannelRockTexture, mapPos, detail, false );
    MapHeight result = MapHeight( groudHeight, 0 );
    
    if ( waterOctaves > 0 )
    {
        float waterHeight = Water_GetHeight(mapPos, waterOctaves, iTime );
        if (waterHeight > result.height )
        {
            result.height = waterHeight;
            result.objectId = 1;
        }
    }
    
    return result;
}

MapHeight Map_GetAltitude( vec3 pos, int waterOctaves, bool detail )
{
    MapHeight mapHeight = Map_GetHeight( pos.xz, waterOctaves, detail );
    return MapHeight( pos.y - mapHeight.height, mapHeight.objectId );    
}

vec3 Map_GetNormal( vec3 pos )
{
    const float delta = 0.01;
    
    const int normalOctaves = 8;
    vec3 normal = vec3(1.0f, 0.0f, 1.0f) * Map_GetHeight( pos.xz, normalOctaves, true ).height
           + Map_GetHeight( pos.xz + vec2(delta, 0.0f), normalOctaves, true ).height * vec3(-1.0f, 0.0, 0.0)
        + Map_GetHeight( pos.xz + vec2(0.0f, delta), normalOctaves, true ).height * vec3(0.0f, 0.0, -1.0) + vec3(0.0, delta, 0.0);
    
    return normalize( normal );
} 

struct MapTraceResult
{
    float dist;
    int objectId;
};

MapTraceResult Map_Trace( vec3 rayOrigin, vec3 rayDir, int waterOctaves, bool detail )
{
    MapTraceResult result = MapTraceResult( -1., -1 );
    //if ( rayDir.y > 0.0f )
    //{
        //return -1.0f;
    //}
        
    float minT;
    vec3 minPos;
    float minH;
    
    float maxT = 0.0f;
    vec3 maxPos = rayOrigin + rayDir * maxT;
	MapHeight mapHeight = Map_GetAltitude( maxPos, waterOctaves, detail );
    float maxH = mapHeight.height;    
    result.dist = maxT;    
    result.objectId = mapHeight.objectId;  

    float yMax = 2.0f;
    float yMin = -8.0f;
    
    yMax = min( yMax, rayOrigin.y );
    
    int maxIterA = 16;
    
    //float traceStep = 1.0;
    
    for( int iter = 1; iter <= maxIterA; iter++ )
    {
        minT = maxT;
        minH = maxH;

        float fr = float(iter) / float(maxIterA);
        float y = yMax + (yMin - yMax) * fr;
        
        maxT = (y - rayOrigin.y) / rayDir.y;               
        
        maxPos = rayOrigin + rayDir * maxT;
		MapHeight mapHeight = Map_GetAltitude( maxPos, waterOctaves, detail );
        maxH = mapHeight.height;
        
        result.dist = maxT;
	    result.objectId = mapHeight.objectId;  
                
        if ( maxH < 0.0 )
        {
            break;
        }        
    }    
    
    
    int maxIterB = 11;
    
    for( int iter = 0; iter < maxIterB; iter++ )
    {
        float midT = (minT + maxT) * 0.5f;        
        //float midT = mix( minT, maxT, ( (maxH + minH) * 0.5 - minH ) / (maxH-minH) );
        
        vec3 midPos = rayOrigin + rayDir * midT;
		MapHeight mapHeight = Map_GetAltitude( midPos, waterOctaves, detail );
        float midH = mapHeight.height;
        
        if ( midH < 0.0f )
        {
            maxT = midT;
            maxH = midH;
            result.dist = maxT;
		    result.objectId = mapHeight.objectId;  
        }
        else
        {
            minT = midT;
            minH = midH;
        }      
        
        if ( abs( minH - maxH ) < 0.001)
        {
            break;
        }
    }
    
    return result;
}

vec3 GetSkyColour( EnvironmentSettings env, vec3 rayOrigin, vec3 rayDir, float mipLod, bool sunDisc )
{
    vec4 skyResult = TraceSky( env, iChannel1, rayDir, iTime * 3.0, mipLod, sunDisc );
    
    
    vec3 result = skyResult.rgb;

    float dist = skyResult.w;
    
    float fogFactor = 1.0 - exp( dist * -env.skyFogDensity );
    result = mix ( result, env.fogCol, fogFactor );
    return result; 
}

vec3 GetInscatter( EnvironmentSettings env, float heading, float cosRefract, vec3 extinction )
{
    // hardcode LUT
    vec3 result = vec3(0.0, 0.0, 0.0);

    // some average sky color
    vec3 skyCol = (env.skyHorizonCol * 3.0f + env.skyZenithCol * 1.0f) / 4.0f;       

    // Parameters:
    float lightIntensity = 0.07f; // overall intensity of result - don't just rely on extinction to darken color
    float scatteringScale = 40.0f;
    float scatteringOffset = 4.0f;
    ///////


    float cosSunHeading = cos( heading - env.sunHeading );

    float spread = -0.5 -cosRefract * 1.5; // wrap sunlight more with "depth"

    float sunIntensityX = cosSunHeading * ( 1.0f - spread ) + spread;
    sunIntensityX = max( 0.0f, sunIntensityX );

    float sunIntensityY = max( 0.0f, -cosRefract );


    float sunIntensity = sunIntensityX * sunIntensityX + sunIntensityY * sunIntensityY;
    sunIntensity *= (1.0 + cosRefract) * 8.0; // decrease sun intensity with "spread"

    vec3 light = env.sunLightCol * sunIntensity + skyCol;

    light *= lightIntensity;        

    float dist = (cosRefract * cosRefract) * scatteringScale + scatteringOffset;

    result.rgb = light * (exp( dist * -extinction)); // could be exp2 if we change scatteringScale and scatteringOffset values

    return result;
}

float GIV( float dotNV, float k)
{
	return 1.0 / ((dotNV + 0.0001) * (1.0 - k)+k);
}


vec4 GetSandCol( vec3 pos, float mipLod )
{
    vec3 textureSample = textureLod( iChannel1, pos.zx * 2.0, mipLod ).rgb;
    textureSample = textureSample * textureSample;

    // darker, browner sand
    vec3 sandColA = vec3( 0.9f, 0.63f, 0.4f );
    sandColA = sandColA * sandColA;
    
    // ligher, whiter sand
    vec3 sandColB = vec3( 1.0f, 0.8f, 0.6f );
    sandColB = sandColB * sandColB;    
    
    // todo - pass in sand type factor - define regions somewhere
    
    float blendFactor = smoothstep(1.2, 2.0, pos.y);
        
	vec3 sandCol = mix( sandColA, sandColB, blendFactor );
    
    //float rockFactor = clamp(-pos.y +textureSample.g * 0.75 + 0.25 + 0.0, 0.0, 1.0);
    
    vec2 heights = Terrain_GetHeights( iChannelRockTexture, pos.xz, true );
        
    float rockFactor = clamp( (heights.y - heights.x + 0.01) * 500.0, 0.0f, 1.0 );
    
#if EQUIRECTANGULAR_PROJECTION    
    rockFactor = 0.0;
#endif       
    
    sandCol = mix( sandCol, textureSample, rockFactor );
    
    //vec3 textureSampleB = textureLod( iChannel1, uv * 10.0, mipLod ).rgb;
    //sandCol *= (textureSample.g * 0.5 + textureSampleB.r * 0.5);
    
    return vec4( sandCol, rockFactor );
    /*
    col = col * col;            
    
    float rawCol = col.r;
    
    float fade = clamp( 0.5 + pos.y, 0.0f, 1.0);
	fade = 0.3 + fade * 0.6f;
    
    col = col * (1.0f - fade) + fade;
    col *= vec3( 1.0f, 0.85f, 0.5f );
    
    return vec4( col, rawCol );
    */
}

vec3 WaterCaustics( EnvironmentSettings env, vec3 pos )
{    
    //return sunLightCol; // no caustics
    
    float h = Water_GetWaves( pos.xz, 3, iTime * 3.0 );
    float i = 0.5f + 0.7f * h * h;
    return env.sunLightCol * i;
}

vec3 GetSceneColour( EnvironmentSettings env, vec3 rayOrigin, vec3 rayDir, out float sceneDist )
{
    vec3 result = vec3(0);

    float wetDiffuseFactor = 0.5;
    
    int waterOctaves = 3;
    MapTraceResult mapTrace = Map_Trace( rayOrigin, rayDir, waterOctaves, false );
    
    if ( mapTrace.dist < 0.0 )
    {        
        result.rgb = GetSkyColour( env, rayOrigin, rayDir, 0.0f, true );
        sceneDist = 10000.0;
    }
    else
    if ( mapTrace.dist >= 0.0 )
    {        
        sceneDist = mapTrace.dist;
        
        vec3 hitPos = rayOrigin + rayDir * mapTrace.dist;
        vec3 normal = Map_GetNormal( hitPos );
                

        float vR0 = 0.02f;
        
        float roughness = 0.0002f;

        vec3 albedo = vec3(1);
        float transparency = 1.0f;
        vec3 colTransmitted = vec3(0);
        
        if ( mapTrace.objectId == 1 )
        {
            vec3 waterExtinction = GetExtinction( hitPos.xz );
            {
                
                float terrainHeight = Terrain_GetHeight( iChannelRockTexture, hitPos.xz, false, true );
                
                float water_terrain_dh = hitPos.y - terrainHeight;
                
                float foamAmount = clamp( 1.0 - water_terrain_dh * (1.0f / 0.5f), 0.0f, 1.0f );
                foamAmount = foamAmount * foamAmount;
                
				float waveFactor = GetShorelineWaves( hitPos.xz, water_terrain_dh ).y;
                
                foamAmount = max( foamAmount, waveFactor );

                vec2 foamMapUV = hitPos.xz; //mix(hitPos.xz, refractHitPos.xz, 0.25);
                foamMapUV = foamMapUV * 20.0 + water_terrain_dh * 100.0;
                
                
	            //normal.xz += (SmoothNoise2( foamMapUV * 2.0) * 2.0f - 1.0f) * foamAmount * 0.2;
                //normal = normalize( normal );
                
	            vec3 rayRefracted = refract( rayDir, normal, 1.0f / 1.3333f );
                
                
                
                MapTraceResult refractTrace = Map_Trace( hitPos, rayRefracted, 0, false );
                vec3 refractHitPos = hitPos + rayRefracted * refractTrace.dist;
                
                float dh = refractHitPos.y - hitPos.y;

                vec3 diffuseCol = GetSandCol( refractHitPos, (log( refractTrace.dist )+1.) * 4.0).rgb;
                
                diffuseCol *= wetDiffuseFactor;

                vec3 seabedLighting = WaterCaustics( env, refractHitPos );
                
                float seabedNdotL = env.sunDir.y;
                vec3 diffuseLight  = seabedNdotL * seabedLighting * exp( (-dh / -env.sunDir.y) * waterExtinction );
                
                diffuseLight += env.ambientCol * exp( dh * waterExtinction );
                                
                colTransmitted = diffuseLight * diffuseCol;
                
                vec3 extinction = exp( (-refractTrace.dist ) * waterExtinction );

                
                colTransmitted *= extinction;  

                {
                    float inscatterFactor = clamp( 1.0 - rayRefracted.y, 0.0f, 1.0f );

                    //vec3 inscatterScale =  exp( -inscatterFactor * waterExtinction * inscatterScaleFactor );

                    float lookupU = atan(rayRefracted.x, rayRefracted.z);
                             

                    float lookupV = clamp( -rayRefracted.y, 0.0f, 1.0f);
                    vec3 inscatterScale = GetInscatter( env, lookupU, lookupV, waterExtinction );
					colTransmitted += inscatterScale;
                }
            //}
            
				//colTransmitted *= RadianceChange( IOR_AIR, IOR_WATER );                
	            //colTransmitted *= RadianceChange( IOR_WATER, IOR_AIR );
                
            //{

                
                //float foam = SmoothNoise2( foamMapUV ).x;
                vec2 foamSampleUV = foamMapUV * 0.005 + iTime * 0.1;
                vec4 foamSample = texture( iChannel1, foamSampleUV, 0.0 );
                float foam = foamSample.x;
                
                
                foam = 1.f - foam;
                foam = 1.f - foam* foam;
                
                float foamFactor = foamAmount * 0.8f;
                
                foamFactor = max( 0.0, foamFactor - foam * (1.0f - foamFactor));
                
                //foamFactor *= 0.25 + 0.75 * SmoothNoise2( hitPos.xz * 10000.0 ).x;
                                
                float foamThicknessFactor = 1.0;
                //if ( abs( dh ) < 0.02 ) { foamThicknessFactor = 0.5; }
                
                // foam shadow
                colTransmitted *= 1.0 - foamFactor * foamThicknessFactor;
                
                // foam bubbles
                //colTransmitted += diffuseLight * exp( -foamAmount * waterExtinction * 10.0 ) * foamSample.b * 0.2;
                
                //albedo = vec3( SmoothNoise2( hitPos.xz * 10000.0 ).x * 0.5 + 0.5 );
                albedo = vec3( 1.0f );
                
                normal.x += (foamSample.x - texture( iChannel1, foamSampleUV - vec2(0.2, 0), 0.0 ).x) * foamFactor * 0.4;
                normal.z += (foamSample.x - texture( iChannel1, foamSampleUV - vec2(0, 0.2), 0.0 ).x) * foamFactor * 0.4;
                normal = normalize( normal );
                
                
                transparency = 1.0 - foamFactor * foamThicknessFactor;                                
                roughness = mix( roughness, 0.3f, foamFactor * foamFactor );                
            }            
        }
        else
        {
            vec3 mapPos = rayOrigin + rayDir * mapTrace.dist;
            
            vec4 sandColSample = GetSandCol( mapPos, 0.0f );
            albedo = sandColSample.rgb;
            transparency = 0.0f;
            
            float wetness = 0.0f;
            
            vec2 noiseLow = SmoothNoise22(mapPos.xz * 0.2);

            roughness = 1.0f - sandColSample.a * (0.5 + sandColSample.r * 0.5);
            
            //float roughnessHeight = smoothstep( 2.0, 1.2, mapPos.y );            
            //roughness = mix( roughness, noiseLow.y * 0.08, roughnessHeight );
            
#if 1
            
            
            //float wetRoughness = mix( 2.0f, 1.2f, noiseLow.x );
            float wetnessHeightFactor = smoothstep( 1.5, 0.6, mapPos.y );
            float wetnessHeight = mix( wetness, 0.8+noiseLow.x * 0.2, wetnessHeightFactor);
            
            wetness = max( wetness, wetnessHeight );
                        
                        
                                                
#endif      
            
	        float waterOldHeight = Water_GetHeight(mapPos.xz, 2, iTime - 0.05 );                        
            float wetnessShorline = smoothstep( 0.4, 0.0, mapPos.y - waterOldHeight);
            
            wetnessShorline *= 1.0;
                
            wetness = max( wetness, wetnessShorline );
            
            
            roughness = mix ( roughness, 0.001, wetness );            
            albedo *= (1.0 - wetness ) * (1.0f - wetDiffuseFactor) + wetDiffuseFactor;
            
            //albedo = clamp( albedo + max(0.0f, wetnessShorline - 0.9), 0.0, 1.0); // attempt to hack persistent foam
        }

        vec3 h = normalize( -rayDir + env.sunDir );
        float NdotL = max( 0.0f, dot( normal, env.sunDir ) );
        float NdotH = dot( h, normal );
        float NdotV = dot( rayDir, normal );
               
        vec3 diffuseIntensity = (NdotL * env.sunLightCol + env.ambientCol) * albedo;

        colTransmitted = mix( diffuseIntensity, colTransmitted, transparency );
        
        roughness = roughness * 0.995 + 0.005;
        
        float gloss = (1.0f - roughness);
        float glossFactor = pow( gloss, 20.0 );
        
        vec3 rayReflected = reflect( rayDir, normal );
        
        vec3 colReflected = GetSkyColour( env, hitPos, rayReflected, glossFactor * 16.0, false );
        
        {
			float alpha = roughness;
            float alphaSqr = alpha * alpha;
            float denom = NdotH * NdotH * (alphaSqr - 1.0) + 1.0f;
            float k = alpha / 2.0;
            float vis = GIV(NdotL, k) * GIV(NdotV, k);
            float f = alphaSqr / (PI * denom * denom);
            colReflected += f * NdotL * env.sunLightCol;
        }
        
        
        {
            float NdotV = max( 0.0, dot( rayDir, -normal ) );

            vec3 fresnel = vR0 + (vec3(1.0) - vR0) * pow( 1.0 - NdotV, 5.0 ) * glossFactor;

            result.rgb = mix( colTransmitted, colReflected, fresnel );
        }            
        
    
        float dist = mapTrace.dist;
        float fogFactor = 1.0 - exp( dist * -env.fogDensity );
        result.rgb = mix ( result.rgb, env.fogCol, fogFactor );
	}

    vec3 sunGlow = GetSunGlow( env, rayDir );
    result.rgb += sunGlow;

    return result;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{       
    vec2 uv = fragCoord.xy / iResolution.xy;;

    CameraState cam;
	Cam_LoadState( cam, iChannelState, ivec2(0,0) );
    
    // Trace Scene
    float fAspectRatio = iResolution.x / iResolution.y;            
    
    vec3 rayOrigin, rayDir;
    vec2 vJitterUV = uv + cam.vJitter / iResolution.xy;
    Cam_GetCameraRay( vJitterUV, fAspectRatio, cam, rayOrigin, rayDir );    

	EnvironmentSettings env = GetEnvironmentSettings();
    
    float dist;
    vec3 sceneColor = GetSceneColour( env, rayOrigin, rayDir, dist );
    
    fragColor = vec4(sceneColor,dist);
}
