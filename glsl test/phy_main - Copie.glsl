// "Leaping Balls Return" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

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

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

const int nBall = 144;
vec3 vnBall, sunDir;
float tCur, dstFar;
int idBall, idObj;

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d;
  dMin = dstFar;
  d = p.y - 0.5;
  if (d < dMin) { dMin = d;  idObj = 1; }
  q = p;
  q.xz = mod (q.xz + 5., 10.) - 5.;
  d = PrBoxDf (q, 0.48 + vec3 (0.5, 0.75, 0.5));
  if (d < dMin) { dMin = d;  idObj = 2; }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  const vec3 e = vec3 (0.001, -0.001, 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float BallHit (vec3 ro, vec3 rd)
{
  vec4 p;
  vec3 u;
  float b, d, w, dMin, rad;
  dMin = dstFar;
  for (int n = 0; n < nBall; n ++) {
    p = Loadv4 (4 + 4 * n);
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
    p = Loadv4 (4 + 4 * n);
    u = ro - p.xyz;
    rad = 0.45 * p.w;
    b = dot (rd, u);
    w = b * b - dot (u, u) + rad * rad;
    if (w >= 0.) {
      d = - b - sqrt (w);
      if (d > 0. && d < dMin) dMin = d;
    }
  }
  return smoothstep (0., rng, dMin);
}

float BallChqr (int idBall, vec3 vnBall)
{
  vec3 u;
  u = vnBall * QtToRMat (Loadv4 (4 + 4 * idBall + 2));
  return 0.4 + 0.6 * step (0., sign (u.y) * sign (u.z) * atan (u.x, u.y));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 objCol;
  vec3 col, vn, bgCol;
  float dstFlr, dstBall, sh, c;
  bgCol = vec3 (0.45, 0.4, 0.4);
  dstFlr = ObjRay (ro, rd);
  dstBall = BallHit (ro, rd);
  if (min (dstBall, dstFlr) < dstFar) {
    if (dstFlr < dstBall) {
      ro += rd * dstFlr;
      if (idObj == 1) {
        objCol = vec4 (1.15 * bgCol * (1. - 0.1 * Fbm2 (20. * ro.xz)), 0.3);
        vn = vec3 (0., 1., 0.);
      } else {
        vn = ObjNf (ro);
        objCol = vec4 (vec3 (0.7, 0.8, 0.7) * (1. -
           0.4 * Fbm2 (30. * vec2 (dot (ro.yzx, vn), dot (ro.zxy, vn)))), 0.1);
      } 
    } else {
      ro += rd * dstBall;
      c = float (idBall / 16) / float (nBall / 16);
      objCol = vec4 (HsvToRgb (vec3 (mod (c, 1.), 1., 1.)), 1.);
      objCol.rgb *= BallChqr (idBall, vnBall);
      vn = vnBall;
    }
    sh = BallHitSh (ro + 0.01 * sunDir, sunDir, 10.);
    col = objCol.rgb * (0.2 + 0.8 * sh * max (dot (vn, sunDir), 0.) +
       0.3 * max (dot (vn, vec3 (- sunDir.x, 0., - sunDir.z)), 0.)) +
       objCol.a * sh * pow (max (0., dot (sunDir, reflect (rd, vn))), 64.);
    col = mix (col, bgCol, clamp (3. * min (dstBall, dstFlr) / dstFar - 2.,
       0., 1.));
  } else col = bgCol;
  return pow (clamp (col, 0., 1.), vec3 (0.7));
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 col, rd, ro, vd, u, rLead, rMid;
  vec2 canvas, uv;
  float az, el, zmFac, f;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iGlobalTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  rLead = Loadv4 (1).xyz;
  rMid = Loadv4 (2).xyz;
  dstFar = 200.;
  az = -0.01 * pi * tCur;
  el = 0.1 * pi + 0.05 * pi * sin (0.011 * pi * tCur);
  zmFac = 6.;
  if (mPtr.z > 0.) {
    el = clamp (el - 0.5 * pi * mPtr.y, 0.02 * pi, 0.45 * pi);
    az -= 2. * pi * mPtr.x;
  }
  ro = 0.5 * (rLead + rMid) + 60. *
     vec3 (cos (el) * cos (az), sin (el), cos (el) * sin (az));
  vd = normalize (rMid - ro);
  u = - vd.y * vd;
  f = 1. / sqrt (1. - vd.y * vd.y);
  vuMat = mat3 (f * vec3 (vd.z, 0., - vd.x), f * vec3 (u.x, 1. + u.y, u.z), vd);
  rd = vuMat * normalize (vec3 (uv, zmFac));
  sunDir = normalize (vec3 (cos (0.007 * tCur), 3., sin (0.007 * tCur)));
  col = ShowScene (ro, rd);
  fragColor = vec4 (col, 1.);
}
