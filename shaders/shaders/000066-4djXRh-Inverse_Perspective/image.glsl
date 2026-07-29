// Image (image) — Inverse Perspective by HLorenzi
// https://www.shadertoy.com/view/4djXRh

// Inverse Perspective by HLorenzi
// (Distance Functions by iquilezles.org)

float marchDistance;
float marchMaterial;
vec3  marchPosition;
float fieldDistance;
float fieldMaterial;

float smin(float a, float b, float k)
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

 void opUnion(inout float df1, inout float mat1, float df, float mat)          {if (df < df1) {df1 = df; mat1 = mat;}}
 void opInters(inout float df1, inout float mat1, float df, float mat)         {if (df > df1) {df1 = df; mat1 = mat;}}
float dfBox(vec3 p, vec3 size, float rad)   {return length(max(abs(p) - size + vec3(rad), 0.0)) - rad;}
float dfSphere(vec3 p, float rad)           {return length(p) - rad;}
float dfPlane(vec3 p, vec3 n, float d)      {return dot(p, n) + d;}
float dfCapsule(vec3 p, vec3 a, vec3 b, float r) {vec3 pa = p - a, ba = b - a; float h = clamp(dot(pa,ba) / dot(ba,ba), 0.0, 1.0); return length(pa - ba * h) - r;}
 vec3 dtRotateZ(vec3 p, float ang)          {return vec3(mat2(cos(ang),-sin(ang),sin(ang),cos(ang)) * p.xy, p.z);}
 vec3 dtRotate(vec3 p, float c, float s)    {return vec3(mat2(c, -s, s, c) * p.xy, p.z);}

float distanceField(vec3 p)
{
	fieldDistance = 10000.0;
	fieldMaterial =    -1.0;
    
    float roundness = 0.1;
	
	opUnion(fieldDistance, fieldMaterial, dfPlane(p, vec3(0, 0, 1), 0.0), 1.0);
	opUnion(fieldDistance, fieldMaterial, dfBox(p - vec3(3, 1, 1.05), vec3(1), roundness), 2.0);
	opUnion(fieldDistance, fieldMaterial, dfBox(p - vec3(-3, 1, 1.05), vec3(1), roundness), 2.0);
	opUnion(fieldDistance, fieldMaterial, dfBox(p - vec3(0, -3, 1.05), vec3(1), roundness), 2.0);
	
	return fieldDistance;
}

vec3 normal(vec3 p)
{
	const vec2 eps = vec2(0.01, 0);
	float nx = distanceField(p + eps.xyy) - distanceField(p - eps.xyy);
	float ny = distanceField(p + eps.yxy) - distanceField(p - eps.yxy);
	float nz = distanceField(p + eps.yyx) - distanceField(p - eps.yyx);
	return normalize(vec3(nx, ny, nz));
}


void raymarch(vec3 from, vec3 increment)
{
	const int   kMaxIterations = 60;
	const float kHitDistance   = 0.01;
	
	marchDistance    = -15.0;
	marchMaterial    = -1.0;
	
	for(int i = 0; i < kMaxIterations; i++)
	{
		distanceField(from + increment * marchDistance);
		if (fieldDistance > kHitDistance)
		{
			marchDistance += fieldDistance;
			marchMaterial  = fieldMaterial;
		}
	}
	
	marchPosition = from + increment * marchDistance;
    if (marchDistance > 32.0)
        marchMaterial = -1.0;
}

float shadow(vec3 from, vec3 increment)
{
	const float minDist = 1.0;
	
	float res = 1.0;
	float t = 0.25;
	for(int i = 0; i < 10; i++)
    {
        float h = distanceField(from + increment * t);
        
		res = min(res, 4.0 * h / t);
        t += 0.25;
    }
    return res;
}

float perspective = 0.0;
float cameraHeight = 0.0;

void camera(vec2 uv, vec3 eye, vec3 at, vec3 up, out vec3 from, out vec3 increment)
{	
	vec3 cw = normalize(at - eye);
	vec3 cu = normalize(cross(cw, up));
	vec3 cv = normalize(cross(cu,cw));
	
    float fov = acos(dot(cw, normalize(cu * uv.x)));
    float screenSize = (10.0 / (2.0 * tan(abs(fov) / 2.0)));
    vec3 virtscreen = eye + cw * 2.0 + (cu * uv.x + cv * uv.y) * screenSize;
    from = eye + (cu * uv.x + cv * uv.y) * (0.7 + 0.2 * perspective) * screenSize;
	increment = normalize(virtscreen - from);
}

vec3 pixel(vec2 uv)
{
    float dist = 4.0;
	vec3 at  = vec3(0, 0, 1);
	vec3 eye = at + vec3(cos(iTime / 2.0) * dist, sin(iTime / 2.0) * dist, 0.25 + cameraHeight * 2.0);
	vec3 up  = vec3(0,0,1);
	vec3 from, increment;
	camera(uv, eye, at, up, from, increment);
	raymarch(from, increment);
	
    vec3 lightdir = normalize(vec3(1, 2, 3) * 3.0 - marchPosition);
    
	if (marchMaterial == 1.0)
    {
		vec3 n = normal(marchPosition);
		float diffuse = max(dot(n, normalize(vec3(1, 2, 3))), 0.0) * 0.5 + 0.5;
        float shade = shadow(marchPosition, lightdir) * 0.5 + 0.5;
		return texture(iChannel1, marchPosition.xy / 4.0).rgb * diffuse * shade;
	}
	else if (marchMaterial == 2.0)
    {
        vec3 tex = texture(iChannel0, (marchPosition.xy + marchPosition.zx) / 2.0).rgb;
		vec3 n = normal(marchPosition);
		float diffuse = max(dot(n, normalize(vec3(1, 2, 3))), 0.0) * 0.5 + 0.5;
        
        float specular = 0.0;
		if (dot(n, lightdir) > 0.0)
        {
			specular = min(1.0, pow(max(0.0,
					dot(reflect(-lightdir, n), normalize(from - marchPosition))), 50.0));
		}
		return mix(
            tex * diffuse,
            vec3(1, 1, 1),
            specular * 0.75);
	}
	else return vec3(0,0,0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	uv = uv * 2.0 - vec2(1);
	uv.x *= iResolution.x / iResolution.y;
    
    perspective = clamp(-0.2 + 1.4 * (iMouse.x / iResolution.x * 2.0), 0.0, 2.0);
    cameraHeight = 2.0 - clamp(-0.2 + 1.4 * (iMouse.y / iResolution.y * 2.0), 0.0, 2.0);
	
	fragColor = vec4(pixel(uv), 1);
    
    float meterSize = 200.0;
    float meterX = (iResolution.x - meterSize) / 2.0;
    float meterY = 32.0;
    
    if (fragCoord.x >= meterX + meterSize * 0.7 &&
            fragCoord.x <= meterX + meterSize * 0.7 + 2.0 &&
            fragCoord.y >= meterY - 18.0 &&
            fragCoord.y <= meterY + 2.0)
    {
        fragColor = vec4(1, 1, 1, 1);
    }
    else if (fragCoord.x >= meterX + 2.0 &&
        fragCoord.x <= meterX + 2.0 + (perspective / 2.0) * (meterSize - 4.0) &&
        fragCoord.y >= meterY - 14.0 &&
        fragCoord.y <= meterY - 2.0)
    {
        fragColor = vec4(1, 0, 0, 1);
    }
    else if (fragCoord.x >= meterX &&
            fragCoord.x <= meterX + meterSize &&
            fragCoord.y >= meterY - 16.0 &&
            fragCoord.y <= meterY)
    {
     	fragColor = vec4(0, 0, 0, 1);   
    }
}