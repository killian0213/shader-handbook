// Image (image) — UI easy to integrate by XT95
// https://www.shadertoy.com/view/ldKSDm

// Created by anatole duprat - XT95/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/*
Never dream to have slider,text display and color picker for you shader ? 
Here we are! 
Easy peasy to integrate :
- copy/paste buffer A to your shader
- modify the mainImage() of the buffer A to make your own IU
- just mix your final render with the buffer A
- enjoy :)

Any suggestions are very welcome!

Thx to :
Smooth HSV - iq : https://www.shadertoy.com/view/MsS3Wc
Rounded box - iq : https://www.shadertoy.com/view/4llXD7
96-Bit 8x12 font - Flyguy : https://www.shadertoy.com/view/Mt2GWD
Abstract Corridor - Shane : https://www.shadertoy.com/view/MlXSWX
*/

//Only what you need in your shaders to get the IU inputs
float uiSlider(int id){return texture(iChannel0, vec2(float(id)+.5,0.5)/iResolution.xy).r;}
vec3 uiColor(int id){return texture(iChannel0, vec2(float(id)+.5,1.5)/iResolution.xy).rgb;}



vec3 sampleEnvMap(vec3 rd, float lod);
float ambientOcclusion( in vec3 p, in vec3 n, float maxDist, float falloff );
vec3 doBumpMap( sampler2D tex, in vec3 p, in vec3 nor, float bumpfactor);
vec3 shade( in vec3 p, in vec3 n, in vec3 ro, in vec3 rd, vec2 v )
{
    //Get the slider here!
    float roughness = uiSlider(0);
    float metallic = uiSlider(1);
    
    
    float d = length(ro-p);
    
    vec3 col = vec3(0.);
    if(d>30.)
        return sampleEnvMap(-rd,.9)*2.;
    
    n = doBumpMap(iChannel1, p*.25, n, .05);
    
    float ao = clamp( pow( ambientOcclusion(p,n,.5,1.), 20.)*5., 0., 1.);
    float fre = clamp(1.0+dot(n,rd), 0.0, 1.0 );
        
    vec3 diff = mix(sampleEnvMap(-n,roughness).rgb, vec3(1.), roughness);
    vec3 spec = sampleEnvMap(-reflect(rd,n),roughness).rgb;
    
    //Get the color here!
    col = (uiColor(0)*.3+.7) * mix(diff*ao,spec, min(1., metallic+fre) );
	return col;
}



vec3 raymarche( in vec3 ro, in vec3 rd, in vec2 nfplane );
vec3 normal( in vec3 p );
float map( in vec3 p );

mat3 lookat( in vec3 fw, in vec3 up );
mat3 rotate( in vec3 v, in float angle);
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
	vec2 q = fragCoord.xy/iResolution.xy;
	vec2 v = -1.0+2.0*q;
	v.x *= iResolution.x/iResolution.y;
	
	float ctime = (iTime)*.1;
	vec3 ro = vec3( cos(ctime)*5., 0., sin(ctime)*5. );
	vec3 rd = normalize( vec3(v.x, v.y, 1.5) );
	rd = lookat( -ro + vec3(0., 0., 0.), vec3(0., 1., 0.) ) * rd;
	
	vec3 p = raymarche(ro, rd, vec2(1., 100.) );
	vec3 n = normal(p.xyz);
	vec3 col = shade(p, n, ro, rd, q);
	
    col = pow(col, vec3(1./2.2));
    col = clamp(col,0.,1.) * (.5 + .5*pow( q.x*q.y*(1.-q.x)*(1.-q.y)*50., .5));
    
    //UI integration
    vec4 ui = texture(iChannel0,q);
    col = mix(col,ui.rgb, ui.a*.8);
        
	fragColor = vec4( col, 1. );
}



//From Shane
float tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max((abs(n) - 0.2)*7., 0.001); // max(abs(n), 0.001), etc.
    n /= (n.x + n.y + n.z );  
    
	return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).x;
}
vec3 doBumpMap( sampler2D tex, in vec3 p, in vec3 nor, float bumpfactor){
   
    const float eps = 0.001;
    float ref = tex3D(tex,  p , nor);                 
    vec3 grad = vec3( tex3D(tex, vec3(p.x-eps, p.y, p.z), nor)-ref,
                      tex3D(tex, vec3(p.x, p.y-eps, p.z), nor)-ref,
                      tex3D(tex, vec3(p.x, p.y, p.z-eps), nor)-ref )/eps;
             
    grad -= nor*dot(nor, grad);          
                      
    return normalize( nor + grad*bumpfactor );
	
}

//From iq
vec3 deform( vec3 p )
{
    p.xyz += 1.000*sin(  2.0*p.zxy );
    p.xyz += 0.500*sin(  4.0*p.zxy );
    p.xyz += 0.250*sin(  8.0*p.zxy );
    return p;
}
    
float map( in vec3 p )
{
	float d = length(deform(p))-1.5;
	
	return d*.1;
}

float roundBox( in vec2 p, in vec2 b, in float r ) 
{
    vec2 q = abs(p) - b;
    vec2 m = vec2( min(q.x,q.y), max(q.x,q.y) );
    float d = (m.x > 0.0) ? length(q) : m.y; 
    return d - r;
}


const float PI = 3.14159265359;
vec3 sampleEnvMap(vec3 rd, float lod)
{
    vec2 uv = vec2(atan(rd.z,rd.x),acos(rd.y));
    uv = fract(uv/vec2(2.0*PI,PI));
    
    vec3 col = vec3(0.,0.05*cos(uv.x)+0.05, .1*sin(uv.y)+.1)*1.;
    
    float r = (1.-pow(lod,.5))*1000.+5.;
    col += vec3(1.)* clamp( pow(1.-roundBox(uv-vec2(.5), vec2(.05,.05),.01),r), 0., 1.);
    col += vec3(1.)* clamp( pow(1.-roundBox(uv-vec2(.67,.5), vec2(.05,.05),.01),r), 0., 1.);
    col += vec3(1.)* clamp( pow(1.-roundBox(uv-vec2(.67,.67), vec2(.05,.05),.01),r), 0., 1.);
    col += vec3(1.)* clamp( pow(1.-roundBox(uv-vec2(.5,.67), vec2(.05,.05),.01),r), 0., 1.);
    col += vec3(1.,.5,.1)*2. * clamp( pow(1.-roundBox(uv-vec2(.3,.7), vec2(.01,.01),.2),r), 0., 1.);
    
    return min(col*(1.-lod*.8),vec3(1.));
}


float hash( float n )//->0:1
{
    return fract(sin(n)*3538.5453);
}
vec3 randomSphereDir(vec2 rnd)
{
	float s = rnd.x*PI*2.;
	float t = rnd.y*2.-1.;
	return vec3(sin(s), cos(s), t) / sqrt(1.0 + t * t);
}
vec3 randomHemisphereDir(vec3 dir, float i)
{
	vec3 v = randomSphereDir( vec2(hash(i+1.), hash(i+2.)) );
	return v * sign(dot(v, dir));
}

float ambientOcclusion( in vec3 p, in vec3 n, float maxDist, float falloff )
{
	const int nbIte = 32;
    const float nbIteInv = 1./float(nbIte);
    const float rad = 1.-1.*nbIteInv; //Hemispherical factor (self occlusion correction)
    
	float ao = 0.0;
    
    for( int i=0; i<nbIte; i++ )
    {
        float l = hash(float(i))*maxDist;
        vec3 rd = normalize(n+randomHemisphereDir(n, l )*rad)*l; // mix direction with the normal
        													    // for self occlusion problems!
        
        ao += (l - map( p + rd )) / pow(1.+l, falloff);
    }
	
    return clamp( 1.-ao*nbIteInv, 0., 1.);
}

vec3 raymarche( in vec3 ro, in vec3 rd, in vec2 nfplane )
{
	vec3 p = ro+rd*nfplane.x;
	float t = 0.;
	for(int i=0; i<1256; i++)
	{
        float d = map(p);
        t += d;
        p += rd*d;
		if( t > nfplane.y )
            break;
            
	}
	
	return p;
}
vec3 normal( in vec3 p )
{
	vec3 eps = vec3(0.0001, 0.0, 0.0);
	return normalize( vec3(
		map(p+eps.xyy)-map(p-eps.xyy),
		map(p+eps.yxy)-map(p-eps.yxy),
		map(p+eps.yyx)-map(p-eps.yyx)
	) );
}



mat3 lookat( in vec3 fw, in vec3 up )
{
	fw = normalize(fw);
	vec3 rt = normalize( cross(fw, normalize(up)) );
	return mat3( rt, cross(rt, fw), fw );
}
