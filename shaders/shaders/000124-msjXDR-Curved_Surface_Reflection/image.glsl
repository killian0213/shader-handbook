// Image (image) — Curved Surface Reflection by NuSan
// https://www.shadertoy.com/view/msjXDR

// Test reflection of rays on curved surface
// Click and drag on the control points to change the surface
// Top-left knob control the "spread" of the emitted light
// Other settings are in the "Common" tab

vec2 GetCurvePos(int i) {
    return texture(iChannel0, vec2(float(i)/float(line_points-1),(0.5)/iResolution.y)).xy;
}

vec2 GetCtrlPos(int i) {
    return texture(iChannel0, vec2((float(i)+0.5)/float(iResolution.x),(1.5)/iResolution.y)).xy;
}

vec4 GetValue(int idx) {
    return texture(iChannel0, vec2((float(idx)+0.5)/float(iResolution.x),(5.5)/iResolution.y));
}

vec4 GetUIValue(int idx) {
    return texture(iChannel0, vec2((float(idx)+0.5)/float(iResolution.x),(1.5)/iResolution.y));
}

vec4 CurveAABB;
vec3 CurveBounds;
void FindCurveBounds() {
    CurveAABB=vec4(10000,10000,-10000,-10000);
    for(int i=0; i<line_points; ++i) {
        vec2 pos = GetCurvePos(i);
        CurveAABB.xy = min(CurveAABB.xy, pos);
        CurveAABB.zw = max(CurveAABB.zw, pos);
    }
    vec2 center=(CurveAABB.xy+CurveAABB.zw)*0.5;
    CurveBounds=vec3(center, length(center-CurveAABB.xy));
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
                   t=pos-prev;
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
	vec2 uv = (fragCoord.xy-iResolution.xy*0.5) / iResolution.y;
    
	vec3 color = vec3(0);
    
    color = texture(iChannel0, fragCoord.xy/iResolution.xy).xyz;
    if(fragCoord.y<2.0) color=vec3(0);
    
    // tonemapping
    color = smoothstep(0.,1.,color);
    color = pow(color, vec3(0.4545));
    
    vec2 rayp0 = GetCtrlPos(ctrl_points);
    vec2 rayp1 = GetCtrlPos(ctrl_points+1);
    vec2 rayp2 = GetCtrlPos(ctrl_points+2);
    vec2 raymid = (rayp0+rayp1)*0.5;

    if(DrawUI) {
        /*
        FindCurveBounds();
        vec2 diffbound=abs(uv-CurveBounds.xy)-(CurveAABB.zw-CurveAABB.xy)*0.5;
        color += vec3(0.5,0,0.5)*smoothstep(0.005,0.002,abs(max(diffbound.x, diffbound.y))); 
        color += vec3(0.5,0.5,0.0)*smoothstep(0.005,0.002,abs(length(uv-CurveBounds.xy)-CurveBounds.z)); 
        */
        

        color += vec3(0.5)*smoothstep(0.01,0.,distanceToSegment(uv, rayp0, rayp1));
        color += vec3(0.5)*smoothstep(0.01,0.,distanceToSegment(uv, ButtonSpread, rayp2));

        vec2 mousePos = (iMouse.xy-iResolution.xy*0.5) / iResolution.y;
        vec2 mousePosClick = (iMouse.zw-iResolution.xy*0.5) / iResolution.y;

        // Full Curve
        vec2 prev=vec2(0);
        float curvenear=10000.0;
        for(int i=0; i<line_points; ++i) {
            vec2 pos = GetCurvePos(i);
            if(i>0) {
                curvenear=min(curvenear, distanceToSegmentSquared(uv, prev, pos));
            }
            //color += vec3(1,0,0)*smoothstep(0.01,0.009,length(uv-pos));
            prev=pos;
        }
        color += vec3(.7)*smoothstep(0.005,0.003,sqrt(curvenear)); 

        // Control Points
        prev=vec2(0);        
        float ctrlnear=10000.0;
        float psize = 0.015;
        for(int i=0; i<ctrl_points; ++i) {
            vec2 pos = GetCtrlPos(i);
            if(i>0) {
                ctrlnear=min(ctrlnear, distanceToSegmentSquared(uv, prev, pos));               
            }
            ctrlnear=min(ctrlnear, max(abs(dot(uv-pos,uv-pos)-psize*psize*2.)-psize*psize*0.1,0.));
            prev=pos;
        }
        
        
        int mousePoint = int(GetValue(1).x);
        float nearestmousedist=100.0;
        vec2 nearmousepoint=vec2(0);
        for(int i=0; i < ctrl_points + ButtonNumber; ++i) {
            vec2 pos = GetCtrlPos(i);
            ctrlnear=min(ctrlnear, max(abs(dot(uv-pos,uv-pos)-psize*psize*2.)-psize*psize*0.1,0.));
            float distmouse=length(mousePos-pos);
            if(i == mousePoint) {
                nearestmousedist=distmouse;
                nearmousepoint=pos;
            }
            prev=pos;
        }
        
        ctrlnear=sqrt(ctrlnear);        
        
        float bdist=length(ButtonSpread-uv);
        //ctrlnear=min(ctrlnear,3.* min(abs(bdist-.01), abs(bdist-length(rayp2-ButtonSpread))));
        ctrlnear=min(ctrlnear,3.* abs(bdist-.01));
        
        color += vec3(0.6)*smoothstep(psize,psize*0.2,ctrlnear); 
        if(mousePoint>=0) {
            color += vec3(0.5)*smoothstep(psize,psize*0.9,length(uv-nearmousepoint));
        }    
    }
        
    if(DrawTestRay) {
        
        vec2 rayaxe = (rayp1-rayp0);
        vec2 rayaxen = normalize(rayaxe);
        vec2 raynorm = vec2(-rayaxen.y, rayaxen.x);
        float rayrealspread = length(rayp2-ButtonSpread);
        
        vec2 raystart = raymid - rayaxen*0.0;
        vec2 raydir = normalize(raynorm + rayaxen * (rayrealspread*(sin(iTime)*0.5)));
        float maxraydir=10.0f;

        for(int i=0; i<maxReflect; ++i) {

            vec2 p;
            vec2 t;
            if (!curveIntersection(raystart, raystart + raydir*maxraydir, p, t))
            {
                color += vec3(0,1,0) * smoothstep(0.005,0.002,distanceToSegment(uv, raystart, raystart + raydir*maxraydir)); 
                break;

            }

            vec2 n=normalize(vec2(t.y, -t.x));

            color += vec3(0,1,0) * smoothstep(0.005,0.002,distanceToSegment(uv, raystart, p)); 
            if (length(p - uv) < 0.02)
            {
                color = vec3(0,0,1);
            }

            color += vec3(0,1,1) * smoothstep(0.005,0.002,distanceToSegment(uv, p, p+n*0.1)); 


            raystart=p-raydir*0.01;

            raydir=reflect(raydir, n);

        }
    }
    
    float h=fragCoord.x/iResolution.x;
    //if(fragCoord.y<100.0) color=max(vec3(1.-h*2.,1.-abs(h-.5)*2.,h*2.-1.),0.);
                
    fragColor = vec4(color, 1.0);
}