// Buffer B (buffer) — CURIOUS CRYSTAL by alro
// https://www.shadertoy.com/view/slccDX

// Create a Perlin texture atlas for interior shapes
// Store normal map in blue channel
// Runs only once in the first frame or when resolution changes
// Based on https://github.com/sebh/TileableVolumeNoise/blob/master/main.cpp

// The atlas is a 6*6 grid of 32*32 tiles with a single layer of halo cells around each tile. 

// TODO: Assumes a size of at least 204 * 204. Make it work with any reasonable resolution.


//-------------------------------- 3D --------------------------------

vec3 modulo(vec3 m, float n){
  return mod(mod(m, n) + n, n);
}

// 5th order polynomial interpolation
vec3 fade(vec3 t){
    return (t * t * t) * (t * (t * 6.0 - 15.0) + 10.0);
}

#define SIZE 4.0

// https://www.shadertoy.com/view/4djSRW
vec3 hash(vec3 p3){
    p3 = modulo(p3, SIZE);
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return 2.0 * fract((p3.xxy + p3.yxx) * p3.zyx) - 1.0;
}

float gradientNoise(vec3 p){

    vec3 i = floor(p);
    vec3 f = fract(p);
	
	vec3 u = fade(f);
    
    /*
    * For 1D, the gradient of slope g at vertex u has the form h(x) = g * (x - u), where u 
    * is an integer and g is in [-1, 1]. This is the equation for a line with slope g which 
    * intersects the x-axis at u.
    * For N dimensional noise, use dot product instead of multiplication, and do 
    * component-wise interpolation (for 3D, trilinear)
    */
    return mix( mix( mix( dot( hash(i + vec3(0.0,0.0,0.0)), f - vec3(0.0,0.0,0.0)), 
              dot( hash(i + vec3(1.0,0.0,0.0)), f - vec3(1.0,0.0,0.0)), u.x),
         mix( dot( hash(i + vec3(0.0,1.0,0.0)), f - vec3(0.0,1.0,0.0)), 
              dot( hash(i + vec3(1.0,1.0,0.0)), f - vec3(1.0,1.0,0.0)), u.x), u.y),
    mix( mix( dot( hash(i + vec3(0.0,0.0,1.0)), f - vec3(0.0,0.0,1.0)), 
              dot( hash(i + vec3(1.0,0.0,1.0)), f - vec3(1.0,0.0,1.0)), u.x),
         mix( dot( hash(i + vec3(0.0,1.0,1.0)), f - vec3(0.0,1.0,1.0)), 
              dot( hash(i + vec3(1.0,1.0,1.0)), f - vec3(1.0,1.0,1.0)), u.x), u.y), u.z );
}

float getPerlinNoise(vec3 pos, float frequency){

	//Compute the sum for each octave.
	float sum = 0.0;
	float weightSum = 0.0;
	float weight = 1.0;

	for(int oct = 0; oct < 4; oct++){

        vec3 p = pos * frequency;
        float val = 0.5 + 0.5 * gradientNoise(p);
        sum += val * weight;
        weightSum += weight;

        weight *= 0.5;
        frequency *= 2.0;
	}

	return saturate(sum / weightSum);
}

//-------------------------------- 2D --------------------------------

vec2 modulo(vec2 m, float n){
  return mod(mod(m, n) + n, n);
}

#define SIZE_2D 16.0

// https://www.shadertoy.com/view/4djSRW
vec2 hash(vec2 p){
    p = modulo(p, float(SIZE_2D));
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return 2.0 * fract((p3.xx+p3.yz)*p3.zy) - 1.0;
}

// 5th order polynomial interpolation
vec2 fade(vec2 t){
    return (t * t * t) * (t * (t * 6.0 - 15.0) + 10.0);
}

float gradientNoise( in vec2 p ){

    vec2 i = floor( p );
    vec2 f = fract( p );
	
	vec2 u = fade(f);
    
    // For 1D, the gradient of slope g at vertex u has the form h(x) = g * (x - u), where u is an integer and g is in [-1, 1].
    // This is the equation for a line with slope g which intersects the x-axis at u.
    // For N dimensional noise, use dot product instead of multiplication, and do component-wise interpolation.
    // For 2D, bilinear. For 3D, trilinear.
    return  mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                      dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                 mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                      dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

float getPerlinNoise(vec2 pos, float frequency){

	//Compute the sum for each octave.
	float sum = 0.0;
	float weightSum = 0.0;
	float weight = 1.0;

	for(int oct = 0; oct < 4; oct++){

        vec2 p = pos * frequency;
        float val = 0.5 + 0.5 * gradientNoise(p);
        sum += val * weight;
        weightSum += weight;

        weight *= 0.5;
        frequency *= 3.0;
	}

	return saturate(sum / weightSum);
}

//--------------------------------------------------------------------

//Return the 3D coordinate corresponding to the 2D atlas uv coordinate.
vec3 get3Dfrom2D(vec2 uv, float tileRows){
    vec2 tile = floor(uv);
    float z = floor(tileRows * tile.y + tile.x);
    return vec3(fract(uv), z);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    bool resolutionChanged = texelFetch(iChannel2, ivec2(0.5, 2.5), 0).r > 0.0;
    
    if(iFrame == 0 || iFrame == 260 || texelFetch(iChannel1, ivec2(0), 0).b == 0.0 
                  || resolutionChanged){
        vec3 col = vec3(0);
        //32 with 1 pixel on either side.
        float tileSize = 34.0;
        float padWidth = 1.0;
        float coreSize = tileSize - 2.0 * padWidth;
        float tileRows = 6.0;
        float tileCount = tileRows * tileRows;
        vec2 tile = floor((fragCoord.xy - 0.5) / tileSize);

        bool padCell = false;
        if(mod(fragCoord.x, tileSize) == 0.5 || mod(fragCoord.x, tileSize) == tileSize - 0.5){
            padCell = true;
        }
        if(mod(fragCoord.y, tileSize) == 0.5 || mod(fragCoord.y, tileSize) == tileSize - 0.5){
            padCell = true;
        }

        bool startPadX = false;
        bool endPadX = false;
        bool startPadY = false;
        bool endPadY = false;

        if(fragCoord.x == tile.x * tileSize + 0.5){
            startPadX = true;
        }
        if(fragCoord.y == tile.y * tileSize + 0.5){
            startPadY = true;
        }
        if(fragCoord.x == (tile.x + 1.0) * tileSize - 0.5){
            endPadX = true;
        }
        if(fragCoord.y == (tile.y + 1.0) * tileSize - 0.5){
            endPadY = true;
        }

        vec2 padding = vec2(2.0 * padWidth) * tile;
        vec2 pixel;
        vec2 uv;
        
        if(!padCell){
            pixel = fragCoord.xy - padWidth - padding;
            uv = vec2(pixel.xy/coreSize);
        }else{
            pixel = fragCoord.xy - padWidth - padding;
            if(startPadX){
                pixel.x += coreSize;	
            }
            if(startPadY){
                pixel.y += coreSize;	
            }
            if(endPadX){
                pixel.x -= coreSize;	
            }
            if(endPadY){
                pixel.y -= coreSize;	
            }
            uv = vec2(pixel.xy/coreSize);
        }
        
        vec3 p_ = get3Dfrom2D(uv, tileRows);
        vec3 p = p_;
        p.z /= (tileRows*tileRows);

        // Get Perlin noise for level l
        col.r = getPerlinNoise(p, SIZE);
        p_ = mod(p_ + 1.0, tileRows * tileRows);
        p = p_;
        p.z /= (tileRows*tileRows);

        // Get Perlin noise for level l+1
        col.g = getPerlinNoise(p, SIZE);

        // Unused cells
        if(gl_FragCoord.x > tileRows * tileSize || gl_FragCoord.y > tileRows * tileSize){
            col = vec3(0);
        }
        
        // 2D noise texture for normal mapping
        uv = fragCoord/iResolution.xy;
        col.b = 2.0 * getPerlinNoise(uv, SIZE_2D) - 1.0;
        col.b *= 0.5 + 2.0*pow(abs(2.0*length(texture(iChannel1, uv).rgb)-1.0), 4.0);
        
    	fragColor = vec4(col, 1.0);
        
    }else{
        
    	fragColor = texelFetch(iChannel0, ivec2(fragCoord - 0.5), 0).rgba;
        
    }

}