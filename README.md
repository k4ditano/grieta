# La Grieta

Un roguelike de tecleo que vive en la barra [k4](https://github.com/k4ditano/k4).

**La isla no es la pantalla del juego: es la grieta.** Una raja en el borde de
tu escritorio por la que sale algo. Lo que sale son palabras, y se sellan
escribiéndolas.

```sh
python3 tools/plugins.py --instalar https://github.com/k4ditano/grieta
quickshell ipc -p ~/.config/quickshell/k4/shell.qml call k4 pluginEnable grieta
```

Llega apagado. Se enciende en Ajustes, viendo antes qué permisos pide —
`sonido`, y nada más.

## Cómo se juega

Escribes. La primera letra engancha una palabra y el resto la sella. Si te
equivocas de letra, **esa letra se dobla ahí mismo** y tienes que escribirla
otra vez: tu error se convierte en trabajo, inmediato y donde estás mirando. Y
si una palabra llega abajo no se borra: **sale de la barra** y se pone a vagar
por encima de tus ventanas hasta que la caces escribiéndola. Cazarla es la
única forma de cerrar grieta.

El juego nunca te quita letras. Se probó —romper la tecla que fallabas— y era
un callejón sin salida: sin poder escribirla no sellabas, sin sellar no había
con qué arreglarla, y perdías sin poder hacer nada. Un juego de tecleo va de
fluidez; cortarte los dedos se pelea con eso.

Cinco fugas y la grieta se abre del todo.

| | |
|---|---|
| `←` `→` `1`-`4` | elegir |
| `Enter` | empezar · bajar de capa |
| `TAB` | gastar tinta y sellar de golpe la palabra más urgente |
| `Retroceso` | soltar la palabra que estás escribiendo |
| `ESC` | pausa · otra vez, salir |
| `C` | copiar el resultado al portapapeles |

## Lo que hay dentro

**Cuatro círculos.** Tu personaje es tu teclado: no cambia una estadística,
cambian las teclas que tienes. El Vocalista tiene pocas letras y palabras
cortas sin descanso; El Escriba el alfabeto entero y la mitad de margen; El
Tartamudo teclea cada letra dos veces; La Ceniza empieza con la grieta ya
medio abierta y tinta de sobra.

**Una ruta.** Al cerrar capa eliges entre dos salas: la Fragua barre de un
golpe todo lo que está cayendo, el Mercado da una runa de tres, el Nido paga
tinta y cobra velocidad, la Sala del Eco lo hace todo valer doble. Nunca
puedes tenerlo todo.

**Doce runas**, y ninguna es un porcentaje escondido: la palabra ya viene
empezada, tus fallos dejan de manchar, encadenar por la última letra sellada
da racha de más. Algunas vienen **malditas**: te las llevas a cambio de que la
grieta se abra un poco.

**Seis guardianes**, cada tres capas, asomando por encima de la barra. Ninguno
tiene «más vida y ya»: te cambian dos teclas de sitio, te apagan el teclado,
ponen todo del revés.

**Y tu némesis.** La primera palabra que se te escapa se te queda pegada y
vuelve cada capa, repetida una vez más cada vez, hasta que la selles.

## La grieta del día

Todo el sorteo va sembrado con la fecha, así que **hoy juegas la misma partida
que cualquiera con k4**: las mismas palabras, las mismas salas, las mismas
runas, el mismo guardián. Por eso `C` copia una tarjeta comparable:

```
La Grieta · grieta del 2/8
El Vocalista
capa 7 · 34 selladas · racha ×12
🟥🟥🟩🟩🟩
me pudo «murciélago»
```

Se puede apagar en Ajustes y jugar partidas sueltas.

## Lo que lee de tu máquina

Nada, salvo que se lo pidas. Opcionalmente mezcla los **nombres de tus
aplicaciones instaladas** con el vocabulario (`K4.Apps`, sin permisos: leer qué
tienes instalado no le hace nada a nadie). Está apagado de fábrica.

No lee lo que escribes, ni tu portapapeles, ni tus ficheros. Un juego de tecleo
que te espiara el teclado sería exactamente lo que la
[API de k4](https://github.com/k4ditano/k4/blob/main/docs/API.md) llama una
línea roja que ningún permiso abre.

## Los assets

Los 34 sprites son originales de este proyecto, generados para él y con su
ficha de procedencia en `assets/manifest.json`. Nada extraído de ningún juego.
