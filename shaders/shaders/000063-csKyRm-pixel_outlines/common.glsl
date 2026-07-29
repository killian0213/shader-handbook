// Common (common) — pixel outlines by UltimateBurrito
// https://www.shadertoy.com/view/csKyRm

const float orthographicSize = 10.0;
const float nearPlane = 0.1;
const float farPlane = 100.0;
const int maxIterations = 128;
const int pixelSize = 3;
const float epsilon = 0.001;
const mat3 identity = mat3(
vec3(1,0,0),
vec3(0,1,0),
vec3(0,0,1));
const mat3 customSpinRotation = mat3(
vec3(100,0,0),
vec3(0,0,0),
vec3(0,0,0));
const float pi = 3.14159;
const float deg2Rad = pi / 180.0;
mat3 xRotation(float theta)
{

    return mat3(
    vec3(1,0,0),
    vec3(0,cos(theta*deg2Rad),-sin(theta*deg2Rad)),
    vec3(0,sin(theta*deg2Rad),cos(theta*deg2Rad))
    );
}
mat3 yRotation(float theta)
{

    return mat3(
    vec3(cos(theta*deg2Rad),0.0,-sin(theta*deg2Rad)),
    vec3(0.0,1.0,0.0),
    vec3(sin(theta*deg2Rad),0.0,cos(theta*deg2Rad))
    );
}

struct Box
{
    vec3 pos;
    vec3 size;
    int materialIndex;
    mat3 basis;
};
struct Material
{
    vec3 albedo;
};
struct PointLight
{
    vec3 pos;
    vec3 color;
    float dist;
    int linkedBoxIndex;
};

const vec3 lightDir = normalize(vec3(3,-4,2));
const vec3 sunColor = vec3(1.0,1.0,0.9);

const Material materials[] = Material[](
    Material(vec3(1,1,1)),
    Material(vec3(0.5,1,0.5)),
    Material(vec3(0.7,0.7,0.7))
);

const Box boxes[] = Box[](
    Box(vec3(0,1,0),vec3(50,1,50),1,identity), // floor
    Box(vec3(0,0,0),vec3(10,1,10),2,identity), // platform
    Box(vec3(0,0.5,0),vec3(12,1,12),2,identity),
    Box(vec3(-5,-2,-5),vec3(2,5,2),2,identity), // pillars
    Box(vec3(5,-2,-5),vec3(2,5,2),2,identity),
    Box(vec3(-5,-2,5),vec3(2,5,2),2,identity),
    Box(vec3(5,-2,5),vec3(2,5,2),2,identity),
    Box(vec3(2,-2,2),vec3(1,1,1),0,customSpinRotation), // magic cube
    Box(vec3(-2,-2,2),vec3(1,1,1),0,customSpinRotation),
    Box(vec3(0,-2,-2),vec3(1,1,1),0,customSpinRotation)
);
const int boxCount = 10;

const PointLight lights[] = PointLight[](
    PointLight(vec3(0,-2,0),vec3(0.0,1.0,0.0),5.0,7),
    PointLight(vec3(0,-2,0),vec3(0.0,0.5,1.0),5.0,8),
    PointLight(vec3(0,-2,0),vec3(1.0,0.0,0.0),5.0,9)
);

const int lightCount = 3;
