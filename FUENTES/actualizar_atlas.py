import fitz, sys
from pathlib import Path
src,dst=map(Path,sys.argv[1:3]); doc=fitz.open(src)
fonts={k:f'/usr/share/fonts/truetype/lato/Lato-{k}.ttf' for k in ('Regular','Bold')}
fontobjs={k:fitz.Font(fontfile=v) for k,v in fonts.items()}
def edit(p,old,new,width=None,size=None,gap=None):
    page=doc[p-1]
    blocks=page.get_text('dict')['blocks']
    for b in blocks:
        if b['type']!=0:continue
        ss=[s for l in b['lines'] for s in l['spans']]
        if old in ss[0]['text']:
            # Select one span for header or specific label, whole block for paragraph.
            if old.startswith('ESCORIA SIDERAL   /') or len(ss)>1 and old=='2.048 combinaciones + 512 lecturas': pass
            if old.startswith('ESCORIA SIDERAL   /'):ss=ss[:1]
            break
        found=[s for s in ss if old in s['text']]
        if found: ss=found;break
    else: raise ValueError((p,old))
    s=ss[0]; x,y=s['origin']; sz=size or s['size']; key='Bold' if 'Bold' in s['font'] else 'Regular'; col=tuple(((s['color']>>sh)&255)/255 for sh in (16,8,0))
    for span in ss:page.add_redact_annot(fitz.Rect(span['bbox']),fill=False)
    page.apply_redactions(images=0,graphics=0,text=0)
    page.insert_font(fontname='Lato'+key,fontfile=fonts[key]); f=fontobjs[key]
    lines=[]
    for para in new.split('\n'):
        line=''
        for w in para.split():
            v=(line+' '+w).strip()
            if line and f.text_length(v,fontsize=sz)>(width or 552-x):lines.append(line);line=w
            else:line=v
        lines.append(line)
    for i,line in enumerate(lines):page.insert_text((x,y+i*(gap or sz+5)),line,fontsize=sz,fontname='Lato'+key,color=col)
def add(p,x,y,txt,size=12,bold=False,color=(.094,.129,.169),gap=17):
    page=doc[p-1]; key='Bold' if bold else 'Regular';page.insert_font(fontname='Lato'+key,fontfile=fonts[key]);f=fontobjs[key]
    lines=[]
    for para in txt.split('\n'):
        line=''
        for word in para.split():
            v=(line+' '+word).strip()
            if line and f.text_length(v,fontsize=size)>552-x:lines.append(line);line=word
            else:line=v
        lines.append(line)
    for i,line in enumerate(lines):page.insert_text((x,y+i*gap),line,fontsize=size,fontname='Lato'+key,color=color)
for i in range(2,25):edit(i,'ESCORIA SIDERAL   /','ESCORIA SIDERAL   /   V1.0.1')
edit(3,'Selecciona un ZX Spectrum','Selecciona un ZX Spectrum 48K en Fuse, abre ESCORIA_SIDERAL_V1.0.1.tap y ejecuta LOAD "" si no arranca automáticamente.')
edit(3,'Escucha la melodía','En el título, SPACE selecciona teclado; FIRE selecciona Kempston y teclado. Tres vidas.')
edit(3,'Tras derrotar a un jefe','Tras derrotar a un jefe, pulsa y suelta SPACE o FIRE para continuar. Mantén la cinta en su posición y reanuda su reproducción si el emulador la pausa.')
edit(4,'Teclado y Kempston simultáneos','SPACE: teclado · FIRE: Kempston y teclado')
edit(4,'Ace siempre mira','Ace mira a la derecha y dispara quieto o caminando, no en salto ni agachado. Salta los proyectiles bajos y agáchate ante los altos. Frena ante una caída por delante o esquiva lateralmente los meteoritos y las columnas de relámpago anunciadas.')
edit(6,'Zombi: 1','Zombi: 1–3 impactos. Alien: 2–4, algo más rápido. Hasta cuatro enemigos activos o muriendo, todos desde el frente. Si la entrada está ocupada, el director espera. Los enemigos normales no disparan.')
for i in range(7,12):edit(i,'Escenario · captura de VRAM','Escenario · captura real de referencia V1.0')
add(17,43,610,'Director táctico V1.0.1',16,True)
add(17,43,635,'Entrada exclusivamente frontal; amenazas por delante, sobre la posición de Ace o ligeramente retrasadas. Se desplazan con la cámara, sin perseguir al jugador. El fondo permanece fijo: parallax descartado para preservar acción y sonido.')
edit(19,'Carga estándar ROM','Carga ROM LD_BYTES ($0556). Se validan tipo, nombre inicial, longitud y dirección. La V1.0.1 espera a que se suelte SPACE antes de las lecturas de cabecera y datos; conserva las cabeceras internas.',size=11,gap=15)
edit(21,'Resultados conservados','Pruebas específicas V1.0.1 (FIX 3 aprobado en Fuse)')
edit(21,'2.048 combinaciones + 512 lecturas','6.144 combinaciones + 512 lecturas')
edit(21,'En el ensayo de cuatro enemigos','Con cuatro enemigos y meteorito, pico de cuerpo de fotograma: 120.630 T-states. En 300 actualizaciones de render: 128.701 T-states. Presupuesto nominal: 139.776 T-states cada dos interrupciones; la espera de audio se mide por separado.')
edit(21,'El simulador de instrucciones','El simulador no reproduce la contención ULA ni la ROM BASIC completa. El autor validó el FIX 3 en Fuse. Las pruebas de transferencia ROM y puertos son simuladas; no se declara una regresión histórica completa.')
add(21,43,620,'Director y multicarga',16,True)
add(21,43,645,'1.280 apariciones frontales, cero traseras. Tres patrones tácticos y restauración del fondo en cinco fases. Cuatro transiciones y final con SPACE mantenido: espera de liberación, transferencia y estado preservado. Pruebas de entrada fantasma superadas.')
add(22,43,461,'V1.0.1',13,True,(.635,.149,.196))
add(22,142,461,'Director frontal y peligros ambientales tácticos.',12)
add(22,142,478,'Multicarga protegida de BREAK; selección de teclado o Kempston.',12)
edit(22,'La versión V1.0 no','La V1.0 queda como edición histórica. V1.0.1 conserva el FIX 3 aprobado, sin cambios de última hora en el binario ni los bancos gráficos.')
edit(23,'TAP V1.0 listo','TAP V1.0.1 listo para cargar. Su SHA-256 identifica exactamente el FIX 3 aprobado.')
edit(23,'Instantánea de la 0.21.2','Fuentes V1.0.1: build.py, loading.py, screen_codec.py, ASM, BIN, símbolos, dependencias, tests y resultados. Se conservan las denominaciones internas históricas.')
edit(23,'Capturas de pantalla generadas','Capturas reales de VRAM de referencia V1.0 y de la última alfa, conservadas porque los recursos visuales no cambian.')
edit(24,'ESCORIA SIDERAL · 2026','ESCORIA SIDERAL · 2026 Tony C. Ware. Diseño, dirección, código, arte y edición. Desarrollo para ZX Spectrum 48K con técnicas de GRIT ENGINE ZX. Revisión V1.0.1: 28 de noviembre de 2026.')
edit(24,'TAP de 93.481 bytes','TAP de 93.481 bytes, idéntico al FIX 3 aprobado en Fuse. Sin cambios adicionales en el contenido de la cinta.')
add(24,43,469,'La pantalla de título conserva la etiqueta histórica KEMPSTON AUTO. El modo depende de SPACE o FIRE al iniciar.',11,gap=15)
edit(24,'250c3210909e','df2d7b596060ee42a675de0b748e14e2\naa2ce9d8be9a2308e7f538df1240766e',gap=19)
doc.set_metadata({'title':'ESCORIA SIDERAL V1.0.1 · Atlas, manual y memoria','author':'Tony C. Ware','subject':'ZX Spectrum 48K · edición V1.0.1'})
doc.save(dst,garbage=4,deflate=True)
