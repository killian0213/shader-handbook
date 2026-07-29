// Buffer A (buffer) — LEGO Creator 5891 by Mathis
// https://www.shadertoy.com/view/DsSSWh

//Storage + G-Buffer

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Color = texture(iChannel0,fragCoord.xy*IRES);
    if (iFrame==0) { //Initialization
        if (fragCoord.x<10. && fragCoord.y<1.) { //Store vars
            if (fragCoord.x<1.) Color = vec4(0.,0.,0.,0.); //Mouse
            else if (fragCoord.x<2.) Color = vec4(-0.3,0.4,0.,0.); //Player Eye (Angles)
            else if (fragCoord.x<3.) Color = vec4(0.,0.,0.,1.); //Player Eye (Vector)
            else if (fragCoord.x<4.) Color = vec4(12.5,11.2,5.5,1.); //Player Pos
            else if (fragCoord.x<5.) Color = vec4(0.36,-0.2,0.,0.); //Sun angles
            else if (fragCoord.x<6.) Color = vec4(0.,0.,0.,0.); //Sun direction
            else if (fragCoord.x<9.) Color = vec4(0.,0.,0.,0.); //R-Value
            else if (fragCoord.x<10.) Color = vec4(0.,0.,0.,0.); //RTime
        } else if (DFBox(fragCoord-vec2(0.,1.),vec2(26.*3.,26.))<0.) {
            //Initializing the bricks
            float OutIndex = floor(fragCoord.x*I26);
            int CIndex = int(floor(mod(fragCoord.x,26.))+floor(fragCoord.y-1.)*26.);
            if (CIndex<512) {
                //Within the amount of bricks
                BRICK CBrick;
                if (CIndex<128) CBrick = BrickArray[CIndex];
                else if (CIndex<256) CBrick = BrickArray1[CIndex-128];
                else if (CIndex<384) CBrick = BrickArray2[CIndex-256];
                else if (CIndex<512) CBrick = BrickArray3[CIndex-384];
                float CIndexf = float(CIndex);
                vec3 CBrickP = CBrick.P;
                Color = ((OutIndex<0.5)?vec4(CBrickP,float(CBrick.I)+0.5):
                        ((OutIndex<1.5)?vec4(normalize(vec3(CBrick.Q.x,fract(abs(CBrick.Q.y))*sign(CBrick.Q.y),CBrick.Q.z)),
                        floor(abs(CBrick.Q.y))*ToRadians):
                        vec4(BrickColorArray[CBrick.Color],-length(CBrickP.xz-CBrick.P.xz))));
            }
        }
    } else { //Update
		if (fragCoord.x<16. && fragCoord.y<1.) { //Update vars
            if (fragCoord.x<1.) { //Mouse
                if (iMouse.z>0.) { //Börjat klicka
                    if (Color.w==0.) {
                    	Color.w = 1.;
                    	Color.xy = iMouse.zw;
                    }
                } else Color.w = 0.;
            } else if (fragCoord.x<2.) { //Player Eye (Angles)
                vec4 LMouse = texture(iChannel0,vec2(0.5,0.5)*IRES);
                if (LMouse.w==0.)  Color.zw = Color.xy;
                if (LMouse.w==1.) {
                	//Y led
                	Color.x = Color.z+(iMouse.y-LMouse.y)*0.01;
                	Color.x = clamp(Color.x,-2.8*0.5,2.8*0.5);
                	//X led
                	Color.y = Color.w-(iMouse.x-LMouse.x)*0.02;
               		Color.y = mod(Color.y,3.1415926*2.);
                }
            } else if (fragCoord.x<3.) { //Player Eye (Vector)
                vec3 Angles = texture(iChannel0,vec2(1.5,0.5)*IRES).xyz;
                Color.xyz = normalize(vec3(cos(Angles.x)*sin(Angles.y),
                  			   			sin(Angles.x),
                  			   			cos(Angles.x)*cos(Angles.y)));
            } else if (fragCoord.x<4.) { //Player Pos
                float Speed = iTimeDelta*2.;
                	if (texelFetch(iChannel1,ivec2(32,0),0).x>0.) Speed = 20.*iTimeDelta;
                vec3 Eye = texture(iChannel0,vec2(2.5,0.5)*IRES).xyz;
                if (texelFetch(iChannel1,ivec2(87,0),0).x>0.) Color.xyz += Eye*Speed; //W
                if (texelFetch(iChannel1,ivec2(83,0),0).x>0.) Color.xyz -= Eye*Speed; //S
                vec3 Tan = normalize(cross(vec3(Eye.x,0.,Eye.z),vec3(0.,1.,0.)));
                if (texelFetch(iChannel1,ivec2(65,0),0).x>0.) Color.xyz -= Tan*Speed; //A
                if (texelFetch(iChannel1,ivec2(68,0),0).x>0.) Color.xyz += Tan*Speed; //D
                //Position clamping
                Color.y = clamp(Color.y,0.1,21.);
                Color.xz = clamp(Color.xz,vec2(0.1),vec2(31.9));
            } else if (fragCoord.x<5.) { //Sun angle
                if (texelFetch(iChannel1,ivec2(77,0),0).x>0.) Color.y += iTimeDelta*1.5;
                if (texelFetch(iChannel1,ivec2(78,0),0).x>0.) Color.y -= iTimeDelta*1.5;
                Color.z = Color.y; //Sunangle last frame
            } else if (fragCoord.x<6.) { //Sun direction
                vec2 Angles = texture(iChannel0,vec2(4.5,0.5)*IRES).xy;
                Color = vec4(normalize(vec3(cos(Angles.y)*cos(Angles.x)
                	,sin(Angles.x),sin(Angles.y)*cos(Angles.x))),1.);
            } else if (fragCoord.x<7.) { //Last frame dir
                Color = texture(iChannel0,vec2(2.5,0.5)*IRES);
            } else if (fragCoord.x<8.) { //Last frame position
                Color = texture(iChannel0,vec2(3.5,0.5)*IRES);
            } else if (fragCoord.x<9.) { //R-Value and movement boolean
                //R
                if (texelFetch(iChannel1,ivec2(82,1),0).x>0.) Color.x = 1.-Color.x;
                float RTime = texture(iChannel0,vec2(9.5,0.5)*IRES).x+min(iTimeDelta,1./30.);
                if (RTime>70.) Color.x = 0.; //Stop building
                //Movement
                Color.y = 1.;
                if (iFrame<BuildFrames ||
                    texelFetch(iChannel1,ivec2(87,0),0).x>0. ||
                    texelFetch(iChannel1,ivec2(83,0),0).x>0. ||
                    texelFetch(iChannel1,ivec2(65,0),0).x>0. ||
                    texelFetch(iChannel1,ivec2(68,0),0).x>0. ||
                    iMouse.xy!=Color.zw) Color.y = 0.;
                Color.zw = iMouse.xy;
            } else if (fragCoord.x<10.) { //RTime
                vec2 RMoved = texture(iChannel0,vec2(8.5,0.5)*IRES).xy;
                if (iFrame>BuildFrames && RMoved.x>0.5) {
                    Color.x += min(iTimeDelta,1./30.);
                    if (Color.x>70.) Color.x = 0.; //Reset RTime and set R to 0
                }
            }
        } else if (DFBox(fragCoord-vec2(0.,1.),vec2(26.*3.,26.))<0.) {
            //Updating the bricks
            float OutIndex = floor(fragCoord.x*I26);
            float CIndexf = floor(mod(fragCoord.x,26.))+floor(fragCoord.y-1.)*26.;
            int CIndex = int(CIndexf);
            vec2 BrickUV = vec2(mod(fragCoord.x,26.),fragCoord.y);
            //R-key and time
            vec2 RMoved = texture(iChannel0,vec2(8.5,0.5)*IRES).xy;
            if (texelFetch(iChannel1,ivec2(82,1),0).x>0.) RMoved.x = 1.-RMoved.x;
            float FrameTime = min(iTimeDelta,1./30.);
            float RelativeTimeCoeff = iTimeDelta/FrameTime;
            float RTime = texture(iChannel0,vec2(9.5,0.5)*IRES).x;
            if (iFrame>BuildFrames && RMoved.x>0.5) {
                RTime += FrameTime;
            }
            if (RTime>70.) RMoved.x = 0.;
            if (CIndex<512 && iFrame>BuildFrames && RMoved.x>0.5) {
                //Within the amount of bricks
                vec4 CBrick0 = texture(iChannel0,BrickUV*IRES);
                vec4 CBrick1 = texture(iChannel0,vec2(BrickUV.x+26.,BrickUV.y)*IRES);
                vec4 CBrick2 = texture(iChannel0,vec2(BrickUV.x+52.,BrickUV.y)*IRES);
                //Falling
                float UFallTime = (20.-CBrick0.y)/(4.+4.*(CBrick0.x+CBrick0.z)*I64);
                if (RTime<6. && RTime>UFallTime) {
                    vec3 Velocity = vec3(0.,min(0.4,pow(RTime-UFallTime,2.)*0.5),0.); //In relation to 30 fps
                    CBrick0.xyz += Velocity*RelativeTimeCoeff;
                }
                //Building
                if (RTime>6.+CIndexf*0.125) {
                    float TimeDiff = RTime-6.-CIndexf*0.125;
                    //Brick attributes
                    BRICK CBrick;
                    if (CIndex<128) CBrick = BrickArray[CIndex];
                    else if (CIndex<256) CBrick = BrickArray1[CIndex-128];
                    else if (CIndex<384) CBrick = BrickArray2[CIndex-256];
                    else if (CIndex<512) CBrick = BrickArray3[CIndex-384];
                    //Create coordinate system
                    vec3 CX = CBrick1.xyz;
                    vec2 sincos = vec2(sin(CBrick1.w),cos(CBrick1.w));
                    vec3 RefCZ = normalize(cross(CX,vec3(0.,1.,0.)));
                    vec3 RefCY = cross(RefCZ,CX);
                    vec3 CY = sincos.y*RefCY+sincos.x*RefCZ;
                    CY *= (max(0.,sign(CY.y))*2.-1.); //CY.y should be positive
                    //Spawn brick
                    CBrick0.xyz = CBrick.P+CY*max(0.,1.2-TimeDiff*TimeDiff*2.)*RelativeTimeCoeff;
                }
                //Output
                Color = ((OutIndex<0.5)?CBrick0:((OutIndex<1.5)?CBrick1:CBrick2));
            }
        } else if (DFBox(fragCoord-vec2(0.,27.),vec2(26.*3.,26.))<0.) {
            //Last frame copy of bricks
            Color = texture(iChannel0,vec2(fragCoord.x,fragCoord.y-26.)*IRES);
        }
    }
    //Logo
    vec2 UV = fragCoord;
    if (DFBox(UV-vec2(0.,53.),vec2(128.))<0.) {
        //LEGO logo SVG
        if (iFrame > 0) {
        } else {
            vec2 fragUV=UV-vec2(0.,53.); fragUV.x = 128.-fragUV.x;
            float normalizer = float(samples * samples);  
            float fstep = 1.0 / float(samples);
            for (int sx = 0; sx < samples; sx++) {
                for (int sy = 0; sy < samples; sy++) {  
                    vec2 uv = (fragUV + vec2(float(sx), float(sy)) * fstep)*I128;
                    uv *= 2.0;
                    uv -= vec2(1.0);
                    uv *= 2.24;
                    if (inPath(uv)) {
                        Color += vec4(1.0);
                    }
                }
            }
            Color = vec4(Color.xyz/normalizer,1.);
        }
    } else if (DFBox(UV-vec2(128.,53.),vec2(128.))<0.) {
        //LEGO logo gradient
        if (iFrame > 1) {
        } else {
            for (float i=-2.; i<2.5; i++) {
                for (float j=-2.; j<2.5; j++) {
                    if (i==0. && j==0.) continue;
                    Color.xy += normalize(vec2(i,j))*texture(iChannel0,(UV-vec2(128.,0.)+vec2(i,j))*IRES).x;
                }
            }
            Color = vec4(normalize(vec3(-Color.y/16.,0.5,-Color.x/16.)),1.);
        }
    }
    //Output
    fragColor = Color;
}