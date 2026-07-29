// Buffer A (buffer) — Sinuous by nimitz
// https://www.shadertoy.com/view/4sGSDw

//Sinuous by nimitz (twitter: @stormoid)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

//Velocity handling

const float initalSpeed = 10.;
#define time iTime

//From Dave (https://www.shadertoy.com/view/4djSRW)
vec2 hash(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3.zxy, p3.yxz+19.19);
    return fract(vec2(p3.x * p3.y, p3.z*p3.x))*2.0 - 1.0;
}

//From iq (https://www.shadertoy.com/view/XdXGW8)
float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
	
	vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

const mat2 m2 = mat2( 0.80, -0.60, 0.60, 0.80 );
float fbm( in vec2 p, float tm )
{
    p *= 2.0;
    p -= tm;
	float z=2.;
	float rz = 0.;
    p += time*0.001 + 0.1;
	for (float i= 1.;i < 7.;i++ )
	{
		rz+= abs((noise(p)-0.5)*2.)/z;
		z = z*1.93;
        p *= m2;
		p = p*2.;
	}
	return rz;
}

vec3 update(in vec3 vel, vec4 p, in float id) { 
    
    float n1a = fbm(p.xy, p.w);
    float n1b = fbm(p.yx, p.w);
    float nn = fbm(vec2(n1a,n1b),0.)*5.8 + .5;
    
    vec2 dir = vec2(cos(nn), sin(nn));
    vel.xy = mix(vel.xy, dir*1.5, 0.005);
    return vel;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    
    vec4 col= vec4(0);
    vec2 w = 1./iResolution.xy;
    if (fragCoord.y > 60.)discard;
    
    //vec2 mo = iMouse.xy/iResolution.xy;
    
    vec4 pos = texture(iChannel0, vec2(q.x,100.*w));
    vec3 velo = texture(iChannel0, vec2(q.x,0.0)).xyz;
    velo = update(velo, pos, pos.w);
    col.w = pos.w;
    
    float mdf = mod(float(iFrame),1601.);
    
    if (fragCoord.y < 30.)
    {
    	if (mdf < 2.5)
        {
            col = vec4(0.1,0,0,0);
            col.w++;
        }
        else
        	col.rgb = velo;
    }
    else
    {
        if (mdf < 2.5)
        {
            pos = vec4(-0.99,((texture(iChannel1, q*1.+3.15 + time))-.5).x,0,0);
            col.w++;
        }
        pos.xy += velo.xy*0.002;
        col.xyz = pos.xyz;
    }
    
	
    //Init
    if (iFrame < 15) 
    {
        if (fragCoord.y < 30.)
            col = vec4(0.1,0,0,0);
        else {
            col = vec4(-0.99,((texture(iChannel1, q*.5+3.15))-.5).x,0,0);;
        }
    }
    
	fragColor = col;
}