// Buffer A (buffer) — Pixie dust by rory618
// https://www.shadertoy.com/view/wllcR7

getters}

//Length of the shared prefix of the morton codes of a pair of particles.
//If the codes are the same, then also count shared bits of the list index which will never be the same.
//Return -1 if the j particle is outside the range of all particles
int plen(int i, int j){
    if(j<0||j>=16384) return -1;
    int mi = ZOrder(sampleIndexStage(i, sortedStage).xyz);
    int mj = ZOrder(sampleIndexStage(j, sortedStage).xyz);
    if(mi!=mj){
        int x = mi^mj;
        float f = log2(float(x)+0.5);
        return 32 - int(f);
    } else {
        int x = i^j;
        float f = log2(float(x)+0.5);
        return 64 - int(f);
    }
}
        
void mainImage( out vec4 O, in vec2 I )
{
    //index always indicates either the left or right end of the range of particle indecies it contains
    int i = int(I.x) + int(I.y)*128;
    
    //Check direction if this node
    int d = sign(plen(i,i+1)-plen(i,i-1));
    
    //Scan to find the other end of this node, so that all the nodes share a prefix at least 
    //as long as the shared prefix between the first two elements
    //Scan away to find an upper bound
    int dmin = plen(i,i-d);
    int lmax = 2;
    for(int k = 0; k<16; k++){
        if (plen(i, i + lmax*d) <= dmin)
            break;
        lmax *= 2;
    }
    
    //Scan back with a binary search
    int l = 0;
    int t = lmax/2;
    for(int k = 0; k<16; k++){
        if (plen(i, i + (l+t)*d) > dmin){
            l = l+t;
        }
        if(t==1) break;
        t /= 2;
        
    }
    //Compute the other end of the range of particle indecies this node contains
    int j = i + l * d;

    //Find the split index where the nodes on one side share a different longes prefix from the other
    int dnode = plen(i, j);
    int s = 0;
    float ft = float(l)/2.;
    for(int k = 0; k<16; k++){
        t = int(max(1.,ceil(ft)));
        if(plen(i, i + (s + t) * d ) > dnode){
            s += t;
        }
        ft /= 2.;
    }
    //Compute split index
    int y = i + s * d + min(d,0);
    
    //Compute the child node indecies using the split index y and two ends i and j
    int childLeft;
    int childRight;
    if (min(i,j) == y) {
        childLeft = y + 16384;
    } else {
        childLeft = y;
    }
    if (max(i,j) == y+1){
        childRight = (y+1) + 16384;
    } else {
        childRight = y+1;
    }
    
    //Safe the left index and right index (just for testing), as well as left and right child nodes
    O = vec4(min(i,j),max(i,j),childLeft,childRight);
    
}