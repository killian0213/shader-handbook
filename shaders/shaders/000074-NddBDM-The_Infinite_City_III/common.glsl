// Common (common) — The Infinite City III by fancyzero
// https://www.shadertoy.com/view/NddBDM

#define FREE_CAMERA_MOVE 0
const uint k = 1103515245U;  // GLIB C

vec3 hash( uvec3 x , uint seed)
{
    x += uvec3(seed);
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    
    return vec3(x)*(1.0/float(0xffffffffU));
}

vec3 random(int row,int col, float seed)
{
    return hash( uvec3(row, col, col), uint(seed));
}

int randomRange( int _min , int _max, int row, int col, float seed )
{
    return int(random( row, col, seed) *float(_max-_min))+_min;
}

int randomRange2( int _min , int _max, int row, int col, float seed )
{
    vec3 r = random( row, col, seed) ;
    r *= r;
    return int(r*float(_max-_min))+_min;
}



float randomRange( float _min , float _max, int row, int col, float seed )
{
    return random( row, col, seed).x *(_max-_min)+_min;
}



vec2 boxIntersection( in vec3 ro, in vec3 rd, in vec3 rad, out vec3 oN ) 
{
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
	
    if( tN>tF || tF<0.0) 
        return vec2(-1.0); // no intersection
    
    oN = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);

    return vec2( tN, tF );
}


vec4 getMipRect( vec2 res , float lod)
{
   vec2 size = res.xy * pow(2.,-lod)*0.5;
   vec2 maxPos = res.xy * (2. - pow(2.,-lod))*0.5;
   vec2 minPos = maxPos - size;
   maxPos.y = size.y;
   minPos.y = 0.;
   return vec4(minPos, maxPos);
}


vec2 getMipUV( vec2 uv )
{
     float lod = floor(abs(log2(1.-uv.x)));
     vec4 rect = getMipRect(vec2(1.,1.), lod);
     vec2 size = vec2(pow(2.,-lod)*0.5);
     return (uv - rect.xy)/size;
  
}


vec3 getCameraPositionFromBufferA(sampler2D bufferA)
{
 	return texture(bufferA, vec2(0.0, 0.0)).xyz;
}

mat3 getCameraRotationFromBufferA(sampler2D bufferA, vec2 resolution)
{
 	
    vec2 cameraAngle = texture(bufferA, vec2(1.2, 0.0) / resolution.xy).xy;
    
    mat3 cameraRotation = mat3(cos(cameraAngle.x), 0.0, -sin(cameraAngle.x),
                                0.0, 1.0, 0.0,
                                sin(cameraAngle.x), 0.0, cos(cameraAngle.x)) *
        				  mat3(1.0, 0.0, 0.0,
                                  0.0, cos(cameraAngle.y), -sin(cameraAngle.y),
                                  0.0, sin(cameraAngle.y), cos(cameraAngle.y));
    
    return cameraRotation;
}
