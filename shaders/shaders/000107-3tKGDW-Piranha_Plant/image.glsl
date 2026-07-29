// Image (image) — Piranha Plant by PixelPhil
// https://www.shadertoy.com/view/3tKGDW

//
// Piranah Plant by Philippe Desgranges
// Email: Philippe.desgranges@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//

#define MAX_DST 50.0
#define MIN_DST 0.004
#define S(a,b,c) smoothstep(a,b,c)
#define sat(a) clamp(a,0.0,1.0)
#define ZERO (min(iFrame,0))

//Material regions
#define LEAF		 	0.0
#define STEM   			1.0
#define HEAD			2.0
#define LIPS			3.0
#define INSIDE_MOUTH 	4.0
#define TONGUE			5.0
#define	TEETH			6.0
#define	POT				7.0
#define	SOIL			8.0
#define	HILL			9.0
#define SKY				10.0

const vec3 leafGreen  = vec3(0.21, 0.66, 0.23);
const vec3 leafInside = vec3(0.52, 1.00, 0.36);

// All the parametters for an animation pose
struct KeyFrame
{
    float leafAngle;
    float mouthAngle;
    float spine1;
    float spine2;
    float spine3;
    float neck;
};

// Linear interpolation between two animation frames
void mixKeyFrame(KeyFrame a, KeyFrame b, float ratio, out KeyFrame c)
{
    ratio = ratio*ratio*(3.0-2.0*ratio); // Thanks iq :D
    
    c.leafAngle		= mix(a.leafAngle , b.leafAngle	  , ratio);
    c.mouthAngle	= mix(a.mouthAngle, b.mouthAngle  , ratio);
    c.spine1		= mix(a.spine1	  , b.spine1	  , ratio);
    c.spine2		= mix(a.spine2	  , b.spine2	  , ratio);
    c.spine3		= mix(a.spine3	  , b.spine3	  , ratio);
    c.neck			= mix(a.neck	  , b.neck		  , ratio);
}

// all matrices and offsets that needs to be pre-computed
// in order to keep the SDF relatively straightforward
struct PlantSpace
{
   //mat4 viewMat;
   
   // Leaf Matrix
   mat2 matLeaf;
   
   // Spine
   float joint1AngleZ;
   float joint2AngleZ;
   float joint3AngleZ;
   mat4 joint1;
   mat4 joint2;
   mat4 head;
   
   // Head / Mouth
   float mouthAngle;
   mat2 mouthRot;
   mat2 teethRot;
   mat2 teethRot2;
   vec3 tPos1;
   vec3 tPos2;
   vec3 tPos3;
   vec3 tPos4;
   vec3 tPos5;
};

// Attributes of a PBR material
struct PBRMat
{
    vec3 albedo;
    float metalness;
    float roughness;
    float occlusion;
};

// From world space to leaf space (before symmetry)
vec3 leafSpace(vec3 pos, PlantSpace ps)
{
    vec3 leafPos = pos;
    
    leafPos.z = abs(leafPos.z) - 2.8;
    leafPos.y  += ps.matLeaf[0][1] * 2.8;
    leafPos.zy = ps.matLeaf * leafPos.zy;
    
    return leafPos;
}

// Distance to the leaf cutout pattern (on xz)
float dstLeaf(vec3 leafPos)
{
    float c1 = 1.1 - length(leafPos.zx - vec2(2.8, 1.1));
    float c2 = 1.25 - length(leafPos.zx - vec2(1.1, 2.5));
    return max(c1, c2);
}

// Color of the LEAF region from pos in world space
vec3 LeafColor(vec3 pos, PlantSpace ps)
{
    vec3 leafPos = leafSpace(pos, ps);
   
    leafPos.x = abs(leafPos.x); // The fishbone pattern uses x symetry in leaf space
    
    float d = leafPos.x - 0.15; // central line
    float l = abs(0.5 - fract(leafPos.z + leafPos.x * 0.5 + 0.20)) * 2.0 - 0.25; // 'fins'
    
    leafPos.z = abs(leafPos.z); // The lighter area uses x and z symettry
   
    float dst = dstLeaf(leafPos); 
    
    float p = smin(d, l, 0.3) + S(-1.2, -0.0, dst) * 0.28;
    float pattern = S(-0.05, 0.05, p); // Fishbone pattern mask
    
    float area = S(-0.5, -0.6, dst); // Lighter area
    
    vec3 col = mix(leafGreen, leafInside, min(area, pattern));
    
    return col;
}

// Computes the color of the HEAD region from pos in world space
vec3 HeadColor(vec3 pos, PlantSpace ps)
{
    // Compute a unit vector from inside the head in head space
    vec3 headPos = normalize((ps.head * vec4(pos, 1.0)).xyz - vec3(0, 3, 0));
    
    
    vec3 dir = vec3(0, -length(headPos.xy), headPos.z); //Longitudinal vector on the 
    
    // The vector is rotated around the jaw taking into account the mouth opening
    // To simulate the skin 'stretching'
    float zAngle = atan(headPos.x, -headPos.y) * (pi / (pi - ps.mouthAngle));
    dir = (rotationZ(zAngle) * vec4(dir, 0.0)).xyz;
    
    dir.xz = abs(dir.xz); // Symetry on x & z for more dots faster

    // Compute the distances with all the dots in the unit sphere
    // hopefully the compiler optimizes out all these normalize()
    float d = S(0.95, 0.96, dot(dir, normalize(vec3(1, 0.1, 0))));
    d += S(0.96, 0.97, dot(dir, normalize(vec3(1, 1, 0.9))));
    d += S(0.94, 0.95, dot(dir, normalize(vec3(0.7, -0.3, 0.9))));
    d += S(0.96, 0.97, dot(dir, normalize(vec3(0.6, -0.6, 0.0))));
    d += S(0.97, 0.98, dot(dir, normalize(vec3(0.0, -1.25, 1.0))));
    
    return mix(vec3(0.8, 0.18, 0.25), vec3(1.0),  d);
}

// Astro turf on the hill
void HillColor(vec3 pos, out PBRMat mat)
{
    vec2 noizeUV = pos.xz * 0.65;
    
    // Compute a low frequency 2D vector field
    vec2 noise = vec2(Noise2(noizeUV.xy + vec2(455.0, 123.9)) - 0.5, Noise2(noizeUV.xy + vec2(-6.8, 467.23)) - 0.5);
    
    // Compute a high frequency noise stretched by the vector field
    float grass = sat(Noise2(pos.xz * 7.0 + noise.xy * 15.0) + length(noise) * 2.0);
    
    // Mix in some octaves of noise
    grass -= (Noise2(pos.xz * 5.0) + Noise2(pos.xz * 10.0) + Noise2(pos.xz * 20.0))  * 0.3;

    vec3 strands = mix(vec3(0.3, 1.0, 0.4), vec3(0.1, 0.5, 0.4), grass);
    
    //use the strands mask as occlusion for richer shadows
    mat = PBRMat(strands, 0.2, 0.8 , sat(grass)); 
}


// Computes a PBR Material from material ID and world position
void GetColor(float id, vec3 pos, PlantSpace ps, out PBRMat mat, out vec3 normalBend)
{   
    normalBend = vec3(0);
    
    if (id == LEAF){
        mat = PBRMat(LeafColor(pos, ps), 0.3, 0.2, 1.0);
    	return;
    }
    else if (id == STEM){
        mat = PBRMat(leafGreen, 0.3, 0.2, 1.0);
    	return;
    }
    else if (id == HEAD){
        mat = PBRMat(HeadColor(pos, ps), 0.5, 0.1, 1.0);
    	return;
    }
    else if (id == LIPS){
        mat = PBRMat(vec3(1.0, 1.0, 1.0), 0.05, 1.0, 1.0);
    	return;
    }
    else if (id == INSIDE_MOUTH){
        mat = PBRMat(vec3(0.7, 0.0, 0.5), 0.3, 0.2, 1.0);
    	return;
    }
    else if (id == TONGUE){
        mat = PBRMat(vec3(1.0, 0.4, 0.4), 0.7, 0.8, 1.0);
    	return;
    }
    else if (id == TEETH){
        mat = PBRMat(vec3(1.0, 1.0, 1.0), 0.4, 0.2, 1.0);
    	return;
    }
    else if (id == POT){
        mat = PBRMat(vec3(0.2, 0.2, 0.6), 1.0, 0.3, 1.0);
    	return;
    } 
    else if (id == SOIL){
        vec2 nCoords = pos.xz * 4.0;
    	normalBend = vec3(Noise2(nCoords) - 0.5, 0.0, Noise2(nCoords.yx + vec2(45.5, 45.5)) - 0.5);
        mat = PBRMat(vec3(0.31, 0.2, 0.08), 0.15, 1.0, 1.0);
        return;
    }
    else if (id == HILL){
        HillColor(pos, mat);
    	return;
    }
	else if (id == SKY){
        mat = PBRMat(vec3(0.5, 0.6, 1.0), 0.0, 0.0, 1.0);
    	return;
    }  	
}

// Somehow the switch block didn't work with the iOS compiler
/*
void GetColor(float id, vec3 pos, PlantSpace ps, out PBRMat mat, out vec3 normalBend)
{   
    normalBend = vec3(0);
    
    switch(int(id))
    {
      case int(LEAF):
        mat = PBRMat(LeafColor(pos, ps), 0.3, 0.2, 1.0);
        return;
      case int(STEM):
        mat = PBRMat(leafGreen, 0.3, 0.2, 1.0);
        return;
      case int(HEAD):
        mat = PBRMat(HeadColor(pos, ps), 0.6, 0.1, 1.0);
        return;
      case int(LIPS):
        mat = PBRMat(vec3(1.0, 1.0, 1.0), 0.05, 1.0, 1.0);
        return;
      case int(INSIDE_MOUTH):
        mat = PBRMat(vec3(0.7, 0.0, 0.5), 0.3, 0.2, 1.0);
        return;
      case int(TONGUE):
        mat = PBRMat(vec3(1.0, 0.4, 0.4), 0.8, 0.6, 1.0);
        return;
      case int(TEETH):
        mat = PBRMat(vec3(1.0, 1.0, 1.0), 0.4, 0.2, 1.0);
        return;
      case int(POT):
        mat = PBRMat(vec3(0.2, 0.2, 0.6), 1.0, 0.3, 1.0);
        return; 
      case int(SOIL):
        vec2 nCoords = pos.xz * 4.0;
        normalBend = vec3(Noise2(nCoords) - 0.5, 0.0, Noise2(nCoords.yx + vec2(45.5, 45.5)) - 0.5);
        mat = PBRMat(vec3(0.31, 0.2, 0.08), 0.15, 1.0, 1.0);
        return;
      case int(HILL):
        HillColor(pos, normalBend, mat);
        return;
      case int(SKY):
        mat = PBRMat(vec3(0.5, 0.6, 1.0), 0.0, 0.0, 1.0);
        return;  	
    }
}
*/

// Build all the matrices and offsets necessary to compute the SDF
// leaving all that in would lead to bad perfs and crazy compile times
void buildPlantSpace(KeyFrame frame, out PlantSpace res)
{
    // Leaves
    float leafAngle = frame.leafAngle;//  -(sin(iTime) * 0.2 + 0.1);
    float leafSin = sin(leafAngle);
    float leafCos = cos(leafAngle);
    
    res.matLeaf = mat2(-leafCos, leafSin, leafSin, leafCos);

    // Spine
    res.joint1AngleZ = frame.spine1;
    res.joint2AngleZ = frame.spine2;
    res.joint3AngleZ = frame.spine3;
    
    res.joint1 = joint3DMatrix(3.0, res.joint1AngleZ);
    res.joint2 = rotationY(frame.neck) * joint3DMatrix(3.0, res.joint2AngleZ) * res.joint1;
    
    
    // Head / Mouth
    float MouthAngle = frame.mouthAngle;
    res.mouthAngle = MouthAngle;
    
    float scale = 1.0 - MouthAngle * 0.07;
    res.head = scaleMatrix(vec3(scale, 1, 1)) * joint3DMatrix(3.0, res.joint3AngleZ) * res.joint2;

    float c = cos(MouthAngle);
    float s = sin(MouthAngle);
   	
    res.mouthRot = mat2(c, s, s, -c);
	
    
    float c2 = cos(MouthAngle * 0.5);
    float s2 = sin(MouthAngle * 0.5);
    
    res.teethRot = mat2(s2, -c2,
                     c2, s2);
    
    res.teethRot2 = mat2(s2,  c2,
                        -c2, s2);
    
    res.tPos1 = vec3(s * 1.5, -1.1, 0.0);
    res.tPos2 = vec3(s * 1.2, -0.8, 1.1);
    res.tPos3 = vec3(s * 0.6, -1.0, 1.5);
    res.tPos4 = vec3(-s * 1.5, -1.0, 0.56);
    res.tPos5 = vec3(-s * 1.2, -1.3, 1.3);
}

// Signed distance foe a leaf (pos in leaf space)
float sdLeaf(vec3 pos)
{
    pos.xz = abs(pos.xz); // Leaf geometry uses symetry on x & z
    
    // Starts with an ellipsoid slightly offset from symmetry plane.
    float leaf = sdEllipsoid(pos - vec3(0.5, 0, 0), vec3(1.4, 0.9, 3));
    
    if (leaf > 0.8)
    {
        //Early exit with bounding volume
        return leaf - 0.05;
    }
    
    
    leaf = abs(leaf) - 0.11; // Onioning
    
    float patternDist = dstLeaf(pos); // Cutout pattern SDF
    
    float offset = 0.0;
    
    leaf = smax(leaf, patternDist, 0.2); //Cutout the shape
    leaf = smax(leaf, -pos.y, 0.2); //remove the lower part
    
    return (leaf - offset) * 0.6; // the 0.6 ratio removed ray marching artefacts
}

// Computes the sdf to the head (y is material id)
vec2 sdHead(vec3 pos, PlantSpace ps)
{
    //Head space is Mouth Up
    
    // Head starts with a sphere
    float head = sdSphere(pos - vec3(0, 3, 0), 2.8);
    
    if (head > 1.0)
    {
        //Early exit with bounding volume
        return vec2(head - 0.5, HEAD);
    }
    
    pos.z = abs(pos.z); // Right/Left Symmetry
    
    vec2 ac = vec2(1,0);
    
    
    
    // Compute teeth implantation positions
    // 5 teeth for the 9 on the plant (The top middle one is on the symmetry plane)
    vec3 teethPos = vec3(ps.teethRot * (pos.xy - vec2(0, 3)), pos.z);
  
    vec3 tPos = teethPos - ps.tPos1;
    vec3 tPos2 = teethPos - ps.tPos2;
    vec3 tPos3 = teethPos - ps.tPos3;
    
    vec3 teethPos2 = vec3(ps.teethRot2 * (pos.xy - vec2(0, 3)), pos.z);
    
    vec3 tPos4 = teethPos2 - ps.tPos4;
    vec3 tPos5 = teethPos2 - ps.tPos5;
    
    // Compute teeths SDFs
    float teeth =      sdRoundCone(tPos, 0.5, 0.15, 1.5);
    teeth = min(teeth, sdRoundCone(tPos2, 0.5, 0.15, 1.2));
    teeth = min(teeth, sdRoundCone(tPos3, 0.5, 0.15, 1.2));
    teeth = min(teeth, sdRoundCone(tPos4, 0.5, 0.15, 1.2));
    teeth = min(teeth, sdRoundCone(tPos5, 0.5, 0.15, 1.2));
    

    
    // Inside of the mouth is a soft compooud of 3 speres 
    float mouthInside = sdSphere(pos - vec3(0, 3.5, 0), 2.2);
	mouthInside = smin(mouthInside, sdSphere(pos - vec3(0.2, 1.5, 0.0), 0.9), 0.3);
    mouthInside = smax(mouthInside, -sdSphere(pos - vec3(0.8, 1.6, 0.0), 0.4), 0.5);
    
    // Tongue is an ellipsoid
    float tongue = sdEllipsoid(pos - vec3(-1.0, 2.2, 0.0), vec3(0.7, 1.7, 1.2));

    // Adds X symmetry to compute both lips simultaneously
	pos.x = abs(pos.x); 
    
    vec3 lp = pos.zyx;
    lp.y -= 3.0;
    lp.yz = lp.yz * ps.mouthRot;
    
    float lips = sdCappedTorus(lp, ac, 2.6, 0.8);
    
    // Cut open the head like a Pac Man 
    vec2 pc = pos.xy - vec2(0, 3.0);
    float plane2 = dot(pc, vec2(ps.mouthRot[1][1], ps.mouthRot[0][1]));
    head = max(plane2, head);
    
    // Combine all parts of the head with material ids
    vec2 res = vec2(head, HEAD);
    res = combineMax(res, vec2(-mouthInside, INSIDE_MOUTH));
    res = combineMin(res, vec2(teeth, TEETH));
    res = combineMin(res, vec2(lips, LIPS));
    res = combineMin(res, vec2(tongue, TONGUE));
    
    return res;
}


// SDF of the scene
vec2 SDF(vec3 pos, PlantSpace ps)
{
    // Hill
    vec3 hillPos = pos - vec3(0, -20, 0);
    hillPos.y = max(0.0, hillPos.y);
    float hillDst = length(hillPos);
    
    float hill = (hillDst - 17.0);
    
    
    float cDist = length(pos.xz);// Infinite cylinder to carve a hole in the Pot
    
    float pot = sdRoundedCylinder(pos - vec3(0, -0.5, 0), 1.3, 0.25, 0.5);
    pot = smax(pot, 1.9 - cDist, 0.25);
    
    vec2 pipe = combineMax(vec2(cDist - 2.0, POT), vec2(pos.y, SOIL));
    
    // Pipe + Soil with materila Ids
    vec2 potCol = combineMin(vec2(pot, POT), pipe);
    
    float leaf = sdLeaf(leafSpace(pos, ps));
    
    // The stem is 3 Joint3DSphere chained
    float stem = smin(sdSphere(pos, 0.8), sdJoint3DSphere(pos,  3.0, ps.joint1AngleZ /*0.4*/, 0.5), 0.8);
    
    vec3 newPos = (ps.joint1 * vec4(pos, 1.0)).xyz;
    stem = min(stem, sdJoint3DSphere(newPos,  3.0, ps.joint2AngleZ /*-0.75*/, 0.5));
    
    newPos = (ps.joint2 * vec4(pos, 1.0)).xyz;
    stem = min(stem, sdJoint3DSphere(newPos,  3.0, ps.joint3AngleZ /*sin(iTime * 0.7) * 0.2 - 0.5*/, 0.5));
    
    vec3 headPos = (ps.head * vec4(pos, 1.0)).xyz;
    
    // A rounded cylinder is addded as the 'neck'
    stem = smin(stem, sdRoundedCylinder(headPos, 0.5, 0.4, 0.0), 0.3);
    
    // Combine all parts together with materil ids
    vec2 res = sdHead(headPos, ps);
    res = combineMin(res, vec2(leaf, LEAF));
    res = combineMin(res, vec2(stem, STEM));
	res = combineMin(res, potCol);
    res = combineMin(res, vec2(hill, HILL));

	return res;
}


// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( vec3 pos, PlantSpace ps)
{
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e * SDF(pos+0.0005*e, ps).x;
    }
    return normalize(n);
}

// inspired by
// https://iquilezles.org/articles/rmshadows
float shadow(vec3 pos, vec3 lPos, PlantSpace ps)
{   
    vec3 dir = lPos - pos;  // Light direction & disantce
    
    float len = length(dir);
    dir /= len;				// It's normalized now
    
    pos += dir * MIN_DST * 2.0;  // Get out of the surface
    
    float dst = SDF(pos, ps).x; // Get the SDF
    
    // Start casting the ray
    float t = 0.0;
    float obscurance = 1.0;
    
    while (t < len)
    {
        if (dst < MIN_DST) return 0.0; 
        obscurance = min(obscurance, (20.0 * dst / t)); 
        t += dst;
        pos += dst * dir;
        dst = SDF(pos, ps).x;
    }
    return obscurance;     
}

float shadow(vec3 p, vec3 n, vec3 lPos, PlantSpace ps)
{
    return shadow(p + n * MIN_DST * 40.0, lPos, ps);
}

// Cast a ray across the SDF return x: Distance, y: Materila Id
vec2 castRay(vec3 pos, vec3 dir, float maxDst, float minDst, PlantSpace ps)
{
    vec2 dst = vec2(minDst * 2.0, 0.0);
    
    float t = 0.0;
    
    while (dst.x > minDst && t < maxDst)
    {
        dst = SDF(pos, ps);
        t += dst.x;
        pos += dst.x * dir;
    }
    
    return vec2(t + dst.x, dst.y);
}

// A 2D blurrable cloud 
float cloudSky(vec2 skyUv, float blur)
{
    float sum = Noise2(skyUv);
    float div = 1.0;
    
    if (blur < 0.75)
    {
        sum += Noise2(skyUv * 8.0) * 0.1 - 0.05;
        
        if (blur < 0.50)
        {
    		sum += Noise2(skyUv * 4.0) * 0.25 - 0.125;
            
            if (blur < 0.25)
        	{
    			sum += Noise2(skyUv * 2.0) * 0.5 - 0.25;
            }
        }
    }
    sum /= 3.0;
    return sum;
}

// A blurrable cloud environement map
vec3 SkyDome(vec3 rayDir, float blur)
{
    float blue = sat(rayDir.y * 2.0 + 0.7);
    vec3    col = mix(vec3(0.8, 0.9, 1.0), vec3(0.5, 0.6, 1.0), blue);
    
    vec2 dome = rayDir.xz;
    float len = length(dome);
    
    float a = atan(rayDir.x, rayDir.z);
    
    // Compute 2 layers of clouds and blend them with longitude to mask the vertical seam
    vec2 skyUv = vec2(a * 7.5 - iTime * 0.1, rayDir.y * 10.0);
    float cloud1 = cloudSky(skyUv, blur);
    
    vec2 skyUv2 = vec2((a + pi2) * 7.5 - iTime * 0.1, rayDir.y * 10.0);
    float cloud2 = cloudSky(skyUv2, blur);
    
    float ratio = 1.0 - (a + pi) / pi2;
    float cloud =  mix(cloud1, cloud2, ratio);
    
    // Mask the cloud across a horizontal band
    float cloudMask = S(0.8, 0.0, abs(rayDir.y + 0.2));
    cloud *= cloudMask;
    
    // When blurred the clouds are merely the mask itself
    cloud = mix(cloud, cloudMask * (1.0 - blur * 0.6), blur);

    // Add some burn around the sun
    float sun = max(0.0, dot(rayDir, normalize(vec3(-1.0, 0.4, -1))) - 0.3);
          
    col.rgb += cloud;
    col.rgb += sun * sun * sun;
    
    //col.rgb = mix(col.rgb, vec3(0, 1, 0), S(-0.5, -1.0, rayDir.y));
    
    return col;
}


// A PBR-ish lighting model
vec3 PBRLight(vec3 pos, vec3 normal, vec3 view, PBRMat mat, vec3 lightPos, vec3 lightColor, float lightRadius, float fresnel, PlantSpace ps, bool AddEnv)
{
    //Basic lambert shading stuff
    
    vec3 key_Dir = lightPos - pos;
    float key_len = length(key_Dir);
    
    float atten = sat(1.0 - key_len / lightRadius);
    atten *= atten;
    
    key_Dir /= key_len;
    

    float key_lambert = max(0.0, dot(normal, key_Dir)) * atten;
    float key_shadow = shadow(pos, normal, lightPos, ps); 
    
    float diffuseRatio = key_lambert * key_shadow;
    
    vec3 key_diffuse = vec3(diffuseRatio);
    
    // The more metalness the more present the Fresnel
    float f = pow(fresnel + 0.5 * mat.metalness, mix(2.5, 0.5, mat.metalness));
    
    // metal specular color is albedo, it is white for dielectrics
    vec3 specColor = mix(vec3(1.0), mat.albedo, mat.metalness);
    
    vec3 col = mat.albedo * key_diffuse * (1.0 - mat.metalness);
    
    // Reflection vector
    vec3 refDir = reflect(view, normal);
    
    // Specular highlight (softer with roughness)
    float key_spec = max(0.0, dot(key_Dir, refDir));
    key_spec = pow(key_spec, 10.0 - 9.0 * mat.roughness) * atten * key_shadow;
    
    float specRatio = mat.metalness * diffuseRatio;
    
    col += vec3(key_spec) * specColor * specRatio;
    col *= lightColor;
    
    //Optionnal environment reflection (only for key light)
    if (AddEnv)
    {
       vec3 dome = SkyDome(refDir, mat.roughness);
       dome *= dome; //linear space conversion;
       col += f * dome * specRatio;
    }
    
    return col;
}

// Some 3 octave 1D noise for animation
float Noise13(float x, float seed)
{
    float res = Noise1(x, seed);
    res += Noise1(x * 2.0, seed) * 0.5;
    res += Noise1(x * 4.0, seed) * 0.25;
    return res;
}

// A calm animation where the plant is idle
void CalmAnim(out KeyFrame kf)
{
    kf.leafAngle = -0.15 + Noise13(iTime * 0.25, 45.0) * 0.5; //-0.5 to 0.2;
    kf.mouthAngle = 0.27; //0.27 to 1.4
    
    float spineNoise = Noise13(iTime * 0.2, 155.0);
    
    kf.spine1 = 0.5 + spineNoise * 0.2;     //rest at 0.5
    kf.spine2 = -0.7 - spineNoise * 0.15;    //rest at -0.7
    kf.spine3 = -0.65 - spineNoise * 0.15;	 //rest at -0.65
    
    kf.neck = Noise1(iTime * 0.25, 456.0) * 0.8;		 //-1.3 to 1.3
}

// A menacing animation where the plant is mouth opened ready to bite
void AgressiveAnim(out KeyFrame kf)
{
    float spineNoise = Noise13(iTime * 0.4, 155.0);
    
    kf.leafAngle = -0.15 - spineNoise * 0.5; //-0.5 to 0.2;
    kf.mouthAngle = 1.3 + Noise13(iTime * 1.0, 45.0) * 0.2; //0.27 to 1.4
    
    kf.spine1 = 0.6 + spineNoise * 0.2;     //rest at 0.5
    kf.spine2 = -0.7 - spineNoise * 0.15;    //rest at -0.7
    kf.spine3 = -0.7 - spineNoise * 0.15;	 //rest at -0.65
    
    kf.neck = Noise1(iTime * 0.6, 456.0) * 2.3;		 //-1.3 to 1.3
}

// An animation where the plant attacks repeatedly
void ChompAnim(out KeyFrame kf)
{
    float a = sin(iTime * 20.0) * 0.5 + 0.5;
    
    float spineNoise = Noise13(iTime * 0.4, 155.0);
    
    kf.leafAngle = -0.25 - a * spineNoise; //-0.5 to 0.2;
    
    kf.mouthAngle = mix(0.27, 1.6, a * a);
    
    kf.spine1 = 0.4 + spineNoise * 0.2;     //rest at 0.5
    kf.spine2 = -0.8 - spineNoise * 0.15 - a * 0.1;    //rest at -0.7
    kf.spine3 = -0.5 - spineNoise * 0.15 + a * 0.1;	 //rest at -0.65
    
    kf.neck = Noise1(iTime * 1.0, 456.0) * 2.3;		 //-1.3 to 1.3
}


vec4 render(vec3 camPos, vec3 rayDir)
{
       
    PlantSpace plantSpace;
    
    KeyFrame kf1;
    KeyFrame kf2;
    KeyFrame kf;
    
    // Varies the plant agressivity with time
    float aggro = mix(-0.5, 2.0, Noise1(iTime * 0.3, 236.8) + 0.5);
    
    // compute two animation poses and a blending factor
    if (aggro < 1.0)
    {
        CalmAnim(kf1);
    	AgressiveAnim(kf2);
    }
    else
    {
        AgressiveAnim(kf1);
    	ChompAnim(kf2);
        aggro -= 1.0;
    }
    
	mixKeyFrame(kf1, kf2, sat(aggro * 2.0), kf); 
    
    // Build matrices
    buildPlantSpace(kf, plantSpace);
    
    vec3 col;
    
    vec2 d = castRay(camPos, rayDir, MAX_DST, MIN_DST, plantSpace);
    
    
    if (d.x > MAX_DST)
    {
        // sky dome
        col = SkyDome(rayDir, 0.0);
    }
    else   
    {
        vec3 pos = camPos + rayDir * d.x;
 
        vec3 n;
        
        vec3 normalOffset = vec3(0);
        
        
        PBRMat mat;
        
        GetColor(d.y, pos, plantSpace, mat, normalOffset);
        
        mat.albedo *= mat.albedo; // Convert albedo to linear space
        
        n = normalize(calcNormal(pos, plantSpace) + normalOffset);
        
        // Some bogus ambient term
        vec3 ambient = mix(vec3(0.5, 1, 0.5), vec3(0.5, 0.5, 1), n.y * 0.5 + 0.5);
        ambient += vec3(0.5, 0.2, 0.2) * (1.0- abs(n.y * n.y));
        
        // Fake AO
        float dst = 1.0 - sat(SDF(pos + n * 0.2, plantSpace).x * 1.0);
        ambient *= (1.0 - dst * dst) * 0.8 + 0.2;
        ambient *= mat.occlusion * 0.5;
  
        col =  mat.albedo * ambient;
        
        // Fresnel
        float fresnel = pow(1.0 - sat(dot(n, -rayDir)), 1.0);

		vec3 key_LightPos = vec3(-10.0, 10.0, -13.0);
        col += PBRLight(pos, n, rayDir, mat, key_LightPos, vec3(0.9), 1000.0, fresnel, plantSpace, true);
        
                
        vec3 fill_LightPos = vec3(-8.0, 10.0, 10.0);
        col += PBRLight(pos, n, rayDir, mat, fill_LightPos, vec3(0.8), 50.0, fresnel, plantSpace, false);

    	col = pow(col,vec3(0.4545));
    }

    return vec4(col, d);
}

// Classic stuff
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv =(fragCoord - .5 * iResolution.xy) / iResolution.y; 

    vec3 camPos = vec3(0.0, 2.8, -40.0);
    vec3 camDir = vec3(0.0, 0.0,  1.0);
    
    vec3 rayDir = camDir + vec3(uv * 0.45, 0.0);
    
    
   	vec3 res = vec3(0.0);
    
    vec2 mouse = iMouse.xy/iResolution.xy;
    if(mouse.x<.001) mouse = vec2(0.5, 0.5);
    
    vec2 viewAngle = vec2((-mouse.x - 0.6) * pi2, (mouse.y - 0.65) * halfPi);
    
    mat4 viewMat = rotationY(viewAngle.x) * rotationX(viewAngle.y);
    
    camPos = (viewMat * vec4(camPos, 1.0)).xyz;
    rayDir = (viewMat * vec4(rayDir, 0.0)).xyz;
    

    res = render(camPos, rayDir).rgb;

    // Output to screen
    fragColor = vec4(res.rgb,1.0);
}