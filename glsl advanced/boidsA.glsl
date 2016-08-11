#define BOID_DENSITY 0.01
#define NEIGHBOR_DIST 7
#define DESIRED_SEPERATION 5
#define MAX_SPEED 0.9
#define MAX_FORCE 0.05

#define PI 3.14159265359
#define NEIGHBOR_DIST_SQR (NEIGHBOR_DIST * NEIGHBOR_DIST)
#define DESIRED_SEPERATION_SQR (DESIRED_SEPERATION * DESIRED_SEPERATION)

float rand(vec2 co){

    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
    
}

void main(){

    vec2 uv = (gl_FragCoord.xy) / iResolution.xy;
    
    if(iFrame == 0)
    {
        if(rand(uv) > 1.0 - BOID_DENSITY)
        {
            float angle = rand(vec2(1.0, 1.0) - uv) * PI * 2.0;
            
            vec2 rot = vec2(cos(angle), sin(angle));
            
            gl_FragColor = vec4(gl_FragCoord.xy, rot);
        }
        else
        {
            gl_FragColor = vec4(0, 0, 0, 0);
        }
    }
    else
    {
        vec4 data = texture2D(iChannel0, uv);
        
        if(data.x > 0.001)
        {
            vec2 pos = data.xy;
            vec2 vel = data.zw;
            
            int nCount = 0;
            int sCount = 0;
            
            vec2 alignment = vec2(0, 0);
            vec2 cohesion = vec2(0, 0);
            vec2 seperation = vec2(0, 0);
            
            for(int i = -NEIGHBOR_DIST; i <= NEIGHBOR_DIST; i++)
            {
                for(int j = -NEIGHBOR_DIST; j <= NEIGHBOR_DIST; j++)
                {
                    if((i == 0 && j == 0) || (i * i + j * j > NEIGHBOR_DIST_SQR))
                        continue;
                    
                    vec2 coord = gl_FragCoord + vec2(float(i), float(j));

                    if(coord.x < -0.001)
                        coord.x = iResolution.x + coord.x;

                    if(coord.y < -0.001)
                        coord.y = iResolution.y + coord.y;

                    if(coord.x > iResolution.x)
                        coord.x = coord.x - iResolution.x;

                    if(coord.y > iResolution.y)
                        coord.y = coord.y - iResolution.y;

                    vec2 uv2 = coord / iResolution.xy;

                    vec4 data2 = texture2D(iChannel0, uv2);

                    if(data2.x > 0.001)
                    {
                        vec2 pos2 = data2.xy;
                        vec2 vel2 = data2.zw;
                        
                        vec2 toBoid = pos - pos2;
                        
                        float distSqr = dot(toBoid, toBoid); 
                        
                        if(distSqr < float(DESIRED_SEPERATION_SQR))
                        {
                            toBoid /= distSqr;
                            
                            seperation += toBoid;
                            sCount++;
                        }
                        
                        if(distSqr < float(NEIGHBOR_DIST_SQR))
                        {
                            alignment += vel2;
                            cohesion += pos2;
                            nCount++;
                        }
                    }
                }
            }
            
            if(nCount > 0)
            {
                cohesion /= float(nCount);
                
                vec2 s = vec2(0, 0);
                vec2 toTarget = cohesion - pos;
                float dist = length(toTarget);
                
                if(dist > 0.0)
                {
                    toTarget = normalize(toTarget);
                    
                    toTarget *= float(MAX_SPEED);
                    
                    s = toTarget - vel;
                    
                    float l = length(s);
                    
                    if(l > MAX_FORCE)
                        s *= MAX_FORCE / l;
                }
                
                cohesion = s;
                
                alignment = normalize(alignment);
                alignment *= float(MAX_SPEED);
                alignment -= vel;
                
                float l = length(alignment);
                
                if(l > MAX_FORCE)
                    alignment *= MAX_FORCE / l;
            }
            
            if(sCount > 0)
            {
                seperation = normalize(seperation);
                seperation *= float(MAX_SPEED);
                seperation -= vel;
                
                float l = length(seperation);
                
                if(l > MAX_FORCE)
                    seperation *= MAX_FORCE / l;
            }
            
            vec2 acc = alignment + seperation * 1.5 + cohesion;
            
            vel += acc;
            
            float l = length(vel);
                
            if(l > float(MAX_SPEED))
                vel *= float(MAX_SPEED) / l;
            
            pos += vel;
            
            if(pos.x < -0.001)
                pos.x += iResolution.x;
            
            if(pos.y < -0.001)
                pos.y += iResolution.y;
            
            if(pos.x > iResolution.x)
                pos.x -= iResolution.x;
            
            if(pos.y > iResolution.y)
                pos.y -= iResolution.y;
            
            gl_FragColor = vec4(pos, vel);
        }
        else
        {
            gl_FragColor = vec4(0, 0, 0, 0);
        }
    }
    
    if(iMouse.z > 0.0)
    {
        float dist = distance(iMouse.zw, gl_FragCoord);
        
        if(dist < 20.0)
        {
            if(rand(uv) > 0.5)
            {
                float angle = rand(vec2(1.0, 1.0) - uv) * PI * 2.0;

                vec2 rot = vec2(cos(angle), sin(angle));

                gl_FragColor = vec4(gl_FragCoord.xy, rot);
            }
        }  
    }
}