// Buffer A (buffer) — Soccermania 3D by kastorp
// https://www.shadertoy.com/view/mdyfzW

//BUFFER A: game engine
#define module 1
vec2 T[22] =vec2[22](
    //red team 4-4-2
    vec2(.92,0),
    vec2(.6,.36),vec2(.6,.12),vec2(.6,-.12),vec2(.6,-.36),
    vec2(.3,.36),vec2(.3,.12),vec2(.3,-.12),vec2(.3,-.36),
    vec2(.05,.18),vec2(.05,-.18),
    //blue team 
    vec2(-.92,0),
#if (module==1) 
    // 4-3-3
    vec2(-.6,.36),vec2(-.6,.12),vec2(-.6,-.12),vec2(-.6,-.36),
    vec2(-.3,-.32), vec2(-.4,.0),vec2(-.3,.32),
    vec2(-.05,.25),vec2(-.05,.0),vec2(-.05,-.25)
#elif(module==2)
    // 4-4-2
    vec2(-.6,.36),vec2(-.6,.12),vec2(-.6,-.12),vec2(-.6,-.36),
    vec2(-.3,.36),vec2(-.3,.12),vec2(-.3,-.12),vec2(-.3,-.36),
    vec2(-.05,.18),vec2(-.05,-.18)
#elif(module==3)
    // 3-4-3
    vec2(-.6,.24),vec2(-.6,.0),vec2(-.6,-.24),
    vec2(-.4,.36),vec2(-.3,.12),vec2(-.3,-.12),vec2(-.4,-.36),
    vec2(-.05,.18),vec2(-.0,0.),vec2(-.05,-.18)
#else
    //4-2-4
    vec2(-.6,.36),vec2(-.6,.12),vec2(-.6,-.12),vec2(-.6,-.36),
    vec2(-.3,.12), vec2(-.3,-.12),
    vec2(-.05,.36),vec2(-.05,.18),vec2(-.05,-.18),vec2(-.05,-.36)
#endif
  );


vec2 hash21(float p)
{
	vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}
void mainImage( out vec4 O, in vec2 U )
{
    if(U.y>1. || U.x>28.) discard;
    
    //who am I?
    int i=int(U.x);
    //who's near ball?
    vec4 ball=  texelFetch(iChannel0,ivec2(0),0);
    vec4 zBall=texelFetch(iChannel1,ivec2(coord(ball.xy) ),0);     
    float zBalld= sdSegment(texelFetch(iChannel0,ivec2(zBall.x,0),0).xy,ball.xy,ball.xy-ball.zw*.04);
    
    ivec4 mode= ivec4( texelFetch(iChannel0,ivec2(24,0),0));
    bool demo = true;//!(texelFetch(iChannel3,ivec2(67,2),0).x>0.);
 
    
    if(iFrame==0) //initialize
        O = i==0 ? vec4(0,0,0,0): //ball
             i<23 ? vec4(.48 - U.x*.04,.0 ,0,0): //players
             i==24? vec4(0,F_START,0,0): //mode
                    vec4(0); //score && last player kick
    else if(  texelFetch(iChannel3,ivec2(65,2),0).x>0.){
        O=texelFetch(iChannel0,ivec2(U),0);
        return;

    } 
    else if(i==24){ //mode (0=goal kick, 1 =game, 2=throw-in)
       int lastP= int( texelFetch(iChannel0,ivec2(26,0),0).x);
       if(any(greaterThan(ball.xy,PC)) || any(lessThan(ball.xy,-PC))) mode=ivec4(CORNERS,iFrame+F_START,lastP,0);
       else if( mode.x==0 && iFrame>mode.y) mode=ivec4(1,iFrame+F_START,0,0);
       else if( mode.x==2 && length(ball.zw)>.001 ) mode=ivec4(1,iFrame+F_START*(length(ball.xy)<.05?53:1) ,0,0);
              
       O=vec4(mode);       
    }
    else if(i==25){ //scores
        ivec4 sc= ivec4( texelFetch(iChannel0,ivec2(25,0),0));
        if( abs(ball.y)<=.07 && mode.x==1){ 
            if(ball.x>PC.x ) sc.x++; //blue goal
            if(ball.x<-PC.x) sc.y++; //red goal
            if(max(sc.x,sc.y)>9) sc.xy=ivec2(0);//reset
        }
        O=vec4(sc);       
    }
    else if(i==26 ){
        // stores last kicking player 
        O= texelFetch(iChannel0,ivec2(26,0),0);
        if(mode.x==1  &&  zBalld <.01){           
                if((iMouse.z>0. && zBall.x<11.5  )
                || (zBall.x>11.5 || demo)) O=vec4(zBall.x);
        }
        if(mode.x==2 && zBalld<.01) O=vec4(zBall.x);
    }
    else if(i==27 ){
        O =vec4(0); //offside position (midfield)
        for(int i=1;i<=22;i++)
        {
            vec2 p=  texelFetch(iChannel0,ivec2(i,0),0).xy;
            if(i>1&& i<12) O.x=max(O.x,p.x);
            if(i>13) O.y=min(O.y,p.x);
        }
        
        
    }
    else if(i==0 ){ //ball
        O =  texelFetch(iChannel0,ivec2(0),0);
        
        //ball movement
        vec2  pBall=vec2(O.xy), vBall=vec2(O.zw);
        vBall*=.96;
        pBall+= vBall*.04;
        
        if(mode.x==1 ){//&& all(greaterThanEqual(pBall,-PC)) || all(lessThanEqual(pBall,PC))){
            //ball kicked
            if( zBalld<.01 ){
                /*
                if(iMouse.z>0. && zBall.x<11.5  ){
                    //mouse target
                    vec2 pMouse =position(iMouse.xy);
                    float power=  max(length(pBall-pMouse),.12);                              
                    if(texelFetch(iChannel3,ivec2(65,0),0).x>0.) power=.9 ;
                    if(texelFetch(iChannel3,ivec2(83,0),0).x>0.) power=.5 ;
                    vBall =-normalize(pBall-pMouse)*min(power,.9) *1.2;
                }else
                */
                 
                if(zBall.x>11.5 || demo) {
                    //find best shot on random set
                    float side = sign(zBall.x-11.5 );
                    float score=-1e5;
                    for(int j=0;j< 300;j++){
                        vec2 tDir =-normalize(pBall- vec2(side*PC.x,0))*.25;
                        vec2 cvBall= tDir + hash21(iTime +float(j)*3.1)*.6-.3 ;
                        
                        vec2 tPos=pBall + cvBall*TDIST; //final ball position (estimation)
                        if(tPos.x>PC.x*TDIST || tPos.x<-PC.x*TDIST)  
                        {
                            //evaluate shot score
                            float cScore = +( abs(tPos.y) <.07  && tPos.x*side>PC.x ?5.:-1.);
                            if (cScore>score) {
                                vBall=cvBall;
                                score=cScore;
                            }
                        } 
                        vec4 zzBall=texelFetch(iChannel1,ivec2(coord(tPos) ),0); 
                        // evaluate passing score
                        float cScore= -.02 + abs(score(side,tPos,ball,zzBall));
                        //(tPos.x-zBall.x)*side *(.03+  smoothstep(.05,.2, zzBall.w-zzBall.y)*2.)  *smoothstep(PC.y*.9,PC.y*.5,abs(tPos.y));
                        if(score<0. ||(cScore>score &&  sign(zzBall.x-11.5 )*side>0. )){
                            vBall=cvBall;
                            score=cScore;
                        }
                    }
                 }          
            }

            O = vec4(pBall,vBall);
        }
        else if(mode.x==2 ) {           
            //WORK IN PROGRESS 
            if( abs(pBall.x)>PC.x && abs(pBall.y)<.07) O=vec4(-.01*sign(pBall.x),0,0,0); //goal
            else if(pBall.x>PC.x && mode.z <=11)  O=vec4(vec2(PC.x,PC.y*sign(pBall.y)),vec2(0)); //corner blue
            else if(pBall.x<-PC.x && mode.z> 11) O=vec4(vec2(-PC.x,PC.y*sign(pBall.y)),vec2(0)); //corner red
            else if(pBall.x>PC.x && mode.z> 11)  O=vec4(vec2(PC.x-.10,.15*sign(pBall.y)),vec2(0)); //throw in red
            else if(pBall.x<-PC.x && mode.z<= 11) O=vec4(vec2(-PC.x+.10,.15*sign(pBall.y)),vec2(0)); //throw in blue
            else if(abs(pBall.y)>PC.y)  O=vec4(pBall.x,PC.y*sign(pBall.y),0,0); //lateral             
            else if(zBalld<.01  && iFrame>mode.y) O= vec4(pBall.xy, -normalize(pBall- vec2(0.))*.02) ;
        }
        else if(mode.x==0 ) O=vec4(max(-PC,min(PC,pBall)),vec2(0)); 

    }
    else if(i>=1 && i<=22){ //player         
            
        //target position
        vec2 p=  T[i-1];
        //current position
        vec4 p0=  texelFetch(iChannel0,ivec2(U),0);
        
        if(mode.x==2 ){
            bool kickoff=  length(ball.xy)<.05;
            //attack/defense
            if(i>12 && !kickoff ) p+=  vec2( ball.x*.5  +.22 +sign(float(mode.z)-11.5) *.03 , 0);
            if(i>1 && i<12 && !kickoff ) p+= vec2( ball.x*.5 -.22 +sign(float(mode.z)-11.5) *.03, 0);          
            if((int(zBall.x)==i || int(zBall.z)==i  )  && ((mode.z >=12 && i<=11) || (mode.z <=11 && i>=12)) ) p=ball.xy;
            else if( !kickoff)  p =mix( p,-ball.xy, smoothstep(.2,-.2,length(p-ball.xy)));
        }
        
        if(mode.x==1 ){
            if( (i>5 && i<12) || i>16 ){
                  //random movements
                  int j= (iFrame/90);
                  vec2 rp= hash21(float(j*24 + i));                 
                  p = clamp(p+ rp.xy*.4-.2,-PC,PC);
            }
            
        
            //attack/defense
            if(i>12 ) p+=  vec2( ball.x*.7  +.3, ball.y*.3);
            if(i>1 && i<12 ) p+= vec2( ball.x*.7  -.3 ,ball.y*.3);
            
            //return from offside
            vec2 offs=texelFetch(iChannel0,ivec2(27,0),0).xy;          
            if(i>1 && i<12)  p.x=max(p.x,offs.y);
            if(i>13)  p.x=min(p.x,offs.x);
           
  
            //ball is mine       
            if(int(zBall.x)==i || int(zBall.z)==i  ) p=ball.xy;//+hash21(iTime )*.01-.005 ;
            else if(mode.x ==1 ) {
                
                vec2 pBall=max(-PC,min(PC,ball.xy +ball.zw*TDIST*.5));
                zBall=texelFetch(iChannel1,ivec2(coord(pBall)),0); 
                //ball is directed to me
                if(int(zBall.x)==i || int(zBall.z)==i ) p=pBall +ball.zw*TDIST*.2;
                else {
                
                   // pressing  
                    p =mix( p,max(-PC,min(PC,ball.xy)), smoothstep(.5,-.2,length(p-ball.xy)));
                }
            }
        }
        /*
        //mouse target
        vec2 pMouse =position(iMouse.xy);
        if(iMouse.z>0. && dot(pMouse,p0.xy-ball.xy)<-0.5) {            
            if(zBall.x<11.5  && int(zBall.x)==i  ) p =pMouse;
            if(zBall.z<11.5  && int(zBall.z)==i  ) p =pMouse;
        } */
        
        //player movement 
        float move =.0035; 
        //if( (texelFetch(iChannel3,ivec2(69,2),0).x>0.) && i>11) move*=.1; ;
        p = p0.xy+  normalize(p-p0.xy)*move * min(length(p-p0.xy)*50.,1.); 
        
        //players collisions        
        vec4 zP=texelFetch(iChannel1,ivec2(coord(p)),0);
        vec2 p1 =texelFetch(iChannel0,ivec2(zP.z,0),0).xy;
        if(int(zP.z)!=i && length(p-p1)<.02) {
            
             p +=  normalize(p-p1)*.0035; 
        }         
        
        //players remain inside field
        float run= length(p-p0.xy);
        O = vec4(p ,run<.001? atan(-p.y+ball.y,-p.x+ball.x): atan(p.y-p0.y,p.x-p0.x),p0.w+length(p-p0.xy));
    }
}