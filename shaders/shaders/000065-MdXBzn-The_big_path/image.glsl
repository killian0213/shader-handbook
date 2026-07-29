// Image (image) — The big path by antonOTI
// https://www.shadertoy.com/view/MdXBzn

#define STEP 256
#define EPS .001


// from various shader by iq

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

const mat2 m = mat2(.8,.6,-.6,.8);

float noise( in vec2 x )
{
	return sin(1.5*x.x)*sin(1.5*x.y);
}

float fbm6( vec2 p )
{
    float f = 0.0;
    f += 0.500000*(0.5+0.5*noise( p )); p = m*p*2.02;
    f += 0.250000*(0.5+0.5*noise( p )); p = m*p*2.03;
    f += 0.125000*(0.5+0.5*noise( p )); p = m*p*2.01;
    f += 0.062500*(0.5+0.5*noise( p )); p = m*p*2.04;
    //f += 0.031250*(0.5+0.5*noise( p )); p = m*p*2.01;
    f += 0.015625*(0.5+0.5*noise( p ));
    return f/0.96875;
}


mat2 getRot(float a)
{
    float sa = sin(a), ca = cos(a);
    return mat2(ca,-sa,sa,ca);
}


vec3 _position;

float sphere(vec3 center, float radius)
{
    return distance(_position,center) - radius;
}

float hozPlane(float height)
{
    return distance(_position.y,height);
}

float swingPlane(float height)
{
    vec3 pos = _position + vec3(0.,0.,iTime * 2.5);
    float def =  fbm6(pos.xz * .25) * 1.;
    
    float way = pow(abs(pos.x) * 34. ,2.5) *.0000125;
    def *= way;
    
    float ch = height + def;
    return max(pos.y - ch,0.);
}

float map(vec3 pos)
{
    _position = pos;
    
    float dist;
    dist = swingPlane(0.);
    
    float sminFactor = 5.25;
    dist = smin(dist,sphere(vec3(0.,-15.,80.),45.),sminFactor);
    return dist;
}


vec3 getNormal(vec3 pos)
{
    vec3 nor = vec3(0.);
    vec3 vv = vec3(0.,1.,-1.)*.01;
    nor.x = map(pos + vv.zxx) - map(pos + vv.yxx);
    nor.y = map(pos + vv.xzx) - map(pos + vv.xyx);
    nor.z = map(pos + vv.xxz) - map(pos + vv.xxy);
    nor /= 2.;
    return normalize(nor);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord.xy-.5*iResolution.xy)/iResolution.y;
    
    vec3 rayOrigin = vec3(uv + vec2(0.,6.), -1. );
    
    vec3 rayDir = normalize(vec3(uv , 1.));
    
   	rayDir.zy = getRot(.05) * rayDir.zy;
   	rayDir.xy = getRot(.075) * rayDir.xy;
    
    vec3 position = rayOrigin;
    
    
    float curDist;
    int nbStep = 0;
    
    for(; nbStep < STEP;++nbStep)
    {
        curDist = map(position + (texture(iChannel0, position.xz) - .5).xyz * .005);
        
        if(curDist < EPS)
            break;
        position += rayDir * curDist * .5;
    }
    
    float f;
    
    //sound = sin(iTime) * .5 + .5;
    
    float dist = distance(rayOrigin,position);
    f = dist /(98.);
    f = float(nbStep) / float(STEP);
    
    f *= .8;
    vec3 col = vec3(f);
    
    
    //float shouldColor = 1.- step(f,threshold);
    //col = mix(col,vec3(1.,0.,0.) ,shouldColor);
    
    fragColor = vec4(col,1.0);
}