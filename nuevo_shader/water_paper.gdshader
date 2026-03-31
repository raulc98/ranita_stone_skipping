shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

// ─────────────────────────────────────────────
//  PARÁMETROS EDITABLES EN EL INSPECTOR
// ─────────────────────────────────────────────

// Colores del agua / papel
uniform vec4  water_color        : source_color = vec4(0.55, 0.78, 0.85, 0.92);
uniform vec4  paper_color        : source_color = vec4(0, 0, 0, 1.0);
uniform vec4  ripple_ink_color   : source_color = vec4(0.18, 0.22, 0.35, 1.0);

// Textura de ruido para rugosidad de papel
uniform sampler2D noise_texture  : hint_default_white, repeat_enable;
// Textura de ruido secundaria para las ondas (puede ser la misma)
uniform sampler2D ripple_noise   : hint_default_white, repeat_enable;

// Movimiento base del agua
uniform float wave_speed         = 0.6;
uniform float wave_scale         = 3.0;
uniform float wave_strength      = 0.04;   // cuánto se deforma la superficie

// Aspecto "papel"
uniform float paper_grain        = 0.35;   // intensidad del grano
uniform float paper_scale        = 6.0;

// Ondas de impacto  (hasta 8 simultáneas)
uniform vec2  ripple_pos[8];               // posición UV de cada onda
uniform float ripple_time[8];              // tiempo desde el impacto (segundos)
uniform float ripple_strength[8];          // intensidad (0-1)

// Configuración de ondas
uniform float ripple_speed       = 1.8;    // velocidad de expansión
uniform float ripple_duration    = 2.5;    // segundos hasta desvanecerse
uniform float ripple_thickness   = 0.025;  // grosor del anillo
uniform float ripple_wobble      = 0.18;   // irregularidad "rotulador"
uniform int   ripple_count       = 8;

// ─────────────────────────────────────────────
//  VARYING
// ─────────────────────────────────────────────
varying vec2 world_uv;

// ─────────────────────────────────────────────
//  UTILIDADES
// ─────────────────────────────────────────────

// Hash rápido
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Ruido suave 2D
float smooth_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// FBM para el movimiento orgánico del agua
float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v   += amp * smooth_noise(p);
		p   *= 2.1;
		amp *= 0.5;
	}
	return v;
}

// ─────────────────────────────────────────────
//  VERTEX
// ─────────────────────────────────────────────
void vertex() {
	world_uv = UV;

	// Pequeño desplazamiento vertical para simular la superficie ondulada
	float t   = TIME * wave_speed;
	vec2  uv2 = UV * wave_scale;
	float disp = fbm(uv2 + vec2(t, t * 0.7)) * 2.0 - 1.0;
	VERTEX.y  += disp * wave_strength;
}

// ─────────────────────────────────────────────
//  FRAGMENT
// ─────────────────────────────────────────────
void fragment() {
	vec2  uv = world_uv;
	float t  = TIME;

	// ── 1. Grano de papel ──────────────────────────────────────────────
	vec2  paper_uv    = uv * paper_scale;
	float grain_val   = texture(noise_texture, paper_uv).r;
	// Segunda octava para más detalle
	grain_val        += texture(noise_texture, paper_uv * 2.3 + vec2(0.5)).r * 0.5;
	grain_val        /= 1.5;
	float grain       = mix(1.0, grain_val, paper_grain);

	// ── 2. Movimiento base del agua (distorsión UV) ────────────────────
	vec2  wave_uv     = uv * wave_scale;
	float nx          = fbm(wave_uv + vec2(t * wave_speed, 0.0));
	float ny          = fbm(wave_uv + vec2(0.0, t * wave_speed * 0.8) + 4.7);
	vec2  distort     = vec2(nx, ny) * 0.06 - 0.03;

	// Color base del agua con distorsión + grano
	vec4  base_color  = mix(paper_color, water_color, 0.85);
	base_color.rgb   *= grain;

	// Leve variación de color por las ondas de fondo
	float water_var   = fbm((uv + distort) * 4.0 + t * 0.3);
	base_color.rgb   += (water_var - 0.5) * 0.06;

	// ── 3. Ondas de impacto con look "rotulador" ──────────────────────
	float ripple_mask = 0.4;

	for (int i = 0; i < ripple_count; i++) {
		float rt = ripple_time[i];
		float rs = ripple_strength[i];
		if (rs <= 0.0 || rt < 0.0) continue;

		// Radio actual de la onda
		float radius = rt * ripple_speed;

		// Distancia desde este fragmento al centro del impacto
		vec2  delta   = uv - ripple_pos[i];
		float dist    = length(delta);

		// ── Irregularidad tipo rotulador ──
		// Usamos el ángulo para desplazar el radio con ruido angulado
		float angle   = atan(delta.y, delta.x);
		// Ruido en coordenadas angulares
		vec2  ang_uv  = vec2(angle / 6.2832 + 0.5, rt * 0.4);
		float wobble  = texture(ripple_noise, ang_uv * vec2(3.0, 1.0)).r;
		// Segunda frecuencia para más textura de trazo
		wobble       += texture(ripple_noise, ang_uv * vec2(7.0, 2.0) + 0.3).r * 0.5;
		wobble       /= 1.5;
		wobble        = (wobble - 0.5) * ripple_wobble;

		float effective_dist = dist - wobble * radius;

		// Anillo: SDF suave del círculo
		float ring    = abs(effective_dist - radius) / ripple_thickness;
		ring          = 1.0 - smoothstep(0.0, 1.0, ring);

		// Fade-out con el tiempo
		float fade    = 1.0 - (rt / ripple_duration);
		fade          = max(0.0, fade);
		// Fade cuadrático para más naturalidad
		fade          = fade * fade;

		// Acumulamos (varias ondas pueden superponerse)
		ripple_mask  += ring * fade * rs;
	}
	ripple_mask = clamp(ripple_mask, 0.0, 1.0);

	// ── 4. Color final ────────────────────────────────────────────────
	// Las ondas dibujan el color de tinta sobre el agua
	vec3 final_rgb = mix(base_color.rgb, ripple_ink_color.rgb, ripple_mask);

	// Pequeño borde extra más oscuro en el pico del anillo (simula presión del rotulador)
	float ink_edge = ripple_mask * ripple_mask;
	final_rgb     *= 1.0 - ink_edge * 0.25;

	ALBEDO      = final_rgb;
	ALPHA       = mix(water_color.a, 1.0, ripple_mask * 0.3) * base_color.a;
	// Muy poca especularidad para look mate/papel
	ROUGHNESS   = 0.92 - ripple_mask * 0.3;
	METALLIC    = 0.0;
}
