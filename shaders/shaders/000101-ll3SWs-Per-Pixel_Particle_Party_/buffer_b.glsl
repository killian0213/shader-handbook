// Buf B (buffer) — Per-Pixel Particle Party! by huwb
// https://www.shadertoy.com/view/ll3SWs

// Buf A is a uniform grid data structure, but storage in each pixel is 1 particle
// (.xy=vel, .zw=pos). For each bucket, searches neighbourhood for newly arriving particle,
// greedily takes first one so particles can annihilate each other if they land in the same
// pixel bucket.

// Flock or perhaps even SPH behavious could probably be implemented on a similar framework.

#define R 5.
#define RESTITUTION .5

// scene data
#define HOSE vec2(.5,.5)/iResolution.xy
#define ATTRACTOR vec2(1.5,0.5)/iResolution.xy
#define COL0 vec2(2.5,0.5)/iResolution.xy
#define COL1 vec2(3.5,0.5)/iResolution.xy
#define COL2 vec2(4.5,0.5)/iResolution.xy
#define HOSE_TARGET vec2(5.5,0.5)/iResolution.xy

vec2 GetVel( vec4 part ) { return part.xy; }
void SetVel( inout vec4 part, vec2 newVel ) { part.xy = newVel; }
vec2 GetPos( vec4 part ) { return part.zw; }
void SetPos( inout vec4 part, vec2 newPos ) { part.zw = newPos; }

vec2 FindArrivingParticle( vec2 arriveCoord, out vec4 partData )
{
    for( float i = -R; i <= R; i++ )
    {
        for( float j = -R; j <= R; j++ )
        {
            vec2 partCoord = arriveCoord + vec2( i, j );
            
            vec4 part = textureLod( iChannel0, partCoord / iResolution.xy, 0. );
            
            // particle in this bucket?
            if( dot(part,part) < 0.001 )
                continue;
            
            // is the particle going to arrive at the current pixel after one timestep?
            vec2 partPos = GetPos( part );
            vec2 partVel = GetVel( part );
            vec2 nextPos = partPos + partVel;
            // arrival means within half a pixel of this bucket
            vec2 off = nextPos - arriveCoord;
            if( abs(off.x)<=.5 && abs(off.y)<=.5 )
            {
                // yes! greedily take this particle.
                // a better algorithm might be to inspect all particles that arrive here
                // and pick the one with the highest velocity.
                partData = part;
                return partCoord;
            }
        }
    }
    // no particle arriving at this bucket.
    return vec2(-1.);
}

void Clip( inout vec4 partData, vec2 col0Pos, vec2 col1Pos, vec2 col2Pos )
{
    vec2 pos = GetPos( partData );
    vec2 vel = GetVel( partData );
    
    vec2 nextPos = pos + vel;
    if( nextPos.y < 0. ) vel.y *= -RESTITUTION;
    if( nextPos.x < 0. ) vel.x *= -RESTITUTION;
    if( nextPos.y > iResolution.y ) vel.y *= -RESTITUTION;
    if( nextPos.x > iResolution.x ) vel.x *= -RESTITUTION;

    vec2 off; float loff2;
    off = nextPos - col0Pos;
    loff2 = dot(off,off);
    if( loff2 < 50.*50. ) {
        loff2 = sqrt(loff2);
        vec2 n = off/loff2;
        vel -= (1.+RESTITUTION) * dot( vel, n ) * n;
        SetPos( partData, col0Pos + 50.*n );
    }
    off = nextPos - col1Pos;
    loff2 = dot(off,off);
    if( loff2 < 50.*50. ) {
        loff2 = sqrt(loff2);
        vec2 n = off/loff2;
        vel -= (1.+RESTITUTION) * dot( vel, n ) * n;
        SetPos( partData, col1Pos + 50.*n );
    }
    off = nextPos - col2Pos;
    loff2 = dot(off,off);
    if( loff2 < 50.*50. ) {
        loff2 = sqrt(loff2);
        vec2 n = off/loff2;
        vel -= (1.+RESTITUTION) * dot( vel, n ) * n;
        SetPos( partData, col2Pos + 50.*n );
    }

    SetVel( partData, vel );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 col0Data = textureLod(iChannel2, COL0, 0.).xyz;
    vec3 col1Data = textureLod(iChannel2, COL1, 0.).xyz;
    vec3 col2Data = textureLod(iChannel2, COL2, 0.).xyz;
    
    // add loads of particles on first frame
    if( iFrame == 0 )
    {
        fragColor = vec4(0.);
        if( mod(fragCoord,10.) == vec2(2.5) )
        {
            vec4 newPart;
            SetPos( newPart, fragCoord );
            SetVel( newPart, vec2(0.) );
            Clip( newPart, col0Data.xy, col1Data.xy, col2Data.xy );
            fragColor = newPart;
        }
        return;
    }
    
    // scene data
    vec3 hoseData = textureLod(iChannel2, HOSE, 0.).xyz;
    vec3 attractData = textureLod(iChannel2, ATTRACTOR, 0.).xyz;
    vec2 hoseTarget = textureLod(iChannel2, HOSE_TARGET, 0.).xy;
    
    float dragCount = hoseData.z + attractData.z + col0Data.z + col1Data.z + col2Data.z;
    
    // mouse emits
    if( iMouse.z > 0. && length(iMouse.xy-fragCoord.xy) < 9. && dragCount == 0. )
    {
        vec4 newPart;
        SetPos( newPart, fragCoord );
        SetVel( newPart, 3.*normalize(fragCoord.xy-iMouse.xy));
        fragColor = newPart;
        return;
    }
    
    // hose 0
    if( length(hoseData.xy-fragCoord.xy) < 9. )
    {
        vec4 newPart;
        SetPos( newPart, fragCoord );
        /*vec2 target = iResolution.xy/2.;
        if( iMouse.x*iMouse.y > 0. ) target = iMouse.xy;*/
        SetVel( newPart, 2.8*normalize(hoseTarget-fragCoord.xy) );
        newPart.xy += .15*sin(15.*iTime)*vec2(-newPart.y,newPart.x);
        fragColor = newPart;
        return;
    }
    
    // look for a particle arriving at the current bucket
    vec4 partData;
    vec2 partCoord = FindArrivingParticle( fragCoord, partData );
    if( partCoord.x < 0. )
    {
        // no particle, empty this bucket
        fragColor = vec4(0.);
        return;
    }
    
    vec2 pos = GetPos( partData );
    vec2 vel = GetVel( partData );
    
    // integrate pos using current vel
    SetPos( partData, pos + vel );
    
    // integrate velocity
    
    // gravity
    vel += vec2(0.,-.05);
    
    // attractor
    vec2 attract = attractData.xy-fragCoord;
    float attractStrength = 20./(.1+dot(attract,attract)) - 0.004;
    if( attractStrength > 0. )
    {
        vel += attract*attractStrength;
    }
    
    // drag
    vel *= .995;
    // turbulence (divergence free curl could work great here but i just want to add a little variation)
    // NOTE this needs mipmapping to be disabled on the texture!
    vel += .125*normalize(textureLod( iChannel1, iTime + 4.*fragCoord/iResolution.xy, 0. ).xy-.5);
    // clamp to the maximum search radius. rsults would benefit from increasing R!
    vel = clamp(vel,-R,R);
    
    SetVel( partData, vel );
    
    Clip( partData, col0Data.xy, col1Data.xy, col2Data.xy );
    
    fragColor = partData;
}
