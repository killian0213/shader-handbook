// Buf A (buffer) — Minesweeper Game by demofox
// https://www.shadertoy.com/view/XdK3zz

// the size in X and Y of our gameplay grid
const float c_gridSize = 16.0;
const float c_maxGridCell = c_gridSize - 1.0;
const float c_numBombs = 32.0;  // on average, this many bombs will show up. could be more or less though.
const int c_gridChecksPerFrame = 16;

// The grid representing the board
// x = revealed (1.0) or not (0.0)
// y = how many bombs are near it 0 to 8, normalized to 0..1
// z = is a bomb (1.0) or not a bomb (0.0)
// w = is a flag (1.0) or not a flag (0.0)
const vec4 txCells = vec4(0.0, 0.0, c_gridSize - 1.0, c_gridSize - 1.0);

// other variables
const vec2 txState = vec2(2.0, c_gridSize);
// x = state.
// y = mouse button down last frame.
// z,w = last cell checked for victory

// keys
const float KEY_SPACE = 32.5/256.0;
const float KEY_F = 70.5/256.0;

//============================================================

// save/load code from IQ's shader: https://www.shadertoy.com/view/MddGzf

float isInside( vec2 p, vec2 c ) { vec2 d = abs(p-0.5-c) - 0.5; return -max(d.x,d.y); }
float isInside( vec2 p, vec4 c ) { vec2 d = abs(p-0.5-c.xy-c.zw*0.5) - 0.5*c.zw - 0.5; return -max(d.x,d.y); }

vec4 loadValue( in vec2 re )
{
    return texture( iChannel0, (0.5+re) / iChannelResolution[0].xy, -100.0 );
}

void storeValue( in vec2 re, in vec4 va, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( isInside(fragCoord,re) > 0.0 ) ? va : fragColor;
}

void storeValue( in vec4 re, in vec4 va, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( isInside(fragCoord,re) > 0.0 ) ? va : fragColor;
}

//============================================================
float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

//============================================================
void PixelToCell (in vec2 fragCoord, out vec2 uv, out vec2 cell, out vec2 cellFract)
{
    float aspectRatio = iResolution.x / iResolution.y;
    uv = ((fragCoord.xy / iResolution.xy)  - vec2(0.25,0.05)) * 1.1;
    uv.x *= aspectRatio;
    cell = floor(uv * c_gridSize);
    cellFract = fract(uv * c_gridSize);
}

//============================================================
vec4 GetCellData (in vec2 cell)
{
    if (cell.x >= 0.0 && cell.y >= 0.0 && cell.x <= c_maxGridCell && cell.y <= c_maxGridCell)
        return texture( iChannel0, (cell + 0.5) / iChannelResolution[0].xy, -100.0 );
    else
        return vec4(0.0);
}

//============================================================
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    if (fragCoord.x > c_gridSize || fragCoord.y > c_gridSize + 1.0)
        discard;
    
    //----- Load State -----
    vec2 cell     = floor(fragCoord);  
    
    vec4 state    = loadValue(txState);
    vec4 cellData = GetCellData(cell);//loadValue(fragCoord.xy-0.5);
    
    // calculate the cell to check, from state.zw
    vec2 cellCheck = floor(state.zw * c_maxGridCell);
    
    // get the neighboring cell data
    vec4 cellDataUL = GetCellData(cell + vec2(-1.0,  1.0));
    vec4 cellDataU  = GetCellData(cell + vec2( 0.0,  1.0));
    vec4 cellDataUR = GetCellData(cell + vec2( 1.0,  1.0));
    vec4 cellDataR  = GetCellData(cell + vec2( 1.0,  0.0));
    vec4 cellDataDR = GetCellData(cell + vec2( 1.0, -1.0));
    vec4 cellDataD  = GetCellData(cell + vec2( 0.0, -1.0));
    vec4 cellDataDL = GetCellData(cell + vec2(-1.0, -1.0));
    vec4 cellDataL  = GetCellData(cell + vec2(-1.0,  0.0));     
    
    // calculate where the mouse is
    vec2 mouseUv, mouseCell, mouseCellFract;
    PixelToCell(iMouse.xy, mouseUv, mouseCell, mouseCellFract);   
    
    // reset game state on first frame
    if (iFrame == 0)
        state = vec4(0.0);
    
    // state .0 -> reset game state
    if (state.x < 0.1)
    {
        state.x = 0.1;
        state.y = 0.0;
        state.zw = vec2(0.0);
        
        // initialize all grid cells to unrevealed, zero neighbor bombs, not a bomb
        cellData = vec4(0.0);
        
        // random up some bombs!
        if (rand(cell+iTime) < c_numBombs / (c_gridSize*c_gridSize))
            cellData.z = 1.0;
    }
   	// state .1 -> set neighbor counts on grid
    else if (state.x < 0.2)
    {
        state.x = 0.2;
        float neighborBombs = 
            (cellDataUL.z > 0.0 ? 1.0 : 0.0) +
            (cellDataU.z  > 0.0 ? 1.0 : 0.0) +
            (cellDataUR.z > 0.0 ? 1.0 : 0.0) +
            (cellDataR.z  > 0.0 ? 1.0 : 0.0) +
            (cellDataDR.z > 0.0 ? 1.0 : 0.0) +
            (cellDataD.z  > 0.0 ? 1.0 : 0.0) +
            (cellDataDL.z > 0.0 ? 1.0 : 0.0) +
            (cellDataL.z  > 0.0 ? 1.0 : 0.0);
        
        cellData.y = neighborBombs / 8.0;
        
        // DEBUG: visualize the numbers by uncommenting this
		//cellData.y = clamp(cell.x / 8.0, 0.0, 1.0);
    }
   	// state .2 -> we are playing!
    else if (state.x < 0.3)
    {
        // if the mouse is down, remember that it is
        if (iMouse.z > 0.0)
        {
            state.y = 1.0;     
        }
        // if it isn't down, it might have been last frame
        else
        {
            // if the mouse was down last frame, we need to see about revealing a cell
            // also remember that the mouse is not down now
            if (state.y == 1.0)
            {
                // get the data for the cell under the mouse
                vec4 mouseCellData = GetCellData(mouseCell); 
                                    
                // if the user is pressing shift, they want to flag this cell
                if (texture( iChannel1, vec2(KEY_F,0.25) ).x == 1.0)
                {
                    // toggle the cell as flagged
                    if (cell == mouseCell)
                        cellData.w = 1.0 - cellData.w;
                }
                // else if they want to reveal it and it isn't flagged (protect user)
                else if (mouseCellData.w < 1.0)
                {
                    // reveal the cell
                    if (cell == mouseCell)
                        cellData.x = 1.0;

                    // if they clicked on a bomb, die
                    if (mouseCellData.z == 1.0)
                        state.x = 0.3;                 
                }                
                
                state.y = 0.0;
            }
        }
        
        // if the current cell we are processing is unrevealed
        // and there are neighbors which have zero bomb neighbors but are revealed, reveal this
        // cell too.
        if (cellData.x == 0.0)
        {
            // if any of the neighbors are revealed zeros, then reveal this cell
            if ((cellDataUL.x == 1.0 && cellDataUL.y == 0.0) ||
                (cellDataU.x  == 1.0 && cellDataU.y  == 0.0) ||
                (cellDataUR.x == 1.0 && cellDataUR.y == 0.0) ||
                (cellDataR.x  == 1.0 && cellDataR.y  == 0.0) ||
                (cellDataDR.x == 1.0 && cellDataDR.y == 0.0) ||
                (cellDataD.x  == 1.0 && cellDataD.y  == 0.0) ||
                (cellDataDL.x == 1.0 && cellDataDL.y == 0.0) ||
                (cellDataL.x  == 1.0 && cellDataL.y  == 0.0))
            {
                cellData.x = 1.0;
            }
        }
        
        // check for victory by scanning cells to find any unrevealed cells that aren't bombs.
        for (int i = 0; i < c_gridChecksPerFrame; ++i)
        {
            if (cellCheck.x == c_maxGridCell)
            {
                cellCheck.x = 0.0;
                if (cellCheck.y == c_maxGridCell)
                {
                    // Victory!
                    cellCheck.y = 0.0;
                    state.x = 0.4;
                    break;
                }
                else
                {
                    cellCheck.y = cellCheck.y + 1.0;
                }
            }
            else
            {
                cellCheck.x = cellCheck.x + 1.0;
            }

            // if the cell we are checking is unrevealed, and not a bomb, start our scan over, they haven't won yet.
            vec4 cellCheckData = GetCellData(cellCheck);
            if (cellCheckData.x == 0.0 && cellCheckData.z == 0.0)
            {
                cellCheck = vec2(0.0);
                break;
            }
        }
        
    }
   	// state .3 -> we lost
	// state .4 -> we won
    else
    {
        // reset when user presses space
        if (texture( iChannel1, vec2(KEY_SPACE,0.25) ).x == 1.0)
        	state.x = 0.0; 
    }
            
	// convert cellCheck back into state.zw
    state.zw = cellCheck / c_maxGridCell;
    
    //----- Save State -----
    fragColor = vec4(0.0);
    storeValue(txState, state   , fragColor, fragCoord);
    storeValue(txCells, cellData, fragColor, fragCoord);
}
