// Cube A (cubemap) — 3D Turing Texture by Shane
// https://www.shadertoy.com/view/NsSSDW

// It can be a bit fiddly filling all four channels in at once, but thankfully, this is
// all calculated at startup. The idea is to put the function you wish to use in the
// middle of the loop here, instead of writing it out four times over.
vec4 funcFace0(vec3 p){
   
    
    vec4 col;
    
    for(int i = 0; i<4; i++){
        
        vec3 q = p + vec3(0, i&1, i>>1)/dims.x;
        
        vec3 rotF = vec3(0); // Rotation factor - Range: [0, 1].
        
        // Wrapped multilayer tertiary order Voronoi.
        gSc = vec3(64);
        vec3 sc = vec3(1);
        float res = hash33(q*gSc).x*.5 + .5;
        
        //res = smoothstep(.4, .6, res);
        
        //float res = 1. - n3DT(q*gSc);
    
        // The pixel channel value: On a side note, setting it to "v.y" is interesting,
        // but not the look we're going for here.
        col[i] = res;//max(1. - res*.85 - res*res*.15, 0.);

        
    }
    
    // Return the four function values -- One for each channel.
    return col;
    
}



// 3D weighted blur routine. Not much different to a 2D one. 
vec4 blur3D(samplerCube iCh, vec3 p, int N, int faceID) {

    vec4 col;

    p *= dims;
    
    vec3 mid = floor(vec3(N) - .5)/2.;
    vec4 res = vec4(0);
    float sum = 0.;

     
    for(int k = 0; k<N; k++){ 
       for(int j = 0; j<N; j++){ 
            for(int i = 0; i<N; i++){
                 
                vec3 offs = vec3(i, j, k) - mid; // Pixel offset.
                
                // Weighted blur value.
                float a = max(length(vec2(N)/2.) - length(offs), 0.); a *= a;
                //float a = 1./(1. + dot(offs, offs));
                //float a = exp(-(dot(offs, offs)/float(N*N))/2.);///float(N)*.39894;
                
                // Weighted texture value.
                res += txChSm(iCh, p + offs)*a;

                sum += a;
            }
        }
    }


    return res/sum;
    
}

// Converting your UV coordinates to 3D coordinates. I've seen some pretty longwinded
// obfuscated conversions out there, but it shouldn't require anything more than 
// the following. By the way, the figure "dims.x" is factored down by four to account
// for the four pixel channels being utilized, but the logic is the same.
vec3 convert2DTo3D(vec2 uv){
    
    // Converting the fract(uv) coordinates from the zero to one range to the whole
    // number, zero to... 1023 range.
    uv = floor(uv*cubemapRes);
    
    // Converting the UV coordinate to a linear representation. The idea is to convert the
    // 2D UV coordinates to a linear value, then use that to represent the 3D coordinates.
    // This way, you can effectively fit all kinds of 3D dimensions into a 2D texture array
    // without having to concern yourself with 2D texture wrapping issues. In theory, so 
    // long as the dimensions fit, and the X dimension is a multiple of four, then anything
    // goes. As mentioned, the maximum cubic dimension allowable for one cube face is 
    // 160 cubed. In that respect, rectangular dimensions, like vec3(160, 80, 320), etc, 
    // would also fit.
    //
    // For instance, the 137th pixel in the third row on a 1024 by 1024 cubemap face texture 
    // would be the number 2185 (2*1024 + 137).
    float iPos = dot(uv, vec2(1, cubemapRes.x));
    
    // In this case the XY slices comprise of 160 pixels (or whatever number we choose) along 
    // X and Y, so the pixel position in any block would be modulo 160*160. The xyBlock position 
    // would have to be converted to X and Y positions, which would be xyBlock mod dimX, and 
    // floor(xyBlock/dimX) mod dimY respectively. The Z position would depend on how many 
    // 160 by 160 blocks deep we're in, which translates to floor(iPos/(dimX*dimY)).
    //
    // Anyway, that's what the following lines represent.
    
    // XY block (or slice) linear position.
    float xyBlock = mod(iPos, dims.x*dims.y);
    
    // Converting to X, Y and Z position.
    vec3 p = vec3(mod(floor(vec3(xyBlock, xyBlock, iPos)/vec3(1, dims.x, dims.x*dims.y)), dims));
    
    //vec3 p = vec3(mod(xySlice, dims.x), mod(floor((xySlice)/dims.x), dims.y),
                  //floor((iPos)/(dims.x*dims.y)));
    
    // It's not necessary, but I'm converting the 3D coordinates back to the zero to one
    // range... There'd be nothing stopping you from centralizing things (p/dims - .5), but 
    // this will do.
    return p/dims;
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
        
        // This is part of an ugly hack that attempts to force the GPU compiler
        // to not unroll the Voronoi loops. Not sure if it'll work, but I'm 
        // trying it anyway, in the hope to get compiler times down on some
        // machines. For the record, this takes about 3 seconds to compile on 
        // my machine.
        frame0 = iFrame;
        
 
        
        
        // Fill the first cube face with a custom 3D function.
        if(faceID==0){
            
            vec3 p = convert2DTo3D(uv);
            
            col = funcFace0(p);
           
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
    
 
        //
        if(faceID!=0 || (iFrame - frame0)>300) {
            
            
            fragColor = tx(iChannel0, uv, faceID);
            
            // I couldn't understand why my frame rate was lagging after
            // applying an "if-else" statement, then realized the GPU will
            // still sometime calculate "if" and "else", even though only 
            // one is executed. Using a return gets around that.
            return;
        }
        
        
        vec3 p = convert2DTo3D(uv);

        
        // Here's the quickest 3D Turing pattern tutorial you're ever going
        // to get: Create some noise, then take the difference between the a 
        // large blur and a smaller one. You're welcome. :D
        //
        // Seriously though, this is just a huge shortcut that I kind of made
        // up on the spot.
        vec4 filt1 = blur3D(iChannel0, p, 3, faceID);
        vec4 filt2 = blur3D(iChannel0, p, 5, faceID);

        col = clamp(filt1*2. - filt2, -1., 1.);

    }
    
    
    // Update the cubemap faces.
    fragColor = col;
    
}

