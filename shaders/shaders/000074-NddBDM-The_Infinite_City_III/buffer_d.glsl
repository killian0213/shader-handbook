// Buffer D (buffer) — The Infinite City III by fancyzero
// https://www.shadertoy.com/view/NddBDM

#define KEY_W 87
#define KEY_A 65
#define KEY_S 83
#define KEY_D 68
#define KEY_Q 81
#define KEY_E 69
#define KEY_G 71
#define KEY_SHIFT 16

#define GET_KEY(k) (texture(iChannel0, vec2(float(k) / 256.0, 0.1) ).x)
#define GET_TOGGLE(k) (texture(iChannel0, vec2(float(k) / 256.0, 0.9) ).x)
#define PI 3.1419

#define MOVE_SPEED 20.0

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if (iFrame < 1) //Camera start position and rotation
    {
     	if (fragCoord.x <= 2.0)
        {
            if (fragCoord.x < 1.0)
            {
				fragColor = vec4(100,100,1, 0.0);
            }
            else fragColor = vec4(0.0);
        }
    }
    else if (fragCoord.y < 1.0 && fragCoord.x <= 2.0)
    {
        vec2 mousePos = iMouse.xy / iResolution.xy - 0.5;
        
        if (iMouse.x < 1.0 && iMouse.y < 1.0) mousePos = vec2(0.0); 

        float yaw = mousePos.x * PI * 2.0+PI;
        float pitch = -mousePos.y*0.5 * PI+PI;

        //Same matrix construction as in common tab
        mat3 cameraRotation = mat3(cos(yaw), 0.0, -sin(yaw),
                                0.0, 1.0, 0.0,
                                sin(yaw), 0.0, cos(yaw)) *
            				mat3(1.0, 0.0, 0.0,
                                  0.0, cos(pitch), -sin(pitch),
                                  0.0, sin(pitch), cos(pitch));
                            

        vec3 forward = cameraRotation * vec3(0, 0, 1);
        vec3 right = normalize(cross(vec3(0, 1, 0), forward));
        vec3 up = normalize(cross(forward, right));

        float keyW = GET_KEY(KEY_W);
        float keyA = GET_KEY(KEY_A);
        float keyS = GET_KEY(KEY_S);
        float keyD = GET_KEY(KEY_D);
        float keyQ = GET_KEY(KEY_Q);
        float keyE = GET_KEY(KEY_E);
        float toggleG = GET_TOGGLE(KEY_G);
        float keyShift = GET_KEY(KEY_SHIFT);
        
        if (fragCoord.x < 1.0)
        {
            float speedBoost = (1.0 + keyShift * 3.0);
            vec3 cameraPos = texture(iChannel1, vec2(0.0, 0.0)).xyz;
            cameraPos += forward * (keyW - keyS) * iTimeDelta * MOVE_SPEED * speedBoost;
            cameraPos += right * (keyD - keyA) * iTimeDelta * MOVE_SPEED * speedBoost;
            cameraPos += up * (keyE - keyQ) * iTimeDelta * MOVE_SPEED * speedBoost;
            fragColor = vec4(cameraPos, toggleG);
        }
        else
        {
            vec2 cameraRotation = vec2(yaw, pitch);
            fragColor = vec4(cameraRotation, 0.0, 0.0);
        }
    }
}