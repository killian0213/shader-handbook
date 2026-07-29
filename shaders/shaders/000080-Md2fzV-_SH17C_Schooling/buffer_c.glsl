// Buf C (buffer) — [SH17C] Schooling by P_Malin
// https://www.shadertoy.com/view/Md2fzV

// Grid insertion
// Add boids to grid to speed up rendering


#define iChannelUI iChannel0
#define iChannelSim iChannel1

// ---------------------- 8< --------------------- 8< --------------------------

///////////////////////////
// UI Data
///////////////////////////

float UI_GetFloat( int iData )
{
    return texelFetch( iChannelUI, ivec2(iData,0), 0 ).x;
}

bool UI_GetBool( int iData )
{
    return UI_GetFloat( iData ) > 0.5;
}

vec3 UI_GetColor( int iData )
{
    return texelFetch( iChannelUI, ivec2(iData,0), 0 ).rgb;
}


void UI_Compose( vec2 fragCoord, inout vec3 vColor, out int windowId, out vec2 vWindowCoord )
{
    vec4 vUISample = texelFetch( iChannelUI, ivec2(fragCoord), 0 );
    
    if ( fragCoord.y < 2.0 )
    {
        // Hide data
        vUISample = vec4(1.0, 1.0, 1.0, 1.0);
    }
    
    vColor.rgb = vColor.rgb * (1.0f - vUISample.w) + vUISample.rgb;
    
    windowId = -1;
    vWindowCoord = vec2(0);
    
    if ( vUISample.a < 0.0 )
    {
        vWindowCoord = vUISample.rg;
        windowId = int(round(vUISample.b));
    }
}

///////////////////////////
// UI Data Definitions
///////////////////////////

// ---------------------- 8< --------------------- 8< --------------------------

const int
     DATA_UICONTEXT						= 0
	,DATA_WINDOW_CONTROLS   			= 2
    ,DATA_PAGE_NO						= 4
    ,DATA_FADE							= 5
	,DATA_SEPARATION					= 6
	,DATA_COHESION						= 7
	,DATA_ALIGNMENT						= 8
    ,DATA_COUNT							= 9
    ,DATA_WALLS 						= 10
    ;    

// ---------------------- 8< --------------------- 8< --------------------------






///////////////////////////
// Common Code
///////////////////////////

// -------------- 8< -------------- 8< -------------- 8< -------------- 8< -------------- 8< --------------

///////////////////////////
// Data Storage
///////////////////////////

vec4 LoadVec4( sampler2D sampler, in ivec2 vAddr )
{
    return texelFetch( sampler, vAddr, 0 );
}

vec3 LoadVec3( sampler2D sampler, in ivec2 vAddr )
{
    return LoadVec4( sampler, vAddr ).xyz;
}

bool AtAddress( ivec2 p, ivec2 c ) { return all( equal( p, c ) ); }

void StoreVec4( in ivec2 vAddr, in vec4 vValue, inout vec4 fragColor, in ivec2 fragCoord )
{
    fragColor = AtAddress( fragCoord, vAddr ) ? vValue : fragColor;
}

void StoreVec3( in ivec2 vAddr, in vec3 vValue, inout vec4 fragColor, in ivec2 fragCoord )
{
    StoreVec4( vAddr, vec4( vValue, 0.0 ), fragColor, fragCoord);
}

///////////////////////////
// Hash generation
///////////////////////////

// From Hash without Sine - by Dave Hoskins: https://www.shadertoy.com/view/4djSRW

#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(1031, .1030, .0973, .1099)

//----------------------------------------------------------------------------------------
//  3 out, 1 in...
vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * HASHSCALE3);
   p3 += dot(p3, p3.yzx+19.19);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}


// -------------- 8< -------------- 8< -------------- 8< -------------- 8< -------------- 8< --------------

const int MAX_BOID_COUNT = 400;
const vec3 WORLD_SIZE = vec3( 10 );
const ivec2 GRID_SIZE = ivec2( 100 );

float Scene_Distance( vec3 vPos )
{
    float fDist = 1000.0;
    
    float fInset = 0.3;
    
    // walls
    fDist = min( fDist, vPos.x - fInset );
    fDist = min( fDist, WORLD_SIZE.x - fInset - vPos.x );
    fDist = min( fDist, vPos.z - fInset );
    fDist = min( fDist, WORLD_SIZE.z - fInset - vPos.z );
    
    {
        vec3 vRockPos = vec3(4, 0, 2);    
        float fRockSize = 1.0;
        float fRockDist = length( vPos - vRockPos ) - fRockSize;
        fDist = min( fDist, fRockDist );
    }

    {
        vec3 vRockPos = vec3(8, 0, 4);    
        float fRockSize = 0.4;
        float fRockDist = length( vPos - vRockPos ) - fRockSize;
        fDist = min( fDist, fRockDist );
    }

    {
        vec3 vRockPos = vec3(3, 0, 6);    
        float fRockSize = 1.5;
        float fRockDist = length( vPos - vRockPos ) - fRockSize;
        fDist = min( fDist, fRockDist );
    }
    
    return fDist + sin(vPos.x * 3.0) * 0.1 + sin(vPos.z * 3.0) * 0.1;
}

vec3 Scene_Normal( vec3 vPos )
{
    const float fDelta = 0.0001;
    vec2 e = vec2( -1, 1 );
    
    vec3 vNormal = 
        Scene_Distance( e.yxx * fDelta + vPos ) * e.yxx + 
        Scene_Distance( e.xxy * fDelta + vPos ) * e.xxy + 
        Scene_Distance( e.xyx * fDelta + vPos ) * e.xyx + 
        Scene_Distance( e.yyy * fDelta + vPos ) * e.yyy;
    
    return normalize( vNormal );
}  

struct Boid
{
    vec3 vPos;
    vec3 vVel;
    
    vec3 vCohesionCentre; 	// only used for visualization
    vec3 vSeparationSteer;	// only used for visualization
    vec3 vAlignmentDir; 	// only used for visualization
};
    

Boid LoadBoid( int index )
{
    Boid boid;
    boid.vPos = LoadVec3( iChannelSim, ivec2(index, 0) );    
    boid.vVel = LoadVec3( iChannelSim, ivec2(index, 1) );    
    boid.vCohesionCentre = LoadVec3( iChannelSim, ivec2(index, 2) );    
    boid.vSeparationSteer = LoadVec3( iChannelSim, ivec2(index, 3) );    
    boid.vAlignmentDir = LoadVec3( iChannelSim, ivec2(index, 4) );    
    
    return boid;
}

void StoreBoid( int index, Boid boid, inout vec4 fragColor, ivec2 fragCoord )
{
    StoreVec3( ivec2( index, 0), boid.vPos, fragColor, fragCoord );
    StoreVec3( ivec2( index, 1), boid.vVel, fragColor, fragCoord );
    StoreVec3( ivec2( index, 2), boid.vCohesionCentre, fragColor, fragCoord );
    StoreVec3( ivec2( index, 3), boid.vSeparationSteer, fragColor, fragCoord );
    StoreVec3( ivec2( index, 4), boid.vAlignmentDir, fragColor, fragCoord );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 iFragIndex = ivec2(fragCoord);
    ivec2 iGridPos = iFragIndex;
    
    if ( any( greaterThanEqual( iGridPos, GRID_SIZE ) ) )
    {
        discard;
        return;
    }

    // get centre of grid cell
    vec2 cellCentre = ((vec2(iGridPos) + 0.5) / vec2(GRID_SIZE)) * WORLD_SIZE.xz;
    
    vec2 vCellSize = WORLD_SIZE.xz / vec2(GRID_SIZE);
    float cellSize = sqrt(dot(vCellSize,vCellSize)) + 0.1;
    
    const int MAX_BOIDS_PER_CELL = 4;
    int cellBoids[MAX_BOIDS_PER_CELL];
    
    cellBoids[0] = -1;
    cellBoids[1] = -1;
    cellBoids[2] = -1;
    cellBoids[3] = -1;
    
    int cellBoidCount = 0;
    
    float boidCount = UI_GetFloat( DATA_COUNT );
    
    for ( int index = 0; index < MAX_BOID_COUNT; index++ )
    {
        if ( index >= int(boidCount) )
        {
            break;
        }
        
        if( cellBoidCount >= MAX_BOIDS_PER_CELL )
        {
            break;
        }
        
        Boid currBoid = LoadBoid( index );

        vec2 vOffset = currBoid.vPos.xz - cellCentre;
        vOffset += WORLD_SIZE.xz / 2.0;
        vOffset = mod(vOffset, WORLD_SIZE.xz);
        vOffset -= WORLD_SIZE.xz / 2.0;
        
        float dist = length( vOffset );
        if ( dist < cellSize )
        {
            cellBoids[cellBoidCount] = index;
            cellBoidCount++;
        }
        
    }    
    
    fragColor = vec4( cellBoids[0], cellBoids[1], cellBoids[2], cellBoids[3] );
}
