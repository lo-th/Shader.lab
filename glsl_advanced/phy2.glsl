

// ------------------ channel define
// 0_# buffer128_phy2A #_0
// ------------------

// https://www.shadertoy.com/view/XsKGWc

// "Destruction" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

mat3 QtToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

const float txRow = 128.;

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture2D (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}

const float pi = 3.14159;
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
  return f;
}

const int nBlock = 64;
const int nSiteBk = 30;
const vec3 blkSph = vec3 (5., 3., 2.);
const vec3 blkGap = vec3 (1., 0.8, 0.8);

vec3 vnBlk, vnBall, sunDir;
vec2 qBlk, qBall;
float tCur, dstFar;
int idBlk, idBall;

vec3 BgCol (vec3 ro, vec3 rd, float sh)
{
  vec3 vn, col;
  vec2 w;
  float sd, f;
  vec2 e = vec2 (0.01, 0.);
  if (rd.y >= 0.) {
    ro.xz += 2. * tCur;
    sd = max (dot (rd, sunDir), 0.);
    col = vec3 (0.1, 0.2, 0.4) + 0.2 * (1. - max (rd.y, 0.)) +
       0.1 * pow (sd, 16.) + 0.2 * pow (sd, 256.);
    f = Fbm2 (0.02 * (ro.xz + rd.xz * (100. - ro.y) / max (rd.y, 0.001)));
    col = mix (col, vec3 (1.), clamp (0.2 + 0.8 * f * rd.y, 0., 1.));
  } else {
    ro -= (ro.y / rd.y) * rd;
    w = 0.3 * ro.xz;
    f = Fbm2 (w);
    col = mix (vec3 (0.4, 0.3, 0.1), vec3 (0.5, 0.4, 0.2), f) *
         (1. - 0.2 * Noisefv2 (w));
    vn = normalize (vec3 (f - Fbm2 (w + e.xy), 0.07, f - Fbm2 (w + e.yx)));
    col *= (0.2 + 0.8 * sh) * (0.1 + 0.9 * max (dot (vn, sunDir), 0.));
    col = mix (col, vec3 (0.45, 0.55, 0.7), pow (1. + rd.y, 64.));
  }
  return col;
}

float BlkHit (vec3 ro, vec3 rd)
{
  mat3 m;
  vec3 rm, rdm, v, tm, tp, bSize, u;
  float dMin, dn, df;
  bSize = 0.5 * blkGap * (blkSph - 1.) + 0.5;
  dMin = dstFar;
  for (int n = 0; n < nBlock; n ++) {
    rm = Loadv4 (4 + 4 * n).xyz;
    m = QtToRMat (Loadv4 (4 + 4 * n + 2));
    rdm = rd * m;
    v = ((ro - rm) * m) / rdm;
    tp = bSize / abs (rdm) - v;
    tm = - tp - 2. * v;
    dn = max (max (tm.x, tm.y), tm.z);
    df = min (min (tp.x, tp.y), tp.z);
    if (df > 0. && dn < min (df, dMin)) {
      dMin = dn;
      vnBlk = - sign (rdm) * step (tm.zxy, tm) * step (tm.yzx, tm);
      idBlk = n;
      u = (v + dn) * rdm;
    }
  }
  if (dMin < dstFar) {
    qBlk = vec2 (dot (u.zxy, vnBlk), dot (u.yzx, vnBlk));
    m = QtToRMat (Loadv4 (4 + 4 * idBlk + 2));
    vnBlk = m * vnBlk;
  }
  return dMin;
}

float BallHit (vec3 ro, vec3 rd)
{
  vec3 rs, u;
  float b, d, w, dMin, rad;
  rad = 0.45;
  dMin = dstFar;
  for (int n = nBlock; n < nBlock + 4; n ++) {
    rs = Loadv4 (4 + 4 * n).xyz;
    u = ro - rs;
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

float BlkHitSh (vec3 ro, vec3 rd, float rng)
{
  mat3 m;
  vec3 rm, rdm, v, tm, tp, bSize;
  float dMin, dn, df;
  bSize = 0.5 * blkGap * (blkSph - 1.) + 0.4;
  dMin = dstFar;
  for (int n = 0; n < nBlock; n ++) {
    rm = Loadv4 (4 + 4 * n).xyz;
    m = QtToRMat (Loadv4 (4 + 4 * n + 2));
    rdm = rd * m;
    v = ((ro - rm) * m) / rdm;
    tp = bSize / abs (rdm) - v;
    tm = - tp - 2. * v;
    dn = max (max (tm.x, tm.y), tm.z);
    df = min (min (tp.x, tp.y), tp.z);
    if (df > 0. && dn < min (df, dMin)) dMin = dn;
  }
  return smoothstep (0., rng, dMin);
}

float BallHitSh (vec3 ro, vec3 rd, float rng)
{
  vec3 rs, u;
  float b, d, w, dMin, rad;
  rad = 0.45;
  dMin = dstFar;
  for (int n = nBlock; n < nBlock + 4; n ++) {
    rs = Loadv4 (4 + 4 * n).xyz;
    u = ro - rs;
    b = dot (rd, u);
    w = b * b - dot (u, u) + rad * rad;
    if (w >= 0.) {
      d = - b - sqrt (w);
      if (d > 0. && d < dMin) dMin = d;
    }
  }
  return smoothstep (0., rng, dMin);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 objCol;
  vec3 col, vn;
  float dstFlr, dstBlk, dstBall, sh;
  bool useBg;
  dstFlr = (rd.y < 0.) ? - (ro.y - 0.5) / rd.y : dstFar;
  dstBall = BallHit (ro, rd);
  dstBlk = BlkHit (ro, rd);
  if (dstBall < dstBlk) {
    idBlk = nBlock;
    dstBlk = dstBall;
  }
  useBg = false;
  if (min (min (dstBlk, dstBall), dstFlr) < dstFar) {
    if (dstFlr < min (dstBlk, dstBall)) {
      ro += rd * dstFlr;
      vn = vec3 (0., 1., 0.);
      useBg = true;
    } else {
      ro += rd * dstBlk;
      if (dstBlk < dstBall) {
        vn = vnBlk;
        objCol = vec4 (vec3 (0.7, 0.7, 0.8) * (1. - 0.4 * Fbm2 (20. * qBlk)), 0.3);
      } else {
        vn = vnBall;
        objCol = vec4 (0., 1., 0., 1.);
      }
    }
  } else useBg = true;
  sh = 1.;
  if (! useBg || rd.y < 0.) sh = min (BlkHitSh (ro + 0.01 * sunDir, sunDir, 100.), 
        BallHitSh (ro + 0.01 * sunDir, sunDir, 100.));
  if (! useBg) col = objCol.rgb * (0.2 + 0.8 * sh * max (dot (vn, sunDir), 0.) +
       0.3 * max (dot (vn, vec3 (- sunDir.x, 0., - sunDir.z)), 0.)) +
       objCol.a * sh * pow (max (0., dot (sunDir, reflect (rd, vn))), 128.);
  else col = BgCol (ro, rd, sh);
  return pow (clamp (col, 0., 1.), vec3 (0.6));
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 col, rd, ro, vd, u, vc;
  vec2 canvas, uv;
  float nStep, mxStep, az, el, zmFac, f;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iGlobalTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  nStep = Loadv4 (0).x;
  mxStep = Loadv4 (0).y;
  dstFar = 150.;
  vc = vec3 (0., mix (10., 2., 1.2 * min (nStep / mxStep, 1.)), 0.);
  az = -0.04 * tCur;
  el = 0.7;
  zmFac = 2.4;
  if (mPtr.z > 0.) {
    el = clamp (el - 3. * mPtr.y, 0.05 * pi, 0.45 * pi);
    az -= 1.5 * pi * mPtr.x;
  }
  ro = 60. * vec3 (cos (el) * cos (az), sin (el), cos (el) * sin (az));
  vd = normalize (vc - ro);
  u = - vd.y * vd;
  f = 1. / sqrt (1. - vd.y * vd.y);
  vuMat = mat3 (f * vec3 (vd.z, 0., - vd.x), f * vec3 (u.x, 1. + u.y, u.z), vd);
  rd = vuMat * normalize (vec3 (uv, zmFac));
  sunDir = normalize (vec3 (1., 2., -1.));
  col = ShowScene (ro, rd);
  fragColor = vec4 (col, 1.);
}
