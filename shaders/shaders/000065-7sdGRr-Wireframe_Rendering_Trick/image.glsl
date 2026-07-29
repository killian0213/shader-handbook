// Image (image) — Wireframe Rendering Trick by Tater
// https://www.shadertoy.com/view/7sdGRr

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define pi 3.1415926535

//This technique will eat steps like nothing else if you have a complex scene, but it does
//look nice
#define STEPS 128.0

#define MDIST 50.0

float box( vec3 p, vec3 b ){
  vec3 d = abs(p)-b;
  return max(d.x,max(d.y,d.z));
}
float octa( vec3 p, float s){
  p = abs(p);
  return (p.x+p.y+p.z-s)*-tan(5.0*pi/6.0);
}

//Standard SDF scene with material IDs
vec2 map(vec3 p){
    vec2 a = vec2(1),b = vec2(2);
    float t = iTime;
    vec3 po = p;
    
    //Box
    p.x+=9.0;
    p.xy*=rot(t);
    p.yz*=rot(t);
    p.zx*=rot(t);
    a.x = box(p, vec3(1.5));
    //Onion the box
    a.x = abs(abs(a.x)-0.4)-0.2;
    
    //Octahedron Thing
    p = po;
    p.xy*=rot(-t);
    p.yz*=rot(-t);
    p.zx*=rot(t);
    
    b.x = octa(p,4.0);
    b.x = max(b.x,box(p,vec3(4.0-(sin(t)*0.5+0.5)*2.0)));
    a = (a.x<b.x)?a:b;
    
    //Exploding Cube
    p = po;
    p.x-=9.0;
    p.xy*=rot(-t);
    p.yz*=rot(t);
    p.zx*=rot(-t);
    float off = 0.8*min(2.5*(sin(t)*0.5+0.5),1.5);
    
    p= abs(p)-off*0.9;
    p= abs(p)-off*1.3;
    
    b.x =  box(p,vec3(0.75));
    b.y = 3.0;
    a = (a.x<b.x)?a:b;
    return a; 
}

//Not all normal functions work the same, @totetmatt also suggested this one
//which works as well.

/*
#define q(s) s*map(p+s).x
vec3 norm(vec3 p,float e){vec2 nv=vec2(e,-e); return normalize(q(nv.xyy)+q(nv.yxy)+q(nv.yyx)+q(nv.xxx));}
*/

vec3 norm(vec3 p, float s) {
  vec2 off=vec2(s,0);
  return normalize(
   vec3(map(p+off.xyy).x, map(p+off.yxy).x, map(p+off.yyx).x)
  -vec3(map(p-off.xyy).x, map(p-off.yxy).x, map(p-off.yyx).x));
}

//When I first saw NuSan's shader from the nevoke pre-jam I didn't notice
//he was actually rendering the wireframe of objects and not just the edge.
//I've tried to come up with a way to render SDF wireframes more than once
//so seeing such an easy way to do it feels like a christmas present

//Brief Explination based on my understanding of how this works:
//Hit an object, calculate it's edge with FMS_Cat edge technique,
//March through the inside of the object, then after hitting the inside 
//calculate the edge again and combine it with previous edges

//Technically the rendered lines are like 90 degree corners,
//so if they are very thick or the angles are shallow you will 
//be able to tell that they aren't a consistent width, but the 
//effect is still quite good imo.


void render( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.y;
    vec3 col = vec3(0);
    float t = iTime;
    vec3 ro = vec3(0,0,-16.5);
    vec3 lk = vec3(0,0,0.0);
    vec3 f = normalize(lk-ro);
    vec3 ra = normalize(cross(vec3(0,1,0),f));
    vec3 rd = normalize(f*0.9+uv.x*ra+uv.y*cross(f,ra));
    
    //s (sign) variable will be used to keep track of if we are marching inside
    //or outside an object
    
    //In NuSan's original shader he didn't used this, and instead added
    //the abs() of the distance to keep marching through objects
    //This way has the benefit of being able to converge to the surface before
    //continuing which makes the lines a bit crisper, but costs some steps & performance
    float s=1.0;
    
    float rayDist,shad;
    vec3 p = ro;
    vec2 d;
    bool hit = false;
    vec3 al;
    
    //Raymarch loop
    for(float i =0.0; i<STEPS; i++){

        //Set current point to based on rayDistance
        p = ro+rd*rayDist;
        
        //Get scene dist and material ID
        d = map(p);
       
        //Converge onto the surface (Seems large epsilon values work better)
        if(abs(d.x)<0.01){
        
            //Determine wireframe/material color whenever an object is hit
            if(d.y == 1.0)al = vec3(1.000,0.659,0.976);
            if(d.y == 2.0)al = vec3(0.016,1.000,1.000);
            if(d.y == 3.0)al = vec3(1.000,0.647,0.325);
            
            //Calculate how big the normal sample offset difference should be
            //based on ray distance, so the wireframe is the same thickness
            //everywhere. 
            
            //You can remove the "rayDist" term and the wireframes will get thinner
            //further away which sometimes looks better but you will need to increase
            //the initial value considerably 
            float edge = 0.003*rayDist*clamp(800.0/iResolution.x,1.0,2.5);
            
            //Edge detection, not sure exactly how this works but I think FMS_Cat
            //was the first one to use this trick. 
            
            //You take length of the difference of two normalize vectors, the bigger 
            //the difference in offset of the normal the thicker the edge will be. 
            float edgeAmount = length(norm(p, 0.015)-norm(p, edge));
            
            //Add the detected edge, I use smoothstep here to make
            //The edge a bit crisper but it's not nessecary.
            
            //Multiply this value by a lower number to give the wireframe
            //a trasparent effect (helps a lot in complex scenes) 
            col += smoothstep(0.0,0.1, edgeAmount)*0.25;
            
            //The magic bit, after we detect an edge invert the s (sign) value,
            //and keep marching through the object but now with an inverted
            //distance field, so the edge detection gets run every time we hit
            //any sufrace, effectively creating a wireframe instead of just edges
            s*=-1.0;
            d.x = 0.01*s;
            
            //Quick iteration based fake ao to get shading
            if(!hit){
                shad = i/STEPS;
                hit = true;
            }
        }
        //A maximum distance break is pretty required since the rays will never hit anything
        if(rayDist>MDIST) break;
        
        //Add the current scene distance to the ray length, with the s (sign) value
        //so we always march through objects
        rayDist+=d.x*s;
        
        //Alternatively you can remove the s (sign) term from everywhere in the shader
        //and replace this bit with
        //rayDist+=abs(d.x);
       
    }
    //Grab the wireframe color that came out of the ray marcher
    vec3 wire = col;
    
    //Color the wireframe
    wire = clamp(wire,0.0,1.0)*al;
    
    //Quick iteration shading
    shad = pow(1.0-shad,2.0);
    if(hit)col = vec3(shad)*sqrt(al);
    
    //Mix between shaded and wireframe scene
    col = mix(col,wire,clamp(1.0-pow(sin(t*0.5),3.0),0.0,1.0));
    
    fragColor = vec4(col,1.0);
}
//My quick copy paste AA
//If you can afford the performance it looks a lot better with AA (change AA to 2.0);
#define AA 1.0
#define ZERO min(0.0,iTime)
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float px = 1.0/AA;
    vec4 col = vec4(0);
    
    if(AA==1.0) {render(col,fragCoord); fragColor = col; return;}
    
    for(float i = ZERO; i <AA; i++){
        for(float j = ZERO; j <AA; j++){
            vec4 col2;
            vec2 coord = vec2(fragCoord.x+px*i,fragCoord.y+px*j);
            render(col2,coord);
            col.rgb+=col2.rgb;
            //If the shader uses accumulation effects they need to be reset here
        }
    }
    col/=AA*AA;
    fragColor = vec4(col);
}


//Fabrice's magic AA
/*
void mainImage(out vec4 O, vec2 U) {
    render(O,U);
    if ( fwidth(length(O)) > .01 ) {  // difference threshold between neighbor pixels
        vec4 o;
        for (int k=0; k < 9; k+= k==3?2:1 )
          { render(o,U+vec2(k%3-1,k/3-1)/3.); O += o; }
        O /= 9.;
     // O.r++;                        // uncomment to see where the oversampling occurs
    }
}
*/



