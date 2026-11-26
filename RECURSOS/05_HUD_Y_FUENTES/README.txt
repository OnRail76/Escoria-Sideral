ZX Spectrum 48K - HUD 256x24, y=168..191. Blanco brillante sobre negro, atributo $47.
HUD fijo, no desplazar con el escenario. hud_base.bin: filas lineales, 32 bytes por fila. hud_base_tiles.bin: 96 caracteres, 8 bytes cada uno, orden fila de caracteres. hud.bin contiene ejemplo.
Fuente 8x8, 8 bytes por glifo, bit 7 izquierda. ASCII 32..95 (huecos sin dibujo), luego ÁÉÍÓÚÜÑ. Convertir minúsculas a mayúsculas.
Campos editables: PUNTOS x16 6 dígitos, VIDAS x120 2 dígitos, FASE x200 2 dígitos; todos y181. Dibujar fuente a nivel de pixel (y no alineada a carácter).
SCR de demostración completo, 6912 bytes. Sin rutina de dibujado ni prueba en emulador.
