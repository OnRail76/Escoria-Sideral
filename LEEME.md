# ESCORIA SIDERAL V1.0.1
2026 Tony C. Ware · ZX Spectrum 48K · Gold Master (FIX 3 aprobado en Fuse)

**El universo también tiene basura…**

Ejecutar `JUEGO/ESCORIA_SIDERAL_V1.0.1.tap` en modo 48K. LOAD "", beep, SPACE o FIRE. En el título, SPACE selecciona teclado (QAOP + SPACE); FIRE selecciona Kempston y teclado. Soltar SPACE antes de la multicarga. Cinco fases.

## Cambios V1.0.1
- Director exclusivamente frontal: hasta cuatro enemigos, sin entradas traseras.
- Meteoritos y relámpagos posicionales: frenar, avanzar o retroceder; sin persecución del jugador.
- Protección contra BREAK por SPACE mantenido en la multicarga.
- Selección de control al inicio y filtrado de Kempston contra lecturas espurias.
- Fondos estáticos, sin parallax; bancos gráficos, jefes y audio intactos.

## Contenido
- `DOCUMENTACION/`: manual, atlas y memoria (24 páginas), portada original e historia.
- `FUENTES/`: generador, ensamblador, dependencias, pruebas y registros. Los tests históricos no equivalen a regresión completa.
- `RECURSOS/`: bancos gráficos y archivo de diseño.
- `CAPTURAS/`: capturas reales de referencia V1.0 y alfas, conservadas.

## Gold Master
93.481 bytes · 28 bloques TAP · SHA-256 `df2d7b596060ee42a675de0b748e14e2aa2ce9d8be9a2308e7f538df1240766e`. Idéntico byte a byte al FIX 3 aprobado. Desde FUENTES: `python3 build_release.py` (Python 3 + Pillow).

## Autoría
2026 Tony C. Ware. Se conserva la licencia del repositorio y los derechos de los recursos artísticos.
