// Image (image) — Light Propagation Volume by paniq
// https://www.shadertoy.com/view/XdtSRn

/*

after
Light Propagation Volumes in CryEngine 3, Anton Kaplanyan
http://advances.realtimerendering.com/s2009/Light_Propagation_Volumes.pdf

also helpful for reference:
Light Propagation Volumes - Annotations, Andreas Kirsch (2010)
http://blog.blackhc.net/wp-content/uploads/2010/07/lpv-annotations.pdf

*/

vec4 sample_lpv(vec3 p, float channel) {
    p = clamp(p * lpvsize, vec3(0.5), lpvsize - 0.5);
    float posidx = packfragcoord3(p, lpvsize) + channel * (lpvsize.x * lpvsize.y * lpvsize.z);
    vec2 uv = unpackfragcoord2(posidx, iChannelResolution[0].xy) / iChannelResolution[0].xy;
    return texture(iChannel0, uv);    
}

vec4 fetch_lpv(ivec3 p, int channel) {
    p = clamp(p, ivec3(0), lpvsizei - 1);
    int posidx = packfragcoord3(p, lpvsizei) + channel * (lpvsizei.x * lpvsizei.y * lpvsizei.z);
    ivec2 uv = unpackfragcoord2(posidx, ivec2(iChannelResolution[0].xy));
    return texelFetch(iChannel0, uv, 0);    
}

vec3 fetch_lpv(ivec3 p, vec4 shn) {
    vec4 shr = fetch_lpv(p, 0);
    vec4 shg = fetch_lpv(p, 1);
    vec4 shb = fetch_lpv(p, 2);
    return vec3(
        shade_probe(shr, shn),
        shade_probe(shg, shn),
        shade_probe(shb, shn));
}

float dot_weight(vec3 a, vec3 b) {
	a = vec3(
        (a.x + a.y)*0.5,
        a.y,
        (a.y + a.z)*0.5);
    return dot(a, b);
}

vec3 interpolate(vec3 a, vec3 b, vec3 c, float x) {
	float rx = 1.0 - x;
    vec3 q = vec3(
        rx*rx, 
        2.0*rx*x,
    	x*x);
    return
        vec3(
            dot_weight(vec3(a.x,b.x,c.x), q),
            dot_weight(vec3(a.y,b.y,c.y), q),
            dot_weight(vec3(a.z,b.z,c.z), q));
}

void sample_lpv_nn(vec3 pf, out vec4 r, out vec4 g, out vec4 b) {
    // use triquadratic interpolation
    pf = pf * lpvsize;
    ivec3 p = ivec3(pf + 0.5);
    r = fetch_lpv(p, 0);
    g = fetch_lpv(p, 1);
    b = fetch_lpv(p, 2);    
}

vec3 sample_lpv_trilin(vec3 pf, vec4 shn) {
#if USE_TRIQUADRATIC_INTERPOLATION
    // use triquadratic interpolation
    pf = pf * lpvsize;
    ivec3 p = ivec3(pf);
    ivec3 e = ivec3(-1, 0, 1);
    vec3 p000 = fetch_lpv(p + e.xxx, shn);
    vec3 p001 = fetch_lpv(p + e.xxy, shn);
    vec3 p002 = fetch_lpv(p + e.xxz, shn);
    vec3 p010 = fetch_lpv(p + e.xyx, shn);
    vec3 p011 = fetch_lpv(p + e.xyy, shn);
    vec3 p012 = fetch_lpv(p + e.xyz, shn);
    vec3 p020 = fetch_lpv(p + e.xzx, shn);
    vec3 p021 = fetch_lpv(p + e.xzy, shn);
    vec3 p022 = fetch_lpv(p + e.xzz, shn);

    vec3 p100 = fetch_lpv(p + e.yxx, shn);
    vec3 p101 = fetch_lpv(p + e.yxy, shn);
    vec3 p102 = fetch_lpv(p + e.yxz, shn);
    vec3 p110 = fetch_lpv(p + e.yyx, shn);
    vec3 p111 = fetch_lpv(p + e.yyy, shn);
    vec3 p112 = fetch_lpv(p + e.yyz, shn);
    vec3 p120 = fetch_lpv(p + e.yzx, shn);
    vec3 p121 = fetch_lpv(p + e.yzy, shn);
    vec3 p122 = fetch_lpv(p + e.yzz, shn);
    
    vec3 p200 = fetch_lpv(p + e.zxx, shn);
    vec3 p201 = fetch_lpv(p + e.zxy, shn);
    vec3 p202 = fetch_lpv(p + e.zxz, shn);
    vec3 p210 = fetch_lpv(p + e.zyx, shn);
    vec3 p211 = fetch_lpv(p + e.zyy, shn);
    vec3 p212 = fetch_lpv(p + e.zyz, shn);
    vec3 p220 = fetch_lpv(p + e.zzx, shn);
    vec3 p221 = fetch_lpv(p + e.zzy, shn);
    vec3 p222 = fetch_lpv(p + e.zzz, shn);

    vec3 w = fract(pf);
    
    vec3 y00 = interpolate(p000, p001, p002, w.z);
    vec3 y01 = interpolate(p010, p011, p012, w.z);
    vec3 y02 = interpolate(p020, p021, p022, w.z);

    vec3 y10 = interpolate(p100, p101, p102, w.z);
    vec3 y11 = interpolate(p110, p111, p112, w.z);
    vec3 y12 = interpolate(p120, p121, p122, w.z);

    vec3 y20 = interpolate(p200, p201, p202, w.z);
    vec3 y21 = interpolate(p210, p211, p212, w.z);
    vec3 y22 = interpolate(p220, p221, p222, w.z);

    vec3 x0 = interpolate(y00, y01, y02, w.y);
    vec3 x1 = interpolate(y10, y11, y12, w.y);
    vec3 x2 = interpolate(y20, y21, y22, w.y);

    return interpolate(x0, x1, x2, w.x);

#else
    pf = pf * lpvsize - 0.5;
    ivec3 p = ivec3(pf);
    ivec2 e = ivec2(0,1);
    vec3 p000 = fetch_lpv(p + e.xxx, shn);
    vec3 p001 = fetch_lpv(p + e.xxy, shn);
    vec3 p010 = fetch_lpv(p + e.xyx, shn);
    vec3 p011 = fetch_lpv(p + e.xyy, shn);
    vec3 p100 = fetch_lpv(p + e.yxx, shn);
    vec3 p101 = fetch_lpv(p + e.yxy, shn);
    vec3 p110 = fetch_lpv(p + e.yyx, shn);
    vec3 p111 = fetch_lpv(p + e.yyy, shn);

    vec3 w = fract(pf);
    

    vec3 q = 1.0 - w;

    vec2 h = vec2(q.x,w.x);
    vec4 k = vec4(h*q.y, h*w.y);
    vec4 s = k * q.z;
    vec4 t = k * w.z;
        
    return
          p000*s.x + p100*s.y + p010*s.z + p110*s.w
        + p001*t.x + p101*t.y + p011*t.z + p111*t.w;
#endif
}

void doCamera( out vec3 camPos, out vec3 camTar, in float time, in float mouseX )
{
    float an = 1.5 + sin(time * 0.37) * 0.4;
	camPos = vec3(4.5*sin(an),2.0,4.5*cos(an));
    camTar = vec3(0.0,0.0,0.0);
}

vec3 doBackground( void )
{
    return vec3( 0.0, 0.0, 0.0);
}

//------------------------------------------------------------------------
// Lighting
//------------------------------------------------------------------------
vec3 doLighting( in vec3 pos, in vec3 nor, in vec3 rd, in float dis, in vec4 mal )
{
    vec3 col = mal.rgb;
    
    vec3 tpos = ((pos - vec3(0.0,1.0,0.0)) / 2.5) * 0.5 + 0.5;
#if 0
    // lambert normal
    vec4 shn = sh_project(-nor);
#else
    // specular normal
    vec4 shn = sh_project(-reflect(rd, nor));
#endif
    
    col *= sample_lpv_trilin(tpos, shn);

    return col;
}

vec4 calcFog( in vec3 ro, in vec3 rd, float t1, float K)
{
	const float maxd = 20.0;           // max trace distance
	const float precis = 0.001;        // precission of the intersection
    float h = precis*2.0;
	float res = -1.0;
    vec3 ft = vec3(0.0);
    const int N = 10;
    for( int i=0; i<=N; i++ )          // max number of raymarching iterations is 90
    {
        float x = float(i)/float(N);
        float t = x*t1;
        vec3 tpos = ((ro+rd*t - vec3(0.0,1.0,0.0)) / 2.5) * 0.5 + 0.5;
        float w = 1.0 - exp(-t*K);
        vec4 shn = sh_project(-rd)*2.0*vec4(vec3(4.0/3.0),0.2);
        ft += sample_lpv_trilin(tpos, shn)*w;
    }
    return vec4(ft.rgb / float(N) * t1, exp(-t1*0.1*K));
}

float calcIntersection( in vec3 ro, in vec3 rd)
{
	const float maxd = 20.0;           // max trace distance
	const float precis = 0.001;        // precission of the intersection
    float h = precis*2.0;
    float t = 0.0;
	float res = -1.0;
    for( int i=0; i<90; i++ )          // max number of raymarching iterations is 90
    {
        if( h<precis||t>maxd ) break;
	    h = doModel( ro+rd*t, iTime ).x;

            
        t += h;
    }
    if( t<maxd ) res = t;
    return res;
}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

vec3 spherical_map (vec2 uv) {
    // pixels are uniformly distributed
    float phi = 6.28318530718*uv.x;
    float rho_c = 2.0 * uv.y - 1.0;
    float rho_s = sqrt(1.0 - rho_c*rho_c);
    return vec3(rho_s * cos(phi), rho_s * sin(phi), rho_c);
}
    
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (-iResolution.xy + 2.0*fragCoord.xy)/iResolution.y;
    vec2 m = iMouse.xy/iResolution.xy;

    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------
    
    // camera movement
    vec3 ro, ta;
    doCamera( ro, ta, iTime, m.x );
    //doCamera( ro, ta, 3.0, 0.0 );

    // camera matrix
    mat3 camMat = calcLookAtMatrix( ro, ta, 0.0 );  // 0.0 is the camera roll
    
	// create view ray
	vec3 rd = normalize( camMat * vec3(p.xy,2.0) ); // 2.0 is the lens length
    
#if 0
    {
        vec2 uv = fragCoord / iResolution.xy;
        uv = uv*2.0 - 1.0;
        uv.x *= iResolution.x/iResolution.y;
        if (abs(uv.x) > 1.0)
            return;
        uv = uv*0.5 + 0.5;

        //ro = vec3(-4.0, -1.1, 1.0);
        ro = vec3(-0.95, 1.0, 0.95);
        rd = spherical_map(uv).xzy * vec3(-1,1,1);
        #if 1
        vec3 tpos = ((ro - vec3(0.0,1.0,0.0)) / 2.5) * 0.5 + 0.5;
        vec4 sh = sh_project(-rd);
        //sh.xyz = vec3(0.0);
        //sh.w = 0.0;
        vec4 shr, shg, shb;
        sample_lpv_nn(tpos, shr, shg, shb);
        vec3 col;
        col.r = max(0.0,dot(sh, shr));
        col.g = max(0.0,dot(sh, shg));
        col.b = max(0.0,dot(sh, shb));
        col *= m3div4pi;      
        col = linear_srgb(ACESFitted(col));
        fragColor = vec4( col, 1.0 );
        return;
        #endif
    }
#endif

    //-----------------------------------------------------
	// render
    //-----------------------------------------------------

	vec3 col = doBackground();

    //ro + rd*t = -w / n - ro
    
	// raymarch
    float t = calcIntersection( ro, rd );
    if( t>-0.5 )
    {
        // geometry
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos, iTime);

        // materials
        vec4 mal = doMaterial( pos, iTime );

        col = doLighting( pos, nor, rd, t, mal );
        
        #if 0
        // doesn't look great with the default lighting
        vec4 fog = calcFog(ro, rd, t, 1.0);
        col = col*fog.w + fog.rgb;
        #endif
	}

	//-----------------------------------------------------
	// postprocessing
    //-----------------------------------------------------
    // gamma
	col = linear_srgb(ACESFitted(col));
	   
    fragColor = vec4( col, 1.0 );
}