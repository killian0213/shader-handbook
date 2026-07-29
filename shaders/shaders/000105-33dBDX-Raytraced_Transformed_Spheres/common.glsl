// Common (common) — Raytraced Transformed Spheres by Shane
// https://www.shadertoy.com/view/33dBDX

/*
// Intersection of a sphere of radius "r".
float traceSphere(in vec3 oc, in vec3 rd, float r){

	float b = dot(oc, rd);
    if(b > 0.) return 1e8;
	float c = dot(oc, oc) - r*r;
	float h = b*b - c;
	if(h<0.) return 1e8;
	return -b - sqrt(h); 
    
}
*/

// Cotterzz's raytraced sphere fix: The standard function most 
// of us use doesn't really cater for miniscule spheres. If speed
// was a concern and the spheres were larger (most of the time,
// they are), you could use the regular one.
float traceSphere(in vec3 oc, in vec3 rd, float r){
    
    float b = dot(oc, rd);
    if(b > 0.) return 1e8;

    // OLD: catastrophic cancellation near silhouette edges
    // float c = dot(oc, oc) - r*r;
    // float h = b*b - c;

    // NEW: h = r² - |oc × rd|²  (stable, no large-minus-large)
    vec3 cx = cross(oc, rd);
    float h = r*r - dot(cx, cx);

    if(h < 0.) return 1e8;
    return -b - sqrt(h);
}


// Plane intersection: Old formula, and could do with some tidying up.
// The tiny "9e-7" figure is something I hacked in to stop near plane 
// artifacts from appearing. I don't like it at all, but not a single 
// formula I found deals with the problem. There definitely has to be
// a better way, so if someone knows of a more robust formula, I'd 
// love to use it.
float tracePlane(vec3 ro, vec3 rd, vec3 n, vec3 o){


    float t = 1e8;
 
	float ndotdir = dot(rd, n);
     
	if (ndotdir<0.){
	
		float dist = -(dot(ro - o, n) + 9e-7*0.)/ndotdir;	// + 9e-7
   		
		if (dist>0.){ 
            t = dist; 
  		}
	}
    
    return t;

}

// Two sphere distances, used for soft shadowing.
vec2 sphDistances(in vec3 ro, in vec3 rd, in vec4 sph )
{
	vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    float d = sqrt( max(0., sph.w*sph.w - h)) - sph.w;
    return vec2(d, -b-sqrt(max(h,0.0)) );
}

// IQ's soft shadow formula for spheres. He wrote an article on it
// that is worth the read.
//
// Related info: https://iquilezles.org/articles/spherefunctions
float sphSoftShadow( in vec3 ro, in vec3 rd, in vec4 sph )
{
    float s = 1.;
    vec2 r = sphDistances( ro, rd, sph );
    if(r.y>0.0 )
        s = max(r.x, 0.0)/r.y;
    return s;
} 
