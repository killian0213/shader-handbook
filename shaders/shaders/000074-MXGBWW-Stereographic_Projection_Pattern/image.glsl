// Image (image) — Stereographic Projection Pattern by Shane
// https://www.shadertoy.com/view/MXGBWW

/*

    Stereographic Projection Pattern
    --------------------------------

    Occasionally, I like to render a cliche "sphere on a plane" scenario, then
    experiment with different patterns. This is one of many that I have. Some of 
    the patterns are interesting enough to post in their own right, and I will at 
    some stage. I'm posting this particular one because it involves a stereographic
    projection of a basic spherical pattern onto the plane, which I've always liked
    from an aesthetic viewpoint. On the internet, this kind of imagery is common, 
    but not so much on Shadertoy. However, there are a few stereographic projection 
    examples in other forms on here.    
    
    I'm not sure why, but I'm guessing one of the stumbling blocks is mapping patterns 
    onto spheres. I don't really have time to explain that particular aspect. However, 
    I can say that there are a few examples on here, and it's just a slightly more 
    difficult version of cube mapping.
    
    Anyway, the stereographic process itself is very straight forward: Raytrace, or 
    raymarch, a ball on a plane. If the ray hits the sphere, use the sphere's hit 
    point to render a pattern onto it. If you hit the ground, raymarch or raytrace 
    (the faster option) from your current ground point to the top of the sphere 
    (north pole). This will provide another intersection point on the sphere. Plug 
    the resultant point into your spherical pattern function, then use that as your 
    floor color. That's it. If you're comfortable putting patterns onto spheres, it'll 
    be easy. If not, sphere mapping can be a fun and rewarding graphics exercise. :)
    
    I've provided a few "define" options for anyone interested in that. Adding the
    options blew the character count up a bit, but if you strip that all back, this
    would be a pretty short example. In fact, I might put together a short version
    at some stage.
    
    

	Other examples:
    
    
    // Stereogrphic panarama. Beautiful example.
    Snow Ball - iapafoto 
    https://www.shadertoy.com/view/Xtl3zM
    
	// Projecting a dodecahedron to the floor. I like the
    // rendering style.
    StereoProj 3D - Ouid 
	https://www.shadertoy.com/view/lt2XDW 
    
    // Mapping a floor pattern back onto the sphere.
    Stereographic Projection & Lines - culdevu 
    https://www.shadertoy.com/view/XdffRl
    
    // Raymarching a 4D object, then projecting down to 3D.
    // Very cool example.
    Torus Knot in R4 - mla
    https://www.shadertoy.com/view/tsBGzt


*/
/////////////

// Sepia: 0, Dark (blinking): 1, Vibrant 2, Greyscale: 3.
#define COLOR 2

// Metallic look, or not.
#define METALLIC

// Subdivide the triangle pattern.
// Numbers 0 through to 5 work.
#define SUBDIVIDE 2

// Tile holes, or not.
//#define HOLES

// Only show the stereographic pattern.
//#define STEREOGRAPHIC_ONLY

//////////////


// Max ray distance.
#define FAR 8.


// Attempting not to unroll loops.
#define ZERO min(0, iFrame)


#define PI 3.14159265359
#define TAU 6.2831853
#define PHI (1. + sqrt(5.))/2.

///////////////


// Scene object ID to separate the mesh object from the terrain.
int objID;
vec4 vID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

 
 // IQ's "uint" based uvec3 to float hash with Fabrice's modification.
float hash31(vec3 f){
   
    uvec3 p = floatBitsToUint(f);
    p = 1664525U*((p >> 2U)^(p.yzx>>1U)^p.zxy);
    uint h32 = 1103515245U*(((p.x)^(p.y>>3U))^(p.z>>6U));

    uint n = h32^(h32 >> 16);
    return float(n & uint(0x7fffffffU))/float(0x7fffffff);
    
}



/////////////////
/*
// Renders a line between points A and B on a sphere. Very handy.
float sphereLineCapAB2(vec3 p, vec3 a, vec3 b, float rad){
 
     
     p /= rad; // Normalize p.
     
     float ln = dot(p, cross(a, b))/length(a - b);
     
     vec3 perpA = a + cross(b - a, a);
     vec3 perpB = b + cross(a - b, b);
     float endA = dot(p, cross(perpA, a))/length(perpA - a);
     float endB = dot(p, cross(perpB, b))/length(perpB - b);
     
     return sign(ln)*max(max(abs(ln), endA), endB);
      
}
*/

// Renders a line between points A and B on a sphere with no capping. 
float sphereLineAB(vec3 p, vec3 a, vec3 b, float rad){
     
     p = normalize(p); // Set radius: p /= rad; 
     return dot(p, cross(a, b))/length(a - b);

}

// Rotate on axis.
// Blackle https://suricrasia.online/demoscene/functions/
// Point to rotate, point to rotate around, and rotation angle.
vec3 erot(vec3 p, vec3 ax, float ro) {
  return mix(dot(ax, p)*ax, p, cos(ro)) + sin(ro)*cross(ax, p);
}
 
// Ages ago, I had a brief discussion with TDHooper regarding producing a
// simple no-frills icosahedral mapping function that takes in 3D coordinates
// and gives you back the triangular cell face center and the three vertices.
// With that information, you can produce icosahedral-based patterns. In turn,
// that also means that dodecahedral patterns are possible too, since the central 
// icosahedral face position represents the dual dodecahedral vertices.
//
// Closest icosahedron face center, and cell vertices: Just a slight rewriting
// of one of TdHooper's functions. Obviously, it's more complicated than selecting 
// cube faces, but it involves the same process, which is stepping on either side 
// of planes.
//
// By the way, it's very easy to rewrite this to produce the dodecahedron center
// and vertices.
void icosahedronVerts(in vec3 p, out vec3 face, out mat3x3 vert) {
  
    // Icosaheral Vertices.
    //
    // If you look up icosahedron (Pacioli) construction, you'll likely come across a
    // picture of 3 mutually perpendicular 2 by 1 rectangles (hypotenuse, sqrt(5)),
    // the corners of which will represent icosahedron vertices. The following is just 
    // stepping across various angled planes until you arrive in the correct cell.
    vec3 V = vec3(PHI, 1,  0);
    vec3 ap = abs(p), v = V;
    if (dot(ap, V.yzx - v) > 0.) v = V.yzx;
    if (dot(ap, V.zxy - v) > 0.) v = V.zxy;
    vert[0] = normalize(v)*sign(p);
    
    // Dodecahedron vertices: Icosahedrons and dodecahedrons are duals, so the 
    // dodecahedral vertices align to the center of the icosahedron cells, which 
    // is pretty handy, since we need the cell center. :)
    v = V.xxx;
    V = vec3(V.zy, V.x + V.y);
    if (dot(ap, V - v) > 0.) v = V;
    if (dot(ap, V.yzx - v) > 0.) v = V.yzx;
    if (dot(ap, V.zxy - v) > 0.) v = V.zxy;
    face = normalize(v)*sign(p);
   
    // Triangle rotation angle -- For dodecahedral pentagons, you'd swap the face
    // and vertex information above, use TAU/5, then produce four other vertices.
    float ang = TAU/3.;
    
    // You can skip this if you don't care about the 2nd vert
    // always being the 2nd closest.
    //float side = boolSign(dot(p, cross(a, face))); ang *= side;
    
    // Rotating the icosahedron vertex around the cell center by TAU/3 will 
    // give you one of the other vertices, and rotating the other way produces 
    // the other. Obvious... once someone provides the answer. :D
    //
    // Point to rotate, pivot point (to rotate around), and rotation angle.
    vert[1] = erot(vert[0], face, -ang);
    vert[2] = erot(vert[0], face, ang);
    
 
}

// Rolling the ball on the plane.
vec3 rollObj(vec3 p){
    
    // The extra terms (PI/10 and atan(PHI)) are only there to align the sphere 
    // to a position I prefer at the zero second mark. They're not necessary.
    p.xz *= rot2(iTime/4. + PI/10.);
    p.xy *= rot2(iTime/2. + atan(PHI));
   
    return p;
}
 

vec3 gID;

// Due to me getting bored and wanting to try different triangle based
// subdivisions, this is a little messy. However, none of it is difficult.
// Obtain the icosahedral face triangle information, then use that information
// to check spherical line distances in order to determine which region you're in.
//
// This is subdivision 101. If you're not sure about it, play around with 
// the concept in 2D. Render a triangle, try splitting across a central
// Euclidean line, color each side, then take it from there.
float getPattern(vec3 p){
    
    // Roll the object.
    p = rollObj(p);
    
    // Icosahedron triangle polygon face center and vertex postions.
    vec3 face;
    mat3x3 v;
    icosahedronVerts(p, face, v);
    
    // Giving the central face position and vertices the sphere's radius. 
    float rad = .5; // Sphere radius.
    face *= rad;
    v *= mat3x3(rad);

    // Face ID.
    gID = face;
  
    // Two points on either side of each triangle edge midpoint. There
    // are six in all. Connecting all six lines will form a hexagon in
    // the middle of the icosahedral triangle.
    //
    // I made this up on the spot, so there are probably better ways
    // to do it. However, I'm not aware of space folding techniques
    // that can achieve this pattern. Someone like TdHooper, knighty,
    // MLA, or Djinn Kahn might, however.
    vec3[3] mid;
    
    // Mid line ratio. "1/2" and "1/3" give different configurations. 
    float midRatio = 1./2.;
    #if SUBDIVIDE == 3
    midRatio = 1./3.;
    #endif
    #if SUBDIVIDE == 5
    midRatio = 1./3.;
    #endif
    for(int i = 0; i<3; i++){
        mid[i] = normalize(mix(v[i], v[(i + 1)%3], midRatio))*rad;
       
    }
    
    // The spherical face polygon. What you produce is up to you.
    float poly = -1e5;

    
    // Triangle border lines, center to vertex lines, and center to mid-edge lines.
    vec3 tri3;
    vec3 lnV;
    vec3 lnMid;
    
    
    for(int i = 0; i<3; i++){
       tri3[i] = sphereLineAB(p, v[i], v[(i + 1)%3], rad);
       lnV[i] = sphereLineAB(p, face, v[i], rad);
       lnMid[i] = sphereLineAB(p, face, mid[i], rad);
    }
    
    #if SUBDIVIDE > 1
     
    // Subdivide the triangles into quads.
    lnMid = max(lnMid, -lnMid.yzx);
    
    // Line stepping to see which region we're in. Sometimes, only the last 
    // check is necessary, but not always, so since this example isn't too
    // taxing on the GPU, we'll check them all.
    
    // Splitting the triangle into quads.
    if(lnMid.x<0.){
    
        gID = (face + v[1] + mid[0] + mid[1])/4.;//mix(face, v[1], .4);
        poly = max(max(tri3.x, tri3.y), lnMid.x);
        
        // This option splits the quads into smaller triangles.
        #if SUBDIVIDE > 3
        if(lnV.y<0.){ poly = max(poly, lnV.y);  gID = (face + v[1] + mid[1])/3.; }
        else { poly = max(poly, -lnV.y); gID = (face + v[1] + mid[0])/3.; }
        #endif 
    }
    else if(lnMid.y<0.){
    
        gID = (face + v[2] + mid[1] + mid[2])/4.;///mix(face, v[2], .4);
        poly = max(max(tri3.y, tri3.z), lnMid.y);
        
        #if SUBDIVIDE > 3
        if(lnV.z<0.){ poly = max(poly, lnV.z);  gID = (face + v[2] + mid[2])/3.; }
        else { poly = max(poly, -lnV.z); gID = (face + v[2] + mid[1])/3.; }
        #endif
    }
    else {
        gID = (face + v[0] + mid[2] + mid[0])/4.;//mix(face, v[0], .4);
        poly = max(max(tri3.z, tri3.x), lnMid.z);

        #if SUBDIVIDE > 3
        if(lnV.x<0.){ poly = max(poly, lnV.x);  gID = (face + v[0] + mid[0])/3.; }
        else { poly = max(poly, -lnV.x); gID = (face + v[0] + mid[2])/3.; }
        #endif
    }
    #else
    
    // Subdivision 0 and 1. Triangles and face-to-edge.
    // Triangle pattern only.
    poly =  max(max(tri3.x, tri3.y), tri3.z);
    
    #if SUBDIVIDE == 1
    lnV = max(lnV, -lnV.yzx);
    
    if(lnV.x<0.){ poly = max(poly, lnV.x);  gID = (face + v[0] + v[1])/3.; }
    else if(lnV.y<0.){ poly = max(poly, lnV.y); gID = (face + v[1] + v[2])/3.; }
    else { poly = max(poly, lnV.z); gID = (face + v[0] + v[2])/3.;  }
    
    #endif
    #endif
    
    // Accuracy problems, due to points sitting on borders of regions --
    // It's the "1 - 1/3" not equaling "2/3" on computers problem, and other
    // reasons... Anyway, my hacky fix is to snap virtually equal points
    // to a a decimal that the GPU is comfortable with.
 
    // Even something like "32768" will work, but I'm using something smaller.
    // If we use the ID for distance based work, then snapping it to the spherical
    // surface (gID = normalize(gID)*rad) would be more correct, but it's only
    // being used for coloring.
    gID = floor(gID*1024. + .001)/1024.;
   
    #ifdef HOLES
    // Polygon holes. I do this a bit. Sometimes it can break up the 
    // monotony, and other times, it looks overblown and busy.
    #if SUBDIVIDE < 3
    poly = abs(poly + .044) - .044; // Shape based.
    #elif SUBDIVIDE == 3
    poly = abs(poly + .04) - .04; // Shape based.
    #else
    poly = abs(poly + .032) - .032;
    #endif
    //poly = max(poly, -(length(p - normalize(gID)/2.) + .0)); // Round.
    #endif
    
    // The sphere surface polygon.
    return poly;


}
 

// The scene. Probably better to raytrace, but I was feeling lazy. :D
float map(vec3 p){
    
    // Floor.
    float fl = p.y + .5;//.5;// -(length(p - vec3(0, 16, 0)) - 16. - .5);
    
    #ifdef STEREOGRAPHIC_ONLY
    float obj = 1e5;
    #else
    // Sphere siting on the floor.
    float obj = length(p) - .5;
    #endif
    
  
    // Overall object ID.
    vID = vec4(obj, fl, 1e5, 1e5);
    
    // Combining the floor with the extruded image
    return  min(obj, fl);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = ZERO; i<96; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.

        t += d*.9; 
    }

    return min(t, FAR);
}


// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t){
	
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.002, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}
 
 
// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test 
    // machine anyway.
    const int maxIterationsShad = 32; 
    
    ro += n*.0015;
    vec3 rd = lp - ro; // Unnormalized direction ray.
    

    float shade = 1.;
    float t = 0.;//.0015; // Coincides with the hit condition in the "trace" function.  
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the 
    // lowest number to give a decent shadow is the best one to choose. 
    for (int i = ZERO; i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: 
        // dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        t += clamp(d, .01, .25); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Sometimes, I'll add a constant to the final shade value, which lightens the shadow a bit --
    // It's a preference thing. Really dark shadows look too brutal to me. Sometimes, I'll add 
    // AO also just for kicks. :)
    return max(shade, 0.); 
}


// Sphere intersection: Pretty standard, and adapted from one
// of IQ's formulae.
vec2 sphInter(in vec3 ro, in vec3 rd, in vec4 sph){

    vec3 oc = ro - sph.xyz;
	float b = dot(oc, rd);
    if(b>0.) return vec2(1e8, 0);
	float c = dot(oc, oc) - sph.w*sph.w;
	float h = b*b - c;
	if(h<0.) return vec2(1e8, 0);
	return vec2(-b - sqrt(h), 1); 
    
}

 
// Surface bump function..
float bumpSurf3D(in vec3 p, in vec3 n){


    vec3 txP = p;
  

    float poly = 0.;
    if(objID==0){
       
        // Get the polygon pattern from the sphere.
        poly = -getPattern(txP);
        //poly = min(poly, .07); // Flat top bevel.
    }
    else {
    
        // We are currently on the ground and aiming for the top 
        // of the sphere, so construct a unit direction ray and 
        // direct it toward the top of the sphere. Obtain the 
        // spherical intersection point, then plug that point 
        // into the sphere's mapping function to obtain a value
        // that we can use for coloring, bump mapping etc..
        
        
         // Sphere top position.
        vec3 sphTop = vec3(0, .5, 0);
        // Unit direction ray from out current position to the one above.
        vec3 rrd = normalize(sphTop - p);
        
        // Raymarch intersection. Too slow for this example.
        //float tSph = trace(sp + sn*.0015, rrd);

        // Raytraced sphere intersection.
        vec2 t2 = sphInter(p + n*.0001, rrd, vec4(0, 0, 0, .5));
        float tSph = t2.x;
        
        // Sphere intersection point.
        vec3 sphP = p + tSph*rrd;


        // Roll the point.
        poly = -getPattern(sphP);
        
        // Bevel a little.
        //poly = min(poly, .03)*.9 + poly*.1;
        poly = min(poly, .03);
    
    }
    
    return poly;

}
 
// Standard function-based bump mapping routine: This is the cheaper four tap version. 
// There's a six tap version (samples taken from either side of each axis), but this 
// works well enough.
vec3 doBumpMap(in vec3 p, in vec3 n, float bumpfactor){
    
    // Larger sample distances give a less defined bump, but can sometimes lessen the 
    // aliasing.
    const vec2 e = vec2(.001, 0);  
    
    mat4x3 p4 = mat4x3(p, p - e.xyy, p - e.yxy, p - e.yyx);
    
    // This utter mess is to avoid longer compile times. It's kind of 
    // annoying that the compiler can't figure out that it shouldn't
    // unroll loops containing large blocks of code.
 
    vec4 b4;
    for(int i = min(iFrame, 0); i<4; i++){
        b4[i] = bumpSurf3D(p4[i], n);
        if(n.x>1e5) break; // Fake break to trick the compiler.
    }
    
    // Gradient vector: vec3(df/dx, df/dy, df/dz);
    vec3 grad = (b4.yzw - b4.x)/e.x; 
   
    
    // Six tap version, for comparisson. No discernible visual difference, in a lot of 
    //cases.
    //vec3 grad = vec3(bumpSurf3D(p - e.xyy) - bumpSurf3D(p + e.xyy),
    //                 bumpSurf3D(p - e.yxy) - bumpSurf3D(p + e.yxy),
    //                 bumpSurf3D(p - e.yyx) - bumpSurf3D(p + e.yyx))/e.x*.5;
    
  
    // Adjusting the tangent vector so that it's perpendicular to the normal. It's some 
    // kind of orthogonal space fix using the Gram-Schmidt process, or something to that 
    // effect.
    grad -= n*dot(n, grad);          
         
    // Applying the gradient vector to the normal. Larger bump factors make things more 
    // bumpy.
    return normalize(n + grad*bumpfactor);
	
}

///////////////////////////

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n)
{
	float sca = 2., occ = 0.;
    for( int i = ZERO; i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        //if(occ>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
}


 vec3 getCol(vec3 id, vec3 p){
    
    
    // 3D vector based coloring. Made up as I went along. I'm using IQ's
    // versatile cosine palette formula, which is probably the best
    // one line palette formula I've ever come across... Opinions may vary. :)
   
    // Random values.
    float rnd = hash31(id + .18); 
    float rnd2 = hash31(id + .07); 
    float rndC = dot((id), vec3(1)/3.);
    
    // Some transcendental palette colors.
    #if COLOR == 0
    vec3 col = .5 + .45*cos(TAU*(rnd2 - dot(p, vec3(1)/2.))/4. + vec3(0, 1, 2)*.85 - .2);
    #else
    vec3 col = .5 + .45*cos(TAU*(rnd2 - dot(p, vec3(1)/2.))/4. + vec3(0, 1, 2)*1.3 - .2);
    if(rnd>.8) col = col.zyx;//.zyx;
    #endif
    
    #if COLOR == 1
    vec3 gr = vec3(.5)*dot(col, vec3(.299, .587, .114)); // Greyscale.
    
    //vec3 cCol = col*vec3(3, .3, .15);
    // Color blinking.
    col = mix(gr/2., col.yzx, smoothstep(.45, .47, sin(TAU*rnd*3. + iTime)));
    #endif
    
    
    return col;
            
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
    // Screen distortion.
    //uv *= 1. + dot(uv, uv)*.25;
    
    #ifdef STEREOGRAPHIC_ONLY
    // Camera Setup.
	vec3 ro = vec3(0, 2, -.0); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(.02*cos(iTime/2.), -.9, .05); // "Look At" position.
 
    // Light positioning. 
 	vec3 lp = ro + vec3(1, 0, -1);// Put it near the camera.
    #else
	// Camera Setup.
	vec3 ro = vec3(0, 1.4, -2); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(.02*cos(iTime/2.), -.2, .25); // "Look At" position.
 
    // Light positioning. 
 	vec3 lp = ro + vec3(1, 2, -.5);// Put it near the camera.
	#endif

    // Using the above to produce the unit ray-direction vector.
    float FOV = .75; // FOV - Field of view.
    vec3 fwd = normalize(lk-  ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x)); 
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Object selection. 
    objID = vID[0]<vID[1]? 0 : 1;
    
    /*
    objID = 0;
    float obD = vID[0]
    // Selecting from more objects.
    for(int i = 0; i<4; i++){ 
        if(vID[i]<obD){ obD = vID[i]; objID = i; }
    }
    */
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
	    //vec3 sn = getNormal(sp, edge, crv, ef, t);
        vec3 sn = getNormal(sp, t);
        
        
        float bF = objID==0? .3 : .5;
        sn = doBumpMap(sp, sn, bF);
        
        // Light direction vector.
	    vec3 ld = lp - sp;

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;
        
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 8.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
        
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);

    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
        #ifdef METALLIC
        diff = pow(diff, 4.)*2.; // Ramping up the diffuse.
    	#endif
        
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 32.); 
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow(clamp(1. + dot(sn, rd), 0., 1.), 2.);
        
        
		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.2, 1., Schlick);  //F0 = .2 - Glass... or close enough.        
        
          
        // Obtaining the texel color. 
	    vec3 texCol;   

        // Object coloring.        
        if(objID==0){ 


            // The sphere.
            
            // Sphere pattern. This function will return the surface
            // polygon distance.
            float poly = getPattern(sp);
            
            // Using the cell ID to produce some semi random coloring. "gID"
            // is a global value that I hacked in. It's updated after calling
            // the function above.
            vec3 pCol = getCol(gID, sp);
            
            // Rendering the pattern.
            texCol = vec3(0);
            
            
            // Edge width and line width.
            float ew = .01;
            float lw = .01;
            // Polygon edges, lines and coloring.
            texCol = mix(texCol, pCol + .5, 1. - smoothstep(.0, .007, poly + lw));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(.0, .007, poly + ew + lw));
            texCol = mix(texCol, pCol, 1. - smoothstep(.0, .007, poly + ew + lw*2.));
            
            // Rendering some dots in the center of the polygons. The ID is 
            // position based, which makes it possible.
            #ifndef HOLES
            vec3 tSp = rollObj(sp);
            float dt = length(tSp - normalize(gID)*.5) - .025;
            texCol = mix(texCol, pCol + .2, 1. - smoothstep(.0, .005, dt));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(.0, .005, dt + lw*.5));
            #endif
   
            
        }
        else { 
            
            // The floor plane.
            
 
            // We are currently on the ground and aiming for the north pole 
            // (top) of the sphere, so construct a unit direction ray aimed
            // toward the top of the sphere. Obtain the spherical intersection 
            // point, then plug that point into the sphere's mapping function 
            // to obtain a value that we can use for coloring, bump mapping etc..
        
            
            // The sphere's north pole.
            vec3 sphTop = vec3(0, .5, 0);
            
            // The unit direction ray. Aimed at the top of the sphere.
            vec3 rrd = normalize(sphTop - sp);
            
            // Raytracing. Expensive and not needed here. However, there are
            // times, when this would be your only option.
            //float tSph = trace(sp + sn*.0015, rrd);
            
            // Much faster raytraced hit function. We're only tracing a 
            // sphere, so bumping the normal off the surface isn't needed.
            vec2 t2 = sphInter(sp, rrd, vec4(0, 0, 0, .5));
            float tSph = t2.x;
            
            // The hit point on the sphere.
            vec3 sphP = sp + tSph*rrd;
 
            // Obtaining the sphere pattern value at the intersection point.
            float poly = getPattern(sphP);
            
            // Use it for some coloring.
            vec3 pCol = getCol(gID, sphP);
            
            // The texture color.
            texCol = vec3(0);
            
            // Adding some coloring, edging, etc., to the floor. I've hacked
            // in a distance based factor to tweak the line widths. It's not
            // physically correct. For that, I'd need to get the gradient 
            // involved, and I think it's overkill for a simple example.
            float tF = 1./(1. + t*.25); // Hacky field width taper factor.
            float ew = .015*tF;
            float lw = .01*tF;
            texCol = mix(texCol, pCol + .5, 1. - smoothstep(.0, .007, poly + lw));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(.0, .007, poly + ew + lw));
            texCol = mix(texCol, pCol, 1. - smoothstep(.0, .007, poly + ew + lw*2.));
            
            // Rendering some dots in the center of the polygons. The ID is 
            // position based, which makes it possible.
            #ifndef HOLES
            sphP = rollObj(sphP);
            float dt = length(sphP - normalize(gID)*.5) - .03/(1. + tSph*2.);
            texCol = mix(texCol, pCol + .2, 1. - smoothstep(.0, .005, dt));
            texCol = mix(texCol, vec3(0), 1. - smoothstep(.0, .005, dt + lw*.5));
            #endif

            
        }

        // Greyscale color.
        #if COLOR == 3
        texCol = vec3(.7)*dot(texCol, vec3(.299, .587, .114));
        #endif
       
    	#ifdef METALLIC
        // Cheap specular reflections.
        float speR = pow(max(dot(normalize(ld - rd), sn), 0.), 8.);
        vec3 rf = reflect(rd, sn); // Surface reflection.
        vec3 rTx = texture(iChannel0, rf).zyx; rTx *= rTx;
        //vec3 rTx = eMap(rf, n);
        //texCol = mix(texCol, texCol*speR*rTx*8., 1. - fre);
        texCol = texCol*.5 + (texCol)*speR*rTx*5.;
        #endif
        
        // Combining the above terms to procude the final color.
        col = texCol*(diff*sh + .25 + vec3(1, .5, .2)*spec*4.*sh);
        
        #ifdef METALLIC
        // Adding some Fresnel, for whatever reason.
        col += texCol*vec3(.2, .4, 1)*fre*(sh);
        #endif
 
       // Shading.
        col *= ao*atten;
        
  	
	}
    
    // Background fog.
    col = mix(col, vec3(0), smoothstep(.3, 1., t/FAR));
    
          
    // Vignette.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);
   
   
    // Rought gamma correction.
	fragColor = vec4(pow(max(col, 0.), vec3(1./2.2)), 1);
	
}