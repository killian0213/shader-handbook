// Image (image) — scribble blue in tweets of two by flockaroo
// https://www.shadertoy.com/view/tsV3Rw

// created by florian berger (flockaroo) - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// scribble blue in tweets of two
//
// improved + golfed down ballpoint effect
//
// check "https://10xfx.com" for this and more effects for AfterEffects and OpenFX

#define R iResolution.xy

#define V(p) textureLod(iChannel0,(p)/R,.5).y

void mainImage( out vec4 c, vec2 f )
{
	float S=sqrt(R.x)/30.,h,s;
    // thx IAI95, Shane, GregRostami (c/=c wont work for me though)
    //c=c-1.;  // <- unfortunately not working on all systems
    c=vec4(1); // <- hmm... portable but now 2tweets+1 ;-(
    vec2 g,d=R/2E2,p,q,v,i,e=vec2(d.x*.2,0);
    for(int k,j=k=0;j<3000;k=++j>>4)
    {
        //int k=j/16;  // this went into the for() - now < 2tweets again ...phew!!
    	if(j%16==0) { i=floor(f/d)+vec2(k%13,k/13)-6.; s=mod(i.y,2.)-.5; p=(i+s)*d; v-=v; }
	    q=p;
        g=V(p)-vec2(V(p-e),V(p-e.yx));
        h=pow(dot(g,g),.3)*20.;
        v=mix(v, 
              mat2( cos( .8*vec4(4,2,6,4) + atan(h)*1.3*s+s ) ) * normalize(g), 
              atan(h*h/8.));
        p+=v*d.x;
	    g=q-p; q=f-p; float l=length(g); g/=l; h=dot(q,g);
		c-=vec4(.3,.2,.1,0)*max(S-max(S-min(l-h,h),abs(dot(q,g.yx*vec2(1,-1)))),0.);
    }
}


