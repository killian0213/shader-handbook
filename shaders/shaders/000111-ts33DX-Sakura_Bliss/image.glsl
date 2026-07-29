// Image (image) — Sakura Bliss by PixelPhil
// https://www.shadertoy.com/view/ts33DX

//
// Sakura Bliss by Philippe Desgranges
// Email: Philippe.desgranges@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//

//
// I recently stumbled upon Martijn Steinrucken aka BigWings Youtube channel
// his work amazed me and inspired me to take a leap and try it out for myself.
//
// This is my first ShaderToy entry.
//

#define S(a,b,c) smoothstep(a,b,c)
#define sat(a) clamp(a,0.0,1.0)


// Borrowed from BigWIngs
vec4 N14(float t) {
	return fract(sin(t*vec4(123., 104., 145., 24.))*vec4(657., 345., 879., 154.));
}


// Computes the RGB and alpha of a single flower in its own UV space
vec4 sakura(vec2 uv, vec2 id, float blur)
{
    float time = iTime + 45.0; //time is offset to avoid the flowers to be aligned at start
    
    vec4 rnd = N14(mod(id.x, 500.0) * 5.4 + mod(id.y, 500.0) * 13.67); //get 4 random numbersper flower
    
    // Offset the flower form the center in a random Lissajous pattern
    uv *= mix(0.75, 1.3, rnd.y);            
    uv.x += sin(time * rnd.z * 0.3) * 0.6;
    uv.y += sin(time * rnd.w * 0.45) * 0.4;
    
    
    // Computes the angle of the flower with a random rotation speed
    float angle = atan(uv.y, uv.x) + rnd.x * 421.47 + iTime * mix(-0.6, 0.6, rnd.x);
    
    
    // euclidean distance to the center of the flower
    float dist = length(uv);
   
  	// Flower shaped distance function form the center
    float petal = 1.0 - abs(sin(angle * 2.5));
    float sqPetal = petal * petal;
    petal = mix(petal, sqPetal, 0.7);
    float petal2 = 1.0 - abs(sin(angle * 2.5 + 1.5));
    petal += petal2 * 0.2;
    
    float sakuraDist = dist + petal * 0.25;
    
   
    // Compute a blurry shadow mask.
    float shadowblur = 0.3;
    float shadow = S(0.5 + shadowblur, 0.5 - shadowblur, sakuraDist) * 0.4;
    
    //Computes the sharper mask of the flower
    float sakuraMask = S(0.5 + blur, 0.5 - blur, sakuraDist);
    
    // The flower has a pink hue and is lighter in the center
    vec3 sakuraCol = vec3(1.0, 0.6, 0.7);
    sakuraCol += (0.5 -  dist) * 0.2;
    
	// Computes the border mask of the flower
    vec3 outlineCol = vec3(1.0, 0.3, 0.3);
    float outlineMask = S(0.5 - blur, 0.5, sakuraDist + 0.045);
    
    // Defines a tiling polarspace for the pistil pattern
    float polarSpace = angle * 1.9098 + 0.5;
    float polarPistil = fract(polarSpace) - 0.5; // 12 / (2 * pi)
    
    // Round dot in the center
    outlineMask += S(0.035 + blur, 0.035 - blur, dist);
    
    float petalBlur = blur * 2.0;
    float pistilMask = S(0.12 + blur, 0.12, dist) * S(0.05, 0.05 + blur , dist);
    
    // Compute the pistil 'bars' in polar space
    float barW = 0.2 - dist * 0.7;
    float pistilBar = S(-barW, -barW + petalBlur, polarPistil) * S(barW + petalBlur, barW, polarPistil);
    
    // Compute the little dots in polar space
    float pistilDotLen = length(vec2(polarPistil * 0.10, dist) - vec2(0, 0.16)) * 9.0;
    float pistilDot = S(0.1 + petalBlur, 0.1 - petalBlur, pistilDotLen);
    
    //combines the middle an border color
    outlineMask += pistilMask * pistilBar + pistilDot;
    sakuraCol = mix(sakuraCol, outlineCol, sat(outlineMask) * 0.5);
    
    //sets the background to the shadow color
    sakuraCol = mix(vec3(0.2, 0.2, 0.8) * shadow, sakuraCol, sakuraMask);
    
    //incorporates the shadow mask into alpha channel
    sakuraMask = sat(sakuraMask + shadow);
    
	//returns the flower in pre-multiplied rgba
    return vec4(sakuraCol, sakuraMask);
}

// blends a pre-multiplied src onto a dst color (without alpha)
vec3 premulMix(vec4 src, vec3 dst)
{
    return dst.rgb * (1.0 - src.a) + src.rgb;
}

// blends a pre-multiplied src onto a dst color (with alpha)
vec4 premulMix(vec4 src, vec4 dst)
{
    vec4 res;
    res.rgb = premulMix(src, dst.rgb);
    res.a = 1.0 - (1.0 - src.a) * (1.0 - dst.a);
    return res;
}


// Computes a Layer of flowers
vec4 layer(vec2 uv, float blur)
{
    vec2 cellUV = fract(uv) - 0.5;
    vec2 cellId = floor(uv);
    
    vec4 accum = vec4(0.0);
    
    // the flowers can overlap on the 9 neighboring cells so we blend them all together on each cell
    for (float y = -1.0; y <= 1.0; y++)
    {
        for (float x = -1.0; x <= 1.0; x++)
        {
            vec2 offset = vec2(x, y); 
            vec4 sakura = sakura(cellUV - offset, cellId + offset, blur);
            accum = premulMix(sakura, accum);
        }
    }
    
 	return accum;
}




void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 nominalUV = fragCoord/iResolution.xy;
    
    vec2 uv = nominalUV - 0.5;
    uv.x *= iResolution.x / iResolution.y;

    // Scroll the UV with a cosine oscillation
    uv.y += iTime * 0.1;
    uv.x -= iTime * 0.03 + sin(iTime) * 0.1;
    
    uv *= 4.3;

    //Compute a BG gradient
    float screenY = nominalUV.y;
    vec3 col = mix(vec3(0.3, 0.3, 1.0), vec3(1.0, 1.0, 1.0), screenY);
    
    // Compute a tilt-shift-like blur factor
    float blur = abs(nominalUV.y - 0.5) * 2.0;
    blur *= blur * 0.15;
    
    // Computes several layers with various degrees of blur and scale
    vec4 layer1 = layer(uv, 0.015 + blur);
    vec4 layer2 = layer(uv * 1.5 + vec2(124.5, 89.30), 0.05 + blur);
    layer2.rgb *= mix(0.7, 0.95, screenY);
    vec4 layer3 = layer(uv * 2.3 + vec2(463.5, -987.30), 0.08 + blur);
    layer3.rgb *= mix(0.55, 0.85, screenY);
    
    // Blend it all together
	col = premulMix(layer3, col);
    col = premulMix(layer2, col);
	col = premulMix(layer1, col);
    
    // Adds some light at the to of the screen
    col += vec3(nominalUV.y * nominalUV.y) * 0.2;

 
    // Output to screen
    fragColor = vec4(col,1.0);
}