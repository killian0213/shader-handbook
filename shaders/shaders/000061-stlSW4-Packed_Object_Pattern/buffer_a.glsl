// Buffer A (buffer) — Packed Object Pattern by Shane
// https://www.shadertoy.com/view/stlSW4

// The dart throwing algorithm.


// Pattern shape: Circle: 0, Triangle: 1,  Square: 2, Polygon: 3
// Changing this will require a reset with the mouse or back button.
#define SHAPE 3

// Put holes in the shapes.
//#define ANULUS

 
// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  
    //p = mod(p, 8.);
    return fract(sin(mod(dot(p, vec2(127.619, 157.583)), 6.2831589))*43758.5453); 
}

 
// I searched Shadertoy for a robust regular polygon routine and came across
// the following example:
//
// Regular Polygon SDF - BasmanovDaniil
// https://www.shadertoy.com/view/MtScRG
//
// To use the functions in more intensive scenes, some optimization would be
// necessary, but I've left them in their original form to show the working.

float Polygon(vec2 p, float vertices, float radius){

    float segmentAngle = 6.2831853/vertices;
    
    float angleRadians = atan(p.x, p.y);
    float repeat = mod(angleRadians, segmentAngle) - segmentAngle/2.;
    float inradius = radius*cos(segmentAngle/2.);
    float circle = length(p);
    float x = sin(repeat)*circle;
    float y = cos(repeat)*circle - inradius;

    float inside = min(y, 0.);
    float corner = radius*sin(segmentAngle/2.);
    float outside = length(vec2(max(abs(x) - corner, 0.0), y))*step(0.0, y);
    return inside + outside;
}

 
// Object distance field and central position based ID.
vec4 object(in vec2 p, in float r, in vec2 id){

    #if SHAPE == 0
    float d = length(p) - r;
    #ifdef ANULUS
    // Effectively boring out holes in the shape.
    d = abs(d + sqrt(r)*.1) - sqrt(r)*.1;
    #endif
    return vec4(d, id, r);
    // Donuts... Doesn't look great, but it works.
    //return vec4(abs(length(p) - r*.66) - r*.34, id, r);
    #else
    
    #if SHAPE == 1
    float vNum = 3.;
    #elif SHAPE == 2
    float vNum = 4.;
    #else
    float vNum = 3. + floor(hash21(id)*6.);
    #endif
    
    p = rot2(hash21(id)*6.2831*4.)*p; 
    float d = Polygon(p, vNum, r - r*.2) - r*.2;
    #ifdef ANULUS
    // Effectively boring out holes in the shape.
    d = abs(d + sqrt(r)*.1) - sqrt(r)*.1;
    #endif
    return vec4(d, id, r);
    
    #endif
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
 
 
    // Screen coordinates. Range: [0, 1].
    vec2 uv = (fragCoord)/iResolution.xy;
    
    vec2 seed = vec2(1.618, 1)*mod(float(iFrame)*0.0127 + iDate.w, 256.);//iDate.w;
    
    // Set all data slots to one.
    vec4 col = vec4(1);
     
    // After loading or hitting the mouse button, reset.
    if(textureSize(iChannel0, 0).x<2 || iMouse.z>1.){
          
          fragColor = col;
          return;
    }
    
    // After the first frame, start filling the buffer.
    if (iFrame>0) { 
    
        // Closest object distance, ID and width at this pixel postion.
        col = texture(iChannel0, uv);
    
        for(int i = min(0, iFrame); i<60; i++){

            // Random object size.
            float rad = hash21(seed + .021)*.12 + .05;

            // Random canvas position.
            vec2 rndPos = vec2(hash21(seed + .141), hash21(seed + .083));
            // Object distance at the random start position.
            vec4 dataRndPos = texture(iChannel0, fract(rndPos + .5));

            for(int j=0; j<10; j++){            
            
                // If there's enough room to place the new object, do so. 
                if(dataRndPos.x>rad){ 

                        // Create the object at the new position.
                        vec4 tmp = object(fract(uv - rndPos) - .5, rad, rndPos);
                        // Compare it to the old closest object, then update if necessary.
                        col = tmp.x<col.x? tmp : col;
                        i = 1000;
                        break;
                }
                // If there's not enough room, reduce the object size and try again.
                rad *= .84;
                
                // Alternative: If there's not enough room, reduce size roughly half the time then
                // try again. In theory, more large objects should result.
                //if(hash21(seed + .071)<.5) rad *= .82;
            }
            
            // If we've made it this far, we didn't get a hit, so update the
            // seed and try at the next position.
            seed = mod(seed + vec2(i*57, i)*.0123, 256.);

        }
    }
    
    fragColor = col;
 
}