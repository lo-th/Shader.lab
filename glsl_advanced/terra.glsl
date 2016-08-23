
// ------------------ channel define
// 0_# bufferFULL_terraA #_0
// ------------------

// https://www.shadertoy.com/view/MdyXRG

// "Terrain Explorer" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
  Control panel appears when yellow ring (or a hidden control) clicked; panel fades
  automatically; use mouse to look around.

  Height functions based on the following (1-3 have additional spatial modulation):
    1) Basic fBm.
    2) Modified fBm in 'Elevated' by iq.
    3) Inverted abs(sin & cos) waves simplified from 'Seascape' by TDM.
    4) Weird forms from 'Sirenian Dawn' by nimitz.

  Sliders (from left):
    Overall height scale.
    Lacunarity - rate of fBm length scale change per iteration.
    Persistence - rate of fBm amplitude change per iteration.
    Variable spatial modulation (shaders 1 & 2), or feature sharpness (3 & 4).
    Flight speed.

  Buttons (from left):
    Height function choice.
    Distance marching accuracy and range (affects update rate).
    Shadows and sun elevation.

  There is no end to the functionality that can be added...
  (NB Shader length is under 0.1 KTweet.)
*/

float ShowInt (vec2 q, vec2 cBox, float mxChar, float val);
float Noisefv2 (vec2 p);
vec3 Noisev3v2 (vec2 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);
mat3 AxToRMat (vec3 vz, vec3 vy);
vec2 Rot2D (vec2 q, float a);
vec4 Loadv4 (int idVar);

const float pi = 3.14159;

vec3 sunDir;
float tCur, dstFar, hFac, fWav, aWav, smFac, stepFac;
int grType, qType, shType, stepLim;
const mat2 qRot = mat2 (0.8, -0.6, 0.6, 0.8);

vec3 SkyBg (vec3 rd)
{
  return vec3 (0.2, 0.3, 0.55) + 0.25 * pow (1. - max (rd.y, 0.), 8.);
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  float f;
  ro.xz += 0.5 * tCur;
  f = Fbm2 (0.1 * (ro + rd * (50. - ro.y) / rd.y).xz);
  return mix (SkyBg (rd) + 0.35 * pow (max (dot (rd, sunDir), 0.), 16.),
     vec3 (0.85), clamp (0.8 * f * rd.y + 0.1, 0., 1.));
}

vec3 TrackPath (float t)
{
  return vec3 (20. * sin (0.07 * t) * sin (0.022 * t) * cos (0.018 * t) +
     13. * sin (0.0061 * t), 0., t);
}

float GrndHt1 (vec2 p)
{
  vec2 q;
  float f, wAmp;
  q = 0.1 * p;
  f = 0.;
  wAmp = 1.;
  for (int j = 0; j <= 4; j ++) {
    f += wAmp * Noisefv2 (q);
    wAmp *= aWav;
    q *= fWav * qRot;
  }
  return min (5. * Noisefv2 (0.033 * smFac * p) + 0.5, 4.) * f;
}

float GrndHt2 (vec2 p)
{
  vec3 v;
  vec2 q, t;
  float wAmp, f;
  q = 0.1 * p;
  wAmp = 1.;
  t = vec2 (0.);
  f = 0.;
  for (int j = 0; j <= 3; j ++) {
    v = Noisev3v2 (q);
    t += v.yz;
    f += wAmp * v.x / (1. + dot (t, t));
    wAmp *= aWav;      
    q *= fWav * qRot;
  }
  return min (5. * Noisefv2 (0.033 * smFac * p) + 0.5, 4.) * f;
}

float GrndHt3 (vec2 p)
{
  vec2 q, t, ta, v;
  float wAmp, pRough, f;
  q = 0.1 * p;
  wAmp = 0.3;
  pRough = 1.;
  f = 0.;
  for (int j = 0; j <= 2; j ++) {
    t = q + 2. * Noisefv2 (q) - 1.;
    ta = abs (sin (t));
    v = (1. - ta) * (ta + abs (cos (t)));
    v = pow (1. - v, vec2 (pRough));
    f += (v.x + v.y) * wAmp;
    q *= fWav * qRot;
    wAmp *= aWav;
    pRough = smFac * pRough + 0.2;
  }
  return min (5. * Noisefv2 (0.033 * p) + 0.5, 4.) * f;
}

float GrndHt4 (vec2 p)
{
  vec3 v;
  vec2 q, t;
  float wAmp, b, sp, f;
  q = 0.1 * p;
  wAmp = 1.;
  t = vec2 (0.);
  f = 0.;
  sp = 0.;
  for (int j = 0; j <= 3; j ++) {
    v = Noisev3v2 (q);
    t += pow (abs (v.yz), vec2 (5. - 0.5 * sp)) - smoothstep (0., 1., v.yz);
    f += wAmp * v.x / (1. + dot (t, t));
    wAmp *= - aWav * pow (smFac, sp);
    q *= fWav * qRot;
    ++ sp;
  }
  b = 0.5 * (0.5 + clamp (f, -0.5, 1.5));
  return 3. * f / (b * b * (3. - 2. * b) + 0.5) + 1.;
}

float GrndHt (vec2 p)
{
  float ht;
  if      (grType == 1) ht = GrndHt1 (p);
  else if (grType == 2) ht = GrndHt2 (p);
  else if (grType == 3) ht = GrndHt3 (p);
  else if (grType == 4) ht = GrndHt4 (p);
  return hFac * ht;
}

float GrndRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = 0; j <= 300; j ++) {
    p = ro + s * rd;
    h = p.y - GrndHt (p.xz);
    if (h < 0.) break;
    sLo = s;
    s += stepFac * (max (0.4, 0.6 * h) + 0.008 * s);
    if (s > dstFar || j == stepLim) break;
  }
  if (h < 0.) {
    sHi = s;
    for (int j = 0; j <= 4; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      h = step (0., p.y - GrndHt (p.xz));
      sLo += h * (s - sLo);
      sHi += (1. - h) * (s - sHi);
    }
    dHit = sHi;
  }
  return dHit;
}

vec3 GrndNf (vec3 p)
{
  vec2 e;
  float ht;
  e = vec2 (0.01, 0);
  ht = GrndHt (p.xz);
  return normalize (vec3 (ht - GrndHt (p.xz + e.xy), e.x,
     ht - GrndHt (p.xz + e.yx)));
}

float GrndSShadow (vec3 p, vec3 vs)
{
  vec3 q;
  float sh, d;
  sh = 1.;
  d = 0.4;
  for (int j = 0; j <= 25; j ++) {
    q = p + vs * d; 
    sh = min (sh, smoothstep (0., 0.02 * d, q.y - GrndHt (q.xz)));
    d += max (0.4, 0.1 * d);
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstGrnd, f, spec, sh;
  dstGrnd = GrndRay (ro, rd);
  if (dstGrnd < dstFar) {
    ro += dstGrnd * rd;
    vn = GrndNf (ro);
    f = 0.2 + 0.8 * smoothstep (0.7, 1.1, Fbm2 (1.7 * ro.xz));
    col = mix (mix (vec3 (0.2, 0.35, 0.1), vec3 (0.1, 0.3, 0.15), f),
       mix (vec3 (0.3, 0.25, 0.2), vec3 (0.35, 0.3, 0.3), f),
       smoothstep (1., 3., ro.y));
    col = mix (vec3 (0.4, 0.3, 0.2), col, smoothstep (0.2, 0.6, abs (vn.y)));
    col = mix (col, vec3 (0.75, 0.7, 0.7), smoothstep (5., 8., ro.y));
    col = mix (col, vec3 (0.9), smoothstep (7., 9., ro.y) *
       smoothstep (0., 0.5, abs (vn.y)));
    spec = mix (0.1, 0.5, smoothstep (8., 9., ro.y));
    vn = VaryNf (2. * ro, vn, 1.5);
    sh = (shType > 1) ? GrndSShadow (ro, sunDir) : 1.;
    col *= 0.2 + 0.1 * vn.y + 0.7 * sh * max (0., max (dot (vn, sunDir), 0.)) +
       spec * sh * pow (max (0., dot (sunDir, reflect (rd, vn))), 16.);
    f = dstGrnd / dstFar;
    f *= f;
    col = mix (col, SkyBg (rd), clamp (f * f, 0., 1.));
  } else col = SkyCol (ro, rd);
  return pow (clamp (col, 0., 1.), vec3 (0.8));
}

mat3 EvalOri (vec3 v, vec3 a)
{
  vec3 g, w;
  float f, c, s;
  v = normalize (v);
  g = cross (v, vec3 (0., 1., 0.));
  if (g.y != 0.) {
    g.y = 0.;
    w = normalize (cross (g, v));
  } else w = vec3 (0., 1., 0.);
  f = v.z * a.x - v.x * a.z;
  f = - clamp (2. * f, -0.2 * pi, 0.2 * pi);
  c = cos (f);
  s = sin (f);
  return mat3 (c, - s, 0., s, c, 0., 0., 0., 1.) * AxToRMat (v, w);
}

vec4 ShowWg (vec2 uv, vec2 canvas, vec4 parmV1, vec4 parmV2)
{
  vec4 wgBx[8];
  vec3 col, cc;
  vec2 ut, ust;
  float vW[8], asp, s;
  cc = vec3 (1., 0., 0.);
  asp = canvas.x / canvas.y;
  for (int k = 0; k <= 4; k ++)
     wgBx[k] = vec4 ((0.25 + 0.05 * float (k)) * asp, 0., 0.014 * asp, 0.18);
  for (int k = 5; k <= 7; k ++)
     wgBx[k] = vec4 ((0.3 + 0.05 * float (k - 5)) * asp, -0.3, 0.024, 0.024);
  vW[0] = parmV1.x;  vW[1] = parmV1.y;  vW[2] = parmV1.z;  vW[3] = parmV1.w;
  vW[4] = parmV2.x;  vW[5] = parmV2.y;  vW[6] = parmV2.z;  vW[7] = parmV2.w;
  col = vec3 (0.);
  for (int k = 0; k <= 4; k ++) {
    ut = 0.5 * uv - wgBx[k].xy;
    ust = abs (ut) - wgBx[k].zw * vec2 (0.7, 1.);
    if (max (ust.x, ust.y) < 0.) {
      if  (min (abs (ust.x), abs (ust.y)) * canvas.y < 2.) col = 0.3 * cc.xxy;
      else col = (mod (0.5 * ((0.5 * uv.y - wgBx[k].y) / wgBx[k].w - 0.99), 0.1) *
         canvas.y < 6.) ? 0.3 * cc.xxy : 0.6 * cc.xxy;
    }
    ut.y -= (vW[k] - 0.5) * 2. * wgBx[k].w;
    s = ShowInt (ut - vec2 (0.018, -0.01), 0.02 * vec2 (asp, 1.), 2.,
       clamp (floor (100. * vW[k]), 0., 99.));
    if (s > 0.) col = (k < 4) ? cc.yxy : cc;
    ut = abs (ut) * vec2 (1., 1.5);
    if (max (abs (ut.x), abs (ut.y)) < 0.025 && max (ut.x, ut.y) > 0.02) col = cc.xxy;
  }
  for (int k = 5; k <= 7; k ++) {
    ut = 0.5 * uv - wgBx[k].xy;
    ust = abs (ut) - wgBx[k].zw;
    if (max (ust.x, ust.y) < 0.) {
      if  (min (abs (ust.x), abs (ust.y)) * canvas.y < 2.) col = cc.xxy;
      else col = 0.6 * cc.xxy;
    }
    s = ShowInt (ut - vec2 (0.015, -0.01), 0.02 * vec2 (asp, 1.), 1., vW[k]);
    if (s > 0.) col = (k == 5) ? cc.yxy : ((k == 6) ? cc : cc.yyx);;
  }
  return vec4 (col, step (0.001, length (col)));
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 flMat, vuMat;
  vec4 stDat, wgBxC, parmV1, parmV2, c4;
  vec3 ro, rd, col, flPos, fpF, fpB, cw;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, asp, dt, tCur, tCurM, mvTot, h, hSum, nhSum, cm;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  asp = canvas.x / canvas.y;
  wgBxC = vec4 (0.45 * asp, -0.4, 0.022, 0.);
  parmV1 = Loadv4 (0);
  hFac = 1. + parmV1.x;
  fWav = 1.5 + 0.7 * parmV1.y;
  aWav = 0.1 + 0.5 * parmV1.z;
  smFac = 0.3 + 0.7 * parmV1.w;
  parmV2 = Loadv4 (1);
  grType = int (parmV2.y);
  qType = int (parmV2.z);
  shType = int (parmV2.w);
  stDat = Loadv4 (2);
  el = stDat.x;
  az = stDat.y;
  tCur = stDat.z;
  tCurM = stDat.w;
  stDat = Loadv4 (3);
  mvTot = stDat.x;
  if (qType == 1) {
    dstFar = 170.;
    stepLim = 100;
    stepFac = 1.;
  } else if (qType == 2) {
    dstFar = 200.;
    stepLim = 200;
    stepFac = 0.5;
  } else if (qType == 3) {
    dstFar = 240.;
    stepLim = 300;
    stepFac = 0.33;
  }
  if (shType == 1) sunDir = normalize (vec3 (1., 2., 1.));
  else if (shType == 2) sunDir = normalize (vec3 (1., 1.5, 1.));
  else if (shType == 3) sunDir = normalize (vec3 (1., 1., 1.));
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  rd = vuMat * normalize (vec3 (uv, 3.));
  flPos = TrackPath (mvTot);
  dt = 1.;
  fpF = TrackPath (mvTot + dt);
  fpB = TrackPath (mvTot - dt);
  flMat = EvalOri ((fpF - fpB) / (2. * dt), (fpF - 2. * flPos + fpB) / (dt * dt));
  ro.xz = flPos.xz;
  hSum = 0.;
  nhSum = 0.;
  dt = 0.3;
  for (float fk = -2.; fk <= 10.; fk ++) {
    hSum += GrndHt (TrackPath (mvTot + fk * dt).xz);
    ++ nhSum;
  }
  ro.y = 4. * hFac + hSum / nhSum;
  rd = rd * flMat;
  col = ShowScene (ro, rd);
  if (canvas.y < 200. || tCur - tCurM < 5.) {
    c4 = ShowWg (uv, canvas, parmV1, parmV2);
    cw = mix (col, c4.rgb, c4.a);
    cm = (canvas.y < 200.) ? 0.3 : 0.2 + 0.8 * smoothstep (4., 5., tCur - tCurM);
  } else {
    cw = vec3 (0.7, 0.7, 0.);
    cm = 0.3 + 0.7 * step (2., abs (length (0.5 * uv - wgBxC.xy) -
       wgBxC.z) * canvas.y);
  }
  fragColor = vec4 (mix (cw, col, cm), 1.);
}

float DigSeg (vec2 q)
{
  return (1. - smoothstep (0.13, 0.17, abs (q.x))) *
     (1. - smoothstep (0.5, 0.57, abs (q.y)));
}

float ShowDig (vec2 q, int iv)
{
  float d;
  int k, kk;
  const vec2 vp = vec2 (0.5, 0.5), vm = vec2 (-0.5, 0.5), vo = vec2 (1., 0.);
  if (iv < 5) {
    if (iv == -1) k = 8;
    else if (iv == 0) k = 119;
    else if (iv == 1) k = 36;
    else if (iv == 2) k = 93;
    else if (iv == 3) k = 109;
    else k = 46;
  } else {
    if (iv == 5) k = 107;
    else if (iv == 6) k = 122;
    else if (iv == 7) k = 37;
    else if (iv == 8) k = 127;
    else k = 47;
  }
  q = (q - 0.5) * vec2 (1.8, 2.3);
  d = 0.;  kk = k / 2;  if (kk * 2 != k) d += DigSeg (q.yx - vo);
  k = kk;  kk = k / 2;  if (kk * 2 != k) d += DigSeg (q.xy - vp);
  k = kk;  kk = k / 2;  if (kk * 2 != k) d += DigSeg (q.xy - vm);
  k = kk;  kk = k / 2;  if (kk * 2 != k) d += DigSeg (q.yx);
  k = kk;  kk = k / 2;  if (kk * 2 != k) d += DigSeg (q.xy + vm);
  k = kk;  kk = k / 2;  if (kk * 2 != k) d += DigSeg (q.xy + vp);
  k = kk;  kk = k / 2;  if (kk * 2 != k) d += DigSeg (q.yx + vo);
  return d;
}

float ShowInt (vec2 q, vec2 cBox, float mxChar, float val)
{
  float nDig, idChar, s, sgn, v;
  q = vec2 (- q.x, q.y) / cBox;
  s = 0.;
  if (min (q.x, q.y) >= 0. && max (q.x, q.y) < 1.) {
    q.x *= mxChar;
    sgn = sign (val);
    val = abs (val);
    nDig = (val > 0.) ? floor (max (log (val) / log (10.), 0.) + 0.001) + 1. : 1.;
    idChar = mxChar - 1. - floor (q.x);
    q.x = fract (q.x);
    v = val / pow (10., mxChar - idChar - 1.);
    if (sgn < 0.) {
      if (idChar == mxChar - nDig - 1.) s = ShowDig (q, -1);
      else ++ v;
    }
    if (idChar >= mxChar - nDig) s = ShowDig (q, int (mod (floor (v), 10.)));
  }
  return s;
}

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec4 t;
  vec2 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = Hashv4f (dot (ip, cHashA3.xy));
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
}

float Fbm2 (vec2 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i <= 4; i ++) {
    f += a * Noisefv2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f;
}

vec3 Noisev3v2 (vec2 p)
{
  vec4 s, t;
  vec2 ip, fp, u;
  ip = floor (p);
  fp = fract (p);
  u = fp * fp * (3. - 2. * fp);
  t = Hashv4f (dot (ip, cHashA3.xy));
  s = vec4 (t.y - t.x, t.w - t.z, t.z - t.x, t.x - t.y + t.w - t.z);
  return vec3 (t.x + s.x * u.x + s.z * u.y + s.w * u.x * u.y,
     30. * fp * fp * (fp * fp - 2. * fp + 1.) * (s.xz + s.w * u.yx));
}

float Fbmn (vec3 p, vec3 n)
{
  vec3 s;
  float a;
  s = vec3 (0.);
  a = 1.;
  for (int i = 0; i <= 4; i ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  float s;
  vec3 e = vec3 (0.1, 0., 0.);
  s = Fbmn (p, n);
  g = vec3 (Fbmn (p + e.xyy, n) - s,
     Fbmn (p + e.yxy, n) - s, Fbmn (p + e.yyx, n) - s);
  return normalize (n + f * (g - n * dot (n, g)));
}

mat3 AxToRMat (vec3 vz, vec3 vy)
{
  vec3 vx;
  vx = normalize (cross (vy, vz));
  vy = cross (vz, vx);
  return mat3 (vec3 (vx.x, vy.x, vz.x), vec3 (vx.y, vy.y, vz.y),
     vec3 (vx.z, vy.z, vz.z));
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) * vec2 (1., 1.) + q.yx * sin (a) * vec2 (-1., 1.);
}

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

const float txRow = 32.;

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture2D (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}



void main(){

    vec4 color = vec4(0.0);

    // screen space
    //vec2 coord = gl_FragCoord.xy;
    // object space
    vec2 coord = vUv * iResolution.xy;

    mainImage( color, coord );

    // tone mapping
    #if defined( TONE_MAPPING ) 
    color.rgb = toneMapping( color.rgb ); 
    #endif

    gl_FragColor = color;

    vec2 uv = ( ( vUv * 2.0 ) - 1.0 ) * vec2(iResolution.z, 1.0);
    gl_FragColor = texture2D(iChannel0,uv);

}