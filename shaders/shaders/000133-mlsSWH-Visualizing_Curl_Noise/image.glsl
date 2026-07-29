// Image (image) — Visualizing Curl Noise by Shane
// https://www.shadertoy.com/view/mlsSWH

/*

    Visualizing Curl Noise
    ----------------------

    This example consists of simple to apply procedural and aesthetic 
    lighting cliches. In particular, it's some bump mapped warped noise
    with colored highlighing. The warp operation used is the curl of a
    noise based function, and it's applied in feedback form.
    
    Field flow examples are not new to me, but I hadn't been motivated to
    post one until seeing Leon's really nice "Curling Smoke" submission. 
    I cobbled together some old code for this example, but it was good to 
    have Leon's and a couple of Fabrice's examples to refer to. I liked 
    the way Leon used blue noise to slightly randomize the offset sample 
    length when bump mapping, so I "borrowed" that idea. :)
    
    If you're not familiar with a curl function, I tend to liken it to 
    a perpendicular gradient vector of sorts that directs the flow in 
    a direction perpendicular to the tangential motion, which results 
    in vortex swirls -- Intuitively, if an object or particle travels 
    along a curve and you apply a sideways force component, a spiralesque 
    traversal pattern will result. 
    
    Domain warping is a pretty common graphics procedure and there are 
    too many examples on Shadertoy to count. The idea is to warp the 
    input coordinates in some way prior to passing them to a function. 
    The function can be whatever you want, like a simple 2D checker or 
    Truchet pattern, texture, or a 3D object. You can warp the 
    coordinates just once, or integrate them, which can be achieved via 
    multiple loop iterations, or in buffered feedback form. I'm using
    the latter method here.
    
    In regard to appearance, I wanted to provide a flow example that 
    clearly demonstrated the swirly flow motion. I did that by applying
    a heavy bump and some surface curvature shading -- By the way,
    curvature is easy to apply and can really bring out a surface.
    
    I used a very basic aesthetic cliche for the lighting. There are three
    lights, including a main directional white light, and two lesser
    strength red and blue lights, which hit from opposing directions. If
    you've watched a movie lately, then I'm sure you're familiar with it.
    
    Anyway, this is not meant to be a treatise on applying curl distortion 
    to noise, or using the curl vector in general, but hopefully, it'll 
    give someone a start. By the way, I have an old 3D curl example that
    I intend to post at some stage.
    
    
    Related examples:
    
    // Really fun to watch. The transcendental noise works nicely
    // in Leon's example, but I'm not sure it would have with the
    // setup I have here.
    https://www.shadertoy.com/view/cl23Wt
    
    // Integrating uv coordinates to a noise flow texture. IQ has a
    // heap of "Iterations" tagged shaders that are all worth looking at.
    Texture flow III - iq
    https://www.shadertoy.com/view/ldjXD3
    
    // Related vector field line example. Fabrice has a heap of
    // flow related examples that are worth looking at.
    vortex field (flow/magnetic) - FabriceNeyret2
    https://www.shadertoy.com/view/lljczz

 
*/


// Pinkish purple highlights.
//#define PINK


/*
// Smoother texture sample.
vec3 tx2D5(vec2 p, float mL){
    vec3 col = texture(iChannel0, p, mL).xyz;
    vec3 e = vec3(1./iResolution.xy, 0);
    col += (texture(iChannel0, p + e.xz).xyz + texture(iChannel0, p - e.xz).xyz +
            texture(iChannel0, p + e.yz).xyz + texture(iChannel0, p - e.yz).xyz)*.7;
    return col/3.8;

}*/

// Texture samples.
vec3 tx2D(vec2 p){ return texture(iChannel0, p).xyz; }

// Texture height.
float getHeight(vec2 p){ return dot(tx2D(p), vec3(.299, .587, .114)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    
    // Screen coordinates.
    vec2 iR = iResolution.xy;
    vec2 uv = fragCoord/iR;
    
    
    // Texture samples.
    vec3 col = tx2D(uv);
    // Height value and offset sample for the colored lights.
    float height = dot(col, vec3(.299, .587, .114));
    float height2 = getHeight(uv - normalize(vec2(1, 2))*.001*vec2(iR.x/iR.y, 1));
    

    // High frequency blue noise sample offset that I took from Leons curl example.
    vec3 nTx = texture(iChannel1, fragCoord/1024.).xyz;
    vec2 e = vec2((pow(dot(nTx, vec3(.299, .587, .114)), 3.)*.5 + .5)*.007, 0);
    //vec2 e = vec2(.0045, 0); // Constant sample distance.

    // Taking four nearby offset samples to use for gradient and curvature calculations.
    vec4 t4 = vec4(getHeight(uv - e.xy),  getHeight(uv + e.xy), 
               getHeight(uv - e.yx), getHeight(uv + e.yx));

    // Using the samples above and some vector math to obtain the surface normal. 
    // I did it this way just to show that there were other possibilities.
    //vec3 vx = vec3(e.x, 0, -t4.y) - vec3(-e.x, 0, -t4.x);
    //vec3 vy = vec3(0, -e.x, -t4.z) - vec3(0, e.x, -t4.w);
    vec3 vx = vec3(e.x*2., 0, t4.x - t4.y);
    vec3 vy = vec3(0, -e.x*2., t4.w - t4.z);
    vec3 sn = normalize(cross(vx, vy));
    
    // One line approximation to the above, if you prefer.
    //vec3 sn = normalize(vec3(t4.x - t4.y, t4.z - t4.w, -height*e.x*2.)); 
    
    // Using the four samples above to calculate the surface curvature.
    float amp = .7;
    float curv = clamp((height*4. - dot(t4, vec4(1)))/e.x/2.*amp + .5, 0., 1.);
         
     
    // Directional light. 
    vec3 ld = normalize(vec3(-.5, 1, -1));
    // Point light, if preferred.
    //vec3 ld = normalize(vec3(.25, 1.25, -.5) - vec3(uv, 0));

    // Directional derivative colored heighlight values.
    float b = max(height2 - height, 0.)/.001;
    float b2 = max(height - height2, 0.)/.001;
    // Highlight colors.
    vec3 hiCol = vec3(.02, .2, 1)*b*.8 + vec3(1, .2, .1)*b2*.3;

    #ifdef PINK
    // Pinkish purple lights.
    col = mix(col.xzy, col, max(dot(sn, ld), 0.));
    #endif
    
    // Specular light, if you wanted that.
    /*
    vec3 rd = normalize(vec3(uv, 1));
    float spe = pow(max(dot(reflect(ld, sn), rd), 0.), 16.);
    hiCol += spe*2.;
    */

    // Applying the directional light, colored highlights and a bit of 
    // ambient light to the surface.
    col *= max(dot(sn, ld), 0.) + hiCol + .4;

    // Applying the curvature.
    col *= curv + .2; 
    
    
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}


