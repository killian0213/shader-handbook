// Image (image) — Rolling Polygon by Shane
// https://www.shadertoy.com/view/3sGBDm

/*

	Rolling Polygon
	---------------

	This is yet another shader that has been sitting in my account for too 
    long. I was going to code a rolling polyhedron on terrain, but it'd been 
    a while since I'd applied collision-based physics, rigid body or otherwise, 
    so I decided to quickly code up a 2D n-gon rolling across an undulating 1D 
    noisy surface. It took me longer than the five minutes I expected it to 
    take, and that was without applying proper physical forces... The math and 
    physics student in me would be disappointed in what I've become. :D
    
    Even so, the idea is very simple: The lowest vertex is always in contact 
    with the ground, so determine which vertex it is and its distance from the 
    contact surface, then use it to offset all vertices... You could use repeat 
    polar coordinates to do this. However, I wanted to test the mid points 
    between vertices to gain a little more ground contact collision accuracy. 
    Plus, I also wanted infrastructure that could deal with haphazard shapes.
    
    Anyway, this example is not that important, and the code was rushed. I've 
    also added a heap of window dressing. Everything works, but there'd be 
    cleaner ways to do what I'm doing here, so you can ignore most of it. 
    Having said that, there isn't a great deal of code featuring rolling 2D 
    polygons along an undulating surface, so at least this is a start. :)
    


    Other examples:
    
    // Much... much more difficult terrain collision, and far more interesting, 
    // but still based on similar principles. By the way, Dr2 has dozens more
    // collision based examples worth looking at.
    Leaping Snakes 2 - dr2
    https://www.shadertoy.com/view/3lBXWV
	

*/


// Number of Polygon vertices:
// Positive integers ranging from 2 to about 8 will work.
// 2 (just a line) looks a bit odd, but is interesting.
// Also, the speeds below may need adjusting.
#define VERTICES 5


// Polygon speed and rotation speed -- Technically, the forward motion should be
// based mostly on the rotation speed, but I'm fudging things a little.
float speed = .4;
// Higher rotational speeds simulate spinning on the surface... Kind of. :)
float rotSpeed = .42;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){ return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

 

// I searched Shadertoy for a robust regular polygon routine and came across
// the following example:
//
// Regular Polygon SDF - BasmanovDaniil
// https://www.shadertoy.com/view/MtScRG
//
// To use the functions in more intensive scenes, some optimization would be
// necessary, but I've left them in their original form to show the working.

float Polygon(vec2 p, float vertices, float radius){

    float segmentAngle = 6.2831853/vertices;
    
    float angleRadians = atan(p.x, p.y);
    float repeat = mod(angleRadians, segmentAngle) - segmentAngle/2.;
    float inradius = radius*cos(segmentAngle/2.);
    float circle = length(p);
    float x = sin(repeat)*circle;
    float y = cos(repeat)*circle - inradius;

    float inside = min(y, 0.);
    float corner = radius*sin(segmentAngle/2.);
    float outside = length(vec2(max(abs(x) - corner, 0.0), y))*step(0.0, y);
    return inside + outside;
}



// Cheap and nasty 2D smooth noise function with inbuilt hash function -- based on IQ's 
// original. Very trimmed down. In fact, I probably went a little overboard. I think it 
// might also degrade with large time values.
float n2D(vec2 p) {

	vec2 i = floor(p); p -= i; p *= p*(3. - p*2.); // p *= p*p*(p*(p*6. - 15.) + 10.); //
    
	return dot(mat2(fract(sin(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)))*43758.5453))*
                vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );

}


float height(vec2 p){
    
    
    p.x += iTime*speed;
    p *= 3.;
    float ns = n2D(p)*.57 + n2D(p*2.)*.28 + n2D(p*4.)*.15;
    //float ns = n2D(p)*.67 + n2D(p*2.)*.33;
    return (mix(ns, smoothstep(.25, 1., ns), .5) - .5)*.25;
}

// The map function. Just two layers of gradient noise. Way more interesting
// functions are possible, but we're keeping things simple.
float map(vec2 p){

    float ns = height(vec2(p.x, 0.));
    float ter = p.y + ns + .075;
    
    return ter;
  
}



// 2D derivative function.
vec2 getNormal(in vec2 p, float m) {
	
    vec2 e = vec2(.001, 0);
    
    // Four extra samples. Slightly better, but not really needed here.
	//return (vec2(map(p + e.xy, i) - map(p - e.xy, i), map(p + e.yx, i) - map(p - e.yx, i)))/e.x*.7071;

    // Three samples, but only two extra sample calculations. 
    return vec2(m - map(p - e.xy), m - map(p - e.yx))/e.x*1.4142;
}



// A hatch-like algorithm, or a stipple... or some kind of textured pattern.
float doHatch(vec2 p){
    
    float res = iResolution.y;
    
    // Produce the pattern.
    
    
        
    
        // The pattern is physically based, so needs to factor in screen resolution.
        p *= res/16.;
    
    	// Just a hack to deal with large "p" values as time progresses.
    	p = mod(p, 64.);

        // Random looking diagonal hatch lines.
        float hatch = clamp(sin((p.x - p.y)*3.14159*200.)*2. + .5, 0., 1.); // Diagonal lines.

        // Slight randomization of the diagonal lines, but the trick is to do it with
        // tiny squares instead of pixels.
        float hRnd = hash21(floor(p*6.) + .73);
        if(hRnd>.66) hatch = hRnd;  


        hatch = hatch*.2 + .8;
        

        return hatch;
    
}



// The polygon line pattern.
float linePattern(vec2 p, vec2 a, vec2 b){
  
    // Determine the angle between the vertical 12 o'clock vector and the edge
    // we wish to decorate (put lines on), then rotate "p" by that angle prior
    // to decorating. Simple.
    vec2 v1 = vec2(0, 1);
    vec2 v2 = (b - a); 
 
    // Angle between vectors.
    //float ang = acos(dot(v1, v2)/(length(v1)*length(v2))); // In general.
    float ang = acos(v2.y/length(v2)); // Trimed down.
    p = rot2(ang)*p; // Putting the angle slightly past 90 degrees is optional.

    float ln = doHatch(p);//clamp(cos(p.x*96.*6.2831)*.35 + .95, 0., 1.);

    return ln;// *clamp(sin(p.y*96.*6.2831)*.35 + .95, 0., 1.); // Ridges.
 
}



void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Coordinates.
    float res = min(iResolution.y, 800.);
    vec2 uv = (fragCoord - iResolution.xy*.5)/res;
    
    // Scaling, translation, etc.
    vec2 p = uv - vec2(.25, 0);
    
    // Keep a copy.
    vec2 oP = p;

    // Smoothing factor.
    float sf = 1./iResolution.y;
    
    // Number of Polygon vertices:
    // Positive integers ranging from 2 to about 8 will work.
    // 2 (just a line) looks a bit odd, but is interesting.
    const int sNum = VERTICES;
    const float fsNum = float(sNum);
    
    
    // Gradient at the center of the shape.
    float grad = (map(vec2(.03, 0)) - map(vec2(-.03, 0)));

    // Rotating time, based on vertice number.
    float t = fract(iTime*min(mix(fsNum, 5., .5), 6.)*rotSpeed);
    t = pow(t, .8);
    t *= 6.283185/fsNum;
    t -= sign(grad)*grad*grad*4.;
   
    
    // Emulating friction -- very badly. :)
    p.xy += vec2(-.5, 1.5)*(cos(t*fsNum - 1.57*.5)*.5 + .5)*.005;
 
    
    // Various distance field values, etc.
    float d = 1e5, vert = d, vert2 = d, poly = d, ln = d, gP = d, ico = d, ico2 = d;
    
    // Polygon side length and vertex size.
    float l = .18;
    float pSz = .015;
    
    
    // Point and transformed point holders.
    vec2[sNum] pnt;
    vec2[sNum] tPnt;
    
    // Create the points, then rotate them.
    for(int i = 0; i<sNum; i++){
        
        pnt[i] = rot2(6.283185/fsNum*float(i))*vec2(0, 1./sqrt(2.))*l;
        tPnt[i] = rot2(t)*pnt[i];
    }
    
    // Line pattern.
    float sLinePat = linePattern(p - vec2(-iTime*speed*1.2, 0), vec2(1, 1), vec2(1, -1));
    
    // Bottom dashed line:
    float xOffs = -.15 - .25;//-.35
    float yOffs = -.43;
    if(res>500.) yOffs -= .1;
    float g = abs(p.y - yOffs + .018) - .0025;
    vec2 q = mod(p + vec2(iTime*speed, 0), 1./32.) - .5/32.;
    float dash = abs(q.x) - .2/32.;
    g = max(g, -dash);
    

    // Find the minimum vertex point height, since that will be the vertex
    // in contact with the ground.
    int lvert = 0;
    for(int i = 0; i<sNum; i++){ 
        
        if(tPnt[i].y<gP) {
            gP = tPnt[i].y;
            lvert = i;
        }

    }
    // Adjust every transformed point by the minimum. 
    for(int i = 0; i<sNum; i++) tPnt[i].y -= gP - yOffs;
   
    // Keeping a copy for the ground based polygon below. Normally, this 
    // wouldn't be necessary.
    float gP2 = gP;

    
    // Previous and next vertex numbers.
    int lvertp = int(mod(float(lvert) + 1., fsNum));
    int lvertn = int(mod(float(lvert) - 1., fsNum));
    
    // Number of midpoints between successive vertices. We test these against
    // the terrain also. More contact points mean more accurate collision.
    const int midPoints = 2;
    
    gP = 1e5;
    
    for(int i = 0; i<sNum; i++){ 
        
        // Terrain height.
        float h = map(vec2(tPnt[i].x, 0));
        
        // If the current vertex plus height is lowest, it becomes the new lowest point.
        if(tPnt[i].y + h<gP) {
            gP = tPnt[i].y + h;
        }
        
        // Add the vertex point to the overall distance field.
        vert2 = min(vert2, length(p - tPnt[i]*.16/.18 - vec2(xOffs, .115*yOffs)) - pSz);
        
        // Get the next vertex point index.
        int inext = (i + sNum - 1)%sNum;
        
        // Check the midpoints between the current and next point, the perform a
        // collision check with the terrain.
        for(int j = 0; j<midPoints; j++){
            
            // Current midpoint... Hmm, midpoint was probably a poor choice of 
            // word, since there can be more than one... Pretend that I mean, waypoint. :)
            vec2 mid = mix(tPnt[i], tPnt[inext], float(j + 1)/float(midPoints + 1));
            float hmid = map(vec2(mid.x, 0)); // Midpoint height.

            // If the current midpoint plus height is lowest, it becomes the new lowest point.
            if(mid.y + hmid<gP) {
                gP = mid.y + hmid;
            }
            
            // Add the midpointto the overall distance field.
            vert2 = min(vert2, length(p - mid*.16/.18 - vec2(xOffs, .115*yOffs)) - pSz*.5);
             
             
        }
    } 
 
   
 
    
    ///////////////////
    
    // Terrain calculations.
    
    float ter = map(p);
    vec2 n = getNormal(p, ter);
    float len = length(n);
   
    vec2 p2 = p*vec2(1, -1) - vec2(75.3, -.3);
    float ter2 = map(p2); 
    vec2 n2 = getNormal(p2, ter2);
    float len2 = length(n2);
 
    
    // Polygon contruction.
    q = rot2(-t)*(p - vec2(0, -gP  - (gP2 - yOffs)));
    poly = Polygon(q, fsNum, l/sqrt(2.)); 
    poly = max(poly, -(poly + .06)); // Hole.
   
    
    // Polygon line pattern. 
    float t2 = (iTime*rotSpeed*(4.));
    t2 *= 6.283185/4.;
    vec2 qp = rot2(-t2)*(p - vec2(0, -gP  - (gP2 - yOffs)));
    float patPoly = clamp(sin((qp.y)*6.283185*50.*sqrt(2.))*.5 + 1., 0., 1.);
    //
    vec2 qq = rot2(-t2)*(p - vec2(0, -gP  - (gP2 - yOffs)));
    //qq = (rot2(-t2))*(p - vec2(0, -gP  - (gP2 - yOffs)));
    patPoly = linePattern(qq, pnt[0], pnt[1]);
    

    
    // Polygon vertices.
    q = rot2(6.283185/2./fsNum)*q;
    float a = atan(q.x, q.y);
    float ia = (floor(a*fsNum/6.283185) + .5)/fsNum;
    q = rot2(-ia*6.283185)*q;
    q.y -= l/sqrt(2.);
    // 
    vert = min(vert, length(q) - pSz);
    
    
    // Terrain overlay line pattern.
    float pat = linePattern(p - vec2(-iTime*speed, 0), vec2(1, 1), vec2(1, -1));
    
    // Dashes.
    q = p;
    q.x = mod(q.x + iTime*speed, 1./36.) - .5/36.;
    q.y -= -map(vec2(p.x, 0));//-gP - (gP2 - yOffs);
    // Rotating by the half the tangent. Normally, you'd use the whole tangent, but
    // I wanted to rotate the lines toward the curve, but not all the way, for 
    // aesthetic purposes.
    q = rot2(atan(-n.x, n.y)/2.)*q;
    dash = abs(q.x) - .2/36.;
    
    q = p2;
    q.x = mod(q.x + iTime*speed, 1./36.) - .5/36.;
    q.y -= -map(vec2(p2.x, 0));//-gP - (gP2 - yOffs);
    // Rotating by the half the tangent. Normally, you'd use the whole tangent, but
    // I wanted to rotate the lines toward the curve, but not all the way, for 
    // aesthetic purposes.
    q = rot2(atan(-n2.x, n2.y)/2.)*q;
    float dash2 = abs(q.x) - .2/36.;
    
    
    // Noise texture.
    q = (p - vec2(-iTime*speed, 0));
    q *= vec2(2, 4. + ter)*32.;
    float ns = n2D(q)*.57 + n2D(q*2.)*.28 + n2D(q*4.)*.15;
    vec3 tx = vec3(1);//*(smoothstep(0., .1, ns - .5)*.1 + .9);


 
    // Tunnel background.
    vec3 col = vec3(1, .92, .75)*.8;
    col *= sLinePat;
    
    // Resolution shadow factor.
    float shF = res/450.;
   
    // Top terrain overlay.    
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*length(n2)*8.*shF, ter2 - length(n2)*.00))*.3);    
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*length(n2), max(ter2, -dash2))));//vec3(.7, .8, .5)
    col = mix(col, vec3(1, .94, .78)*pat*tx, (1. - smoothstep(0., sf*length(n2), ter2 + length(n2)*.005)));
    
    // Bottom terrain overlay.
    float sh = clamp(clamp(sin(ter*250. - 3.14159) + .9, 0., 1.), 0., 1.);
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*length(n)*8.*shF, ter - length(n)*.00))*.3);    
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*length(n), max(ter, -dash))));//vec3(.7, .8, .5)
    col = mix(col, vec3(1, .94, .78)*pat*tx, (1. - smoothstep(0., sf*length(n), ter + length(n)*.005)));
   
    
   
    // Polygon lines.
    col = mix(col, vec3(0), (1. - smoothstep(0., sf*8.*shF, min(poly, vert - .003) - .004))*.3);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, poly - .004));
    col = mix(col, vec3(1, .97, .92)*patPoly, 1. - smoothstep(0., sf, poly + .004));

    // Bottom straight faded line.
    float fade = min(abs(uv.x - (xOffs + .25)), 1.);
    col = mix(col, mix(col, vec3(0), 1. - smoothstep(0., .15, fade - .3)), (1. - smoothstep(0., sf, g)));
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, ln));
   
    // Polygon vertices.
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, vert - .003));
    col = mix(col, mix(vec3(1, .8, .42), vec3(.8, 1, .35)*1.3, .4), 1. - smoothstep(0., sf, vert + .003));

    // Bottom polygon vertices.
    vec3 bg = col;
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, vert2 - .003));  
    col = mix(col, mix(vec3(1, .8, .42), vec3(.8, 1, .35)*1.3, .2), 1. - smoothstep(0., sf, vert2 + .003));  
    
    
    // Render some border objects to frame things a little bit.
    //
    // Border sights: The background corners looked a little empty, so I threw 
    // these in to balance things out... Not sure if it worked, but it's done now. :)
    vec2 b = vec2(iResolution.x/iResolution.y, 1) - .1;
    q = (uv*2.);
    q.x = abs(q.x);
    q.y = -q.y;
    float bord = max(q.x - b.x, q.y - b.y);
    bord = max(bord, -(bord + .11));
    bord = max(bord, -min(q.x - b.x + .22, q.y - b.y + .22));
    //bord = max(bord, -(bord + .02));

    
    // Render the border sight... edge things, or whatever they are.
    float falloff = 1./res;
    col = mix(col, vec3(0), (1. - smoothstep(0., falloff*12.*shF, bord ))*.35);
    col = mix(col, vec3(0), (1. - smoothstep(0., falloff, bord))*.7);
    col = mix(col, bg*1., (1. - smoothstep(0., falloff, bord + .01)));
    col = mix(col, vec3(0), (1. - smoothstep(0., falloff, bord + .035)));
    col = mix(col, bg*1.3, (1. - smoothstep(0., falloff, bord + .044)));    
    ////
     
    // Very subtle sepia tone with a sprinkling of noise, just to even things up a bit more.
    p.xy += iTime*speed*vec2(1, .0);
    col *= vec3(1.03, 1, .97);
    // Noise, with custom frequency and amplitude distribution.
    col *= ((n2D(p*16.)*.4 + n2D(p*36.)*.25 + n2D(p*80.)*.2 + n2D(p*180.)*.15)*.2 + .9);
    
    // Failed color experiment.
    //col = mix(col, col.zyx, uv.y*.5);
  
    // Subtle vignette.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*(1. - uv.x)*(1. - uv.y)*uv.x*uv.y, 1./16.)*1.05;

    // Output to screen
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}