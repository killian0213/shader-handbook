// Buf D (buffer) — [SH17C] Schooling by P_Malin
// https://www.shadertoy.com/view/Md2fzV

// Scene Rendering & Diagrams


#define iChannelUI iChannel0
#define iChannelSim iChannel1
#define iChannelGrid iChannel2


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

struct Boid
{
    vec3 vPos;
    vec3 vVel;
    
    vec3 vCohesionCentre; 	// just used for visualization
    vec3 vSeparationSteer;	// just used for visualization
    vec3 vAlignmentDir; 	// just used for visualization
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

float DrawCircle( vec2 vPos, vec2 vOrigin, float fRadius, float fThickness )
{    
    float fCircleDist = length( vOrigin - vPos ) - fRadius;
    float fCircle = clamp( 1.0 - abs(fCircleDist) / fThickness, 0.0, 1.0 );    
    return fCircle;
}

float DrawLine( vec2 vPos, vec2 vA, vec2 vB, float fThickness )
{    
    vec2 vOffset = vPos- vA;
    vec2 vAB = vB - vA;
    vec2 vDir = normalize( vAB );
    float fLength = length( vAB );
    
    float fProj = clamp( dot( vOffset, vDir ) / fLength, 0.0, 1.0 );
    
    vec2 vClosest = vA + vDir * fProj * fLength;
    
    float fLine = clamp( 1.0 - length( vClosest - vPos ) / fThickness, 0.0, 1.0 );
    return fLine;
}

float DrawArrowhead( vec2 vPos, vec2 vStart, vec2 vDir, float fSize, float fThickness )
{    
    vDir = normalize( vDir );    
    vec2 vPerp = vec2( vDir.y, -vDir.x );
    
    vec2 vEndA = vStart + vDir * fSize + vPerp * fSize * .5;
    vec2 vEndB = vStart + vDir * fSize - vPerp * fSize * .5;
    
    float fArrow = DrawLine( vPos, vStart, vEndA, fThickness );
    fArrow = max( fArrow, DrawLine( vPos, vStart, vEndB, fThickness ) );
    
    return fArrow;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{        
    vec2 vScreenUV = fragCoord.xy / iResolution.xy;
    
    vec3 vResult = mix( vec3(0.5, 0.6, 0.9), vec3(0.25, 0.3, 0.9), vScreenUV.y );

    vec2 vUV  = vScreenUV;
    vUV -= 0.5;
    vUV.x *= iResolution.x / iResolution.y;
    vUV = vUV;
    
    float fZoom = 1.0;
    vec3 vTarget = WORLD_SIZE * 0.5;

    bool bDrawCohesionForce = false;
    bool bDrawSeaparationForce = false;
    bool bDrawAlignmentForce = false;
    
    bool bDrawCollision = false;
    
    float fCircleRadius = 0.0;
    
    float fade = UI_GetFloat(DATA_FADE);
    
    int pageNo = int( UI_GetFloat(DATA_PAGE_NO) );
    int targetBoidIndex = -1;
    
    float fTargetFactor = 0.0;
    
    if ( pageNo == 2 )
    {
        fTargetFactor = 1.0f;//(1.0 - fade);
        targetBoidIndex = 0;
    }
    if ( pageNo == 3 )
    {
        fTargetFactor = 1.0f;//(1.0 - fade);
        targetBoidIndex = 0;
        
        fCircleRadius = 0.75;
    }
    if ( pageNo == 4 )
    {
        bDrawSeaparationForce = true;
        fTargetFactor = 1.0;
        targetBoidIndex = 0;
    }
    if ( pageNo == 5 )
    {
        fTargetFactor = 1.0f;//(1.0 - fade);
        bDrawCohesionForce = true;
        targetBoidIndex = 0;
    }
    if ( pageNo == 6 )
    {
        bDrawAlignmentForce = true;
        fTargetFactor = 1.0;
        targetBoidIndex = 0;
    }
    if ( pageNo == 7 )
    {
        fTargetFactor = 0.0;
    }

    if ( pageNo >= 8 )
    {
        bDrawCollision = UI_GetBool(DATA_WALLS);
    }
    
    Boid targetBoid = LoadBoid( targetBoidIndex );
    if ( fTargetFactor > 0.0 )
    {
        float fTargetFactor2 = smoothstep( 0.0, 1.0, fTargetFactor * 4.0 );
        vec3 vTarget2 = targetBoid.vPos;
        vTarget2.x -= 1.0;
        vTarget2.z += 0.4;
    	vTarget = mix( vTarget, vTarget2, fTargetFactor2 );
        fZoom = 1.0 + smoothstep( 0.0, 1.0, fTargetFactor ) * 3.0;
    }

    
    float fLineThickness = 10.0 / fZoom / iResolution.y;
    float fArrowSize = 0.05;
        
    vec3 vPos = vec3( vUV.x, 0.0, vUV.y ) * WORLD_SIZE;
    
    vPos /= fZoom;
    
    vPos += vTarget;
    vPos.y = 0.0f;
        
    if ( bDrawCollision )
    {
    	float fDist = Scene_Distance( vPos );
        
        if ( fDist < 0.0 )
        {
            float fBlend = smoothstep( 0.0, 1.0, -fDist );
            vResult = mix( vec3(0.4, 0.3, 0.1), vec3(0.2, 0.0, 0.0), fBlend );
        }           
    }
    
    
    vec3 vCircleOrigin = targetBoid.vPos;
    
    vec3 vLineTarget = vec3(0);
    
    if ( bDrawCohesionForce )
    {
    	vLineTarget = targetBoid.vCohesionCentre;
        fCircleRadius = 0.75;
    }
    
    if ( bDrawSeaparationForce )
    {
    	vLineTarget = targetBoid.vPos;
        fCircleRadius = 0.75;
    }
    
    if ( bDrawAlignmentForce )
    {
    	vLineTarget = targetBoid.vPos;
        fCircleRadius = 0.75;
    }
    
	vLineTarget = mod( vLineTarget - vTarget + WORLD_SIZE * 0.5, WORLD_SIZE ) + vTarget - WORLD_SIZE * 0.5;
    
    vec3 vForceColor = vec3(.5,0,0);
    
    float boidCount = UI_GetFloat( DATA_COUNT );
    
    ivec2 vGridCell = ivec2( vec2(GRID_SIZE) * mod(vPos.xz, WORLD_SIZE.xz) / WORLD_SIZE.xz );
    vec4 cellBoids = texelFetch( iChannelGrid, vGridCell, 0 );
    

    float fTargetCircleDist = length( vPos.xz - vCircleOrigin.xz );
    float fTextureFactor = clamp( 1.0 - ( fTargetCircleDist - 0.75 ), 0.0, 1.0);
        
    if ( fTargetFactor == 0.0 )
        fTextureFactor = 1.0;
    vResult *= 1.0 - textureLod( iChannel3, vPos.xz / 10.0, 0.0 ).xyz * 0.15 * fTextureFactor;
        
    
    if ( bDrawCohesionForce || bDrawSeaparationForce || bDrawAlignmentForce )
    {
        // only do complex per-boid rendering near circle
        if ( fTargetCircleDist < (fCircleRadius + 0.2) )
        {
            for ( int index = 0; index < MAX_BOID_COUNT; index++ )
            {
                if ( index >= int(boidCount) )
                {
                    break;
                }


                Boid currBoid = LoadBoid( index );

                // Wrap world
                currBoid.vPos = mod( currBoid.vPos - vTarget + WORLD_SIZE * 0.5, WORLD_SIZE ) + vTarget - WORLD_SIZE * 0.5;

                currBoid.vPos.y = 0.0f;
                currBoid.vVel.y = 0.0f;

                vec3 vDir = normalize( currBoid.vVel );

                vec3 vBoidWorldOffset = vPos - currBoid.vPos;

                float fDistToBoid = length( vBoidWorldOffset );

                float fDot = dot( vBoidWorldOffset, vDir );

                vec3 vClosest = currBoid.vPos + fDot * vDir;

                float fClosestDist = length( vClosest - vPos );
                float fCurrDist = fClosestDist * 0.5 / abs(fDot-0.1);
                fCurrDist = max( fCurrDist, fDistToBoid );

                float fCircleDist = length( vCircleOrigin - currBoid.vPos );
                bool inCircle = fCircleDist < fCircleRadius;

                if ( bDrawCohesionForce || bDrawSeaparationForce )
                {
                    if ( inCircle )
                    {
                        if ( index != targetBoidIndex )
                        {
                            float fLine = DrawLine( vPos.xz, vLineTarget.xz, currBoid.vPos.xz, fLineThickness);
                            vResult = mix( vResult, vec3(0.3, 0.3, 0.3), fLine );
                        }
                    }
                }

                if ( bDrawAlignmentForce )
                {
                    if ( inCircle )
                    {
                        if ( index != targetBoidIndex )
                        {
                            vec3 vArrowStart = currBoid.vPos;
                            vec3 vArrowEnd = vArrowStart + currBoid.vVel * 5.0;
                            vec3 vDir = vArrowEnd - vArrowStart;

                            float fArrow = DrawLine( vPos.xz, vArrowStart.xz, vArrowEnd.xz, fLineThickness);
                            fArrow = max( fArrow, DrawArrowhead( vPos.xz, vArrowEnd.xz, -vDir.xz, fArrowSize, fLineThickness ) );
                            vResult = mix( vResult, vec3(0.0, 0.0, 1.0), fArrow );
                        }
                    }
                }


            }
        }
    }

    for ( int cellBoidIndex=0; cellBoidIndex < 4; cellBoidIndex++ )
    {
        int index = int(cellBoids[cellBoidIndex]);
        if ( index < 0 )
            continue;
        
        Boid currBoid = LoadBoid( index );

        // Wrap world
        currBoid.vPos = mod( currBoid.vPos - vTarget + WORLD_SIZE * 0.5, WORLD_SIZE ) + vTarget - WORLD_SIZE * 0.5;
        
        currBoid.vPos.y = 0.0f;
        currBoid.vVel.y = 0.0f;
        
        vec3 vDir = normalize( currBoid.vVel );
        
        vec3 vBoidWorldOffset = vPos - currBoid.vPos;
        
        float fDistToBoid = length( vBoidWorldOffset );

        float fDot = dot( vBoidWorldOffset, vDir );

        vec3 vClosest = currBoid.vPos + fDot * vDir;

        float fClosestDist = length( vClosest - vPos );
        float fCurrDist = fClosestDist * 0.5 / abs(fDot-0.1);
        fCurrDist = max( fCurrDist, fDistToBoid );

        float fCircleDist = length( vCircleOrigin - currBoid.vPos );
        bool inCircle = fCircleDist < fCircleRadius;

        if ( fCurrDist < 0.1 )
        {
            if ( index == targetBoidIndex )
            {
                vResult = vec3(0.1, 0.4, 0.0);
            }
            else
            if ( inCircle )
            {
                vResult = vec3(0.1, 0.1, 0.6);                                    
            }
            else
            {
                vResult = vec3(0.2, 0.2, 0.2);                    
            }
        }            
    }

    if ( fCircleRadius > 0.0 )
    {
		float fCircle = DrawCircle( vPos.xz, vCircleOrigin.xz, fCircleRadius, fLineThickness );    
    	vResult = mix( vResult, vec3(0.5, 0.2, 0.0), fCircle );
    }
        
    if ( bDrawCohesionForce )
    {
        float fLine = DrawLine( vPos.xz, vLineTarget.xz, targetBoid.vPos.xz, fLineThickness);
        vResult = mix( vResult, vForceColor, fLine );

        vec3 vArrowPos = vLineTarget;
        vec3 vDir = targetBoid.vPos - vLineTarget;
        float fArrow = DrawArrowhead( vPos.xz, vArrowPos.xz, vDir.xz, fArrowSize, fLineThickness );
        vResult = mix( vResult, vForceColor, fArrow );
	}
    
                
    if ( bDrawSeaparationForce )
    {
        vec3 vDir = targetBoid.vSeparationSteer;

        vec3 vArrowStart = targetBoid.vPos;
        vec3 vArrowEnd = vArrowStart + vDir * 0.02;

        float fArrow = DrawLine( vPos.xz, vArrowStart.xz, vArrowEnd.xz, fLineThickness);
        fArrow = max( fArrow, DrawArrowhead( vPos.xz, vArrowEnd.xz, -vDir.xz, fArrowSize, fLineThickness ) );
        vResult = mix( vResult, vForceColor, fArrow );
    }
    
    if ( bDrawAlignmentForce )
    {
        {
            vec3 vArrowStart = targetBoid.vPos;
            vec3 vArrowEnd = vArrowStart + targetBoid.vVel * 5.0;
            vec3 vDir = vArrowEnd - vArrowStart;

            float fArrow = DrawLine( vPos.xz, vArrowStart.xz, vArrowEnd.xz, fLineThickness);
            fArrow = max( fArrow, DrawArrowhead( vPos.xz, vArrowEnd.xz, -vDir.xz, fArrowSize, fLineThickness ) );
            vResult = mix( vResult, vec3(0.0, 0.8, 0.0), fArrow );        
        }

        {
            vec3 vArrowStart = targetBoid.vPos;
            vec3 vArrowEnd = vArrowStart + targetBoid.vAlignmentDir * 5.0;
            vec3 vDir = vArrowEnd - vArrowStart;

            float fArrow = DrawLine( vPos.xz, vArrowStart.xz, vArrowEnd.xz, fLineThickness);
            fArrow = max( fArrow, DrawArrowhead( vPos.xz, vArrowEnd.xz, -vDir.xz, fArrowSize, fLineThickness ) );
            vResult = mix( vResult, vec3(0.0, 0.0, 1.0), fArrow );        
        }
        
        {
            vec3 vArrowStart = targetBoid.vPos;
            vec3 vArrowEnd = vArrowStart + (targetBoid.vAlignmentDir - targetBoid.vVel) * 20.0;
            vec3 vDir = vArrowEnd - vArrowStart;

            float fArrow = DrawLine( vPos.xz, vArrowStart.xz, vArrowEnd.xz, fLineThickness);
            fArrow = max( fArrow, DrawArrowhead( vPos.xz, vArrowEnd.xz, -vDir.xz, fArrowSize, fLineThickness ) );
            vResult = mix( vResult, vForceColor, fArrow );        
        }        
    }    
        
    fragColor = vec4( vResult, 1.0 );
}