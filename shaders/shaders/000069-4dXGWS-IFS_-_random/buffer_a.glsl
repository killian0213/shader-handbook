// Buffer A (buffer) — IFS - random by iq
// https://www.shadertoy.com/view/4dXGWS

// Created by inigo quilez - iq/2013
// I share this piece (art and code) here in Shadertoy and through its Public API, only for educational purposes. 
// You cannot use, sell, share or host this piece or modifications of it as part of your own commercial or non-commercial product, website or project.
// You can share a link to it or an unmodified screenshot of it provided you attribute "by Inigo Quilez, @iquilezles and iquilezles.org". 
// If you are a teacher, lecturer, educator or similar and these conditions are too restrictive for your needs, please contact me and we'll work it out.


// Random linear IFS fractal (4 affine transforms) inverted and
// twisted. Very noisy due to the low iteration count (rendering
// approach is brute force gathering).
//
// Some more information:
// https://iquilezles.org/articles/ifsfractals/ifsfractals.htm[/url]
//
// Because WebGL cannot scatter data to a buffer, a gather approach
// is used to colorize the pixels, which is millions of times slower
// than it should. Because of that only a very few iterations are
// performed, and the image is very noisy. So I used a temporal
// accumulation trick to smooth the image out,but that introduces
// blurring. You cannot have it all, not until we have scatter
// operations in WebGL, that is.


// oldschool rand() from Visual Studio
int   seed = 1;
void  srand(int s ) { seed = s; }
int   rand(void) { seed = seed*0x343fd+0x269ec3; return (seed>>16)&32767; }
float frand(void) { return float(rand())/32767.0; }
// hash to initialize the random sequence (copied from Hugo Elias)
int   hash( int n ) { n=(n<<13)^n; return n*(n*n*15731+789221)+1376312589; }

// ensure determinant is less than 0.4
mat3x2 fixDet( in mat3x2 m, out float w )
{
    mat2x2 r = mat2x2( m[0][0], m[0][1], m[1][0], m[1][1] );
    w = abs(determinant(r));
    if( w>0.4 )
    {
        float s = 0.4/w;
        w *= s;
        m[0][0] = r[0][0]*s;
        m[0][1] = r[0][1]*s;
        m[1][0] = r[1][0]*s;
        m[1][1] = r[1][1]*s;
    }
    return m;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // init randoms
    ivec2 q = ivec2(fragCoord);
    srand( hash(q.x+hash(q.y+hash(iFrame))) );

    // create ifs
	float t = 0.02*iTime;

	mat3x2 am = mat3x2( cos(t*1.71+0.18), cos(t*1.11+5.31), 
                        cos(t*1.31+3.18), cos(t*1.44+4.21),
                        cos(-t*2.13+0.94), cos(-t*1.19+0.29) );
                      
	mat3x2 bm = mat3x2( cos(-t*2.57+1.66), cos(t*1.08+0.74), 
                        cos(t*1.31+4.51), cos(t*1.23+1.29),
                        cos(t*1.09+5.25), cos(t*1.27+1.77) );
                        
	mat3x2 cm = mat3x2( cos(t*1.75+0.33), cos(t*1.74+5.12), 
                        cos(t*2.94+1.92), cos(t*2.58+2.36),
                        cos(t*2.76+2.39), cos(t*2.35+2.04) );
                        
	mat3x2 dm = mat3x2( cos(t*1.42+4.89), cos(t*1.14+1.94),
                        cos(t*2.73+6.34), cos(-t*1.21+4.84),
                        cos(-t*1.42+4.71), cos(t*2.81+3.51) );

    // ensure all transformations are contracting, by checking
    // the determinant and inverting the top 2x2 matrix if it
    // is less than 1
    
    float ad, bd, cd, dd;
    am = fixDet(am, ad);
    bm = fixDet(bm, bd);
    cm = fixDet(cm, cd);
    dm = fixDet(dm, dd);

    // compute probability for each transformation
    float wa = (ad         ) / (ad+bd+cd+dd);
    float wb = (ad+bd      ) / (ad+bd+cd+dd);
    float wc = (ad+bd+cd   ) / (ad+bd+cd+dd);
    float wd = (ad+bd+cd+dd) / (ad+bd+cd+dd);

    // render ifs
    float zoom = 0.5+0.5*sin(iTime*0.1);
    vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.y;
	uv *= 3.0*exp2(-zoom);


	vec3  cola = vec3(0.0);
	vec3  colb = vec3(0.0);
    float colw = 0.0;
	float cad = 0.0;

    vec2 z = vec2( 0.0 );
	const int num = 1024;
	for( int i=0; i<num; i++ ) 
    {
		float p = frand();

        // affine transform
        cad *= 0.25;
             if( p < wa ) { z = am*vec3(z,1.0); cad += 0.00; }
        else if( p < wb ) { z = bm*vec3(z,1.0); cad += 0.25; }
        else if( p < wc ) { z = cm*vec3(z,1.0); cad += 0.50; }
        else              { z = dm*vec3(z,1.0); cad += 0.75; }

        // non linear transform
        float an = length(z)*0.25;
        vec2 c = vec2( cos(an), sin(an) );
        z = 2.0*mat2(c.x,c.y,-c.y,c.x)*z/dot(z,z);

        // splat into screen
        if( i>10 )
		{
        vec3  co = 0.5 + 0.5*sin(1.5*cad + vec3(0.5,2.0,2.0)+2.0);
        co.z += co.y*(1.0*sin(cad*3.0+3.0));
        co = clamp(co,0.0,1.0);
    
        float d2 = dot(uv-z,uv-z)*4.0;
        cola += co*exp2( -8192.0*d2 );
        colb += co*exp2(  -128.0*d2 );
        colw += exp2( -256.0*d2 );
		}
	}
    cola/=float(num);
    colb/=float(num);
    colw/=float(num);
    
    // color
    cola = 256.0*sqrt(cola);
    colb =   2.0*sqrt(colb);
    colw = 64.0*sqrt(colw);
    vec3 col = cola + colb;
    
    // auto-gain
    col *= 3.0/(1.0+col);
    col = clamp(col,0.0,1.0);
    colw = clamp(colw,0.0,1.0);
   
    vec4 old = texelFetch( iChannel0, ivec2(fragCoord), 0 );

	fragColor = mix( old, vec4(col,colw), 0.1 );
}
