#version 320 es
precision highp float;
uniform float u_time;
uniform vec2 u_resolution;

// Четыре световые ленты без объёмного расчёта и дополнительных текстур.
void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    float t = u_time * 0.12;
    vec3 color = mix(vec3(0.015, 0.022, 0.055), vec3(0.025, 0.045, 0.095), uv.y);
    for (int i = 0; i < 4; i++) {
        float f = float(i);
        float ribbon = 0.40 + f * 0.08 + 0.12 * sin(uv.x * 4.0 + t + f)
                     + 0.045 * sin(uv.x * 11.0 - t * 1.4 + f * 2.0);
        float d = uv.y - ribbon;
        float glow = exp(-abs(d) * 16.0) * (0.45 + 0.22 * sin(uv.x * 22.0 + t + f));
        vec3 tint = mix(vec3(0.13, 0.73, 0.60), vec3(0.46, 0.29, 0.85), f / 3.0);
        color += tint * glow * 0.24;
    }
    vec2 cell = floor(uv * vec2(180.0, 100.0));
    float seed = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
    float dotStar = 1.0 - smoothstep(0.03, 0.12, length(fract(uv * vec2(180.0, 100.0)) - 0.5));
    color += vec3(0.62, 0.71, 0.95) * dotStar * step(0.985, seed)
           * (0.45 + 0.22 * sin(u_time * 0.7 + seed * 90.0));
    color *= 0.7 + 0.3 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.18);
    fragColor = vec4(color, 1.0);
}
