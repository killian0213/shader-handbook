// Sound (sound) — [SH16B] Mach 1 by P_Malin
// https://www.shadertoy.com/view/MttGz4

#define INVERT_STEREO

//////////////////////////////////////

///////////////////////////
// Camera
///////////////////////////

struct CameraState
{
    vec3 vPos;
    vec3 vTarget;
    float fFov;
    float fAperture;
};
   
mat3 Cam_GetWorldToCameraRotMatrix( const CameraState cameraState )
{
    vec3 vForward = normalize( cameraState.vTarget - cameraState.vPos );
	vec3 vRight = normalize( cross(vec3(0, 1, 0), vForward) );
	vec3 vUp = normalize( cross(vForward, vRight) );
    
    return mat3( vRight, vUp, vForward );
}    

struct SceneState
{
    vec3 vCarPos;
    float fThruster;
    float fDustTrail;
    float fCarVel;
};  
    
SceneState g_sceneState;

struct Sequence
{
    float fTime;
    float fLength;
    float fBlend;
    float fSmoothBlend;
};
    
Sequence Sequence_Init( float fTime )
{
    Sequence seq;
    seq.fTime = fTime;
    seq.fLength = 0.0;
    seq.fBlend = 0.0;
    seq.fSmoothBlend = 0.0;
    return seq;
}

bool Sequence_Next( inout Sequence seq, float fLength )
{
    seq.fTime -= seq.fLength;
    seq.fLength = fLength;
    seq.fBlend = seq.fTime / fLength;
    seq.fSmoothBlend = smoothstep( 0.0, 1.0, seq.fBlend );
    
    return seq.fTime >= 0.0 && seq.fTime < fLength;
}

struct CarInt
{
    float s;
    float u;
    float a;
};
    
void CarInt_Update( inout CarInt carInt, float fTime )
{
    carInt.s += carInt.u * fTime + .5 * carInt.a * fTime * fTime;
    carInt.u += carInt.a * fTime;
}

float CarInt_GetDisplacement( CarInt carInt, float fTime )
{
    return carInt.s + carInt.u * fTime + .5 * carInt.a * fTime * fTime;    
}

float CarInt_GetVelocity( CarInt carInt, float fTime )
{
    return carInt.u + carInt.a * fTime;
}

void GetSceneState( out SceneState scene, out CameraState camera, float fTime )
{
    scene.vCarPos = vec3(0.0);
    scene.fThruster = 0.0;
    scene.fDustTrail = 0.0;
    scene.fCarVel = 0.0;

    camera.vPos = vec3( 0.0, 1.0, -10.0 );
    camera.vTarget = vec3( 0.0, 0.0, 0.0 );
    camera.fFov = 15.0;
    camera.fAperture = 0.5;
    
    float fCameraShake = 0.0;

    //scene.fThruster = clamp( sin(iTime) * 0.5 + 0.5, 0.0, 1.0);
    //scene.fDustTrail = scene.fThruster;
    //    scene.vCarPos.z = -iTime * 100.0;//343.0;
        
    Sequence seq = Sequence_Init( fTime );

    CarInt carInt;
    carInt.s = 0.0;
    carInt.u = 0.0;
    carInt.a = 0.0;
    
    if ( Sequence_Next( seq, 8.0 ) )
    {
    }

    // Initial Vel
    carInt.u = 100.0;    
    if ( Sequence_Next( seq, 4.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = vec3( 0.0, 1.0, -100.0 );
        camera.vPos = camera.vTarget + vec3( 10.0, -0.5, -5.0 );
        
        //camera.vTarget = camera.vPos + normalize(camera.vTarget - camera.vPos) * 100.0 * (1.0 - seq.fBlend * 0.9);
    	//camera.fAperture = 1.5;
    }
    
    CarInt_Update( carInt, seq.fLength );

    // vel +50 in 10 secs
    carInt.a = 100.0 / 15.0;    

    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = scene.vCarPos + vec3( 0.0, 1.5, -15.0 );
        camera.vTarget.z += seq.fSmoothBlend * 20.0;
        camera.vPos = camera.vTarget + vec3( -8.0, 0.5, -3.0 );
        camera.fFov = 20.0;
    	camera.fAperture = 0.5;
        fCameraShake = 1.0;
    }
    CarInt_Update( carInt, seq.fLength );
    
    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = scene.vCarPos + vec3( 0.0, 2.0, -4.5 );
        camera.vPos = camera.vTarget + mix( vec3( -4.0, 2.0, -20.0 ), vec3( -30.0, 1.0, 40.0 ) ,seq.fBlend );
        camera.vTarget.z += seq.fBlend * 10.0;
        camera.fFov = mix( 25.0, 15.0, seq.fBlend );
    	camera.fAperture = 1.5;
        fCameraShake = 1.0;
    }    
    CarInt_Update( carInt, seq.fLength );
    
    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = scene.vCarPos + vec3( 0.0, 1.5, -2.5 );
        camera.vPos = camera.vTarget + mix( vec3( 10.0, 3.0, -20.0 ), vec3( -10.0, 3.0, -20.0 ) ,seq.fSmoothBlend );
        camera.fFov = 8.0;
    	camera.fAperture = 1.5;
        fCameraShake = 1.0;
    }
    
    CarInt_Update( carInt, seq.fLength );

    carInt.a = 0.0;    
    if ( Sequence_Next( seq, 3.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = scene.vCarPos + vec3( 1.5, 1.4, 5.5 );
        camera.vPos = camera.vTarget + vec3( 3.0, -0.5 + seq.fSmoothBlend * 2.0, 4.0+ pow( seq.fBlend, 4.0) * 16.0 );
        camera.fFov = 20.0;
    	camera.fAperture = 0.5;
        
        scene.fThruster = seq.fSmoothBlend;
        fCameraShake = 1.0;
    }

    // vel +150 in 10 secs
    carInt.a = 150.0 / 30.0;    
    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

        // Tail fin cam
	    camera.vTarget = scene.vCarPos + vec3( 0.0, 1.8, 3.5 );
        camera.vPos = camera.vTarget + vec3( 0.0, 1.2, 4.0 );
        camera.fFov = 35.0;
    	camera.fAperture = 0.3;
        
        scene.fThruster = 1.0;
        scene.fDustTrail = seq.fBlend * 0.1;
        fCameraShake = 1.0;
    }
    
    CarInt_Update( carInt, seq.fLength );


    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

	    camera.vTarget = scene.vCarPos + vec3( 0.0, 1.0, seq.fSmoothBlend * 10.5 );
        camera.vPos = camera.vTarget + vec3( 10.0, 2.0, -30.0 );
        camera.fFov = 15.0;
    	camera.fAperture = 0.5;

        scene.fThruster = 1.0;
        scene.fDustTrail = 0.1 + seq.fSmoothBlend * 0.9;
        fCameraShake = 1.0;
    }
    
    CarInt_Update( carInt, seq.fLength );

    if ( Sequence_Next( seq, 15.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

        camera.vTarget = scene.vCarPos + mix( vec3( 0.0, 1.0, 20.0 ), vec3( 0.0, 1.0, -15.0 ), seq.fBlend );
	    camera.vPos = camera.vTarget + vec3( -8.0, 1.0, 4.5 );
        camera.fFov = 20.0;
    	camera.fAperture = 0.4;

        scene.fThruster = 1.0;
        scene.fDustTrail = 1.0;
        fCameraShake = 1.0;
    }
    CarInt_Update( carInt, seq.fLength );
    
    if ( Sequence_Next( seq, 5.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

        // Tail fin cam
	    camera.vTarget = scene.vCarPos + vec3( 0.0, 1.8, 3.5 );
        camera.vPos = camera.vTarget + vec3( 0.0, 1.2, 4.0 );
        camera.fFov = 45.0;
    	camera.fAperture = 0.3;
        
        scene.fThruster = 1.0;
        scene.fDustTrail = 1.0;
        fCameraShake = 1.0;
    }
    CarInt_Update( carInt, seq.fLength );

    carInt.a = 0.0;    
    if ( Sequence_Next( seq, 17.0 ) )
    {
        scene.vCarPos.z = -CarInt_GetDisplacement( carInt, seq.fTime );
        scene.fCarVel = -CarInt_GetVelocity( carInt, seq.fTime );

        camera.vPos = vec3(0.0);
        camera.vPos.z = -CarInt_GetDisplacement( carInt, 0.0 );
        
        camera.vPos += vec3( 12.0, 0.5, -650.0 );
	    camera.vTarget = camera.vPos + vec3( -4.0, 0.0, 10.0 );
        
        camera.fFov = 10.0;
    	camera.fAperture = 0.5;
        
        scene.fThruster = 1.0;
        scene.fDustTrail = 1.0;
        fCameraShake = 1.0;
    }
    
    //camera.vTarget.y += (noise(camera.vPos * 0.2) - 0.5) * fCameraShake / length(camera.vTarget - camera.vPos);
    
    
    //camera = GetCameraState_MouseOrbitCar();
}

/////////////////////////////////////

struct C_Listener
{
    vec3 m_vPos;
    mat3 m_ToWorld;
    float m_fEarSeparation;
    vec3 m_vEarDirL;
    vec3 m_vEarDirR;
};

struct C_MixerValues
{
    vec2 m_vPan;
    vec2 m_vDopplerOffset;
};

struct C_Source
{
    vec3 m_Pos;
    float m_Volume;
};    
    
C_Source g_SourceInfo[4];

#define GET_VELOCITY(X, T) ((X(T + 0.1) - X(T)) / 0.1)

void SetupListener( out C_Listener listener, const in vec3 vCameraCurrPos, const in mat3 mCameraCurrRot )
{
    listener.m_vPos = vCameraCurrPos;
    listener.m_ToWorld = mCameraCurrRot;    
    listener.m_fEarSeparation = 0.1;
    listener.m_vEarDirL = normalize(vec3( -1.0, 0.0, 0.1));
    listener.m_vEarDirR = normalize(vec3( 1.0, 0.0, 0.1));    
}


void GetMixerValues( const in C_Listener listener, const in C_Source source, out C_MixerValues mixerValues )
{
    vec3 vLocalEarPosL = vec3(-listener.m_fEarSeparation, 0.0, 0.0);
    vec3 vLocalEarPosR = vec3( listener.m_fEarSeparation, 0.0, 0.0);
    
    vec3 vWorldEarPosL = listener.m_ToWorld * vLocalEarPosL + listener.m_vPos;
    vec3 vWorldEarPosR = listener.m_ToWorld * vLocalEarPosR + listener.m_vPos;

    vec3 vSourceToEarL = vWorldEarPosL - source.m_Pos;
    vec3 vSourceToEarR = vWorldEarPosR - source.m_Pos;
    
    vec2 vDist = vec2(length(vSourceToEarL), length(vSourceToEarR));
    const float kSpeedOfSound = 340.29;
    mixerValues.m_vDopplerOffset = -vDist / kSpeedOfSound;
    vec2 vVolume = vec2(source.m_Volume) / (vDist * vDist);

    vec3 vWorldEarDirL = normalize( listener.m_ToWorld * listener.m_vEarDirL );
    vec3 vWorldEarDirR = normalize( listener.m_ToWorld * listener.m_vEarDirR );
    vec2 vPan = clamp(vec2( dot(normalize(vSourceToEarL), vWorldEarDirL), dot(normalize(vSourceToEarR), vWorldEarDirR) ) * 0.4 + 0.6 , 0.0, 1.0);
    
    mixerValues.m_vPan = vPan * vVolume;
    
#ifdef INVERT_STEREO
    mixerValues.m_vPan = mixerValues.m_vPan.yx; // erm?!
#endif
}

#define DOPPLER_PER_EAR

#ifdef DOPPLER_PER_EAR
	#define MIX(SAMPLE_FN, TIME, MIXER_VALUES) (vec2(SAMPLE_FN(TIME + MIXER_VALUES.m_vDopplerOffset.x), SAMPLE_FN(TIME + MIXER_VALUES.m_vDopplerOffset.y)) * MIXER_VALUES.m_vPan);
#else
	#define MIX(SAMPLE_FN, TIME, MIXER_VALUES) (SAMPLE_FN(TIME + dot(MIXER_VALUES.m_vDopplerOffset, vec2(0.5))) * MIXER_VALUES.m_vPan);
#endif

/////////////////////////////////////


float Envelope( float time, float decay )
{	
	return exp2( -time * (5.0 / decay) );
}

float Envelope( float time, float attack, float decay )
{
	if( time < attack )
	{
		return time/attack;//exp2( -(attack - time) * (5.0 / attack) );
	}

	time -= attack;

	return Envelope( time, decay );
}


float Envelope( float time, float attack, float sustain, float decay )
{
	if( time < attack )
	{
		return time/attack;//exp2( -(attack - time) * (5.0 / attack) );
	}

	time -= attack;
	
	if(time < sustain)
	{
		return 1.0;
	}

	time -= sustain;
	
	return Envelope( time, decay );
}

float Tri( float t )
{
	return abs(fract( t ) * 4.0 - 2.0) - 1.0;
}

float Saw( float t )
{
	return fract( t ) * 2.0 - 1.0;
}

float Cos( float t )
{
	return cos( t * radians(360.0) );
}

float Square( float t )
{
	return step( fract(t), 0.5 ) * 2.0 - 1.0;
}

float Hash( float x )
{
	return fract(sin(x * 1.2345678)*123456.78);
}

float Noise( float x )
{
	return Hash( floor(x * 32.0) ) * 2.0 - 1.0;
}

float SmoothNoise( float t )
{
	float noiset = t * 32.0;
	float tfloor = floor(noiset);
	float ffract = fract(noiset);
	
	float n0 = Hash(tfloor);
	float n1 = Hash(tfloor + 1.0);
	float blend = ffract*ffract*(3.0 - 2.0*ffract);
	return mix(n0, n1, blend) * 2.0 - 1.0;
}

float FBM( float t, float persistence )
{
    float result = 0.0;
    
    float a = 1.0;
    float tot = 0.0;
    result += SmoothNoise(t) * a; tot += a; t *= 2.02; a *= persistence;
    result += SmoothNoise(t) * a; tot += a; t *= 2.02; a *= persistence; 
    result += SmoothNoise(t) * a; tot += a; t *= 2.02; a *= persistence; 
    result += SmoothNoise(t) * a; tot += a; t *= 2.02; a *= persistence; 
    tot += a; 
    return result / tot;
}

//////////////////////////////////////
/*
float GetSource0Sample(float t)
{     
    //return 0.0;
    return Square(220.0*fract(t)) * Envelope(fract(t), 0.05, 0.95);

    //return FBM( t * 30.0, 0.5 );
    //return Square(220.0*fract(t)) * Envelope(fract(t), 0.05, 0.95);
    //return Saw(220.0*fract(t)) * Envelope(fract(t), 0.05, 0.95);
    //return Cos(220.0*fract(t)) * Envelope(fract(t), 0.05, 0.95);
    //return Tri(220.0*fract(t)) * Envelope(fract(t), 0.05, 0.95);
}

vec3 GetSource0Pos(float t)
{
    return vec3(0.0, 0.0, 0.0);
}
*/

float GetSource0Sample(float t)
{        
    float s = FBM( t * 30.0 , 0.6 ) * 1.0
        + Saw(t*(440.0 - g_sceneState.fCarVel)) * 0.1
        + FBM( t * 30.0 , 0.4 ) * 2.0 * -g_sceneState.fCarVel / 300.0;
        
    return s;
}

vec3 GetSource0Pos(float t)
{
    return g_sceneState.vCarPos + vec3( 0.0, 0.0, 0.0 );
}


float GetSource1Sample(float t)
{        
    float s = FBM( t * 20.0 , 0.2 ) * 1.0 * g_sceneState.fThruster;
        
    return s;
    // + Saw(220.1*t + 0.5) * 0.5;
    
    //return FBM( t * 30.0, 0.5 );
    //return Square(440.0*fract(t)) * Envelope(fract(t), 0.05, 0.95);
    //return Saw(220.1*t + 0.5);// * Envelope(fract(t), 0.05, 0.95);
    //return Cos(440.0*fract(t)) * Envelope(fract(t), 0.05, 0.95);
    //return Tri(440.0*fract(t)) * Envelope(fract(t), 0.05, 0.95);
}

vec3 GetSource1Pos(float t)
{
    return g_sceneState.vCarPos + vec3( 0.0, 1.0, 5.8 );
}

float FBoom( float t )
{
    float fResult = 0.0;
    
    float a = 1.0;
    
    for ( int i=0; i<10; i++)
    {      
        if ( t > 0.0 )
        {
            fResult += SmoothNoise( t * 100.0 )*exp(-8.0*t) * a;
       	}
        t -= 0.2;        
	    a *= 0.4;
    }
    return fResult;
}

vec2 mainSound( in int samp,float time)
{
    float iTime = time;
    
    CameraState cam;       
    GetSceneState( g_sceneState, cam, time );
    
	vec3 vCameraCurrPos = cam.vPos;
    mat3 mCameraCurrRot = Cam_GetWorldToCameraRotMatrix( cam );    
    
    C_Listener listener;
    SetupListener( listener, vCameraCurrPos, mCameraCurrRot );

    g_SourceInfo[0].m_Pos = GetSource0Pos(time);
    g_SourceInfo[0].m_Volume = 50.0;

    g_SourceInfo[1].m_Pos = GetSource1Pos(time);
    g_SourceInfo[1].m_Volume = 50.0;
    
    vec2 vResult = vec2(0.0);    

    C_MixerValues mixerValues;

    GetMixerValues( listener, g_SourceInfo[0], mixerValues );
    vResult += MIX( GetSource0Sample, time, mixerValues );

    GetMixerValues( listener, g_SourceInfo[1], mixerValues );
    vResult += MIX( GetSource1Sample, time, mixerValues );

    vResult += FBoom( time - 61.85 ) * 8.0;
    
    if ( time < 8.0 || time > 75.0 )
    {
        vResult = vec2(0.0);
    }
    
    return vResult;   
}
