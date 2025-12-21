shader_type spatial;

render_mode blend_mix, cull_disabled;

// Color del agua - puedes ajustar estos valores
uniform vec4 water_color : source_color = vec4(0.1, 0.3, 0.5, 0.8);

// Control de olas
uniform float wave_speed = 0.5;
uniform float wave_height = 0.15;
uniform float wave_frequency = 2.0;

void vertex() {
    // Ondas simples
    float wave = sin(VERTEX.x * wave_frequency + TIME * wave_speed) * wave_height;
    wave += cos(VERTEX.z * wave_frequency * 0.8 + TIME * wave_speed * 0.7) * wave_height * 0.5;

    // Aplicar al vértice
    VERTEX.y += wave;
}

void fragment() {
    // Color base
    ALBEDO = water_color.rgb;

    // Transparencia
    ALPHA = water_color.a;

    // Propiedades de reflexión
    METALLIC = 0.1;
    ROUGHNESS = 0.2;
}