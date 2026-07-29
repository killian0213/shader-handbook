// Buffer A (buffer) — Interactive Rubik's Cube by kishimisu
// https://www.shadertoy.com/view/w3lGRf

/* This buffer manages the state of the rubik's cube.
   It has 27 active threads (fragments), one for each cell.
   
   It can update the rubik's cube state in only two ways:
   - (Reset)  Reset the cube to its solved state, done once at the start of the shader
   - (Rotate) After a rotation animation has finished, update the state for each 
              cell of the face that was rotated.
              
   Rotations are applied using an array of offsets for each axis of rotation. Each cell
   look up its inverse rotated offset, and copies the state of the cell at that offset
   (using swizzling to achieve the correct rotation).
   
Each cell stores its state as a color index for each axis:
   r: x-axis color index (0-5)
   g: y-axis color index (0-5)
   b: z-axis color index (0-5)
   
Map of thread indices for each face:

[FRONT]   [BACK]       [LEFT]      [RIGHT]     [BOTTOM]     [TOP]        
6, 7, 8   26, 25, 24   24, 15, 6   8, 17, 26    0,  1,  2   24, 25, 26     
3, 4, 5   23, 22, 21   21, 12, 3   5, 14, 23    9, 10, 11   15, 16, 17   
0, 1, 2   20, 19, 18   18,  9, 0   2, 11, 20   18, 19, 20   6,  7,  8   
*/
void mainImage(out vec4 O, vec2 F)
{
    ivec2 tid = ivec2(F);
    if (tid.x > 26 || tid.y > 0) discard; // 27 active threads
    
    vec4 col = texture(iChannel0, F/iResolution.xy);
    vec4 swipe = texelFetch(iChannel1, ivec2(1, 0), 0);
    
    int  id = tid.x;
    ivec3 p = getID(id);
    
    // Reset cube
    if (iFrame < 3) 
    {
        if (p.x == 0) col.x = 0.; // blue   (left)
        else          col.x = 3.; // green  (right)
        
        if (p.y == 0) col.y = 1.; // orange (bottom)
        else          col.y = 4.; // red    (top)
        
        if (p.z == 0) col.z = 2.; // white  (front)
        else          col.z = 5.; // yellow (back)
    }
    
    // Apply face rotation (update state)
    else if (iTime - swipe.r > ANIM_DURATION) 
    {
        int rot = int(swipe.z); // rotation id (0-8)
        int cc  = int(swipe.w); // counter-clockwise (0-1)
        
        // x rotations
        if (p.x == rot) {
            const int offsets[18] = int[18](
                6, 12, 18,-6, 0, 6,-18,-12,-6, // clockwise
                18, 6,-6, 12, 0,-12, 6,-6,-18  // counter-clockwise
            );
            int nid = id + offsets[id/3 + cc*9];
            col = texelFetch(iChannel0, ivec2(nid, 0), 0).rbga;
        }
        // y rotations
        else if (p.y == rot - 3) {
            const int offsets[18] = int[18](
                2, 10, 18,-8, 0, 8,-18,-10,-2,
                18, 8,-2, 10, 0,-10, 2,-8,-18
            );
            int nid = id + offsets[(id/9)*3 + id%3 + cc*9];
            col = texelFetch(iChannel0, ivec2(nid, 0), 0).bgra;
        }
        // z rotations
        else if (p.z == rot - 6) {
            const int offsets[18] = int[18](
                2, 4, 6,-2, 0, 2,-6,-4,-2,
                6, 2,-2, 4, 0,-4, 2,-2,-6
            );
            int nid = id + offsets[id%9 + cc*9];
            col = texelFetch(iChannel0, ivec2(nid, 0), 0).grba;
        }
    }
    
    O = col;
}