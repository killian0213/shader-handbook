// Image (image) — Hex Voxel Scene by Shane
// https://www.shadertoy.com/view/4dsBz4

/* 
    hex voxels, by mattz
    License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

    Idea: raytrace through stacked hexagonal boxes, based on Shane's comment
    in hexwaves - https://www.shadertoy.com/view/XsBczc

	Hex Voxel Scene
	---------------

	Testing out Mattz's hexagonal prismatic voxel traversal formula on a basic scene.

	I've always been curious as to what a simple scene would look like using a non-standard
	voxel traversal, especially the hexagonal box one, but have never got around to putting
	it into effect. Thankfully, Mattz is a more efficient coder than myself and wrote a 
	hexagonal prismatic voxel traversal (thanks for the technical term, IQ) not too long ago. 
	On a side note, he wrote it in what seemed to be a couple of hours, at most. It takes me  
    that long just to choose a texture. :)

	There are numerous standard cubic voxel examples around, but not too many featuring other 
	kinds. Mattz's "hex voxel" example is the first hexagonal box voxel traversal I've seen 
	in shader form.

	Anyway, most of this is Mattz's work. I simply plugged a different scene in, rearranged 
	things in a hurry, and changed a few settings here and there, so if the code looks patched 
	together, that's because it is. :)

    Hopefully, it'll work well enough, but it needs a tidy up. In addition, I put it together 
	on a pretty fast machine, so am not yet aware of the frame rate on slower machines. Having
	said that, I tried to choose a simplistic scene with cheap operations, so hopefully, there 
	won't be too many issues.

	
	Based On:
	
	// The original this is based on. Much neater code. :)
	hex voxels - mattz
	https://www.shadertoy.com/view/ldBcDd

	// Cool 2D hexagon traversal.
	hexwaves - mattz
	https://www.shadertoy.com/view/XsBczc

*/


#define FAR 100. // Maximum ray distance. Analogous to the far plane.

// Fabrice's succinct, 2D rotation formula. Apparently slower than the standard one, but
// only used for its compactness here.
mat2 r2(float th){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }
float objID, svObjID; // Object ID 


// square root of 3 over 2
const float hex_factor = 0.8660254037844386;

// ratio of cell height to hex radius
const float cell_height = 1.75;

// relationship between integer grid cells & sizes
const vec3 cell_size = vec3(hex_factor, 1.0, cell_height);

// ambient occlusion falloff - smaller is darker
const float ao_falloff = 3.5;

// ambient occlusion strength - bigger is darker
const float ao_strength = 0.65;

// higher resolution discretizes more finely but needs more grid steps to render
const float resolution = 1.5;

// number of steps to take to render
const int grid_steps = 160;

// light direction
//vec3 light_dir;
vec3 lp;


#define HEX_FROM_CART(p) vec2(p.x / hex_factor, p.y)
#define CART_FROM_HEX(g) vec2(g.x * hex_factor, g.y)

//////////////////////////////////////////////////////////////////////
// Used to draw top borders

float hexDist(vec2 p) {
    p = abs(p);
    return max(dot(p, vec2(hex_factor, 0.5)), p.y) - 1.0;
}

//////////////////////////////////////////////////////////////////////
// Given a 2D position, find integer coordinates of center of nearest
// hexagon in plane.

vec2 nearestHexCell(in vec2 pos) {
    
    // integer coords in hex center grid -- will need to be adjusted
    vec2 gpos = HEX_FROM_CART(pos);
    vec2 hex_int = floor(gpos);

    // adjust integer coords
    float sy = step(2.0, mod(hex_int.x+1.0, 4.0));
    hex_int += mod(vec2(hex_int.x, hex_int.y + sy), 2.0);

    // difference vector
    vec2 gdiff = gpos - hex_int;

    // figure out which side of line we are on and modify
    // hex center if necessary
    if (dot(abs(gdiff), vec2(hex_factor*hex_factor, 0.5)) > 1.0) {
        vec2 delta = sign(gdiff) * vec2(2.0, 1.0);
        hex_int += delta;
    }

    return hex_int;
    
}

//////////////////////////////////////////////////////////////////////
// Flip normal if necessary to have positive dot product with d

vec2 alignNormal(vec2 h, vec2 d) {
    return h * sign(dot(h, CART_FROM_HEX(d)));
}

//////////////////////////////////////////////////////////////////////
// Intersect a ray with a hexagon wall with normal n

vec3 rayHexIntersect(in vec2 ro, in vec2 rd, in vec2 h) {
    
    //return vec3(0); 

    vec2 n = CART_FROM_HEX(h);

    // solve for u such that dot(n, ro+u*rd) = 1.0
    float u = (1.0 - dot(n, ro)) / dot(n, rd);
    
    // return the 
    return vec3(h, u);

}

//////////////////////////////////////////////////////////////////////
// Choose the vector whose z coordinate is minimal

vec3 rayMin(vec3 a, vec3 b) {
    return a.z < b.z ? a : b;
}


// Smooth maximum, based on IQ's smooth minimum.
float smax(float a, float b, float s){
    
    float h = clamp(.5 + .5*(a - b)/s, 0., 1.);
    return mix(b, a, h) + h*(1. - h)*s;
}

// IQ's smooth minium function. 
float smin(float a, float b , float s){
    
    float h = clamp( 0.5 + 0.5*(b-a)/s, 0. , 1.);
    return mix(b, a, h) - h*(1.0-h)*s;
}

// The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
vec2 path(in float z){ 

    //return vec2(0); // Straight path.
    return vec2(sin(z*.085)*8., cos(z*.085)*6.); // Windy path.
    
}




// The terrain setup up.
float map(vec3 p){
     
    // The original uses a different coordinate system, so this is a quick hack
    // to enable me to drop in a "Z into the page" coordinate system.
    p = p.yzx; 
    
    // A gyroid-like perturbation to add to a plane. I'm doing it prior to the
    // wrapping the objects around the path, but there's no rule saying you can't
    // wrap this as well.
    float trSf = dot(sin(p*3.14159/16. - cos(p.yzx*3.14159/12.)), vec3(8));
 
    p.xy -= path(p.z); // Wrap the object (to follow) around the path.

   
    // Add the perturbation to the plane, then carve out a tunnel. I named the resultant object
    // "surr" for surroundings - I was in a hurry. :)
    float surr = smax(4. - length(p.xy*vec2(1, .75)), p.y - 4. + (.5 - trSf), 2.);
    float rail = max(abs(abs(p.x) - 4.) - 1., p.y + 2.); // Some rails for the path below.
    
    // Attaching the rails to the surroundings - instead of the path - for color reasons.
    surr = min(surr, rail); 
    
    // A windy path - Everything above a certain height is omitted.
    float path = max(abs(p.x) - 3.5, p.y + 4.); 

    objID = step(surr, path); // Object ID - Surrounding or path floor.

    return min(surr, path); // Return the minimum hit point.
 
}


// Tri-Planar blending function. Based on an old Nvidia tutorial.
vec3 tex3D( sampler2D t, in vec3 p, in vec3 n ){
     
    n = max(abs(n), 0.001);
    n /= dot(n, vec3(1));
	vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
}

//////////////////////////////////////////////////////////////////////
// Just for coloring the sky

vec3 sky(vec3 ro, vec3 rd) {
    
    float s = 0.5*dot(normalize(lp - ro), rd) + 0.5;
    return mix(vec3(1, .8, .7), vec3(.75, .92, 1), s)*vec3(1.35, 1.2, 1);
}


//////////////////////////////////////////////////////////////////////
// Surface shading function. hit_nt holds normal and ray distance,
// bdist holds distance to voxel edge, ndist holds distance to 
// neighbors (useful for AO).

vec3 shade(vec3 ro, vec3 rd, vec4 hit_nt, float bdist, float ndist, float diffuse) {
    
    // Surface point.
    vec3 p = ro + rd*hit_nt.w;
    
    // get the normal
    vec3 n = hit_nt.xyz;
    
    // Light direction vector.
    vec3 ld = normalize(lp - p);
    

    // gotta deal with borders

    // need to antialias more far away
    float border_scale = 3.0/iResolution.y;
    float border_size = 0.01;
    float border = smoothstep(0.0, border_scale*hit_nt.w, abs(bdist)-border_size);
    
    border_scale = 4.0/iResolution.y;
    border_size = 0.01*3.;
    float border2 = smoothstep(0.0, border_scale*hit_nt.w, abs(bdist)-border_size);



    // diffuse + ambient term
    diffuse = min(diffuse, clamp(dot(ld, n), 0.0, 1.0));
    float spec = pow(max( dot( reflect(-ld, n), -rd ), 0.0 ), 32.0);
    
    //float atten = 3./(1. + hit_nt.w*.1);
    
    //float fres = clamp(1. + dot(rd, n), 0., 1.);
    
    float ao = 1.0 - ao_strength*exp(-ao_falloff*ndist); // Ambient occlusion.

    // Surface color.
    vec3 color = (tex3D(iChannel0, p/4., n)*.66+tex3D(iChannel0, p/2., n)*.34);
    color *= vec3(1, .8, .6)*1.5;
    
    float gr = dot(color, vec3(.299, .587, .114));
   
    // Color the path and the surrounds slightly different colors.
    if(svObjID == 0.) { // Path.
        color = mix(color*vec3(1, 1.5, 1), vec3(1)*gr, .35)*1.5;//*vec3(1, .7, .4); // Terrain.
        color *= vec3(1.5, 1.25, 1); 
        //color = color.xxx;
    }
    else { // Surrounds.
         
        color = mix(color*vec3(1, 1.5, 1), vec3(1)*gr, .5);
        color *= vec3(1.5, 1.25, 1); 
        //color = color.xxx;
    }
  
    // Fake reflection. Doesn't really work well here.    
    //vec3 ref = tex3D(iChannel1, (p + reflect(rd, n)*2.)/64., n).xyz;//*vec3(.5, .7, 1)*.2;
    //color += ref*.25;      
    
    // add in border color
    color = mix((color*2.5 + gr*.75), color, border2);
    color *= border*.97 + .03;
 
    
    // multiply by diffuse/ambient
    color = color*(diffuse + 0.25*ao + vec3(.5, .7, 1)*spec*2.);// + color*fres*fres*ao*.125;


    // consider AO
    color *= ao;
    

	return color;
    
}



//////////////////////////////////////////////////////////////////////
// Compute min distance between point on vertical side of a hexagon 
// and corners of occupied cells. This checks just the four cells 
// needed.

float vertEdgeDist(vec3 prev_cell, vec3 hit_cell, vec3 p) {
 
    // Get difference on integer hex grid
    vec3 cell_diff = prev_cell - hit_cell;
    
    // Normal direction across cell boundary
    vec2 n = CART_FROM_HEX(cell_diff.xy);
    
    // Perpendicular vector, scaled to correct length to check corners
    vec2 np = vec2(-n.y, n.x) * 0.5 / hex_factor;
        
    // Coordinates of cell center
    vec3 cell_pos = prev_cell * cell_size;
    
    // We only care about difference from center when measuring distances
    p -= cell_pos;
    
    // These are "rotation" matrices that rotate directions on the
    // integer hex grid.  
    const mat2 M0 = mat2(0.5, 0.75, -1.0, 0.5);
    const mat2 M1 = mat2(0.5, -0.75, 1.0, 0.5);
    
    // Get directions to left and right neighbors, along with sign
    // for perpendicular to normal
    vec3 h[2];
    h[0] = vec3(M0 * cell_diff.xy, 1.0);
    h[1] = vec3(M1 * cell_diff.xy, -1.0);
    
    // Initialize distance to large value
    float rval = 1e5;
    
    // For each neighbor direction
    for (int i=0; i<2; ++i) {
        
        // Check below and above on grid
        for (float d=-1.0; d<=1.0; d+=2.0) {
            
            // Get the neighbor cell
            vec3 neighbor_cell = hit_cell + vec3(h[i].xy, d);
            vec3 neighbor_pos = neighbor_cell * cell_size;
            
            // If it's occupied
            if (map(neighbor_pos/resolution) < 0.0) {
                
                // Get corner with this neighbor                  
                vec3 corner = 0.5*(vec3(np*h[i].z, cell_height*d) - cell_diff*cell_size);
                
                // Check distance to corner
                rval = min(rval, length(p - corner));
                
            }
        }
    }
    
    return rval;

}

//////////////////////////////////////////////////////////////////////
// Get minimum distance to all eight connected neighbors across a 
// face, except for the occupied one (which would have
// distance of zero).

float neighborDist(vec3 prev_cell, vec3 hit_cell, vec3 p) {
            
    // Get cell center position
    vec3 cell_pos = prev_cell * cell_size;
    
    // Only care about distances relative to center
    p -= cell_pos;
    
    // Cancel out some multiplication that will happen down below
    p.z *= 2.0/cell_height;
    
    // Set up four neighbors and distances to walls
    vec4 h[4];
    
    h[0] = vec4(0.0,  1.0, 0.0, 1.0);
    h[1] = vec4(1.0,  0.5, 0.0, 1.0);
    h[2] = vec4(1.0, -0.5, 0.0, 1.0);
    h[3] = vec4(0.0,  0.0, 0.5, 0.5*cell_height);
    
    // Initialize return value to large number
    float rval = 1e5;
   
    // For each neighbor direction...
    for (int i=0; i<4; ++i) {
        
        // ...and its opposite direction
        for (float s=-1.0; s<=1.0; s+=2.0) {
            
            // Get the neighbor integer grid coords
            vec3 neighbor_cell = prev_cell + 2.0*s*h[i].xyz;
            
            // Ignore the one we already know is occupied
            if (neighbor_cell != hit_cell) {
                
                // Get neighbor center position
                vec3 neighbor_pos = neighbor_cell * cell_size;
                
                // If occupied...
                if (map(neighbor_pos/resolution) < 0.0) {
                
                    // Get normal
                    vec3 n = s * h[i].xyz * cell_size;
                    
                    // Update using distance to neighbor along normal
                    rval = min(rval, h[i].w - dot(n, p));
                
                }   
            }
        }
    }
    
    // Return minimum distance
    return rval;
    
}

 

//////////////////////////////////////////////////////////////////////
// Return the normal and intersection distance for ray with origin
// ro and direction rd.

void raytrace(in vec3 ro, in vec3 rd,
              out vec4 hit_nt, 
              out vec3 prev_cell,
              out vec3 cur_cell) {
    
 
    
    // find nearest hex cell center to ray origin    
    cur_cell = vec3(nearestHexCell(ro.xy), floor(ro.z/cell_height + 0.5));
    
    // we also will care about the cell we entered in from
    prev_cell = cur_cell;
    
    // current cell center
    vec3 cur_center = cur_cell * cell_size;

    // see if ray is pointed up or down
    float dz = rd.z < 0.0 ? -1.0 : 1.0;

    // get the three candidate wall directions for this ray (i.e. the
    // three hex side directions that correspond to normals with positive
    // dot products to ray direction)
    vec2 h0 = alignNormal(vec2(0.0, 1.0), rd.xy);
    vec2 h1 = alignNormal(vec2(1.0, 0.5), rd.xy);
    vec2 h2 = alignNormal(vec2(1.0, -0.5), rd.xy);

	// have we hit a hex yet?    
    bool hit = false;
    
    // initialize normal to zero and intersection distance to negative
    hit_nt = vec4(0, 0, 0, -1.0);    

    // march along ray, one iteration per cell
    for (int i=0; i<grid_steps; ++i) {
        
        // once we hit we're good
        if (hit) { break; }
        
        // distance from ray origin to current cell center
        vec3 rdelta = ro-cur_center;
        
        // first, test intersections with sides:
        // after three tests, ht.xy holds the direction, ht.z holds the
        // ray distance parameter with intersecting sides
        vec3 ht = rayHexIntersect(rdelta.xy, rd.xy, h0);
        ht = rayMin(ht, rayHexIntersect(rdelta.xy, rd.xy, h1));
        ht = rayMin(ht, rayHexIntersect(rdelta.xy, rd.xy, h2));
        
        // next, test intersection with top/bottom 
        float tz = (0.5*dz*cell_height - rdelta.z) / rd.z;
        
        // now we will need to figure out how to update the current cell
        // either horizontally or vertically.
        
        // stash the previous cell
        prev_cell = cur_cell;        

        // variable to hold return value if we do hit
        vec4 new_nt;
 
        // check whether we hit top/bottom before side
        if (tz < ht.z) {
            
            // hit top/bottom first, so march vertically
            cur_cell.z += dz;
            
            // set up normal and ray distance for return value
            new_nt = vec4(0, 0, -dz, tz);
            
        } else {
            
            // hit side first, so march horizontally
            cur_cell.xy += 2.0*ht.xy;
            
            // set up normal and ray distance for return value
            new_nt = vec4(-CART_FROM_HEX(ht.xy), 0, ht.z);
            
        }
        
        // we updated the current cell, now update the cell center position
        cur_center = cur_cell * cell_size;
            
        // see if the new cell center is occupied
        if (map(cur_center/resolution) < 0.0) {
            hit = true;
            hit_nt = new_nt;
        }
        
        

    }

}

//////////////////////////////////////////////////////////////////////
// Return the color for a ray with origin ro and direction rd

vec3 ray_shade(in vec3 ro, in vec3 rd) {
    
    // handle resolution scaling
    ro *= resolution;

    // hit_nt will hold normal and distance
    vec4 hit_nt;
    
    // prev_cell and hit_cell store cell before and after intersection
    vec3 prev_cell, hit_cell;
    
    // do raytrace
    raytrace(ro, rd, hit_nt, prev_cell, hit_cell);
    
    svObjID = objID;
    
    // output color
    vec3 color = vec3(0);
    
    //vec3 light_dir = normalize(lp - ro);
    vec3 sk = sky(ro, rd);
    color = sk;
    
    // if ray hit
    if (hit_nt.w >= 0.0) {
        
        // get the cell center where it hit
        vec3 cell_center = hit_cell * cell_size;
        
        // get the intersection point
        vec3 pintersect = ro + rd * hit_nt.w;
        
        // store distance to border, to neighbor cell
        float bdist, ndist;
        
        // see if we hit top/bottom or side
        if (abs(hit_nt.z) > 0.0) {
            
            // was top/bottom
            bdist = hexDist(pintersect.xy - cell_center.xy);
            ndist = neighborDist(prev_cell, hit_cell, pintersect); 
            
        } else {
            
            // was side
            vec2 n = hit_nt.xy;
            bdist = abs(fract(pintersect.z/cell_height)-0.5)*cell_height;
                    
            vec2 p = pintersect.xy - cell_center.xy;
            p -= n * dot(p, n);
            bdist = min(bdist, abs(length(p) - 0.5/hex_factor));
            
            ndist = neighborDist(prev_cell, hit_cell, pintersect);
            ndist = min(ndist, vertEdgeDist(prev_cell, hit_cell, pintersect));

        }
        
        // default case: assume shadow - note for "realism" we would set 0.0 here
        float diffuse = 0.05;
        
        // A distant point light, so it's almost directional, but it still has a
        // slight point light feel... if that makes any sense. :)
        vec3 light_dir = normalize(lp - pintersect);
        
        // see if on lit side
        if (dot(hit_nt.xyz, light_dir) > 0.0) {
            
            // shadow ray
            vec4 shadow_nt;
            raytrace(pintersect + 0.001*hit_nt.xyz, light_dir, 
                     shadow_nt, prev_cell, hit_cell);
            
            // full light if shadow ray missed
            if (shadow_nt.w < 0.0) { diffuse = 1.0; }

            
        }
        
        // shade the hit point
        color = shade(ro, rd, hit_nt, bdist, ndist, diffuse);

        
    } 
    
    color = mix(color, sk, smoothstep(0., .95, hit_nt.w*.6/100.));
    
	return color;
	
}	
 


//////////////////////////////////////////////////////////////////////

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
	
	const float yscl = 800.0;
	const float f = 450.0;
	
    vec2 uvn = (fragCoord - 0.5*iResolution.xy)/iResolution.y;
	vec2 uv = uvn*yscl;
    
    
    vec3 rd = normalize(vec3(uv, f));
    rd = normalize(vec3(rd.xy, rd.z - dot(rd.xy, rd.xy)*.15)); // Subtle lens distortion.
	
	vec3 ro = vec3(0, 0, iTime*5.);
	vec3 tgt = ro + vec3(0, 0, .25);
	vec3 up = vec3(0, 0, 1);
    
    
    
    lp = ro + vec3(FAR*.24, FAR*.52, FAR*.78);
    


    vec2 sw = path(tgt.z);
    
    ro.xy += path(ro.z);
	tgt.xy += sw;
     
    // The original uses a different coordinate system, so this is a quick hack
    // to enable me to drop in a "Z into the page" coordinate system.
    ro = ro.zxy;
    tgt = tgt.zxy;
    lp = lp.zxy;    
	
	vec3 rz = normalize(tgt - ro);
	vec3 rx = normalize(cross(rz,up));
	vec3 ry = cross(rx,rz);
    
    mat3 R = mat3(rx,ry,rz);
     

    
	float thetax = sw.y/32.;
	float thetay = 0.; // sw.x/64.

/*  
    // Mouse camera direction overide.
	if (iMouse.y > 10.0 || iMouse.x > 10.0) { 
		thetax = (iMouse.y - 0.5*iResolution.y) * -1.25/iResolution.y;
		thetay = (iMouse.x - 0.5*iResolution.x) * 6.28/iResolution.x; 
	}
*/ 
    
	float cx = cos(thetax);
	float sx = sin(thetax);
	float cy = cos(thetay);
	float sy = sin(thetay);
	
	mat3 Rx = mat3(cx, 0, -sx, 0, 1, 0, sx, 0, cx);
    mat3 Ry = mat3(cy, -sy, 0, sy, cy, 0, 0, 0, 1);
	
    ro = Ry*Rx*(ro-tgt) + tgt;
    rd = Ry*Rx*R*rd;

    rd.yz *= r2(-sw.x/64.);

    
    vec3 color = ray_shade(ro, rd);
    
    // Some post processing. Wasn't used.
    //color = mix(color, color.xxx, .8);
    //color = mix(color.xxx, pow(color.xxx, vec3(1, 2, 3)), .35);
    
   
    
    // Subtle vignette.
    uv = fragCoord/iResolution.xy;
    color *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .125)*.5 + .5;
    
	color = sqrt(color);

    fragColor = vec4(color, 1.0);
    
}