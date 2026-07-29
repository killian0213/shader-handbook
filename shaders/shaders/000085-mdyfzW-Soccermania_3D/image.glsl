// Image (image) — Soccermania 3D by kastorp
// https://www.shadertoy.com/view/mdyfzW

// Soccermania 3d by Kastorp
//--------------------------------

float pitch(vec2 uv)
{
    float d =1e5;
    uv=abs(uv);
    d=min(d,abs(length(uv) - .18));
    d=min(d,max(uv.x- PC.x +.34, abs(length(uv-vec2(PC.x-.27,0)) - .18)));
    d=min(d,abs(sdBox(uv-vec2(PC.x/2.,0),vec2(PC.x/2.,PC.y))));
    d=min(d,abs(sdBox(uv-vec2(PC.x-.17,0),vec2(.17,.4))));
    d=min(d,abs(sdBox(uv-vec2(PC.x-.05,0),vec2(.05,.15))));
    d=min(d,length(uv-vec2(PC.x-.25,0.)));
    return d;
}



//---------render functions--------------------------
struct RayIn{
    vec3 rd;
    float t; 
};

struct RayOut{   
    float tN;
    float tF;
    vec3 n;
    vec3 fuv;
    float id;
};

RayOut sRayOut(float d,float id) {return RayOut(d,0.,vec3(0),vec3(0),id);}
RayOut tRayOut(vec2 d,float id) {return RayOut(d.x,d.y,oNor,oFuv,id);}

const RayIn rSDF=RayIn(vec3(0),-1.);

RayOut RotSphere( in RayIn m,vec3 p, float ra ,float a, float id)
{

        vec2 v = iSphere(p,m.rd,ra);
        oFuv.z-=a*ra*1.57;
        return  tRayOut(v,id);
}

RayOut Box(  in RayIn m,vec3 p, in vec3 b,float id)
{
    return  tRayOut(iBox(p,m.rd,b),id);
}

RayOut RotBox(  in RayIn m, vec3 p, in vec3 b, vec3 ax, vec3 c, float a,float id)
{
    vec3 pr=  c+ erot( p-c , ax, a); 
    m.rd=  erot( m.rd , ax, a); 

          vec2 d=iBox(pr,m.rd,b);
          return RayOut(d.x,d.y, erot( oNor , ax, a),oFuv,id);

}
RayOut Plane(  in RayIn m, vec3 p, in vec3 n ,float h,float id)
{
 return  tRayOut(iPlane(p,m.rd,n,h),id);
}


RayOut Union( RayOut a, RayOut b)
{
   if(a.tN<b.tN) return a;
   else return b;
}
#define Add(_ro,_func) _ro = Union(_ro,_func);

#define  RotView( p, _ri,_ro, _ax,  _c ,  _a,  _body) \
    p=  _c+ erot( p-_c , _ax, _a); \
    _ri.rd=  erot( _ri.rd , _ax, _a); \
    _body \
    _ro.n=erot( _ro.n , _ax, -_a); 


//------------------------------------

RayOut oRay;
float map(in RayIn m0,vec3 p0 ) { 
    RayOut r =  Plane(m0,p0,vec3(0,1.0,0),0.,1.);
    //walls
    Add(r,Box(m0,p0-vec3(0,0.,SIZE*1.3),vec3(SIZE*2.2,5.,1.),7.));
    Add(r,Box(m0,p0-vec3(0,0.,-SIZE*1.3),vec3(SIZE*2.2,5.,1.),7.));
    Add(r,Box(m0,p0-vec3(SIZE*PC.x*2.3,0.,0.),vec3(1.,5.,SIZE*1.3),7.));
    Add(r,Box(m0,p0-vec3(-SIZE*PC.x*2.3,0.,0.),vec3(1.,5.,SIZE*1.3),7.));
  
  // RayOut r0=Box(m0,p0,vec3(SIZE*2.2,3.,SIZE),2.); //bounding box:  field
  // if(  (m0.t<0.  && r0.tN <.5) || (m0.t>=0. && r0.tN>=0. && r0.tN<NOHIT)){
  RayOut r0;
  if(true){
    
    //bars
    Add(r,Box(m0,p0-vec3(SIZE*PC.x*2.,1.,SIZE*0.15),vec3(SIZE*tk,2.,SIZE*tk),3.));
    Add(r,Box(m0,p0-vec3(SIZE*PC.x*2.,1.,-SIZE*0.15),vec3(SIZE*tk,2.,SIZE*tk),3.));
    Add(r,Box(m0,p0-vec3(SIZE*PC.x*2.,3.,0.),vec3(SIZE*tk,SIZE*tk,SIZE*.15),3.));
    Add(r,Box(m0,p0-vec3(-SIZE*PC.x*2.,1.,SIZE*0.15),vec3(SIZE*tk,2.,SIZE*tk),3.));
    Add(r,Box(m0,p0-vec3(-SIZE*PC.x*2.,1.,-SIZE*0.15),vec3(SIZE*tk,2.,SIZE*tk),3.));
    Add(r,Box(m0,p0-vec3(-SIZE*PC.x*2.,3.,0.),vec3(SIZE*tk,SIZE*tk,SIZE*.15),3.));
    for(int i=0;i<=22;i++)
    {
        vec4 pl=  texelFetch(iChannel0,ivec2(i,0),0);
        vec3 p= p0 - vec3(pl.x,0.,pl.y)*40.;
        float a =pl.z+1.57;
       
        r0=Box(m0,p,vec3(.45,2.2,.45),2.);//bounding box:  player
        if((m0.t<0. && r0.tN <.5) || (m0.t>=0. && r0.tN>=0. && r0.tN<NOHIT)){
            RayIn ri_player=m0;
            RayOut ro_player;
            if(i==0){
                //ball
                 ro_player= RotSphere(ri_player,p-vec3(0,.1,0),.18,a,3.); 
            }
            else{
                 float fl= (mod(pl.w*.5,0.04)-0.02);
                 float mat_id=(i<12? 5.:4.),sk_id=2.+float(i&1)*4.;
                 if(i==1 || i==12) mat_id=8.;
                Add(r,RotSphere(ri_player,p-vec3(0,2.,0),.18,a,sk_id)); //todo fix head rotation
   
                RotView(p,ri_player,ro_player, vec3(0,1,0),vec3(0.,0,0), a, //player rotation
                
                 
                ro_player=  Box(ri_player,p-vec3(0,1.43,0),vec3(.28,.35,.1),mat_id);
                float mrot=.4; float rot= abs(mod(fl*20.,mrot*3.)-mrot);
               
                Add(ro_player,RotBox(ri_player,p-vec3(+.4,1.47,0),vec3(.08,.3,.08),vec3(1,0,0),vec3(0,0.25,0),rot-mrot*.5,sk_id));
                Add(ro_player,RotBox(ri_player,p-vec3(-.4,1.47,0),vec3(.08,.3,.08),vec3(1,0,0),vec3(0,0.25,0),mrot*.5 -rot,sk_id));    
                Add(ro_player,RotBox(ri_player,p-vec3(+.17,.5,0),vec3(.08,.5,.08),vec3(1,0,0),vec3(0,0.35,0),mrot*.5 -rot,sk_id));
                Add(ro_player,RotBox(ri_player,p-vec3(-.17,.5,0),vec3(.08,.5,.08),vec3(1,0,0),vec3(0,0.35,0),rot-mrot*.5,sk_id));
            );
           }
            r= Union(r,ro_player);
        } else if( r0.tN >=.5) r=Union(r,r0); //outside player BB
    }
    }else if( r0.tN >=.5) r=Union(r,r0);//outside field BB
    oRay=r;
    return r.tN;
}

vec3[8] mat = vec3[8](
    vec3(0.184,0.380,0.082), //pitch
    vec3(0.914,0.584,0.584), //pale skin
    vec3(0.945,0.933,0.635), //ball
    vec3(0.294,0.420,0.925), //blue
    vec3(0.855,0.043,0.043), //red
    vec3(0.251,0.047,0.047),  //dark skin
    vec3(0.275,0.267,0.267),  //wall
    vec3(0.973,0.941,0.051)   //goalkeeper
    );

//------------------------------------
float trace(vec3 ro, vec3 rd) {
    return map( RayIn(rd,0.), ro);
}




vec3 lights(vec3 p, vec3 rd, float d) {
    vec3 lightPos =  vec3(1500.,2000.,-500.) ;
	vec3 ld = normalize(lightPos - p), 
    n =  oRay.n;

	float l1 = max(0., .5 + .5 * dot(ld, n)),
        spe = max(0., dot(rd, reflect(ld, n))) * .1,
        fre = smoothstep(.7, 1., 1. + dot(rd, n));
   
    vec3 pp=p+.001*n;
    float ss=.7;
    if(texelFetch(iChannel3,ivec2(50,2),0).x>.1) ss=.4;
	l1 *=  (1.-ss)+ss*  smoothstep(.001,500., trace(pp,ld));
         
	vec3 lig = (l1+ spe) * vec3(1.) *2.5;
	return mix(.3, .4, fre) * lig;
}

vec3 getRayDir(vec3 ro, vec3 lookAt, vec2 uv) {
	vec3 f = normalize(lookAt - ro),
		 r = normalize(cross(vec3(0, 1, 0), f));
	return normalize(f + r * uv.x + cross(f, r) * uv.y);
}


void mainImage(out vec4 fragColor, vec2 fc)
{
	vec4 ball=  texelFetch(iChannel0,ivec2(0),0);         
    vec4 zBall=texelFetch(iChannel1,ivec2(coord(ball.xy)),0);   
    

    
    if(iMouse.z>0.) fc=iMouse.xy+.66*(fc-iMouse.xy);
    vec2 uv = (fc - .5 * iResolution.xy) / iResolution.y;
	vec3 ro =vec3(ball.x*40.+20.,15,ball.y*20.),
         rt= vec3(ball.x*40.,0.,.01+ball.y*20.);		
    if(texelFetch(iChannel3,ivec2(49,2),0).x<1.) {
        ro =vec3(ball.x*12.,35,-28.);	
        rt=vec3(ro.x+.01,0,-4);
    
    } 
    if(texelFetch(iChannel3,ivec2(50,2),0).x>.1) {
        ro =vec3(0,45,0.1);	
        rt=vec3(0,0,0);
    }
    vec3 rd =  getRayDir(ro, rt, uv);
    
        
 
    float d=trace(ro,rd);  
    vec3 p=ro+rd*d; 
    int mat_id=int(oRay.id)-1;
    vec3 alb=mat[mat_id];
    if(mat_id==0 &&  pitch(p.xz/40.)<tk) alb=vec3(1);
    vec2 uvt= fract(oRay.fuv.yz*.1)-.5;
    if((mat_id==0 || mat_id==6) && uvt.x*uvt.y<0.)alb*=.9;
    vec3 col=lights(p, rd, d) * exp(-d * .001)*alb;
    if(mat_id==0  && texelFetch(iChannel3,ivec2(32,2),0).x>0.){
        vec2 uv2=p.xz/SIZE/2.;
        vec4 d=texelFetch(iChannel1,ivec2(coord(uv2)),0);
        float side = sign(zBall.x-11.5 );
        float cScore= abs(score(side,uv2,ball,d));                        
        int j = int(d.x);        
        //team zones
        col=mix(col,  ((j<12? vec3(.5,0,0):vec3(0,0,.7))), .8*smoothstep(-.3,.3,cScore));
        vec4 b=ball;
        vec4 zBallt=texelFetch(iChannel1,ivec2(coord(ball.xy+ball.zw*1.)),0);
        col=mix(col, vec3(1,1,0),smoothstep(tk,.0,-.01+length(uv2-b.xy-b.zw*TDIST))); //ball target 
        vec4 pl=texelFetch(iChannel0,ivec2(zBall.x,0),0);
        col=mix(col, vec3(1,0,1),smoothstep(tk,.0,-.01+length(uv2-pl.xy))); //closest player
        vec4 plt=texelFetch(iChannel0,ivec2(zBallt.x,0),0);
        col=mix(col, vec3(0,1,1),smoothstep(tk,.0,-.01+length(uv2-plt.xy))); //target player   
        vec2 offs=texelFetch(iChannel0,ivec2(27,0),0).xy;
        col=mix(col, vec3(.5,.5,0),smoothstep(tk,0.,min(abs(uv2.x-offs.x),abs(uv2.x-offs.y))));        
    }
    
    
    //score
    ivec4 sc= ivec4( texelFetch(iChannel0,ivec2(25,0),0));
    drawChar(iChannel2, col, vec3(0.,.7,0), uv, vec2(-0.05,.45), vec2(.1), 48+sc.x);
    drawChar(iChannel2,col, vec3(0.,.7,0), uv, vec2(0.00,.45), vec2(.1), 45);
    drawChar(iChannel2,col, vec3(0.,.7,0), uv, vec2(0.05,.45), vec2(.1), 48+sc.y);
    fragColor = vec4(pow(col, vec3(.45)), 0);
}