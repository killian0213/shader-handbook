// Cube A (cubemap) — HEAVENLY CREATURE by alro
// https://www.shadertoy.com/view/ddyBRy

/*

    Store signed distance field in the first frame in the alpha channel.
    Find density along light ray in the second frame and store it in the red channel.
    Store some glow gradients for stars in the green channel.
    Second to fourth frames mix surrounding data to get rid of voxel artefacts.
    From the on copy data every frame.

*/

// Does exactly what it says. Compile and reset timer to see change.
const bool eightRabbits = false;


//-------------------------------- Shape --------------------------------

// A neural representation of the Stanford rabbit taken from https://www.shadertoy.com/view/wtVyWK
// Can be replaced with any arbitrary shape
float getSDF(vec3 p) {
    if(eightRabbits){
        p = mod(p*2.0, 1.0);
    }
    // Flip, position and scale the rabbit
    p = p.xzy;
    p -= vec3(0.55, 0.47, 0.435);
    p *= 1.325;
    

    // What follows is sinister magic not meant for mortal minds
    
    if (length(p) > 1.0) {
        return length(p) - 0.8;
    }

    vec4 f00=sin(p.y*vec4(-3.02,1.95,-3.42,-.60)+p.z*vec4(3.08,.85,-2.25,-.24)-p.x*
    vec4(-.29,1.16,-3.74,2.89)+vec4(-.71,4.50,-3.24,-3.50));
    vec4 f01=sin(p.y*vec4(-.40,-3.61,3.23,-.14)+p.z*vec4(-.36,3.64,-3.91,2.66)-p.x*
    vec4(2.90,-.54,-2.75,2.71)+vec4(7.02,-5.41,-1.12,-7.41));
    vec4 f02=sin(p.y*vec4(-1.77,-1.28,-4.29,-3.20)+p.z*vec4(-3.49,-2.81,-.64,2.79)-p.x*
    vec4(3.15,2.14,-3.85,1.83)+vec4(-2.07,4.49,5.33,-2.17));
    vec4 f03=sin(p.y*vec4(-.49,.68,3.05,.42)+p.z*vec4(-2.87,.78,3.78,-3.41)-p.x*
    vec4(-2.65,.33,.07,-.64)+vec4(-3.24,-5.90,1.14,-4.71));
    vec4 f10=sin(mat4(-.34,.06,-.59,-.76,.10,-.19,-.12,.44,.64,-.02,-.26,.15,-.16,.21,.91,.15)*f00+
        mat4(.01,.54,-.77,.11,.06,-.14,.43,.51,-.18,.08,.39,.20,.33,-.49,-.10,.19)*f01+
        mat4(.27,.22,.43,.53,.18,-.17,.23,-.64,-.14,.02,-.10,.16,-.13,-.06,-.04,-.36)*f02+
        mat4(-.13,.29,-.29,.08,1.13,.02,-.83,.32,-.32,.04,-.31,-.16,.14,-.03,-.20,.39)*f03+
        vec4(.73,-4.28,-1.56,-1.80))/1.0+f00;
    vec4 f11=sin(mat4(-1.11,.55,-.12,-1.00,.16,.15,-.30,.31,-.01,.01,.31,-.42,-.29,.38,-.04,.71)*f00+
        mat4(.96,-.02,.86,.52,-.14,.60,.44,.43,.02,-.15,-.49,-.05,-.06,-.25,-.03,-.22)*f01+
        mat4(.52,.44,-.05,-.11,-.56,-.10,-.61,-.40,-.04,.55,.32,-.07,-.02,.28,.26,-.49)*f02+
        mat4(.02,-.32,.06,-.17,-.59,.00,-.24,.60,-.06,.13,-.21,-.27,-.12,-.14,.58,-.55)*f03+
        vec4(-2.24,-3.48,-.80,1.41))/1.0+f01;
    vec4 f12=sin(mat4(.44,-.06,-.79,-.46,.05,-.60,.30,.36,.35,.12,.02,.12,.40,-.26,.63,-.21)*f00+
        mat4(-.48,.43,-.73,-.40,.11,-.01,.71,.05,-.25,.25,-.28,-.20,.32,-.02,-.84,.16)*f01+
        mat4(.39,-.07,.90,.36,-.38,-.27,-1.86,-.39,.48,-.20,-.05,.10,-.00,-.21,.29,.63)*f02+
        mat4(.46,-.32,.06,.09,.72,-.47,.81,.78,.90,.02,-.21,.08,-.16,.22,.32,-.13)*f03+
        vec4(3.38,1.20,.84,1.41))/1.0+f02;
    vec4 f13=sin(mat4(-.41,-.24,-.71,-.25,-.24,-.75,-.09,.02,-.27,-.42,.02,.03,-.01,.51,-.12,-1.24)*f00+
        mat4(.64,.31,-1.36,.61,-.34,.11,.14,.79,.22,-.16,-.29,-.70,.02,-.37,.49,.39)*f01+
        mat4(.79,.47,.54,-.47,-1.13,-.35,-1.03,-.22,-.67,-.26,.10,.21,-.07,-.73,-.11,.72)*f02+
        mat4(.43,-.23,.13,.09,1.38,-.63,1.57,-.20,.39,-.14,.42,.13,-.57,-.08,-.21,.21)*f03+
        vec4(-.34,-3.28,.43,-.52))/1.0+f03;
    f00=sin(mat4(-.72,.23,-.89,.52,.38,.19,-.16,-.88,.26,-.37,.09,.63,.29,-.72,.30,-.95)*f10+
        mat4(-.22,-.51,-.42,-.73,-.32,.00,-1.03,1.17,-.20,-.03,-.13,-.16,-.41,.09,.36,-.84)*f11+
        mat4(-.21,.01,.33,.47,.05,.20,-.44,-1.04,.13,.12,-.13,.31,.01,-.34,.41,-.34)*f12+
        mat4(-.13,-.06,-.39,-.22,.48,.25,.24,-.97,-.34,.14,.42,-.00,-.44,.05,.09,-.95)*f13+
        vec4(.48,.87,-.87,-2.06))/1.4+f10;
    f01=sin(mat4(-.27,.29,-.21,.15,.34,-.23,.85,-.09,-1.15,-.24,-.05,-.25,-.12,-.73,-.17,-.37)*f10+
        mat4(-1.11,.35,-.93,-.06,-.79,-.03,-.46,-.37,.60,-.37,-.14,.45,-.03,-.21,.02,.59)*f11+
        mat4(-.92,-.17,-.58,-.18,.58,.60,.83,-1.04,-.80,-.16,.23,-.11,.08,.16,.76,.61)*f12+
        mat4(.29,.45,.30,.39,-.91,.66,-.35,-.35,.21,.16,-.54,-.63,1.10,-.38,.20,.15)*f13+
        vec4(-1.72,-.14,1.92,2.08))/1.4+f11;
    f02=sin(mat4(1.00,.66,1.30,-.51,.88,.25,-.67,.03,-.68,-.08,-.12,-.14,.46,1.15,.38,-.10)*f10+
        mat4(.51,-.57,.41,-.09,.68,-.50,-.04,-1.01,.20,.44,-.60,.46,-.09,-.37,-1.30,.04)*f11+
        mat4(.14,.29,-.45,-.06,-.65,.33,-.37,-.95,.71,-.07,1.00,-.60,-1.68,-.20,-.00,-.70)*f12+
        mat4(-.31,.69,.56,.13,.95,.36,.56,.59,-.63,.52,-.30,.17,1.23,.72,.95,.75)*f13+
        vec4(-.90,-3.26,-.44,-3.11))/1.4+f12;
    f03=sin(mat4(.51,-.98,-.28,.16,-.22,-.17,-1.03,.22,.70,-.15,.12,.43,.78,.67,-.85,-.25)*f10+
        mat4(.81,.60,-.89,.61,-1.03,-.33,.60,-.11,-.06,.01,-.02,-.44,.73,.69,1.02,.62)*f11+
        mat4(-.10,.52,.80,-.65,.40,-.75,.47,1.56,.03,.05,.08,.31,-.03,.22,-1.63,.07)*f12+
        mat4(-.18,-.07,-1.22,.48,-.01,.56,.07,.15,.24,.25,-.09,-.54,.23,-.08,.20,.36)*f13+
        vec4(-1.11,-4.28,1.02,-.23))/1.4+f13;
    return dot(f00,vec4(.09,.12,-.07,-.03))+dot(f01,vec4(-.04,.07,-.08,.05))+
        dot(f02,vec4(-.01,.06,-.02,.07))+dot(f03,vec4(-.05,.07,.03,.04))-0.16;
}

//-------------------------------- Detail --------------------------------

// Noise for carving cloud surface detail

// https://en.wikipedia.org/wiki/Gyroid
// https://www.shadertoy.com/view/wddfDM
float gyroid(vec3 p, float thickness, float bias, float frequency){
    return clamp(abs(dot(sin(p*0.5), cos(p.zxy*1.23) * frequency) - bias) - thickness, 0.0, 3.0)/3.0;
}

// Gyroid noise based on https://www.shadertoy.com/view/3l23Rh
float fbm(vec3 p){

    const int octaves = 12;
    const float fbmScale = 1.95;

    // Rotation of the gyroid every iteration to produce a noise look
    const float a = PI / float(octaves);
    const mat3 m3 = fbmScale * mat3(cos(a), sin(a), 0, -sin(a), cos(a), 0, 0, 0, 1);


    float weight = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    float res = 0.0;
    
    for(int i = min(0, iFrame); i < octaves; i++){
        res += amplitude * gyroid(p, 0.1, 0.0, frequency);
        p *= m3;
        weight += amplitude;
        amplitude *= (i < 4 ? 0.9 : 0.7);
        frequency *= 0.78;
    }
    
    return saturate(res / weight);
}

//---------------------- Light density sampling -------------------------

// Get orthonormal basis
// https://graphics.pixar.com/library/OrthonormalB/paper.pdf
void pixarONB(vec3 n, out vec3 b1, out vec3 b2){
	float sign_ = n.z >= 0.0 ? 1.0 : -1.0;
	float a = -1.0 / (sign_ + n.z);
	float b = n.x * n.y * a;
	b1 = vec3(1.0 + sign_ * n.x * n.x * a, sign_ * b, -sign_ * n.x);
	b2 = vec3(b, sign_ + n.y * n.y * a, -n.y);
}

// Collect total density along light ray
float lightDensity(vec3 p){
	float lightRayDensity = 0.0;
    
    vec3 tangent;
    vec3 bitangent;

    pixarONB(sunDirection, tangent, bitangent);

    tangent = normalize(tangent);
    bitangent = normalize(bitangent);
    
	for(uint j = 0u; j < lightSteps; j++){
        vec3 samplePoint = p + sunDirection * float(j) * stepL;
        
        // Disperse farther samples away from the light vector and reduce the strength of those samples
        float dist = mix(0.0, 25.0, float(j) / float(lightSteps));
        float weight = mix(1.0, 0.0, float(j) / float(lightSteps));
        
        vec2 rand = dist * (2.0 * hash33(samplePoint).xz - 1.0);
        samplePoint += tangent * rand.x + bitangent * rand.y;
        
        // Do not read beyond the domain
        if(insideAABB(samplePoint, -0.5 * scale, 0.5 * scale)){
            lightRayDensity += weight * getDataInterpolated(samplePoint, iChannel0).a;
        }
	}
    return lightRayDensity;
}

//-------------------------------- Stars --------------------------------

float getGlow(float dist, float radius, float intensity){
    dist = max(dist, 1e-6);
	return pow(radius/dist, intensity);
}

// Stars with random placement and strength
float getStars(vec3 p){
    p *= 0.02;
    p += 80.0;
    vec3 rand;
    float d = 1e10;
    vec3 cell;
    
    for(int x = -1; x <= 1; x++){
        for(int y = -1; y <= 1; y++){
            for(int z = -1; z <= 1; z++){
                vec3 c = floor(p) + vec3(x, y, z);
                vec3 h = hash33(c);
                vec3 f = c + 0.5 + 0.5 * h;
                float dd = length(p - f);
                if(dd < d){
                    d = dd;
                    rand = h;
                    cell = c;
                }
            }
        }
    }
    rand = clamp(0.5 + 0.5 * rand, 0.0, 1.0);
    vec3 rand2 = clamp(0.5 + 0.5 * hash33(cell+vec3(3.12, 104.9, -9.5)), 0.0, 1.0);
    return  rand.z * 
            step(0.9, rand2.z) * 
            smoothstep(0.5, 0.0, d) * 
            min(getGlow(d, 0.5, 1.0), 256.0);
}


//-------------------------------- Storage --------------------------------

void mainCubemap( out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir ){
    
    vec3 rd = abs(rayDir);

    uint face;
    if(rd.x > rd.y && rd.x > rd.z){
        face = rayDir.x > 0.0 ? 0u : 1u;
    }else if(rd.y > rd.z){
        face = rayDir.y > 0.0 ? 2u : 3u;
    }else{
        face = rayDir.z > 0.0 ? 4u : 5u;
    }

    uint idx = face * 1024u * 1024u + uint(fragCoord.y) * 1024u + uint(fragCoord.x);
    
    if(idx < maxIdx){
    
        if(iFrame == 0 || iFrame == 10){

            vec3 pos = idxToPoint(idx);
            // Carve away density from cloud based on noise.
            float cloud = getSDF(pos / float(width));
            cloud = smoothstep(0.3, -0.1, cloud);
            cloud = saturate(remap(cloud, 0.9 * (1.0 - fbm(pos / 8.0)), 1.0, 0.0, 0.15));
            fragColor = vec4(cloud);

        }else if(iFrame < 4 || (iFrame > 10 && iFrame < 14)){
        
            int frame = iFrame < 4 ? iFrame - 1 : iFrame - 11;
        
            // Sample neighbouring data to get rid of voxel artefacts and smooth the volume
            // This also blurs the staggered sampling of the light density
            vec3 pos = idxToPoint(idx)+mix(-0.5, 0.5, float(frame)/2.0) - 0.5 * scale;
            fragColor = getDataInterpolated(pos, iChannel0);

            if(iFrame == 1 || iFrame == 11){
                float lightRayDensity = lightDensity(pos);
                fragColor.r = lightRayDensity;
                
                // Stars
                fragColor.g = getStars(3.5*pos + 17.51) + 
                              getStars(2.4*pos - 6.2) +
                              getStars(3.7*pos + 109.9);
            }

        }else{
            fragColor = texture(iChannel0, rayDir);
       }
    }else{
       fragColor = vec4(0);
    }
}