// Common (common) — Van Damme - Distance by Flyguy
// https://www.shadertoy.com/view/Wl3fWX

//Converts a ray direction to uv coords (xy, normalized) & a face id (z, 0-5).
//for the cubemap face it's pointing to.
vec3 rayToFace(vec3 rd)
{
    vec3 asign = sign(rd);
    rd = abs(rd);
    float amax = max(max(rd.x,rd.y),rd.z);
    
    vec3 face = (rd.x == amax) ? vec3(asign.yz*rd.yz, floor(1.+.5*asign.x)) :
                (rd.y == amax) ? vec3(asign.xz*rd.xz, floor(3.+.5*asign.y)) :
                (rd.z == amax) ? vec3(asign.xy*rd.xy, floor(5.+.5*asign.z)) : 
                                 vec3(0,0,-1);
    face.xy = .5+.5*(face.xy/amax);
    return face;
}

//opposite of rayToFace
//Converts normalized uv coords & a face id to a ray direction
//for cubemap sampling
vec3 faceToRay(vec3 face)
{
    face.xy = 2.*fract(face.xy)-1.;
    vec3 rd = (face.z == 0.) ? vec3(-1,face.x,face.y) :
              (face.z == 1.) ? vec3( 1,face.x,face.y) :
              (face.z == 2.) ? vec3(face.x,-1,face.y) :
              (face.z == 3.) ? vec3(face.x, 1,face.y) :
              (face.z == 4.) ? vec3(face.x,face.y,-1) :
              (face.z == 5.) ? vec3(face.x,face.y, 1) :
                               vec3(0);
    return normalize(rd);
}

//Sample a cubemap face (0-5) with normalized uv coords.
vec4 textureCubeFace(samplerCube cube, float face, vec2 uv)
{
    vec3 rd = faceToRay(vec3(uv,floor(face)));
    return texture(cube, rd, 0.0).rgba;  
}


