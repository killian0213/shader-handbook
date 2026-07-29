// Buffer A (buffer) — Light Propagation by Mathis
// https://www.shadertoy.com/view/4d3fWX

//Vars + voxelized scen

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Color=texture(iChannel0,fragCoord.xy/iResolution.xy);
    if (iFrame==0) { //Initialization
        if (fragCoord.x<10. && fragCoord.y<1.) { //Store vars
            if (fragCoord.x<1.) Color=vec4(0.,0.,0.,0.); //Mouse
            else if (fragCoord.x<2.) Color=vec4(-0.2,2.5,0.,0.); //Player Eye (Angles)
            else if (fragCoord.x<3.) Color=vec4(0.,0.,0.,1.); //Player Eye (Vector)
            else if (fragCoord.x<4.) Color=vec4(1.5,2.7,16.5,1.); //Player Pos
            else if (fragCoord.x<5.) Color=vec4(0.2,4.,0.,1.); //Sun angles
            else if (fragCoord.x<6.) Color=vec4(0.,0.,0.,1.); //Sun direction
        }
    } else { //Update
		if (fragCoord.x<10. && fragCoord.y<1.) { //Update vars
            if (fragCoord.x<1.) { //Mouse
                if (iMouse.z>0.) { //Börjat klicka
                    if (Color.w==0.) {
                    	Color.w=1.;
                    	Color.xy=iMouse.zw;
                    }
                } else Color.w=0.;
            } else if (fragCoord.x<2.) { //Player Eye (Angles)
                vec4 LMouse=texture(iChannel0,vec2(0.5,0.5)*ires);
                if (LMouse.w==0.)  Color.zw=Color.xy;
                if (LMouse.w==1.) {
                	//Y led
                	Color.x=Color.z+(iMouse.y-LMouse.y)*0.01;
                	Color.x=clamp(Color.x,-2.8*0.5,2.8*0.5);
                	//X led
                	Color.y=Color.w-(iMouse.x-LMouse.x)*0.02;
               		Color.y=mod(Color.y,3.1415926*2.);
                }
            } else if (fragCoord.x<3.) { //Player Eye (Vector)
                vec3 Angles=texture(iChannel0,vec2(1.5,0.5)*ires).xyz;
                Color.xyz=normalize(vec3(cos(Angles.x)*sin(Angles.y),
                  			   			sin(Angles.x),
                  			   			cos(Angles.x)*cos(Angles.y)));
            } else if (fragCoord.x<4.) { //Player Pos
                float Speed=8.*iTimeDelta;
                	if (texelFetch(iChannel1,ivec2(32,0),0).x>0.) Speed=24.*iTimeDelta;
                vec3 Eye=texture(iChannel0,vec2(2.5,0.5)*ires).xyz;
                if (texelFetch(iChannel1,ivec2(87,0),0).x>0.) Color.xyz+=Eye*Speed; //W
                if (texelFetch(iChannel1,ivec2(83,0),0).x>0.) Color.xyz-=Eye*Speed; //S
                vec3 Tan=normalize(cross(vec3(Eye.x,0.,Eye.z),vec3(0.,1.,0.)));
                if (texelFetch(iChannel1,ivec2(65,0),0).x>0.) Color.xyz-=Tan*Speed; //A
                if (texelFetch(iChannel1,ivec2(68,0),0).x>0.) Color.xyz+=Tan*Speed; //D
            } else if (fragCoord.x<5.) { //Sun angle
                if (texelFetch(iChannel1,ivec2(188,0),0).x>0.) Color.y+=0.02;
                if (texelFetch(iChannel1,ivec2(190,0),0).x>0.) Color.y-=0.02;
            } else if (fragCoord.x<6.) { //Sun direction
                vec2 Angles=texture(iChannel0,vec2(4.5,0.5)*ires).xy;
                Color=vec4(normalize(vec3(cos(Angles.y),1.,sin(Angles.y))),1.);
            }
        } else if (fragCoord.x<512. && fragCoord.y<32.*2.+1.) { //Voxelisering
            vec2 FUV=floor(fragCoord-vec2(0.,1.));
            //vec2 uv=vec2(FUV.x+0.5,mod(FUV.y,64.)+1.5)*ires;
            float AddZ=((fract(fragCoord.y*i32*0.5)<0.5)?0.:16.);
            vec3 Pos=vec3(floor(fract(FUV.x*i32)*32.),floor(mod(FUV.y,32.))
                      ,floor(FUV.x*i32)+AddZ)+0.5;
            DF Voxel=SDF(Pos,iTime);
        	Color=((Voxel.d<VoxelisationDist)?vec4(Voxel.c,1.+Voxel.Mat):vec4(0.));
        }
    }
    fragColor=Color;
}