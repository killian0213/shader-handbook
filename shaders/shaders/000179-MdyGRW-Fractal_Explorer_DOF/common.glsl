// Common (common) — Fractal Explorer DOF by Dave_Hoskins
// https://www.shadertoy.com/view/MdyGRW

#define CSize vec3(1., 1.7, 1.)

float Map( vec3 p )
{
	p = p.xzy;
	float scale = 1.1;
	for( int i=0; i < 8;i++ )
	{
		p = 2.0*clamp(p, -CSize, CSize) - p;
		float r2 = dot(p,p);
        //float r2 = dot(p,p+sin(p.z*.3)); //Alternate fractal
		float k = max((2.)/(r2), .5);
		p     *= k;
		scale *= k;
	}
	float l = length(p.xy);
	float rxy = l - 1.0;
	float n = l * p.z;
	rxy = max(rxy, (n) / 8.);
	return (rxy) / abs(scale);
}
