// Buffer A (buffer) — Racing Concept (in car) by eiffie
// https://www.shadertoy.com/view/MsKGWy

//eiffie - This is almost intact from the original https://www.shadertoy.com/view/lsK3RK by Imp5
//I changed the start/end positions to make it more challenging since driving "in car" is easier.

// GLSL Racing Concept
// Created by Alexey Borisov / 2016
// License: GPLv2


const float PI = 3.141592653;

const float KEY_A = 65.5 / 256.0;
const float KEY_W = 87.5 / 256.0;
const float KEY_S = 83.5 / 256.0;
const float KEY_D = 68.5 / 256.0;
const float KEY_R = 82.5 / 256.0;
const float KEY_LEFT = 37.5 / 256.0;
const float KEY_UP = 38.5 / 256.0;
const float KEY_DOWN = 40.5 / 256.0;
const float KEY_RIGHT = 39.5 / 256.0;

const float LAPS = 6.0;

const float IS_INITED = 0.5;
const float CAR_POSE = 1.5;
const float CAR_VEL = 2.5;
const float DEBUG_DOT = 3.5;
const float CAR_PROGRESS = 4.5;

const float MAX_SPEED = 1.2;

const float carLength = 0.045;
const float carWidth = 0.02;

float is_key_pressed(float key_code)
{
    return texture(iChannel1, vec2((key_code), 0.0)).x;
}

vec2 track_distort(vec2 pos)
{
    pos *= 0.5;    
    pos -= vec2(cos(pos.y * 2.4), sin(pos.x * 2.0 - 0.3 * sin(pos.y * 4.0))) * 0.59;
    return pos;
}

float track_val(vec2 pos)
{
    pos = track_distort(pos);
    return abs(1.0 - length(pos)) * 8.0 - 1.0;
}

vec2 track_grad(vec2 pos)
{
    const float d = 0.01;
    float v0 = track_val(pos);
    return vec2(track_val(pos + vec2(d, 0)) - v0, track_val(pos + vec2(0, d)) - v0) / d;
}

vec2 get_point_on_track(vec2 pos)
{
    for (int i = 8; i >= 0; i--)
        pos = pos - track_grad(pos) * float(i) * 0.001;
    
    return pos;
}

vec4 get_val(float variable, float index)
{
    return texture(iChannel0, vec2(variable, index) / iResolution.xy);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0.45, 0.0, 0.0, 1.0);
    vec4 debugDot = vec4(100.0, 100.0, 1.0, 1.0);
        
    if (fragCoord.y <= 8.0 && fragCoord.x <= 10.0)
    {
        float carIdx = fragCoord.y;
        if (get_val(IS_INITED, carIdx).x < 0.99 || is_key_pressed(KEY_R) > 0.5) // not inited
        {
            if (fragCoord.x < ceil(IS_INITED))
                fragColor = vec4(1, 0, 0, 1);
            else if (fragCoord.x < ceil(CAR_POSE))
            {
			if(carIdx<0.75)carIdx+=8.0;
                fragColor = vec4(1.2 + carIdx * 0.094 + (fract(carIdx * 0.5) - 0.2) * 0.2, 1.85 - carIdx * 0.074, -1.0, 0.8);
                fragColor.zw = normalize(fragColor.zw);
            }
            else if (fragCoord.x < ceil(CAR_VEL))
                fragColor = vec4(0.0, 0.0, 0.0, 0.0);
            else if (fragCoord.x < ceil(DEBUG_DOT))
                fragColor = vec4(1.0, 0.0, 0.0, 1.0);
            else
                fragColor = vec4(0.0, 0.0, 0.0, 0.0);               
        }
        else // inited
        {
            vec4 carPose = get_val(CAR_POSE, carIdx);
            vec2 carPos = carPose.xy;
            vec2 prevPos = carPos;
            vec2 carDir = carPose.zw;
            vec2 carLeft = normalize(vec2(-carDir.y, carDir.x));
            vec3 carVel3 = get_val(CAR_VEL, carIdx).xyz;
            vec2 carVel = carVel3.xy;
            float carOmega = carVel3.z;
            vec4 carProgress = get_val(CAR_PROGRESS, carIdx);
            
            // Detect dt manually,
            // this is workaround for iTimeDelta issue
            float timeLoop = mod(iTime, 128.0);
            float dt = clamp(timeLoop - carProgress.z, 0.01, 1.0 / 30.0);
            carProgress.z = timeLoop;
 
                       
            float timeAfterFinish = min(carProgress.y, 1.0);//clamp(iTime - 3.0, 0.0, 1.0);
           
            if (carIdx <= 1.0 && timeAfterFinish <= 0.0)
            {
                carOmega *= 0.96 - (dt - 1.0 / 60.0) * 8.0;
               
                if (is_key_pressed(KEY_W) > 0.5 || is_key_pressed(KEY_UP) > 0.5)
                    carVel += 1.0 * carDir * dt;
                if (is_key_pressed(KEY_S) > 0.5 || is_key_pressed(KEY_DOWN) > 0.5)
                    carVel -= 1.0 * carDir * dt;
               
                if (is_key_pressed(KEY_A) > 0.5 || is_key_pressed(KEY_LEFT) > 0.5)
                {
                    carOmega += 1.55 * dt;
                    carVel *= 0.999;
                }
                if (is_key_pressed(KEY_D) > 0.5 || is_key_pressed(KEY_RIGHT) > 0.5)
                {
                    carOmega -= 1.55 * dt;
                    carVel *= 0.999;                
                }
            }
            else
            {                
                carOmega *= 0.85 - (dt - 1.0 / 60.0) * 11.0;
               
                float accel = min(1.0, 0.9 +
                    0.1 * sin(carIdx + iTime * (0.25 + carIdx * 0.2)) - (floor(carIdx / 2.0) - 0.85) * 0.13);

                carVel += accel * carDir * dt;
                
                carVel *= clamp((5.0 - timeAfterFinish), 0.0, 1.0);
                //carSpeed = length(carVel);
                
                float posOnTrack = sin((carIdx + 2.0) * iTime * 0.2 + carIdx) * 0.025 + 0.97;
                                
                vec2 wishPos = posOnTrack * get_point_on_track(carPos + normalize(carDir) * (0.2 + length(carVel) * 0.4));
                //wishPos += vec2(0.0, 0.5) * timeAfterFinish;
                vec2 wishDir = normalize(wishPos - carPos);
                carOmega += 8.0 * dt * clamp(dot(wishDir, carLeft) * (5.0 - carIdx * 0.5), -1.0, 1.0) * min(carProgress.w - 0.8, 1.0);
                    
		       
	         //   debugDot.xy = wishPos;
            }
            
            if (carProgress.w < 1.0)
            	carVel = vec2(0.0, 0.0);
            
            carOmega = clamp(carOmega, -1.0, 1.0);
            carDir += carLeft * dt * min(length(carVel) * 4.0 * carOmega, 2.0);
            carDir = normalize(carDir);
                        
            float wall =
                max(track_val(carPos - carLeft * carWidth - carDir * carLength), 0.0) +
                max(track_val(carPos - carLeft * carWidth + carDir * carLength), 0.0) +
                max(track_val(carPos + carLeft * carWidth - carDir * carLength), 0.0) +
                max(track_val(carPos + carLeft * carWidth + carDir * carLength), 0.0);

            // collision with walls
            if (timeAfterFinish < 0.001)
            {
            	if (wall > 0.0)
            	{
	                carVel *= 1.0 - 0.04 * min(wall * 10.0, 1.0);
	            	carPos -= track_grad(carPos) * min(wall * 0.02, 0.02);
	                vec2 grad = track_grad(carPos);
	                vec2 gradLeft = normalize(vec2(-grad.y, grad.x));
	                carDir = normalize(carDir + dot(gradLeft, carDir) * gradLeft * length(carVel) * dt * 5.0);
	            }
            }
            else
            {
                carVel *= 1.0 - clamp((wall - 1.0) * 0.02, 0.0, 1.0);
            }
            
            // collision with cars
            {
                for (int i = 0; i < 8; i++)
                {
                   	float secondIdx = float(i) + .5;
                    if (abs(secondIdx - carIdx) > 0.5)
                    {
                        vec4 secondPose = get_val(CAR_POSE, secondIdx);
                        vec2 secondPos = secondPose.xy;
                        vec2 secondDir = secondPose.wz;
                        vec2 secondVel = get_val(CAR_VEL, secondIdx).xy;
                        
                        vec2 dir = normalize(carPos - secondPos);
                        float cDist = (carLength - carWidth);
                        float cWidth = carWidth * 2.1;
                        float k = 0.0;
                        k = max(k, (cWidth - length(carPos + cDist * carDir - secondPos - cDist * secondDir)) / cWidth);
                        k = max(k, (cWidth - length(carPos - cDist * carDir - secondPos - cDist * secondDir)) / cWidth);
                        k = max(k, (cWidth - length(carPos + cDist * carDir - secondPos + cDist * secondDir)) / cWidth);
                        k = max(k, (cWidth - length(carPos - cDist * carDir - secondPos + cDist * secondDir)) / cWidth);
                        k = max(k, (cWidth - length(carPos - cDist * carDir - secondPos)) / cWidth);
                        k = max(k, (cWidth - length(carPos + cDist * carDir - secondPos)) / cWidth);

                        carPos += dir * 0.02 * k;
                        carVel += dir * 0.2 * k;
                        carDir = normalize(carDir + secondDir * 0.1 * k);
                    }
                }
            }
            
            // friction
            {
                float carSpeed = min(length(carVel), MAX_SPEED * 1.1);
            	float fr = carSpeed / MAX_SPEED;
            	carSpeed = max(carSpeed - dt * (0.1 + fr * fr * fr), 0.0);
            	if (carSpeed > 0.00001)
	            	carVel = carSpeed * normalize(carVel + carDir * dt * 4.0);
            }
                                

            carPos += carVel * dt;
            
            //progress
            {
                vec2 trackPrev = prevPos;
                vec2 trackCur = carPos;
            	float prevAngle = atan(trackPrev.y, trackPrev.x);
            	float angle = atan(trackCur.y, trackCur.x);
            	float dAngle = angle - prevAngle;
            	dAngle = abs(dAngle) > 1.0 ? 0.0 : dAngle;
	                            
	            carProgress.x += dAngle / (2.0 * PI);
                
                if (carProgress.x > LAPS)
                    carProgress.y += dt;
                
                carProgress.w += dt * 0.3333;
            }
            
                        
            if (fragCoord.x < ceil(IS_INITED))
                fragColor = vec4(1, 1, 1, 1);
            else if (fragCoord.x < ceil(CAR_POSE))
            {
                fragColor.xy = carPos;
                fragColor.zw = carDir;
            }
            else if (fragCoord.x < ceil(CAR_VEL))
                fragColor = vec4(mix(carVel, carVel3.xy, 0.25), carOmega, 0.0);
            else if (fragCoord.x < ceil(DEBUG_DOT))
                fragColor = debugDot;
            else if (fragCoord.x < ceil(CAR_PROGRESS))
                fragColor = carProgress;
        }
    }
    else
        fragColor = vec4(0.0, 1.0, 0.0, 1.0);    
}