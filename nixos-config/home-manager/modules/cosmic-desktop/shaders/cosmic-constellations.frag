#version 320 es
precision highp float;
uniform float u_time;
uniform vec2 u_resolution;

// Фиксированные звёзды; вращение общее. Нет тригонометрии внутри цикла.
const vec2 nodes[12] = vec2[12](
    vec2(-0.68, 0.14), vec2(-0.58, 0.28), vec2(-0.45, 0.11),
    vec2(-0.34, 0.26), vec2(-0.23, 0.12),
    vec2(0.02, -0.22), vec2(0.16, -0.10), vec2(0.30, -0.16),
    vec2(0.42, -0.04), vec2(0.66, -0.02), vec2(0.61, 0.16), vec2(0.39, 0.12)
);
const int links[12] = int[12](1, 2, 3, 4, 3, 6, 7, 8, 9, 10, 11, 8);

void main() {
    vec2 uv = (gl_FragCoord.xy - u_resolution * 0.5) / u_resolution.y;
    float angle = u_time * 0.012;
    uv = mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * uv;
    vec3 color = vec3(0.013, 0.019, 0.047);
    float pulse = 0.72 + 0.15 * sin(u_time * 0.35);
    for (int i = 0; i < 12; i++) {
        vec2 a = nodes[i];
        vec2 ab = nodes[links[i]] - a;
        vec2 delta = uv - a;
        vec2 fromLine = delta - ab * clamp(dot(delta, ab) / dot(ab, ab), 0.0, 1.0);
        float line = 1.0 - smoothstep(0.00000016, 0.00000225, dot(fromLine, fromLine));
        color += vec3(0.23, 0.37, 0.72) * line * pulse * 0.22;
        float d2 = dot(delta, delta);
        float point = 1.0 - smoothstep(0.000001, 0.000009, d2);
        float halo = exp(-d2 * 18000.0) * 0.16;
        color += vec3(0.69, 0.73, 1.0) * (point + halo) * pulse;
    }
    fragColor = vec4(color, 1.0);
}
