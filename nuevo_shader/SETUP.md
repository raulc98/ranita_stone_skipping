# 💧 Agua estilo Papel & Rotulador — Godot 4.4
## Guía de montaje

---

## Archivos del proyecto

| Archivo | Descripción |
|---|---|
| `water_paper.gdshader` | El shader principal |
| `WaterRippleController.gd` | Gestiona las ondas en el shader |
| `StoneThrowDemo.gd` | Demo de lanzamiento de piedras |

---

## 1. Preparar el shader

1. Crea una carpeta `shaders/` en `res://` y copia `water_paper.gdshader` dentro.
2. En el Inspector del `MeshInstance3D` del agua:
   - **Mesh** → `PlaneMesh` (ponle el tamaño que quieras, p.ej. 10×10)
   - **Material** → `New ShaderMaterial`
   - En el ShaderMaterial → **Shader** → selecciona `water_paper.gdshader`

---

## 2. Texturas necesarias

El shader necesita **2 texturas de ruido** (pueden ser la misma):

### Opción A — Usar el generador de Godot (recomendado)
1. Panel **FileSystem** → clic derecho → *New Resource* → `NoiseTexture2D`
2. Configura:
   - **Noise** → `FastNoiseLite`
   - Frequency: `0.05`, FractalOctaves: `4`
   - Width/Height: `512×512`
3. Asígnala a `noise_texture` **y** a `ripple_noise` en el ShaderMaterial.

### Opción B — Imagen PNG
Cualquier textura de ruido tileable en escala de grises (512×512 o 1024×1024).

---

## 3. Montar la escena

```
Node3D  (raíz)
├─ Camera3D
├─ DirectionalLight3D
│   (rotación aprox. -45°, -30°, 0°)
├─ WaterPlane  ← MeshInstance3D
│   ├─ ShaderMaterial (water_paper.gdshader)
│   └─ Script: WaterRippleController.gd
└─ WaterArea   ← Area3D  (opcional, para detección automática)
    └─ CollisionShape3D (BoxShape3D del mismo tamaño que el plano)
```

---

## 4. Parámetros del shader más importantes

### Apariencia "papel"
| Parámetro | Valor sugerido | Efecto |
|---|---|---|
| `paper_grain` | 0.2 – 0.5 | Más valor = más textura de papel |
| `paper_scale` | 4.0 – 8.0 | Escala del grano |
| `water_color` | azul/verde suave | Color base del agua |
| `paper_color` | crema/blanco roto | Color del papel |

### Ondas "rotulador"
| Parámetro | Valor sugerido | Efecto |
|---|---|---|
| `ripple_ink_color` | azul oscuro / tinta | Color del trazo |
| `ripple_wobble` | 0.1 – 0.3 | Irregularidad del anillo |
| `ripple_thickness` | 0.015 – 0.04 | Grosor del trazo |
| `ripple_speed` | 1.5 – 2.5 | Velocidad de expansión |
| `ripple_duration` | 2.0 – 4.0 | Tiempo hasta desvanecerse |

> ⚠️ Si cambias `ripple_duration` en el Inspector del shader,
> actualiza también la variable `ripple_duration` en `WaterRippleController.gd`.

---

## 5. Lanzar una onda desde código

```gdscript
# Desde cualquier script que tenga referencia al nodo del agua:
@onready var water = $WaterPlane  # tiene WaterRippleController.gd

# En el momento del impacto (posición en world space):
water.spawn_ripple(body.global_position, 1.0)
```

---

## 6. Conectar el Area3D (detección automática)

Si añades un `Area3D` llamado `WaterArea` con un `CollisionShape3D`:

```gdscript
# En StoneThrowDemo.gd (o en _ready de tu escena):
$WaterArea.body_entered.connect($WaterPlane._on_area_body_entered)
```

Los `RigidBody3D` que entren en el área generarán ondas automáticamente.

---

## 7. Tips para mejorar el look

- **Más ondas concéntricas**: Lanza varias ondas desde el mismo punto
  con un pequeño delay entre ellas (0.1 – 0.2 s) para simular los
  anillos múltiples del rebote de una piedra.

- **Variación de grosor**: Usa `ripple_wobble` alto (0.25+) para que los
  círculos parezcan trazados a mano de forma imperfecta.

- **Sombra del papel**: Añade una ligera `AmbientLight` cálida y una
  `DirectionalLight3D` a baja intensidad para que el grano del papel
  proyecte microsombras.

- **Post-process**: Un `WorldEnvironment` con `glow` muy bajo y
  saturación reducida termina de darle ese look de ilustración acuarela.

---

## Créditos

Shader y scripts creados para Godot 4.4.
Licencia MIT — úsalos libremente en tu proyecto.
