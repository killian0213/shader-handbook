// Buf A (buffer) — fluidcube by zguerrero
// https://www.shadertoy.com/view/Xlc3R4

const float EPSILON = 0.01;


float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec3 rotationY(vec3 pos, float angle) {
	float c = cos(angle);
    float s = sin(angle);
    vec3 rotPos;
	rotPos.x = c * pos.x + s * pos.z;
    rotPos.y = pos.y;
	rotPos.z = -s * pos.x + c * pos.z;
    
    return rotPos;
}

float box(vec3 pos, vec3 size)
{
	return length(max(abs(pos) - size, 0.0));
}

float sphere(vec3 pos, float radius)
{
	return length(pos) - radius;
}

float infinitePlane(vec3 pos, float height)
{
    return pos.y - height;
}

vec3 repeatTime(vec3 s)
{
    return fract(iTime*s)*3.14159265359*2.0;
}

vec3 noise(vec3 pos, vec3 k, vec3 p, vec3 s)
{
    vec3 t = repeatTime(s);
    float X1 = cos(dot(pos.yz,k.yz) + p.x - t.x);
    float Y1 = cos(dot(pos.zx,k.zx) + p.y - t.y);
    float Z1 = cos(dot(pos.xy,k.xy) + p.z - t.z);

    float X2 = cos(dot(vec2(Y1, Z1),k.yz) + p.x + t.x);
    float Y2 = cos(dot(vec2(Z1, X1),k.zx) + p.y + t.y);
    float Z2 = cos(dot(vec2(X1, Y1),k.xy) + p.z + t.z);
 	return vec3(X2, Y2, Z2); 
}

float distfunc(vec3 pos)
{
    vec3 t = repeatTime(vec3(0.4,0.0,0.0));
    float s1 = sin(t.x)*0.5+0.5;
    float s2 = sin(t.x - 0.4)*0.5+0.5 + 0.2;
    
    float attenuationY = 1.0 - clamp(pos.y*0.25,0.0,1.0);
    float attenuationXZ = 1.0 - clamp(length(pos.xz*0.05),0.0,1.0);
    
    vec3 n1 = noise(pos, vec3(1.4,1.5,1.25), vec3(0.0,1.0,2.0), vec3(0.2,0.5,0.1));
	float n2 = sin(length(pos.xz) - iTime*7.0);
    vec3 nGround = (n2+n1*0.1)*attenuationXZ*(1.0 - s2);
    vec3 nObj = n1*0.2*(1.0 - s2)*attenuationY - vec3(0.0,s1*6.0 - 3.0,0.0);
    
    float ground = infinitePlane(pos+nGround, 0.0);
    vec3 rotPos = rotationY(pos, iTime);
    float box1 = box(rotPos + nObj, vec3(1.5,1.5,1.5));
    float box2 = box(rotPos + nObj, vec3(1.75,1.0,1.0));
    float box3 = box(rotPos + nObj, vec3(1.0,1.0,1.75)); 
    float box4 = min(box1, min(box2, box3));
    float sphere1 = sphere(pos + nObj, 3.0);
	return smin(ground, mix(sphere1, box4, s1*0.9), 1.0);
}

vec2 rayMarch(vec3 rayDir, vec3 cameraOrigin)
{
    const int MAX_ITER = 100;
	const float MAX_DIST = 40.0;
    
    float totalDist = 0.0;
	vec3 pos = cameraOrigin;
	float dist = EPSILON;
    
    for(int i = 0; i < MAX_ITER; i++)
	{
		dist = distfunc(pos);
		totalDist += dist;
		pos += dist*rayDir;
        
        if(dist < EPSILON || totalDist > MAX_DIST)
		{
			break;
		}
	}
    
    return vec2(dist, totalDist);
}

vec3 skyBox(vec3 rayDir, float blur)
{
    vec3 skyColor1 = vec3(0.5,0.5,1.0);
    vec3 skyColor2 = vec3(1.0,1.0,1.0);
    vec3 groundColor1 = vec3(1.0,0.4,0.3);
    vec3 clouds1 = noise(rayDir, vec3(4.0, 6.0, 3.5),  vec3(0.0, 1.0, 2.0), vec3(0.1, 0.0, 0.0));
    vec3 clouds2 = noise(rayDir + clouds1*0.2, vec3(2.0, 3.0, 2.5),  vec3(0.0, 1.0, 2.0), vec3(-0.1, 0.05, 0.0))*0.5+0.5;
    float c = (clouds2.x+clouds2.y+clouds2.z)*0.05;
    
    vec3 skyColor = mix(skyColor2+c, skyColor1, rayDir.y);
    float m = smoothstep(0.0, blur, (rayDir.y+0.5)+sin(rayDir.x*20.0)*0.01+sin(rayDir.z*15.0)*0.01);
    return mix(groundColor1, skyColor, m);
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 calculateNormals(vec3 pos)
{
	vec2 eps = vec2(0.0, EPSILON);
	vec3 n = normalize(vec3(
	distfunc(pos + eps.yxx) - distfunc(pos - eps.yxx),
	distfunc(pos + eps.xyx) - distfunc(pos - eps.xyx),
	distfunc(pos + eps.xxy) - distfunc(pos - eps.xxy)));
	return n;
}

float calculateAO(vec3 pos, vec3 n)
{
	float occ = 0.0;

	for( int i=0; i<5; i++ )
	{
		float hr = 0.1*float(i);
		vec3 aopos = pos + n*hr;
		float dd = distfunc(aopos);
		occ += dd;
	}
	return mix(1.0, clamp(0.0, 1.0, occ), 1.0);   
}

float softshadow(vec3 pos, vec3 rayDir, float mint, float tmax )
{
	float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
		float h = distfunc( pos + rayDir*t );
        res = min( res, 2.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );

}

vec3 lighting(vec3 pos, vec3 rayDir)
{
    vec3 n = calculateNormals(pos);
    
    vec3 ambientColor = vec3(0.0,0.0,0.0);
    vec3 diffuseColor = vec3(0.5,0.5,0.5);
    vec3 specColor = vec3(1.0,1.0,1.0);
    vec3 lightColor = vec3(1.0,1.0,0.8);
    vec3 ssColor = vec3(0.1,0.1,0.3);
    
	vec3 light = vec3(0.0, 2.0, 5.0);


	float s = softshadow(pos + n*0.15, light, 0.01, 20.0);
	float ao = calculateAO(pos, n);
	float diff = max(0.0, dot(normalize(light), n))*s;
	float fresnel = (1.0 - dot(n, -rayDir));
	vec3 r = reflect(normalize(rayDir), n);
    float refl = softshadow(pos + n*0.15, r, 0.01, 20.0);
	float spec = pow(max (0.0, dot (r, rayDir)), 20.0);

	vec3 sky = skyBox(r,0.1);
	vec3 res = diffuseColor;
	res *= ambientColor*ao;
	res += diff*lightColor*0.5;
    res += spec*lightColor*specColor*fresnel*ao;
    res += sky*fresnel*0.25;
    res += sky*0.2;
    res	+= (1.0 - refl)*0.5*diffuseColor;
    res += (1.0 - diff)*ssColor;
	return res;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float rotationSpeed = (iMouse.x/iResolution.x)*7.0;
    float cameraDistance = 7.0;
    float camX = cos(rotationSpeed)*cameraDistance;
    float camY = 2.0 + (iMouse.y/iResolution.y)*10.0;
    float camZ = sin(rotationSpeed)*cameraDistance;                 
    vec3 cameraOrigin = vec3(camX, camY, camZ);
	vec3 cameraTarget = vec3(0.0,2.0,0.0);
    
	vec2 screenPos = (fragCoord.xy/iResolution.xy)*2.0-1.0;
	screenPos.x *= iResolution.x/iResolution.y;
    
	mat3 cam = setCamera(cameraOrigin, cameraTarget, 0.0 );
    
    vec3 rayDir = cam* normalize( vec3(screenPos.xy,1.0) );
    vec2 dist = rayMarch(rayDir, cameraOrigin);
    
    vec3 sky = skyBox(rayDir, 0.75);
    vec3 res;
	if(dist.x < EPSILON)
    {
        vec3 pos = cameraOrigin + dist.y*rayDir;
        vec3 no = noise(pos, vec3(0.3,0.25,0.35), vec3(0.0,1.0,2.0), vec3(0.2,0.0,0.0));
        float fogNoise = 1.0 + no.x*no.y*no.z;
        float fog = clamp((dist.y - 18.0)*0.05, 0.0, 1.0);
        float fogY = 1.0 - clamp(pos.y*0.5, 0.0, 1.0);
        res = mix(lighting(pos, rayDir), sky, clamp(fogNoise*(fog+fogY*0.75), 0.0, 1.0));
    }
    else
    {
        res = sky;       
    }

	fragColor = vec4(res, 1.0);
}