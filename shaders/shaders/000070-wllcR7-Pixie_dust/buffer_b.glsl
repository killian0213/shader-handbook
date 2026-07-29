// Buffer B (buffer) — Pixie dust by rory618
// https://www.shadertoy.com/view/wllcR7


getters}

const float eps = 1e-1;

vec4 DFS(vec3 p, vec3 rd){
    int count = 0;
    int[] stack_data = int[] (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
    float[] stack_d = float[] (0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.);
    int stack_pos = -1;
    int v = 0;
    float fd = length(rd);
    
    #define pop() stack_data[stack_pos--]
    #define push(data)  stack_data[++stack_pos] = data
    
    int node = 0;
    BBox bbox = BBox(sampleIndexStage(node, BBoxStageFinal+BBoxStages-2).xyz,
                     sampleIndexStage(node, BBoxStageFinal+BBoxStages-3).xyz);
    float d = 1e8;
    vec3 c = vec3(0);
    count++;
    for(int k = 0; k < 3200; k++){
        vec4 node_data = sampleIndexStage(node, BBoxStageFinal-BBoxStages+1);
        
        
        int childLeft = int(node_data.x) + int(node_data.y)*128;
        int childRight = int(node_data.z) + int(node_data.w)*128;
        bool leafLeft = childLeft >= 16384;
        bool leafRight = childRight >= 16384;
        
        
        vec4 pDataLeft = sampleIndexStage(childLeft & 16383, leafLeft?sortedStage+BBoxStages-1:BBoxStageFinal+BBoxStages-2);
        vec4 pDataRight = sampleIndexStage(childRight & 16383, leafRight?sortedStage+BBoxStages-1:BBoxStageFinal+BBoxStages-2);
        vec4 pDataLeftB = sampleIndexStage(childLeft & 16383, leafLeft?sortedStage+BBoxStages-1:BBoxStageFinal+BBoxStages-3);
        vec4 pDataRightB = sampleIndexStage(childRight & 16383, leafRight?sortedStage+BBoxStages-1:BBoxStageFinal+BBoxStages-3);
        
        BBox bboxLeft = BBox(pDataLeft.xyz,pDataLeftB.xyz);
        BBox bboxRight = BBox(pDataRight.xyz,pDataRightB.xyz);
        if(leafLeft){ bboxLeft = leafToBBox(pDataLeft); }
        if(leafRight){ bboxRight = leafToBBox(pDataRight); }
        
        
        bool validLeft = BBoxIntersectsCone(bboxLeft, p+rd/2., rd, 0.05);
        bool validRight = BBoxIntersectsCone(bboxRight, p+rd/2., rd, 0.05);
        
        float dleft = length((bboxLeft.a+bboxLeft.b)/2.-p);
        float dright = length((bboxRight.a+bboxRight.b)/2.-p);
                
        count += int(validLeft);
        count += int(validRight);
        validLeft = validLeft && (!leafLeft);
        validRight = validRight && (!leafRight);
        
        if(leafLeft){
            float l = max(.03,abs(length(p-pDataLeft.xyz)-fd));
            
            c += .0003/l/l*float( PointIntersectsCone(pDataLeft.xyz, p+rd, rd, 0.05) || PointIntersectsCone(pDataLeft.xyz, p, rd, 2./R.x)) *
                 (.5+.5*cos(4e-1*vec3(2,3,4)*float(pDataLeft.w)));
            
        } else {
            float a = acos(dot(normalize(rd), normalize((bboxLeft.a+bboxLeft.b)/2.-p)));
            c += 0.003*max(0.,1.-.75*dleft*sin(a)/length((bboxLeft.a-bboxLeft.b)/2.));
        }
        if(leafRight){
            float l = max(.03,abs(length(p-pDataRight.xyz)-fd));
            c += .0003/l/l*float( PointIntersectsCone(pDataRight.xyz, p+rd, rd, 0.05) || PointIntersectsCone(pDataLeft.xyz, p, rd, 2./R.x)) *
                 (.5+.5*cos(4e-1*vec3(2,3,4)*float(pDataRight.w)));
            
        } else {
            float a = acos(dot(normalize(rd), normalize((bboxRight.a+bboxRight.b)/2.-p)));
            c += 0.003*max(0.,1.-.75*dright*sin(a)/length((bboxRight.a-bboxRight.b)/2.));
        }
        
        
        
        if(validRight){
            if(validLeft){
                //if(dleft<dright){
                    push(childRight);
                    node = childLeft;
                //} else {
                //    push(childLeft);
                //    node = childRight;
                //}
            } else {
                //Go right
                node = childRight;
            }
        } else {
            if(validLeft){
                //Go left
                node = childLeft;
            } else {
                //Go up stack
                if(stack_pos >= 0){
                    node = pop();
                } else {
                    return vec4(c,0);
                }
            }
        }
    }
        
    return vec4(c,1);
}



void mainImage( out vec4 O, in vec2 I )
{   
    //Dot Dot Dot while pipeline fills up
    if(iFrame<BVHStage0){
        float fracDone = float(iFrame) / float(BVHStage0);
        vec2 c = mod(I,R.xy/vec2(3,1));
        O = vec4(min(1.,R.x/30.-length(c-R.xy/vec2(6,2))));
        O *= .25+.75*vec4(I.x/R.x<floor(fracDone*4.)/3.);
    } else {
        vec3 r0 = vec3((I-R.xy/2.)/R.y,1);
        vec3 rd = vec3(0,0,-1);
        
        float p = (iMouse.y/R.y*2.-1.)*3.14/2.;
        float y = (iMouse.x/R.x*2.-1.)*3.14 + iTime/14.;
        
        r0.yz = mat2(r0.yz,-r0.z,r0.y) * vec2(cos(p), sin(p));
        rd.yz = mat2(rd.yz,-rd.z,rd.y) * vec2(cos(p), sin(p));
        
        r0.xz = mat2(r0.xz,-r0.z,r0.x) * vec2(cos(y), sin(y));
        rd.xz = mat2(rd.xz,-rd.z,rd.x) * vec2(cos(y), sin(y));
        
        r0 += .5;
        rd /= 1.0;
        O = DFS(r0,rd)*2.;
        O = log(1.+O*6.)/3.;
    }
}