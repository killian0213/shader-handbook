// Buffer A (buffer) — A cup of coffee (Progressive) by PixelPhil
// https://www.shadertoy.com/view/3ltXR8


#define  PROGRESSIVE_RENDERING

// Uncomment one of those lines to focus on a different target in interactive mode
//#define  ASHTRAY
//#define  CENTER

// Uncomment this line for a different artistic statement
//#define MATCAP

// Yan can play with that quantity for a smoother or sharper DOF
#define BOKEH 0.02



#define MAX_DST 200.0
#define MIN_DST 0.004
#define S(a,b,c) smoothstep(a,b,c)
#define sat(a) clamp(a,0.0,1.0)
#define ZERO (min(iFrame,0))

//Material regions
#define TABLE		 	0.0
#define COFEE			2.0
#define STEEL			3.0
#define BURNT_TIP		4.0
#define ASH				5.0
#define SUGAR			6.0
#define MILK			7.0
#define CIGARETTE1		8.0
#define CIGARETTE2		9.0
#define PAPER			10.0

#define GLASS 			11.0



// all matrices and offsets that needs to be pre-computed
// in order to keep the SDF relatively straightforward
struct SceneSetup
{
    mat4 cup;
    mat4 spoon;
    mat4 ashtray;
    mat4 cig1;
    mat4 cig2;
    mat4 jug;
    mat4 sugar;
    
    vec3 noise;
};

// Attributes of a PBR material
struct PBRMat
{
    vec4 albedo;
    float metalness;
    float roughness;
    float occlusion;
};

    
// Procedural wood veins with optionnal grain
void WoodMaterial(vec3 pos, out PBRMat mat, bool simpler)
{
    vec2 p = (pos.xz + pos.yy);
    float wood = VoroNoise(p * vec2(0.01, 0.08), 0.5, 1.0);
    
    wood = fract(wood * 3.0);
    
    float wood2 = fract(wood * 10.0);
    
    p *= vec2(3.0, 6.0);
    
    float noise = 0.5;
    
    if (!simpler)
    {
        noise = (Noise2(p) + Noise2(p * 2.0)) * 0.5;
    }
    
    wood = wood * 0.5 + wood2 * 0.3 +  noise * 0.2;
    
    vec3 woodColor = mix(vec3(0.52, 0.38, 0.25), vec3(0.7, 0.58, 0.4), wood);
    
    mat = PBRMat(vec4(woodColor, 1.0), 0.4, noise * 0.3, 1.0); 
}

// Ash material
void AshMaterial(vec3 pos, out PBRMat mat, bool simpler)
{
    float noise = VoroNoise(pos.xz * 4.0, 1.0, 0.3);
    noise = 1.0 - (noise * noise) * 0.75;
    
    if (!simpler)
    {
       noise -= VoroNoise(pos.xz * 10.0, 1.0, 0.3) * 0.2;
    }
    
    mat = PBRMat(vec4(vec3(noise), 1.0), 0.0, 1.0, 1.0); 
}

// Cigarette material
void CigMaterial(vec3 pos, mat4 cigMat, out PBRMat mat, bool simpler)
{
	vec3 cigPos = (cigMat * vec4(pos, 1.0)).xyz;
    
    if (cigPos.y < 4.5) // At the filter
    {   
        vec3 filterColor = vec3(0.9, 0.55, 0.01);
        
        if (!simpler) // in reflexions the dots are not computed
        {
            // Get the cylindrical texture coordinates
            float angle = atan(-cigPos.z, cigPos.x); 
            vec2 uv = vec2(angle, -cigPos.y);
            
            // Add some noise to the domain for more irregular shapes
            uv = uv * 1.5 + vec2(VoroNoise(uv * 3.0, 1.0, 1.0) * 0.6, 0);

			// Threshold a voronoi distance to prodice dots
            float noise = S(0.2, 0.21, Voronoi(uv, 1.0));

            // Blend two colors
            filterColor = mix(vec3(0.98, 0.7, 0.01), vec3(0.9, 0.55, 0.01), noise);
        }
        
        mat = PBRMat(vec4(filterColor, 1.0), 0.2, 0.7, 1.0); 
    }
    else if (cigPos.y < 4.7)
    {
        // This is the golden ring of the filter
    	mat = PBRMat(vec4(1, 0.7, 0, 1.0), 1.0, 0.0, 1.0);
    }
    else
    {
        // Te rest is white
		mat = PBRMat(vec4(0.95, 0.95, 0.95, 1.0), 0.0, 0.5, 1.0); 
    }
}

void CofeeMaterial(vec3 pos, out PBRMat mat, SceneSetup setup)
{
    vec3 cofeeCol = vec3(0.15, 0.01, 0.1);
    
    pos = (setup.cup * vec4(pos, 1.0)).xyz;
    
	if (pos.y > 5.25)
    { 
		// Foam
        float fl = max(0.0, length(pos.xz + vec2(-1.8, 1.5)));

        float foam = S(3.0, 6.0, fl);
        float foam2 = S(10.0, 3.0, fl);
        
        vec3 foamHue = mix(vec3(0.9, 0.7, 0.4), vec3(0.9, 0.8, 0.75) * 0.8, foam2);
        
        vec3 foamColor = mix(cofeeCol, foamHue, foam);;
        
        mat = PBRMat(vec4(foamColor, 1.0), 0.5, foam, 1.0);
    }
    else
    {
    	mat = PBRMat(vec4(cofeeCol, 1.0), 0.5, 0.0, 1.0);
    }
}

// Computes a PBR Material from material ID and world position
void GetMaterial(float id, vec3 pos, SceneSetup setup, out PBRMat mat, bool simpler)
{   

    mat = PBRMat(vec4(1, 0, 0, 1.0), 0.6, 1.0, 0.5); // Default material is red plastic
    #ifdef MATCAP
    return;
    #else
    
    
    if 		(id == TABLE		) { WoodMaterial(pos, mat, simpler); } 
    //else if (id == PORCELAIN	) { mat = PBRMat(vec4(0.9, 0.9, 0.9, 1.0), 0.7, 0.0, 4.0); }
    else if (id == COFEE		) { CofeeMaterial(pos, mat, setup); }
    else if (id == STEEL		) { mat = PBRMat(vec4(0.75, 0.75, 0.75, 1.0), 0.95, 0.0, 1.0); }
    else if (id == GLASS 		) { mat = PBRMat(vec4(0, 0, 0, 0.05), 2.0, 0.0, 1.0); }
    else if (id == ASH			) { AshMaterial(pos, mat, simpler); }
    else if (id == SUGAR		) { mat = PBRMat(vec4(0.8, 0.8, 0.8, 1.0), 0.2, 0.9, 6.0); }
    else if (id == MILK			) { mat = PBRMat(vec4(1, 1, 1, 1.0), 0.0, 0.0, 3.0); }
    else if (id == CIGARETTE1	) { CigMaterial(pos, setup.cig1, mat, simpler); }
    else if (id == CIGARETTE2	) { CigMaterial(pos, setup.cig2, mat, simpler); }
    else if (id == PAPER		) { mat = PBRMat(vec4(1, 1, 1, 1.0), 0.3, 1.0, 1.0); }
    else if (id == BURNT_TIP	) { mat = PBRMat(vec4(0, 0, 0, 1.0), 0.2, 1.0, 1.0); }
    
    #endif
    
  	return;	
}

// Build all the matrices and offsets necessary to compute the SDF
// leaving all that in would lead to bad perfs and insane compile times
void buildSetup(out SceneSetup res, vec3 target)
{

    res.cup = translate(target);
    
    res.spoon = rotationX(-1.5) *
        		rotationY(-1.0) *
                translate(vec3(2.0, -0.48, 9.0)) * res.cup;
    
    res.ashtray = rotationY(-0.5) * 
        		  translate(vec3(-10.0, -5.0, -20.0)) * res.cup; 
 
    res.cig1 =  rotationX(1.8)*
                translate(vec3(0.0, 1.0, 10.0)) *
                res.ashtray;

    mat4 swizzle = 	mat4( 1, 0, 0, 0,
                          0, 0, 1, 0,
                          0, 1, 0, 0,
                          0, 0, 0, 1);
    
    res.cig2 =  rotationZ(-2.5)*
                translate(vec3(-3, -4.0, 3.5)) *
        		swizzle *
                res.ashtray;
    
    res.jug =  rotationY(3.5) * translate(vec3(18.0, -0.6, -8)) * res.cup;
        
    res.sugar = rotationY(2.0) * translate(vec3(-6.2, -0.4, 4.3)) * res.cup;
}

// A cigarete ditance function with material ids
vec2 dstCigarette(vec3 pos, float len, float id)
{
    vec2 cig = vec2(length(pos.xz) - 0.8, id); // infinite cylinder
    
    cig = combineMax(cig, vec2(-pos.y, PAPER)); // cut at the tip of the filter with paper material
    
     // cut irregularly at the end with burt black material
    cig = combineMax(cig, vec2(pos.y - len + (sin(pos.x * 10.0) + sin(pos.y * pos.z)) * 0.029, BURNT_TIP));
    
    return cig;
}

// I use the noise texture mainly to reduce compile time under 10s on my less capable computer
vec3 TextureNoise(vec2 uvs)
{
    return textureLod(iChannel3, uvs, 0.0).rgb;
}

// SDF of the scene
// There is a neat trick here to bring back compile time from 30 to 10s
// When OpaqueOnly is set to true only the opaque obects are returned
// When it is set to false only glass is returned
// This produces two simpler SDFs that end up being much more efficient to trace
// on their own and doing compositing afterward rather than tracing a more complicated
// one that would include both
vec2 SDF(vec3 pos, SceneSetup setup, bool opaqueOnly)
{
    vec2 res;
    

    vec3 cupPos = (setup.cup * vec4(pos, 1.0)).xyz;
    
    // cup starts with the coumpound of a round cylinder and round cone
    float cup = sdRoundedCylinder(cupPos, 2.0, 0.25, 0.0);
    float cupsp = sdRoundCone(cupPos - vec3(0, 4.5,0), 6.2, 7.4, 10.0 );
   	cup = smin(cup, cupsp, 1.0);
    
    
    // is a reduced version of the cup's hull cut at a level
    float coffee = cup + 0.5;
	coffee = smax(coffee, cupPos.y - 5.5, 0.3);
    
    // Cup is hollowed with onioning and cut open
    cup = abs(cup) - 0.5; 
    cup = smax(cup, cupPos.y - 8.0, 0.6) * 0.5;
    
    // The plate starts with a rounded cylinder stretched in x and z
    vec3 platePos = cupPos * vec3(0.35, 1.0, 0.35);
    float plate = sdRoundedCylinder(platePos  - vec3(0, 1.0,0), 2.0, 2.0, 0.0);
    
    // hollowed with onioning and cut 
    plate = abs(plate) - 0.1;
    plate = smax(plate, cupPos.y - (1.0), 0.4);
    
    // a torus is added at the base of the cup for extra detail
    plate = smin(plate, sdTorus(cupPos - vec3(0, -0.8, 0), vec2(5.1, 0.3)), 0.6);
    plate *= 0.35; // Adjusts for ray tracing misses
    
    
    // Then handle is an elongated torus that is scaled along x on the liower left quarter  
    vec3 handlePos = cupPos.xzy - vec3(8.1, 0.0, 4.5);
    float scale = 1.0;
    
    if (handlePos.x < 0.0 && handlePos.z < 0.0)
    {
        scale = 0.6;
        handlePos.x *= scale;
    }
    handlePos.y = max(0.0, abs(handlePos.y) - 0.5);
    float handle = sdTorus(handlePos, vec2(2.2, 0.45));
    
     
    res = vec2(coffee, COFEE); // combine coffee in the final result
    
    // The table is a rounded cylinder
    vec3 tablePos = cupPos - vec3(-15.0, -3.0, 43.0);
    float table = sdRoundedCylinder(tablePos, 30.0, 1.0, 1.0);
    
    // It has a foot (check it out ;) ) that is an infinite cylinder cut a level
    float tablefoot = max(tablePos.y, length(tablePos.xz) - 4.5);
    
    res = combineMin(res, vec2(table, TABLE)); // table is combines in the final result
    


    vec3 sponPos = (setup.spoon * vec4(pos, 1.0)).xyz;
    
    // The spoon starts with a 2D disk sdf with a top half stretched
    if (sponPos.y > 0.0) sponPos.y *= 0.7;
    sponPos.x *= 1.1;
    float len = length(sponPos.xy);
    float spoon = len - 2.8; 
    
    // The handle starts with a trapezoid sdf with it's tip smoothly clamped
   	if (sponPos.y < 0.0)
    {
        float handle = abs(sponPos.x) - 0.5 + sponPos.y * 0.04;
        handle = smax(handle,  -16.0 - sponPos.y, 1.0);
        
        spoon = smin(spoon, handle, 1.5);
    }
    
    // That resulting 2D shape is the used to stencil cut a combination of distances
    // function to describe the curvature of the handle and the spoon itself
    float d = (len / 3.0);
    d = smin(d * d, 1.0, 0.2);
    
    float k = abs(sponPos.x);
    
    float bend = S(-1.8, -4.5, sponPos.y);
    k = k* k * 0.2;
    k *= bend;
    
    spoon = smax(spoon, -0.1 + abs(sponPos.z -  bend * 0.5 - d + k), 0.05);
    
    // It is super non-euclidean and honestly I couldn't believe I would get away with it
    // but it turned out that just adjusting the ray marching step a bit produced a clean result
    spoon *= 0.5;
    

    vec3 ashtrayPos = (setup.ashtray * vec4(pos, 1.0)).xyz; 
    
    
	// Ashtray, like many other things, starts with a rounded cylinder
    float ashtray = sdRoundedCylinder(ashtrayPos - vec3(0, -0.7,0), 4.5, 0.6, 4.0);
    

   	if (ashtray - 4.0 > 0.0) //Bounding volume optimisation for the ashtray
   	{
        ashtray = ashtray - 3.5;
    }
    else
    {
		// The cigarette holder holes are cut with an infinite cylingder
        // elongated on y with a central domain symmetry
        
        vec3 cylPos = abs(ashtrayPos);
        if (cylPos.x > cylPos.z) cylPos.xz = cylPos.zx;
        cylPos.y = max(0.0, abs(cylPos.y) - 1.0);
        float cyl = length(cylPos.yx) - 1.0;    
        
        ashtray = abs(ashtray) - 0.8;				// Hollwed with onioning
        ashtray = smax(ashtray, ashtrayPos.y, 0.5); // Cut open
        ashtray = smax(ashtray, -cyl, 0.35);		// Removed holder holes
        
        // The ash level is a combination of the squared central ditance to the ashtray
        // and some arbitrary sines
        float l = length(ashtrayPos.xz) / 5.0;
        l = l * l * 0.7;
        float ash = ashtrayPos.y + 3.5 + sin(ashtrayPos.x * 0.3 - 0.4)  + sin(ashtrayPos.z * 0.76) * 0.25 + l;
        ash = smax(ash, -ashtrayPos.y - 4.75, 0.25);
        
        if (ash - 1.0 > 0.0) // Do not compute details of the ash unless very close
        {
            ash -= 0.5;
        }
        else
        {
            // VoroNoise is more pleasing to the eyes but adds 2s to compile time on my PC Laptop per call in the SDF
        	// ash += VoroNoise(ashtrayPos.xz * 2.5, 1.0, 0.55) * 0.6;
            ash += TextureNoise(ashtrayPos.xz * 2.5 / 64.0).r * 0.9;
        	ash *= 0.6;
        }
        
        
        vec3 cig2Pos = (setup.cig2 * vec4(pos, 1.0)).xyz;

        // The second cigarette is crushed, so I mess with it's domain
        cig2Pos.x += abs(sin(pos.x)) * 0.3;
            
        vec2 cig2 = dstCigarette(cig2Pos, 6.0, CIGARETTE2);
        
        // Put all that trash together
        res = combineMin(res, vec2(ash, ASH));
        res = combineMin(res, cig2);
    }
    
    
    // Leave the first cigarette out of the Ashtray bound optimisation as it is on the edge
    // and prone to raycast misses
    vec3 cig1Pos = (setup.cig1 * vec4(pos, 1.0)).xyz;
	vec2 cig1 = dstCigarette(cig1Pos, 14.0, CIGARETTE1);
    res = combineMin(res, cig1);
   

    // See comments on top of the function
    // When opaqueOnly is set to false, ignore the glass entierly
    // The compiler will strip it out
    if (!opaqueOnly)
    {
        cup = smin(handle,cup, 0.5);
        cup = min(ashtray,cup);
        cup = min(plate,cup);

        // When opaqueOnly is set to true, just return the glass
        // The compiler will strip out all dead code and produce a lightweight SDF
        return vec2(cup, GLASS);
    }


    
    vec3 jugPos = (setup.jug * vec4(pos, 1.0)).xyz;
    //jugPos -= vec3(-18, 0.6, 8);
    //jugPos = (rotationY(3.5) * vec4(jugPos, 0.0)).xyz;  
    
    float jug = sdRoundCone( jugPos - vec3(0, 0, 0), 4.0, 3.0, 10.0 );
    
    
    if (jug - 7.0 > 0.0) // Bounding box optimisations for the milk jug
    {
        jug = jug - 4.3;
    }
    else
    {
        // The spout is an infinite cylinder bent and scale on the x axis
        vec2 spoutPos = jugPos.xz;
        spoutPos.x *= 0.7;
        spoutPos.x += jugPos.y * 0.23;

        // combines with the jug body
        jug = smin(jug, length(spoutPos) - 1.0, 0.2);

        jug = smax(jug, -jugPos.y - 1.5, 1.0); // cut below

        jug = abs(jug) - 0.1;  // hollowed with onioning

        jug = smax(jug, jugPos.y - 8.5, 0.1); // cut above
        jug *= 0.8; // adjust for raycast misses

		// The Handle is an elongated, hollowed cylinder bent with some domain distortion
        vec3 jugHandlePos = jugPos - vec3(5.0, 4.5, 0);

        //jugHandlePos.x -= jugHandlePos.y * 0.1;
        jugHandlePos = max(vec3(0.0), abs(jugHandlePos) -vec3(jugPos.y * 0.1 + 0.25, 2.3, 0.0));

        float jughandle = abs(length(jugHandlePos.xy) - 0.6) - 0.1;

        jughandle = smax(jughandle, abs(jugHandlePos.z) - 0.6, 0.1);

        jug = min(jug, jughandle);

        // Got milk?
        float milk = sdRoundedCylinder(jugPos - vec3(0.0, 4.0, 0), 1.5, 0.35, 0.0);
        res = combineMin(res, vec2(milk, MILK));
    }

    // Integrate everything steel in the final result
    res = combineMin(res, vec2(min(min(spoon, jug), tablefoot), STEEL));
    
    // Sugar is a rounded bow with added noise
    vec3 sugarPos = (setup.sugar * vec4(pos, 1.0)).xyz;
    float sugar = sdRoundBox(sugarPos, vec3(1.8, 0.6, 0.9), 0.3);
    
    if (sugar - 0.5 < 0.0)
    {
        // Changed to bring back compile time under 10s on my laptop
        //sugar += VoroNoise((sugarPos.xz + sugarPos.yx)  * 6.0, 1.0, 0.5) * 0.1;   
        sugar += TextureNoise((sugarPos.xz + sugarPos.yx)  * 8.0 / 64.0).r * 0.1;
        sugar *= 0.7;
    }
    
	res = combineMin(res, vec2(sugar, SUGAR)); // Finally add sugar :D

	return res;
}


// Like the SDF, normals can be computed with glass or solid objects
// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( vec3 pos, SceneSetup ps, bool opaqueOnly)
{
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e * SDF(pos+0.0005*e, ps, opaqueOnly).x;
    }
    return normalize(n);
}


// Cast a ray across the SDF return x: Distance, y: Materila Id
vec2 castRay(vec3 pos, vec3 dir, float maxDst, float minDst, SceneSetup ps, bool opaqueOnly)
{
    vec2 dst = vec2(5.0, 0.0);

    float t = 0.0;
    
    while (dst.x > minDst && t < maxDst)
    {
        dst = SDF(pos, ps, opaqueOnly);
        t += dst.x;
        pos += dst.x * dir;
    }
    
    return vec2(t + dst.x, dst.y);
}

float shadow(vec3 pos, vec3 normal, vec3 lPos, SceneSetup ps)
{       
#ifdef PROGRESSIVE_RENDERING
    lPos += ps.noise * 8.0; // In progressive mode, the light position is jittered for smooth shadows
#endif
    
    vec3 dir = lPos - pos;  // Light direction & disantce
    
    float len = length(dir);
    dir /= len;				// It's normalized now
    
    pos += normal * MIN_DST * 40.0;
    
    
    vec2 ray =  castRay(pos, dir, MAX_DST, MIN_DST * 10.0, ps, true);
    if (ray.x < MAX_DST) return 0.0; // if it crosses something opage shadow is full
    
    ray =  castRay(pos, dir, MAX_DST, MIN_DST * 10.0, ps, false);
    if (ray.x < MAX_DST) return 0.45; // if it crosses something transparent shadow is partial
    
    // No shadow
    return 1.0;
}

// Convert the St Peters Basilica red ambiance to something more blueinsh and desaturated
vec3 AmbianceLight(vec3 texColor)
{
    vec3 color = texColor.bgr; // swizzle to change red to blue
    float gs = dot(color, vec3(0.33)); // grayscale value
    color = mix(color, vec3(gs), 0.5); // desaturate
    return color * color; // convert to linear space
}

vec3 SkyDomeBlurry(vec3 rayDir, float lod)
{
    rayDir.z = -rayDir.z;
    return AmbianceLight(textureLod(iChannel2, rayDir.xyz,  lod).rgb);
}

vec3 SkyDomeSharp(vec3 rayDir)
{
    rayDir.z = -rayDir.z;
    return AmbianceLight(textureLod(iChannel2, rayDir.xyz,  0.0).rgb);
}

// Simplified render within reflection
vec3 ReflectionLight(vec3 pos, vec3 n, float matId, vec3 rayDir, SceneSetup setup)
{
     PBRMat mat;
     
     GetMaterial(matId, pos, setup, mat, true); // Comput material
     mat.albedo.rgb *= mat.albedo.rgb; 

     // Fresnel
     float fresnel = pow(1.0 - sat(dot(n, -rayDir)), 1.0);

     // Just some basic facing ratio and environment lighting
     vec3 col = fresnel * mat.albedo.rgb;
    
     if (mat.roughness < 0.5)
     {
         vec3 refDir = reflect(rayDir, n);
         col += SkyDomeSharp(refDir) * fresnel * 0.6;
     }
    
	 return col;
}

// A PBR-ish lighting model
vec3 PBRLight(vec3 pos, vec3 normal, vec3 view, PBRMat mat, vec3 lightPos, vec3 lightColor, float lightRadius, float fresnel, SceneSetup ps, bool AddEnv)
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
    vec3 specColor = mix(vec3(1.0), mat.albedo.rgb, mat.metalness);
    
    vec3 col = mat.albedo.rgb * key_diffuse * min(1.0, 2.0 - mat.metalness * 2.0);
    
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
       vec3 hitPos = pos + normal * MIN_DST * 40.0;
       
#ifdef PROGRESSIVE_RENDERING
       refDir = normalize(refDir + (ps.noise * mat.roughness * 0.5));
#endif
        
       // Cast two rays
       // One with only opage objects
       vec2 hitOpaque = castRay(hitPos, refDir, MAX_DST, MIN_DST * 5.0, ps, true);
       // One with oly transparent ones
       vec2 hitGlass  = castRay(hitPos, refDir, MAX_DST * 0.5, MIN_DST * 5.0, ps, false);
        
       vec3 refCol;
       
       if (hitOpaque.x < MAX_DST)
       {
           // If opaque did hit we reflect that
           vec3 refPos = hitPos + refDir * hitOpaque.x;
           vec3 refN = calcNormal(refPos, ps, true);
           refCol = ReflectionLight(refPos, refN, hitOpaque.y, refDir, ps);
       }
       else
       {
           // otherwise we reflect the skydome
           refCol = SkyDomeSharp(refDir);
       }
        
        
       if (hitGlass.x < MAX_DST * 0.5 && hitGlass.x < hitOpaque.x)
       {
           // If the glass is before the solid hit then we reflect that too
           vec3 refPos = hitPos + refDir * hitGlass.x;
           vec3 refN = calcNormal(refPos, ps, false);
           refCol += ReflectionLight(refPos, refN, hitGlass.y, refDir, ps);
       }

       col += f * refCol * specRatio;
    }
    
    return max(vec3(0), col);
}

// Shades and integrate a surface point from its position, normal and material id
vec3 IntegrateSurface(vec3 col, vec3 pos, vec3 n, float matId, vec3 rayDir, SceneSetup setup)
{ 
     PBRMat mat;
     
     GetMaterial(matId, pos, setup, mat, false);
     
     mat.albedo.rgb *= mat.albedo.rgb; // Convert albedo to linear space

     vec3 ambient = SkyDomeBlurry(n, 5.0);
     ambient *= mat.occlusion * 0.5;
    
     col = mix(col, mat.albedo.rgb * ambient, mat.albedo.a);
     
     // Fresnel
     float fresnel = pow(1.0 - sat(dot(n, -rayDir)), 1.0);

     // Add both light contributions
	 vec3 key_LightPos = vec3(10.0, 24.0, -13.0);
     col += PBRLight(pos, n, rayDir, mat, key_LightPos, vec3(1.0), 1000.0, fresnel, setup, true);
                  
     vec3 fill_LightPos = vec3(-20.0, 15.0, 20.0);
     col += PBRLight(pos, n, rayDir, mat, fill_LightPos, vec3(1.0), 1000.0, fresnel, setup, false);

	return col;
}


// Render a ray including refraction of glass
vec4 renderRefract(vec3 camPos, vec3 rayDir, SceneSetup setup)
{

    // Cast to rays on on solid things on on glass only
    vec2 hitSolid = castRay(camPos, rayDir, MAX_DST, MIN_DST, setup, true);
    vec2 hitGlass = castRay(camPos, rayDir, MAX_DST * 0.5, MIN_DST, setup, false);
    
    // I know it seems weird, but it's much more efficient to proceed this way and
    // to trace both rays from the camera on two much simpler SDFs
    
    vec3 solidPos;
    vec3 solidRayDir;
    float solidMat;
    
    vec3 glassPos;
    vec3 glassNormal;
    bool needGlass = false;   
    bool needSolid = false;
    bool needSky = false;
    
    vec3 skyDir = rayDir;
    
    if (hitGlass.x < hitSolid.x && hitGlass.x < MAX_DST * 0.5)
    {
        // Glass is before anything solid
        
        // wee keep track of the glass surface
        needGlass = true;
        glassPos = camPos + rayDir * hitGlass.x;
        glassNormal = calcNormal(glassPos, setup, false);
        
        // refract the ray and shoot again in the opage SDF
        vec3 dir2 =  normalize(rayDir - glassNormal * 0.5);
        
        vec2 hitRefract = castRay(glassPos, dir2, MAX_DST, MIN_DST, setup, true);
        
        if (hitRefract.x < MAX_DST)
        {
            // Refraction hit! that's the opaque surface we'll shade
            needSolid = true;
            solidPos = glassPos + dir2 * hitRefract.x;
            solidMat = hitRefract.y;
        }
        else
        {
            // It's a miss, we need to refract the sky dome
            needSky = true;
            skyDir = dir2;
        }       
    }
    else
    {
        // No glass here
        if (hitSolid.x < MAX_DST)
        {
            // a solid his si confirmed, we'll render that
            needSolid = true;
            solidPos = camPos + rayDir * hitSolid.x;
            solidRayDir = rayDir;
            solidMat = hitSolid.y;
        }
        else
        {
            // No hit, the skydome is straight ahead
            needSky = true;
            skyDir = rayDir;
        }
    }
    
    vec3 col = vec3(0);
    
    if (needSky) // Render the skydome if needed
    {
        col =  SkyDomeBlurry(skyDir, 0.0); 
    }
    

    if (needSolid) // Render the opaque surfaces if needed
    {
        col = IntegrateSurface(col, solidPos, calcNormal(solidPos, setup, true), solidMat, rayDir, setup);
    }


    if (needGlass) // Render glass if needed
    {
        col = IntegrateSurface(col, glassPos, glassNormal, GLASS, rayDir, setup);
    }

  
    return vec4(col, 1.0);
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 mouse = iMouse.xy/iResolution.xy;
    if(mouse.x<.001) mouse = vec2(0.37, 0.4);
    
    
    // There's a hidden pixel in the corner of the frame that store
    // xy: previous mouse position
    // z: 0 -> Interactive Mode / 0.1 and above -> Slideshow frame tick
    // w: Integration amount for progressive rendering convergence
    vec4 mixData = texture(iChannel0, vec2(0,0));
    
    bool SlideShow = (mixData.z > 0.0);
    
    if (iTime < 0.1) // When time is reset we turn off progressive integration for a while
    {
        mixData.xy = mouse; // Set the mouse pos
        mixData.a = 1.0;    // Integrate 100%
        mixData.z = 0.1;    // Force SlideShow mode
    }
    
    float finalMix = mixData.a;
    
    // Compute the index of the Slide of the diaporama we are showing
    
    float time = iTime;
    if (iResolution.x <= 300.0) time -= 5.0; // For a better thumbnail the time is offset by 5s
    
    float frameTime = time * 0.1;
    float frameId = floor(frameTime);
        
    
    if (fragCoord.x < 1.0 && fragCoord.y < 1.0)
    {
        // We are rendering the secret control pixel
        
        // Update the pixel with up to date info
        fragColor.xy = mouse;
        fragColor.z = mixData.z;
        
        vec2 mouseDiff = mixData.xy - mouse;
        
        float diffSq = dot(mouseDiff, mouseDiff);
        if (diffSq > 0.00001)
        {
            // If the mouse has moved
           	fragColor.a = finalMix = 1.0; // Restart integration
            fragColor.z = 0.0; // Turn off Slideshow mode
            
        }
        else
        {
            // For the mage integral to quickly converge to the average of all the computed 
            // frames the blending ratio must follow the sequence 1; 1/2; 1/3; 1/4 etc...
#ifdef PROGRESSIVE_RENDERING
            float div = 1.0 / finalMix; // current divisor
            fragColor.a = max(0.01, 1.0 / (div + 1.0)); // new divisor (never less than 1%)
            
            if (SlideShow)
            {
                float frame = 0.1 + mod(frameId, 5.0) * 0.1; // Compute the slideshow 'tick'

                if (abs(mixData.z - frame) > 0.01) // If we just chnanged Slide
                {
                    // Restart integration from scratch for the new frame to converge quickly
                    fragColor.a = finalMix = 1.0;
                    fragColor.z = frame; // Record the change for next frame
                }       
            }
#else
            fragColor.a = 1.0; // No integration when turned off
#endif

        }
        
        return;
    }
    
    vec3 target;
    vec2 viewAngle;
        
    if (SlideShow)
    {
		// In slideshow mode
        float viewPoint = mod(frameId, 3.0);
        vec4 ranges;
        
        // Round robin on the 3 targets
        if (viewPoint == 0.0)
        {
            // Coffee cup
            target = vec3(0.0);
            ranges = vec4(-1.3, 1.8, -0.2, -0.8);
        }
        else if (viewPoint == 1.0)
        {
            // Ashtray
            target = vec3(10.0, 0.0, 20.0);
            ranges = vec4(0.15, 2.0, -0.2, -1.2);
        }
        else
        {
            // Composition center
            target = vec3(0.0, 0.6, 10);
            ranges = vec4(-1.0, 1.8, -0.2, -0.5);
        }
        
        
        // Shuffle the view angle from pre-determined ranges
        float v = mod(frameId + 1.0, 6.0) / 5.0;
        float h = mod((frameId + 1.0) * 3.0, 7.0) / 6.0;
        
        float vert = mix(ranges.z, ranges.w, v);
        float horiz = mix(ranges.x, ranges.y, h);

        
        viewAngle = vec2(horiz, vert);
        // In slideshow mode the camera rotates very slowly to create some sort of subliminal parralax
        viewAngle.x += fract(frameTime) * 0.06;
    }
    else
    {
        // In intergactive mode aim at a fixed point an orient the view with the mouse
        target = vec3(0.0);
    
        #ifdef ASHTRAY
        target = vec3(10.0, 0.0, 20.0);
        #endif

        #ifdef CENTER
        target = vec3(0.0, 0.6, 10);
        #endif
        
        viewAngle = vec2((-mouse.x - 0.6) * pi2, (mouse.y - 0.65) * halfPi);
    }
       
    

    SceneSetup setup;
    
    
    // Build matrices
    buildSetup(setup, target);
    
    vec2 uv =(fragCoord - .5 * iResolution.xy) / iResolution.y; 

    // Compute Camera
    vec3 camPos = vec3(0.0, 2.0, -50.0);
    
    vec3 camDir = vec3(0.0, 0.0,  1.0);
    
    // Get some 3D noise to jitter some stuff
    vec2 noiseUv = uv + vec2(mod(iTime, 45.0), 0.0);
    setup.noise = hash3(noiseUv) - vec3(0.5); // vec3(n, n2, fract((n + n2) * 456.345));
    
    // Jitter the ray direction at sub-pixel level for perfect AA
    #ifdef PROGRESSIVE_RENDERING
    vec2 aa = setup.noise.xy * 0.5 / iResolution.y;
    #else
    vec2 aa = vec2(0);
    #endif
    
    vec3 rayDir = camDir + vec3(uv * 0.45 + aa , 0.0) ;
    
    
    
   	vec3 res = vec3(0.0);

    // Slightly jitter the camera around the focal point for depth of field
    #ifdef PROGRESSIVE_RENDERING
    viewAngle += setup.noise.xy * BOKEH;
    #endif
    
    
    // Orient the camera
    mat4 viewMat = rotationY(viewAngle.x) * rotationX(viewAngle.y);
    
    camPos = (viewMat * vec4(camPos, 1.0)).xyz;
    rayDir = (viewMat * vec4(rayDir, 0.0)).xyz;
    

    // Render the pixel
    res = renderRefract(camPos, rayDir, setup).rgb;

    // Integrate the new pixel with the previous frame.
    // The integration is done in linear space for the result to be gamma correct.
    #ifdef PROGRESSIVE_RENDERING
    vec3 prevFrame = textureLod(iChannel0, fragCoord.xy / iResolution.xy, 0.0).rgb;
    res = mix(prevFrame, res, finalMix);
    #endif
    

    // Output to buffer
    fragColor = vec4(res.rgb,1.0);
}