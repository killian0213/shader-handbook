// Common (common) — Asteroid Debris by Shane
// https://www.shadertoy.com/view/tsGXWm

/*

    For people who need a quick 3D coordinate packing explanation, or refresher --
    I always forget, so need to refresh my memory every. single. damn. time. :D

	Anyway, a 1024 by 1024 texture will have just over a million pixels. What you 
    need to do is choose three dimensions (one for X, Y and Z) that will multiply
	together to fit into those million pixels -- We'll ignore the four individual
	pixel channels, for now. X, Y and Z don't need to be equal, or even, but it's 
	probably helpful to choose something simple that will fit into the geometry of 
	the situation -- For instance, if you were surfacing a long box, you'd probably
	want more X pixels, and fewer Y and Z. 

	To make things easy, I chose 100 pixels for all three dimensions, since 
	100x100x100 equals 1 million precisely. This works out nicely. On the texture, 
	you render 100 boxes (10 rows of 10) that each have X and Y dimensions of 100. 
	The X and Y values are represented by the XY coordinate of each box, and the Z 
	value is represented by the box itself. For instance, the surface value for the
	coordinate "vec3(20, 40, 45)" will be found in the 45th box (row 5, column 6) 
    at XY coordinates "vec2(20, 40)." Simple.

	There is the matter of converting the uv (fragment) coordinates to the 3D 
	position, and also converting the 3D position in your scene to the texture 
	coordinates in the cube map face, but that's just a bit of math involving 
	modulos and so forth, which you can find below.

*/

// Cube size.
const vec3 size = vec3(100);

// Cubic texture dimensions. They're large and they're constant, which makes life
// so much easier.
vec2 cubeMapRes = vec2(1024);

// Global texture scaling variable. I probably should have built it into various
// functions
float gSc;


vec3 convertCoord(vec2 p){
   
    p *= cubeMapRes;
    
    //p = mod(p, vec2(1000, 1000));
    float z = floor(p.x/100.) + floor(p.y/100.)*10.;
    return vec3(mod(floor(p.xy), 100.), z)/100.;

}

// Straight UV coordinate to cubemap face read.
vec4 tx(samplerCube iCh, vec2 uv){
    
    // Back Z face -- Depending on perspective. Either way, so long as
    // you're consistant.
    return texture(iCh, vec3(fract(uv) - .5, .5));
}


// Straight 3D coordinate to cubemap face read.
vec4 tMap(samplerCube iCh, vec3 p){

    // Multiplying "p" by 100 was style choice.
    p *= 100.;
    
    // Using the 3D coordinate to index into the cubemap and read
    // the isovalue. Basically, we need to convert Z to the particular
    // square slice on the 2D map, the read the X and Y values. 
    //
    // mod(p.xy, 100), will read the X and Y values in a square, and 
    // the offset value will tell you how far down (or is it up) that
    // the square will be.
    
    vec2 offset = mod(floor(vec2(p.z, p.z/10.)), vec2(10, 10));
    vec2 uv = (mod(floor(p.xy), 100.) + offset*100. + .5)/cubeMapRes;
    
    // Back Z face -- Depending on perspective. Either way, so long as
    // you're consistant.
    return texture(iCh, vec3(fract(uv) - .5, .5));
}



// Smooth interpolated 3D coordinate to cubemap face. The "p" value has 
// already been multiplied by 100 in the "texMapSmooth" function (See below).
vec4 tMapSm(samplerCube iCh, vec3 p){
 
    // Using the 3D coordinate to index into the cubemap and read
    // the isovalue. Basically, we need to convert Z to the particular
    // square slice on the 2D map, the read the X and Y values. 
    //
    // mod(p.xy, 100), will read the X and Y values in a square, and 
    // the offset value will tell you how far down (or is it up) that
    // the square will be.
    vec2 offset = mod(floor(vec2(p.z, p.z/10.)), vec2(10, 10));
    vec2 uv = (mod(p.xy, 100.) + offset*100. + .5)/cubeMapRes;
    
    // Back Z face -- Depending on perspective. Either way, so long as
    // you're consistant. I noticed the Y values need to be flipped...
    // I'd like to arrange so that it's not necessary, but it might be
    // and internal thing, so I'm not sure how, yet.
    //
    // You could also use one of the newer texture functions that 
    // doesn't require the ".5" and "iChannelRes0" division, but I'm
    // keeping it oldschool. :) Actually, if the newer ones are
    // superior, let us know.
    return texture(iCh, vec3(fract(uv) - .5, .5));
}


// Smooth texture interpolation. You really need this -- I wish you didn't, but you do.
// I wrote it a while ago, and I'm pretty confident that it works. The smoothing factor
// isn't helpful at all, which surprises me. It's written in the same way that you'd 
// write any cubic interpolation: 8 corners, then a linear interpolation using the corners
// as boundaries.
vec4 texMapSmooth(samplerCube tx, vec3 p){

    // Used as shorthand to write things like vec3(1, 0, 1) in the short form, e.yxy. 
	vec2 e = vec2(0, 1);
  
    // Multiplying the coordinate value by 100 to put them in the zero to 100 pixel range.
    // It was a style choice... which I'm standing by, for now. :)
    p *= 100.;
    
    
    vec3 ip = floor(p);
    // Set up the cubic grid.
    p -= ip; // Fractional position within the cube.
    
    // Smoothing - for smooth interpolation. Comment it out to see the
    //p = p*p*p*(p*(p*6. - 15.) + 10.); // Quintic smoothing. Slower, but derivaties are smooth too.
    //p = p*p*(3. - 2.*p); // Cubic smoothing. 
    //p = mix(p, smoothstep(0., 1., p), .5);
    //vec3 w = p*p*p; p = ( 7. + (p - 7.)*w)*p;	// Super smooth, but less practical.
    //p = .5 - .5*cos(p*3.14159); // Cosinusoidal smoothing.
    // No smoothing. Gives a blocky appearance.
    
     // Smoothly interpolating between the eight verticies of the cube. Due to the shared verticies between
    // cubes, the result is blending of random values throughout the 3D space.
    vec4 c = mix(mix(mix(tMapSm(tx, ip + e.xxx), tMapSm(tx, ip + e.yxx), p.x),
                     mix(tMapSm(tx, ip + e.xyx), tMapSm(tx, ip + e.yyx), p.x), p.y),
                 mix(mix(tMapSm(tx, ip + e.xxy), tMapSm(tx, ip + e.yxy), p.x),
                     mix(tMapSm(tx, ip + e.xyy), tMapSm(tx, ip + e.yyy), p.x), p.y), p.z);
/*   
    // For fun, I tried a straight up average. It didn't work. :)
    vec4 c = (tMapSm(tx, ip + e.xxx) + tMapSm(tx, ip + e.yxx) +
              tMapSm(tx, ip + e.xyx) + tMapSm(tx, ip + e.yyx) +
              tMapSm(tx, ip + e.xxy) + tMapSm(tx, ip + e.yxy) +
              tMapSm(tx, ip + e.xyy) + tMapSm(tx, ip + e.yyy))/8.;
*/ 
    
    return c;

}



// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}


// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

/*
// IQ's exponential-based smooth maximum function. Unlike the polynomial-based
// smooth maximum, this one is associative and commutative.
float smaxExp(float a, float b, float k){

    float res = exp(k*a) + exp(k*b);
    return log(res)/k;
}
*/

// IQ's exponential-based smooth minimum function. Unlike the polynomial-based
// smooth minimum, this one is associative and commutative.
float sminExp(float a, float b, float k){

    float res = exp(-k*a) + exp(-k*b);
    return -log(res)/k;
}

// With the spare cycles, I thought I'd splash out and use Dave's more reliable hash function. :)
//
// Dave's hash function. More reliable with large values, but will still eventually break down.
//
// Hash without Sine.
// Creative Commons Attribution-ShareAlike 4.0 International Public License.
// Created by David Hoskins.
// vec3 to vec3.
vec3 hash33G(vec3 p){

    
    p = mod(p, gSc);
	p = fract(p * vec3(.10313, .10307, .09731));
    p += dot(p, p.yxz + 19.1937);
    p = fract((p.xxy + p.yxx)*p.zyx)*2. - 1.;
    return p;
   
    /*
    // Note the "mod" call. Slower, but ensures accuracy with large time values.
    mat2  m = rot2(mod(iTime, 6.2831853));	
	p.xy = m * p.xy;//rotate gradient vector
    p.yz = m * p.yz;//rotate gradient vector
    //p.zx = m * p.zx;//rotate gradient vector
	return p;
    */

}

// Cheap vec3 to vec3 hash. I wrote this one. It's much faster than others, but I don't trust
// it over large values.
vec3 hash33(vec3 p){ 
   
    
    p = mod(p, gSc);
    //float n = sin(dot(p, vec3(7, 157, 113)));    
    //p = fract(vec3(2097152, 262144, 32768)*n)*2. - 1.; 
    
    //mat2  m = rot2(iTime);//in general use 3d rotation
	//p.xy = m * p.xy;//rotate gradient vector
    ////p.yz = m * p.yz;//rotate gradient vector
    ////p.zx = m * p.zx;//rotate gradient vector
	//return p;
    
    float n = sin(dot(p, vec3(113, 57, 27)));    
    return fract(vec3(2097152, 262144, 32768)*n)*2. - 1.;  

    
    //float n = sin(dot(p, vec3(7, 157, 113)));    
    //p = fract(vec3(2097152, 262144, 32768)*n); 
    //return sin(p*6.2831853 + iTime)*.5; 
}


// hash based 3d value noise
vec4 hash41(vec4 p){
    return fract(sin(p)*43758.5453);
}

// Compact, self-contained version of IQ's 3D value noise function.
float n3D(vec3 p){
    
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(hash41(h), hash41(h + s.x), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

// Gradient noise fBm.
float fBm2(in vec3 p){
    
    return n3D(p)*.57 + n3D(p*2.)*.28 + n3D(p*4.)*.15;
}


// Gradient noise, or Perlin noise. Break space into cubes, attach random 3D vectors to each of the eight 
// verticies, then smoothly interpolate between them. It's that simple. With the exception of some simple
// changes and some commentary addition, this is basically IQ's implementation.
// 
float gradN3D(in vec3 p){
   
    // Utilility bector.
    const vec2 e = vec2(0, 1);
    
    // Set up the cubic grid.
    // Integer value - unique to each cube, and used as an ID to generate random vectors for the
    // cube vertiies. Note that vertices shared among the cubes have the save random vectors attributed
    // to them.
    vec3 ip = floor(p); 
    
    p -= ip; // Fractional position within the cube.

    // Smoothing - for smooth interpolation. Comment it out to see the
    //vec3 w = p*p*p*(p*(p*6. - 15.) + 10.); // Quintic smoothing. Slower, but derivaties are smooth too.
    vec3 w = p*p*(3. - 2.*p); // Cubic smoothing. 
    //vec3 w = p*p*p; w = (7. + (w - 7.) * p) * w;	// Super smooth, but less practical.
    //vec3 w = .5 - .5*cos(p*3.14159); // Cosinusoidal smoothing.
    //vec3 w = p; // No smoothing. Gives a blocky appearance. Can look cool under the right conditions.
    
    // Smoothly interpolating between the eight verticies of the cube. Due to the shared verticies between
    // cubes, the result is blending of random values throughout the 3D space.
    float c = mix(mix(mix(dot(hash33G(ip + e.xxx), p - e.xxx), dot(hash33G(ip + e.yxx), p - e.yxx), w.x),
                      mix(dot(hash33G(ip + e.xyx), p - e.xyx), dot(hash33G(ip + e.yyx), p - e.yyx), w.x), w.y),
                  mix(mix(dot(hash33G(ip + e.xxy), p - e.xxy), dot(hash33G(ip + e.yxy), p - e.yxy), w.x),
                      mix(dot(hash33G(ip + e.xyy), p - e.xyy), dot(hash33G(ip + e.yyy), p - e.yyy), w.x), w.y), w.z);
    
    // Taking the final result, and putting it into the zero to one range.
    return c*.5 + .5; // Range: [0, 1].

}

// Gradient noise fBm.
float fBm(in vec3 p){
    
    return gradN3D(p)*.57 + gradN3D(p*2.)*.28 + gradN3D(p*4.)*.15;
}




// This is a variation on a regular 2-pass Voronoi traversal that produces a Voronoi
// pattern based on the interior cell point to the nearest cell edge (as opposed
// to the nearest offset point). It's a slight reworking of Tomkh's example, which
// in turn, is based on IQ's original example. The links are below:
//
// On a side note, I have no idea whether a faster solution is possible, but when I
// have time, I'm going to try to find one anyway.
//
// Voronoi distances - iq
// https://www.shadertoy.com/view/ldl3W8
//
// Here's IQ's well written article that describes the process in more detail.
// https://iquilezles.org/articles/voronoilines
//
// Faster Voronoi Edge Distance - tomkh
// https://www.shadertoy.com/view/llG3zy
//
//
vec3 cellID;
//
vec3 Voronoi(in vec3 p, in vec3 rd){
    
    // One of Tomkh's snippets that includes a wrap to deal with
    // larger numbers, which is pretty cool.

 
    vec3 n = floor(p);
    p -= n + .5;
 
    
    // Storage for all sixteen hash values. The same set of hash values are
    // reused in the second pass, and since they're reasonably expensive to
    // calculate, I figured I'd save them from resuse. However, I could be
    // violating some kind of GPU architecture rule, so I might be making 
    // things worse... If anyone knows for sure, feel free to let me know.
    //
    // I've been informed that saving to an array of vectors is worse.
    //vec2 svO[3];
    
    // Individual Voronoi cell ID. Used for coloring, materials, etc.
    cellID = vec3(0); // Redundant initialization, but I've done it anyway.

    // As IQ has commented, this is a regular Voronoi pass, so it should be
    // pretty self explanatory.
    //
    // First pass: Regular Voronoi.
	vec3 mo, o;
    
    // Minimum distance, "smooth" distance to the nearest cell edge, regular
    // distance to the nearest cell edge, and a line distance place holder.
    float md = 8., lMd = 8., lMd2 = 8., lnDist, d;
    
    for( int k=-2; k<=2; k++ ){
    for( int j=-2; j<=2; j++ ){
    for( int i=-2; i<=2; i++ ){
    
        o = vec3(i, j, k);
        o += hash33(n + o) - p;
        // Saving the hash values for reuse in the next pass. I don't know for sure,
        // but I've been informed that it's faster to recalculate the had values in
        // the following pass.
        //svO[j*3 + i] = o; 
  
        // Regular squared cell point to nearest node point.
        d = dot(o, o); 

        if( d<md ){
            
            md = d;  // Update the minimum distance.
            // Keep note of the position of the nearest cell point - with respect
            // to "p," of course. It will be used in the second pass.
            mo = o; 
            cellID = vec3(i, j, k) + n; // Record the cell ID also.
        }
       
    }
    }
    }

    // Second pass: Distance to closest border edge. The closest edge will be one of the edges of
    // the cell containing the closest cell point, so you need to check all surrounding edges of 
    // that cell, hence the second pass... It'd be nice if there were a faster way.
    for( int k=-3; k<=3; k++ ){
    for( int j=-3; j<=3; j++ ){
    for( int i=-3; i<=3; i++ ){
        
        // I've been informed that it's faster to recalculate the hash values, rather than 
        // access an array of saved values.
        o = vec3(i, j, k);
        o += hash33(n + o) - p;
        // I went through the trouble to save all sixteen expensive hash values in the first 
        // pass in the hope that it'd speed thing up, but due to the evolving nature of 
        // modern architecture that likes everything to be declared locally, I might be making 
        // things worse. Who knows? I miss the times when lookup tables were a good thing. :)
        // 
        //o = svO[j*3 + i];
        
        // Skip the same cell... I found that out the hard way. :D
        if( dot(o - mo, o - mo)>.00001 ){ 
            
            // This tiny line is the crux of the whole example, believe it or not. Basically, it's
            // a bit of simple trigonometry to determine the distance from the cell point to the
            // cell border line. See IQ's article for a visual representation.
            lnDist = dot(0.5*(o + mo), normalize(o - mo));
            
            // Abje's addition. Border distance using a smooth minimum. Insightful, and simple.
            //
            // On a side note, IQ reminded me that the order in which the polynomial-based smooth
            // minimum is applied effects the result. However, the exponentional-based smooth
            // minimum is associative and commutative, so is more correct. In this particular case, 
            // the effects appear to be negligible, so I'm sticking with the cheaper polynomial-based 
            // smooth minimum, but it's something you should keep in mind. By the way, feel free to 
            // uncomment the exponential one and try it out to see if you notice a difference.
            //
            // // Polynomial-based smooth minimum.
            //lMd = smin2(lMd, lnDist, lnDist*.75); //lnDist*.75
            //
            // Exponential-based smooth minimum. By the way, this is here to provide a visual reference 
            // only, and is definitely not the most efficient way to apply it. To see the minor
            // adjustments necessary, refer to Tomkh's example here: Rounded Voronoi Edges Analysis - 
            // https://www.shadertoy.com/view/MdSfzD
            lMd = sminExp(lMd, lnDist, 10.); 
            
            // Minimum regular straight-edged border distance. If you only used this distance,
            // the web lattice would have sharp edges.
            lMd2 = min(lMd2, lnDist);
        }

    }
    }
    }

    // Return the smoothed and unsmoothed distance. I think they need capping at zero... but 
    // I'm not positive.
    return max(vec3(lMd, lMd2, md), 0.);
}





/*
// 3D blurring function. Not used here, but it will be in later examples.
vec4 BlurTri(samplerCube iCh, vec3 p, int dim){
    
    // Initiate the color.
    vec4 col = vec4(0);
    
    p *= 100.;
    //p = floor(p);
    
    
    int hDim = dim/2;
    
    float tot = 0.;
    // There's a million boring ways to apply a kernal matrix to a pixel, and this 
    // is one of them. :)
    for (int k=0; k<dim; k++){
        for (int j=0; j<dim; j++){
            for (int i=0; i<dim; i++){ 

               // Triangle blur, of sorts.
               float ijk = float(hDim - abs(hDim - i) + 1)*float(hDim - abs(hDim - j) + 1)*
                   		  float(hDim - abs(hDim - k) + 1);
               float d = length(vec3(hDim - i, hDim - j, hDim - k));
               //if(d>float(hDim)*1.2) continue;
                 
               //ijk = length(vec3(hDim)) - d;
               float mDim = pow(float(hDim + 1), 3.);
               //ijk = smoothstep(0., 1., ijk/mDim)*mDim;//sqrt(ij);
               col += ijk*tMapSm(iCh, p + vec3(i - hDim, j - hDim, k - hDim));
               tot += ijk;
            }
        }
    }
    
    return col/tot; // /81.
    
}
*/

 
