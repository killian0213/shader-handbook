// Cube A (cubemap) — Path Traced Quad Prism Traversal by Shane
// https://www.shadertoy.com/view/msXfz2

// The irregular quad pattern.

vec4 gVal; // Storage for the cell contents.
//vec2 gSID; // Static ID.



// The asymmetric quad grid. 
vec4 pattern(vec2 p, vec2 sc){    
    // Distance and edge width.
    
    float d = 1e5;
    
     
    // Centers for all four tiles.
    const mat4x2 cntr = mat4x2(vec2(-.5), vec2(-.5, .5), vec2(.5), vec2(.5, -.5)); 
    
    // Because the asymmetric boundaries of the quads overlap neighboring cells, 
    // neighbors need to be considered. In this case four cell renders will do.
    //const int n = 2;
    //const float m = floor(float(n)/2. + .001) - .5;
    for(int i = 0; i<4; i++){

        // Local coordinates and ID.
        vec2 q = p.xy;
        vec2 iq = floor(q/sc - cntr[i]) + .5; 
        q -= (iq)*sc;
        
        // The four vertices for this cell.
        mat4x2 v = cntr;
        
        // Offset vertices.
        mat4x2 sv = mat4x2(hash22T(iq + v[0]), hash22T(iq + v[1]), 
                           hash22T(iq + v[2]), hash22T(iq + v[3]));
        
        // Offset the vertices.
        v += (sv/float(ni)*2. - 1.)*.25;

        // Scale.
        v[0] *= sc; v[1] *= sc; v[2] *= sc; v[3] *= sc;        
        

        // Quad boundary normals.
        mat4x2 e = v - mat4x2(v[1], v[2], v[3], v[0]);
        e[0] = normalize(e[0]).yx*vec2(1, -1);
        e[1] = normalize(e[1]).yx*vec2(1, -1);
        e[2] = normalize(e[2]).yx*vec2(1, -1);
        e[3] = normalize(e[3]).yx*vec2(1, -1);
        
        // Quad distance.
        float d2 = dot(q - v[0], e[0]);
        d2 = max(d2, dot(q - v[1], e[1]));
        d2 = max(d2, dot(q - v[2], e[2]));
        d2 = max(d2, dot(q - v[3], e[3]));
  
        // If this quad distance is nearer, update.
        if(d2<d){
            
            // New distance, static ID and moving ID.
            // The zero field is an unused height value holder.
            d = d2;
            //gSID = iq + (v[0] + v[1] + v[2] + v[3])/4./s;
            
            // Storing the four quad vertices into the final two channels.
            vec2 gQV;
            gQV.x = DecodeFloatRGBA(vec4(sv[0], sv[1]));
            gQV.y = DecodeFloatRGBA(vec4(sv[2], sv[3]));
            
            // Saving the central coordinates and four vertices of the nearest quad. 
            // "sc" needs to be there for wrapping purposes.
            gVal = vec4(iq*sc, gQV);
        }
    
    }
    
    
    // Combining the floor with the extruded object.
    return  gVal;
 
}



vec4 funcFace0(vec3 q3){

    // Cube map face pattern.
    return pattern(q3.xy, s);
}



// Cube mapping - Adapted from one of Fizzer's routines. 
int CubeFaceCoords(vec3 p){

    // Elegant cubic space stepping trick, as seen in many voxel related examples.
    vec3 f = abs(p); f = step(f.zxy, f)*step(f.yzx, f); 
    
    ivec3 idF = ivec3(p.x<.0? 0 : 1, p.y<.0? 2 : 3, p.z<0.? 4 : 5);
    
    return f.x>.5? idF.x : f.y>.5? idF.y : idF.z; 
}



void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir){
    
    
    
    
    // Adapting one of Fizzer's old cube mapping routines to obtain the cube face ID 
    // from the ray direction vector.
    int faceID = CubeFaceCoords(rayDir);
    
    // We're only using one cube map face, so don't calculate any others...
    // or give the annoying compiler a chance to calculate others.
    if(faceID > 0) return;
    
    
    // UV coordinates.
    //
    // For whatever reason (which I'd love expained), the Y coordinates flip each
    // frame if I don't negate the coordinates here -- I'm assuming this is internal, 
    // a VFlip thing, or there's something I'm missing. If there are experts out there, 
    // any feedback would be welcome. :)
    vec2 uv = fract(fragCoord/iResolution.y*vec2(1, -1));
  
  
    // Pixel storage.
    vec4 col = vec4(0);
    
    
    
    // Precalculation flag: GPUs are annoying. Sometimes, they'll will calculate
    // both the "if" and "else" statements every time. The "if" part here is extremely
    // expensive, so we don't want that. The solution is to not have an "if-else"
    // statement at all.
    int preCalc = 0;
    

    // Initial conditions -- Performed upon initiation.
    //if(abs(tx(iChannel0, uv, 5).w - iResolution.y)>.001){
    //if(iFrame<1){
    //
    // Great hack, by IQ, to ensure that this loads either on the first frame, or in the
    // event that the texture hasn't loaded (this happens a lot), wait, then do it...
    // Well kind of. Either way, it works. It's quite clever, which means that it's 
    // something I never would have considered. :)
    if(textureSize(iChannel0, 0).x<2 || iFrame<maxFrames){
        
        //if(iFrame>=maxFrames) return;        
        
        // Fill the first cube face with a custom function.
        if(faceID==0){
            
            //vec3 p = convert2DTo3D(uv);      
            vec3 p = vec3(uv, 0);      
            
            col = funcFace0(p);
            
            preCalc = 1;
           
        }
        
    }
    
    // If precalculation has already occurred, read in the texture.
    if(preCalc == 0) col = tx0(iChannel0, uv);
    
    
    
    // Update the cubemap faces.
    fragColor = col;
    
}

