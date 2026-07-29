// Buffer A (buffer) — 2d spectral ray tracer by riouxld
// https://www.shadertoy.com/view/stSXzm

// ------------------------------------------------------------------------------ //
// Memory & keyboard management: Could be way simpler but I wanted to investigate //
//     how to keep global variable using buffers.                                 //
// ------------------------------------------------------------------------------ // 



// keyboard / mouse input
// ----------------------
bool isKeyPressed(int key)
{
	return texelFetch( iChannel3, ivec2(key, 0), 0 ).x != 0.0;
}

// mouse input
// ----------------------

bool isMousePressed()
{
	return iMouse.z > 0.0;
}


// main
// ----
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // pixelindices (0,width-1)x(0, height-1)
    ivec2 indices = ivec2(fragCoord);
    
    // uv texture coordinate (0,1)x(0,1)
    vec2 uv = (fragCoord)/iResolution.xy;
    
    // initial state (x reset time, yz light pos)
    if (iFrame == 0 ) {
         if (indices == reset_time_loc) {
             fragColor = vec4(0.);
         } else if (indices == light_pos_loc) {
             fragColor = vec4(vec2(0.3,0.35), vec2(0.0));
         } else {
             fragColor = vec4(0.);
         } 
         return;
    }
    
    
    // if reset simulation
    if (isKeyPressed(KEY_SPACE) ) {
         if (ACCUMULATE && indices == reset_time_loc) {
             fragColor = vec4(float(iFrame) , vec3(0.));
         } else {
             fragColor = texture(iChannel0, uv);
         }
         return;
    }
    
    
    // if light has moved
    if (isMousePressed() ) {
         if (ACCUMULATE && indices == reset_time_loc) {
             fragColor = vec4(float(iFrame), vec3(0.));
         } 
         else if (indices == light_pos_loc) {
             fragColor = vec4(iMouse.xy/iResolution.y, vec2(0.0));
         } else {
             fragColor = texture(iChannel0, uv);
         }
         return;
    }
    
    // Accumulate fluence with walking average
    fragColor = texture(iChannel0, uv);
}



/*
// initial state (x reset time, yz light pos)
if (iFrame == 0 ) {
     if (indices.x == 0 && indices.y == 0) {
         fragColor = vec4(0.);
     } else if (indices.x == 0 && indices.y == 1) {
         fragColor = vec4(vec2(0.15,0.5), vec2(0.0));
     }
     fragColor = vec4(0., vec2(0.15,0.5), 0.0);
     return;
}


// if reset simulation
if (isKeyPressed(KEY_SPACE) ) {
     fragColor = vec4(float(iFrame), texture(iChannel0, uv).yz, 0.0);
     return;
}


// if light has moved
if (isMousePressed() ) {
     fragColor = vec4(float(iFrame), iMouse.xy/iResolution.y, 0.0);
     return;
}

*/