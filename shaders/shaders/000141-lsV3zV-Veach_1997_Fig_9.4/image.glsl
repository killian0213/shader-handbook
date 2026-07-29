// Image (image) — Veach 1997 Fig 9.4 by mplanck
// https://www.shadertoy.com/view/lsV3zV

// Final gather 

// INPUTS

// 1 := select brdf importance sampling only
// 2 := select light importance sampling only
// 3 := select multiple importance sampling
// 4 := turn on green coloring of brdf importance samples, red coloring of light importance samples
// SPACE := reset to no coloring and multiple importance sampling

// **************************************************************************
// GLOBALS

float g_frame = 0.;

void setup_globals()
{
    g_frame = float(iFrame) - texture(iChannel1, vec2(0., 0.), -100.).r ;
}

// **************************************************************************
// MAIN COLOR

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    setup_globals();
    vec2 uv = fragCoord.xy / iResolution.xy;
        
    vec3 scol = vec3(0.);
    if (g_frame > .5)
    {
		scol = texture( iChannel0, uv ).xyz;
        scol /= g_frame;
        scol = pow( scol, vec3(0.4545) );
    }
    
    fragColor = vec4(scol, 1.0);
}