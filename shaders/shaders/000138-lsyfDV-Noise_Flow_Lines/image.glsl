// Image (image) — Noise Flow Lines by Shane
// https://www.shadertoy.com/view/lsyfDV

/*

	Noise Flow Lines
	----------------
	
	Davidar's "Wind Flow Map" reminded me that I've had a few noise flow examples sitting 
	around half finished, so I decided to finish one and post it... It's less polished 
	than I'd like, but it's more complete than it was. :) I have some static imagery, and
	some animated particle versions that I'll post at some stage.

	I'm sure you've seen noise flow-field images before. This is a cheap recreation, but 
	the real ones look pretty cool. They're trivial to construct when you have random pixel 
	access -- Convert a noise value to a constant length direction vector, advance the
    current position, render something at, or between, points, repeat the process, etc. 
	The problem, of course, is drawing a set of overlapping objects at a decent frame rate 
	in a pixel shader. It's possible to produce some really nice particle based versions,
	but you tend to lose the wind-swept fibrous animation along the way.
	
	If realtime animation wasn't a concern, it'd be possible to recreate the beautiful
    particle based equivalent precisely. A particle\line array approach simply isn't 
	possible in this situation. This particular image requires the rendering of six lines 
	9000 times over (I think) per pixel per frame. Taking a grid approach brings the total 
	line count way down to the order of 300. Not ideal, and at the expense of quality, but 
	a mid-range GPU can handle it easy enough.

	As inferred, it's possible to render static noise field lines outside the pixel shader 
	environment with very little effort, and since I hacked this method together on the fly, 
    I'd imagine there might be better ways to get the job done. However, this will suffice 
	for now. I know of a way that might increase efficiency considerably, but I'll have to 
	conduct some experiments first.

	For anyone who wants a start on noise flow, I stripped down IQ's "Noise Blur" example,
	and put in some quick comments. The example wasn't interesting enough to list, so the 
    link is private. 
    //
	Directional Noise Blur - Shane
	https://www.shadertoy.com/view/MdyfDc
    //
    The shader above is based largely on the following:
	Noise Blur - iq
	https://www.shadertoy.com/view/4dlGDN

    
	Other examples:


	// Real time particle flow.
    //
	Wind flow map - davidar 
	https://www.shadertoy.com/view/4sKBz3

    // Very classy -- Nimitz is the kind of coder who can lift your coding skills. Wish
	// he posted more. For my own amusement, I've been meaning to port an old example 
	// that's similar, but it involves too many particles, which means I'll have to 
	// organize them into grid segments, etc... Too lazy for that at the moment. :)
    //
	Sinuous - nimitz
	https://www.shadertoy.com/view/4sGSDw

    // If you're not familiar with noise flow imagery, you can find a few examples here:
    //
    Getting Creative with Perlin Noise Fields - Sighack
    https://sighack.com/post/getting-creative-with-perlin-noise-fields



*/



void mainImage(out vec4 fragColor, in vec2 fragCoord){
    
  
    // Screen coordinates.
    float iResY = min(iResolution.y, 800.);
    vec2 uv = (fragCoord.xy - iResolution.xy*.5)/iResY;
    
    // Grid scale. Smaller numbers space the strands out more, and larger numbers pack them in.
    // I thought this was about right for the 800 by 450 window. There's also a screen size factor
    // that I fudged in to attempt to achieve the right scale when using fullscreen, etc. Sometimes,
    // it'd be nice to just cater to one window size, but that's never happening. :)
    float scSizeFactor = pow(iResY/450., .333); // Just a rough guess. No science whatsoever. :)
    float scale = 72.*scSizeFactor;
    
    vec2 p = uv*scale; // Add "iTime" for scrolling, if desired.
    
    // The unique ID for each cell. Oddly enough, it's used to uniquely identify the cell. :)
    vec2 ip = floor(p);
    
    p -= ip + .5; // The centered local cell coordinates. Same as: p = fract(p) - .5;
    
    
    // Scene color. Intitialized to zero.
    vec3 col = vec3(0);
    
        	
    // The joys of rendering things on a repeat grid. :) If the object in question fits within the confines of 
    // the local grid cell, then you only need render that grid cell. However, if it overlaps other grid cells,
    // then you need to render those too. In this instance, the object is a strand of six lines that can overlap
    // a whole heap of neighboring cells (7x7), so each have to be rendered. Not ideal, but the alternative is 
    // to iterate through the 7000 or so grid cells on the canvas.
    for(int j = -3; j<=3; j++){
    	for(int i = -3; i<=3; i++){
        
            // Cell coordinates we're covering. The unique identifier will be 
            // "ip + o," which is used to index the various precalculated values, etc.
            vec2 o = vec2(i, j);
            
            // Slight grid center offset, just to break the grid lines up a little.
            o += hash22(o + ip, 64.)*.25;
            
            // Alpha value. Used to fade out the strand as it lengthens.
            float alpha = 1.;
            
            // Layer color.
            vec3 col2 = vec3(0);
            
            // Extra noise values for some strand coloring, shadowing, etc.
            vec2 v = texture(iChannel0, (ip + o)/scale/16.).yz;
            
            // The texture strand color. Unique to each strand.
            // Option one:
            //vec3 tx = vec3(v.x*.2 + .8, v.x*.5 + .25, v.x)*vec3(2.4, 2, 1.6);
            //tx *= smoothstep(0., .1, v.y - .4)*.4 + .8;
            
            // Option 2:
            // Load "Organic 3" into iChannel1 to use this.
            //vec3 tx = texture(iChannel1, ((ip + o)/scale/1.)*vec2(iResolution.y/iResolution.x, 1) + .5).xyz;
            //tx *= tx;
            //tx = smoothstep(-.05, .5, tx)*2.5;
            
            // Option 3: Using IQ's cosine palette.
            vec3 tx = (.5 + .45*cos(6.2831*v.y*128. - vec3(0, 1, 2)*1.25))*3.;
            
            
            // Drawing circles in every grid cell below the strands, but I decided against it.
            //float circ = length(o - p) - .1;
            //circ = max(circ, -(circ - .07));
             
            // Start off from the grid origin, obtain the noise value at that position, convert it to
            // an angle in order to construct a constant lenth direction vector. Use the direction
            // vector to advance to the new position and draw a line between them. Repeat the 
            // process. Very simple. However, slightly costly due to the overlapping line segments.
            // Hence, the very small number of short segments.
            
            const int lNum = 6;
            for(int n = 0; n<lNum; n++){
        	
                // If grinding things to a halt by not precalculating is more your thing, swap the 
                // line below for this one. :D
                //float a = (fBm((ip + o)/scale, 6., iTime/1.5) - .5)*6.2831*2.;
               
                // The precalulated angular noise value. Equivalent to the line above. 
                float a = texture(iChannel0, ((ip + o)/scale) + .0).x;
                
                // The length of the direction vector needs to be such that the total
                // lines drawn don't exceed the NxN grid area boundaries.
                const float rl = 3.5/6.; // 3.5/float(lNum);
                
                // Standard way to take an angle and convert it to a direction vector.
                vec2 r = vec2(cos(a), sin(a))*rl;


                // Drawing a line from one point to the next point in the segment. By the way, lines
                // aren't mandatory. You could draw points, and so forth.
                float l = distLine(o - p, o + r - p);
                //float l = (dot(o - p, o - p))*2.;
                //float l = distLine(o - p, o + r - p);
                //float l = length(o + r/2. - p) - .1;

                l = (1. - smoothstep(0., .0045/scSizeFactor, (l - .005)/scale));
                //l = max(1. - l*4., 0.)*1.; // Alternate.
                
                // The "alpha*(1. - alpha)" is a weighted distribution trick that I'd forgotten about.
                // You'll see IQ use it when he's layering things. You can also square the term. Anyway,
                // it's not mandatory. Something like "alpha*.2" would work, but it tends to layer things 
                // in a less nice way, whereas weighted distribution layering alleviates the subtle grid
                // marks.
                l *= alpha*(1. - alpha)*.8;
                //l *= alpha*.25;


                // Max blend. No join marks with overlapping line segments. Some texture coloring
                // is applied as well.
                col2 = max(col2, tx*l);
                
                // Additive blend. You can see the overlapping joins when using this method...
                // which might be preferable, in some cases.
                //col2 += vec3(l)*tx*.8;

                
                // Advance the line position by the angular direction ray.
                o += r;
                
                // Falloff with increasing strand length. 
                alpha -= 1./6.; // Hardcoding "1./float(sNum);"
                
                
            }
            
            // How you blend the layers is up to you. I'm using a simple additive blend here, but
            // max, screen, mixes, etc, are possible.
            col += col2;
            
            // Layer mix. A little cleaner, but less vibrant.
            //col = mix(col, vec3(1), col2);
             
            // Early pixel color threshold exit, if prefered, but I want more prominence in 
            // the streaks.
            //if (col.x>=1.) break;

    	}
    }
    
    // Very basic postprocessing.
    //col += vec3(.03, .01, 0);
    //col = pow(col, vec3(1.2))*1.2; // Vibrance.
    // Toning down the highlights by just a touch.
    //col = mix(col, 1. - exp(-col), .5);
    
    // Greyscale.
    //col = vec3(1)*dot(col, vec3(.299, .587, .114));
    
 
    // Approximate gamma correction. Every now and again, someone will post a quick example explaining
    // why this is necessary. If you don't know why, then I'd highly recommend reading up on it.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
    
}