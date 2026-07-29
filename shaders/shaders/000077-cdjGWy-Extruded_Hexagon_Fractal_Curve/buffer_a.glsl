// Buffer A (buffer) — Extruded Hexagon Fractal Curve by Shane
// https://www.shadertoy.com/view/cdjGWy

// The 2D hexagon fractal object.


// Dividing line passing through "a" and "b".
float divLine(vec2 p, vec2 a, vec2 b){

   // I've had to put a hack on the end to get rid of fine lines
   // at the zero point. That, of course, invalidates the distance portion.
   // However, in this case, I only need it for a border check, not distances.
   // I'm not sure why the hack is needed... Some kind of float inaccuracy... 
   // I'll look into it later. :)
   b -= a; 
   return dot(p - a, vec2(-b.y, b.x)/length(b))*1e8;
}

// Standard polar partitioning.
vec2 polRot(vec2 p, inout float na, int m){

    const float aN = 6.;
    float a = atan(p.y, p.x);
    na = mod(floor(a/6.2831*aN) + float(m - 1), aN);
    float ia = (na + .5)/aN;
    p *= rot2(-ia*6.2831);
    // Flip alternate cells about the center.
    if(mod(na, 2.)<.001) p.y = -p.y;

    return p;
}

// Partition lines.
vec3 prtnLines(vec2 p, mat3x2 ctr){

                
    // Cell partition lines.
    float div1 = divLine(p, ctr[1], ctr[0]);
    float div2 = divLine(p, ctr[2], ctr[1]);  
     // Cell border.
    float bR = divLine(p, vec2(0), ctr[2]);
    //bL = divLine(p, vec2(0), ctr[0]);

    return vec3(div1, -max(div1, div2), max(div2, bR));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Aspect corret coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Scale and smoothing factor.
    const float sc = 1.;
    float sf = sc*1.5/iResolution.y;
    
    // Automatically rotate through all levels.
    //cInd = int(mod(floor(iTime/4.), 2.));
    
    
    // Scaling and translation.
    vec2 p = sc*uv;//rot2(3.14159/6. - iTime/24.)*sc*uv;
    
    // Scene field calculations.

    vec2 op = p;
    
    // The distance field for each level.
    vec3 gDst = vec3(1e5);
 
    // Polar cell numbers.
    vec3 na;    
  
    
    // Bounds for each level.
    float gBound = 1e5;

    
    // I poached this from one of my hexagonal six petal geometry examples. I remember
    // working it out on paper and liking the fact that it was so weird but concise. 
    // Unfortunately, I didn't mention how I got there. :)
    const float shF = sqrt(1./7.);
    // The original radius of the circle that the curve is constucted around.
    const float r0 = .2;
    const float hr0 = r0/.8660254; // Hexagon radius.
    float r20 = hr0/3.; // Small circle radius.
    #if SHAPE != 0
    r20 *= .8660254; // Readjusting the radius for hexagonal shapes.
    #endif
    // Each polar cell has an S-shaped curve running through it, which is
    // constructed with three vertex points. There are two on the cell boundaries, 
    // and one in the center -- Check the figure with one iteration for a visual. 
    // The vertex scale changes for greater iteration depth, but not the direction, 
    // so we're going to precalculate the original scale and direction here.
    mat3x2 ctr0 = mat3x2(rot2(3.14159/6.)*vec2(hr0*2./3., 0), vec2(r0*4./3., 0), 
                         rot2(-3.14159/6.)*vec2(hr0*4./3., 0));
    
    // Precalculating the rotation matrices, which get used a few times.
    // The angle is a hexagonal rotation related number involving ratios...
    // The tangential angle between thrice the apothem and half the side
    // length... I worked it out long ago, and no longer care why it works. :D
    //
    // Angle between the vertical line and the line running through the 
    // left hexagon vertex to the right vertex on the hexagon above.
    float rotAng = atan(sqrt(3.)/9.); // Approx: 0.19012.
    mat2 mRot = rot2(rotAng);
    mat2 mRotP3 = rot2(rotAng + 3.14159/3.); // Inner curve needs extra rotation.

    for(int aI = 0; aI<3; aI++){

        // The radius of the circle that the curve is constucted around.
        float r2 = r20; // Small circle radius.
        p = op; // Original global coordinates.
       
        // Split this space into polar cells, and return the local coordinates
        // and the cell number, which is used later.
        p = polRot(p, na.x, aI);


        mat3x2 ctr = ctr0; // Curve center -- There are three in each segment.


        // Partition lines for each of the three vertices in the cell.
        vec3 oDiv = prtnLines(p, ctr);
        // Hexagon bounds for this scale. It's used to reverse coloring at the end.
        gBound = min(gBound, max(-oDiv.y, oDiv.z)); // Previous hexagonal boundary lines.

    
        // Left, middle, right central point distances.
        vec3 c = vec3(dist(p - ctr[0]), dist(p - ctr[1]), dist(p - ctr[2])) - r2;
        
        
        c = max(c*vec3(-1, 1, -1), oDiv);

        float crv = min(max(c.x, c.z), c.y);
        
        if(crv<gDst.x){ gDst.x = crv; }
        
        

        ////////////////////////  

        // Move to the new frame of reference, readjust r to the new scale
        // (the smaller circle, r2), then recalculate the curve.
        
        // Move to the new points.
        mat3x2 p3 = mat3x2(p, p, p) - ctr;
        //
        if(mod(na.x, 2.)<.001){
            // Flip the X-value in every second polar cell.
            p3[0].x = -p3[0].x; p3[1].x = -p3[1].x; p3[2].x = -p3[2].x;
        }
        // Rotate each point to the new orientation. The second point
        // needs to be rotated an extra 60 degrees.
        p3[0] *= mRot; p3[1] *= mRotP3; p3[2] *= mRot;
 

        for(int i = 0; i<3; i++){

            ctr = ctr0*shF; 
            r2 = r20*shF;
            
            p = p3[i];
            
            // Split this space into polar cells, and return the local coordinates
            // and the cell number, which is used later.
            p = polRot(p, na.y, 1); // bI - 1


            // Partition lines for each of the three vertices in the cell.
            vec3 oDiv2 = prtnLines(p, ctr);
            
       
            // Applying the previous clipping region to this one.
            oDiv2 = max(oDiv2, oDiv[i]);
     
            // Left, middle, right central point distances.
            c = vec3(dist(p - ctr[0]), dist(p - ctr[1]), dist(p - ctr[2])) - r2;
            ////
            
            c = max(c*vec3(-1, 1, -1), oDiv2);
           
            crv = min(max(c.x, c.z), c.y);
        
            if(crv<gDst.y){ gDst.y = crv; }

           
       

        } // End "i".
        

    } // End "aI".   


    
    // Clamp the level index between zero and one, since they're the only
    // one's that work.
    cInd = cInd<0? 0 : cInd>1? 1 : cInd;
    
    // Flipping patterns outside the bounds of previous levels... Yeah, it's confusing. :)
    // With Truchet patterns, there's usually some cell pattern flipping involved, but with 
    // this example, there's level flipping also. 
    if(gBound<0.){ gDst.y = -gDst.y; gDst.z = -gDst.z; }
     
    // Giving the pattern some extra thickness.
    gDst -= .004*float(3 - cInd);
    
    #ifdef CURVE
    gDst = abs(gDst + .004*float(3 - cInd)) - .009*float(3 - cInd);
    #endif
 
    

    // Edge, or stroke.
    float dst = gDst[cInd];


    // Output to screen
    fragColor = vec4(dst);
}