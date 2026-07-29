// Cube A (cubemap) — Pixie dust by rory618
// https://www.shadertoy.com/view/wllcR7

getters}

//Generate random particles each frame, and use a pipelined bitonic sorting network to arrange them in a list
//so that they are in ascending order along a z curve covering uv space, saving the xy coordinate at each step.

//Get the partner to be compared with for a bitonic sort at a given stage
//See https://en.wikipedia.org/wiki/Bitonic_sorter#Alternative_representation
int getPartner(int x, int s){
    float j = floor(sqrt(float(2*s)+1.25)-0.5);		//Major stage
    float n = floor(float(s) - 0.5*(j*j+j) + 0.5);	//Minor stage
    float b = floor(exp2(j-n+1.)+0.5);				//Block size
    float bot = floor(float(x)/b)*b;				//Bottom index in block 
    float top = bot + b - 1.;						//Top index in block
    if(n<0.5){										//Swap with opposite index in block
        return int(top - (float(x)-bot) + 0.5);
    }else{											//Swap with index a constant distance away in block
        if(float(x)-bot < b/2.-0.5){
            return int(float(x) + b/2. + 0.5);
        }else{
            return int(float(x) - b/2. + 0.5);
        }
    }
}



//Combine two bounding boxes, return null bbox if one of the bboxes is also null
BBox mergeBBox(BBox A, BBox B){
    if((A.a==vec3(0) && A.b==vec3(0)) || (B.a==vec3(0) && B.b==vec3(0)) ){
        return BBox(vec3(0),vec3(0));
    }
    return BBox(min(A.a,B.a), max(A.b,B.b) );
}

void mainCubemap( out vec4 O, in vec2 I, in vec3 rayOri, in vec3 rayDir )
{
    
    ivec3 XYFace = RayDirToXYFace(rayDir);
    ivec2 XYTall = ivec2(XYFace.x, XYFace.y + 1024*XYFace.z);
    int index = XYTall.x*16 + (XYTall.y%16);
    if(XYTall.y < 16){
        vec4 coord = texelFetch(iChannel2, ivec2(index/128,index%128),0);
        
        O = (coord);
    } else  {
        int stage = XYTall.y/16;
        int sortStage = stage - 1;
        if(stage<106){
        	//Execute the sorting network swaps
            int partner = getPartner(index,sortStage);
            vec4 A = sampleIndexStage(index, stage-1);
            vec4 B = sampleIndexStage(partner, stage-1);
            int zA = ZOrder(A.xyz);
            int zB = ZOrder(B.xyz);
            if(index > partner){
                if(zA>zB){
                    O=A;
                } else {
                    O=B;
                }
            } else {
                if(zA>zB){
                    O=B;
                } else {
                    O=A;
                }
            }
        } else if(stage==BVHStage0){
            //Fetch the BVH graph from buf A
            vec4 A = texelFetch(iChannel1, ivec2(index%128, index/128), 0);
            int childLeft = int(A.z);
            int childRight = int(A.w);
            //Pack a 15 bit integer into a pair of cubemap channels
            O = vec4(childLeft%128,childLeft/128,childRight%128,childRight/128);
        } else if(stage>=BBoxStage0){
            //Compute the bounding boxes from leaf nodes upwards towards the root node
            int BBoxStage = (stage - BBoxStage0)/2;
            int substage = (stage - BBoxStage0)%2;
            BBox bbox = BBox(sampleIndexStage(index, BBoxStage0+BBoxStage*2-2).xyz,
                             sampleIndexStage(index, BBoxStage0+BBoxStage*2-1).xyz);
            if((bbox.a==vec3(0) && bbox.b==vec3(0)) || BBoxStage==0){
                vec4 node = sampleIndexStage(index, BBoxStage+BVHStage0);

                int childLeft = int(node.x) + int(node.y)*128;
                int childRight = int(node.z) + int(node.w)*128;

                BBox bboxLeft = BBox(vec3(0),vec3(0));
                BBox bboxRight =BBox(vec3(0),vec3(0));
                
                if(BBoxStage!=0){
                    
                     bboxLeft = BBox(sampleIndexStage(childLeft, BBoxStage0+BBoxStage*2-2).xyz,
                                     sampleIndexStage(childLeft, BBoxStage0+BBoxStage*2-1).xyz);
                	bboxRight = BBox(sampleIndexStage(childRight, BBoxStage0+BBoxStage*2-2).xyz,
                                     sampleIndexStage(childRight, BBoxStage0+BBoxStage*2-1).xyz);
                }

                //Particle 'nodes' are indexed starting from 16384. Make a 1x1 bounding box if its a particle
                if(childLeft>=16384){
                    childLeft -= 16384;
                    vec4 data = sampleIndexStage(childLeft, sortedStage+BBoxStage+1);
                    bboxLeft = leafToBBox(data);
                }
                if(childRight>=16384){
                    childRight -= 16384;
                    vec4 data = sampleIndexStage(childRight, sortedStage+BBoxStage+1);
                    bboxRight = leafToBBox(data);
                }
                bbox = mergeBBox(bboxLeft, bboxRight);
            }
            O.xyz = substage==0?bbox.a:bbox.b;
        } else {
            //Keep shifting the result down so that they are avalible at each point in the pipeline
            O = sampleIndexStage(index, stage-1);
        }
        
    }
    
    
}
    
