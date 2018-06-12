// ------------------ channel define
// 0_# bufferFULL_rollingB #_0
// ------------------

// "Rolling Stones" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
  Rolling/bouncing balls dragged across a fractal landscape and also
  attracted to their center-of-mass.

  Control panel appears when ring (or a hidden control) clicked; panel fades
  automatically; look around using mouse.

  Sliders (from left - arbitrary values) adjust:
    Lacunarity - rate of landscape fBm length scale change per iteration.
    Persistence - rate of landscape fBm amplitude change per iteration.
    Landscape height.
    Drag speed.
*/

// https://www.shadertoy.com/view/MdsfD7



float ShowInt (vec2 q, vec2 cBox, float mxChar, float val);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
mat3 QtToRMat (vec4 q);
vec4 Loadv4 (int idVar);
vec3 HsvToRgb (vec3 c);

mat2 fqRot;
vec3 vnBall, sunDir;
float dstFar, fWav, aWav, htFac, htMax;
int idBall;
const int nBall = 144;
const float pi = 3.14159;

float GrndHt (vec2 p)
{
  vec2 q;
  float f, wAmp;
  q = 0.05 * p;
  f = 0.;
  wAmp = 1.;
  for (int j = 0; j < 5; j ++) {
    f += wAmp * Noisefv2 (q);
    wAmp *= aWav;
    q *= fqRot;
  }
  return htMax * f;
}

float GrndRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = 0; j < 200; j ++) {
    p = ro + s * rd;
    h = p.y - GrndHt (p.xz);
    if (h < 0.) break;
    sLo = s;
    s += max (0.2, 0.35 * h);
    if (s > dstFar) break;
  }
  if (h < 0.) {
    sHi = s;
    for (int j = 0; j < 5; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      if (p.y > GrndHt (p.xz)) sLo = s;
      else sHi = s;
    }
    dHit = 0.5 * (sLo + sHi);
  }
  return dHit;
}

vec3 GrndNf (vec3 p)
{
  const vec2 e = vec2 (0.01, 0.);
  float h;
  h = GrndHt (p.xz);
  return normalize (vec3 (h - GrndHt (p.xz + e.xy), e.x, h - GrndHt (p.xz + e.yx)));
}

float GrndSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  float sh, d, h;
  sh = 1.;
  d = 0.1;
  for (int j = 0; j < 16; j ++) {
    p = ro + rd * d;
    h = p.y - GrndHt (p.xz);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += max (0.2, 0.1 * d);
    if (sh < 0.05) break;
  }
  return sh;
}

float BallHit (vec3 ro, vec3 rd)
{
  vec4 p;
  vec3 u;
  float b, d, w, dMin, rad;
  dMin = dstFar;
  for (int n = 0; n < nBall; n ++) {
    p = Loadv4 (4 * n);
    u = ro - p.xyz;
    rad = 0.45 * p.w;
    b = dot (rd, u);
    w = b * b - dot (u, u) + rad * rad;
    if (w >= 0.) {
      d = - b - sqrt (w);
      if (d > 0. && d < dMin) {
        dMin = d;
        vnBall = (u + d * rd) / rad;
        idBall = n;
      }
    }
  }
  return dMin;
}

float BallHitSh (vec3 ro, vec3 rd, float rng)
{
  vec4 p;
  vec3 rs, u;
  float b, d, w, dMin, rad;
  dMin = dstFar;
  for (int n = 0; n < nBall; n ++) {
    p = Loadv4 (4 * n);
    u = ro - p.xyz;
    rad = 0.45 * p.w;
    b = dot (rd, u);
    w = b * b - dot (u, u) + rad * rad;
    if (w >= 0.) {
      d = - b - sqrt (w);
      if (d > 0. && d < dMin) dMin = d;
    }
  }
  return 0.4 + 0.6 * smoothstep (0., rng, dMin);
}

float BallChqr (int idBall, vec3 vnBall)
{
  vec3 u;
  u = vnBall * QtToRMat (Loadv4 (4 * idBall + 2));
  return 0.4 + 0.6 * step (0., sign (u.y) * sign (u.z) * atan (u.x, u.y));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 objCol;
  vec3 col, vn, bgCol;
  float dstGrnd, dstBall, sh, c;
  bgCol = vec3 (0.4, 0.4, 0.45);
  dstGrnd = GrndRay (ro, rd);
  dstBall = BallHit (ro, rd);
  if (min (dstBall, dstGrnd) < dstFar) {
    if (dstGrnd < dstBall) {
      ro += rd * dstGrnd;
      vn = GrndNf (ro);
      objCol = vec4 (mix (vec3 (0.35, 0.3, 0.1), vec3 (0.4, 0.6, 0.2),
         clamp (0.5 * pow (vn.y, 4.) + Fbm2 (0.5 * ro.xz) - 0.5, 0., 1.)) *
         (1. - 0.1 * Noisefv2 (10. * ro.xz)), 0.);
      sh = min (BallHitSh (ro + 0.01 * sunDir, sunDir, 10.),
         GrndSShadow (ro, sunDir));
    } else {
      ro += rd * dstBall;
      c = float (idBall / 16) / float (nBall / 16);
      objCol = vec4 (HsvToRgb (vec3 (mod (c, 1.), 1., 1.)), 1.);
      objCol.rgb *= BallChqr (idBall, vnBall);
      vn = vnBall;
      sh = 1.;
    }
    col = objCol.rgb * (0.2 + 0.8 * sh * max (dot (vn, sunDir), 0.)) +
       objCol.a * sh * pow (max (dot (normalize (sunDir - rd), vn), 0.), 256.);
    col = mix (col, bgCol, clamp (3. * min (dstBall, dstGrnd) / dstFar - 2.,
       0., 1.));
  } else col = bgCol;
  return pow (clamp (col, 0., 1.), vec3 (0.8));
}

#define N_SLIDR 4

vec4 ShowWg (vec2 uv, vec2 canvas, vec4 parmV)
{
  vec4 wgBx[N_SLIDR];
  vec3 col, cc;
  vec2 ut, ust;
  float vW[N_SLIDR], asp, s;
  cc = vec3 (1., 0., 0.);
  asp = canvas.x / canvas.y;
  for (int k = 0; k < N_SLIDR; k ++)
     wgBx[k] = vec4 ((0.31 + 0.05 * float (k)) * asp, -0.15, 0.014 * asp, 0.18);
  vW[0] = parmV.x;  vW[1] = parmV.y;  vW[2] = parmV.z;  vW[3] = parmV.w;
  col = vec3 (0.);
  for (int k = 0; k < N_SLIDR; k ++) {
    ut = 0.5 * uv - wgBx[k].xy;
    ust = abs (ut) - wgBx[k].zw * vec2 (0.7, 1.);
    if (max (ust.x, ust.y) < 0.) {
      if  (min (abs (ust.x), abs (ust.y)) * canvas.y < 2.) col = 0.3 * cc.yxx;
      else col = (mod (0.5 * ((0.5 * uv.y - wgBx[k].y) / wgBx[k].w - 0.99), 0.1) *
         canvas.y < 6.) ? 0.3 * cc.yxx : 0.6 * cc.yxx;
    }
    ut.y -= (vW[k] - 0.5) * 2. * wgBx[k].w;
    s = ShowInt (ut - vec2 (0.018, -0.01), 0.02 * vec2 (asp, 1.), 2.,
       clamp (floor (100. * vW[k]), 1., 99.));
    if (s > 0.) col = cc.yxy;
    ut = abs (ut) * vec2 (1., 1.5);
    if (max (abs (ut.x), abs (ut.y)) < 0.025 && max (ut.x, ut.y) > 0.02) col = cc.yxx;
  }
  return vec4 (col, step (0.001, length (col)));
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 stDat, wgBxC, parmV, c4;
  vec3 col, rd, ro, vd, u, rLead, rMid, cw;
  vec2 canvas, uv;
  float asp, tCur, tCurM, az, el, zmFac, f, cm;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  asp = canvas.x / canvas.y;
  wgBxC = vec4 (0.45 * asp, -0.4, 0.022, 0.);
  rMid = Loadv4 (4 * nBall).xyz;
  rLead = Loadv4 (4 * nBall + 1).xyz;
  parmV = Loadv4 (4 * nBall + 2);
  fWav = 4. * (0.5 + 0.1 * (parmV.x - 0.5));
  fqRot = fWav * mat2 (0.6, -0.8, 0.8, 0.6);
  aWav = 1. * (0.5 + 0.2 * (parmV.y - 0.5));
  htFac = 30. * (0.5 + 0.2 * (parmV.z - 0.5));
  htMax = htFac * (1. - aWav) / (1. - pow (aWav, 5.));
  stDat = Loadv4 (4 * nBall + 4);
  tCur = stDat.z;
  tCurM = stDat.w;
  az = -0.01 * pi * tCur;
  el = pi * (0.1 + 0.05 * sin (0.011 * pi * tCur));
  el += stDat.x;
  az += stDat.y;
  el = clamp (el, 0.02 * pi, 0.45 * pi);
  zmFac = 4.;
  ro = 0.5 * (rLead + rMid) + 60. *
     vec3 (cos (el) * cos (az), sin (el), cos (el) * sin (az));
  ro.y = max (ro.y, GrndHt (ro.xz) + 3.);
  vd = normalize (rMid - ro);
  u = - vd.y * vd;
  f = 1. / sqrt (1. - vd.y * vd.y);
  vuMat = mat3 (f * vec3 (vd.z, 0., - vd.x), f * vec3 (u.x, 1. + u.y, u.z), vd);
  rd = vuMat * normalize (vec3 (uv, zmFac));
  sunDir = normalize (vec3 (cos (0.01 * tCur), 1., sin (0.01 * tCur)));
  dstFar = 100.;
  col = ShowScene (ro, rd);
  if (canvas.y < 256. || tCur - tCurM < 5.) {
    c4 = ShowWg (uv, canvas, parmV);
    cw = mix (col, c4.rgb, c4.a);
    cm = (canvas.y < 256.) ? 0.3 : 0.2 + 0.8 * smoothstep (4., 5., tCur - tCurM);
  } else {
    cw = vec3 (0., 0.7, 0.7);
    cm = 0.3 + 0.7 * step (2., abs (length (0.5 * uv - wgBxC.xy) -
       wgBxC.z) * canvas.y);
  }
  fragColor = vec4 (mix (cw, col, cm), 1.);
}

mat3 QtToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  q = normalize (q);
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
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
  for (int i = 0; i < 5; i ++) {
    f += a * Noisefv2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

const float txRow = 128.;

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture2D (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}
