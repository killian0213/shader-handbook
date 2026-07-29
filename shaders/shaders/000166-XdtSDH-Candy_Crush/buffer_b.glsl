// Buf B (buffer) — Candy Crush by ciberxtrem
// https://www.shadertoy.com/view/XdtSDH

// Every pixel will calculate the number of adjacent cells of same type in Horizontal and Vertical

const float xCells = 10.;
const float yCells = 8.;
vec4 mCellId    = vec4(0.,    0.,     xCells, yCells);
vec4 mCellPos   = vec4(0.,    yCells, xCells, yCells);

float IsInside(vec2 memPos, in vec2 fragCoord)
{
    vec2 res = abs(fragCoord -0.5 -memPos) -0.5; return -max(res.x, res.y);
}
void Save(vec2 memPos, vec4 value, in vec2 fragCoord, inout vec4 fragColor)
{
    fragColor = IsInside(memPos, fragCoord) > 0.0 ? value : fragColor;
}
vec4 Load(vec2 memPos, sampler2D sampler, vec2 resolution)
{
    return texture(sampler, (memPos+0.5)/resolution, -100.);
}

float FindCells(vec2 myCellId, float myCellType, vec2 dir, inout vec2 hmin, inout vec2 hmax)
{
    float numCells = 0.;
    for(float i=0.; i<8.;++i)
    {
        vec2 id = floor(myCellId.xy+dir*i);
        vec4 currCellData = Load(mCellId.xy+id, iChannel0, iChannelResolution[0].xy);
        if( min(id.x, id.y) < -0.5 || id.x >= xCells || id.y >= yCells || abs(currCellData.z-myCellType) > 0.5)
        {
            break;
        }
        numCells++;
        hmin = min(hmin, id);
        hmax = max(hmax, id);
    }
    return max(numCells-1., 0.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //if(fragCoord.x > xCells+1. || fragCoord.y > yCells+1.) return;
    
    vec2 myCellId = floor(fragCoord);
    
    vec4 myCellIdData = Load(mCellId.xy+myCellId, iChannel0, iChannelResolution[0].xy);
    vec4 myCurrCellIdPos = Load(mCellPos.xy+myCellId, iChannel0, iChannelResolution[0].xy);
    
    // Search for same cells in horizontal
    vec2 hmin = vec2(99., 99.);
    vec2 hmax = vec2(-99., -99.);
    float numCellsX = 0.;
    numCellsX  = FindCells(myCellId, myCellIdData.z, vec2(-1., 0.), hmin, hmax);
    numCellsX += FindCells(myCellId, myCellIdData.z, vec2(1., 0.), hmin, hmax);
    numCellsX = sign(max(numCellsX-1.5, 0.));
    hmin *= numCellsX;
    hmax *= numCellsX;
    
    // Search for same cells in vertical
    vec2 vmin = vec2(99., 99.);
    vec2 vmax = vec2(-99., -99.);
    float numCellsY = 0.;
    numCellsY  = FindCells(myCellId, myCellIdData.z, vec2(0., -1.), vmin, vmax);
    numCellsY += FindCells(myCellId, myCellIdData.z, vec2(0., 1.), vmin, vmax);
    numCellsY = sign(max(numCellsY-1.5, 0.));
    vmin *= numCellsY;
    vmax *= numCellsY;

    float ymax = -99.;
    float ymin = 99.;
    vec2 hdir = abs(hmax-hmin); 
    float hcells = max(hdir.x, hdir.y);
    if(hcells > 0.5) { ymin = hmin.y; ymax = hmax.y; }
    
    vec2 vdir = abs(vmax-vmin);
    float vCells = max(vdir.x, vdir.y);
    if(vCells > 0.5) { ymin = min(ymin, vmin.y); ymax = max(ymax, vmax.y); }
    
    fragColor = vec4(hcells+vCells, ymin, ymax, 0.);
}