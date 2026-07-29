// Cube A (cubemap) — Mirrored Polyhedron On Terrain by Shane
// https://www.shadertoy.com/view/WdtBzn



// It can be a bit fiddly filling all four channels in at once, but thankfully, this is
// all calculated at startup. The idea is to put the function you wish to use in the
// middle of the loop here, instead of writing it out four times over.
vec4 funcFace1(vec2 uv){
    
    // It's a 2D conversion, but we're using a 3D function with constant Z value.
    vec3 p;
    // Just choose any Z value you like. You could actually set "p.z" to any constant,
    // or whatever, but I'm keeping things consistant.
    p.z = floor(.0*cubemapRes.x)/cubemapRes.x; 
       
    vec4 col;
    
    for(int i = 0; i<4; i++){

        // Since we're performing our own 2D interpolation, it makes sense to store
        // neighboring values in the other pixel channels. It makes things slightly
        // more confusing, but saves four texel lookups -- usually in the middel of
        // a raymarching loop -- later on.
        
        // The neighboring position for each pixel channel.
        p.xy = mod(floor(uv*cubemapRes) + vec2(i&1, i>>1), cubemapRes)/cubemapRes;
         
        // Layering in some noise as well. This is all precalculated, so speed isn't
        // the primary concern... Compiler time still needs to be considered though.
        gSc = vec3(4);
        float res2 = n3DT(p*gSc);
        gSc = vec3(8);
        res2 = mix(res2, n3DT(p*gSc), .333);
        gSc = vec3(16);
        res2 = mix(res2, n3DT(p*gSc), .333/2.);
        //gSc = vec3(32);
        //res2 = mix(res2, n3DT(p*gSc), .333/4.);
        gSc = vec3(64);
        res2 = mix(res2, 1. - abs(.5 - n3DT(p*gSc))*2., .02);
 
       

        // Individual Voronoi cell scaling.
        vec3 sc = vec3(1, 1, 1);
        vec3 rotF = vec3(0); // Rotation factor.
        
        //sc += res2*.05;
        
        // Put whatever function you want here. In this case, it's Voronoi.
        gSc = vec3(32);
        vec3 v = Voronoi(p*gSc, sc, rotF, 1., 0);
        float res = v.x;
        gSc = vec3(64);
        v = Voronoi(p*gSc, sc, rotF, 1., 0);
        res = mix(res, v.x, .333);
        gSc = vec3(256);
        v = Voronoi(p*gSc, sc, rotF, 1., 0);
        res = mix(res, mix(v.y - v.x, smoothstep(.1, 1., v.y - v.x), .5), .333/3.);
        
        
        
        // The pixel channel value: On a side note, setting it to "v.y" is interesting,
        // but not the look we're going for here.
        
        
        
        // Mix in the Voronoi and the noise.
        col[i] = mix(res, res2, .9);
        
        
        
        gSc = vec3(4);
        vec3 r3 = terrain(p.xy*gSc.xy + .5);
        float res3 = smoothstep(0.1, 1., r3.x);
        
        col[i] = mix(res, res3, .9);

    }
    
    return col;
}



// Cube mapping - Adapted from one of Fizzer's routines. 
int CubeFaceCoords(vec3 p){

    // Elegant cubic space stepping trick, as seen in many voxel related examples.
    vec3 f = abs(p); f = step(f.zxy, f)*step(f.yzx, f); 
    
    ivec3 idF = ivec3(p.x<.0? 0 : 1, p.y<.0? 2 : 3, p.z<0.? 4 : 5);
    
    return f.x>.5? idF.x : f.y>.5? idF.y : idF.z; 
} 

void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir){
    
    
    // UV coordinates.
    //
    // For whatever reason (which I'd love expained), the Y coordinates flip each
    // frame if I don't negate the coordinates here -- I'm assuming this is internal, 
    // a VFlip thing, or there's something I'm missing. If there are experts out there, 
    // any feedback would be welcome. :)
    vec2 uv = fract(fragCoord/iResolution.y*vec2(1, -1));
    
    // Adapting one of Fizzer's old cube mapping routines to obtain the cube face ID 
    // from the ray direction vector.
    int faceID = CubeFaceCoords(rayDir);
  
  
    // Pixel storage.
    vec4 col;
    

    // Initial conditions -- Performed upon initiation.
    //if(abs(tx(iChannel0, uv, 5).w - iResolution.y)>.001){
    //if(iFrame<1){
    //
    // Great hack, by IQ, to ensure that this loads either on the first frame, or in the
    // event that the texture hasn't loaded (this happens a lot), wait, then do it...
    // Well kind of. Either way, it works. It's quite clever, which means that it's something 
    // I never would have considered. :)
    if(textureSize(iChannel0,0).x<2 || iFrame<1){
      
        
        /*
        // Debug information for testing individual cubeface access.
        if(faceID==0) col = vec4(0, 1, 0, 1);
        else if(faceID==1) col = vec4(0, .5, 1, 1);
        else if(faceID==2) col = vec4(1, 1, 0, 1);
        else if(faceID==3) col = vec4(1, 0, 0, 1);
        else if(faceID==4) col = vec4(.5, .5, .5, 1);
        else col = vec4(1, 1, 1, 1);
        */
 
        
        // Fill the second cube face with a custom 2D function... We're actually
        // reusing a 3D function, but it's in slice form, which essentially makes
        // it a 2D function.
        if(faceID==1){

            col = funcFace1(uv);
            
        } 
        
        /*
        // Last channel on the last face: Used to store the current 
        // resolution to ensure loading... Yeah, it's wasteful and it
        // slows things down, but until there's a reliable initiation
        // variable, I guess it'll have to do. :)
        if(faceID==5){
            
            col.w = iResolution.y;
        }
        */

        
    }
    else {
        	
        // The cube faces have already been initialized with values, so from this point,
        // read the values out... There's probably a way to bypass this by using the 
        // "discard" operation, but this isn't too expensive, so I'll leave it for now.
        //col = tx(iChannel0, uv, faceID);
        if(faceID == 1) col = tx1(iChannel0, uv);
    }
    
    
    // Update the cubemap faces.
    fragColor = col;
    
}

