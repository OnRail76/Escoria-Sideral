5 suelos planos repetibles de 64x24 pixeles, 8x3 caracteres.
Banco global: 49 tiles de 8 bytes. Mapas de 24 indices en orden de filas. Atributos ZX: PAPER negro, INK por fase, BRIGHT 0.
Repetir columnas 0..7; para scroll por caracter avanzar una columna cada 8 pixeles. Para scroll fino desplazar bits entre bytes y mantener atributos uniformes. Los binarios locales _tiles contienen los 24 tiles sin deduplicar; los mapas hacen referencia al banco global tiles.bin. No incluye motor ni prueba emulador.

V2: solo cambia el suelo alien.
