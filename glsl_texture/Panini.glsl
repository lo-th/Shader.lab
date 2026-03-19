
// ------------------ channel define
// 0_# cube_church #_0
// ------------------


// https://www.shadertoy.com/view/Nd3Bzl

#define PI 3.1415926

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, s, -s, c);
	return m * v;
}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll ){

    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );

}

void main() {

	 vec2 m = 2. * vec2(iMouse.xy - .5 * iResolution.xy) / iResolution.y;

    // Normalize fragment coordinates to a range of [-aspect, +aspect] and [-1, +1]
    vec2 uv = ((vUv * 2.0) - 1.0) * vec2( iResolution.z, 1.0 );

    // zoom
    uv *= exp(iWheel);

    // Fixed parameter for the Panini projection
    // k controls the "curvature" of the projection
    // Try other values (e.g. 1.5, 0.8, etc.) to see different Panini distortion strengths
    float k = 1.0;

    // -----------------------------------------------
    // Step 1: Solve for the intersection with the cylinder
    // -----------------------------------------------

    // Quadratic equation coefficients
    float A = uv.x * uv.x + (k + 1.0) * (k + 1.0);
    float B = k * (k + 1.0);
    float C = k * k - 1.0;

    // Solve the quadratic equation for t
    // t is the distance scaling factor to reach the cylinder surface
    float t = (B + sqrt(B * B - A * C)) / A;

    // -----------------------------------------------
    // Step 2: Compute the ray direction
    // -----------------------------------------------

    // The ray direction intersects the virtual cylinder at this point
    vec3 rayDirection = vec3(t * uv, t * (k + 1.0) - k);

    rayDirection.xz = rotate(rayDirection.xz,-0.5*PI);
    if (iMouse.x > 0.0) {
    	rayDirection.xy = rotate(rayDirection.xy,-PI*m.y);
        rayDirection.xz = rotate(rayDirection.xz,PI*m.x);
      //rayDirection.xy = rotate(rayDirection.xy,-PI*(2.0*iMouse.y-iResolution.y)/iResolution.y);
      //rayDirection.xz = rotate(rayDirection.xz,PI*(2.0*iMouse.x-iResolution.x)/iResolution.x);
    }

    // Auto rotation
    rayDirection.xz = rotate(rayDirection.xz,-0.25*iTime);

    // Normalize the ray direction to ensure proper sampling
    rayDirection = normalize(rayDirection);

    vec3 col = textureCube(iChannel0, rayDirection).rgb;

    // GRID
    float phi = asin(rayDirection.y)/PI;
	float nsteps = 12.0;
	phi *= nsteps ;
	col *= 0.6+0.4*smoothstep(0.0,fwidth(phi),abs(phi-round(phi)));
	float lambda = atan(rayDirection.x,rayDirection.z)/PI;
	float dlambda = fwidth(lambda);
	float lambda1 = mod(lambda,2.0);
	float dlambda1 = fwidth(lambda1);
	dlambda = dlambda1; 
	lambda *= nsteps; dlambda *= nsteps;
	col *= 0.6+0.4*smoothstep(0.0,dlambda,abs(lambda-round(lambda)));

	//

    gl_FragColor = vec4(col,1.0);
}