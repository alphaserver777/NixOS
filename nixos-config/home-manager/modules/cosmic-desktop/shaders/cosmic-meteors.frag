#version 320 es
precision highp float;
uniform float u_time;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.y;
    vec2 bounds = u_resolution / u_resolution.y;
    vec3 color = vec3(0.012, 0.018, 0.044);
    vec2 cells = uv * 90.0;
    float seed = fract(sin(dot(floor(cells), vec2(127.1, 311.7))) * 43758.5453);
    float star = 1.0 - smoothstep(0.035, 0.13, length(fract(cells) - 0.5));
    color += vec3(0.54, 0.65, 0.94) * star * step(0.985, seed) * 0.55;
    vec2 direction = normalize(vec2(-1.0, -0.58));
    vec2 normal = vec2(-direction.y, direction.x);
    for (int i = 0; i < 6; i++) {
        float f = float(i);
        float phase = fract(u_time * 0.075 + f * 0.173);
        vec2 head = vec2(bounds.x * (0.20 + fract(f * 0.618)), 1.25)
                  + direction * phase * (bounds.x + 1.2);
        vec2 delta = uv - head;
        float along = dot(delta, direction);
        float across = abs(dot(delta, normal));
        float tail = exp(-across * 650.0) * exp(min(along, 0.0) * 9.0)
                   * step(along, 0.0) * smoothstep(0.0, 0.08, phase)
                   * (1.0 - smoothstep(0.82, 1.0, phase));
        color += mix(vec3(0.32, 0.57, 1.0), vec3(0.70, 0.43, 0.94), f / 5.0) * tail;
    }
    fragColor = vec4(color / (1.0 + color * 0.3), 1.0);
}
