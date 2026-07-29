// Common (common) — Procedural Swords by SnoopethDuckDuck
// https://www.shadertoy.com/view/slBXWc

// change randStart to generate new "seed"
const float randStart = 123.;

// number of frames each sprite lasts for
const int reset = 120;

const float pi = 3.14519;


// ( resetting dims is buggy - seems fine if new value < old value though,
//   arbitrarily large 500 works fine )

// half gem dimensions 
vec2 dimGem = vec2(500);

// handle dimensions (not half)
vec2 dimHandle = vec2(500);

float hash1( float n )
{
    return fract(sin(n)*138.5453123);
}

// get an index for arrays (not optimal at all)
int randIndex ( int frame, float maxIndex, float offset ) {
    return int(maxIndex * hash1(randStart + offset +  floor(float(frame) / float(reset))));
}

// if you want custom width/height, change the values below
vec2 setDimGem(int frame) {    
    float gen = randStart + floor(float(frame) / float(reset));
    float width = round(3. + 3. * hash1(gen));
    float height = max(2. * width, round(40. * hash1(100. + gen)));
    return dimGem = vec2(width, height);
}

vec2 setDimHandle(int frame) {    
    float gen = randStart + floor(float(frame) / float(reset));
    float width = 2. * round(10. + 8. * hash1(50. + gen));
    float height = 2. * round(14. + 12. * hash1(150. + gen));
    return dimHandle = vec2(width, height);
}

/*

Rough explanation of how this works:

Buffer A: 
Generates hexagon gem in bottom left of screen.
Width, height, top shape and shading are chosen here. (but not color)

Buffer B:
Generates shape of handle in bottom left of screen.
Initial state with noise is generated, then various cellular automata are run on it
to get an appropriate shape.
Width, height of handle are chosen here (sort of).

Buffer C:
Generates mirrored noise to color the handle with.

Image:
Transforms the gem and handle so they are together.
Picks color schemes for the gem outline, gem interior, and handle.
Overlays noise from buffer C onto the handle shape.
Draws a background.

*/