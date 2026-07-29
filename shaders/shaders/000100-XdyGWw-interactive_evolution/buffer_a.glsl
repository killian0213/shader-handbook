// Buf A (buffer) — interactive evolution by bergi
// https://www.shadertoy.com/view/XdyGWw

/* Interactive Evolutionary Framework - https://www.shadertoy.com/view/XdyGWw
   (c) 0x7e Stefan Berke
   License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

   This buffer renders a set of parameters 
   and applies mutation on mouse-click

   (first two columns of output are used for various flags)
*/

const int NUM_PARAM_ROWS = 1;		// Number of rows of parameters for one 'tile'
const int NUM_TILES = 4;			// Number of 'tiles' per screen height
const int NUM_TILES_ALL = 100;		// for cross-breeding, set this to the maximum
									// number of tiles on screen

const float MUTATION_PROB = .5;		// Probability of mutating one parameter
const float MUTATION_AMT = 0.1; 	// Maximum amount of mutation +/-
const float AV_NUM_PARAMS = 20.;	// Number of parameters for a cross-breed section
									// This is kind of the length of a consecutive section
									// in the gene..

// scales mutation amount by distance to clicked tile
#define DO_SCALE
// define for only positive values 
//#define ABSOLUTE
//#define RANGE_MIN -1.
//#define RANGE_MAX  1.



// hashes by Dave_Hoskins https://www.shadertoy.com/view/4djSRW
float hash(float p)
{
	vec2 p2 = fract(vec2(p * 5.3983, p * 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
	return fract(p2.x * p2.y * 95.4337);
}
float hash(vec2 p)
{
	p  = fract(p * vec2(5.3983, 5.4427));
    p += dot(p.yx, p.xy + vec2(21.5351, 14.3137));
	return fract(p.x * p.y * 95.4337);
}

// uniform random vec4 [-1,1]
// (this is not state-of-the-art hashing)
vec4 rndVec(in vec2 seed)
{
    return vec4(hash(seed), hash(seed+.1283), hash(seed+.7229), hash(seed+.32941)) * 2. - 1.;
}

vec4 clampVec(in vec4 v)
{
#ifdef ABSOLUTE
    v = abs(v);
#endif
#ifdef RANGE_MIN
    v = max(vec4(RANGE_MIN), v);
#endif
#ifdef RANGE_MAX
    v = min(vec4(RANGE_MAX), v);
#endif
  	return v;
}


// returns the parameters for the given 'tile' 
vec4 parameter(in int column, in int row, in int cur_tile) 
{ 
    vec2 uv = (vec2(column+2, row + cur_tile*NUM_PARAM_ROWS)+.5) / iChannelResolution[0].xy;
    return texture(iChannel0, uv);    
}


// sets random parameters
void reset(out vec4 fragColor, in vec2 fragCoord)
{
    if (fragCoord.x >= 1.) // keep ui-states
    {
        // clear flags
        if (fragCoord.x < 2.)
            fragColor = vec4(0.);
        // init randomly
        else
        {
            vec2 seed = fragCoord/1.1 + sin(iDate.zw + float(iFrame)*.1); 
            fragColor = clampVec( rndVec(seed) );    
        }
    }
}

vec4 mutate(in int sel_tile, in vec2 fragCoord)
{
    // init random mutation 
    vec2 seed = fragCoord + sin(iDate.zw);
    vec4 mutate = vec4(0.);

    #ifdef DO_SCALE
    // scale mutation amount by tile distance
    float amt = clamp( abs(float(sel_tile) - fragCoord.y / float(NUM_PARAM_ROWS))
                      / float(NUM_TILES * NUM_TILES), 0.1, 1.);
    #else
    float amt = 1.;
    #endif
    // mutate with probability
    if (hash(seed*0.12345) < MUTATION_PROB * max(.5, amt))
        mutate = MUTATION_AMT * amt * rndVec(seed);

    // copy weights from 'sel_tile' slot to all others + mutation
    return clampVec( parameter(int(fragCoord.x-2.), 
                                   int(mod(fragCoord.y, float(NUM_PARAM_ROWS))), 
                                   sel_tile)
                     + mutate);
}

vec4 crossBreed(in int tile1, in int tile2, in vec2 fragCoord)
{
    ivec2 parVec = ivec2(int(fragCoord.x-2.), 
                         int(mod(fragCoord.y, float(NUM_PARAM_ROWS))));
  	vec4 p1 = parameter(parVec.x, parVec.y, tile1);
    vec4 p2 = parameter(parVec.x, parVec.y, tile2);
    
    vec2 seed = vec2(fragCoord.y) + sin(iDate.zw);
    float freq = 3.14159265 / float(AV_NUM_PARAMS);
    float mx = (.5 + .5 * sin(fragCoord.x*freq + 6.*hash(seed)));
    mx = pow(mx, 1. + 5. * hash(seed.yx*.87));
    mx *= hash(seed*1.31);
    // swap dominant set
    if (hash(seed+mx) > .5)
    	mx = 1.-mx;
    return p1 + mx * (p2 - p1);
}
    

// --- ui state ---

// is the given 'tile' excluded from mutation?
bool isTileLocked(in int cur_tile) 
{
    vec2 uv = (vec2(1, cur_tile * NUM_PARAM_ROWS) + .5) / iChannelResolution[0].xy;
	return texture(iChannel0, uv).x >= .5;
}

int selectedTile()
{
    vec2 uv = (vec2(0., 0.) + .5) / iChannelResolution[0].xy;
	return int(texture(iChannel0, uv).x)-1;
}

float selectionMorph()
{
    vec2 uv = (vec2(0., 2.) + .5) / iChannelResolution[0].xy;
	return texture(iChannel0, uv).x;
}

bool prevMouseDown()
{
    vec2 uv = (vec2(0., 3.) + .5) / iChannelResolution[0].xy;
	return texture(iChannel0, uv).x > .5;
} 

// chooses two random, non-equal, locked tiles
// if none is locked, chooses two random tiles
void selectParents(out int tile1, out int tile2, in vec2 fragCoord)
{
    // count number of locked tiles
    int count = 0;
    for (int i=0; i<NUM_TILES_ALL; ++i)
    {
        bool isLocked = isTileLocked(i);
        if (isLocked)
            ++count;
    }

    vec2 seed = sin(iDate.wz + float(iFrame)*.123 + fragCoord.y);

    if (count < 1)
    {
        tile1 = int(hash(seed) * iResolution.y / float(NUM_PARAM_ROWS));
        tile2 = int(hash(1.-seed*1.11341) * iResolution.y / float(NUM_PARAM_ROWS));
        return;
    }
    
    // choose index of locked tiles
    int tilei1, tilei2;
    if (count == 2)
    {
		tilei1 = 0;
        tilei2 = 1;
    }
    else
    {
        tilei1 = int(hash(seed) * float(count));
        tilei2 = int(hash(seed*1.1311+3.) * float(count));
    }
    
    tile1 = tile2 = -1;
    
    // select locked tiles
	count = 0;
    for (int i=0; i<NUM_TILES_ALL; ++i)
	if (isTileLocked(i))
    {
        if (count == tilei1 && tile1 < 0)
            tile1 = i;
    	if (count++ == tilei2 && tile2 < 0)// || tile2 == tile1)
        	tile2 = i;
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    ivec2 pixpos = ivec2(fragCoord);
    
    // by default, copy previous pixel
    vec4 pix = texture(iChannel0, fragCoord.xy / iChannelResolution[0].xy);
    fragColor = pix;
    
    // currently rendered 'tile' parameters
    int cur_tile = int(fragCoord.y) / NUM_PARAM_ROWS;

	// catch single mouse-down event
	bool mouseDown = false;
    bool prevDown = prevMouseDown();
    if (iMouse.z > .5 && !prevDown)
    {
        mouseDown = true;
        if (pixpos.x == 0 && pixpos.y == 3)
            fragColor.x = 1.;
    }
    else if (iMouse.z < .5 && prevDown)
    {
        if (pixpos.x == 0 && pixpos.y == 3)
            fragColor.x = 0.;
    }

    // init parameters
    if (iFrame < 2)
    {
		reset(fragColor, fragCoord);
    }
	else
        
    // on click
    if (mouseDown && selectedTile() < 0)
    {
        vec2 muv = iMouse.xy / iResolution.y;
        
        // clicked on reset-square?
        if (muv.x < 0.05 && muv.y < 0.05)
        {
            if (!isTileLocked(cur_tile))
            	reset(fragColor, fragCoord);
        }
        // clicked on sex-party square?
        else if (muv.x < 0.1 && muv.y < 0.05)
        {
            if (!isTileLocked(cur_tile) && fragCoord.x >= 2.)
            {
                int tile1, tile2;
                selectParents(tile1, tile2, fragCoord);
                fragColor = crossBreed(tile1, tile2, fragCoord);
            }
        }
        // per tile
        else
        {
            // find 'tile' that was clicked
            float width = iResolution.y / float(NUM_TILES);
            int sel_tile = int(iMouse.y / width)
                         + int(iMouse.x / width) * NUM_TILES;
            // are we rendering the parameters for the clicked tile?
            bool is_this_tile = cur_tile == sel_tile;
            
            vec2 clickuv = vec2(mod(iMouse.x, width) / width, 
                                mod(iMouse.y, width) / width);
            
            // clicked on top bar?
            if (clickuv.y > .85)
            {
                // lock
                if (clickuv.x < .15)
                {                
                    if (pixpos.x == 1 && is_this_tile)
                    {
                        pix.x = 1. - pix.x;
	                    fragColor = pix; 
                    }
                }
                // show
                else if (clickuv.x < .3)
                {
                    if (pixpos.x == 0 && pixpos.y <= 1)
        				fragColor = vec4(float(sel_tile+1));
                }
            }
            
            // mutate
            else
            {
                // don't mutate flags, locked sets or clicked tile
                if (fragCoord.x < 2. || is_this_tile 
                    || isTileLocked(cur_tile))
                {
                    /* fragColor = pix; */
                }
                else
                {
                    fragColor = mutate(sel_tile, fragCoord);
                    //fragColor = crossBreed(sel_tile, 4, fragCoord);
                }
            }
        }
    }
    else
        
    // end selection click
    if (mouseDown && selectedTile() >= 0)
    {
        if (pixpos.x == 0 && pixpos.y == 0)
        {
            fragColor = vec4(0.);
        }
    }
    
    // ui-flags
    else if (pixpos.x == 0)
    {
        // selection fade-in
        if (pixpos.y == 2)
        {
            float on = selectedTile() >= 0 ? 1. : 0.;
            fragColor.x += min(1., 7.*iTimeDelta) * (on - fragColor.x);
        }
    }
}