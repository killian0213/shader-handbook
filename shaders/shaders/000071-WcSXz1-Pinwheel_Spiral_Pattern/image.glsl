// Image (image) — Pinwheel Spiral Pattern by Shane
// https://www.shadertoy.com/view/WcSXz1

/*

    Pinwheel Spiral Pattern
    -----------------------

    See the "Buffer A" tab for an explanation.
 
*/

// Display the texture only, with no highlighting. I probably prefer
// it this way, but after all that work... :)
//#define FLAT_TEXTURE

// Texture samples.
vec3 tx2D(vec2 p){ return texture(iChannel0, p).xyz; }

// Texture height.
//float getHeight(vec2 p){ return dot(tx2D(p), vec3(.299, .587, .114)); }

// Texture height.
float getHeight(vec2 p){ return texture(iChannel0, p).w; }


void mainImage(out vec4 fragColor, in vec2 fragCoord){

    
    // Screen coordinates.
    vec2 iR = iResolution.xy;
    vec2 uv = (fragCoord - iR*.5)/iR.y;
    vec2 uvT = fragCoord/iR;
    
    // Texture samples.
    vec3 col = tx2D(uvT);
    vec3 oCol = col;
    // Height value and offset sample for the colored lights.
    float height = getHeight(uvT);
    

    //vec3 e = vec3(.003*450./iR, 0); // Constant PPI sample distance.
    vec3 e = vec3(.003*iR.y/iR.x, .003, 0); // Variable sample distance.


    // Taking four nearby offset samples to use for gradient and curvature calculations.
    vec4 t4 = vec4(getHeight(uvT - e.xz),  getHeight(uvT + e.xz), 
               getHeight(uvT - e.zy), getHeight(uvT + e.zy));

    // Using the samples above and some vector math to obtain the surface normal. 
    // I did it this way just to show that there were other possibilities.
    //vec3 vx = vec3(e.x, 0, -t4.y) - vec3(-e.x, 0, -t4.x);
    //vec3 vy = vec3(0, -e.x, -t4.z) - vec3(0, e.x, -t4.w);
    float bmpF = .25;
    vec3 vx = vec3(e.x*2., 0, (t4.x - t4.y)*bmpF);
    vec3 vy = vec3(0, -e.y*2., (t4.w - t4.z)*bmpF);
    vec3 sn = normalize(cross(vx, vy));
    
    // One line approximation to the above, if you prefer.
    //vec3 sn = normalize(vec3(t4.x - t4.y, t4.z - t4.w, -height*e.x*2.)); 
    
    // Using the four samples above to calculate the surface curvature. Technically,
    // you need to divide by the sample-width squared (e.x*e.x), but we're 
    // ad-libbing a bit. :)
    float amp = 1.;
    float curv = clamp((dot(t4, vec4(1)) - height*4.)/e.x/2.*amp + .5, 0., 1.);
    //float curv = smoothstep(-.05, .05, (dot(t4, vec4(1)) - height*4.)/e.x/2.*amp);
          
     
    // Directional light. 
    //vec3 ld = normalize(vec3(-.5, 1, -1));
    // Point light, if preferred.
    vec3 ld = normalize(vec3(.125, .25, -1) - vec3(uv, 0));
    
    // Unit direction ray.
    vec3 rd = normalize(vec3(uv, 1));
    
    // Diffuse, specular and Fresnel.
    float dif = max(dot(sn, ld), 0.);
    float spe = pow(max(dot(reflect(ld, sn), rd), 0.), 32.);
    float fre = clamp(1. + dot(rd, sn), 0., 1.); // Fresnel reflection term.

    
    // Fake backfill light.
    col += col*12.*max(dot(normalize(vec3(-ld.xy, 0)), sn), 0.)*vec3(1, .1, .2);

    // Faux Fresnel edge glow.
    //float fres = pow(max(1. - max(dot(-rd, sn), 0.), 0.), 4.);
    //col += col*vec3(1, .4, .2)*fres*32.; 


    // Using the Forest cube map (in Channel1) for some fake specular reflections.
    //vec3 tx2 = texture(iChannel1, -reflect(rd, sn).yzx).xyz; tx2 *= tx2;
    //col = mix(col, col*tx2*3., fre);
 
     
    // Applying the directional light, colored highlights and a bit of 
    // ambient light to the surface.
    col *= (dif + spe*4. + .75); 
     
    // Debug lines.
    //col = mix(col, col*vec3(fre*fre)*8., .5);
    //col = vec3(fre);
    //col = pow(max(-sn.zyx*2. + .5, 0.), vec3(2));
   
    // Applying the curvature and shadows.
    //col += max(1. - curv*2., 0.)*.2;
    col *= max(1.1 - abs(curv - .5)*2.*.7, 0.);
    col *= max(-height*8. + .5, 0.);
    
    #ifdef FLAT_TEXTURE
    // Plane pattern with no lighting.
    col = oCol; 
    #endif
    
    // Subtle vignette -- Making use of IQ's box formula.
    uv = abs(uv) - vec2(iR.x/iR.y, 1)/2. + .15;
    float vig = min(max(uv.x, uv.y), 0.) + length(max(uv, 0.)) - .075;
    //col = mix(col, col.xzy,  smoothstep(0., .15, vig)); // Border coloring.
    col = mix(col, col*.65,  smoothstep(0., .1, vig));


    // Rough gamma correction.
    fragColor = vec4(pow(max(col, 0.), vec3(1./2.2)), 1);
}




