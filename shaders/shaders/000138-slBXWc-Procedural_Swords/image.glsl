// Image (image) — Procedural Swords by SnoopethDuckDuck
// https://www.shadertoy.com/view/slBXWc


// gem interior colors
vec3 darkMap( int index,  float v ) {
    vec3[5] arr;
    
    if (index == 0)      // blue 
        arr = vec3[] ( vec3(95,205,228), vec3(99,155,255), vec3(91,110,225), vec3(48,96,130),vec3(63,63,116));
    else if (index == 1) // red 
        arr = vec3[] ( vec3(238,195,154),vec3(215,123,186),vec3(217,87,99),  vec3(172,50,50),vec3(69,40,60));
    else if (index == 2) // green 
        arr = vec3[] ( vec3(153,229,80), vec3(106,190,48), vec3(55,148,110), vec3(48,96,130),vec3(63,63,116));
    else if (index == 3) // brown
        arr = vec3[] ( vec3(217,160,102),vec3(180,123,80), vec3(143,86.,59), vec3(102,57,49),vec3(69,40,60));
    else if (index == 4) // grey
        arr = vec3[] ( vec3(155,173,183),vec3(132,126,135),vec3(105,106,106),vec3(89,86,82), vec3(50,60,57));
    else if (index == 5) // pink
        arr = vec3[] ( vec3(215,123,186),vec3(217,87,99),  vec3(118,66,138), vec3(63,63,116),vec3(50,60,57));
   
   return arr[ min(5, int(v)) ] / 255.;
}

// gem interior outline colors
vec3 lightMap( int index, float v ) {
    vec3[5] arr;
    
    if (index == 0)      // blue
        arr = vec3[] ( vec3(255),vec3(203,219,252),vec3(95,205,228), vec3(99,155,255), vec3(91,110,225));
    else if (index == 1) // gold 
        arr = vec3[] ( vec3(255),vec3(251,242,54), vec3(255,182,45), vec3(223,113,38), vec3(172,50,50));
    else if (index == 2) // green
        arr = vec3[] ( vec3(255),vec3(203,219,252),vec3(153,229,80), vec3(106,190,48), vec3(55,148,110));
    else if (index == 3) // brown 
        arr = vec3[] ( vec3(255),vec3(238,195,154),vec3(217,160,102),vec3(180,123,80), vec3(143,86,59));
    else if (index == 4) // grey
        arr = vec3[] ( vec3(255),vec3(203,219,252),vec3(155,173,183),vec3(132,126,135),vec3(105,106,106));
    else if (index == 5) // pink
        arr = vec3[] ( vec3(255),vec3(238,195,154),vec3(215,123,186),vec3(217,87,99),  vec3(118,66,138));
    
    return arr[ min(5, int(v)) ] / 255.;
}

// handle colors
vec3 handleMap ( int index, float v) {
    vec3[6] arr;
    if (index == 0)      // blue
        arr = vec3[] ( vec3(63,63,116),vec3(48,96,130),vec3(91,110,225),vec3(95,205,228),vec3(203,219,252),vec3(255));
    else if (index == 1) // gold
        arr = vec3[] ( vec3(69,40,60),vec3(172,50,50),vec3(223,113,38),vec3(255,182,45),vec3(251,242,54),vec3(255));
    else if (index == 2) // green
        arr = vec3[] ( vec3(63,63,116),vec3(48,96,130),vec3(55,148,110),vec3(106,190,48),vec3(153,229,80),vec3(203,219,252));
    else if (index == 3) // brown
        arr = vec3[] ( vec3(69,40,60),vec3(102,57,49),vec3(143,86,59),vec3(180,123,80),vec3(217,160,102),vec3(238,195,154));
    else if (index == 4) // grey
        arr = vec3[] ( vec3(50,60,57),vec3(118,66,138),vec3(105,106,106),vec3(155,173,183),vec3(203,219,252),vec3(255));
    else if (index == 5) // pink
        arr = vec3[] ( vec3(50,60,57),vec3(63,63,116),vec3(118,66,138),vec3(217,87,99),vec3(215,123,186),vec3(238,195,154));
   return arr[ min(5, int(5. * v)) ] / 255.;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    setDimGem(iFrame);
    setDimHandle(iFrame);
    
    float h = dimGem.y + 0.5 * dimHandle.y;
        
    float sf = 1.2 * (2. * dimGem.y + dimHandle.y) / iResolution.y; //2.
    vec2 osc = vec2(0., sf * (24. * cos(iTime) + 8.));
    
    // gem coord
    vec2 coord = ceil(sf * fragCoord + osc + vec2(dimGem.x, -dimHandle.y)
               - sf * 0.5 * iResolution.xy
               + vec2(0.,h)  );

    // handle coord
    vec2 coord2 = ceil( sf * fragCoord + osc + 0.5 * vec2(dimHandle.x, -4.)
                - sf * 0.5 * iResolution.xy       
                + vec2(0.,h) );
                
    // gem color
    vec3 col = texelFetch(iChannel0, ivec2(coord), 0).rgb;
    // handle shape
    float B = texelFetch(iChannel1, ivec2(coord2), 0).x;
    // handle noise
    float C = texelFetch(iChannel2, ivec2(coord2), 0).x;
    
    // index for handle, gem interior outline
    int index = randIndex(iFrame, 5. + 1., 0.);
    
    // index for gem interior
    int index2 = randIndex(iFrame, 5. + 1., floor(iDate[3] / float(reset)) - 100.);
   
    // color gem
    if ( col.r == 1. )
        col = vec3(34,32,52) / 255.;
    else if ( col.r == 0. )
        col = vec3(0.);
    else if (col.g > 0.)
        col = lightMap(index, col.g - 1.); 
    else if (col.b > 0.)
        col = darkMap(index2, col.b - 1.); 
        
    vec3 col2;
    float t = 100. * C;
    
    // color handle
    if (B == 1.) {
    
        // cos with high frequency t generates linework
        float v = 0.5 * (1. - cos(pi * t));  
    
        // shade top lighter, bottom darker
        v = min(1., v * (0.6 + 0.9 * coord2.y / dimHandle.y));

        // shade left side darker
        if (coord2.x <= 0.5 * dimHandle.x - 1.)
            v = max(0., v - 2. / 6.);
        
        col2 = handleMap(index, v);
    }
    
    // background
    else if (B == 0.) {
        vec2 uv = fragCoord / iResolution.y; 
        uv = mod(1.5 * uv + vec2(0.05 * iTime), 1.);
        if ((uv.x > 0.5 && uv.y > 0.5) || (uv.x < 0.5 && uv.y < 0.5))
            col2 = vec3(143,86,59) / 255.;
        else
            col2 = vec3(102,57,49) / 255.;
    } 
    
    // outline of handle
    else
        col2 = vec3(34, 32, 52) / 255.;
        
    if (col.x == 0.)
        fragColor = vec4(col2,1.);
    else 
        fragColor = vec4(col, 1.);
}
