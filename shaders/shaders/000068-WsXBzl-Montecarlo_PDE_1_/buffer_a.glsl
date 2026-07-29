// Buffer A (buffer) — Montecarlo PDE (1) by iq
// https://www.shadertoy.com/view/WsXBzl

// Playing with Keenan Crane's latest paper in collab with
// Rohan Sawhney
//
// http://www.cs.cmu.edu/~kmcrane/Projects/MonteCarloGeometryProcessing/paper.pdf[/url]
//

// https://iquilezles.org/articles/distfunctions
vec4 sdLine( in vec2 p, in vec2 a, in vec2 b, in vec3 ca, in vec3 cb )
{
    vec2 pa = p-a;
    vec2 ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba),0.0,1.0);
    float d = length(pa-h*ba);
    float s = step(0.0,pa.x*ba.y-pa.y*ba.x);
    return vec4(d, mix(ca,cb,s)*smoothstep(-0.1,0.1,sin(50.0*h)) );
}

// sdf map
vec4 map( in vec2 p )
{
    vec4 d  = sdLine(p, vec2(-1.0,0.4), vec2(1.1,-0.1), vec3(1.0,0.4,0.1),vec3(0.2,0.5,0.8) )-0.05;
    vec4 d2 = sdLine(p, vec2(-0.3,0.8), vec2(0.2,-0.6), vec3(1.0,1.0,0.2), vec3(0.1,0.7,0.3) )-0.05;
    if( d2.x<d.x ) d = d2;
    
    return d;
}


// --------------------------------------
// oldschool rand() from Visual Studio
// --------------------------------------
int   seed = 1;
int   rand(void) { seed = seed*0x343fd+0x269ec3; return (seed>>16)&32767; }
float frand(void) { return float(rand())/32767.0; }
void  srand( ivec2 p, int frame )
{
    int n = frame;
    n = (n<<13)^n; n=n*(n*n*15731+789221)+1376312589; // by Hugo Elias
    n += p.y;
    n = (n<<13)^n; n=n*(n*n*15731+789221)+1376312589;
    n += p.x;
    n = (n<<13)^n; n=n*(n*n*15731+789221)+1376312589;
    seed = n;
}

// --------------------------------------

vec2 randomInCircle( void )
{
    float an = 6.283185*float(rand())/32767.0;
    return vec2(cos(an),sin(an));
}
    
// WoS
vec3 march( in vec2 p )
{
    vec4 h=vec4(0.0);
	for( int i=0; i<32; i++ )
    {
        h = map(p);
        if( h.x<0.001 ) break;
        p = p + h.x*randomInCircle();
    }
    return h.yzw;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	// init randoms
    srand( ivec2(fragCoord), iFrame );

    // solve
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec3 col = march(p);

    // display map()
    #if 0
    vec4 dcol = map(p);
    float f = 1.0-smoothstep(0.0,0.01,dcol.x);
    col = mix(col,dcol.yzw,f);
    col *= smoothstep(0.0,0.01,abs(dcol.x));
    #endif

    // montecarlo
    vec4 data = texelFetch(iChannel0,ivec2(fragCoord),0);
    fragColor = data + vec4(col,1.0);
}