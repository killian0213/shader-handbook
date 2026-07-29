// Image (image) — Spatial Decorrelation by rory618
// https://www.shadertoy.com/view/WsfXzs

//Deterministic particle sorting algorithm
//using 7 stage 3x3 strided sorting stages split over 2 frames, in total just 36 or 27 calls to texelFetch per frame
//Non recurrent, each frame is computed independent of the last, particles can jump around quickly with no adverse effects
//Running at half speed, takes two frames to draw the image. I'm starting to like this approach, d 30 fps on shadertoy
//feels a lot more than twice as powerful.
//All that is done is getting particles to the closest pixel.
//Particles affecting more than a single pixel are out of scope here for now.

//Still no gaurentee that a pixel doesnt come up empty when there is a particle there, but chances of that happening
//are reduced compared to previous approaches

//See https://www.shadertoy.com/view/XsjyRm for another use of strided sort

//Sampling over a deterministic constant grid is cheaper than the random normal sampling done in stochastic routing, and
//also gaurentees no collisions and complete coverage if designed using a proper Hierarchical tree.
//The downside is that if you are only saving a finite number of particles per buffer cell (updated to save list of two)
//then some particles will get booted by other nearby ones and end up not getting drawn. giving sohttps://www.shadertoy.com/newme pretty visible artifacts.
//Stochastic routing has the same problem, but because there is no structure with hard edges, the artifacts end up looking
//like some very nice shading. The effect is most objious here:
//Web of lines: https://www.shadertoy.com/view/ldcBz4
//There is no shading done here, all the shadows are just these artifacts. Looks nice but not a good thing in general

//So what is the simple solution? Spatial decorrelation
//The problem only comes up when particles are clumped i.e. they are not sparse in the space that the serach is happening in.
//But the screen space and the search space dont actually need to be the same space at all! For example the search space could be
//a long one dimensional line. First map each pixel on the screen to the line, and map each particle xy to the index on the line it
//should reach. The do one dimensional particle sorting to get the particles along the line. Finally for each screen xy pixel,
//map that xy to the point on the line and splat the particle located there. Since shadertoy buffers are 2d, I still use a 2d search
//space for convinience. (would a 1d search be faster? what about 3d?) The mapping is completely pseudorandom and one to one, so the
//particles get completely scrambled all across. A particle might barely move at all but end up jumping from one side of buffer D all
//the way to the other. Now with the particles scrambled, sparsity is restored in almost all of cases. Now the worst case is no longer
//A bunch of particles nearby, but a bunch of particles precisely arranged so that the random mapping brings them close together,
//which is exceptionally unlikely, and will have little visual effect since they would have to be evenly spread out across the screen
//in order to map to nearby points.


//Research:
//Use hilbert curve instead?
//Good result from google search of "Spatial Decorrelation"
//https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=722032
//Why isn't it perfect? Good to know this to get farther, is it a suboptimal mapping?
//Or is it a must to start saving more than one particle per texel
//Ultimate goal is R.x*R.y pixels with zero chance of an empty pixel
//where a particle should be, which is definately acheivable, at worst use more intermediate frames per rendered frame
//that is still far easier than drawing every particle which seems to
//have a pretty awful worst case, every particle in the exact same location
//and the render pass for that texel must take care of all of them. I
//don't plan on tackling that because I don't see an application where I
//would want to draw that many particles in one spot anyways.


//Rendering in buf A
void mainImage( out vec4 O, in vec2 I )
{
    #define T(a,b) texelFetch(iChannel0, ivec2(I)+ivec2(a,b),0).wwww
    //Soften with a little blur over space
    O=T(0,0)/2.+(T(1,0)+T(0,1)+T(-1,0)+T(0,-1))/12.+(T(1,1)+T(1,-1)+T(-1,-1)+T(-1,1))/24.;
}