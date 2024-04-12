uniform float uTime;
uniform vec4 uResolution;
uniform sampler2D uMatcapOne;
uniform sampler2D uMatcapTwo;
uniform vec2 uMouse;
uniform float uProgress;

varying vec2 vUv;

float PI = 3.1415926533589793238;

mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec2 getMatcap(vec3 eye, vec3 normal) {
    vec3 reflected = reflect(eye, normal);
    float m = 2.8284271247461903 * sqrt( reflected.z+1.0 );
    return reflected.xy / m + 0.5;
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
	mat4 m = rotationMatrix(axis, angle);
	return (m * vec4(v, 1.0)).xyz;
}

float smin(float a, float b, float k){
    float h = clamp(.5 + .5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sdSphere(vec3 p, float r){
    return length(p) - r;
}

float random(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec2 sineDistanceFunction(vec3 p){
    float type = 0.0;
    vec3 p1 = rotate(p, vec3(1.0), uTime/5.0);
    float size = 0.3 + 0.1 * sin(uTime * 3.0) + 0.2 * sin(uTime / 6.0) + 0.05 * sin(uTime);
    float box = smin(sdBox(p1, vec3(.2)), sdSphere(p, .2), size);

    float realSphere = sdSphere(p1, .3);
    float final = mix(box, realSphere, .5 + .5 * sin(uTime / 2.0));


    for(float i = 0.0; i < 10.0; i++){
        float randOffset = random(vec2(i, 0.0));
        float progress = 1.0 - fract(uTime * .8 + randOffset * 3.0);
        vec3 posDir = vec3(sin(randOffset*2.0*PI), cos(randOffset*2.0*PI), 0.0);
        float goToCenter = sdSphere(p - posDir * progress, .1 * sin(PI * progress));
        final = smin(final, goToCenter, .3);
    }

    float mouseSphere = sdSphere(p - vec3(uMouse * uResolution.zw * 2.0, 0.), .1 + .1 * sin(uTime));

    if(mouseSphere < final){
        type = 1.0;
    }

    return vec2(smin(final, mouseSphere, .4), type);
}

vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3(sineDistanceFunction(p+h.xyy).x - sineDistanceFunction(p-h.xyy).x,
                            sineDistanceFunction(p+h.yxy).x - sineDistanceFunction(p-h.yxy).x,
                            sineDistanceFunction(p+h.yyx).x - sineDistanceFunction(p-h.yyx).x ) );
}

void main(){
    float dist = length(vUv - vec2(.5));
    vec3 bg = mix(vec3(.3), vec3(.0), dist);

    vec2 newUv = (vUv - vec2(.5)) * uResolution.zw + vec2(.5);
    vec3 camPos = vec3(0.0, 0.0, 2.0);
    vec3 ray = normalize(vec3((vUv - vec2(.5)) * uResolution.zw, -1.0));

    vec3 rayPos = camPos;
    float t = 0.0;
    float tMax = 5.0;
    float type = -1.0;

    for(int i = 0 ; i < 256 ; ++i){
        vec3 pos = camPos + t*ray;
        float h = sineDistanceFunction(pos).x;
        type = sineDistanceFunction(pos).y;
        
        if(h<.0001 || t>tMax){
            break;
        }

        t+=h;
    }

    vec3 color = bg;
    if(t<tMax){
        vec3 pos = camPos + t*ray;
        color = vec3(1.0);
        vec3 normal = calcNormal(pos);
        color = normal;
        float diff = dot(vec3(1.0), normal);
        vec2 matcapUv = getMatcap(ray, normal);
        color = vec3(diff);

        if(type < .5){
            color = texture2D(uMatcapOne, matcapUv).rgb;
        }else{
            color = texture2D(uMatcapTwo, matcapUv).rgb;
        }


        float fresnel = pow(1.0 + dot(ray, normal), 3.0);

        color = mix(color, bg, fresnel);
    }

    gl_FragColor = vec4(color, 1.0);
}