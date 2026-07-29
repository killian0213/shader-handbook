// Common (common) — Mysterious Roman Dodecahedron by sylvain69780
// https://www.shadertoy.com/view/Nsd3Wl



// Normal of a plan having a dihedral angle of PI/3 with the YZ plan and PI/5 with the XZ plane
const float CP = cos(3.14159/5.), SP=sqrt(0.75-CP*CP);
const vec3  P35 = vec3(-0.5, -CP, SP);

// Dihedral angles of the Dode. and Ico.
// This probably can be obtained using linera algebra calculations
// https://en.wikipedia.org/wiki/Table_of_polyhedron_dihedral_angles

const float ICODIHEDRAL  = acos(sqrt(5.)/3.);  
const float DODEDIHEDRAL = acos(sqrt(5.)/5.);

// below are the directions from the origin limiting the coordniate's domain after folding space
// trivial, this is the Z axis
const vec3 ICOMIDEDGE = vec3(0,0,1); 
// direction in the XZ plan, the ICO vertex on this line
// I think this is also the normal of a DODE face
const vec3 ICOVERTEX  = normalize(vec3(SP,0.0,0.5)); 
// direction in the YZ plan, you will find the DODE vertex on this line
// I think this is also the normal of an ICO face
const vec3 ICOMIDFACE = normalize(vec3(0.0,SP,CP));  
/*

    This represents the up view of a Rhombic face at z = 1 
    This can help to draw some figures on the faces

                Y_TO_DODE_VERTEX
                Y_TO_ICO_CENTER (after ICODIHEDRAL rotation on X axis)
                
                         ** 
                      ********
                   ***   **    ***
                ***      **       ***
             ***         **          ***
          ***            **             ***
       ***               **                ***
    ***                  ** (0,0)             ***
 ***************************************************  X_TO_ICO_VERTEX
    ***                  **                   ***    X_TO_DODE_CENTER (after DODEDIHEDRAL rotation on Y axis)
       ***               **                ***
          ***            **             ***
             ***         **          ***
                ***      **       ***
                   ***   **    ***
                      ********
                         ** 

*/

const float X_TO_ICO_VERTEX  = length(cross(ICOMIDEDGE,ICOVERTEX))/dot(ICOMIDEDGE,ICOVERTEX);
const float Y_TO_DODE_VERTEX = length(cross(ICOMIDEDGE,ICOMIDFACE))/dot(ICOMIDEDGE,ICOMIDFACE);
const float X_TO_DODE_CENTER = X_TO_ICO_VERTEX*cos(DODEDIHEDRAL*.5);
const float Y_TO_ICO_CENTER  = Y_TO_DODE_VERTEX*cos(ICODIHEDRAL*.5);

// https://iquilezles.org/articles/smin
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float sdSphere( vec3 p, float r )
{
	return length(p) - r;
}

// List of other 2D distances: https://www.shadertoy.com/playlist/MXdSRf
//
// and iquilezles.org/articles/distfunctions2d


float sdBlobbyCross( in vec2 pos, float he )
{
    pos = abs(pos);
    pos = vec2(abs(pos.x-pos.y),1.0-pos.x-pos.y)/sqrt(2.0);


    float p = (he-pos.y-0.25/he)/(6.0*he);
    float q = pos.x/(he*he*16.0);
    float h = q*q - p*p*p;
    
    float x;
    if( h>0.0 ) { float r = sqrt(h); x = pow(q+r,1.0/3.0) - pow(abs(q-r),1.0/3.0)*sign(r-q); }
    else        { float r = sqrt(p); x = 2.0*r*cos(acos(q/(p*r))/3.0); }
    x = min(x,sqrt(2.0)/2.0);
    
    vec2 z = vec2(x,he*(1.0-2.0*x*x)) - pos;
    return length(z) * sign(z.y);
}

float sdHorseshoe( in vec2 p, in vec2 c, in float r, in vec2 w )
{
    p.x = abs(p.x);
    float l = length(p);
    p = mat2(-c.x, c.y, 
              c.y, c.x)*p;
    p = vec2((p.y>0.0 || p.x>0.0)?p.x:l*sign(-c.x),
             (p.x>0.0)?p.y:l );
    p = vec2(p.x,abs(p.y-r))-w;
    return length(max(p,0.0)) + min(0.0,max(p.x,p.y));
}

float opExtrussion( in vec3 p, in float sdf, in float h )
{
    vec2 w = vec2( sdf, abs(p.z) - h );
  	return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}

float dot2( in vec2 v ) { return dot(v,v); }

float sdHeart( in vec2 p )
{
    p.x = abs(p.x);

    if( p.y+p.x>1.0 )
        return sqrt(dot2(p-vec2(0.25,0.75))) - sqrt(2.0)/4.0;
    return sqrt(min(dot2(p-vec2(0.00,1.00)),
                    dot2(p-0.5*max(p.x+p.y,0.0)))) * sign(p.x-p.y);
}

float sdSegment( in vec3 p, in vec3 a, in vec3 b )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdRoundedX( in vec2 p, in float w, in float r )
{
    p = abs(p);
    return length(p-min(p.x+p.y,w)*0.5) - r;
}

// https://www.shadertoy.com/view/XsXfz2
// distancefield of torus around arbitrary axis z
// similar to https://iquilezles.org/articles/distfunctions
float distTorus(vec3 pos, float r1, float r2, vec3 z)
{
    float pz = dot(pos,normalize(z));
    return length(vec2(length(pos-z*pz)-r1,pz))-r2;
}


// Blackle Mori
vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

mat2 orient(vec2 a)
{
    return mat2(a.x,a.y,-a.y,a.x);
}


// Shane awesome work below
// Tri-Planar blending function. Based on an old Nvidia tutorial.
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
    
    //return cellTileColor(p);
  
    n = max((abs(n) - 0.2)*7., 0.001); // n = max(abs(n), 0.001), etc.
    n /= (n.x + n.y + n.z ); 
	return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}

// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. I tried to 
// make it as concise as possible. Whether that translates to speed, or not, I couldn't say.
vec3 texBump( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(0.002, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.    
    mat3 m = mat3( tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
	
}

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001
#define T (iTime*.05)

const float PI = 3.14159265359;
const float PHI = (1.+sqrt(5.))/2.;


