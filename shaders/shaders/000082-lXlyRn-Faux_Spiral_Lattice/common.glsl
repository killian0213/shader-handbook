// Common (common) — Faux Spiral Lattice by Shane
// https://www.shadertoy.com/view/lXlyRn


////////
// A 2D triangle partitioning. I've dropped in an old routine here.
// It works fine, but could do with some fine tuning. By the way, this
// will partition all repeat grid triangles, not just equilateral ones.

// Skewing coordinates. "s" contains the X and Y skew factors.
vec2 skewXY(vec2 p, vec2 s){ return mat2(1, -s.yx, 1)*p; }

// Unskewing coordinates. "s" contains the X and Y skew factors.
vec2 unskewXY(vec2 p, vec2 s){ return inverse(mat2(1, -s.yx, 1))*p; }

// Triangle scale: Smaller numbers mean smaller triangles, oddly enough. :)
const float scale = 1./3.;
 
float gTri;

vec4 getTriVerts(in vec2 p, inout mat3x2 vID, inout mat3x2 v){

    // Rectangle scale.
    const vec2 rect = (vec2(1./.8660254, 1))*scale;

    // Skewing half way along X, and not skewing in the Y direction.
    const vec2 sk = vec2(rect.x*.5, 0)/scale; // 12 x .2

    // Skew the XY plane coordinates.
    p = skewXY(p, sk);
    
    // Unique position-based ID for each cell. Technically, to get the central position
    // back, you'd need to multiply this by the "rect" variable, but it's kept this way
    // to keep the calculations easier. It's worth putting some simple numbers into the
    // "rect" variable to convince yourself that the following makes sense.
	vec2 id = floor(p/rect) + .5; 
    // Local grid cell coordinates -- Range: [-rect/2., rect/2.].
	p -= id*rect; 
    
    
    // Equivalent to: 
    //gTri = p.x/rect.x < -p.y/rect.y? 1. : -1.;
    // Base on the bottom (-1.) or upside down (1.);
    gTri = dot(p, 1./rect)<0.? 1. : -1.;
   
    // Puting the skewed coordinates back into unskewed form.
    p = unskewXY(p, sk);
    
    
    // Vertex IDs for each partitioned triangle: The numbers are inflated
    // by a factor of 3 to ensure vertex IDs are precisely the same. The
    // reason behind it is that "1. - 1./3." is not always the same as
    // "2./3" on a GPU, which can mess up hash logic. However, "3. - 2."
    // is always the same as "1.". Yeah, incorporating hacks is annoying, 
    // but GPUs don't work as nicely as our brains do, unfortunately. :)
    if(gTri<0.){
        vID = mat3x2(vec2(-1.5, 1.5), vec2(1.5, -1.5), vec2(1.5));
    }
    else {
        vID = mat3x2(vec2(1.5, -1.5), vec2(-1.5, 1.5), vec2(-1.5));
    }
    
    // Triangle vertex points.
    for(int i = 0; i<3; i++) v[i] = unskewXY(vID[i]*rect/3., sk); // Unskew.
    
    // Centering at the zero point.
    vec2 ctr = (v[0] + v[1] + v[2])/3.;
    p -= ctr;
    v[0] -= ctr; v[1] -= ctr; v[2] -= ctr;
    
    // Centered ID, taking the inflation factor of three into account.
    vec2 ctrID = (vID[0] + vID[1] + vID[2])/3.;//vID[2]/3.;
    vec2 tID = id*3. + ctrID;   
    // Since these are out by a factor of three, "v = vertID*rect/3.".
    vID[0] -= ctrID; vID[1] -= ctrID; vID[2] -= ctrID;


    // Triangle local coordinates (centered at the zero point) and 
    // the central position point (which acts as a unique identifier).
    return vec4(p, id);
}

/*
// IQ;s signed distance to an equilateral triangle.
// https://www.shadertoy.com/view/Xl2yDW
float sdEqTri(in vec2 p, in float r){

    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r/k;
    if(p.x + k*p.y>0.) p = vec2(p.x - k*p.y, -k*p.x - p.y)/2.;
    p.x -= clamp(p.x, -2.*r, 0.);
    return -length(p)*sign(p.y);
}
*/
  

// Signed distance to a line passing through A and B.
float distLineS(vec2 p, vec2 a, vec2 b){

   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b));
}