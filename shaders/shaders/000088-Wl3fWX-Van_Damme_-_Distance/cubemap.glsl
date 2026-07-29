// Cube A (cubemap) — Van Damme - Distance by Flyguy
// https://www.shadertoy.com/view/Wl3fWX

//Utilizes the cubemap buffer as 6 1024x1024 buffers, 2 passes per face.
//Jump floods a 1-pixel wide outline of the stencil.
//Initializes non-outline pixels as vec2(+/-maxDist) to store the sign.
//The JFA function leaves the sign unchanged through each step.
//The sign is then re-applied to the calculated distance at the end.

const float cubeRes = 1024.0; // X/Y Resolution of each cubemap face. 
const float maxSteps = 10.;// Max# of JFA steps
const float maxDist = 1e5;// Max distance 

//Coordinate pairs for the JFA function.
#define XY 0
#define ZW 1

//Outputs the stencil (x) and 1 pixel wide outline (y)
vec2 outline(vec2 uv, vec2 pixelSize)
{
    float center = step(0.0, texture(iChannel0, uv, 0.0).a);
    
    vec4 neighbors = vec4(
        texture(iChannel0, uv + pixelSize*vec2( 0, 1), 0.0).a,
        texture(iChannel0, uv + pixelSize*vec2( 0,-1), 0.0).a,
        texture(iChannel0, uv + pixelSize*vec2(-1, 0), 0.0).a,
        texture(iChannel0, uv + pixelSize*vec2( 1, 0), 0.0).a
    );
    neighbors = step(0.0, neighbors); 
    
    return vec2(center, min(1.0, center*dot(1.0-neighbors, vec4(1))));
}

//Jump flooding algorithim on a cubemap face.
//buf -------> cubemap buffer to sample
//uv --------> current uv coords
//aspect ----> aspect ratio correction
//jfaStep ---> current step
//cubeFace --> cubemap face to sample
//coordPair -> coordinate pair to sample (XY or ZW)
vec2 JFA(samplerCube buf, vec2 uv, vec2 aspect, float jfaStep, float cubeFace, int coordPair)
{
    float nearestDist = maxDist;
    float stepSize = exp2(maxSteps - jfaStep)/cubeRes;

    vec4 nearestCoord = textureCubeFace(buf, cubeFace, uv);
    nearestCoord.xy = (coordPair == ZW) ? nearestCoord.zw : nearestCoord.xy;
    
    float sdfSign = sign(nearestCoord.x);
    
    for(int i = -1; i <= 1; i++)
    {
        for(int j = -1; j <= 1; j++)
        {
            vec2 curUV = uv + vec2(i,j) * stepSize;
            
            vec4 curCoord = abs(textureCubeFace(buf, cubeFace, curUV));
            
            curCoord.xy = (coordPair == ZW) ? curCoord.zw : curCoord.xy;
            
            float curDist = length(curCoord.xy - vec2(uv*aspect));
            
            if(curCoord.xy != vec2(0) && curDist < nearestDist)
            {
                nearestCoord.xy = curCoord.xy;
                nearestDist = curDist;
            }
        }
    }
    
    return abs(nearestCoord.xy)*sdfSign;
}

void mainCubemap( out vec4 fragColor, in vec2 fragCoord, in vec3 ro, in vec3 rd )
{
    vec3 face = rayToFace(rd);
    vec2 uv = face.xy;
    vec2 aspect = vec2(textureSize(iChannel0,0));
    aspect = aspect / aspect.y;
    
    vec4 cout = vec4(0);
    
    cout.xy = JFA(iChannel1, uv, aspect, face.z*2.0, face.z-1.0, ZW);
    
    if(face.z == 0.0) //Initialize XY with stencil/outline on face 0.
    {
        vec2 edge = outline(uv, vec2(1.0/cubeRes));
        cout.xy = vec2(uv*aspect)*edge.y; //outline
        cout.xy = (edge.y == 0.0) ? vec2(maxDist*(2.0*edge.x-1.0)) : cout.xy; //sign
    }
    
    cout.zw = JFA(iChannel1, uv, aspect, face.z*2.0+1.0, face.z, XY);
    
    //Calculate the signed distance and normals.
    if(face.z == 5.0) 
    {
        vec2 coord = cout.xy;
        cout.xy = normalize(uv*aspect - abs(coord));
        cout.z = distance(uv*aspect, abs(coord)) * sign(coord.x);
        cout.w = 0.0;
    }
    

    // Output to cubemap
    fragColor = vec4(cout);
}