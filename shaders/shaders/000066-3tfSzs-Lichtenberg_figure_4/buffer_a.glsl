// Buffer A (buffer) — Lichtenberg figure 4 by rory618
// https://www.shadertoy.com/view/3tfSzs


#define cam (vec3(0.,0.,.21))
#define theta ((iMouse.yx/iResolution.yx-.5)*vec2(-6,6))
#define transform (mat4(1,0,-cam.x/cam.z,0,0,1,-cam.y/cam.z,0,0,0,1,0,0,0,-1./cam.z,1)*(mat4(cos(theta.y),0,-sin(theta.y),0,0,1,0,0,sin(theta.y),0,cos(theta.y),0,0,0,0,1)*mat4(1,0,0,0,0,cos(theta.x),sin(theta.x),0,0,-sin(theta.x),cos(theta.x),0,0,0,0,1)))


//Particle buffer
void mainImage( out vec4 O, in vec2 I )
{
    vec3 col = texture(iChannel0, I/R.xy).xyz*.01+.5;
    vec2 coord;
    
    int seed = int(iMouse.x);

    int seed2 = int(I.x + I.y*2000.)+iFrame*4000000;
    vec2 sf = R.xy/R.y;
    vec2 a = vec2(0);
    vec2 b = vec2(R.xy);
	vec2 c,d;
    col = vec3(1);
    for(int k=0; k<24;k++){
        int v = (200/(k+1));
        float l = length(b-a);


        c = (a+b)/2.+l*randn(rand2(seed^0x8593F4D5))/6.;
        d = (a+b)/2.+l*randn(rand2(seed^0x93D35DE5))/1.;

		vec4 j = rand4(seed2^IHash((iFrame*0x5da8d7da)));
        
        float d0 = length(a-c);
        float d1 = length(b-c);
        float d2 = length(c-d)/4.;
        float s = d0+d1+d2;
        if(j.x<d0/s){
            b=c;
            seed = IHash(seed^0x7d964ba9);
            seed2 = IHash(seed2^0x7d964ba9);
        } else if(j.x<(d0+d1)/s){
            a=c;
            seed = IHash(seed^0xb7798235);
            seed2 = IHash(seed2^0xb7798235);
        } else {
            a=c;
            b=d;
            seed = IHash(seed^0x5b2a74f5);
            seed2 = IHash(seed2^0x5b2a74f5);
            col *= vec3(.95,.95,.956);
        }
            
    }
    
    coord = mix(a,b,Hash(seed2));
    //coord *= R.y*2.;
    //coord += R.xy*vec2(.5,-1);
	coord += .2*randn(rand2(seed2^0xAA91B4C3));
    particle p = particle(!(coord.x>0.&&coord.x<R.x&&coord.y>0.&&coord.y<R.y), coord, col);
    O.xy = packParticle(p);
}