// Image (image) — Jellyfish - Creature  by senzheng
// https://www.shadertoy.com/view/ttdSWN

/*
    Jellyfish | Creature in Future
  - Created by SEN ZHENG - 2020/02/08
  -
  - 元·宵·快·乐
*/

#define ENABLE_REFRACTION 0
#define MAX_RAYMARCHING_COUNT 100
#define PRECISION 0.005
#define FAR 12.
#define mouse (iMouse.xy / iResolution.xy)
#define time (iTime + 4.4)

vec3 ro, rd;

//----------------------------------------------------

// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
   
    n = max(n*n, 0.001);
    n /= (n.x + n.y + n.z );  
    
	return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}

//----------------------------------------------------

// The Noise function and SDF functions below are from iq's blog.

const mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );

vec3 hash( vec3 p )
{
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
			  dot(p,vec3(269.5,183.3,246.1)),
			  dot(p,vec3(113.5,271.9,124.6)));

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}
float hash( float n ) { return fract(sin(n)*753.5453123); }
float noise( in vec3 p )
{
    vec3 i = floor( p );
    vec3 f = fract( p );
	
	vec3 u = f*f*(3.0-2.0*f);

    float res = mix( mix( mix( dot( hash( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                          dot( hash( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                          dot( hash( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
                mix( mix( dot( hash( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                          dot( hash( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                          dot( hash( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
    return res;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float sdPlane( vec3 p, vec4 n )
{
  return dot(p,n.xyz) + n.w;
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdCapsule( vec3 pa, vec3 ba, float ba2, float r )
{
    float h = clamp( dot(pa,ba)/ba2, 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float opUnion( float d1, float d2 ) {  return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

//----------------------------------------------------

// SDF operation functions for Hit struction

Hit mixHit(Hit h1, Hit h2, float dres) {
    float factor = (dres - h1.d)/(h2.d - h1.d);
    return Hit(dres, 
               mix(h1.uv, h2.uv, factor),
               mix(h1.col, h2.col, factor),
               mix(h1.ref, h2.ref, factor),
               mix(h1.spe, h2.spe, factor),
               mix(h1.rough, h2.rough, factor),
               mix(h1.lightD, h2.lightD, factor),
               mix(h1.lightCol, h2.lightCol, factor),
               mix(h1.lightStrength, h2.lightStrength, factor),
               mix(h1.sss, h2.sss, factor),
               mix(h1.diffuseTex, h2.diffuseTex, factor)
               );
}

Hit opUnion(Hit h1, Hit h2) {
	float dres = opUnion(h1.d, h2.d);
    return mixHit(h1, h2, dres);
}

Hit opSubtraction(Hit h1, Hit h2) {
	float dres = opSubtraction(h1.d, h2.d);
    return mixHit(h1, h2, dres);
}

Hit opSmoothUnion(Hit h1, Hit h2, float k) {
	float dres = opSmoothUnion(h1.d, h2.d, k);
    return mixHit(h1, h2, dres);
}

Hit opSmoothSubtraction(Hit h1, Hit h2, float k) {
	float dres = opSmoothSubtraction(h1.d, h2.d, k);
    return mixHit(h1, h2, dres);
}


//----------------------------------------------------

// circleClone: Clone object by dividing the space into [num] parts according to the angle
// It is very useful and performance-saving.

vec3 circleClone( vec3 p, float num, out float id ) {
    vec3 pp = p;
    float angleArea = PI * 2.0 / num;
    float originangle = atan( pp.x, pp.z );
    float angle = mod( originangle, angleArea ) - angleArea * 0.5;
    id = floor(originangle / angleArea);
    
    float shake = cos( pp.y * 2.0 + time * 2.0 + id) * 0.2;
    pp.xz += normalize( pp.xz ) * shake * smoothstep( -0.3, -1.0, pp.y );
    float len = length( pp.xz );
    
    vec3 modPos = vec3( cos( angle ) * len, p.y, sin( angle ) * len );
    return modPos;
}


//----------------------------------------------------

// jerryfish: Jerryfish sdf function

Hit jerryfish( vec3 p ) {
    
    vec3 backupPos = p;
    float shake = sin( p.y * 2.0 + time * 3.6 ) * 0.2;
    p.xz += normalize( p.xz )*shake;

    float radius = 1.5;
    
    // Main Hat
    vec3 _NoiseScale = vec3( 8.0, 0.2, 8.0 );
    _NoiseScale.xz -= smoothstep( 0.2, -radius, p.y ) * 3.0;
    float _NoiseAmp = 0.4 * smoothstep( 0.6, -radius * 0.3, p.y ) * smoothstep(-0.4, 0.2, shake);
    float n = noise( normalize( p ) * _NoiseScale + time * 0.5 );
    float d = length( p * vec3( 1.0, 1.4, 1.0 )) - radius;
    d = max( d, -sdBox( p + vec3( 0.0, 1.0, 0.0 ), vec3( 100.0, 0.5, 100.0 ) ) );
    d = opSmoothSubtraction(length( p * vec3( 1.0, 1.4, 1.0 )) - radius * 0.85, d, 0.1);
    
    d += n * _NoiseAmp;
    d *= 0.7;
    
    // Tentacles 
    float id;
    vec3 modPos = circleClone( p, 120.0, id );
    float tentaclesRadius = 0.015 + sin( id ) * 0.008;
    float tentaclesLength = -4.0 - cos( id ) * 1.0;
    d = opSmoothUnion( d, 0.5 * sdCapsule( modPos, vec3( radius - 0.25, 0.0, 0.0 ), vec3( radius - 0.25, tentaclesLength, 0.0 ), tentaclesRadius ), 0.1 );

    // Inner Center
    vec3 pic = circleClone(p, 10.0, id);
    float adjustFactor = 1.0 + abs(sin(pic.y * 12.0)) * 0.25;
    adjustFactor += noise(pic * 10.0) * 0.5;
    float dic = 0.5 * sdCapsule( pic, vec3(0.55, 0.0, 0.0), vec3(0.55, -2.2, 0.0), 0.1 * adjustFactor * smoothstep(-2.2, -1.0, pic.y));

    // Different Material Info
    float originD = d;
    d = min( d, dic );
    
    float factor = (d - originD)/(dic - originD);
    float limitHead = smoothstep(-radius*0.7, radius*0.8, backupPos.y);
    
    vec3 col0 = mix(vec3(0.37, 0.73, 0.88), vec3(0.117, 0.145, 0.317), limitHead);
    vec3 col1 = mix(vec3(0.89, 0.31, 0.145), vec3(0.8, 0.31, 0.5), smoothstep(-1.0, 0.0, backupPos.y));
    vec3 col = mix(col0, col1, factor);
    
    // Dot Light
    vec3 nor = normalize(p);
    float a = acos(abs(nor.y) / 1.0);
    vec2 uv = mod(p.xz * a * 6.0, vec2(1.0)) - 0.5;
    float dotScale = 15.0 / (0.1 + length(p.xz * a * 6.0));
    float dotLight = smoothstep(0.08 * dotScale, 0.07 * dotScale, length(uv));
    dotLight *= (0.6 + 0.4 * sin(p.x * 10.0 + time * 5.6));
    dotLight *= smoothstep( 0.0, 0.2, p.y );

    return Hit( d, vec2( 0.0 ), col, 0.7, 1.0, 0.0, d, vec3(1.0), dotLight, 0.4, 1.0 );
}

//----------------------------------------------------

// bubbles: Bubbles sdf function

Hit bubbles( vec3 p ) {
    vec3 backupPos = p;
    float density = 0.5;
    p.xz = mod( p.xz, vec2( density, density ) ) - vec2( density * 0.5, density * 0.5 );
    float id = sin(floor( backupPos.x / density )) + cos(floor( backupPos.z / density ));
    id *= 10.0;
    float factor = smoothstep(1.8, 0.0, backupPos.y);
    float radius = 0.02 + sin( id ) * 0.01;
    float speed = 2.5 - sin( id ) * 0.5;
    p.y = mod( p.y + cos( id ) * 10.0 - speed * time, 6.8) - 5.0;
    p.xz += vec2( cos( time * 2.0 ), sin( time * 2.0 ) ) * sin( id ) * density * 0.2;
    float d = sdSphere( p, radius );
    d = opIntersection( d, sdBox( backupPos + vec3( 0.0, 1.6, 0.0 ), vec3( 1.8, 3.4, 1.8 ) ) );
    return Hit( d, vec2( 0.0 ), vec3(1.0), 1.0, 1.0, 0.0, d, vec3(1.0, 1.05, 1.1), 0.3, 0.0, 0.0 );
}

//----------------------------------------------------

// Ray-Box intersection
// https://iquilezles.org/articles/boxfunctions
void iBox( in vec3 ro, in vec3 rd, in mat4 txx, in mat4 txi, in vec3 rad, out vec4 nearInfo, out vec4 farInfo ) 
{
    // convert from ray to box space
	vec3 rdd = (txx*vec4(rd,0.0)).xyz;
	vec3 roo = (txx*vec4(ro,1.0)).xyz;

	// ray-box intersection in box space
    vec3 m = 1.0/rdd;
    vec3 n = m*roo;
    vec3 k = abs(m)*rad;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
    if( tN > tF || tF < 0.0) {
        nearInfo = vec4(9999.0);
        farInfo = vec4(9999.0);
        return;
    }

	vec3 norN = -sign(rdd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
	vec3 norF = -sign(rdd)*step(t2.xyz,t2.yzx)*step(t2.xyz,t2.zxy);

    // convert to ray space
	
	norN = (txi * vec4(norN,0.0)).xyz;
	norF = (txi * vec4(norF,0.0)).xyz;
    
    nearInfo = vec4(tN, norN);
    farInfo = vec4(tF, norF);

}

Hit map2(vec3 p) {
    Hit res = jerryfish(p);
    res = opUnion(res, bubbles(p));
    return res;
}

vec3 calcuNormal(in vec3 p)
{  
    vec2 e = vec2(-1., 1.)*0.001;   
    return normalize(e.yxx*map2(p + e.yxx).d + e.xxy*map2(p + e.xxy).d + 
                     e.xyx*map2(p + e.xyx).d + e.yyy*map2(p + e.yyy).d );   
}

float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = map2( ro + rd*t ).d;
        res = min( res, 5.0*h/t );
        t += clamp( h, 0.02, 0.2 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.2, 1.0 );
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map2( aopos ).d;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

float calcThickness( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = -map2( aopos ).d;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

vec3 getBgCol(vec3 ray) {
    return vec3(0.05);
}

vec4 shading(vec3 sp, Hit hitdata, vec3 bgCol, float t) {
    vec3 col = vec3(0.0);
	
    // Light source
    vec3 lp = vec3(0.0, 0.25, 0.0);
    vec3 lCol = vec3(0.98, 0.76, 0.58) * (7.0 + sin(time * 3.6) * 4.0);
    vec3 sundir = lp - sp;
    float distToLight = length(sundir);
    vec3 ld = normalize(sundir);
    
    vec3 nor = normalize( calcuNormal( sp ) );
    float shd = calcSoftshadow( sp, ld, 0.02, FAR );
    float occ = calcAO( sp, nor );
    float thickness = calcThickness( sp-nor*0.01, ld);
    float fresnel = 0.0 + 1.0 * pow( 1.0 - max( dot( -rd, nor ), 0.0), 2.0);

    vec3 hal = normalize( lp - rd );
    float amb = clamp( 0.3 + 0.7 * nor.y, 0.0, 1.0 );
    float dif = max( dot( ld, nor ), 0.0);
    float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ), 12.0);
    float bac = clamp( dot( nor, normalize(vec3(lp.x,-lp.y,lp.z))), 0.0, 1.0 );

    // surface color
    float spot = tex3D(iChannel0, sp, nor).r;
    col = mix(hitdata.col, vec3(0.4, 0.35 ,0.2), spot * hitdata.diffuseTex);
    thickness *= spot;

    // Light Falloff
    lCol *= 1.0 / distToLight;

    vec3 lin = lCol * dif * shd;
    lin += hitdata.spe * spe * lCol * shd;
    lin += 0.3 * amb * vec3(1.0);
    lin += 0.3 * bac * vec3(1.0);
    col *= lin * occ;

    // Fake SSS
    float sss = (1.0 - thickness) * hitdata.sss / (0.0001 + pow(distToLight, 2.0));
    vec3 colWithSSS = mix(col, lCol*hitdata.col, sss);
    col = colWithSSS;

    // Limit Head Area
    float limitHead = smoothstep( -0.5, 0.0, sp.y );

    // reflect
    vec3 r = reflect(rd, nor);
    col += texture( iChannel1, r ).xyz * hitdata.ref * fresnel * limitHead;

    // Outline Glow
    vec3 outlineCol = vec3(1.5, 1.1, 1.0) * 2.0;
    col += pow(fresnel, 5.0) * limitHead * outlineCol;
    
    // Emission
    vec3 emission = hitdata.lightCol * hitdata.lightStrength;
    col += emission;
    
    // Caustics
    mat3 m1 = mat3(-2.,-1.,2., 3.,-2.,1., 1.,2.,2.);
    vec3 a1 = vec3( sp.xz * 200. / 4e2, time / 8. ) * m1;
    vec3 b1 = a1 * m1 * .4;
    vec3 c1 = b1 * m1 * .3;
    vec4 k = vec4(pow(
        min( min( length(.5 - fract( a1 )), 
      			length(.5 - fract(b1))), 
          length(.5 - fract(c1))), 
        8.) * 20.) ;
    col += k.rgb * vec3(1.05, 1.0, 1.1) * limitHead;

    //col = vec3(sss);

    //col = mix(col, bgCol, smoothstep(0.5, FAR, t));
    
    
    return vec4(col, hitdata.lightStrength);
}

vec4 render(vec3 ro, vec3 rd) {
    Hit hitdata;
    float t = 0.0;
    float told = t, d;
    
    vec4 col = vec4(0.0);
    vec3 bgCol = getBgCol(rd);
    float fresnel = 1.0;
    int isHit = 0;
    
    float prec = PRECISION;
    
    // Get Front Box Hitdata
    // Translate box	
	mat4 tra = translate( 0.0, -1.6, 0.0 );
	mat4 txi = tra; 
	mat4 txx = translate( 0.0, 1.6, 0.0 );
    vec3 nearPoint, nearNor;
    vec4 nearInfo, farInfo;
    vec3 box = vec3(1.8, 3.4, 1.8);
	iBox( ro, rd, txx, txi, box, nearInfo, farInfo);
    nearPoint = ro + rd * nearInfo.x;
    nearNor = nearInfo.yzw;
    
    if(nearInfo.x < FAR) {
        // Dirty glass
        vec3 nor = nearNor;
        vec3 sc = tex3D(iChannel2, nearPoint*0.5, nor).rgb;
        col.rgb = texture( iChannel1, reflect(rd, nor) ).xyz;
        float lCol = ( sin( time * 3.6 ) * 0.5 + 0.5) * 2.0;
        col.rgb = mix(col.rgb, vec3( max( 0.0, dot( -nor, normalize(-nearPoint) ) ) ) * lCol, 0.2);
        col.rgb *= vec3(1.0, 1.1, 1.2);
        float baseF = 0.1 + sc.r * 0.9;
        fresnel = baseF + (1.0 - baseF) * pow( 1.0 - max( dot( -rd, nor ), 0.0), 2.2);
        fresnel = smoothstep(0.3, 0.8, fresnel);
        
        // Simple HUD
        vec2 uv;
        if (nor.x != 0.0) uv = nearPoint.yz;
        if (nor.y != 0.0) uv = nearPoint.xz;
        if (nor.z != 0.0) uv = nearPoint.xy;
        vec2 uv1 = uv * 5.0;
        float id = sin(floor(uv1.x) * 10.0) + cos(floor(uv1.y) * 10.0);
        id = sin( id * 10.0 + time * 3.6 );
        uv1 = mod(uv1, vec2(1.0));
        
        float distToBox = length(ro - nearPoint);
        float lineWidth = mix(0.01, 0.04,  distToBox / 6.0);
        // Grid
        float grid = smoothstep(0.97 - lineWidth , 1.0 - lineWidth , max(uv1.x, uv1.y)) * 0.5;
        // Random Center Dot
        grid = max( grid, smoothstep( lineWidth * 2.5, lineWidth * 2.5 - 0.01, length(uv1 - vec2(0.5))) * smoothstep(0.5, 1.0, id) );
        // Active Grid | Filled
        // grid += smoothstep(0.5, 1.0, id) * 0.3;
        // Scan Anim
        grid = max(0.0, min(1.0, grid * sin( time * 1.8 + nearPoint.y * 1.0 ) ) );
        
        col.rgb += grid * vec3(0.8, 0.9, 1.2);
        fresnel *= (1.0 - grid);
        
        // Reset ro and rd
        ro = nearPoint;
        rd = refract(rd, nor, 0.659);
        
    } else {
        col.rgb = bgCol;
    }
    
    
    for (int i = 0 ; i < MAX_RAYMARCHING_COUNT ; i++) {
        
        vec3 sp = ro + rd*t;
        hitdata = map2(sp);
        d = hitdata.d;
        
        
        if (d < prec) {
            vec4 shadingCol = shading( sp, hitdata, bgCol, t );
            col = mix( col, shadingCol, fresnel );
        	vec3 nor = normalize( calcuNormal( sp ) );
            
            break;
            
        } else if ( t >= FAR || i+1 == MAX_RAYMARCHING_COUNT) {
            // Get Back Box Hitdata
            vec3 farPoint, farNor;
            vec4 nearInfo, farInfo;
            iBox( ro - rd, rd, txx, txi, box, nearInfo, farInfo);
            farPoint = ro + rd * farInfo.x;
            farNor = farInfo.yzw;
            if(farInfo.x < FAR) {
                ro = farPoint;
                vec3 nor = -farNor;
                vec3 refrCol = texture( iChannel1, refract(rd, nor, 1.52) ).xyz;
                vec3 reflCol = texture( iChannel1, reflect(rd, nor) ).xyz;
        		float f = pow( 1.0 - max( dot( -rd, nor ), 0.0), 2.2);
                vec3 shadingCol = mix(refrCol, reflCol, f);
            	col.rgb = mix( col.rgb, shadingCol, fresnel );
                
            } else {
            	col.rgb = mix( col.rgb, getBgCol(rd), fresnel );
            }
            
            break;
        }
        
        told = t;
        t += d;
        t = min(FAR, t);
    }
    
    //col.rgb = pow(col.rgb, vec3(1.2));
    
    return col;
}

mat3 setCamera(vec3 ro, vec3 lookAt, vec3 cp) {
    vec3 cw = normalize(lookAt-ro);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
    
    float dist = 8.0 + sin(time * 0.4) * 2.0;
    ro = vec3( sin( time * 0.5 + mouse.x * 5.0) * dist, sin( time ) * 0.8 - 0.8 + mouse.y * 5.0, cos( time * 0.5 + mouse.x * 5.0 ) * dist);
    
    vec3 lookAt = vec3( 0.0, -0.2, 0.0 );
    vec3 camup = normalize( vec3( sin( time * 0.2 ), 13.0, cos( time * 0.2 )));
    mat3 viewMat = setCamera( ro, lookAt, camup );
    rd = viewMat * normalize( vec3( p, 3.0 ) );
    
    vec4 col = render( ro, rd );
    
    
    fragColor = col;
}
