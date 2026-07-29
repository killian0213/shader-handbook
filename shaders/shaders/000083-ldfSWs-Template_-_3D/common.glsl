// Common (common) — Template - 3D by iq
// https://www.shadertoy.com/view/ldfSWs

//------------------------------------------------------------------------
// SDF functions
//
// More info: https://iquilezles.org/articles/distfunctions/
//------------------------------------------------------------------------
float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    float g = max(d.x,max(d.y,d.z));
    return g < 0.0 ? g : length(max(d,0.0));
}

//------------------------------------------------------------------------
// Matrices
//------------------------------------------------------------------------
mat4 rotate( vec3 v, float a ) // axis, angle
{
    float s = sin( a );
    float c = cos( a );
    float ic = 1.0 - c;
    return mat4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                 v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                 v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
			     0.0,                0.0,                0.0,                1.0 );
}

mat4 translate( float x, float y, float z )
{
    return mat4( 1.0, 0.0, 0.0, 0.0,
				 0.0, 1.0, 0.0, 0.0,
				 0.0, 0.0, 1.0, 0.0,
				 x,   y,   z,   1.0 );
}

mat4x4 computeLookAt( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ro-ta);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cp,cw) );
	vec3 cv =          ( cross(cw,cu) );
    return mat4x4( cu, 0.0, 
                   cv, 0.0,
                   cw, 0.0,
                   ro, 1.0);
}