// Buffer A (buffer) — Day 378 by jeyko
// https://www.shadertoy.com/view/wlcyRB


#define TAA false

vec3 getNormal(vec3 p);
vec3 getSun(vec2 uv, vec2 sunPosU, vec3 ro, mat3 vp);
float t = 0.;
float invisibleWall = 10e4;

float groundNoise = 0.;
float alleyNoise = 0.;
float treebarkNoise = 0.;
vec3 alleyUv = vec3(0);

float fp(float z){return sin(z*0.15 + cos(z*0.05 + sin(z*0.04)));}

vec3 getPath(vec3 p){
    return vec3(fp(p.z),0.,0.)*7.;
    //return vec3(sin(p.z*0.2),0.,0.)*3.;

}


vec2 getGround(vec3 p){
    
    float d = p.y;
    float noise = groundNoise = cyclicNoiseGround(vec3(p)*0.2, false);
    
    d -= noise*0.2;
    
    return vec2(d,1.);
}   



vec2 getAlley(vec3 p){
    p -= getPath(p);
    
    
    p.y -= (alleyNoise = cyclicNoiseAlley(vec3(p)*62.2, true))*0.05*0.325;
    p.y -= 0. + groundNoise*0.4 + 0.09;
    p.y += smoothstep(0.0,0.9, abs(p.x) - pathW + sin(p.z*0.2)*0.2)*0.4;
    
    alleyUv = p;
    
    float d = p.y;
    
    
    
    return vec2(d,2.);
}
vec2 getTrees(vec3 po){
    float d = 10e5;
    float noise = cyclicNoiseTrees(vec3(po)*0.4, false);
    float noiseb = cyclicNoiseTrees(vec3(po.x,po.y*0.2,po.z)*24.4, false);
    treebarkNoise = noiseb;
    
    po.xz += noise*.5;
    vec3 p = po;
    
    
    vec3 id = floor((p)/vec3(treesSeperation, treeBranchSeperation, treesSeperation));
    
    p -= getPath(vec3(0.,0.,id.z*treesSeperation + treesSeperation*0.5));
    id = floor((p)/vec3(treesSeperation, treeBranchSeperation, treesSeperation));
    
    
    
    p.z = pmod(p.z,treesSeperation);
    
    p.x = pmod(p.x,treesSeperation);
    
    invisibleWall = abs(abs(p.z) - treesSeperation*0.5) + 0.3;
    
    
    float lpxz = length(p.xz);
    
    d = lpxz - trunkW  - noiseb*0.11*(1. + smoothstep(1.1,0.,p.y)*2.);
    
    //p.y -= smoothstep(0.,0.2,(lpxz + 0.2))*0.5;
    
    
    p.y = opRepLim( p.y - treeBranchSeperation*11.  + 0.75*treeBranchSeperation, treeBranchSeperation, 9. );
    //p.y = pmod( p.y, treeBranchSeperation);
    
    
    //p.y += 0.25*treeBranchSeperation;
    
    p.xz *= rot(sin(id.x*40.0 + id.z*1.4 + id.x*id.y*20. + id.y*229. + id.y * id.z*200.)*pi*222.);
    //p.xz *= rot(sin(id.z)*pi*2.);
    
    
    float polarId;
    
    pModPolar(p.xz, polarId, 4.);
    
    invisibleWall = min(invisibleWall, abs(abs(p.y) - treeBranchSeperation*0.5) + 0.03);
    
    p.yx *= rot(0.5*pi);
    float mdBranchLen = sin(id.x + id.y + 20.*id.y*id.z +20.*polarId);
    mdBranchLen = mix(mdBranchLen*0.3, abs(mdBranchLen)*0.9,smoothstep(0.,1.,id.y*0.5 - 0.8));
    float branchLen = (1.1  + mdBranchLen)*( 0.1 + smoothstep(0.4,1.,id.y*0.4 - 0.5)) ;
    
    float branchWidth = abs(sin(branchLen*200.  + polarId*10.));
    
    branchLen = max(branchLen, 0.);
    
    
    
    p.y += branchLen - 0.5;
    p.x -= pow(smoothstep(0.,2.9,(lpxz - 0.)*1.)/branchLen*1.6,1.)*0.9;
    
    
    //p.x -= noiseb*0.04 + noise*0.0;
    //branchWidth *= 0.5 + noiseb;
    
    //d = opSmoothUnion( d,  sdRoundCone( p, 0.01 + branchWidth*0.02, 0.05 + branchWidth*0.04, branchLen ), 0.09 ) ;
    
    //d = min( d,  sdRoundCone( p, 0.03 + branchWidth*0.04, 0.00 + branchWidth*0.0, branchLen )*1.) ;
    
    d = min( d,  max(length(p.xz) - 0.01 - 0.05*smoothstep(0.,1.,p.y/branchLen*0.6), - p.y - branchLen*0.5)*0.7 ) ;
    
    
    return vec2(d,3.);
}
float getLeaf(vec3 p, float sz, vec3 op, vec2 id){ 
    p.z -= sin(5.*abs(p.x)/sz)*sz*.575;
    
    p.x *= 0.75;
    p.xy *= rot(0. + sin(id.x*10. + id.y)*0.5);
    
    float d = length(p.xz) - sz ; 
    
    d = max(d,abs(p.y) - 0.01);
    return d;//max(, - abs(p.y) + 0.03);

}
float getLeavesLayer(vec3 op, float md, float sz){
    vec3 p = op; 
    vec2 id = floor(p.xz/md);
    p.xz = pmod(p.xz, md);
    return getLeaf(p, sz, op, id);
}

vec2 getLeaves(vec3 p, float dTrees){
    vec2 d = vec2(10e4);
    p.y -= smoothstep(0.4,0.,dTrees)*0.1;
    
    p.y -= groundNoise*0.4;
    p.xz *= rot(0.25);
    
    d = dmin(d, getLeavesLayer(p, 0.25, 0.05), 20.);
    p.xz *= rot(0.25);
    p.y -= 0.04;
    d = dmin(d, getLeavesLayer(p, 0.5, 0.05), 21.);
    
    p.xz *= rot(0.25);
    p.y -= 0.005;
    d = dmin(d, getLeavesLayer(p, 0.45, 0.05), 22.);

    p.xz *= rot(0.25);
    p.y += 0.025;
    d = dmin(d, getLeavesLayer(p, 0.35, 0.05), 23.);

    p.xz *= rot(0.25);
    p.y -= 0.002;
    d = dmin(d, getLeavesLayer(p, 0.25, 0.05), 24.);
    
    p.xz *= rot(0.25);
    p.y += 0.04;
    d = dmin(d, getLeavesLayer(p, 0.25, 0.15), 24.);


    return d;
}

vec2 map(vec3 p){
    vec2 d = vec2(10e5);
    
    vec2 dGround = getGround(p);
    vec2 dAlley = getAlley(p);
    vec2 dTrees = getTrees(p);
    vec2 dLeaves = getLeaves(p,dTrees.x);
   
   
   
    d = dmin(d, dAlley.x,dAlley.y);
    
    
    dGround.x = opSmoothSubtraction( -dGround.x, -dAlley.x, 0.1 );
    
    
    
    //dLeaves.x = opSmoothSubtraction( -dLeaves.x, -dAlley.x + 0.05, 0.01 );
    
    //dLeaves.x = mix(dLeaves.x, max(dLeaves.x, -dGround.x + 0.03),smoothstep(0.05,0.,abs(dLeaves.x - dAlley.x) - 0.04 ));
    
    d = dmin(d, dGround.x,dGround.y);
    dTrees.x = opSmoothUnion( dTrees.x, dGround.x, 0.4 );
    
    
    d = dmin(d, dTrees.x,dTrees.y);
    
    d = dmin(d, dLeaves.x,dLeaves.y);
    
        
    
    
    return d;
}




void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 prevFrame = texture(iChannel2,fragCoord/iResolution.xy);
    if(TAA){
        vec2 taaidx = r23(vec3(fragCoord,float(iFrame)))*4.;
        fragCoord += float(iMouse.z>0.)*.6*vec2(sin(float(taaidx.x)*pi/4.),cos(float(taaidx.x)*pi/4.))*taaidx.y/4.;

    }
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;
    vec2 muv = iMouse.xy/iResolution.xy - 0.5;
    vec3 col = vec3(0);
    float T = iTime*1.4;
    
    vec3 sunDir = normalize(sunPos);
    vec3 ro = vec3(0);
    ro.z += T;
    
    //ro.y -= getGround(ro).x;
    ro += groundOffs;
    ro += getPath(ro);
    
    vec3 lookAt = vec3(0,0,ro.z + 6.51);
    //lookAt.y -= getGround(lookAt).x;
    lookAt += groundOffs;
    lookAt += getPath(lookAt);
    
    
    if(iMouse.z > 0.){
        lookAt = vec3(
            ro.x + sin(muv.x*tau - pi),
            lookAt.y + muv.y*3. + 0.5,
            ro.z + cos(muv.x*tau - pi)
        );
    
    }

    mat3 vp = getRd(ro,lookAt);    
    //vec3 rd = normalize(vec3(uv,1.))*vp;
    vec3 rd = getRdUV(ro, lookAt, uv);
    
    
    // Marching
    
    vec3 p = ro;
    vec2 d;
    for(int i = 0; i < marchSteps ; i++){
        d = map(p);
        
        if(d.x < marchEps){
            hit = true;
            break;
        } else if (t > 24.){
            break;
        }
        
        d = dmin(d,invisibleWall, 10.);
        
        p = ro + rd*(t += d.x * distScale);
    }
    
    float depthView;
    vec3 atmosphere = getAtmosphere(vec3(0,ro.y - 0.,0), rd, t, depthView);
    

    
    // Wind
    float volumetricDith = r21(fragCoord + sin(iTime*20.)*20.)*volumetricDithAmt;
    
    vec3 windP = ro + rd*volumetricDith*0.00 ;
    float windStepSz = min(t,maxWindD)/windSteps;
    
    vec3 windAccum = vec3(0);
    float windDensTotal = 0.;
    //vec3 windAccum = vec3(0.);
    
    for(float i = 0.; i < windSteps ; i++){
        vec3 wp = windP*0.51 - vec3(-iTime*0.5,smoothstep(0.,1.,windP.y*0.5 - 1.9),0.);
        float dens = max(cyclicNoiseWind(wp,false,iTime),0.05)*0.461;
        dens *= smoothstep(1.,0.,windP.y*0.01 + 0.4);
        
        vec3 c = mix(
            vec3(1.4,1.1,0.67)*0.4,
            vec3(0.2,0.44,0.47)*0.3,
            //smoothstep( 0., 1., abs(windP.x)*0.9 - 0.5)
            smoothstep( 0., 1., length(rd.xy - sunDir.xy)*0.75 + 0.4)
            
            );
        
        c = mix( c*c*0.4, c, smoothstep(0.,1.,windP.y*0.15 + 0.1));
        
        //dens *= aoVol(windP,1.,sunDir)*aoVol(windP,0.6,sunDir)*aoVol(windP,0.2,sunDir)*aoVol(windP,2.2,sunDir)*2.;
        //dens *= aoVol(windP,1.,sunDir)*aoVol(windP,0.6,sunDir)*aoVol(windP,0.2,sunDir)*aoVol(windP,2.2,sunDir)*2.;
        
        
        dens = dens*(1.-windDensTotal);
        windAccum += dens*windStepSz*c*1.;
        windDensTotal += dens*windStepSz;
        
        
        if( windDensTotal > 0.97){
            break;
        }
        windP += rd*windStepSz;
    }
    

    // Coloring
    
    vec3 hitCol = vec3(0);
    vec3 ambientCol = atmosphere*1.;
    if(hit){
        vec3 n = getNormal(p);
        if(d.y == 2.){
            n = normalize(n + texture(iChannel3,p.xz).xyz)*0.7;
            
            n = normalize(n + texture(iChannel3,p.xz*0.2 + 3.).xyz);
        }
        
        vec3 prevFrameMip = pow(max(texture(iChannel2,vec2(uv.x,-uv.y),7.).xyz, 0.),vec3(2.)) * float(iFrame > 0);
        
        vec3 hf = normalize(sunDir - rd);
        float diff = max(dot(n,sunDir),0.);
        float spec = pow(max(dot(n,hf),0.),29.);
        float fres = pow( 1. - max(dot( n, -rd),0.001),5.);
        fres = max(fres,0.);
        
        float AO = ao(2.9)*ao(0.2)*ao(1.)*ao(0.4)*2.;
        float SSS = sss(.3)*sss(0.04)*sss(.1)*5.;
        float shad = diff;
        
        vec3 albedo = vec3(0);
        
        vec3 treesCol = vec3(0);
        {
            albedo = 1.2*vec3(0.22,0.22,0.21)*(sunCol + atmosphere*0.4);
            vec3 ambCol = albedo*(sunCol*0.2 + atmosphere*5.)*0.4;
            vec3 aoCol = 0.4*albedo*albedo*(sunCol*0.3 + atmosphere*1.4);
            
            treesCol = mix(ambCol, albedo, shad);
            treesCol = mix(aoCol, albedo, (AO - treebarkNoise*0.1));
        }
        vec3 groundCol = vec3(0.);
        {
            albedo = vec3(0.8,0.42,0.2)*0.1*(sunCol + prevFrameMip*224.4);
            vec3 ambCol = albedo*(sunCol*0.2 + atmosphere*5.)*0.4;
            vec3 aoCol = albedo*albedo*(sunCol*0.3 + atmosphere*1.4);
            
            groundCol = mix(ambCol, albedo, shad);
            groundCol = mix(aoCol, albedo, AO);
        }
        vec3 leavesCol = vec3(0.);
        {
            //albedo = vec3(0.8,0.42,0.2)*0.1;
            
            //albedo = pal(0.5,0.5,vec3(1,2,1),1.,d.y);
            
            albedo = vec3(1.,0.1,0.2)*0.8;
            
            albedo += 1.;
            
            albedo.yz *= rot(-sin(d.y*20.)*0.1);
            
            albedo.xy *= rot(-sin(d.y)*0.1);
            
            albedo.xz *= rot(-sin(d.y*40.)*0.02);
            
            albedo -= 1.;
            albedo *= sunCol + prevFrameMip;
            albedo *= vec3(0.9,0.95,0.7);
            
            albedo *= 1. - smoothstep(0.5,0., abs(alleyUv.x) - pathW*1.1 )*vec3(1.,0.9,0.8)*0.76;
            
            vec3 ambCol = albedo*(sunCol*0.2 + prevFrameMip*2.)*0.4;
            vec3 aoCol = albedo*albedo*albedo*(sunCol*0.1 + prevFrameMip*9.);
            
            leavesCol = mix(ambCol, albedo, shad);
            leavesCol = mix(aoCol, albedo, AO);
        }
        
        vec3 pathCol = vec3(0.);
        {
             
            albedo = .6*vec3(0.11,0.1,0.1);
            
            float darkened = smoothstep(0.4,0., -abs(alleyUv.x) + pathW*0.5  + 0.05+ texture(iChannel1,alleyUv.xz).x*texture(iChannel1,alleyUv.xz*vec2(0.,0.05)).x*2.);
            
            albedo = mix(
                albedo,
                albedo*texture(iChannel1,alleyUv.xz).xyz + albedo*0.5,
                darkened
            );
            //albedo += ;
            
            vec3 ambCol = albedo*(sunCol*0.2  + prevFrameMip*24.4)*0.1;
            vec3 aoCol = albedo*albedo*(sunCol*0.3 +  + prevFrameMip*24.4);
            
            
            
            pathCol = mix(ambCol, albedo, shad);
            pathCol = mix(aoCol, albedo, AO*1.2);
            pathCol += (smoothstep(0.4, 1.,alleyNoise) + 0.9)
                *(spec*1.5 + fres*0.9)*3.9*(clamp(prevFrameMip,0.,.00) + vec3(0.,0.2,0.3)*0.008)*(1. - darkened*0.7);
        }
        
        hitCol += groundCol*float(d.y == 1.);
        hitCol += pathCol*float(d.y == 2.);
        hitCol += treesCol*float(d.y == 3.);
        hitCol += leavesCol*float(d.y >= 20.);
        
        
        hitCol -= hitCol*float(d.y == 10.);
        
    }
    

    // Compositing
    
    col += hitCol;
    
    if(hit){
       atmosphere *= 1.-pow(exp(-(t)*.04 ),2.);
    }
    
    //atmosphere += getSun(rd.xy, sunDir.xy, ro, vp);
    
    atmosphere*=0.04;
    float depthViewFac = smoothstep(0.,1.,exp(-depthView*0.02) + exp(-t*0.4));
    
    col = col * depthViewFac + atmosphere; 
    
    /*
    if (!hit  && lowerCloudLimitDist > 0.){
        cloudAccum = mix(cloudAccum,col,clamp(1.-exp(-lowerCloudLimitDist*0.01 + 0.4),0.,1.));
        col = mix(col,cloudAccum*1. , pow(clamp(cloudDensTotal*1. - 0.,0.,1.),4.));
    }
    */
    //windAccum *= smoothstep(0.,1.,t*0.2 - 1.);
    col = mix(col, windAccum, pow(windDensTotal,1.));
    
    //col = (col - windDensTotal) + 1.*windAccum;
    
    if(TAA && iFrame >1 && iMouse.z < 1.){
        fragColor = mix(prevFrame, col.xyzz,0.4);
    } else {
        fragColor = col.xyzz;
    }
    
    
    
    
    //fragColor.w = cloudDensTotal + float(hit)*1.;
    fragColor.w = 1.;

}


vec3 getNormal(vec3 p){
      vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*0.02).x;
    }
    return normalize(n);
}


vec3 getSun(vec2 uv, vec2 sunPosU, vec3 ro, mat3 vp){
    
    vec3 sunPosW = sunPos;
    vec2 sunUVOriginal = uv;
    vec2 sunUV = uv - sunPosU;
    //float cloudDensPrevFrame = texture(iChannel2, ((sunUV*iResolution.y + 0.5*iResolution.xy)/iResolution.xy)).w;
    
    //vec2 sunUvPrevFrame = (normalize(sunPosW - ro)*inverse(getRd(ro,sunPosW))).xy;
    vec2 sunUvPrevFrame = (normalize(sunPosW - ro)*inverse(vp)).xy;
    
    sunUvPrevFrame = (sunUvPrevFrame*iResolution.y)/iResolution.xy + 0.5;
    
    float deltaUV = 0.04;
    float cloudDensPrevFrame = 
        texture(iChannel2, sunUvPrevFrame + deltaUV).w
        + texture(iChannel2, sunUvPrevFrame - deltaUV).w
        + texture(iChannel2, sunUvPrevFrame + vec2(-deltaUV,deltaUV)).w
        + texture(iChannel2, sunUvPrevFrame + vec2(deltaUV,-deltaUV)).w
        ; 
    
    cloudDensPrevFrame /= 4.;
    
    cloudDensPrevFrame = clamp(cloudDensPrevFrame,0.,1.);
    // sun
    vec3 sun = sunCol*smoothstep(0.07,0.,length(sunUV));
    sun += sunCol*vec3(1.,0.4,0.6)*smoothstep(0.1,0.,length(sunUV));
    sun += sunCol*vec3(0.7,0.4,0.6)*smoothstep(0.3,0.,length(sunUV))*0.5;
    sun += sunCol*vec3(0.3,0.4,0.6)*smoothstep(0.6,0.,length(sunUV))*0.35;
    
    
    // rays
    
    
    vec3 sunRays = 0.4*sunCol * smoothstep(0.015*(1. + smoothstep(1.,0.,abs(sunUV.x)) ) ,0.,abs(sunUV.y))*smoothstep(0.5,0.,abs(sunUV.x));
    
    for(float i = 0.; i < 8.; i++){
        sunUV *= rot(pi/8./1.);
        float mda = sin(i*pi/4.);
        float mdb = sin(i*pi/2.);
        float w = 0.03;
        float l = 0.1;
        sunRays += (sunCol) *
            mix(.8,.1,smoothstep(0.,0.25 +  sin(i*pi/ 4. + iTime)*0.1,length(sunUV))) *
            smoothstep(w + mda*w/4.,0.,abs(sunUV.y))*smoothstep((l + mdb*0.1)*1.5,0.,abs(sunUV.x));
    }   
    sunUV = sunUVOriginal - sunPosU;
    vec3 flares = vec3(0);
    vec2 toMid = sunPosU;
    vec2 dirToMid = -normalize(toMid);
    float lenToMid = length(toMid);

    // flares
    for(float i = 0.; i < 12.; i++){
          sunUV -= 2.*lenToMid*dirToMid/12.;
          float dfl = length(sunUV) - (0.1 + 0.1*sin(i*5.))*0.5;
          dfl *= 0.5;
          vec3 flare = 0.01*(sunCol)*smoothstep(0.02,0.,dfl);
          flare += 0.003*(sunCol*sunCol)*smoothstep(0.01,0.,abs(dfl - dFdx(uv.x)));
          flares += flare*abs(sin(i*10.));
    }   
    
    
    return (sun + sunRays + flares*3.*sunCol) * (1. - cloudDensPrevFrame*1.);
}

