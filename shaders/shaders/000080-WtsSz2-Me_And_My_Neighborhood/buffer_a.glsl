// Buffer A (buffer) — Me And My Neighborhood by wyatt
// https://www.shadertoy.com/view/WtsSz2

// wyattflanders.com/MeAndMyNeighborhood.pdf

#define LOOKUP(COORD) texture(iChannel0,(COORD)/iResolution.xy)

vec4 Field (vec2 position) {
    // Rule 1 : All My Energy transates with my ordered Energy
    vec2 velocityGuess = LOOKUP (position).xy;
    vec2 positionGuess = position - velocityGuess;
	return LOOKUP (positionGuess);
}


void mainImage( out vec4 Energy, in vec2 Me )
{
    Energy  =  Field(Me);
    // Neighborhood :
    vec4 pX  =  Field(Me + vec2(1,0));
    vec4 pY  =  Field(Me + vec2(0,1));
    vec4 nX  =  Field(Me - vec2(1,0));
    vec4 nY  =  Field(Me - vec2(0,1));
    
    // Rule 2 : Disordered Energy diffuses completely :
    Energy.b = (pX.b + pY.b + nX.b + nY.b)/4.0;
    
    // Rule 3 : Order in the disordered Energy creates Order :
    vec2 Force;
    Force.x = nX.b - pX.b;
    Force.y = nY.b - pY.b;
    Energy.xy += Force/4.0;
    
    // Rule 4 : Disorder in the ordered Energy creates Disorder :
    Energy.b += (nX.x - pX.x + nY.y - pY.y)/4.;
    
    // Gravity effect :
    Energy.y -= Energy.w/300.0;
    
    // Mass concervation :
    Energy.w += (nX.x*nX.w-pX.x*pX.w+nY.y*nY.w-pY.y*pY.w)/4.;
    
    //Boundary conditions :
    if(Me.x<10.||Me.y<10.||iResolution.x-Me.x<10.||iResolution.y-Me.y<10.)
    {
    	Energy.xy *= 0.;
    }
    
    // Mouse input  :  
    if (iMouse.z > 0. && length(Me-iMouse.xy) < 10.) {
        Energy.w = 1.;
    }
}