// Buf A (buffer) — Irradiance cubemap by Bers
// https://www.shadertoy.com/view/ls3Szr

//Author : SÃ©bastien BÃ©rubÃ©
//Buffer A : Hemisphere integration to compute environment diffuse contribution.
//           The result is "cubemapped" and folded into the current buffer output,
//           using uvToFace() and faceToRay().
//           
//           function "FaceInfo uvToFace(vec2 uv)" converts a [0-1] uv input into the cubemap face info (face ID + face UV).
//           function "vec3 faceToRay(FaceInfo info)" converts a face info into a 3D direction.
//           
//    BufferA :
//     __________________________________________
//    |    Face 6      |    Face 6      |        |
//    |   z- lower     |   z- upper     |MetaData|
//    |________________|________________|________|
//    |        |                |                |
//    |        |                |                |
//    |Face 3  |     Face 4     |     Face 5     |
//    |  y+    |       y-       |       z+       |
//    |________|________________|________________|
//    |                |                |        |
//    |                |                |        |
//    |    Face 1      |    Face 2      |  Face 3|
//    |      X+        |      X-        |    y+  |
//    |________________|________________|________|
//     
//#define HIGH_QUALITY //Time needs to be reset when defining this value.

#ifdef HIGH_QUALITY
const int SAMPLES_PER_ITERATION = 30;
const int CONVERGENCE_FRAME_COUNT = 200;
#else
const int SAMPLES_PER_ITERATION = 5;
const int CONVERGENCE_FRAME_COUNT = 100;
#endif


//Arbitrary axis rotation (around normalized u, cos theta, sin theta)
mat3 UTIL_axisRotationMatrix( vec3 u, float ct, float st )
{
    return mat3(  ct+u.x*u.x*(1.-ct),     u.x*u.y*(1.-ct)-u.z*st, u.x*u.z*(1.-ct)+u.y*st,
	              u.y*u.x*(1.-ct)+u.z*st, ct+u.y*u.y*(1.-ct),     u.y*u.z*(1.-ct)-u.x*st,
	              u.z*u.x*(1.-ct)-u.y*st, u.z*u.y*(1.-ct)+u.x*st, ct+u.z*u.z*(1.-ct) );
}

vec3 rotateSample(vec3 sampleDir, float range_01, float circular_01, out float range_angle)
{
    const float PI = 3.14159;    
    float theta = 2.0*PI*circular_01;
    
	vec3 notColinear = (abs(sampleDir.y)<0.8)?vec3(0,1,0):vec3(1,0,0);
	vec3 othogonalAxis = normalize(cross(notColinear,sampleDir));
    
    range_angle = atan( sqrt(range_01)/sqrt(1.0-range_01) );
    float cost = sqrt(1.0-range_01);//=cos(range_angle);
    float sint = sqrt(range_01);//=sin(range_angle);
	mat3 m1 = UTIL_axisRotationMatrix(othogonalAxis, cost, sint);
	mat3 m2 = UTIL_axisRotationMatrix(sampleDir, cos(theta), sin(theta));
    return sampleDir*m1*m2;
}

vec3 integrateHemisphere(vec3 normal, float progress)
{
    //Add some randomness in between progress steps.
    float ff = 0.5-(fract(normal.x*4913.)
	               +fract(normal.y*4913.)
	               +fract(normal.z*4913.))/6.0;
    
    progress += max(0.,ff/float(CONVERGENCE_FRAME_COUNT));
        
    vec3 up = vec3(0,1,0);
    vec3 right = normalize(cross(up,normal));
    up = cross(normal,right);

    vec3 sampledColour = vec3(0,0,0);
    float index = 0.;
    float theta = 0.;
    
    //http://www.codinglabs.net/article_physically_based_rendering.aspx
    for(int j=0; j < SAMPLES_PER_ITERATION; ++j)
    {
        float circular_angle_01 = index/float(SAMPLES_PER_ITERATION)+fract(progress*87316.)/float(SAMPLES_PER_ITERATION);
        vec3 sampleVector = rotateSample(normal, progress, circular_angle_01, theta);
		vec3 linearGammaColor = pow(texture( iChannel0, sampleVector, -100.0 ).rgb,vec3(2.2));
        float sampledArea = sin(theta);
		sampledColour += linearGammaColor * cos(theta) * sampledArea;
		index ++;
	}

    return vec3( 3.14159 * sampledColour / index);
}

struct FaceInfo
{
    vec2 uv; //[0-1]
    float id; //[0=x+,1=x-,2=y+,3=y-,4=z+,5=z-]
};

//receives a faceID + uv, which it converts into a 3D direction from cube center to face point.
vec3 faceToRay(FaceInfo info)
{
    //info.id = [0=x+,1=x-, 2=y+,3=y-, 4=z+,5=z-]
    //fAxis   = [0.01;0.51; 1.01;1.51; 2.01;2.51]
    float eps = 0.01;              
    float fAxis = info.id/2.0+eps;
    bvec3 axis  = lessThan(abs(floor(fAxis)-vec3(0,1,2)),vec3(eps));
    vec3 camU = (axis.y)?vec3(0,0,1):vec3(0,1,0);
    vec3 camD = vec3(axis.x?1:0,axis.y?1:0,axis.z?1:0);
    vec3 camR = cross(axis.z?-camD:camD,camU);
    float axisSign = (fract(fAxis)<0.5)?1.:-1.;
    return  normalize(camR*(info.uv.x*2.-1.)
                     +camU*(info.uv.y*2.-1.)
                     +camD*axisSign);
}

//Converts a 2D texture into its tile uv and its [0..5] index;
FaceInfo uvToFace(vec2 uv)
{
    //huv is the "horizontally unrolled" wide uv coord, where u.x=[0-6] and u.y=[0-1].
    //tuv is the tile uv coord, back to [0-1]. Note: 6th anf 7th tiles are cut in half and combined.
    const float freq = 2.5;
    uv *= freq;
    vec2 huv = vec2(uv.x+freq*floor(uv.y),fract(uv.y));
    float idx = floor(huv.x);
    vec2 tuv = vec2(fract(huv.x),huv.y+(idx>5.01?0.5:0.));
    return FaceInfo( tuv, min(idx,5.) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.xy;
    
    FaceInfo info = uvToFace(uv);
    vec3 rayDir = faceToRay(info);
    
    vec3 cBuf = texture(iChannel1,vec2(1),-100.0).xyz;
    vec2 prevRes = cBuf.xy;
    float frameCount = cBuf.z;
	        
    vec3 accumColor = texture(iChannel1,uv,-100.0).rgb;
    if(iTime<0.1 || length(prevRes-iResolution.xy) > 1.)
    {
        //Init/reset on resolution change
        accumColor = vec3(0);
        frameCount = 0.0;
    }
    
    float progress = frameCount/float(CONVERGENCE_FRAME_COUNT);
    vec3 cCurrentContribution = integrateHemisphere(rayDir, progress)/float(CONVERGENCE_FRAME_COUNT);
    vec3 c = accumColor+((progress<1.)?cCurrentContribution:vec3(0.));
	fragColor = vec4(c,1.0);
    
    //Use top-right texture pixel to store computation resolution & frame count.
    if(length(uv-vec2(1))<0.01)
    {
        fragColor.xyz = vec3(iResolution.xy,frameCount+1.);
    }
}