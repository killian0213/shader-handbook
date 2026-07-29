// Buffer B (buffer) — Watercolor Pad by ivansafrin
// https://www.shadertoy.com/view/wdyGWm

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
 	vec2 uv = fragCoord/iResolution.xy;   

	vec4 lastFrameData = texture(iChannel0, vec2(0.5, 0.0));
    float brushStrength = lastFrameData.z;
    vec4 col = texture(iChannel0, uv); 
    
    if(fragCoord.y < iResolution.y-10.0  && fragCoord.y > 5.0) {
        vec2 w = 1.0/iResolution.xy;  
        vec4 tr = texture(iChannel0, uv + vec2(w.x , 0), 0.0);
        vec4 tl = texture(iChannel0, uv - vec2(w.x , 0), 0.0);
        vec4 tu = texture(iChannel0, uv + vec2(0 , w.y), 0.0);
        vec4 td = texture(iChannel0, uv - vec2(0 , w.y), 0.0);

        const float K = 0.2;
        const float v = 0.55;

        vec2 laplacian = tu.xy + td.xy + tr.xy + tl.xy - 4.0*col.xy;
        vec2 viscForce = vec2(v)*laplacian;
        col = texture(iChannel0, uv - dt*col.xy*w, 0.); 
    }
        
	vec2 oldBrushPos = lastFrameData.xy;
    
	vec2 dirVec = iMouse.xy -  oldBrushPos;    
    
    float dissolveStrength = noise(fragCoord) * 100.0;
    float dissolveAngle = noise(fragCoord) * 6.283 * 2.0;
    
    dirVec += vec2(cos(dissolveAngle), sin(dissolveAngle)) * dissolveStrength;
    
    vec4 brushColor = vec4(dirVec.x, dirVec.y, 0.0, 0.0);
	float brushStregthRamp = 0.0;
    if(brushStrength > 0.01) {
        brushStregthRamp = 1.0;
    }
   
    for(int i=0; i < 20; i++) {
        vec2 mPos = mix(iMouse.xy, oldBrushPos, float(i)/20.0);
        float bc = 1.0-clamp(distance(fragCoord, mPos) / BRUSH_SIZE / brushStregthRamp / 2.0, 0.0, 1.0);
       	bc *= smoothstep(0.1, 1.0, (noise(vec2(brushStrength * 20.0, 0.0) + (fragCoord-mPos)/2.0)+0.0)/5.0) * 10.0;                       
      	col.xy = mix(col.xy, brushColor.xy, bc);  
    }

    col.xy *= 0.95;
    brushStrength -= distance(iMouse.xy, oldBrushPos) / STROKE_LENGTH;

	if(iMouse.z != lastFrameData.w) {
        if(iMouse.z > 0.0) {
			brushStrength = 1.0;
        } else {
			brushStrength = 0.0;
        }
    }
    brushStrength = clamp(brushStrength, 0.0, 1.0);
      
    vec4 newAppData = vec4(iMouse.x, iMouse.y, brushStrength, iMouse.z);   
    col = mix(newAppData, col, smoothstep(0.99, 1.0, fragCoord.y));
    
    fragColor = col;
}