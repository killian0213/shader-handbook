// Buffer A (buffer) — Basic Montecarlo by iq
// https://www.shadertoy.com/view/MsdGzl

// Pathtrace the scene. One path per pixel. Samples the sun light
// and the sky dome light at each vertex of the path.
//
// More info: https://iquilezles.org/articles/simplepathtracing

//------------------------------------------------------------------
// oldschool rand() from Visual Studio
//------------------------------------------------------------------
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
//------------------------------------------------------------------
vec3 cosineDirection( in vec3 nor)
{
    float u = frand();
    float v = frand();

    // Method 1 and 2 first generate a frame of reference to use
    // with an arbitrary distribution, cosine in this case.
    // Method 3 (invented by fizzer) specializes the whole math to
    // the cosine distribution and simplifies the result to a more
    // compact version that does not even need constructing a frame
    // of reference.

    #if 0
        // method 1 by http://orbit.dtu.dk/fedora/objects/orbit:113874/datastreams/file_75b66578-222e-4c7d-abdf-f7e255100209/content
        vec3 tc = vec3( 1.0+nor.z-nor.xy*nor.xy, -nor.x*nor.y)/(1.0+nor.z);
        vec3 uu = vec3( tc.x, tc.z, -nor.x );
        vec3 vv = vec3( tc.z, tc.y, -nor.y );
        float a = 6.2831853*v;
        return sqrt(u)*(cos(a)*uu + sin(a)*vv) + sqrt(1.0-u)*nor;
    #endif
	#if 0
                               
    	// method 2 by pixar: https://graphics.pixar.com/library/OrthonormalB/paper.pdf or http://jcgt.org/published/0006/01/01/paper.pdf
    	float ks = (nor.z>=0.0)?1.0:-1.0;     //do not use sign(nor.z), it can produce 0.0
        float ka = 1.0 / (1.0 + abs(nor.z));
        float kb = -ks * nor.x * nor.y * ka;
        vec3 uu = vec3(1.0 - nor.x * nor.x * ka, ks*kb, -ks*nor.x);
        vec3 vv = vec3(kb, ks - nor.y * nor.y * ka * ks, -nor.y);
        float a = 6.2831853 * v;
        return sqrt(u)*(cos(a)*uu + sin(a)*vv) + sqrt(1.0-u)*nor;
    #endif
    #if 1
    	// method 3 by fizzer: http://www.amietia.com/lambertnotangent.html
        float a = 6.2831853*v; float b = 2.0*u-1.0;
        vec3 dir = vec3(sqrt(1.0-b*b)*vec2(cos(a),sin(a)),b);
        return normalize( nor + dir );
    #endif
}
vec3 uniformVector(void)
{
    float phi = frand()*6.28318530718;
    float x = frand()*2.0-1.0;
    float z = frand();
	return pow(z,1.0/3.0)*vec3(sqrt(1.0-x*x)*vec2(sin(phi),cos(phi)),x);
}
    
//------------------------------------------------------------------

float sdBox( vec3 p, vec3 b )
{
  vec3  di = abs(p) - b;
  float mc = max(di.x,max(di.y,di.z));
  return min(mc,length(max(di,0.0)));
}

vec2 map( vec3 p )
{
    vec3 w = p;
    vec3 q = p;

    q.xz = mod( q.xz+1.0, 2.0 ) -1.0;
    
    float d = sdBox(q,vec3(1.0));
    float s = 1.0;
    for( int m=0; m<6; m++ )
    {
        float h = float(m)/6.0;

        p =  q - 0.5*sin( abs(p.y) + float(m)*3.0+vec3(0.0,3.0,1.0));

        vec3 a = mod( p*s, 2.0 )-1.0;
        s *= 3.0;
        vec3 r = abs(1.0 - 3.0*abs(a));

        float da = max(r.x,r.y);
        float db = max(r.y,r.z);
        float dc = max(r.z,r.x);
        float c = (min(da,min(db,dc))-1.0)/s;

        d = max( c, d );
   }

   vec2 res = vec2(d,1.0);
    
   {
   d = length(w-vec3(0.22,0.35,0.4)) - 0.09;
   if( d<res.x ) res=vec2(d,2.0);
   }
   
   {
   d = w.y + 0.22;
   if( d<res.x ) res=vec2(d,3.0);
   }
    
   return res;
}

//------------------------------------------------------------------

vec3 calcNormal( in vec3 pos )
{
    const vec2 eps = vec2(0.0001,0.0);
    return normalize( vec3(
      map( pos+eps.xyy ).x - map( pos-eps.xyy ).x,
      map( pos+eps.yxy ).x - map( pos-eps.yxy ).x,
      map( pos+eps.yyx ).x - map( pos-eps.yyx ).x ) );
}

vec2 intersect( in vec3 ro, in vec3 rd )
{
    vec2 res = vec2(-1.0,-1.0);
    float tmax = 16.0;
    float t = 0.01;
    for(int i=0; i<128; i++ )
    {
        vec2 h = map(ro+rd*t);
        res = vec2(t,h.y);
        if( h.x<0.0001 || t>tmax ) break;
        t += h.x;
    }
    
    if( t>tmax ) res.x = -1.0;;

    return res;
}

float shadow( in vec3 ro, in vec3 rd )
{
    float res = 0.0;
    
    float tmax = 12.0;
    
    float t = 0.001;
    for(int i=0; i<80; i++ )
    {
        float h = map(ro+rd*t).x;
        if( h<0.0001 || t>tmax) break;
        t += h;
    }

    return (t<tmax) ? res : 1.0;
}

const float epsilon = 0.0001;
vec3 light( vec3 surfColor, float surfSpecN, bool surfIsMetal,
            vec3 pos, vec3 nor, vec3 rd, 
            vec3 ligDir, vec3 ligColor )
{
    vec3 fo = (!surfIsMetal) ? vec3(0.04) : surfColor;

    vec3  hal = normalize(ligDir-rd);
    float dif = max(0.0, dot(ligDir, nor));
    float sha = 1.0; if( dif > 0.00001 ) sha = shadow( pos + nor*epsilon, ligDir);
    float spe = (surfSpecN+0.0)/8.0*pow(clamp(dot(nor,hal),0.0,1.0),surfSpecN);
    vec3  fre = fo + (1.0-fo)*pow(clamp(1.0-dot(hal,ligDir),0.0,1.0),5.0);
    
    vec3 res = vec3(0.0);

    if( !surfIsMetal )
    res += surfColor * ligColor * dif * sha;
    res +=             ligColor * dif * sha * spe * fre * 3.0;
    return res;
}

const vec3 sunDir = normalize(vec3(-0.3,1.3,0.1));
const vec3 sunCol = 12.0*vec3(1.1,0.8,0.6);
const vec3 skyCol = 6.0*vec3(0.2,0.5,0.8);

vec3 calculateColor(vec3 ro, vec3 rd )
{
    vec3 colorMask = vec3(1.0);
    vec3 accumulatedColor = vec3(0.0);

    float fdis = 0.0;
    for( int bounce = 0; bounce<4; bounce++ ) // bounces of GI
    {
        //rd = normalize(rd);
       
        //-----------------------
        // trace
        //-----------------------
        vec2 tm = intersect( ro, rd );
        float t = tm.x;
        if( t < 0.0 )
        {
            if( bounce==0 ) return mix( 0.1*vec3(0.8,0.9,1.0), skyCol, smoothstep(0.05,0.1,rd.y) );
            break;
        }

        if( bounce==0 ) fdis = t;

        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal( pos );
        
        //-----------------------
        // material
        //-----------------------

        vec3  surfColor;
        float surfSpecN;
        bool  surfIsMetal;
        if( tm.y<1.5 )
        {
        surfColor= vec3(0.38)*vec3(1.2,0.8,0.6);
        surfIsMetal = false;
        surfSpecN = 8.0;
        }
        else if( tm.y<2.5 )
        {
        //surfColor = vec3(0.37);
        surfColor = vec3(0.9,0.8,0.5);
        surfIsMetal = true;
        surfSpecN = 2000.0;
        }
        else //if( tm.y<2.5 )
        {
        surfColor = vec3(0.38)*vec3(1.2,0.8,0.6);
        surfIsMetal = false;
        surfSpecN = 8.0;
        }


        //-----------------------
        // sample light sources
        //-----------------------

        // light 1 : sun
        accumulatedColor += light(surfColor*colorMask,surfSpecN,surfIsMetal,
                                  pos,nor,rd,
                                  sunDir, sunCol );

        // light 2 : sky
        #if 0
        // sample sky uniformly
        vec3 skyDir = uniformVector();
        if( skyDir.y<0.0 ) skyDir=-skyDir;
        accumulatedColor += light(surfColor*colorMask,surfSpecN,surfIsMetal,
                                  pos,nor,rd,
                                  skyDir, skyCol )*3.1415;
        #else
        // sample sky cosine weighted
        vec3 skyDir = cosineDirection(nor);
        if( skyDir.y<0.0 ) skyDir=-skyDir;
        accumulatedColor += light(surfColor*colorMask,surfSpecN,surfIsMetal,
                                  pos,nor,rd,
                                  skyDir, skyCol )/(dot(nor,skyDir)+0.00001);
        #endif                          

        //---------------------------------
        // bounce and gather indirect light
        //---------------------------------
        
        if( surfIsMetal )
        {
            // TODO: I feel need to multiply colorMask by fresnel
            colorMask *= surfColor;
            float glo = clamp(1.0-surfSpecN/2048.0,0.0,1.0);
            glo = glo*glo;
            rd = normalize(reflect(rd,nor)) + glo*uniformVector();
        }
        else
        {
            //float isDif = 1.0;
            //if( frand() < isDif )
            {
               colorMask *= surfColor;
               rd = cosineDirection(nor);
            }
            //else
            //{
            //    float glo = clamp(1.0-surfSpecN/2048.0,0.0,1.0);
            //    glo = glo*glo;
            //    rd = normalize(reflect(rd,nor)) + glo*uniformVector();
           // }
        }
        ro = pos;
   }

   float ff = exp2(-0.2*fdis);
   accumulatedColor *= ff; 
   accumulatedColor += (1.0-ff)*(1.0-ff)*0.1*vec3(0.8,0.9,1.0);


   
   
   return accumulatedColor;
}

mat3 setCamera( in vec3 ro, in vec3 rt, in float cr )
{
	vec3 cw = normalize(rt-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, -cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // init randoms
    srand( ivec2(fragCoord), iFrame );

    
    vec2 of = -0.5 + vec2( frand(), frand()  );
    vec2 p = (2.0*(fragCoord+of)-iResolution.xy)/iResolution.y;

    vec3 ro = vec3(0.0,0.0,0.0);
    vec3 ta = vec3(1.5,0.7,1.5);

    mat3  ca = setCamera( ro, ta, 0.0 );
    vec3  rd = normalize( ca * vec3(p,-1.3) );

    vec4 data = texture( iChannel0, fragCoord/iResolution.xy );
    if( iFrame==0 ) data = vec4(0.0);
    
    data += vec4( calculateColor( ro, rd ), 1.0 );

    fragColor = data;
}