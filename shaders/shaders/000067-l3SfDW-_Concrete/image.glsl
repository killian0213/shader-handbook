// Image (image) —  Concrete by kishimisu
// https://www.shadertoy.com/view/l3SfDW

/*
    A path-traced infinite complex made of concrete, inspired by brutalist architecture.
    
      > Add some fantasy with the mouse!
      
    In order to increase performance while doing many samples per frame, I tried to
    only compute the scene intersection once with a larger number of iterations.
    Each of the following sample then starts bouncing from this intersection 
    with a random direction and a lower number of iterations.
    
    This avoid computing the first ray for each sample as it's always the same and 
    improves fps quite a lot when increasing the quality.
*/

void mainImage(out vec4 O, vec2 F) 
{
    O = texture(iChannel0, F/iResolution.xy);
    O = pow(O, vec4(.45));
}