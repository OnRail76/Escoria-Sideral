# ESCORIA SIDERAL V1.0.1 — Tactical Director — edición definitiva
2026 Tony C. Ware · ZX Spectrum 48K · Gold Master (FIX 3 aprobado por el autor en Fuse).

FIX 3: posible origen de saltos/disparos fantasma: el puerto Kempston se leía incluso sin mando, enmascarando los bits altos. Al iniciar desde el título con SPACE se selecciona exclusivamente teclado (QAOP + SPACE); con FIRE se selecciona Kempston y teclado simultáneo. SPACE tiene prioridad si ambos coinciden. Para cambiar el modo, regresar al título e iniciar con el otro control. Kempston exige tres lecturas consecutivas idénticas, bits altos a cero y direcciones válidas; no garantiza rechazar una señal falsa persistente que coincida con una lectura válida. No se modifica la puerta de carga inicial ni la espera de SPACE del FIX 2. El modo seleccionado se conserva en las fases y se reinicia al título. La etiqueta interna KEMPSTON AUTO se conserva; la selección ahora depende del control que inicia la partida.

124 bytes residentes modificados respecto a FIX 2, sin mover ninguna dirección existente. 27 restantes bloques TAP idénticos. 93.481 bytes, 28 bloques. Director, gráficos, sonido y código de multicarga intactos.

Reconstrucción: Python 3 + Pillow; python3 build_release.py. Genera ESCORIA_SIDERAL_V1.0.1_DIRECTOR.tap y copia el resultado verificado a ../JUEGO/ESCORIA_SIDERAL_V1.0.1.tap. SHA256: df2d7b596060ee42a675de0b748e14e2aa2ce9d8be9a2308e7f538df1240766e.

PRUEBAS_FIX3: test_kempston.py, test_rom_break.py, test_loading.py, test_director101.py, test_audio212.py, test_boss20.py, test_render.py; todas ejecutadas correctamente. test_boot_compat101.py compara las revisiones anteriores y queda como histórico (no aplicable a FIX3). test_cpu.py conserva pruebas históricas de jugabilidad (algunas esperan enemigos traseros); no se presenta la regresión histórica completa como aprobada. ROM, puertos y IRQ simulados; el autor confirmó el funcionamiento en Fuse. PRUEBAS_FIX1 y PRUEBAS_FIX2 son históricas.
