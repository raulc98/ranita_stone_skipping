shader_type canvas_item;

// Parámetros personalizables
uniform float wave_speed = 0.5;
uniform float wave_height = 0.02;
uniform float wave_frequency = 8.0;
uniform float foam_intensity = 0.3;
uniform vec4 water_color : source_color = vec4(0.2, 0.4, 0.8, 0.7);
uniform vec4 foam_color : source_color = vec4(0.9, 0.95, 1.0, 0.9);
uniform float edge_thickness = 0.01;
uniform float time_scale = 1.0;

// Texturas de ruido para efecto manga
uniform sampler2D noise_tex : source_color;
uniform float noise_scale = 4.0;

// Parámetros para ondas de colisión
uniform sampler2D collision_map;
uniform vec2 collision_resolution = vec2(256.0, 256.0);
uniform float collision_decay = 0.95;
uniform float collision_wave_speed = 2.0;

// Variables para el efecto de dibujo
uniform float posterize_levels = 4.0;
uniform float outline_threshold = 0.3;
uniform vec4 outline_color : source_color = vec4(0.1, 0.2, 0.4, 1.0);

// Función para generar ruido suave
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Función para ondas de Gerstner (más realistas)
vec2 gerstner_wave(vec2 pos, float time, float amplitude, float frequency, float speed, vec2 direction) {
    float phase = speed * frequency;
    float theta = dot(direction, pos) * frequency + time * phase;
    float cos_theta = cos(theta);
    float sin_theta = sin(theta);
    
    return direction * amplitude * sin_theta;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * time_scale;
    
    // Generar ondas base
    vec2 wave_uv = uv;
    
    // Ondas múltiples para efecto más orgánico
    vec2 wave1 = gerstner_wave(wave_uv, time, wave_height, wave_frequency * 0.7, wave_speed, normalize(vec2(1.0, 0.5)));
    vec2 wave2 = gerstner_wave(wave_uv, time, wave_height * 0.7, wave_frequency * 1.2, wave_speed * 1.3, normalize(vec2(-0.7, 0.3)));
    vec2 wave3 = gerstner_wave(wave_uv, time, wave_height * 0.5, wave_frequency * 1.8, wave_speed * 0.7, normalize(vec2(0.3, -0.8)));
    
    wave_uv += wave1 + wave2 + wave3;
    
    // Ruido para textura de manga
    float n = texture(noise_tex, wave_uv * noise_scale).r;
    n += noise(wave_uv * 10.0) * 0.2;
    
    // Leer mapa de colisiones
    vec2 collision_uv = SCREEN_UV;
    vec4 collision_data = texture(collision_map, collision_uv);
    float collision_strength = collision_data.r;
    
    // Aplicar ondas de colisión
    if (collision_strength > 0.01) {
        float collision_wave = sin(length(uv - 0.5) * 20.0 - time * collision_wave_speed) * collision_strength;
        n += collision_wave * foam_intensity;
        
        // Crear espuma en el centro de la colisión
        float foam_center = smoothstep(0.3, 0.1, length(uv - collision_data.gb)) * collision_strength;
        n += foam_center * 0.5;
    }
    
    // Posterizar para efecto manga
    float posterized = floor(n * posterize_levels) / posterize_levels;
    
    // Crear bordes de dibujo
    float edge = 1.0 - smoothstep(0.0, outline_threshold, abs(posterized - 0.5));
    
    // Mezclar colores
    vec4 base_color = water_color;
    vec4 final_color = mix(base_color, foam_color, posterized * foam_intensity);
    
    // Añadir bordes de dibujo
    final_color = mix(final_color, outline_color, edge);
    
    // Añadir sombras de manga
    float shadow = smoothstep(0.3, 0.7, uv.y);
    final_color.rgb *= (1.0 - shadow * 0.3);
    
    // Patrón de líneas para efecto de dibujo
    float line_pattern = step(0.5, sin(uv.y * 100.0 + time * 2.0) * 0.5 + 0.5);
    final_color.rgb *= (1.0 - line_pattern * 0.1);
    
    COLOR = final_color;
    
    // Transparencia en los bordes
    float edge_alpha = smoothstep(0.0, edge_thickness, min(uv.x, min(uv.y, min(1.0 - uv.x, 1.0 - uv.y))));
    COLOR.a *= edge_alpha;
}