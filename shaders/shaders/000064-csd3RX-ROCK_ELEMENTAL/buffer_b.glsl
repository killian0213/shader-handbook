// Buffer B (buffer) — ROCK ELEMENTAL by alro
// https://www.shadertoy.com/view/csd3RX

/*
    Rock material using tiled splatting and noise layering
    
    Inspired by:
    https://www.shadertoy.com/view/XdcfDf
    https://www.shadertoy.com/view/ls3fzj
    https://www.youtube.com/watch?v=kh3aAHKsjqY
    
    We want to create a height map that looks like a realistc rock formation.
    This raises a deceptively simple question - what do rocks look like?
    This is impossible to answer as there are many different kinds of rock. One description
    is perhaps that a rock's look is mostly decided by its shape and roughness. Rocks can also
    exhibit high frequency colour variation but the same is true for sand etc. However, when 
    shaped in an uncommon way, rock can cease to look like rock. For extreme examples consider
    marble sculptures and the walls of Antelope Canyon. 
    
    Let's take the stereotypical rock to look like rough granite or limestone. The structure
    is a mixture of different crystalline materials. When the surface is damaged, whole chips
    are ejected and other regions remain sticking out. This creates a varying landscape of 
    dips, furrows and peaks. The borders of these areas are abrupt, reflecting the scale
    of the material heterogeneity. The surface can also be affected by water erosion, ice 
    expansion and biological processes. This leads to deeper cracks and fractures.
    
    We start by creating a field of regular polygon height maps (triangles in this shader). 
    These are rotated, scaled, stretched and smudged to introduce randomness. The field is
    then carved with slashes and high-frequency dips and raises from a stepped gradient
    noise field. The sharpness of the cuts and peaks controls how granular the material will 
    look with sharper cuts looking more rocky and smoother variation resembling dirt or mud.
    
    We store the maximum height of the overlapping carved polygons but any way of mixing is 
    valid. The idea is that we end up with a height field that looks layered and randomly 
    varied. In the next pass we layer the texture multiple times like an FBM. We also detect
    how much of a texel is surrounded by higher regions. This information is used for ambient
    occlusion and ridge highlighting when we shade the material. Using simple height based
    colouring and roughness calculations leads to a convincing rock look even with a simple
    greyscale gradient.
    
    All of the above lacks any real citation but the target for a good rock look seems to be
    a multi-frequency layered height field of irregular sharp variations.

    
*/

mat2 rotate(float angle){
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

//https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p){
	vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 modulo(vec2 m, float n){
  return mod(mod(m, n) + n, n);
}

vec2 hash(vec2 p, float m){
    p = modulo(p, m);
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return 2.0 * fract((p3.xx+p3.yz)*p3.zy) - 1.0;
}

// 5th order polynomial interpolation
vec2 fade(vec2 t){
    return (t * t * t) * (t * (t * 6.0 - 15.0) + 10.0);
}

float gradientNoise(vec2 p, float m){

    vec2 i = floor(p);
    vec2 f = fract(p);
	
	vec2 u = fade(f);
    
    /*
        For 1D, the gradient of slope g at vertex u has the form h(x) = g * (x - u), 
        where u is an integer and g is in [-1, 1].
        This is the equation for a line with slope g which intersects the x-axis at u.
        For N dimensional noise, use dot product instead of multiplication, and do 
        component-wise interpolation. For 2D, bilinear. For 3D, trilinear.
    */
    return  mix( mix( dot( hash( i + vec2(0.0,0.0), m ), f - vec2(0.0,0.0) ), 
                      dot( hash( i + vec2(1.0,0.0), m ), f - vec2(1.0,0.0) ), u.x),
                 mix( dot( hash( i + vec2(0.0,1.0), m ), f - vec2(0.0,1.0) ), 
                      dot( hash( i + vec2(1.0,1.0), m ), f - vec2(1.0,1.0) ), u.x), u.y);
}

vec2 getGradient(vec2 uv, float scale){
    const float eps = 1e-1;
    return (vec2(gradientNoise(uv + vec2(-eps, 0.0), scale) - 
                 gradientNoise(uv + vec2(eps, 0.0), scale),
                 gradientNoise(uv + vec2(0.0, -eps), scale) - 
                 gradientNoise(uv + vec2(0.0, eps), scale)));
}

float fbm(vec2 pos, float scale, int N){
    float res = 0.0;
    float freq = 1.0;
    float amp = 1.0;
    float weight = 0.0;
    
    for(int i = 0; i < N; i++){
        res += gradientNoise(freq*pos, scale) * amp;
        weight += amp;
        freq *= 2.0;
        amp *= 0.75;
    }
    return res/weight;
}

// https://www.shadertoy.com/view/7tSXzt
// Signed distance to a regular n-gon
float sdNGon(vec2 p, float r ){
    float an = 6.2831853/float(3); // <---- Side count
    float he = r*tan(0.5*an);
    
    p = -p.yx;
    float bn = an*floor((atan(p.y,p.x)+0.5*an)/an);
    vec2  cs = vec2(cos(bn),sin(bn));
    p = mat2(cs.x,-cs.y,cs.y,cs.x)*p;

    return length(p-vec2(r,clamp(p.y,-he,he)))*sign(p.x-r);
}

// Normalised internal distance of a polygon with radius 3
float getHeight(vec2 uv){
    return -sdNGon(uv, 3.0) / 3.0;
}

vec3 getHeightFromTexture(vec2 uv){
            vec3 h = vec3(0);
            float w = 1.0;
            float sum = 0.0;
            for(float i = float(ZERO); i < 3.0; i++){
                // This should not be textureLod() but Windows does aggressive prefetching
                // which means that we pay the texture read cost every frame, even when we 
                // do not enter this function. 
                // Using a variable LOD stops the compiler from guessing wrong.
                h += w * textureLod(iChannel0, pow(2.0, i) * uv, float(ZERO)).rgb;
                sum += w;
                w *= 0.5;
            }
            
            return h / sum;
}

// Get something like an occlusion map by finding how much of a texture point
// is surrounded by higher parts.
float getAO(vec2 uv){
    
    float h = getHeightFromTexture(uv).r;
    
    float del = 0.1;
    float height = 0.0;
    float eps = 3e-3;
    float count = 0.0;
    float iterations = 0.0;
    for(float i = float(ZERO); i < TWO_PI; i += del){
        float hh = getHeightFromTexture(uv + eps * vec2(cos(i), sin(i))).r;
        if(hh > h){
            count++;
        }
        iterations++;
    }
    count /= iterations;
    
    return 1.0 - count;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    bool needsSecondPass = texelFetch(iChannel0, ivec2(0.5, 0.5), 0).r > 0.0;
    bool resolutionChanged = texelFetch(iChannel1, ivec2(0.5, 2.5), 0).r > 0.0;

    if(iFrame == 0 || resolutionChanged){

        float scale = 8.0;

        float h = -1e5;
        float noiseScale = 3.0;

        // Work in cells and consider surrounding ones as we shift shapes around randomly.
        for(float i = -5.0; i <= 5.0; i += 1.0){
            for(float j = -5.0; j <= 5.0; j += 1.0){
                // The cell UV used for the polygon shapes
                vec2 uv = fragCoord/iResolution.xy;
                vec2 cell = mod(floor(uv * scale) - vec2(i, j), scale);
                uv = fract(uv * scale) + vec2(i, j);

                // Random offset based on cell
                uv -= hash12(cell);
                
                // Rotate based on cell
                mat2 m = rotate(TWO_PI * hash12(cell));
                uv = m * uv;

                // The UV used for noise based on the cell uv but not stretched or smudged
                vec2 noiseUV = noiseScale * uv;

                // Stretch shape in one direction
                uv.y *= mix(0.5, 2.0, hash12(cell));

                // Smudge base shape based on noise gradient
                vec2 grad = getGradient(noiseUV, 32.0);
                grad *= normalize(grad);
                uv += 0.25 * grad;
                // Offset some more for fun
                uv += 0.5;
                
                // Get polygon distance as height
                float newHeight = getHeight(uv);

                // Slashes
                newHeight -= 32.0 * pow(max(0.0, (gradientNoise(noiseUV * vec2(1.0, 0.05) +
                             0.1 * sin(vec2(2.0 * noiseUV.y, 0.0)), 1000.0))), 4.0);
                // Raised areas
                newHeight += 0.2 * smoothstep(0.1, 0.3, abs(fbm(0.35 * noiseUV, 1000.0, 4)));
                // Sunken areas
                newHeight -= 0.5 * smoothstep(0.1, 0.25, abs(fbm(0.25 * noiseUV, 1000.0, 4)));
                
                // Record larger value
                h = max(h, newHeight);
                
            }
        }
        
        // Remap values to be in [0-1]
        h = saturate(remap(h, 0.6, 1.0, 0.0, 1.0));
        
        // Output to screen
        fragColor = vec4(vec3(h), 0.0);
        
        // Green channel will hold simple noise texture for gold seams
        fragColor.g = 0.5+0.5*fbm(12.0*fragCoord/iResolution.xy, 12.0, 3);

        // Blue channnel will hold simple noise texture for colour variation
        fragColor.b = 0.5+0.5*fbm(16.0*fragCoord/iResolution.xy, 16.0, 3);
        
        // Call second pass
        if(ivec2(fragCoord.xy) == ivec2(0.5, 0.5)){
            fragColor.r = 1.0;
        }
        
    }else if(iFrame == 1 || needsSecondPass){
        vec2 uv = fragCoord/iResolution.xy;
        
        // Layer the results of the previous pass multiple times and find occlusion
        fragColor = vec4(getHeightFromTexture(uv), getAO(uv));
        
        // Adjust gold seam texture to be sharper
        fragColor.g = 2.0 * pow(fragColor.g, 2.0);
        
        // Do not call second pass again
        if(ivec2(fragCoord.xy) == ivec2(0.5, 0.5)){
            fragColor.r = 0.0;
        }
    }else{
        fragColor = texelFetch(iChannel0, ivec2(fragCoord.xy), 0);
    }
}