// Buffer C (buffer) — Local Light Source Ball Pit by fenix
// https://www.shadertoy.com/view/mt23R3

// ---------------------------------------------------------------------------------------
// G buffer render
// ---------------------------------------------------------------------------------------

// https://iquilezles.org/articles/spherefunctions/
float sphIntersect( in vec3 ro, in vec3 rd, in vec4 sph )
{
	vec3 oc = ro - sph.xyz;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return -1.0;
	return -b - sqrt( h );
}

// draw one ball
void renderParticle(int id, fxParticle p, vec3 ro, vec3 rd, inout fxGBufferPixel pix)
{
    float t = sphIntersect(ro, rd, vec4(p.pos, PARTICLE_SIZE));
    if (t > 0. && t < pix.t)
    {
        vec3 hitPos = ro + rd * t;
        vec3 normal = normalize(hitPos - p.pos);

        pix.n = normal;
        pix.m = float(id + 2); // materials 0...1 are for box
        pix.t = t;
    }
}

// Derived from iq, but DO NOT COPY FROM HERE (modified to return interior results):
// https://iquilezles.org/articles/boxfunctions/
// Calcs intersection and exit distances, normal, face and UVs
// row is the ray origin in world space
// rdw is the ray direction in world space
// txx is the world-to-box transformation
// txi is the box-to-world transformation
// ro and rd are in world space
// rad is the half-length of the box
//
// oT contains the entry and exit points
// oN is the normal in world space
// oU contains the UVs at the intersection point
bool boxIntersect( in vec3 row, in vec3 rdw, in mat4 txx, in mat4 txi, in vec3 rad,
                   out vec2 oT, out vec3 oN, out vec2 oU ) 
{				 
    // convert from world to box space
    vec3 rd = (txx*vec4(rdw,0.0)).xyz;
    vec3 ro = (txx*vec4(row,1.0)).xyz;

    // ray-box intersection in box space
    vec3 m = 1.0/rd;
    vec3 s = vec3((rd.x<0.0)?1.0:-1.0,
                  (rd.y<0.0)?1.0:-1.0,
                  (rd.z<0.0)?1.0:-1.0);
    vec3 t1 = m*(-ro + s*rad);
    vec3 t2 = m*(-ro - s*rad);

    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
	
    if( tN>tF || tF < 0.0) return false;

    // compute normal (in world space), face and UV
    if( t2.x<t2.y && t2.x<t2.z ) { oN=txi[0].xyz*s.x; oU=ro.yz+rd.yz*t2.x; }
    else if( t2.y<t2.z   )       { oN=txi[1].xyz*s.y; oU=ro.zx+rd.zx*t2.y; }
    else                         { oN=txi[2].xyz*s.z; oU=ro.xy+rd.xy*t2.z; }

    oT = vec2(tN,tF);
    
    return true;
}

float boxDist(vec2 a, vec2 b) { return max(abs(a.x - b.x), abs(a.y - b.y)); }

// generates a checkerboard pattern
// aa allows reduction of aliasing at steep angles
float checker(vec2 p, float aa)
{
    vec2 m = mod(p, vec2(2.));
    float sd = min(boxDist(vec2(.5, 1.5), m), boxDist(vec2(1.5, .5), m));
    return smoothstep(-aa, aa, .5 - sd) * .5 + .5;
}

// draws an inside-out antialiased checkered box
void drawBox(fxState state, vec3 ro, vec3 rd, inout fxGBufferPixel pix)
{
    vec2 t, uv;
    vec3 n;
    mat4 m = boxMat(state.boxRot);
    if (boxIntersect(ro, rd, inverse(m), m, vec3(1), t, n, uv))
    {
        float x = 1.2 + dot(n, rd);
        float aa = x * 20./iResolution.y;
        float ch = checker(uv * 4.25 - .5, aa);
        
        pix.n = n;
        pix.t = t.y;
        pix.m = ch;
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fxState state = fxGetState();
   
    vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
    fxCalcCamera(cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

    vec3 rayDir = fxCalcRay(fragCoord, iResolution, cameraFwd, cameraUp, cameraLeft);

    fxGBufferPixel pix;
    pix.t = FAR_CLIP;
    
    // render box
    drawBox(state, cameraPos, rayDir, pix);

    // render particles
    ivec4 old = fxGetClosest( ivec2(fragCoord) );      
    for (int j = 0; j < 4; j++)
    {
        int id = old[j];
        if (id < 0) break;
        fxParticle data = fxGetParticle(id);
        renderParticle(id, data, cameraPos, rayDir, pix);
    }
    
    fragColor = fxPackGBuffer(pix);
}
