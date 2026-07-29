// Buffer A (buffer) — Inky by huwb
// https://www.shadertoy.com/view/4d3SD8

// sorry this is a mess right now! i will write up a blog post about what the code
// below was written to do and update this later.

float ten_r = 0.04;

float GetAngle( float i, float t )
{
    //float amp = .75; //.25 is subtle wriggling
	//t += amp*sin(1.*t + 4.*iTime + float(i));
    float dir = mod(i,2.) < 0.5 ? 1. : -1.;
    return dir * (1./(.5*i+1.)+1.) * t + i/2.;
}

#define POS_CNT 5
vec2 pos[POS_CNT];

float Potential( int numNodes, vec2 x )
{
    if( numNodes == 0 ) return 0.;
    
    float res = 0.;
    float k = 16.;
    for( int i = 0; i < POS_CNT; i++ )
    {
        if( i == numNodes ) break;
        res += exp( -k * length( pos[i]-x ) );
    }
    return -log(res) / k;
}

void ComputePos_Soft( float t )
{
    for( int i = 0; i < POS_CNT; i++ )
    {
        float a = GetAngle( float(i), t );
        vec2 d = vec2(cos(a),sin(a));
        float r = ten_r;
        
        for( int j = 0; j < 3; j++ )
        {
            r += ten_r-Potential(i,r*d);
        }
        
        pos[i] = r * d;
    }
}


vec3 drawSlice( vec2 uv )
{
    float t = iTime/2.;
    ComputePos_Soft(t);
    float pot = Potential(POS_CNT,uv);
    return vec3(smoothstep(0.03,0.01,pot));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    // sample from previous frame, with slight offset for advection
    fragColor = textureLod( iChannel0, uv*.992, 0. );
    
    // clear on first frame (dont know if this is required)
    if( iFrame == 0 ) fragColor = vec4(0.);
    
    // camera
    uv.x += .1*sin(.7*iTime);
    uv.y += .05*sin(.3*iTime);
    uv = 2. * uv - 1.;
    uv.x *= iResolution.x/iResolution.y;
    
    // draw spots
    vec3 spots = drawSlice( uv );
    
    // accumulate
    fragColor.rgb = fragColor.rgb*.95 + spots;
}
