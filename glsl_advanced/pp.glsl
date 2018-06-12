
// ------------------ channel define
// 0_# buffer64_ppA #_0
// ------------------


// "Reflecting Balls" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
Elastic balls; there are also damping forces and gravity. The front-facing walls are
transparent when looking from outside, but not for the reflections. Use the mouse to
spin the box.
*/

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

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

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrSphDf (vec3 p, float s)
{
  return length (p) - s;
}

/*float shift_right (float v, float amt) { 
    v = floor(v) + 0.5; 
    return floor(v / exp2(amt)); 
}
float shift_left (float v, float amt) { 
    return floor(v * exp2(amt) + 0.5); 
}
float mask_last (float v, float bits) { 
    return mod(v, shift_left(1.0, bits)); 
}
float extract_bits (float num, float from, float to) { 
    from = floor(from + 0.5); to = floor(to + 0.5); 
    return mask_last(shift_right(num, from), to - from); 
}
vec4 encode_float (float val) { 
    if (val == 0.0) return vec4(0, 0, 0, 0); 
    float sign = val > 0.0 ? 0.0 : 1.0; 
    val = abs(val); 
    float exponent = floor(log2(val)); 
    float biased_exponent = exponent + 127.0; 
    float fraction = ((val / exp2(exponent)) - 1.0) * 8388608.0; 
    float t = biased_exponent / 2.0; 
    float last_bit_of_biased_exponent = fract(t) * 2.0; 
    float remaining_bits_of_biased_exponent = floor(t); 
    float byte4 = extract_bits(fraction, 0.0, 8.0) / 255.0; 
    float byte3 = extract_bits(fraction, 8.0, 16.0) / 255.0; 
    float byte2 = (last_bit_of_biased_exponent * 128.0 + extract_bits(fraction, 16.0, 23.0)) / 255.0; 
    float byte1 = (sign * 128.0 + remaining_bits_of_biased_exponent) / 255.0; 
    return vec4(byte4, byte3, byte2, byte1); 
}*/

const float txRow = 64.;

vec4 Loadv4 (int idVar)
{

  float fi = float (idVar);
  vec4 v = texture2D (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) / txSize);
  //float val = decode_float( v );
  //float res = float( val );
  //return encode_float( res );

  //return vec4( v.r/255.0, v.g/255.0, v.b/255.0, v.a/255.0 );
  //return vec4( v.r*255.0, v.g*255.0, v.b*255.0, v.a*255.0 );
  return v;
  //float fi = float (idVar);
  //return texture2D (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) / txSize);
  //return encode_float( texture2D (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) / txSize) );
}

const float pi = 3.14159;
const int nMol = 8;
vec3 pMol[nMol], ltDir, rdSign;
float dstFar, hbLen;
int idObj;
bool isRefl;

float ObjDf (vec3 p)
{
  vec4 fVec;
  vec3 q, eLen, eShift;
  float dMin, d, eWid, sLen;
  dMin = dstFar;
  sLen = hbLen - 0.35;
  eWid = 0.04;
  eShift = vec3 (0., sLen, sLen);
  eLen = vec3 (sLen + eWid, eWid, eWid);
  if (! isRefl) {
    fVec = vec4 (sLen * rdSign, 0.);
    q = p;
    d = min (min (PrBoxDf (q - fVec.xww, eLen.yxx),
       PrBoxDf (q - fVec.wyw, eLen.xyx)), PrBoxDf (q - fVec.wwz, eLen.xxy));
    if (d < dMin) { dMin = d;  idObj = 1; }
    q = abs (p);
    d = min (min (PrBoxDf (q - eShift, eLen), PrBoxDf (q - eShift.yxz, eLen.yxz)),
       PrBoxDf (q - eShift.yzx, eLen.yzx));
    if (d < dMin) { dMin = d;  idObj = 2; }
  } else {
    fVec = vec4 (sLen * vec3 (1.), 0.);
    q = abs (p);
    d = min (min (PrBoxDf (q - fVec.xww, eLen.yxx),
       PrBoxDf (q - fVec.wyw, eLen.xyx)), PrBoxDf (q - fVec.wwz, eLen.xxy));
    if (d < dMin) { dMin = d;  idObj = 1; }
  }
  for (int n = 0; n < nMol; n ++) {
    d = PrSphDf (p - pMol[n], 0.45);
    if (d < dMin) { dMin = d;  idObj = 3; }
  }
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
  const vec3 e = vec3 (0.0002, -0.0002, 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 objCol;
  vec3 col, vn, w;
  float dstHit, reflFac;
  int idObjT;
  reflFac = 1.;
  isRefl = false;
  rdSign = sign (rd);
  for (int nf = 0; nf < 4; nf ++) {
    idObj = -1;
    dstHit = ObjRay (ro, rd);
    if (idObj == 3) {
      ro += rd * dstHit;
      rd = reflect (rd, ObjNf (ro));
      ro += 0.01 * rd;
      isRefl = true;
      reflFac *= 0.95;
    } else break;
  }
  if (dstHit < dstFar) {
    ro += rd * dstHit;
    idObjT = idObj;
    vn = ObjNf (ro);
    idObj = idObjT;
    if (idObj == 1) {
      w = smoothstep (0., 0.1, abs (fract (1.95 * ro + 0.5) - 0.5));
      objCol = vec4 (mix (vec3 (1., 1., 0.4), vec3 (0.5, 0.5, 1.),
         dot (abs (vn) * w.yzx * w.zxy, vec3 (1.))), 0.4);
    } else if (idObj == 2) objCol = vec4 (1., 1., 0.4, 0.4);
    else if (idObj == 3) objCol = vec4 (0.5, 0.5, 0.8, 0.1);
    col = objCol.rgb * (0.6 + 0.4 * max (dot (vn, ltDir), 0.)) +
       objCol.a * pow (max (0., dot (ltDir, reflect (rd, vn))), 128.);
  } else col = vec3 (0., 0., 0.1);
  return clamp (reflFac * col, 0., 1.);
}

void GetMols ()
{
  for (int n = 0; n < nMol; n ++) pMol[n] = Loadv4 (2 * n).xyz;
  hbLen = Loadv4 (2 * nMol).y;
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 qtVu;
  vec3 col, rd, ro;
  vec2 canvas, uv, ut;
  float tCur;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iGlobalTime;
  ut = abs (uv) - vec2 (1.);
  if (max (ut.x, ut.y) > 0.003) col = vec3 (0.82);
  else {
    dstFar = 100.;
    qtVu = Loadv4 (2 * nMol + 1);
    vuMat = QToRMat (qtVu);
    rd = normalize (vec3 (uv, 8.)) * vuMat;
    ro = vec3 (0., 0., -35.) * vuMat;
    ltDir = normalize (vec3 (1., 1.5, -1.2)) * vuMat;
    GetMols ();
    col = ShowScene (ro, rd);
  }
  fragColor = vec4 (col, 1.);
}

