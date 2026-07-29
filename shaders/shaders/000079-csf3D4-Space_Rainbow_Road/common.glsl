// Common (common) — Space Rainbow Road by rcargou
// https://www.shadertoy.com/view/csf3D4

mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

vec2 hash22( vec2 p )
{
    //p = mod(p, 4.0); // tile
    p = vec2(dot(p,vec2(175.1,311.7)),
             dot(p,vec2(260.5,752.3)));
    return fract(sin(p+455.)*18.5453);
}


float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float sdTriangle( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2 )
{
	vec2 e0 = p1 - p0;
	vec2 e1 = p2 - p1;
	vec2 e2 = p0 - p2;

	vec2 v0 = p - p0;
	vec2 v1 = p - p1;
	vec2 v2 = p - p2;

	vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
	vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
	vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    
    float s = e0.x*e2.y - e0.y*e2.x;
    vec2 d = min( min( vec2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                       vec2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                       vec2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));

	return -sqrt(d.x)*sign(d.y);
}

vec3 saturate(vec3 x)
{
    return clamp(x, vec3(0.0), vec3(1.0));
}


float sdCross(vec2 p) {
    p *= 2.;
    vec2 p2 = vec2(p.y, p.x);
    p2.y = abs(p2.y);
    p2.y -=.0;
    p.y = abs(p.y);
    p.y-=.0;

	vec2 v1 = vec2(-.5, 0.);
	vec2 v2 = vec2(.5, 0.);
	vec2 v3 = vec2(0., 1.5);
    float sd1= sdTriangle(p, v1, v2, v3);
    float sd2 = sdTriangle(p2, v1, v2, v3);
    return min(sd1, sd2);

}

 
mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

float sdStar(vec2 p) {
    float d1 = sdCross(p);
    float d2 = sdCross(rotate2d(3.14 / 4.) * p  );
    return min(d1, d2);
}


float opExtrusion( in vec3 p, in float h )
{
    float d = sdStar(p.xy);
    vec2 w = vec2( d, abs(p.z) - h );
    return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}