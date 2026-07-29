// Cube A (cubemap) — single pass 3D fluid by flockaroo
// https://www.shadertoy.com/view/tl33RM

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// single pass 3D CFD

// same fluid as in "molten bismut" but generalized to 3 dimensions
// ...but with self-consistent-ish velocity field
// the previous method was just defined implicitely by the rotations on multiple scales
// here the calculated velocity field is put back into the stored field

// the actual simulation

#define RotNum 6

#define keyTex iChannel2
#define KEY_I (texture(keyTex,vec2((105.5-32.0)/256.0,(0.5+0.0)/3.0)).x)

vec3 getVal(vec3 pos)
{
    vec4 coord=coord3to2(pos);
    vec3 v1=textureLod(iChannel0,vec3(coord.xy/Res0.xy-.5,.5),0.).xyz;
    vec3 v2=textureLod(iChannel0,vec3(coord.zw/Res0.xy-.5,.5),0.).xyz;
    return mix(v1,v2,fract(pos.z-.5));
}

vec3 deltaPoint(int i)
{
    #if RotNum == 8 // cube diagonals
        vec3 b = (vec3(i&1,i&2,i&4)*vec3(2,1,.5)-1.)*.58;
    #endif
    #if RotNum == 6 // +/- x,y,z (cube sides)
        vec3 d=1.-clamp(mod(vec3(i,i+1,i+2),3.),0.,1.);
        float sg=float(i/3)*2.-1.;
        vec3 b = d*sg;
    #endif
    #if RotNum == 4 // tetrahedral points (every other cube diag)
        vec2 sg=vec2((i&1)*2,i&2)-1.;
        vec3 b = (sg.x*vec3(1,sg.y,0)+sg.y*vec3(0,0,1))*.58;
    #endif
    #if RotNum == 3 // 3 points on a triangle
        vec3 b = vec3(cos(.5+float(i)*PI2/3.+vec2(0,1.57)),0.);
    #endif
    #if RotNum == 2 // 2 opposite points
        vec3 b = float(i&1)*2.-1.*vec3(1,1,1)*.58;
    #endif
    #if RotNum == 1 // only 1 points
        vec3 b = vec3(1,1,1)*.58;
    #endif
    return b;
}

vec3 getRot(vec3 pos, float s, vec4 q)
{
    vec3 rot=vec3(0);
    for(int i=0;i<RotNum;i++)
    {
        vec3 b=s*transformVecByQuat(deltaPoint(i),q);
        vec3 v=getVal(pos+b);
        rot+=cross(v,b);
    }
    return rot/float(RotNum)/(s*s);
}

vec4 rand3d(vec3 uv)
{
    float pz=uv.z*256.;
    float z=floor(pz);
    vec2 uv1=uv.xy+z*vec2(17,31)/256.;
    vec2 uv2=uv1+vec2(17,31)/256.;
    return mix(textureLod(iChannel1,uv1,0.),textureLod(iChannel1,uv2,0.),pz-z);
}

vec4 getRand(int idx)
{
    ivec2 res = textureSize(iChannel1,0);
    return texelFetch(iChannel1,ivec2(idx%res.x,(idx/res.x)%res.y),0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 pos = coord2to3(fragCoord);
    if(pos.z>FRes.z) discard; // ignore idle parts of storing texture
    
    vec4 q = normalize(cos(vec4(1,1.5,2.3,3)*float(iFrame)*2.3+.0*pos.yzxy)); // vary curl-evaluation-points in time
    //vec4 q = normalize(getRand(iFrame+int(pos.x)+int(.1*pos.y))); // vary curl-evaluation-points in time
    
    // this could be a crucial part to find a quaternions that vary rpeopery
    // - no too small roatations
    // - q, qr fairly orthogonal 
    //q=normalize(getRand(iFrame+1+int(pos.x)+int(.1*pos.y)));
    vec4 qr=normalize(getRand(iFrame+1));
    //vec4 qr=normalize(q.yxzw*vec3());
    vec3 v=vec3(0);
    vec3 vm=vec3(0);
    float cnt=0.;
    float sMax=.2*length(FRes); // take curls up to 1/4 field size
    float s=1.;
    q=normalize(getRand(iFrame/*+int(pos.x*13.+pos.y*7.+pos.z*17.)*/));
    for(int l=0;l<20;l++)
    {
        //q=normalize(getRand(iFrame+l));
        if ( s > sMax ) break;
        for(int i=0;i<RotNum;i++)
        {
            vec3 b=s*transformVecByQuat(deltaPoint(i),q);
            v+=cross(getRot(pos+b, s, q.wxyz),b);
            vm+=s*getVal(pos+b);
            cnt+=s;
        }
        s*=2.0;
        q=multQuat(q,qr);
    }
    
    v*=1./float(RotNum);
    vm/=cnt;
    #ifdef OBSTACLE
    //install 0'th order velocity (ignored by algorithm)
    v=mix(v,vm,.05);
    #endif
    
    // perform advection
    fragColor.xyz=getVal(pos-.05*v*FRes.x);
    
    // feeding some self-consistency into the velocity field
    // (otherwise velocity would be defined only implicitely by the multi-scale rotation sums)
    fragColor.xyz=mix(fragColor.xyz,v*4.,.025);
    
    // add a little "motor"
    //vec2 c=fract(scuv(iMouse.xy/iResolution.xy))*iResolution.xy;
    //vec2 dmouse=texelFetch(iChannel3,ivec2(0),0).zw;
    //if (iMouse.x<1.) c=Res0*.5;
    vec3 c=FRes*.5*vec3(1,1.,1);
    #ifdef OBSTACLE
    c=FRes*.5*vec3(1,.1,1);
    #endif
    vec3 scr=(pos-c)/FRes*2.;
    #ifdef OBSTACLE
    // nozzle in y-direction
    fragColor.xyz = mix(fragColor.xyz,2.25*vec3(0,1,0),1./(dot(scr,scr)/0.005+.005));
    #else
    // slowly rotating current in the center (when mouse not moved yet)
    fragColor.xyz += 1.1*cos(floor(iTime*.2)*2.5*vec3(.3,1,1.7)) / (dot(scr,scr)/0.005+.005);
    //fragColor.xyz= mix(fragColor.xyz, 8.1*cos(floor(iTime*.1)*2.5*vec3(.3,1,1.7)), 1./(dot(scr,scr)/0.005+.005));
    #endif
    
    //fragColor.xyz = mix(fragColor.xyz,1.5*vec3(0,1,0),exp(-scr.y*scr.y/0.01/0.01));
    //fragColor.xyz = mix(fragColor.xyz,1.5*vec3(0,1,0),exp(-(scr.y-1.8)*(scr.y-1.8)/0.01/0.01));

    #ifdef OBSTACLE
    if(obstacleDist(distPos(pos))<0.) 
    {
        vec3 n=normalize(obstacleGrad(distPos(pos),.001));
        fragColor.xyz-=1.*dot(fragColor.xyz,n)*n;
        fragColor.xyz*=vec3(0.8);
    }
    #endif
    
    // feed mouse motion into flow
    //fragColor.xy += .0003*dmouse/(dot(scr,scr)/0.05+.05);

    // initialization
    if(iFrame<=4) fragColor=vec4(0);
    if(KEY_I>.5 ) fragColor=(rand3d(coord2to3(fragCoord)*.0003)-.5)*6.;
    fragColor.w=1.;
}


void mainCubemap( out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir )
{
	// only use one face of cubemap (z+)
    if( rayDir.z<0.0 || abs(rayDir.x)>abs(rayDir.z) || abs(rayDir.y)>abs(rayDir.z)) discard;

    // Output to cubemap
    mainImage(fragColor,(rayDir.xy/rayDir.z*.5+.5)*Res0);
}
