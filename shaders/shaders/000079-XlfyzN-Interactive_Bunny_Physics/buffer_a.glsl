// Buffer A (buffer) — Interactive Bunny Physics by ThomasSchander
// https://www.shadertoy.com/view/XlfyzN

// Contains quaterion code from https://www.shadertoy.com/view/lsG3W3
#define txBuf iChannel0
#define txSize iChannelResolution[0].xy
#define saturate(x) clamp(x, 0.0, 1.0)

mat3 QtToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  q = normalize (q);
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

vec4 RMatToQt (mat3 m)
{
  vec4 q;
  const float tol = 1e-6;
  q.w = 0.5 * sqrt (max (1. + m[0][0] + m[1][1] + m[2][2], 0.));
  if (abs (q.w) > tol) q.xyz =
     vec3 (m[1][2] - m[2][1], m[2][0] - m[0][2], m[0][1] - m[1][0]) / (4. * q.w);
  else {
    q.x = sqrt (max (0.5 * (1. + m[0][0]), 0.));
    if (abs (q.x) > tol) q.yz = vec2 (m[0][1], m[0][2]) / q.x;
    else {
      q.y = sqrt (max (0.5 * (1. + m[1][1]), 0.));
      if (abs (q.y) > tol) q.z = m[1][2] / q.y;
      else q.z = 1.;
    }
  }
  return normalize (q);
}

const float txRow = 128.;
vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}

void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord)
{
  vec2 d;
  float fi;
  fi = float (idVar);
  d = abs (fCoord - vec2 (mod (fi, txRow), floor (fi / txRow)) - 0.5);
  if (max (d.x, d.y) < 0.5) fCol = val;
}

mat3 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

#define NUM_PHYS_SPHERES 15
vec4 physProxy[] = vec4[](vec4(0.0336538, -0.213592, 0.0843372, 0.35474),
vec4(-0.192308, -0.0970871, 0.0903615, 0.262483),
vec4(-0.120192, 0.218447, -0.108434, 0.158823),
vec4(-0.278846, 0.131068, 0.0361445, 0.169385),
vec4(-0.0144231, 0.315534, -0.168675, 0.0801684),
vec4(-0.341346, 0.106796, 0.222892, 0.156275),
vec4(-0.192308, -0.354369, 0.253012, 0.126427),
vec4(-0.225962, -0.373786, 0.0361445, 0.127061),
vec4(0.317308, -0.315534, 0.108434, 0.146499),
vec4(-0.25, -0.417476, 0.168675, 0.0725712),
vec4(-0.0528846, 0.393204, -0.108434, 0.0474471),
vec4(-0.110577, -0.42233, -0.162651, 0.0710944),
vec4(-0.317308, 0.315534, -0.26506, 0.0679328),
vec4(-0.307692, 0.349515, -0.379518, 0.0577368),
vec4(-0.293269, 0.276699, -0.156627, 0.0891464));

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    mat3 bunnyRotation = QtToRMat(Loadv4(0));
    vec3 bunnyPos = Loadv4(3).xyz;
    vec3 bunnyVelocity = Loadv4(4).xyz;
    mat3 bunnyMomentum= QtToRMat(Loadv4(5));
    vec4 motionVals = Loadv4(1);
    
    mat3 earRotation = QtToRMat(Loadv4(6));
    vec3 earPos = Loadv4(7).xyz;
    mat3 earMomentum= QtToRMat(Loadv4(8));
    vec3 earVelocity = Loadv4(9).xyz;    

    if(iFrame == 0)
    {
        bunnyRotation = mat3(1.0);
        bunnyPos = vec3(0.0, 1.0, 0.0);
        bunnyVelocity = vec3(0.0);
        bunnyMomentum = mat3(1.0);
        
        earRotation = mat3(1.0);
        earPos = vec3(0.0, 1.0, 0.0);
        earVelocity = vec3(0.0);
        earMomentum = mat3(1.0);
        
        const float MAX_EAR_HEALTH = 0.05;
        motionVals = vec4(0.0, -MAX_EAR_HEALTH, 0.0, 0.0);
    }   
    
    if(iMouse.z > 0.0)
    {
      	bunnyVelocity.y += 0.4*iTimeDelta * (0.2+1.0*iMouse.y/iResolution.y - bunnyPos.y);        
        bunnyVelocity.x += 0.2*iTimeDelta * (0.5-iMouse.x/iResolution.x - bunnyPos.x);
        bunnyVelocity.z += 0.2*iTimeDelta * (-bunnyPos.z);
    }
    
    bool showEar = motionVals.y < 0.0;
          
    const float RESTITUTION = 0.4;
    vec3 surfaceNormal = vec3(0,1.0, 0.0);
    float M = 2.0;
    float invM = 1.0/M;
    float R = 0.5;
    float I = 2.0* M * R*R/5.0;//2mr*r / 5
    float invI = 1.0/I; 
    vec3 earDelta = vec3(0.185, 0.8, 0.25)-vec3(0.5);
    
    const float GRAVITY = 0.06;    
    bunnyVelocity.y -= iTimeDelta*GRAVITY;
    
    motionVals.x *= 0.2;
    for(int i = 0; i < NUM_PHYS_SPHERES; i++)
    {       
        if(!showEar && (i >= 12))
            continue;
            
        vec3 p0 = inverse(bunnyRotation)*(physProxy[i].xyz+vec3(0.0, 0.15, 0.0)) - vec3(0.0, physProxy[i].w, 0.0);       
        float thisPenetration = -(bunnyPos.y + p0.y);
        if(0.0 < thisPenetration)
        {
            vec3 hitPoint = p0;
            vec3 p1 = inverse(bunnyMomentum)*hitPoint;
        	vec3 pVel = bunnyVelocity + (p1-hitPoint); 
            if(pVel.y < 0.0) // if moving into the surface
            {                
                vec3 rCrossN = cross(p0, surfaceNormal);
                float thisImpulse = -(1.0+RESTITUTION)*dot(pVel, surfaceNormal)/(invM + invI*dot(rCrossN,rCrossN));                
                bunnyVelocity += surfaceNormal*thisImpulse*invM;  
            	vec3 rotCross = invI*cross(hitPoint, thisImpulse*surfaceNormal);
        		bunnyMomentum = bunnyMomentum*rotationMatrix(rotCross, length(rotCross));
                
                motionVals.x = max(motionVals.x, thisImpulse);
                if(motionVals.y < 0.0 && i >= 12)
                {
                    motionVals.y += max(0.0, abs(thisImpulse)-0.01);
                    if(motionVals.y > 0.0) // Ear is gone
                    {
                    	motionVals.y = iTime;
                    	motionVals.zw = p0.xz;
                        
                        earRotation = bunnyRotation;
                        earPos = bunnyPos + inverse(bunnyRotation) * (earDelta+vec3(0.0, 0.15, 0.0));
                        earMomentum = bunnyMomentum;
                        earVelocity = bunnyVelocity;
                        
                        // Toss the ear a bit away from bunny
                        earVelocity += vec3(0.0, 0.03, 0.0) + normalize(earPos-bunnyPos)*vec3(0.05, 0.0, 0.05);
                    }
                } 
#if 1 // Friction
                vec3 fripVel = pVel * vec3(1.0, 0.0, 1.0);
                float LfripVel = length(fripVel);
                if(LfripVel > 0.0)
                {
                	vec3 rCrossN = cross(p0, fripVel);
               		 thisImpulse = -(0.9)*LfripVel/(invM + invI*dot(rCrossN,rCrossN));
                
                	bunnyVelocity += fripVel*thisImpulse*invM;  
            		vec3 rotCross = invI*cross(hitPoint, thisImpulse*fripVel);
        			bunnyMomentum = bunnyMomentum*rotationMatrix(rotCross, length(rotCross));
                }
#endif                
            }
            bunnyPos.y += 0.6*max(0.0, thisPenetration - 0.001);
        }
    }
    
    bunnyVelocity *= pow(0.8, iTimeDelta); // Air friction
    bunnyPos += bunnyVelocity;
    bunnyRotation = bunnyRotation*bunnyMomentum;  
    
    if(!showEar)
    {        
        float M = 0.5;
        float invMear = 1.0/M;
    	float R = 0.1;
    	float I = 2.0* M * R*R/5.0;//2mr*r / 5
    	float invIear = 1.0/I;        
        earVelocity.y -= iTimeDelta*GRAVITY;
        for(int i = 12; i < NUM_PHYS_SPHERES; i++)
        {       
            vec3 p0 = inverse(earRotation)*(physProxy[i].xyz-earDelta) - vec3(0.0, physProxy[i].w, 0.0);       
            float thisPenetration = -(earPos.y + p0.y);
            if(0.0 < thisPenetration)
            {
                vec3 hitPoint = p0;
                vec3 p1 = inverse(earMomentum)*hitPoint;
                vec3 pVel = earVelocity + (p1-hitPoint); 
                if(pVel.y < 0.0) // if moving into the surface
                {                
                    vec3 rCrossN = cross(p0, surfaceNormal);
                    float thisImpulse = -(1.0+RESTITUTION)*dot(pVel, surfaceNormal)/(invMear + invIear*dot(rCrossN,rCrossN));                
                    earVelocity += surfaceNormal*thisImpulse*invM;  
                    vec3 rotCross = invI*cross(hitPoint, thisImpulse*surfaceNormal);
                    earMomentum = earMomentum*rotationMatrix(rotCross, length(rotCross));         
#if 1 // Friction
                    vec3 fripVel = pVel * vec3(1.0, 0.0, 1.0);
                    float LfripVel = length(fripVel);
                    if(LfripVel > 0.0)
                    {
                        vec3 rCrossN = cross(p0, fripVel);
                         thisImpulse = -LfripVel/(invMear + invIear*dot(rCrossN,rCrossN));

                        earVelocity += fripVel*thisImpulse*invM;  
                        vec3 rotCross = invI*cross(hitPoint, thisImpulse*fripVel);
                        earMomentum = earMomentum*rotationMatrix(rotCross, length(rotCross));
                    }
#endif  
                }
                earPos.y += 0.6*max(0.0, thisPenetration - 0.001);
            }
        }  
        
        earVelocity *= pow(0.3, iTimeDelta); // Air friction
    	earPos += earVelocity;
    	earRotation = earRotation*earMomentum;
    }   
        
    Savev4(0, RMatToQt(bunnyRotation), fragColor, fragCoord);
    Savev4(1, motionVals, fragColor, fragCoord);
    Savev4(3, vec4(bunnyPos, 1.0), fragColor, fragCoord);    
    Savev4(5, RMatToQt(bunnyMomentum), fragColor, fragCoord);
    Savev4(4, vec4(bunnyVelocity, 1.0), fragColor, fragCoord); 
    Savev4(6, RMatToQt(earRotation), fragColor, fragCoord);
    Savev4(7, vec4(earPos, 1.0), fragColor, fragCoord);    
    Savev4(8, RMatToQt(earMomentum), fragColor, fragCoord);
    Savev4(9, vec4(earVelocity, 1.0), fragColor, fragCoord);
 
}