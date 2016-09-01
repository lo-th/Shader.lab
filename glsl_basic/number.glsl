
// https://www.shadertoy.com/view/4sf3RN

// Number Printing - @P_Malin
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// For a smaller less restrictive version, see this shader: https://www.shadertoy.com/view/4sBSWW

//#define BITMAP_VERSION

const float kCharBlank = 12.0;
const float kCharMinus = 11.0;
const float kCharDecimalPoint = 10.0;

#ifndef BITMAP_VERSION

float InRect(const in vec2 vUV, const in vec4 vRect)
{
    vec2 vTestMin = step(vRect.xy, vUV.xy);
    vec2 vTestMax = step(vUV.xy, vRect.zw); 
    vec2 vTest = vTestMin * vTestMax;
    return vTest.x * vTest.y;
}

float SampleDigit(const in float fDigit, const in vec2 vUV)
{
    const float x0 = 0.0 / 4.0;
    const float x1 = 1.0 / 4.0;
    const float x2 = 2.0 / 4.0;
    const float x3 = 3.0 / 4.0;
    const float x4 = 4.0 / 4.0;
    
    const float y0 = 0.0 / 5.0;
    const float y1 = 1.0 / 5.0;
    const float y2 = 2.0 / 5.0;
    const float y3 = 3.0 / 5.0;
    const float y4 = 4.0 / 5.0;
    const float y5 = 5.0 / 5.0;

    // In this version each digit is made of up to 3 rectangles which we XOR together to get the result
    
    vec4 vRect0 = vec4(0.0);
    vec4 vRect1 = vec4(0.0);
    vec4 vRect2 = vec4(0.0);
        
    if(fDigit < 0.5) // 0
    {
        vRect0 = vec4(x0, y0, x3, y5); vRect1 = vec4(x1, y1, x2, y4);
    }
    else if(fDigit < 1.5) // 1
    {
        vRect0 = vec4(x1, y0, x2, y5); vRect1 = vec4(x0, y0, x0, y0);
    }
    else if(fDigit < 2.5) // 2
    {
        vRect0 = vec4(x0, y0, x3, y5); vRect1 = vec4(x0, y3, x2, y4); vRect2 = vec4(x1, y1, x3, y2);
    }
    else if(fDigit < 3.5) // 3
    {
        vRect0 = vec4(x0, y0, x3, y5); vRect1 = vec4(x0, y3, x2, y4); vRect2 = vec4(x0, y1, x2, y2);
    }
    else if(fDigit < 4.5) // 4
    {
        vRect0 = vec4(x0, y1, x2, y5); vRect1 = vec4(x1, y2, x2, y5); vRect2 = vec4(x2, y0, x3, y3);
    }
    else if(fDigit < 5.5) // 5
    {
        vRect0 = vec4(x0, y0, x3, y5); vRect1 = vec4(x1, y3, x3, y4); vRect2 = vec4(x0, y1, x2, y2);
    }
    else if(fDigit < 6.5) // 6
    {
        vRect0 = vec4(x0, y0, x3, y5); vRect1 = vec4(x1, y3, x3, y4); vRect2 = vec4(x1, y1, x2, y2);
    }
    else if(fDigit < 7.5) // 7
    {
        vRect0 = vec4(x0, y0, x3, y5); vRect1 = vec4(x0, y0, x2, y4);
    }
    else if(fDigit < 8.5) // 8
    {
        vRect0 = vec4(x0, y0, x3, y5); vRect1 = vec4(x1, y1, x2, y2); vRect2 = vec4(x1, y3, x2, y4);
    }
    else if(fDigit < 9.5) // 9
    {
        vRect0 = vec4(x0, y0, x3, y5); vRect1 = vec4(x1, y3, x2, y4); vRect2 = vec4(x0, y1, x2, y2);
    }
    else if(fDigit < 10.5) // '.'
    {
        vRect0 = vec4(x1, y0, x2, y1);
    }
    else if(fDigit < 11.5) // '-'
    {
        vRect0 = vec4(x0, y2, x3, y3);
    }   
    
    float fResult = InRect(vUV, vRect0) + InRect(vUV, vRect1) + InRect(vUV, vRect2);
    
    return mod(fResult, 2.0);
}

#else

float SampleDigit(const in float fDigit, const in vec2 vUV)
{       
    if(vUV.x < 0.0) return 0.0;
    if(vUV.y < 0.0) return 0.0;
    if(vUV.x >= 1.0) return 0.0;
    if(vUV.y >= 1.0) return 0.0;
    
    // In this version, each digit is made up of a 4x5 array of bits
    
    float fDigitBinary = 0.0;
    
    if(fDigit < 0.5) // 0
    {
        fDigitBinary = 7.0 + 5.0 * 16.0 + 5.0 * 256.0 + 5.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 1.5) // 1
    {
        fDigitBinary = 2.0 + 2.0 * 16.0 + 2.0 * 256.0 + 2.0 * 4096.0 + 2.0 * 65536.0;
    }
    else if(fDigit < 2.5) // 2
    {
        fDigitBinary = 7.0 + 1.0 * 16.0 + 7.0 * 256.0 + 4.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 3.5) // 3
    {
        fDigitBinary = 7.0 + 4.0 * 16.0 + 7.0 * 256.0 + 4.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 4.5) // 4
    {
        fDigitBinary = 4.0 + 7.0 * 16.0 + 5.0 * 256.0 + 1.0 * 4096.0 + 1.0 * 65536.0;
    }
    else if(fDigit < 5.5) // 5
    {
        fDigitBinary = 7.0 + 4.0 * 16.0 + 7.0 * 256.0 + 1.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 6.5) // 6
    {
        fDigitBinary = 7.0 + 5.0 * 16.0 + 7.0 * 256.0 + 1.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 7.5) // 7
    {
        fDigitBinary = 4.0 + 4.0 * 16.0 + 4.0 * 256.0 + 4.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 8.5) // 8
    {
        fDigitBinary = 7.0 + 5.0 * 16.0 + 7.0 * 256.0 + 5.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 9.5) // 9
    {
        fDigitBinary = 7.0 + 4.0 * 16.0 + 7.0 * 256.0 + 5.0 * 4096.0 + 7.0 * 65536.0;
    }
    else if(fDigit < 10.5) // '.'
    {
        fDigitBinary = 2.0 + 0.0 * 16.0 + 0.0 * 256.0 + 0.0 * 4096.0 + 0.0 * 65536.0;
    }
    else if(fDigit < 11.5) // '-'
    {
        fDigitBinary = 0.0 + 0.0 * 16.0 + 7.0 * 256.0 + 0.0 * 4096.0 + 0.0 * 65536.0;
    }
    
    vec2 vPixel = floor(vUV * vec2(4.0, 5.0));
    float fIndex = vPixel.x + (vPixel.y * 4.0);
    
    return mod(floor(fDigitBinary / pow(2.0, fIndex)), 2.0);
}

#endif

float PrintValue(const in vec2 vStringCharCoords, const in float fValue, const in float fMaxDigits, const in float fDecimalPlaces)
{
    float fAbsValue = abs(fValue);
    
    float fStringCharIndex = floor(vStringCharCoords.x);
    
    float fLog10Value = log2(fAbsValue) / log2(10.0);
    float fBiggestDigitIndex = max(floor(fLog10Value), 0.0);
    
    // This is the character we are going to display for this pixel
    float fDigitCharacter = kCharBlank;
    
    float fDigitIndex = fMaxDigits - fStringCharIndex;
    if(fDigitIndex > (-fDecimalPlaces - 1.5))
    {
        if(fDigitIndex > fBiggestDigitIndex)
        {
            if(fValue < 0.0)
            {
                if(fDigitIndex < (fBiggestDigitIndex+1.5))
                {
                    fDigitCharacter = kCharMinus;
                }
            }
        }
        else
        {       
            if(fDigitIndex == -1.0)
            {
                if(fDecimalPlaces > 0.0)
                {
                    fDigitCharacter = kCharDecimalPoint;
                }
            }
            else
            {
                if(fDigitIndex < 0.0)
                {
                    // move along one to account for .
                    fDigitIndex += 1.0;
                }

                float fDigitValue = (fAbsValue / (pow(10.0, fDigitIndex)));

                // This is inaccurate - I think because I treat each digit independently
                // The value 2.0 gets printed as 2.09 :/
                //fDigitCharacter = mod(floor(fDigitValue), 10.0);
                fDigitCharacter = mod(floor(0.0001+fDigitValue), 10.0); // fix from iq
            }       
        }
    }

    vec2 vCharPos = vec2(fract(vStringCharCoords.x), vStringCharCoords.y);

    return SampleDigit(fDigitCharacter, vCharPos);  
}

float PrintValue(in vec2 fragCoord, const in vec2 vPixelCoords, const in vec2 vFontSize, const in float fValue, const in float fMaxDigits, const in float fDecimalPlaces)
{
    return PrintValue((fragCoord.xy - vPixelCoords) / vFontSize, fValue, fMaxDigits, fDecimalPlaces);
}

float GetCurve(float x)
{
    return sin( x * 3.14159 * 4.0 );
}

float GetCurveDeriv(float x) 
{ 
    return 3.14159 * 4.0 * cos( x * 3.14159 * 4.0 ); 
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 vColour = vec3(0.0);

    // Multiples of 4x5 work best
    vec2 vFontSize = vec2(8.0, 15.0);

    // Draw Horizontal Line
    if(abs(fragCoord.y - iResolution.y * 0.5) < 1.0)
    {
        vColour = vec3(0.25);
    }
    
    // Draw Sin Wave
    // See the comment from iq or this page
    // http://www.iquilezles.org/www/articles/distance/distance.htm
    float fCurveX = fragCoord.x / iResolution.x;
    float fSinY = (GetCurve(fCurveX) * 0.25 + 0.5) * iResolution.y;
    float fSinYdX = (GetCurveDeriv(fCurveX) * 0.25) * iResolution.y / iResolution.x;
    float fDistanceToCurve = abs(fSinY - fragCoord.y) / sqrt(1.0+fSinYdX*fSinYdX);
    float fSetPixel = fDistanceToCurve - 1.0; // Add more thickness
    vColour = mix(vec3(1.0, 0.0, 0.0), vColour, clamp(fSetPixel, 0.0, 1.0));    

    // Draw Sin Value   
    float fValue4 = GetCurve(iMouse.x / iResolution.x);
    float fPixelYCoord = (fValue4 * 0.25 + 0.5) * iResolution.y;
    
    // Plot Point on Sin Wave
    float fDistToPointA = length( vec2(iMouse.x, fPixelYCoord) - fragCoord.xy) - 4.0;
    vColour = mix(vColour, vec3(0.0, 0.0, 1.0), (1.0 - clamp(fDistToPointA, 0.0, 1.0)));
    
    // Plot Mouse Pos
    float fDistToPointB = length( vec2(iMouse.x, iMouse.y) - fragCoord.xy) - 4.0;
    vColour = mix(vColour, vec3(0.0, 1.0, 0.0), (1.0 - clamp(fDistToPointB, 0.0, 1.0)));
    
    // Print Sin Value
    vec2 vPixelCoord4 = vec2(iMouse.x, fPixelYCoord) + vec2(4.0, 4.0);
    float fDigits = 1.0;
    float fDecimalPlaces = 2.0;
    float fIsDigit4 = PrintValue(fragCoord, vPixelCoord4, vFontSize, fValue4, fDigits, fDecimalPlaces);
    vColour = mix( vColour, vec3(0.0, 0.0, 1.0), fIsDigit4);
    
    // Print Shader Time
    vec2 vPixelCoord1 = vec2(96.0, 5.0);
    float fValue1 = iGlobalTime;
    fDigits = 6.0;
    float fIsDigit1 = PrintValue(fragCoord, vPixelCoord1, vFontSize, fValue1, fDigits, fDecimalPlaces);
    vColour = mix( vColour, vec3(0.0, 1.0, 1.0), fIsDigit1);

    // Print Date
    vColour = mix( vColour, vec3(1.0, 1.0, 0.0), PrintValue(fragCoord, vec2(0.0, 5.0), vFontSize, iDate.x, 4.0, 0.0));
    vColour = mix( vColour, vec3(1.0, 1.0, 0.0), PrintValue(fragCoord, vec2(0.0 + 48.0, 5.0), vFontSize, iDate.y + 1.0, 2.0, 0.0));
    vColour = mix( vColour, vec3(1.0, 1.0, 0.0), PrintValue(fragCoord, vec2(0.0 + 72.0, 5.0), vFontSize, iDate.z, 2.0, 0.0));

    // Draw Time
    vColour = mix( vColour, vec3(1.0, 0.0, 1.0), PrintValue(fragCoord, vec2(184.0, 5.0), vFontSize, mod(iDate.w / (60.0 * 60.0), 12.0), 2.0, 0.0));
    vColour = mix( vColour, vec3(1.0, 0.0, 1.0), PrintValue(fragCoord, vec2(184.0 + 24.0, 5.0), vFontSize, mod(iDate.w / 60.0, 60.0), 2.0, 0.0));
    vColour = mix( vColour, vec3(1.0, 0.0, 1.0), PrintValue(fragCoord, vec2(184.0 + 48.0, 5.0), vFontSize, mod(iDate.w, 60.0), 2.0, 0.0));
    
    if(iMouse.x > 0.0)
    {
        // Print Mouse X
        vec2 vPixelCoord2 = iMouse.xy + vec2(-52.0, 6.0);
        float fValue2 = iMouse.x / iResolution.x;
        fDigits = 1.0;
        fDecimalPlaces = 3.0;
        float fIsDigit2 = PrintValue(fragCoord, vPixelCoord2, vFontSize, fValue2, fDigits, fDecimalPlaces);
        vColour = mix( vColour, vec3(0.0, 1.0, 0.0), fIsDigit2);
        
        // Print Mouse Y
        vec2 vPixelCoord3 = iMouse.xy + vec2(0.0, 6.0);
        float fValue3 = iMouse.y / iResolution.y;
        fDigits = 1.0;
        float fIsDigit3 = PrintValue(fragCoord, vPixelCoord3, vFontSize, fValue3, fDigits, fDecimalPlaces);
        vColour = mix( vColour, vec3(0.0, 1.0, 0.0), fIsDigit3);
    }
    
    fragColor = vec4(vColour,1.0);
}