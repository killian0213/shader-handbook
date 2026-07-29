// Buffer A (buffer) — Arcane Lands by Dave_Hoskins
// https://www.shadertoy.com/view/XdcfR7

// by David Hoskins.

// This is the Data buffer, holds everything that only uses one pixel to calculate.
// I don't know if it efficient to do this but it appears to work well with complex shaders...


//----------------------------------------------------------------------------------------
float grabTime()
{
  	float m = (iMouse.x/iResolution.x)*80.0;
	return (iTime+m+410.)*32.;
}

//----------------------------------------------------------------------------------------
int StoreIndex(ivec2 p)
{
	return p.x + 64 * p.y;
}

//----------------------------------------------------------------------------------------
void mainImage( out vec4 fragColour, in vec2 fragCoord )
{
    ivec2 pos = ivec2(fragCoord);
    vec4 col = vec4(0.);
	float gTime = grabTime();
    
    int num = StoreIndex(pos);
    if (num >= LAST) discard;
    
    float r = gTime / 63.;
    vec3 camPos, camTar;
    mat3 camMat;
    if (num <= CAMERA_MAT2)
    {
    	camPos = cameraPath(gTime)+vec3(sin(r*.4 )*24., cos(r*.3)*24., 0.);
    	camTar = cameraPath(gTime + 30.);
        camMat = setCamMat(camPos, camTar, (camTar.x-camPos.x)*.02);
    }

    switch (num)
    {
        case CAMERA_POS:
        	col.xyz = camPos;
    		break;
        case CAMERA_TAR:
            col.xyz = camTar;
        	break;
        case CAMERA_MAT0:
	       	col.xyz = camMat[0];
        	break;
		case CAMERA_MAT1:
        	col.xyz = camMat[1];
        	break;
        case CAMERA_MAT2:
        	col.xyz = camMat[2];
        	break;
        case SUN_DIRECTION:
        	col.xyz  = normalize( vec3(  0.3, .75, .4 ) );
    		break;
    }
    fragColour = col;
 
    
}