// Buffer A (buffer) — Microcars by iapafoto
// https://www.shadertoy.com/view/XlXBWl

float gTime;

vec4[12] _PREV = vec4[12](
    vec4(1,0,-1,0), vec4(-1,0, 1,0), vec4(0,-1,0,1), vec4( 0,1,0,-1),
    vec4(0,1,1,0),  vec4( 0,1,-1,0), vec4(0,-1,1,0), vec4(-1,0,0,-1),
    vec4(-1,0,0,1), vec4( 1,0,0,1), vec4(-1,0,0,-1), vec4( 1,0,0,-1)    
);


vec4 state(in vec2 ip ) {
    return texelFetch(iChannel0, ivec2(ip), 0);
}


// Dave Hoskins's
vec3 hash23(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

// 0:left 1:right 2:top 3:bottom
int getSide(vec2 p) {
    return p.y == 0. ? (p.x < 0. ? 3 : 2) : (p.y < 0. ? 1 : 0);
}

// 0:left 1:right 2:top 3:bottom
float getBySide(vec4 st, int side) {
    int sq = int(floor(st.z));
    vec4 v = sq == 5 ? st.yxyx : sq == 6 ? st.xyxy :
             sq < 8 ?  st.yxxy : st.yyxx ;
    return v[side];
}

vec2 getPrevObj(vec2 ip, int kind) {
    vec4 p = _PREV[kind];
    return vec2(getBySide(state(ip+p.xy), getSide(p.xy)),
    			getBySide(state(ip+p.zw), getSide(p.zw)));
}


int getKind(vec2 ip) {
    // to introduce linear elements in the flow, we need to import 2 on x and y
	vec3 rnd = hash23(floor(ip/2.));
    if (rnd.z<.6) {
    	rnd = hash23(ip);
        rnd.z = 0.;
    }
    if (rnd.z<.25) { // curve
        return (fract(dot(ip, vec2(.5))) > .25 ? 0 : 2) + (rnd.y < .5 ? 0:1);      
    } else {	    // linear
        int sq = 8 + (mod(ip.y,2.)>.5 ? 0 : 1) + (mod(ip.x,2.)>.5 ? 0 : 2);
        return rnd.z>.5 ? sq :
        // Transform one element in special curve with inverted directions
            sq == 9 ? 4 : sq == 8 ? 5 : sq == 11 ? 6 : 7;
    } 
}


void mainImage( out vec4 fragColor, in vec2 fragCoord) {
    gTime = 1.*iTime;

    vec2 p = fragCoord, ip = floor(p);

    if (iTime<.5 || iFrame < 10) {
		// Init
        fragColor = vec4(hash23(p).xy, float(getKind(ip)), floor(gTime));
        
    } else {
        vec4 st = state(ip);
        if (gTime > floor(abs(st.w)) + 1.) {
        	int sq = int(round(st.z));
            st.xy = getPrevObj(ip, sq);
            st.w = floor(gTime); // prochain switch
        /*    // switch type
            vec3 rnd = hash23(ip + floor(time));
            if (rnd.x>.96) {                
				// Possible inversion but without animation for the moment
			//	     if (sq == 9) st.z = 4., st.w = -st.w;
            //    else if (sq == 4) st.z = 9., st.w = -st.w;
            //    else
                     if (sq == 0) st.z = 1., st.w = -st.w;
                else if (sq == 1) st.z = 0., st.w = -st.w;                
                
            } */
        }   
        fragColor = st;  
    } 
}