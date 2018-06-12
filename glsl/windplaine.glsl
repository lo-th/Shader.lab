// ------------------ channel define
// 0_# tex10 #_0
// 2_# noise #_2
// ------------------


// https://www.shadertoy.com/view/ltXXRM


mat3 rotx(float a) { mat3 rot; rot[0] = vec3(1.0, 0.0, 0.0); rot[1] = vec3(0.0, cos(a), -sin(a)); rot[2] = vec3(0.0, sin(a), cos(a)); return rot; }
mat3 roty(float a) { mat3 rot; rot[0] = vec3(cos(a), 0.0, sin(a)); rot[1] = vec3(0.0, 1.0, 0.0); rot[2] = vec3(-sin(a), 0.0, cos(a)); return rot; }
mat3 rotz(float a) { mat3 rot; rot[0] = vec3(cos(a), -sin(a), 0.0); rot[1] = vec3(sin(a), cos(a), 0.0); rot[2] = vec3(0.0, 0.0, 1.0); return rot; }

// Height of grass
const float H = 0.2;


vec4 flter(sampler2D sampler, vec2 uv, float f)
{
    vec4 c = texture(sampler, uv);
    c = clamp(c - f, 0.0, 1.0);
    c /= f;
    return c;
}

float flter(float f, float a)
{
    f = clamp(f - a, 0.0, 1.0);
    return f / (1.0 - a);
}


// clouds fbm 
float fbm(vec2 uv)
{
    float f = 0.0;
    
    f += (texture(iChannel0, uv).r - 0.5) * 0.5;
    f += (texture(iChannel0, uv * 2.0).r - 0.5) * 0.25;
    f += (texture(iChannel0, uv * 4.0).r - 0.5) * 0.125;
    f += (texture(iChannel0, uv * 8.0).r - 0.5) * 0.125 * 0.5;
    f += (texture(iChannel0, uv * 32.0).r - 0.5) * 0.125 * 0.5 * 0.5;
    
    return f + 0.5;
}


struct AA
{
    float a;
    float b;
    float c;
    float d;
    float e;
    float f;
    float g;
    float h;
};

    
void rotate(inout AA aa, float v)
{
    aa.h = aa.g;
    aa.g = aa.f;
    aa.f = aa.e;
    aa.e = aa.d;
    aa.d = aa.c;
    aa.c = aa.b;
    aa.b = aa.a;
    aa.a = v;
}

float avg(in AA aa)
{
    float f1 = 0.7;
    float f2 = 0.5;
    float f3 = 0.8;

    float a = aa.a + aa.b;
    float b = aa.c + aa.d;
    float c = aa.e + aa.f;
    float d = aa.g + aa.h;
    
    float a1 = mix(a, b, 1.0 - f1);
    float a2 = mix(c, d, 1.0 - f2);
    
    float a3 = mix(a1, a2, 1.0 - f3);
    
    return a3 * 0.5;
}

vec2 rot2d(in vec3 p, float angle)
{
    float x = p.x * cos(angle) + p.y * -sin(angle);
    float y = p.x * sin(angle) + p.y * cos(angle);
    return vec2(x, y);
}


vec4 strawcol = vec4(0.8);
vec3 warpedRp = vec3(0.0);


float map(in vec3 rp, inout AA aa, bool useAA)
{
    float gt = iTime * 0.9;
    float t = sin(gt + rp.x * 1.2) * 0.5;
    t += sin(gt + rp.z * 1.4) * 0.5;
    t *= 0.5;
    
    vec2 off = rot2d(vec3(0.0, 5.0, 0.0), rp.y * 20.0* t);
    rp.x -= off.x * 0.04;
    rp.y -= off.y * 0.005;
    vec2 uv = rp.xz * 6.5;
    
    
    // path
    float s1 = 1.0 - smoothstep(rp.x + sin(rp.z * 3.0) * 0.1 + sin(rp.z * 5.0) * 0.12, -0.4, 0.);
    float s2 = 1.0 - smoothstep(rp.x - sin(rp.z * 4.4) * 0.1 + sin(rp.z * 14.0) * 0.04, 0.4, -0.);
    rp.y += (s1 + s2) * 0.03;
    
    vec4 col = texture(iChannel0, uv, -100.0);
    float h = col.r;
    
    if(useAA)
    {
        rotate(aa, h);
        h = avg(aa);
    }
    
    h *= mix(texture(iChannel0, uv * 0.025).r + 0., 1.0, 0.7);
    h *= H;
    warpedRp = rp;
    return rp.y - h;
}


vec3 grad (in vec3 rp, in AA aa)
{
    
    vec2 off = vec2(0.03, 0.0);
    vec3 grad = vec3(map(rp + off.xyy, aa, false) - map(rp - off.xyy, aa, false),
                     off.x,
                     map(rp + off.yyx, aa, false) - map(rp - off.yyx, aa, false));
    return normalize(grad);
}

vec3 light = normalize(vec3(.0, 2., .0));

float shadow(in vec3 rp)
{
    float d = 0.05;
    AA aa;
    float h = map(rp + normalize(vec3(0.0, .0, 1.0)) * d, aa, false);
    return clamp(h / d, 0.0, 1.0);
}


vec4 clouds(in vec3 rp, in vec3 rd)
{
    vec4 c = vec4(0.0);
    float gt = iTime * 0.5;
    rp += rd * (1.0 / abs(rd.y));
    vec2 uv = rp.xz;
    uv.y += gt;
    float f1 = fbm(uv * 0.009);
    f1 = flter(f1, .3);

    uv = rp.xz;
    uv.y += gt * 1.5;
    uv.x += gt * 0.5;
    
    float f2 = fbm(uv * 0.015);
    f2 = flter(f2, 0.5);
    float f = mix(f1, f2, .2);
    f = clamp(f * 1.2, 0.0, 1.0);
    return vec4(f);
}



vec4 grasscol = vec4(0.5, 0.5, 0.3, 0.0) * 2.;



bool trace(inout vec3 rp, in vec3 rd, inout vec4 col)
{
    if(rd.y > 0.0)
    {
        return false;
    }
    
    vec3 ro = rp;
    float ydiff = rp.y - H;
    float l = 0.0;
    rp += rd * (ydiff / abs (rd.y));
    AA aa;
    for (int i = 0; i < 450; ++i)
    {
        float h = map(rp, aa, true);
        
        if(h <= 0.0 || rp.y < 0.0)
        {
            
            vec4 tx = texture(iChannel2, warpedRp.xz * 0.5);
            
            // straw color variance    
            float flter = 0.5;
            float strw = clamp(tx.g - flter, 0.0, 1.0);
            strw /= 1.0 - flter;
            strawcol = mix(vec4(1., 1., 0., 0.0), vec4(.8, 0.6, 0.3, 0.0), strw);
            strawcol *= 1.5;
            
            // coloring
            vec4 c2 = texture(iChannel2, warpedRp.xz * 0.008);
            col = mix(c2, strawcol, 0.8);
            
            vec3 g = grad(rp, aa);
            col = mix(vec4(0.0), col, smoothstep(H * 0.2,  H * 1.4, rp.y));
            
            vec4 clds = clouds(ro, rd);
            col *= 1.0 - clds;
            col *= vec4(1.0) * mix(shadow(rp), 1.0, 0.7);
            return true;
        }
        
        vec3 diff = rp - ro;
        float dst = dot(diff, diff);
        
        if ( dst > 30. )
        {
            return false;
        }
        
        float dist = max(0.00001, h * 0.04 * exp(max(0.0, (l - 0.5) * .2)));
        rp += rd * dist;
        l += dist;
    }
    
    
    return false;
}




void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    fragColor = vec4(0.0);
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv -= vec2(0.5);
    uv.y /= iResolution.x / iResolution.y;
    
    vec3 rp = vec3(0.0, 0.5, -1.0);
    rp.z += iTime * 0.15;
    
    vec3 ro = rp;
    vec3 rd = normalize(vec3(uv ,0.5));
    
    vec2 m = iMouse.xy - 0.5 * iResolution.xy;
    if(iMouse.xy == vec2(0.0)) m = vec2(0.0, 0.2 * iResolution.y);
    
    rd *= rotx( (m.y / iResolution.y) * 2.0);
    rd *= roty( (m.x / iResolution.y) * 3.0);
    rd = normalize(rd);
    bool hit = false;
    hit = trace(rp, rd, fragColor);
    
    if(!hit)
    {
        if(rd.y > -0.08)
            rp += rd * 10.0;
    }
    
    float dist = length(ro - rp);
    vec4 fog = vec4(0.1, 0.25, 0.4, 0.0) * 0.7;
    fog = mix(fog, vec4(1.0), smoothstep(0.5,-0.4, rd.y));
    fragColor = mix(fragColor, fog, smoothstep(3.0, 10.0, dist));
    
    if(rd.y > 0.0)
    {
        vec4 clds = clouds(ro, rd);
        clds *= smoothstep(0.0, 0.2, rd.y);
        fragColor = mix(fragColor, vec4(1.0) * 0.95, clds);
    }

    vec2 halo = rd.xy;
    float hl = length(halo);
    if(rd.z < 0.0) hl = 11.0;
    fragColor += clamp(1.0 - pow(hl, .3), 0.0, 1.0);
    
    float mx = max(fragColor.r, fragColor.g);
    mx = max(fragColor.b, mx);
    fragColor /= max(1.0, mx);
    
    // contrast
    float contr = 0.2;
    fragColor = mix(vec4(0.0), vec4(1.0), fragColor * contr + (1.0 - contr) * fragColor * fragColor * (3.0 - 2.0 * fragColor));
    
}