
// ------------------ channel define
// 0_# buffer64_ppA #_0
// ------------------

// "Reflecting Balls" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

vec4 QMul (vec4 q1, vec4 q2)
{
  return vec4 (
     q1.w * q2.x - q1.z * q2.y + q1.y * q2.z + q1.x * q2.w,
     q1.z * q2.x + q1.w * q2.y - q1.x * q2.z + q1.y * q2.w,
   - q1.y * q2.x + q1.x * q2.y + q1.w * q2.z + q1.z * q2.w,
   - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z + q1.w * q2.w);
}

mat3 QToRMat (vec4 q) 
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

vec4 EulToQ (vec3 e)
{
  float a1, a2, a3, c1, s1;
  a1 = 0.5 * e.y;  a2 = 0.5 * (e.x - e.z);  a3 = 0.5 * (e.x + e.z);
  s1 = sin (a1);  c1 = cos (a1);
  return normalize (vec4 (s1 * cos (a2), s1 * sin (a2), c1 * sin (a3),
     c1 * cos (a3)));
}

float Hashff (float p)
{
  const float cHashM = 43758.54;
  return fract (sin (p) * cHashM);
}

const float txRow = 64.;



vec4 Loadv4 (int idVar)
{
  float fi = float (idVar);
  vec2 coord = (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) / txSize;
  vec4 v = texture2D ( txBuf, coord );
  //vec4 v = textureLod ( txBuf, coord, 0.0 );
  //float rgb = 0.003921569;
  //vec4 va = texelFetch( txBuf, ivec2((coord)), 0 );
  //vec4 v = vec4(float( va.x )*rgb, float( va.y )*rgb, float( va.z )*rgb, 0.0);
  //vec3 v3 = texelFetch ( txBuf, ivec2(coord), 0 );
  //float val = decode_float( v );
  //float res = float( val );
  ///return encode_float( res );

  //return vec4( v.r*255.0, v.g*255.0, v.b*255.0, v.a*255.0 );
  return v;
  //return texture2D ( txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) / txSize );
  //return encode_float( texture2D ( txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) / txSize ) );
}

void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord)
{
  float fi = float (idVar);
  vec2 d = abs (fCoord - vec2 (mod (fi, txRow), floor (fi / txRow)) - 0.5);
  if (max (d.x, d.y) < 0.5) fCol = val;
}

const float pi = 3.14159;
const int nMol = 8;
vec4 qtVu;
float hbLen;

void Step (int mId, out vec3 r, out vec3 v)
{
  vec3 rn, vn, dr, f;
  float fOvlap, fDamp, grav, rSep, dt;
  fOvlap = 1000.;
  fDamp = 0.05;
  grav = 5.;
  r = Loadv4 (2 * mId).xyz;
  v = Loadv4 (2 * mId + 1).xyz;
  f = vec3 (0.);
  for (int n = 0; n < nMol; n ++) {
    rn = Loadv4 (2 * n).xyz;
    dr = r - rn;
    rSep = length (dr);
    if (n != mId && rSep < 1.) f += fOvlap * (1. / rSep - 1.) * dr;
  }
  dr = hbLen - abs (r);
  f -= step (dr, vec3 (1.)) * fOvlap * sign (r) * (1. / abs (dr) - 1.) * dr +
      vec3 (0., grav, 0.) * QToRMat (qtVu) + fDamp * v;
  dt = 0.02;
  v += dt * f;
  r += dt * v;
}

vec3 VInit (int n)
{
  float fn;
  fn = float (n);
  return 2. * normalize (vec3 (Hashff (fn), Hashff (fn + 0.3),
     Hashff (fn + 0.6)) - 0.5);
}

void OrientVu (inout vec4 qtVu, vec4 mPtr, inout vec4 mPtrP, bool init)
{
  vec3 vq1, vq2;
  vec2 dm;
  float mFac;
  if (! init) {
    qtVu = vec4 (0., 0., 0., 1.);
    mPtrP = vec4 (99., 0., -1., 0.);
  } else {
    if (mPtr.z > 0.) {
      if (mPtrP.x == 99.) mPtrP = mPtr;
      mFac = 1.5;
      dm = - mFac * mPtrP.xy;
      vq1 = vec3 (dm, sqrt (max (1. - dot (dm, dm), 0.)));
      dm = - mFac * mPtr.xy;
      vq2 = vec3 (dm, sqrt (max (1. - dot (dm, dm), 0.)));
      qtVu = normalize (QMul (vec4 (cross (vq1, vq2), dot (vq1, vq2)), qtVu));
      mPtrP = mPtr;
    } else mPtrP = vec4 (99., 0., -1., 0.);
  }
}

void Init (int mId, out vec3 r, out vec3 v)
{
  float fm, fme, fn;
  fme = 2.;
  fm = float (mId);
  r = 1.5 * floor (vec3 (mod (fm, fme), mod (fm, fme * fme) / fme,
     fm / (fme * fme))) - 0.5 * (fme - 1.);
  v = VInit (mId);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 mPtr, mPtrP, stDat;
  vec3 p, r, v;
  float tCur;
  int mId, pxId;
  bool doInit;
  vec2 kv = floor (fragCoord);
  pxId = int (kv.x + txRow * kv.y);
  if (kv.x >= txRow || pxId > 2 * nMol + 2) discard;
  tCur = iGlobalTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / iResolution.xy - 0.5;
  qtVu = Loadv4 (2 * nMol + 1);
  mPtrP = Loadv4 (2 * nMol + 2);
  mId = pxId / 2;
  doInit = false;
  if (iFrame < 2) {
    hbLen = 3.;
    OrientVu (qtVu, mPtr, mPtrP, false);
    stDat = vec4 (0., hbLen, tCur, 0.);
    if (mId < nMol) doInit = true;
  } else {
    OrientVu (qtVu, mPtr, mPtrP, true);
    stDat = Loadv4 (2 * nMol);
    ++ stDat.x;
    hbLen = stDat.y;
    if (mPtrP.z < 0.) qtVu = normalize (QMul (EulToQ (0.2 * (tCur - stDat.z) *
       pi * vec3 (-0.27, -0.34, -0.11)), qtVu));
    stDat.z = tCur;
    if (mId < nMol) {
      Step (mId, r, v);
      p = (2 * mId == pxId) ? r : v;
    }
  }
  if (doInit) {
    Init (mId, r, v);
    p = (2 * mId == pxId) ? r : v;
  }
  if (pxId == 2 * nMol + 1) stDat = qtVu;
  else if (pxId == 2 * nMol + 2) stDat = mPtrP;
  Savev4 (pxId, ((pxId < 2 * nMol) ? vec4 (p, 0.) : stDat), fragColor, fragCoord);
}
