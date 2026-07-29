// Buffer B (buffer) — UNSTABLE FLAME by alro
// https://www.shadertoy.com/view/dsKfWR

/*
    Trace voxels and intersect particles
*/

// The voxel structure can be hidden slightly by shifting particles along their flow direction
// but this will result in them being cut off
const float offset = 0.5;

// WIP
const bool rayMarching = false;

//-------------------------- AABB -------------------------

// https://gist.github.com/DomNomNom/46bb1ce47f68d255fd5d
// Compute the near and far intersections using the slab method.
// No intersection if tNear > tFar.
vec2 intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    return vec2(tNear, tFar);
}

bool insideAABB(vec3 p, vec3 boxMin, vec3 boxMax){
    float eps = 1e-4;
	return  (p.x > boxMin.x-eps) && (p.y > boxMin.y-eps) && (p.z > boxMin.z-eps) && 
			(p.x < boxMax.x+eps) && (p.y < boxMax.y+eps) && (p.z < boxMax.z+eps);
}

bool testAABB(vec3 org, vec3 dir, vec3 boxMin, vec3 boxMax){
    return insideAABB(org, boxMin, boxMax);
	vec2 intersections = intersectAABB(org, dir, boxMin, boxMax);
	
    if(insideAABB(org, boxMin, boxMax)){
        intersections.x = 1e-4;
    }
    
    return intersections.x > 0.0 && (intersections.x < intersections.y);
}

//-------------------------------- Blackbody --------------------------------

// Blackbody code from https://www.shadertoy.com/view/WsccDH

// Convert sRGB-int8 to linear RGB-float
vec3 rgb(int r, int g, int b){
    return pow(vec3(r,g,b)/255., vec3(2.2));
}

vec3 rgb(int a){
    int r = (a>>16) & 0xff;
    int g = (a>>8) & 0xff;
    int b = a & 0xff;
    return rgb(r,g,b);
}

vec3 colorFromTemperature( float t ){
    // Convert a temperature in Kelvin to a color
    vec3 col = vec3(0);
    col = mix(col, rgb(0xff3800), clamp(t/1000.,0.,1.));
    col = mix(col, rgb(0xff8912), clamp((t-1000.)/1000.,0.,1.));
    col = mix(col, rgb(0xffb46b), clamp((t-2000.)/1000.,0.,1.));
    col = mix(col, rgb(0xffd1a3), clamp((t-3000.)/1000.,0.,1.));
    col = mix(col, rgb(0xffe4ce), clamp((t-4000.)/1000.,0.,1.));
    col = mix(col, rgb(0xfff3ef), clamp((t-5000.)/1000.,0.,1.));
    col = mix(col, rgb(0xf5f3ff), clamp((t-6000.)/1000.,0.,1.));
    return col*t/3000.0;
}


//-------------------------------- Particles --------------------------------

// Get orthonormal basis from surface normal
// https://graphics.pixar.com/library/OrthonormalB/paper.pdf
void pixarONB(vec3 n, out vec3 b1, out vec3 b2){
	float sign_ = n.z >= 0.0 ? 1.0 : -1.0;
	float a = -1.0 / (sign_ + n.z);
	float b = n.x * n.y * a;
	b1 = vec3(1.0 + sign_ * n.x * n.x * a, sign_ * b, -sign_ * n.x);
	b2 = vec3(b, sign_ + n.y * n.y * a, -n.y);
}

// https://www.shadertoy.com/view/lsfGDB
vec3 intersectCoordSys(in vec3 ro, in vec3 rd, vec3 dc, vec3 du, vec3 dv){
	vec3 oc = ro - dc;
	return vec3(
        dot(cross(du, dv), oc),
		dot(cross(oc, du), rd),
		dot(cross(dv, oc), rd)) / 
        dot(cross(dv, du), rd);
}

//-------------------------------- Colour --------------------------------

// Unbelievable mileage from this function
float getGlow(float dist, float radius, float intensity){
    dist = max(dist, 1e-6);
	return pow(radius/dist, intensity);
}

// https://iquilezles.org/articles/palettes/
vec3 getGradient(float t){

    t *= 1.0;
    t += 0.5*iTime;

    vec3 a = vec3(0.65);
    vec3 b = 1.0 - a;
    vec3 c = vec3(1.0,1.0,1.0);
    vec3 d = vec3(0.15,0.5,0.75);

    return pow(a + b * cos(TWO_PI * (c * t + d)), vec3(2.2));
}


//-------------------------------- Voxels --------------------------------
vec3 hash33(vec3 p3){
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

// https://www.shadertoy.com/view/4dfGzs
vec3 traceVoxels(vec3 org, vec3 rayDir, inout vec3 totalTransmittance){
    org *= 0.5 * scale;
    
	vec3 cell = floor(org);
	vec3 delta = 1.0 / rayDir;
	vec3 dir = sign(rayDir);
    
    vec3 mask = vec3(0);
	vec3 axisDist = (cell - org + 0.5 + dir * 0.5) * delta;
	
    // Create a coordinate system from the ray direction
    vec3 n = -rayDir;
    vec3 tangent;
    vec3 bitangent;
    pixarONB(n, tangent, bitangent);
    tangent = normalize(tangent);
    bitangent = normalize(bitangent);
    
    vec3 col = vec3(0);
    
    // Shift between clean red flame and sooty gradient flame
    float mode = smoothstep(-0.1, 0.1, sin(0.5 * iTime));
	
    for(int i = 0; i < 200; i++){
    
        vec4 data = getData(cell, iChannel1);
        
        if(data.a > 0.0){
        
            vec3 pos = cell + 0.5;
            pos += remap(hash33(cell+iTime), vec3(0), vec3(1), vec3(-offset), vec3(offset));

            vec3 intersection = intersectCoordSys(org, rayDir, pos, tangent, bitangent);

            // Distance of intersection in disc uv space
            float d = dot(intersection.yz, intersection.yz);
            // Gradient in density
            float s = smoothstep(0.0, 0.25, data.a);
            
            vec3 luminance = data.a * getGradient(data.a);
            luminance = mix(luminance, colorFromTemperature(20000.0 * data.a), mode);
            float glow =  mix(0.2, 0.5, s) * mix(0.2, clamp(getGlow(d, 0.25, 1.5), 0.0, 32.0), s);
            luminance *= 2.0*glow;
            
            vec3 sampleSigmaE = 8.0 * vec3(mix(0.1, 0.001 + data.a, mode));
            
            vec3 transmittance = exp(-sampleSigmaE * glow);
 
            col += totalTransmittance * luminance / sampleSigmaE; 
            totalTransmittance *= transmittance;
            
            if(length(totalTransmittance) <= 0.001){
                totalTransmittance = vec3(0.0);
                return col;
            }
        }
        
        // Create 1 for whichever component is smallest and 0 for others
		mask = step(axisDist.xyz, axisDist.yzx) * step(axisDist.xyz, axisDist.zxy);
        // Step axis-delta amount along the minimum axis and 0 for others
		axisDist += mask * dir * delta;
        // Increment cell
        cell += mask * dir;

        // Return when outside the domain
        if( (dir.x < 0.0 && cell.x < -0.5*scale.x) || 
            (dir.x > 0.0 && cell.x >= 0.5*scale.x) || 
            (dir.y < 0.0 && cell.y < -0.5*scale.y) || 
            (dir.y > 0.0 && cell.y >= 0.5*scale.y) || 
            (dir.z < 0.0 && cell.z < -0.5*scale.z) || 
            (dir.z > 0.0 && cell.z >= 0.5*scale.z)){
            return col;
        }
	}

	return col;
}

vec3 rayMarch(vec3 org, vec3 rayDir, inout vec3 totalTransmittance, float dist, float dither){
    
    org *= 0.5 * scale;
    dist *= 0.5 * float(width);
    
    const float stepCount = 16.0;
    float stepS = (dist/stepCount);
    
    vec3 p = org + rayDir * stepS * dither;
    
    vec3 col = vec3(0);
    
    // Shift between clean red flame and sooty gradient flame
    float mode = smoothstep(-0.1, 0.1, sin(0.5 * iTime));
	
    for(int i = 0; i < int(stepCount); i++){
    
        vec4 data = getDataInterpolated(p + 0.5 * scale, iChannel1);
        
        vec3 pos = p;
        pos += remap(hash33(floor(p) + 0.5 + iTime), vec3(0), vec3(1), vec3(-offset), vec3(offset));
        
        // Distance to voxel centre
        float d = length(floor(p) + 0.5 - pos);
        // Gradient in density
        float s = smoothstep(0.0, 0.25, data.a);
        
        if(data.a > 0.0){
            
            vec3 luminance = data.a * getGradient(data.a);
            luminance = mix(luminance, colorFromTemperature(20000.0 * data.a), mode);
            float glow = mix(0.2, clamp(getGlow(d, 0.75, 5.0), 0.0, 32.0), s);
            luminance *= glow;
            
            vec3 sampleSigmaE = 8.0 * vec3(mix(mix(0.025, 0.1, s), 0.001 + data.a, mode));
           
            vec3 transmittance = exp(-sampleSigmaE * stepS * glow);
 
            col += totalTransmittance * luminance / sampleSigmaE; 
            totalTransmittance *= transmittance;
            
            if(length(totalTransmittance) <= 0.001){
                totalTransmittance = vec3(0.0);
                return col;
            }
        }
        

        p += stepS * rayDir;
	}

	return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    //----------------- Define a camera -----------------

    // Get the default direction of the ray (along the negative Z direction)
    vec3 rayDir = rayDirection(55.0, fragCoord, iResolution.xy);


    vec3 cameraPos = texelFetch(iChannel0, ivec2(0.5, 1.5), 0).xyz;
    vec3 targetDir = -cameraPos;
    vec3 up = vec3(0.0, 1.0, 0.0);

    // Get the view matrix from the camera orientation
    mat3 viewMatrix = lookAt(targetDir, up);

    // Transform the ray to point in the correct direction
    rayDir = normalize(viewMatrix * rayDir);

    //---------------------------------------------------

    vec3 col = 0.2 * vec3(0.1, 0.15, 0.25);
    vec3 data;

    vec2 intersections = intersectAABB(cameraPos, rayDir, vec3(-1.0-(1.0/scale)), 
                                                          vec3(1.0+(1.0/scale)));
    if(intersections.x < intersections.y){
        vec3 totalTransmittance = vec3(1);
        vec3 p = cameraPos + rayDir * max(0.0, intersections.x);
        
    if(rayMarching){
        float dither = 0.0;
        const float goldenRatio = 1.61803398875;
            if(iChannelResolution[2].xy == vec2(1024)){
                float blueNoise = texture(iChannel2, fragCoord / 1024.0).r;
                dither = fract(blueNoise + float(iFrame%32) * goldenRatio);
            }
            data = rayMarch(p, rayDir, totalTransmittance, intersections.y - intersections.x, dither);
        }else{
            data = traceVoxels(p, rayDir, totalTransmittance);
        }
        
        
        col = mix(data, col, totalTransmittance);
    }

    fragColor = vec4(col, 1.0);
}