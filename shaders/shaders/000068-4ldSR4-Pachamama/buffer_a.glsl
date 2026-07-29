// Buffer A (buffer) — Pachamama by XT95
// https://www.shadertoy.com/view/4ldSR4

// ---------------------------------------------------------------------------------------
//	Created by anatole duprat - XT95/2016
//	License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
//
//  /!\ Heavy GPU required /!\
//  You can disable some features on the Buffer A if it's too slow..
//
// 	Special Thanks to :
//  Shane ( Nice Bump mapping https://www.shadertoy.com/view/MscSDB )
//  Virgill ( Killer DOF https://www.shadertoy.com/view/llK3Dy )
//  reinder ( FXAA https://www.shadertoy.com/view/ls3GWS)
//  iq ( OrenNayar https://www.shadertoy.com/view/ldBGz3 & Soft Shadow https://iquilezles.org/articles/rmshadows )
//
//  Wonderfull music by Tinush : https://soundcloud.com/tinush/tinush-journey-original
//  Enjoy =)
//
// ---------------------------------------------------------------------------------------


#define ROCKITERATION 7
#define ENABLE_GRASS

//Header
const float PI = 3.14159265359;
vec4 raymarch( in vec3 ro, in vec3 rd, in vec2 nfplane );
vec3 normal( in vec3 p );
vec3 bumpMap( sampler2D tx, in vec3 p, in vec3 n, float bf);
float map( in vec3 p );
mat3 lookat( in vec3 fw, in vec3 up );
mat3 rotate( in vec3 v, in float angle);
vec3 triPlanarProj( in sampler2D tex, in vec3 p, in vec3 n );
float hash( in float n );//->0:1
vec2 hash2( in float n );
float fbm( in vec2 uv);
vec3 randomSphereDir(in vec2 rnd);
vec3 randomHemisphereDir(in vec3 dir, in float i);
float ambientOcclusion( in vec3 p, in vec3 n, float maxDist, float falloff );
float softshadow( in vec3 ro, in vec3 rd );


//-----------------------------------------------------------------------------
// Distance field
//-----------------------------------------------------------------------------
//Based on Mandelbox
float rock(in vec3 pos)
{
    const float scale = 2.82;
    const float minRad2 = .83;
    const vec4 scaled8 = vec4(3.525);

    vec4 p = vec4(pos,1.), p0 = p;
    float r2;
    for (int i=0; i<ROCKITERATION; i++)
    {
        p.xyz = rotate(vec3(0.,1.,0.),p.y*.12) * p.xyz;
        p.xyz = rotate(vec3(0.,0.,1.),-p.z*.1) * p.xyz;
        p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;
        r2 = dot(p.xyz, p.xyz);
        p *= clamp(max(minRad2/r2, minRad2), 0.0, 1.0);

        p = p*scaled8 + p0;
    }
  	return ((length(p.xyz) - abs(scale - 1.0)) / p.w - pow(scale, float(1-ROCKITERATION)));
}

//Deformed cylinders
float grass(in vec3 p)
{
	float id = textureLod(iChannel1,floor(p.xz)/256.,0.0).r;
    float h = p.y;
    
	p.xz = mod(p.xz,1.)-.5;
	p = rotate(vec3(0.,1.,0.),id*60.)*p;
    
	//p = rotate(vec3(1.,0.,0.),p.y*.2+cos(iTime*.01+id*7.))*p; //Grass animation
	p = rotate(vec3(1.,0.,0.),p.y*.2)*p;
    
    float d = length( p.xz )-id*.05 + pow(h*.2,4.) ;

   return d;
}

//Final distance field map
float map(in vec3 p)
{
    float r = rock(p);
	float ground = min(p.y+.5,p.y+r*.5);
    
    float d = min(r, ground);
	d = max(d,p.y-1.);
    
	#ifdef ENABLE_GRASS
	const float grassSize = 100.;
	vec3 pgrass = (p+vec3(0.,ground-p.y,0.)) * grassSize;
    d = min(d, grass(pgrass)/grassSize );
    d = min(d, grass(pgrass+vec3(10.8,0.,1.5))/grassSize );
    d = min(d, grass(pgrass+vec3(-1.3,0.,-10.1))/grassSize );
    #endif
    
    return  d;
}




//-----------------------------------------------------------------------------
// Shading
//-----------------------------------------------------------------------------
//Cheap procedural sky - https://www.shadertoy.com/view/lt2SR1
vec3 skyColor( in vec3 rd )
{
    vec3 sundir = normalize( vec3(.0, .1, 1.) );
    rd.y += .02;
    float yd = min(rd.y, 0.), clouds = 0.;
    rd.y = max(rd.y, 0.);
    
    vec3 col = vec3(0.);
    
    col += vec3(.4, .4 - exp( -rd.y*20. )*.3, .0) * exp(-rd.y*9.);
    col += vec3(.4, .6, .7) * (1. - exp(-rd.y*8.) ) * exp(-rd.y*.9);
    
    col = mix(col*1.2, vec3(.3),  1.-exp(yd*100.));
    
    //Clouds
    vec2 pclouds = rd.xz/rd.y;
    clouds += fbm(pclouds*.01);
    col += .1*(clouds*2.-1.);
    
    //Synchronized raindow!
    vec3 raindow = clamp( abs(mod(-rd.x*20.*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    raindow = raindow*raindow*(3.0-2.0*raindow);;
    col += raindow * max(-abs(rd.x+.715)+.025,0.)*100.*pow(texture(iChannel3, vec2(mod(rd.x*5.,1.),0.)).r,2.);
    
    return clamp(col,vec3(0.),vec3(1.))*2.;
}

//Better diffuse for rock - https://www.shadertoy.com/view/ldBGz3
float orenNayar( in vec3 l, in vec3 n, in vec3 v, float r )
{
    float lv = dot(l,v);
    float nl = dot(n,l);
    float nv = dot(n,v);
    
    float r2 = r*r;
    float a = 1. - .5 * (r2 / (r2+.57));
    float b = .45 * r2 / (r2+.09);
    

    float ga = dot(v-n*nv,n-n*nl);

	return max(0.0,nl) * (a + b*max(0.0,ga) * sqrt((1.0-nv*nv)*(1.0-nl*nl)) / max(nl, nv));
}

//Shading a point
vec3 shade( in vec4 p, in vec3 n, in vec3 ro, in vec3 rd )
{		
	vec3 ldir = normalize(vec3(-0.8,2.,0.95));
	vec3 albedo, amb, dif, sky, col;
    
    //Sky
    float d = exp( -length(p.xyz-ro)*0.1 );
    if( d < .3 )
    {
        return skyColor(rd);
    }
    
    //Albedo
	float r = rock(p.xyz);
	if(r>.003)
		albedo = vec3(0.65,1.,0.05)*(1.-exp(-(p.y+r*.5)*120.));
	else
	{	
		n = bumpMap(iChannel0,p.xyz*8.,n,.1);
		albedo = triPlanarProj(iChannel0,p.xyz*8.,n);
	}

    //Lighting
    float occ = ambientOcclusion(p.xyz,n, .05, -108.5) * ambientOcclusion(p.xyz,n, .2, -17.);
    float shad = softshadow(p.xyz,ldir);

	dif = vec3(1.,.7,.3) * orenNayar(n,ldir,rd,1.) * shad;
    sky = vec3(.8,.95,1.) * orenNayar(n,vec3(0.,1.,0.),rd,1.) * occ;
	amb = vec3(.9,.95,1.) * occ;
   
    col = albedo * ( dif*2.5 + sky*.1 + amb*.2 );

    //Fog
	col += vec3(1.,.8,.6)*pow(p.w,2.)*.025;
	col = mix(col, vec3(.8,1.,1.), min(length(p.xyz-ro)*.001, 1.));

	return col;
}


//-----------------------------------------------------------------------------
// Entry point
//-----------------------------------------------------------------------------
float time;
int idSeq; 

void cameraPath( in vec2 v, out vec3 ro, out vec3 rd )
{
    float nt = smoothstep(0.,1., max(mod(time,30.),0.)/30.);
    
    if(idSeq == 0)
    {
        ro = mix(vec3(2.1,0.1,1.45), vec3(2.1,0.1,.7), nt);
        rd = mix(vec3(5.,0.,3.), vec3(5.,0.,-1.5), nt);
    }
    else if(idSeq == 1)
    {    
        ro = mix(vec3(.1,.1,2.6), vec3(.1,.7,2.2), nt);
        rd = mix(vec3(0.,0.,3.), vec3(0.,-1.,3.), nt);
    }
    else if(idSeq == 2)
    {    
        ro = mix(vec3(2.1,.05,1.2), vec3(0.,.05,1.2), nt);
        rd = mix(vec3(5.,2.,0.), vec3(5.,-8.,0.), nt);
    }
    else if(idSeq == 3)
    {    
        ro = mix(vec3(.5,.1,4.5), vec3(-.5,.1,4.5), nt);
        rd = mix(vec3(2.,-2.,5.), vec3(2.,-3.,5.), nt);
    }
    else if(idSeq == 4)
    {    
        ro = mix(vec3(2.53,.05,-1.505),vec3(1.8,.05,-.8), nt);
        rd = mix(vec3(5.,2.,-4.), vec3(5.,-3.,-0.), nt);
    }
    
    rd = lookat(rd,vec3(0.,1.,0.)) * normalize( vec3(v.xy*vec2(-1.,1.),-1.5) );
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    time = mod(iTime,150.);
	idSeq = int(time/30.);

    
    vec2 o = hash2( float(iFrame) ) - 0.5;
    vec2 q = (-iResolution.xy + 2.0*(fragCoord+o*.6))/ iResolution.y;
    
    //Camera ray
    vec3 ro,rd;
    cameraPath( q, ro, rd );

	//Classic raymarching by distance field
	vec4 p = raymarch(ro, rd, vec2(0., 1000.) );
    vec3 n = normal(p.xyz);
    vec3 col = shade(p, n, ro, rd);


    fragColor = vec4(col,0.);
        
    //Dof factor
    if(idSeq == 0 || idSeq == 4)
    	fragColor.a += clamp( 1.-(length(ro-p.xyz)-.2)*4., 0., 1.)*.25;
    else if(idSeq == 1 || idSeq == 2)
 	    fragColor.a += clamp( (length(ro-p.xyz)-2.)*4., 0., 1.)*.4;
    else
 	    fragColor.a += clamp( (length(ro-p.xyz)-1.)*1., 0., 1.)*.5;
            
    
	vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = mix(fragColor, texture(iChannel2, uv),.5);
    
}





    
//-----------------------------------------------------------------------------
// Utils
//-----------------------------------------------------------------------------
//Raymarching by distance field
vec4 raymarch( in vec3 ro, in vec3 rd, in vec2 nfplane )
{
    float glow = 0.;
	vec3 p = ro+rd*nfplane.x;
	float t = 0.;
	for(int i=0; i<256; i++)
	{
        float d = map(p)*.8;
        t += d;
        p += rd*d;
		glow += 1./256.;
		if( d < 0.0001 || t > nfplane.y )
            break;
            
	}
	
	return vec4(p,glow);
}

//Take the gradient of map()
vec3 normal( in vec3 p )
{
	vec3 eps = vec3(0.001, 0.0, 0.0);
	return normalize( vec3(
		map(p+eps.xyy)-map(p-eps.xyy),
		map(p+eps.yxy)-map(p-eps.yxy),
		map(p+eps.yyx)-map(p-eps.yyx)
	) );
}

//Clever code taken from Shane shader - https://www.shadertoy.com/view/MscSDB
vec3 bumpMap( sampler2D tx, in vec3 p, in vec3 n, float bf)
{
    const vec2 e = vec2(0.001, 0);
    
    mat3 m = mat3( triPlanarProj(tx, p - e.xyy, n), triPlanarProj(tx, p - e.yxy, n), triPlanarProj(tx, p - e.yyx, n));
    
    vec3 g = vec3(0.299, 0.587, 0.114)*m;
    g = (g - dot(triPlanarProj(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);
                      
    return normalize( n + g*bf );
    
}

//Lookat matrix
mat3 lookat( in vec3 fw, in vec3 up )
{
	fw = normalize(fw);
	vec3 rt = normalize( cross(fw, normalize(up)) );
	return mat3( rt, cross(rt, fw), fw );
}

//Rotate matrix
mat3 rotate( in vec3 v, in float angle)
{
	float c = cos(angle);
	float s = sin(angle);
	
	return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
		(1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
		(1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
		);
}

//Tri Planar Projection of a texture
vec3 triPlanarProj( in sampler2D tex, in vec3 p, in vec3 n )
{
    n = abs(n);
	vec4 col = texture(tex, p.yz)*n.x + texture(tex, p.xz)*n.y + texture(tex, p.xy)*n.z;
    return pow(col.rgb,vec3(2.2));
}

//Random number [0:1]
float hash( in float n )
{
    return fract(sin(n)*3538.5453);
}
vec2 hash2( in float n )
{
    return fract(sin(vec2(n,n+1.0))*vec2(43758.5453123,22578.1459123));
}

//2D Fractional Brownian motion
float fbm( in vec2 uv )
{
    float r = .5 * texture(iChannel1, uv).r;
    r += .25 * texture(iChannel1, uv*2.).g;
    r += .125 * texture(iChannel1, uv*4.).b;
    r += .05125 * texture(iChannel1, uv*8.).r;
    return r;
}

//Random vector
vec3 randomSphereDir(in vec2 rnd)
{
	float s = rnd.x*PI*2.;
	float t = rnd.y*2.-1.;
	return vec3(sin(s), cos(s), t) / sqrt(1.0 + t * t);
}

//Random vector in a hemisphere
vec3 randomHemisphereDir(in vec3 dir, in float i)
{
	vec3 v = randomSphereDir( vec2(hash(i+1.), hash(i+2.)) );
	return v * sign(dot(v, dir));
}

//More info at http://www.aduprat.com/portfolio/?page=articles/hemisphericalSDFAO
float ambientOcclusion( in vec3 p, in vec3 n, float maxDist, float falloff )
{
	const int nbIte = 32;
    const float nbIteInv = 1./float(nbIte);
    const float rad = 1.-1.*nbIteInv;
    
	float ao = 0.0;
    
    for( int i=0; i<nbIte; i++ )
    {
        float l = hash(float(i))*maxDist;
        vec3 rd = normalize(n+randomHemisphereDir(n, l )*rad)*l; 
        
        ao += (l - map( p + rd )) / pow(1.+l, falloff);
    }
	
    return clamp( 1.-ao*nbIteInv, 0., 1.);
}


//From iq - https://iquilezles.org/articles/rmshadows
float softshadow( in vec3 ro, in vec3 rd )
{
    float res = 1.0;
    float t=0.01;
    for(int i=0; i<128; i++)
    {
        float h = map(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        res = min( res, 200.*h/t );
        t += h;
        if(t>2.)
            break;
    }
    return res;
}
