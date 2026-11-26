SOLDADO ZX SPECTRUM 48K

Adaptacion raster del diseno generado. 25 poses por direccion, 50 fotogramas totales.
32x32 (4x4 caracteres), 1 bit. Ancla nominal (16,31), pies normalizados; el motor controla el salto.
Orden: run 5, idle 1, aim_up 3, crouch 3, fire 3, jump 4, death 6. Apuntado arriba diagonal, no vertical puro. No hay pose tumbada de disparo independiente.
Cada direccion ocupa 25 frames, primero derecha y luego izquierda.
sprites.bin y masks.bin: 128 bytes por frame, cuatro bytes por fila, MSB izquierda.
sprites_masks.bin: 128 bytes imagen + 128 mascara por frame.
chars_8x8.bin: 16 caracteres por frame, orden de izquierda a derecha y arriba a abajo; 8 bytes por caracter.
soldier.asm: etiquetas y datos DB, sintaxis hexadecimal estilo sjasmplus.
Mascara: inversa de la silueta dilatada 1 pixel. Dibujo: (fondo AND mascara) OR sprite. Restaurar fondo antes de mover.
El negro de los PNG de imagen representa bits 0; usar la mascara para transparencia.
No incluye rutina de dibujado ni prueba en emulador. La conversion es por remuestreo del arte, no pixel art manual.
