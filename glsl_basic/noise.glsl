
// ------------------ channel define
// 0_# noise #_0
// ------------------

#ifdef USE_PROCEDURAL
float hash( float n ) { return fract(sin(n)*753.5453123); }
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}
#else
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = texture2D( iChannel0, (uv+0.5)/256.0, -100.0 ).yx;
    return mix( rg.x, rg.y, f.z );
}
#endif


const mat3 m = mat3(0.00, 0.80, 0.60, -0.80, 0.36, -0.48, -0.60, -0.48, 0.64);

void main() {

    //vec2 uv = (1.0 - vUv * 2.0) * vec2(iResolution.x / iResolution.y, -1.0);
    //vec2 uv = ((vUv - 0.5) * 2.0) * vec2(iResolution.z, 1.0);

    vec2 uv = ( ( vUv * 2.0 ) - 1.0 ) * vec2(iResolution.z, 1.0);
    
    vec2 p = uv;

    float an = 0.5 * iGlobalTime;
    vec3 ro = vec3(2.5 * cos(an), 1.0, 2.5 * sin(an));
    vec3 ta = vec3(0.0, 1.0, 0.0);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = normalize(cross(uu, ww));
    vec3 rd = normalize(p.x * uu + p.y * vv + 1.5 * ww);
    vec3 sc = vec3(0.0, 1.0, 0.0);
    float tmin = 10000.0;
    vec3 nor = vec3(0.0);
    float occ = 1.0;
    vec3 pos = vec3(0.0);
    float h = (0.0 - ro.y) / rd.y;
    if (h > 0.0) 
    {
        tmin = h;
        nor = vec3(0.0, 1.0, 0.0);
        pos = ro + h * rd;
        vec3 di = sc - pos;
        float l = length(di);
        occ = 1.0 - dot(nor, di / l) * 1.0 * 1.0 / (l * l);
    }
     vec3 ce = ro - sc;
    float b = dot(rd, ce);
    float c = dot(ce, ce) - 1.0;
    h = b * b - c;
    if (h > 0.0) 
    {
        h = -b - sqrt(h);
        if (h < tmin) 
        {
            tmin = h;
            nor = normalize(ro + h * rd - sc);
            occ = 0.5 + 0.5 * nor.y;
        }
     }
     vec3 col = vec3(0.9);
    if (tmin < 100.0) 
    {
        pos = ro + tmin * rd;
        float f = 0.0;
        if (p.x < 0.0) 
        {
            f = noise(16.0 * pos);
        }
 else 
        {
            vec3 q = 8.0 * pos;
            f = 0.5000 * noise(q);
            q = m * q * 2.01;
            f += 0.2500 * noise(q);
            q = m * q * 2.02;
            f += 0.1250 * noise(q);
            q = m * q * 2.03;
            f += 0.0625 * noise(q);
            q = m * q * 2.01;
        }
        f *= occ;
        col = vec3(f * 1.2);
        col = mix(col, vec3(0.9), 1.0 - exp(-0.003 * tmin * tmin));
    }
     col = sqrt(col);
    col *= smoothstep(0.006, 0.008, abs(p.x));
    gl_FragColor = vec4(col, 1.0);
}
