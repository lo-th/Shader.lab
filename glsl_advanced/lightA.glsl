
// ------------------ channel define
// 0_# bufferFULL_lightA #_0
// 1_# bufferFULL_lightB #_1
// ------------------

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 linePointDist(vec2 lb, vec2 le, vec2 p) {
    float len = length(lb-le);
    if (len==0.0) {
        return (lb-p);
    }
    vec2 dir = normalize(le-lb);
    float t = max(0.0, min(len, dot(p - lb, dir)));
    vec2 proj = lb+t*dir;
    return proj-p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 mouse =texture2D(iChannel1, vec2(0.0));
    float mOffset=2.0;
    mOffset+=mouse.w*40.0;
    vec3 mousePrev = texture2D(iChannel1, vec2(mOffset/iResolution.x)).rgb;
    
    vec4 c = vec4(0.0);
    
    if (mouse.z+mousePrev.z>=2.0) {
        float aspect = iResolution.x/iResolution.y;
        vec2 distanceVec = linePointDist(mouse.xy,mousePrev.xy, uv);
        distanceVec.y/=aspect;
        float dist = length(distanceVec);
        float str = 16.0/(dist*4500.0+1.0)/(dist*200.0+length(mouse.rg-mousePrev.rg)*20.0+10.0);
        c.rgb = hsv2rgb(vec3(iGlobalTime/76.0,1.0,str));
 
    }
    
    vec3 old = texture2D(iChannel0, uv).rgb;
    //old =rgb2hsv(old.rgb);
                 //old = hsv2rgb(old.rgb+vec3(0.001,0.0,0.0));
    
    fragColor =  old.rgbr*0.9992 + c;
}