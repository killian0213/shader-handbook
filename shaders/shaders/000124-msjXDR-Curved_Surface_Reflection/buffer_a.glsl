// Buffer A (buffer) — Curved Surface Reflection by NuSan
// https://www.shadertoy.com/view/msjXDR


const float rayangle = 0.3;
const float rayspread = 0.2;
const vec2 raybase = vec2(0.6f,0.0f);

vec4 getPoint(float p) {
    p=clamp(p, 0.0, float(ctrl_points)-1.0);
    return texture(iChannel0, vec2((p+0.5)/float(iResolution.x),1.5/iResolution.y));
}

vec4 GetValue(int idx) {
    return texture(iChannel0, vec2((float(idx)+0.5)/float(iResolution.x),(5.5)/iResolution.y));
}

vec2 GetCtrlPos(int i) {
    return texture(iChannel0, vec2((float(i)+0.5)/float(iResolution.x),(1.5)/iResolution.y)).xy;
}
vec2 GetCurvePos(int i) {
    return texture(iChannel0, vec2(float(i)/float(line_points-1),(0.5)/iResolution.y)).xy;
}

bool curveIntersection(vec2 Start, vec2 End, out vec2 p, out vec2 t) {
    bool res=false;
    float mindist=10000.0;
    int inter=0;
    vec2 prev=vec2(0);
    for(int i=0; i<line_points; ++i) {
        vec2 pos = GetCurvePos(i);
        if(i>0) {
           vec2 cp=vec2(0);
           if (lineIntersection(Start, End, pos, prev, cp)) {
               float ls=lengthSquared(Start, cp);
               if(ls < mindist) {
                   res=true;
                   inter=i;
                   p=cp;
                   //t=pos-prev;
                   mindist=ls;
               }
           }
        }
        prev=pos;
    }
    if(res) {
        vec2 p0 = GetCurvePos(inter-2);
        vec2 p1 = GetCurvePos(inter-1);
        vec2 p2 = GetCurvePos(inter);        
        vec2 p4 = GetCurvePos(inter+1);
        vec2 t1 = (p2-p0);
        vec2 t2 = (p4-p1);
        float perc = NearestPercentSegment(p, p1, p2);
        
        t = mix(t1,t2,perc);
    }
    return res;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 mousePos = (iMouse.xy-iResolution.xy*0.5) / iResolution.y;
    
    vec4 prevColor = texture(iChannel0, fragCoord/iResolution.xy);
    bool init = iFrame<1;

    vec4 col=vec4(0);
    if(fragCoord.y<1.0) {
        // Smoothed Curve
        float prog=((float(fragCoord.x))/float(iResolution.x)) * float(ctrl_points);
        vec4 p1 = getPoint(floor(prog)-1.0);
        vec4 p2 = getPoint(floor(prog)-0.5);        
        vec4 p3 = getPoint(floor(prog)+0.5);
        vec4 p4 = getPoint(floor(prog)+1.0);
        
        vec4 p5 = mix(p2, 2.0*p2-p1, fract(prog));
        vec4 p6 = mix(2.0*p3-p4, p3, fract(prog));
        col = mix(p5, p6, fract(prog));
        //col = mix(p1, p2, fract(prog));        
        
    } else if(fragCoord.y<2.0) {
        // Control Curve
        int idx=int(fragCoord.x)+1;
        float prog=float(idx)/float(ctrl_points);
        bool viewinit=false;
        if(init || viewinit) {
            col.xy=vec2(cos(prog*3.2+1.7)*0.8, sin(prog*3.5+1.7)*0.45+prog*0.5-0.24);
            if(idx==(ctrl_points+1)) {
                col.xy=raybase-vec2(0,rayspread*0.5);
            }
            if(idx==(ctrl_points+2)) {
                col.xy=raybase+vec2(0,rayspread*0.5);
            }
            if(idx==(ctrl_points+3)) {
                col.xy=ButtonSpread+normalize(vec2(1,-1))*rayspread;
            }
        } else {
            col = prevColor;
            int mousePoint = int(GetValue(1).x)+1;
            if(iMouse.w<=0.0) { // not the frame clicked, as there is a one frame latency on the selected point
                if(idx==mousePoint) {
                    col.xy = mousePos;
                }
            }
        }
    } else {    
        // raycast image
        
        vec2 rayp0 = GetCtrlPos(ctrl_points);
        vec2 rayp1 = GetCtrlPos(ctrl_points+1);
        vec2 rayp2 = GetCtrlPos(ctrl_points+2);
        vec2 raypos = (rayp0+rayp1)*.5;
        vec2 rayaxe = (rayp1-rayp0);
        vec2 rayaxen = normalize(rayaxe);
        vec2 raynorm = vec2(-rayaxen.y, rayaxen.x);
        float rayrealspread = length(rayp2-ButtonSpread);
                
        vec2 uv = (fragCoord.xy-iResolution.xy*0.5) / iResolution.y;
        float maxraydir=10.0f;
        vec3 color=vec3(0);
        for(int j=0; j<ray_per_frame; ++j) {
            vec3 rr = rnd3(vec3(uv, fract(iTime*0.1)+float(j)));
            //vec2 rr = hash23(vec3(fragCoord.xy, fract(iTime)));
            float h=(float(j)+rr.x)/float(ray_per_frame);
            float v=rr.y;
            //float h=rr.x;
            //float v=(float(j)+rr.y)/float(ray_per_frame);
            vec2 raystart = raypos + rayaxe*(h-0.5);
            vec3 addcol = max(vec3(1.-h*2.,1.-abs(h-.5)*2.,h*2.-1.),0.);
            vec2 raydir = normalize(raynorm + rayaxen * (rayrealspread*(v-0.5)));
            //vec2 raydir = -normalize(rayp2-raystart);
            raystart-=raydir;
            for(int i=0; i<maxReflect; ++i) {

                vec2 p;
                vec2 t;
                if (!curveIntersection(raystart, raystart + raydir*maxraydir, p, t))
                {
                    float dist = distanceToSegment(uv, raystart, raystart + raydir*maxraydir);
                    color += addcol*clamp(1.-dist/rayblur,0.,1.); 
                    break;

                }

                vec2 n=normalize(vec2(t.y, -t.x));

                float dist = distanceToSegment(uv, raystart, p);
                color += addcol*clamp(1.-dist/rayblur,0.,1.); 
                raystart=p-raydir*0.01;
                raydir=reflect(raydir, n);
            }
        }
        color *= luminosity/float(ray_per_frame);
        
        vec3 histo = prevColor.xyz;
        // spatial blur
        if(spatialBlur) {
            float blurdist=rnd3(vec3(uv, fract(iTime)+7.3)).x*2.0;
            histo += texture(iChannel0, (fragCoord+vec2(blurdist,0))/iResolution.xy).xyz;
            histo += texture(iChannel0, (fragCoord-vec2(blurdist,0))/iResolution.xy).xyz;
            histo += texture(iChannel0, (fragCoord+vec2(0,blurdist))/iResolution.xy).xyz;
            histo += texture(iChannel0, (fragCoord-vec2(0,blurdist))/iResolution.xy).xyz;
            histo *= 0.2;
        }
        
        col.xyz = mix(color, histo, timeblur);
    }
    
    if(int(fragCoord.x) == 1) {
        if(int(fragCoord.y) == 5 ) {
            col = prevColor;
            if(iMouse.w>0.0) {
                vec2 mousePosClick = (iMouse.zw-iResolution.xy*0.5) / iResolution.y;

                float nearestmousedist=100.0;
                vec2 nearmousepoint=vec2(0);
                int nearmouseIndex=-1;
                for(int i=0; i<ctrl_points+ButtonNumber; ++i) {
                    vec2 pos = texture(iChannel0, vec2((float(i)+0.5)/float(iResolution.x),(1.5)/iResolution.y)).xy;
                    float distmouse=length(mousePos-pos);
                    if(distmouse<nearestmousedist) {
                        nearestmousedist=distmouse;
                        nearmousepoint=pos;
                        nearmouseIndex=i;
                    }
                }
                if(nearestmousedist<0.05) {
                    col.x=float(nearmouseIndex);
                } else {
                    col.x=-1.;
                }
            }
            if(init) col.x=-1.0;
        }
    }
    
    fragColor = col;
}