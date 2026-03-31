shader_type spatial;
render_mode unshaded, cull_front;

// ================================================================
// CIELO (Gradiente)
// ================================================================
uniform vec4 sky_top_color : source_color = vec4(0.2, 0.4, 0.8, 1.0);      // Color del cenit
uniform vec4 sky_horizon_color : source_color = vec4(0.6, 0.7, 0.9, 1.0); // Color del horizonte
uniform float sky_curve : hint_range(0.1, 1.0) = 0.3;                      // Curva del gradiente

// ================================================================
// SUELO (Parte inferior)
// ================================================================
uniform vec4 ground_color : source_color = vec4(0.3, 0.25, 0.2, 1.0);      // Color del suelo
uniform float ground_fade : hint_range(0.1, 0.8) = 0.2;                    // Qué tan arriba llega el suelo

// ================================================================
// SOL (Direccional)
// ================================================================
uniform vec3 sun_direction : source_color = vec3(0.0, 1.0, 0.0);           // Dirección del sol (normalizada)
uniform vec4 sun_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);         // Color del sol
uniform float sun_size : hint_range(0.01, 0.3) = 0.05;                     // Tamaño del disco solar
uniform float sun_intensity : hint_range(0.5, 3.0) = 1.2;                  // Intensidad del sol
uniform float sun_glow_size : hint_range(0.1, 1.0) = 0.3;                  // Tamaño del resplandor

// ================================================================
// NUBES
// ================================================================
uniform sampler2D cloud_noise : source_color;                              // Textura de ruido para nubes
uniform sampler2D cloud_detail : source_color;                             // Textura de detalle para nubes
uniform float cloud_density : hint_range(0.5, 2.0) = 1.2;                  // Densidad de nubes
uniform float cloud_coverage : hint_range(0.3, 1.2) = 0.8;                 // Cobertura general
uniform float cloud_speed : hint_range(0.0, 0.5) = 0.05;                   // Velocidad de movimiento
uniform float cloud_direction : hint_range(-1, 1) = 0.4;  // Dirección del viento
uniform float cloud_height : hint_range(0.2, 0.8) = 0.4;                   // Altura de la capa de nubes
uniform float cloud_sharpness : hint_range(1.0, 4.0) = 2.0;                // Nitidez de las nubes

// ================================================================
// ESTRELLAS (opcional, para noche)
// ================================================================
uniform bool stars_enabled = false;
uniform sampler2D starfield;                                               // Textura de estrellas
uniform float star_intensity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// ============================================================
    // 1. DIRECCIÓN DE VISIÓN (coordenadas del fragmento)
    // ============================================================
    // Normalizamos la dirección desde la cámara hasta el punto actual
    vec3 view_dir = normalize(VERTEX - CAMERA_POSITION_WORLD);
    
    // Ángulo vertical (Y) para determinar si miramos arriba o abajo
    float vertical_angle = view_dir.y;
    
    // ============================================================
    // 2. GRADIENTE DE CIELO (basado en la altura)
    // ============================================================
    // Convertimos el ángulo vertical a un factor 0-1
    // 1.0 = arriba (cenit), 0.0 = horizonte
    float t = clamp(vertical_angle, 0.0, 1.0);
    t = pow(t, sky_curve); // Aplicamos curva
    
    // Mezclamos colores de cielo
    vec3 sky_gradient = mix(sky_horizon_color.rgb, sky_top_color.rgb, t);
    
    // ============================================================
    // 3. SUELO (si miramos hacia abajo)
    // ============================================================
    float ground_factor = 0.0;
    if (vertical_angle < ground_fade) {
        // Si miramos hacia abajo, calculamos factor de suelo
        ground_factor = 1.0 - clamp(vertical_angle / ground_fade, 0.0, 1.0);
    }
    
    // Mezclamos suelo con cielo
    vec3 base_color = mix(sky_gradient, ground_color.rgb, ground_factor);
    
    // ============================================================
    // 4. SOL (usando dirección fija)
    // ============================================================
    vec3 sun_dir_normalized = normalize(sun_direction);
    float sun_angle = dot(view_dir, sun_dir_normalized);
    
    // Disco solar
    float sun_disc = smoothstep(1.0 - sun_size, 1.0, sun_angle);
    
    // Resplandor alrededor del sol
    float sun_glow = pow(max(0.0, sun_angle), 5.0 / sun_glow_size);
    sun_glow = sun_glow * 0.3 * sun_intensity;
    
    // Añadimos sol al color base
    vec3 sun_contribution = sun_color.rgb * (sun_disc * sun_intensity + sun_glow);
    base_color = mix(base_color, sun_contribution, sun_disc * 2.0);
    
    // ============================================================
    // 5. NUBES (con movimiento)
    // ============================================================
    // Calculamos coordenadas UV esféricas para las nubes
    // Usamos la dirección horizontal (XZ) y limitamos la altura
    vec2 cloud_uv = view_dir.xz / (vertical_angle + 0.3); // +0.3 para evitar división por cero
    
    // Escalamos las coordenadas
    cloud_uv *= 1.5;
    
    // Añadimos movimiento basado en el tiempo
    vec2 movement = cloud_uv * TIME * cloud_speed;
    vec2 uv1 = cloud_uv + movement;
    vec2 uv2 = cloud_uv * 2.0 - movement * 0.5; // Segunda capa para detalle
    
    // Muestreamos las texturas de nubes
    float clouds_base = texture(cloud_noise, uv1).r;
    float clouds_detail = texture(cloud_detail, uv2).r;
    
    // Combinamos las capas
    float clouds = (clouds_base * 0.7 + clouds_detail * 0.3) * cloud_density;
    
    // Aplicamos cobertura (menos nubes cerca del horizonte)
    float horizon_mask = clamp(vertical_angle * 2.0, 0.0, 1.0);
    clouds = clouds * horizon_mask * cloud_coverage;
    
    // Aplicamos altura de nubes (máximo en cloud_height)
    float height_mask = 1.0 - abs(vertical_angle - cloud_height) * 3.0;
    height_mask = clamp(height_mask, 0.0, 1.0);
    clouds *= height_mask;
    
    // Ajustamos nitidez
    clouds = pow(clouds, cloud_sharpness);
    
    // Mezclamos nubes con el cielo (las nubes son más brillantes cerca del sol)
    float sun_near = pow(max(0.0, sun_angle), 2.0);
    vec3 cloud_tint = mix(base_color, sun_color.rgb, sun_near * 0.5);
    
    vec3 final_color = mix(base_color, cloud_tint, clouds);
    
    // ============================================================
    // 6. ESTRELLAS (opcional, activar para noche)
    // ============================================================
    if (stars_enabled && vertical_angle > 0.1) {
        // Coordenadas para estrellas (fijas, sin movimiento)
        vec2 star_uv = vec2(atan(view_dir.z, view_dir.x) / (2.0 * PI) + 0.5, 
                            acos(view_dir.y) / PI);
        
        float stars = texture(starfield, star_uv * 4.0).r;
        stars = stars * step(0.95, stars); // Solo puntos brillantes
        stars *= star_intensity * (1.0 - clouds); // Menos estrellas donde hay nubes
        
        final_color = mix(final_color, vec3(1.0, 1.0, 1.0), stars);
    }
    
    // ============================================================
    // 7. OUTPUT FINAL
    // ============================================================
    ALBEDO = final_color;
    EMISSION = final_color; // Para que se vea sin iluminación
}