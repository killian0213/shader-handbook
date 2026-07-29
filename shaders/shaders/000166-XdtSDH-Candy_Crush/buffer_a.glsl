// Buf A (buffer) — Candy Crush by ciberxtrem
// https://www.shadertoy.com/view/XdtSDH

// Game Logic

const float xCells = 10.;
const float yCells = 8.;
const vec2 cellSize = vec2(0.5);
const vec2 gridPos = vec2(6.315, 0.8);

float gT;
vec4 mCellId    = vec4(0.,    0.,     xCells, yCells);
vec4 mCellPos   = vec4(0.,    yCells, xCells, yCells);
vec2 mState     = vec2(0., 2.*yCells);
vec2 mSelected0 = vec2(1., 2.*yCells);
vec2 mSelected1 = vec2(2., 2.*yCells);
vec2 mMouse     = vec2(3., 2.*yCells);
vec2 mLerp      = vec2(4., 2.*yCells);

vec2 gFragCoord;
vec4 gFragColor;
vec4 gLerp;

float hash(float x) { return fract(sin(x)*15.4); }

float dsCell(vec2 p)
{
    return length(max(abs(p)-cellSize, 0.)) - 0.075;
}

float IsInside(vec2 memPos)
{
    vec2 res = abs(gFragCoord -0.5 -memPos) -0.5; return -max(res.x, res.y);
}
void Save(vec2 memPos, vec4 value)
{
    gFragColor = IsInside(memPos) > 0.0 ? value : gFragColor;
}

float IsInside(vec4 memPos)
{
    vec2 res = abs(gFragCoord -0.5 -memPos.xy -memPos.zw*0.5) -memPos.zw*0.5 -0.5; return -max(res.x, res.y);
}
void Save(vec4 memPos, vec4 value)
{
    gFragColor = IsInside(memPos) > 0.0 ? value : gFragColor;
}

vec4 Load(vec2 memPos, sampler2D sampler, vec2 resolution)
{
    return texture(sampler, (memPos+0.5)/resolution, -100.);
}

vec2 GetCellPos(vec2 cellId)
{
    return gridPos + cellId*1.2;
    //return cellId;
}

float IsSameCell(vec2 a, vec2 b)
{
    vec2 dir = b-a;
    return dot(dir, dir) < 1e-3 ? 1. : 0.;
}

float LerpEaseOutBounce(float t, float b, float c, float d)
{
    if ((t/=d) < (1./2.75)) {
			return c*(7.5625*t*t) + b;
		} else if (t < (2./2.75)) {
			return c*(7.5625*(t-=(1.5/2.75))*t + .75) + b;
		} else if (t < (2.5/2.75)) {
			return c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b;
		} else {
			return c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b;
		}
}

void DoMove()
{
    for(float y=0.; y<yCells-0.5;++y) {
        for(float x=0.; x<xCells-0.5;++x) {
            if(IsInside(mCellId.xy+vec2(x, y)) > 0.)
            {
                vec4 cellId  = Load(mCellId.xy+vec2(x,y), iChannel0, iChannelResolution[0].xy);
                vec4 cellPos = Load(mCellPos.xy+vec2(x,y), iChannel0, iChannelResolution[0].xy);

                float t = clamp((gT-cellPos.z)/cellPos.w, 0., 1.);
                t = mix(smoothstep(0., 1., pow(t, 0.5)), LerpEaseOutBounce(t, 0., 1., 1.), step(0.5, gLerp.z));
                cellId.xy = mix(cellPos.xy, GetCellPos(vec2(x, y)), t);
                Save(mCellId, cellId);
            }
        }
    }
}

void Switch(vec2 selected0, vec2 selected1, float duration)
{
    vec4 cellId0 = Load(mCellId.xy+selected0.xy, iChannel0, iChannelResolution[0].xy);
    vec4 cellId1 = Load(mCellId.xy+selected1.xy, iChannel0, iChannelResolution[0].xy);

    if(IsInside(mCellId.xy+selected0.xy) > 0.)
    {
        vec4 cellId = cellId1;
        Save(mCellId, cellId);
    }
    if(IsInside(mCellPos.xy+selected0.xy) > 0.)
    {
        vec4 cellPos = vec4(cellId1.xy, gT, 0.5);
        Save(mCellPos, cellPos);
    }

    if(IsInside(mCellId.xy+selected1.xy) > 0.)
    {
        vec4 cellId = cellId0;
        Save(mCellId, cellId);
    }
    if(IsInside(mCellPos.xy+selected1.xy) > 0.)
    {
        vec4 cellPos = vec4(cellId0.xy, gT, 0.5);
        Save(mCellPos, cellPos);
    }
}
void DoRefill()
{
    vec2 id = floor(gFragCoord);
    if(gFragCoord.y > yCells) 
    {
        id -= vec2(0., yCells);
    }
    
    float numCells = 0.;
    float dy = 0.;
    for(float y=0.; y<yCells-0.5;++y)
    {
        vec2 currId = vec2(id.x, id.y -y);
        if(currId.y < -0.5) { break; }
        
    	vec4 numCellsData = Load(currId, iChannel2, iChannelResolution[2].xy);
        float cellToRefill = step(1.5, numCellsData.x);
        dy += cellToRefill;
        numCells += cellToRefill;
    }
    
    if(dy < 0.5)
    {
        return;
    }
    
    for(float y=1.; y<yCells-0.5;++y)
    {
        vec2 currId = vec2(id.x, id.y +y);
        if(currId.y > yCells-0.5) { break; }
        if(y -0.5 > dy) { break; }
        
        vec4 numCellsData = Load(currId, iChannel2, iChannelResolution[2].xy);
        dy += step(1.5, numCellsData.x);
    }
    
    float baseDuration = 0.35*dy + 0.35*hash(gT);
    float delay = id.y*0.045 + mod(id.x, 3.)*0.045;

    vec2 sourceId = id;
    vec2 targetId = sourceId + vec2(0., dy);

    vec4 cellId = Load(mCellId.xy+targetId, iChannel0, iChannelResolution[0].xy);
    if(targetId.y > yCells-0.5)
    {
        cellId = vec4(GetCellPos(targetId), floor(hash(iTime+2.+(id.x+13.)*(id.y+25.)*18.)*5.), 1.);
    }
    vec4 cellPos = vec4(cellId.xy, gT+delay, baseDuration);

    Save(mCellId.xy +  sourceId.xy, cellId);
    Save(mCellPos.xy + sourceId.xy, cellPos);
}

void DoKill(float blend)
{
    vec2 id = floor(gFragCoord);
    if(gFragCoord.y > yCells) 
    {
        id -= vec2(0., yCells);
    }
    
    vec4 cellData = Load(id, iChannel2, iChannelResolution[2].xy);
    float numCells = cellData.x;
    
    if(numCells > 1.5)
    {
        vec4 cellId   = Load(mCellId.xy+id, iChannel0, iChannelResolution[0].xy);
        float t = clamp(blend, 0., 1.);
        cellId.w = mix(1.0, 0.0, smoothstep(0., 1., t));
        Save(mCellId, cellId);
    }
}

void CalculateSelectedCells(in vec4 state, in vec4 mouse, inout vec4 selected0, inout vec4 selected1)
{
    if(mouse.w > 0.5 && mouse.z < 0.5 && selected0.z > 0.5)
    {
        for(float y=0.; y<yCells-0.5;++y) {
            for(float x=0.; x<xCells-0.5;++x){
                vec2 cellPos = GetCellPos(vec2(x, y));
                float d = dsCell(mouse.xy-cellPos.xy);
                if(d < 0.) 
                { 
                    selected0.xy = mix(vec2(x,y), selected0.xy, step(0.5, selected0.w));
                    selected1.xy = mix(vec2(x,y), selected1.xy, step(selected0.w, 0.5));
                    selected0.w += 1.;

                    if(selected0.w > 1.5)
                    {
                        vec2 dir = abs(selected1.xy-selected0.xy);
                        if(dir.x+dir.y > 1.5)
                        {
                            selected0 = selected1; selected0.z = 1.0;
                            selected1 = vec4(-100., -100., 1.0, 0.);
                            selected0.w = 1.0;
                        }
                    }
                    break;
                }
            }
        }
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //if(fragCoord.x > xCells+1. || fragCoord.y > 2.*yCells+1.) return;
    
    gT = iTime;
    gFragCoord = fragCoord;
    gFragColor = texture(iChannel0, fragCoord/iResolution.xy, -100.);
    
    vec4 state   = Load(mState, iChannel0, iChannelResolution[0].xy);
    vec4 selected0 = Load(mSelected0, iChannel0, iChannelResolution[0].xy);
    vec4 selected1 = Load(mSelected1, iChannel0, iChannelResolution[0].xy);
    vec4 mouse = Load(mMouse, iChannel0, iChannelResolution[0].xy);
    mouse.xy = 10.*(iMouse.xy/iResolution.y);
    mouse.w = mouse.z;	// was clicked?
    mouse.z = iMouse.z;	// is clicked?
    gLerp = Load(mLerp, iChannel0, iChannelResolution[0].xy);
    
    CalculateSelectedCells(state, mouse, selected0, selected1);
    
    if(iFrame == 0) 
    {
        state = vec4(0.); 
    }
    if(state.x < 0.5)
    {   
        state.z = 0.;
        state.y = floor(20.+hash(gT+3.)*5.);
        state.w = 60.+floor(+hash(gT+4.)*200.);
        selected0 = selected1 = vec4(-100., -100., 0., 0.);
        mouse = vec4(0.);
        gLerp = vec4(0., 0., 1., 0.);
        gLerp.x = gT;
        
        float baseDuration = 0.35*yCells + 0.35*hash(gT);
        //for(float y=0.; y<yCells-0.5;++y) {
            //for(float x=0.; x<xCells-0.5;++x) {
                vec2 currCell = floor(fragCoord);
                float delay = currCell.y*0.045 + mod(currCell.x+xCells*currCell.y+currCell.x, 3.)*0.045 + 4.0*step(float(iFrame), 0.5);
            	gLerp.y = max(gLerp.y, baseDuration + delay);
                
                //if(IsInside(mCellId.xy+currCell) > 0.)
                {
                    vec4 cellId = vec4(GetCellPos(currCell), floor(hash(iTime+2.+(currCell.x+13.)*(currCell.y+25.)*18.)*5.), 1.);
                    Save(mCellId, cellId);
                }
                //if(IsInside(mCellPos.xy+currCell) > 0.)
                {
                    vec4 cellPos = vec4(GetCellPos(currCell+vec2(0.,yCells)), vec2(gT+delay, baseDuration));
                    Save(mCellPos, cellPos);
                }
            //}
        //}
        
        state.x = 1.0;
    }
    else if(state.x < 1.5) // SettingUp
    {
        DoMove();
        if(gT > gLerp.x + gLerp.y)
        {
            state.x = 3.;
        }
    }
    else if(state.x < 2.5) // Idle
    {
        selected0.z = 1.; //allow cell selection
        
        if(selected0.w > 1.5)
        {
            state.x = 3.;
            state.y--;
            gLerp = vec4(gT, 0.5, 0., 0.);
            selected0.z = 0.; // disallow cell selection
            Switch(selected0.xy, selected1.xy, 1.);
        }

    }
    else if(state.x < 3.5) // Switch
    {
        DoMove();
        if(gT > gLerp.x + gLerp.y)
        {
            vec4 gridInfo = Load(vec2(0., 0.), iChannel1, iChannelResolution[1].xy);
            if( gridInfo.x > 1.) // Go to Kill
            {
                state.x = 5.;
                selected0 = selected1 = vec4(-100., -100., 1., 0.);
                gLerp = vec4(gT, 0.5, 0., 0.);
            }
            else // Go to Switch Back
            {
                state.x = 4.;
                gLerp = vec4(gT, 0.5, 0., 0.);
                Switch(selected0.xy, selected1.xy, 1.);
                selected0 = selected1 = vec4(-100., -100., 1., 0.);
            }
        }
    }
    else if(state.x < 4.5) // Switch Back
    {
        DoMove();
        if(gT > gLerp.x + gLerp.y)
        {
        	state.x = 2.;
            state.y++;
        }
    }
    else if(state.x < 5.5) // Killing
    {
        DoKill((gT-gLerp.x)/gLerp.y);
        if(gT > gLerp.x + gLerp.y)
        {
            DoRefill();
            vec4 adjacentData = Load(vec2(0., 0.), iChannel1, iChannelResolution[1].xy);
            float maxDy = adjacentData.w+1.0;
            float maxDuration = 0.5 + 0.35*maxDy + (yCells+3.)*0.045;
            
            gLerp = vec4(gT, maxDuration, 1., 0.);
        	
            // add points
            for(float y=0.; y<yCells-0.5;++y) {
                for(float x=0.; x<xCells-0.5;++x) {
                    vec4 adjacentData = Load(vec2(x, y), iChannel2, iChannelResolution[2].xy);
                    state.z += step(1.5, adjacentData.x); // add points
                }
            }
            state.x = 6.;
        }
    }
    else if(state.x < 6.5) // Refill
    {
        DoMove();
        if(gT > gLerp.x + gLerp.y)
        {
            
            vec4 gridInfo = Load(vec2(0., 0.), iChannel1, iChannelResolution[1].xy);
            if( gridInfo.x > 1.) // Go to Kill
            {
                state.x = 5.;
                gLerp = vec4(gT, 0.5, 0., 0.);
            }
            else
            {
                if(state.y <= 0.)
                {
                    gLerp.x = gT;
                    state.x = 7.;
                }
                else
                {
                    state.x = 2.;
                }
            }
        }
    }
    else if(state.x < 7.5) // Win/Lose
    {
        if(gT > gLerp.x + 3.)
        {
            state.x = 0.;
        }
    }

    Save(mState, state);
    Save(mSelected0, selected0);
    Save(mSelected1, selected1);
    Save(mMouse, mouse);
    Save(mLerp, gLerp);
    
    fragColor = gFragColor;
}
