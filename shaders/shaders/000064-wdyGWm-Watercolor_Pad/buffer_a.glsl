// Buffer A (buffer) — Watercolor Pad by ivansafrin
// https://www.shadertoy.com/view/wdyGWm

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
 	vec2 uv = fragCoord/iResolution.xy;   

	vec4 lastFrameData = texture(iChannel0, vec2(0.5, 1.0));
    float brushStrength = lastFrameData.z;
    
    vec4 lastBrushData = texture(iChannel0, vec2(0.5, 0.0));
    float brushHue = lastBrushData.x;
    float brushSaturation = lastBrushData.y;
    
    vec4 col = texture(iChannel0, uv); 
    
    vec4 dirCol = texture(iChannel1, uv); 
    if(fragCoord.y < iResolution.y-10.0 && fragCoord.y > 5.0) {
        vec2 w = 1.0/iResolution.xy;  
        vec4 tr = texture(iChannel1, uv + vec2(w.x , 0), 0.0);
        vec4 tl = texture(iChannel1, uv - vec2(w.x , 0), 0.0);
        vec4 tu = texture(iChannel1, uv + vec2(0 , w.y), 0.0);
        vec4 td = texture(iChannel1, uv - vec2(0 , w.y), 0.0);

        const float K = 0.2;
        const float v = 0.55;

        vec2 laplacian = tu.xy + td.xy + tr.xy + tl.xy - 4.0*dirCol.xy;
        vec2 viscForce = vec2(v)*laplacian;
		col = texture(iChannel0, uv - dt*dirCol.xy*w, 0.);   
    }
        
	vec2 oldBrushPos = lastFrameData.xy;
    
	vec2 dirVec = iMouse.xy -  oldBrushPos;    
	vec4 brushColor = vec4(hsv2rgb(vec3(brushHue, (0.1 + brushStrength * brushSaturation), 0.875)), 0.0);
        
    float brushStregthRamp = 0.0;
    if(brushStrength > 0.01) {
        brushStregthRamp = 1.0;
    }
    
    for(int i=0; i < 20; i++) {
        vec2 mPos = mix(iMouse.xy, oldBrushPos, float(i)/20.0);
    	float d = 1.0 - smoothstep(0.0, 1.0, distance(fragCoord, mPos) / BRUSH_SIZE / brushStregthRamp);       
        d *= smoothstep(0.2, 1.0, (noise(fragCoord-mPos)+0.75)/5.0) * 10.0;               
        float bd = 1.0 - smoothstep(0.0, 1.0, distance(fragCoord, mPos) / BRUSH_SIZE / brushStregthRamp / 1.5);
        bd *= smoothstep(0.1, 1.0, (noise(vec2(brushStrength * 20.0, 0.0) + (fragCoord-mPos)/2.0)+0.0)/5.0) * 10.0;
    	col.xyz = mix(col.xyz, col.xyz * brushColor.xyz, (d + bd) * 0.05);
    }

    brushStrength -= distance(iMouse.xy, oldBrushPos) / STROKE_LENGTH;

	if(iMouse.z != lastFrameData.w) {
        if(iMouse.z > 0.0) {
           	 	if(iMouse.y > iResolution.y-20.0) {
                    brushHue = iMouse.x/iResolution.x; 
                } else {
               	 brushStrength = 1.0;
                 brushSaturation = 0.3 + rand(vec2(iTime, 0.0)) * 0.5;
                }
        } else {
                brushStrength = 0.0;
        }
    }
    brushStrength = clamp(brushStrength, 0.0, 1.0);
    
  
    vec4 newAppData = vec4(iMouse.x, iMouse.y, brushStrength, iMouse.z);   
    vec4 brushData = vec4(brushHue, brushSaturation, 0.0, 0.0); 
    col = mix(col, newAppData, smoothstep(iResolution.y-1.01, iResolution.y, fragCoord.y));
    col = mix(brushData, col, smoothstep(0.99, 1.0, fragCoord.y));
    
    fragColor = col;
    if(iFrame < 2) {
		fragColor = vec4(1.0);
    }
}