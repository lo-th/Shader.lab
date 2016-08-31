
// ------------------ channel define
// 0_# bufferFULL_lostA #_0
// ------------------

// Physics parameters
#define GRAVITY vec3 (0.0, -3.0, 0.0) // Feel free to comment this out to explore the maze freely :)

// Math constants
#define DELTA   0.002
#define PI      3.14159265359

// Element
struct Element {
    vec3 position;
    vec3 speed;
    vec3 force;
    float friction;
    float radius;
    float elasticity;
};

// Head
struct Head {
    Element element;
    mat3 orientation;
    float forceOrientation;
};

// Light ball
struct LightBall {
    Element element;
    float aheadDistance;
    float movementAmplitude;
    float forceSpringStiffness;
    float forceMaxSqr;
    float collisionTimer;
    float collisionTimerMax;
};

// PRNG (predictable)
float randPredictable (in vec3 seed) {
    return fract (11.0 * sin (3.0 * seed.x + 5.0 * seed.y + 7.0 * seed.z));
}

// Check whether there is a block at a given position
float blockCheck (in vec3 blockPosition) {
    vec3 blockEven = mod (blockPosition, 2.0);
    float blockSum = blockEven.x + blockEven.y + blockEven.z;
    return max (step (blockSum, 1.5), step (blockSum, 2.5) * step (0.5, randPredictable (blockPosition))) *
        step (4.5, mod (blockPosition.x, 32.0)) *
        step (2.5, mod (blockPosition.y, 16.0)) *
        step (4.5, mod (blockPosition.z, 32.0));
}

// React to collisions
void collisionReact (inout Element element, in vec3 relativePosition) {

    // Compute the position relative to the actual hit point
    relativePosition -= 0.5 * sign (relativePosition);

    // Make sure there is a hit
    float distance = length (relativePosition);
    if (distance < element.radius) {

        // Compute the normalized direction of the hit
        relativePosition /= distance;

        // Upate the position
        distance -= element.radius;
        element.position -= relativePosition * distance;

        // Update the speed
        element.speed -= (1.0 + element.elasticity) * dot (element.speed, relativePosition) * relativePosition;
    }
}

// Detect collisions (here, "element" is a sphere, and the environment is made of cubes)
void collisionDetect (inout Element element) {

    // Get the position of the current block
    vec3 blockPosition = floor (element.position + 0.5);

    // There is no collision if we are inside a block already
    if (blockCheck (blockPosition) > 0.5) {
        return;
    }

    // Compute the relative position within the block
    vec4 relativePosition = vec4 (element.position - blockPosition, 0.0);

    // Check whether we are close to a side of the current block
    vec3 check = step (0.5 - element.radius, abs (relativePosition.xyz));
    if (check.x + check.y + check.z < 0.5) {
        return;
    }

    // Prepare to check nearby blocks
    vec4 blockDelta = sign (relativePosition);

    // Handle collisions with the sides
    if (check.x > 0.5 && blockCheck (blockPosition + blockDelta.xww) > 0.5) {
        check.x = 0.0;
        collisionReact (element, relativePosition.xww);
    }
    if (check.y > 0.5 && blockCheck (blockPosition + blockDelta.wyw) > 0.5) {
        check.y = 0.0;
        collisionReact (element, relativePosition.wyw);
    }
    if (check.z > 0.5 && blockCheck (blockPosition + blockDelta.wwz) > 0.5) {
        check.z = 0.0;
        collisionReact (element, relativePosition.wwz);
    }

    // Take note of whether we have to check the collision with the corner
    float checkXYZ = check.x * check.y * check.z;

    // Handle collisions with the edges
    if (check.x * check.y > 0.5 && blockCheck (blockPosition + blockDelta.xyw) > 0.5) {
        checkXYZ = 0.0;
        collisionReact (element, relativePosition.xyw);
    }
    if (check.y * check.z > 0.5 && blockCheck (blockPosition + blockDelta.wyz) > 0.5) {
        checkXYZ = 0.0;
        collisionReact (element, relativePosition.wyz);
    }
    if (check.z * check.x > 0.5 && blockCheck (blockPosition + blockDelta.xwz) > 0.5) {
        checkXYZ = 0.0;
        collisionReact (element, relativePosition.xwz);
    }

    // Handle the collision with the corner
    if (checkXYZ > 0.5 && blockCheck (blockPosition + blockDelta.xyz) > 0.5) {
        collisionReact (element, relativePosition.xyz);
    }
}

// Handle movements
void move (inout Element element, in bool collide) {

    // Handle the friction
    element.force -= element.speed * element.friction;

    // Update the speed
    element.speed += element.force * iTimeDelta;

    // Compute the movement
    float speed = length (element.speed);
    float movementLength = speed * iTimeDelta;
    vec3 movementDirection = element.speed / speed;

    // Move towards the destination by small increments, to make sure we detect all collisions
    // Note: we could optimize this by going faster when within the inner part of a block, far from the sides
    // ...but this isn't really needed, so let's keep it simple
    if (collide && element.radius > 0.0) {
        for (int iteration = 0; iteration < 8; ++iteration) {
            if (movementLength > element.radius) {
                element.position += element.radius * movementDirection;
                movementLength -= element.radius;
                collisionDetect (element);
            }
        }
    }
    element.position += movementLength * movementDirection;
    if (collide) {
        collisionDetect (element);
    }
}

// Get the orientation of the head
mat3 headOrientationGet () {

    float yawAngle = 3.0 * PI * (iMouse.x / iResolution.x - 0.5);
    float pitchAngle = PI * (0.5 - iMouse.y / iResolution.y);

    float cosYaw = cos (yawAngle);
    float sinYaw = sin (yawAngle);
    float cosPitch = cos (pitchAngle);
    float sinPitch = sin (pitchAngle);

    mat3 headOrientation;
    headOrientation [0] = vec3 (cosYaw, 0.0, -sinYaw);
    headOrientation [1] = vec3 (sinYaw * sinPitch, cosPitch, cosYaw * sinPitch);
    headOrientation [2] = vec3 (sinYaw * cosPitch, -sinPitch, cosYaw * cosPitch);
    return headOrientation;
}

// Main function
void mainImage (out vec4 fragColor, in vec2 fragCoord) {

    // Don't waste time...
    if (fragCoord.x > 5.0 || fragCoord.y > 1.0) {
        discard;
    }

    // Define the head
    Head head;
    head.element.friction = 1.0;
    head.element.radius = 0.1;
    head.element.elasticity = 0.5;
    head.forceOrientation = 2.0;

    // Define the light ball
    LightBall lightBall;
    lightBall.element.friction = 1.0;
    lightBall.element.radius = 0.03;
    lightBall.element.elasticity = 0.5;
    lightBall.aheadDistance = 0.5;
    lightBall.movementAmplitude = 0.1;
    lightBall.forceSpringStiffness = 15.0;
    lightBall.forceMaxSqr = 900.0;
    lightBall.collisionTimerMax = 5.0;

    // Initialize the position and speed of both the head and the light ball
    if (iFrame < 5) {
        head.element.position = vec3 (13.05, 1.5, 13.0);
        head.element.speed = vec3 (0.0);
        lightBall.element.position = vec3 (13.0, 1.0, 13.0);
        lightBall.element.speed = vec3 (0.0);
        lightBall.collisionTimer = 0.0;
    } else {
        head.element.position = texture2D (iChannel0, vec2 (0.5, 0.5) / iResolution.xy).xyz;
        head.element.speed = texture2D (iChannel0, vec2 (1.5, 0.5) / iResolution.xy).xyz;
        lightBall.element.position = texture2D (iChannel0, vec2 (2.5, 0.5) / iResolution.xy).xyz;
        vec4 data = texture2D (iChannel0, vec2 (3.5, 0.5) / iResolution.xy);
        lightBall.element.speed = data.xyz;
        lightBall.collisionTimer = data.w;
    }

    // Move the head
    head.orientation = headOrientationGet ();
    head.element.force = head.orientation [2] * head.forceOrientation;
    #ifdef GRAVITY
    float gravitySqr = dot (GRAVITY, GRAVITY);
    if (gravitySqr > DELTA) {
        head.element.force += (1.0 - dot (head.element.force, GRAVITY) / gravitySqr) * GRAVITY;
    }
    #endif
    move (head.element, true);

    // Move the light ball (using a spring force)
    vec3 lightBallPositionTarget = lightBall.movementAmplitude * vec3 (sin (iGlobalTime * 2.0), sin (iGlobalTime * 3.0), sin (iGlobalTime));
    lightBallPositionTarget.z += lightBall.aheadDistance;
    lightBallPositionTarget = head.element.position + head.orientation * lightBallPositionTarget;
    lightBall.element.force = (lightBallPositionTarget - lightBall.element.position) * lightBall.forceSpringStiffness;
    if (dot (lightBall.element.force, lightBall.element.force) < lightBall.forceMaxSqr) {
        lightBall.collisionTimer = 0.0;
    } else {
        lightBall.collisionTimer += iTimeDelta;
    }
    move (lightBall.element, lightBall.collisionTimer < lightBall.collisionTimerMax);

    // Store the data
    if (fragCoord.x < 1.0) {
        fragColor = vec4 (head.element.position, head.orientation [1].x);
    } else if (fragCoord.x < 2.0) {
        fragColor = vec4 (head.element.speed, 0.0);
    } else if (fragCoord.x < 3.0) {
        fragColor = vec4 (lightBall.element.position, head.orientation [1].y);
    } else if (fragCoord.x < 4.0) {
        fragColor = vec4 (lightBall.element.speed, lightBall.collisionTimer);
    } else {
        fragColor = vec4 (head.orientation [0], head.orientation [1].z);
    }
}