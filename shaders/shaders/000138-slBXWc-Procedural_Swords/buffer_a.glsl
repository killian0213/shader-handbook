// Buffer A (buffer) — Procedural Swords by SnoopethDuckDuck
// https://www.shadertoy.com/view/slBXWc

// top variants for the gem
float hexTop (int index, vec2 uv) {
    if (index == 0) // pointy
        return abs(uv.x) + abs(uv.y);
    if (index == 1) // right diag / 
        return abs(uv.x - (dimGem.x - 2.)) + abs(uv.y);
    if (index == 2) // left diag
        return abs(uv.x + (dimGem.x - 2.)) + abs(uv.y);
    if (index == 3) // square
        return uv.x; 
    if (index == 4) // square -> diag
        return uv.x + uv.y;
    if (index == 5) // diag -> square
        return -uv.x + uv.y;       
}


float hexagon (int index, vec2 uv, vec2 dim) {
    // rectangle shape
    float d = max(dim.y/dim.x * abs(uv.x), abs(uv.y));

    // (modified) diamond shape
    float d2 = uv.y > 0. ? hexTop(index, uv) 
                         : abs(uv.x) + abs(uv.y);

    // intersect both shapes
    return step(d, dim.y) * step(d2, dim.y);
}

// forms ---_-_ shape to color with
float stepHole (float v, float h) {
    return step(h,v ) + (step(h, v + 2.) - step(h, v + 1.));
}

// choose length of each ---_-_ segment, depending on gem height 
float chooseN(vec2 dimGem) {
    float h = 2. * dimGem.y;
    if (h <= 14.)
        return 2.;
    if (h <= 21.)
        return 3.;
    if (h <= 28.)
        return 4.;
    return 5.;
}

void mainImage( out vec4 fragColor, in vec2 coord )
{
    // I think it goes off last value for some reason (maybe update order)
    vec2 dimgem = setDimGem(iFrame); 
    
    vec2 uv = coord - dimGem;
    
    int index = randIndex(iFrame, 5. + 1., -31.5);
    
    // split channels by parts
    // r: outline, b: interior outline, g: interior
    vec3 col = vec3(hexagon(index, uv, dimGem) - 0.5 * hexagon(index, uv, dimGem - 1.),
                    hexagon(index, uv, dimGem - 1.) -  hexagon(index, uv, dimGem - 2.),
                    hexagon(index, uv, dimGem - 2.));
    
    // remove bottom outline so handle and gem don't overlap
    if (coord.y < 1.)
        col.r = 0.;
    
    // apply shades to interior outline + interior
    // ( repeatedly run stepHole to get ---_-_ pattern, overlay higher indexes
    //   min index is 1., and -step(dim.x, fragCoord.x) makes left side darker )
    vec2 shade = vec2(1.);
    float n = chooseN(dimGem);
    for (float i = 1.; i < n; i++) { 
        shade = max(shade, 
                    1. + (n-i) * stepHole(ceil(2. * dimGem.y / n) * i, coord.y)
                       - step(dimGem.x, coord.x));                  
    }
    
    // make the top bright (white outline wraps around to the left)
    if (coord.y > 2. * dimGem.y - 2.)
        shade = vec2(1.);
        
    // split the top interior to two shades (left and right)
    else if (coord.y > 2. * dimGem.y - 4.)
        shade = vec2(2.- step(dimGem.x, coord.x),1.);
    
    col.bg *= shade;

    fragColor = vec4(col, 1.);   
}