//  La simulación de una partida. Aquí no se pinta nada.
//
//  Reparto de responsabilidades, y no es capricho: esto decide QUÉ hay y la
//  vista decide DÓNDE está. El recorrido de cada palabra lo lleva su propia
//  animación en la vista —el motor de animación, no un Timer a 16 ms, que ya
//  se sabe que eso no da 60 Hz— y cuando una llega al final avisa aquí con
//  `escapo()`. Así la simulación no tiene que saber de píxeles.
//
//  Las palabras van en un ListModel y NO en un array, y esto costó una
//  partida entera de depuración: con un array hay que reasignarlo entero para
//  que la vista se entere de un cambio, el Repeater ve un modelo nuevo,
//  destruye y recrea TODOS los delegados, y con ellos sus animaciones. El
//  efecto era precioso de diagnosticar: cada palabra que brotaba reiniciaba
//  la caída de todas las demás, así que ninguna llegaba nunca abajo y se
//  amontonaban arriba para siempre. Un ListModel toca solo la fila que cambia.
//
//  Fase 1: sin ruta, sin runas y sin tinta. Lo que sí está es la corrupción,
//  porque sin ella el teclado dibujado no significaría nada — y como todavía
//  no hay tinta con la que limpiarla, aquí se cura sola con el tiempo.

import QtQuick
import K4 as K4

QtObject {
    id: sim

    property Vocabulario vocabulario: Vocabulario {}

    // ── el círculo ────────────────────────────────────────────────
    //
    //  Las teclas despiertas. En la fase 1 es fijo; en la 4 será la clase que
    //  elijas y lo que crece al bajar de capa. Se queda generoso a propósito:
    //  con pocas letras el vocabulario se queda en cuatro palabras y no se ve
    //  si el juego funciona, que es para lo que existe esta fase.
    readonly property string circulo: "aeioustrnlmdcpbg"

    // ── estado de la partida ──────────────────────────────────────
    property bool jugando: false
    property bool pausada: false

    //  Lo abierta que está la grieta, de 0 a 1. Es la vida, y no hay número:
    //  se enseña como lo rajada que está la isla.
    property real fisura: 0

    property int capa: 1
    property int selladas: 0
    property int combo: 0
    property int mejorCombo: 0
    property int fallos: 0

    //  Filas: { pid, texto, muestra, esperado, tipo, escrito, carril }
    //  `muestra` y no `visible` porque un rol llamado `visible` le pisaría al
    //  delegado la suya y la palabra no se vería. Y `pid` y no `id` por lo
    //  mismo con el id de QML.
    property ListModel palabras: ListModel {}

    //  Lo que se te escapó y anda suelto por el escritorio. No es adorno: se
    //  puede cazar, y cazarlo CIERRA grieta. Es la única forma de curarse,
    //  así que una fuga no es solo daño — es una deuda que puedes pagar, y
    //  decidir si la persigues o sigues con lo que sale es media partida.
    property ListModel fugadas: ListModel {}

    property int objetivo: -1
    property int _siguienteId: 1

    //  Racha alta: la isla crece, todo cae más deprisa y cada sellada cuenta
    //  doble. Se entra sin querer y se sale al primer fallo, así que es una
    //  recompensa por ir fino y un riesgo por ir rápido a la vez.
    readonly property int umbralSobrecarga: 10
    readonly property bool sobrecarga: combo >= umbralSobrecarga

    //  El instante de cerrar una capa: todo se para un momento mientras la
    //  onda barre la pantalla. Lo levanta y lo baja la vista.
    property bool lento: false

    //  { letra: instante en que se cura }
    property var corruptas: ({})

    signal sellada(int pid)
    signal selladaEnFuga(int pid)
    signal escapada(int pid)
    signal capaCerrada(int capa)
    signal fallo(string letra)
    signal muerte()

    // ── el ritmo ──────────────────────────────────────────────────
    //
    //  Cada capa acorta la espera y alarga las palabras. Los números salen de
    //  querer que una partida de fase 1 dure sobre un minuto: lo justo para
    //  ver si esto se siente bien.
    readonly property int esperaMs: Math.max(1100, 2600 - capa * 220)
    //  En sobrecarga cae todo un tercio más rápido: la recompensa por ir fino
    //  tiene que dar miedo, o no es una recompensa, es un regalo.
    readonly property int caidaMs: Math.round(
        Math.max(4200, 9000 - capa * 600) * (sobrecarga ? 0.68 : 1))

    function empezar() {
        palabras.clear()
        fugadas.clear()
        objetivo = -1
        corruptas = ({})
        fisura = 0
        capa = 1
        selladas = 0
        combo = 0
        mejorCombo = 0
        fallos = 0
        pausada = false
        jugando = true
        brotar()
    }

    function parar() {
        jugando = false
        pausada = false
        lento = false
        palabras.clear()
        fugadas.clear()
        objetivo = -1
    }

    function alternarPausa() {
        if (jugando)
            pausada = !pausada
    }

    // ── lo que sale por la grieta ─────────────────────────────────

    function _listaDeCapa() {
        const v = vocabulario
        //  Las primeras capas son cortas; a partir de la tercera entran las
        //  medias, y las largas asoman al final. Se mezcla en vez de saltar de
        //  golpe para que el salto de dificultad no se note como un muro.
        let fuente = v.cortas
        if (capa >= 5)
            fuente = v.cortas.concat(v.medias, v.largas)
        else if (capa >= 3)
            fuente = v.cortas.concat(v.medias)
        return v.deCirculo(fuente, circulo)
    }

    //  Un carril libre. Se sortean unos cuantos y gana el que más lejos quede
    //  de lo que ya hay: dos palabras superpuestas no son más difíciles, son
    //  ilegibles, y eso no es dificultad sino mala letra.
    function _carrilLibre() {
        let mejor = Math.random()
        let mejorDistancia = -1
        for (let intento = 0; intento < 6; ++intento) {
            const c = 0.04 + Math.random() * 0.72
            let cerca = 2
            for (let i = 0; i < palabras.count; ++i)
                cerca = Math.min(cerca, Math.abs(palabras.get(i).carril - c))
            if (cerca > mejorDistancia) {
                mejorDistancia = cerca
                mejor = c
            }
        }
        return mejor
    }

    function brotar() {
        if (!jugando || pausada)
            return

        const lista = _listaDeCapa()
        if (!lista.length)
            return

        const texto = lista[Math.floor(Math.random() * lista.length)]

        //  El espejo: se enseña del revés y se teclea tal como se ve. El reto
        //  es que la palabra deja de leerse sola — hay que MIRARLA. A partir
        //  de la segunda capa.
        const tipo = (capa >= 2 && Math.random() < 0.25) ? "espejo" : "llana"
        const muestra = tipo === "espejo"
            ? texto.split("").reverse().join("") : texto

        let esperado = ""
        for (let i = 0; i < muestra.length; ++i)
            esperado += vocabulario.llana(muestra[i].toLowerCase())

        palabras.append({
            pid: _siguienteId++,
            texto: texto,
            muestra: muestra,
            esperado: esperado,
            tipo: tipo,
            escrito: 0,
            carril: _carrilLibre()
        })
    }

    //  Una palabra puede estar en la isla o suelta por el escritorio, y para
    //  teclearla da igual dónde esté: se busca en los dos sitios y se devuelve
    //  en cuál apareció. Los pid no se repiten entre modelos, así que un solo
    //  `objetivo` vale para las dos.
    function _buscar(pid) {
        for (let i = 0; i < palabras.count; ++i)
            if (palabras.get(i).pid === pid)
                return { modelo: palabras, i: i, enFuga: false }
        for (let j = 0; j < fugadas.count; ++j)
            if (fugadas.get(j).pid === pid)
                return { modelo: fugadas, i: j, enFuga: true }
        return null
    }

    function _quitar(pid) {
        const d = _buscar(pid)
        if (d)
            d.modelo.remove(d.i)
        if (objetivo === pid)
            objetivo = -1
    }

    // ── el teclado ────────────────────────────────────────────────

    function estaCorrupta(letra) {
        return corruptas[letra] !== undefined
    }

    function _corromper(letra) {
        if (circulo.indexOf(letra) < 0 || estaCorrupta(letra))
            return
        //  Reasignar el MISMO objeto a una propiedad `var` no notifica: hay
        //  que copiar para que el teclado dibujado se entere.
        const d = Object.assign({}, corruptas)
        //  Ocho segundos. En la fase 4 no se curará sola: se limpiará con
        //  tinta, y decidir en qué gastarla será media partida.
        d[letra] = Date.now() + 8000
        corruptas = d
    }

    function _curar() {
        const ahora = Date.now()
        let cambio = false
        const d = {}
        for (const letra in corruptas) {
            if (corruptas[letra] > ahora)
                d[letra] = corruptas[letra]
            else
                cambio = true
        }
        if (cambio)
            corruptas = d
    }

    //  Una tecla. Devuelve `true` si ha servido para algo.
    function teclear(bruta) {
        if (!jugando || pausada || !bruta.length)
            return false

        const letra = vocabulario.llana(bruta.toLowerCase())

        //  Una tecla corrompida no hace NADA. Ni acierta ni falla: está rota,
        //  y notarlo en los dedos es el castigo.
        if (estaCorrupta(letra))
            return false

        if (objetivo >= 0) {
            const d = _buscar(objetivo)
            if (d === null) {
                objetivo = -1
            } else {
                const modelo = d.modelo
                const i = d.i
                //  Lo que hay que leer se copia ANTES de tocar el modelo:
                //  `get(i)` devuelve una referencia VIVA a la fila, así que
                //  después de `setProperty` ese mismo `p.escrito` ya vale lo
                //  nuevo. Con la comparación hecha después, la palabra se
                //  sellaba una letra antes de tiempo y la última letra caía
                //  ya sin objetivo: te corrompía su propia tecla por haber
                //  acertado. Costó verlo porque solo se notaba en el teclado.
                const p = modelo.get(i)
                const pid = p.pid
                const hechas = p.escrito
                const largo = p.esperado.length
                if (p.esperado[hechas] === letra) {
                    modelo.setProperty(i, "escrito", hechas + 1)
                    if (hechas + 1 >= largo)
                        _sellar(pid, d.enFuga)
                    return true
                }
                _errar(letra)
                return false
            }
        }

        //  Sin objetivo, la letra elige: de las que empiezan por ella, la más
        //  vieja, que es la que está más cerca de escaparse. Perseguir la más
        //  urgente es lo que uno quiere hacer, así que que lo haga sola.
        //  Las de la isla mandan sobre las fugadas: lo que está cayendo es lo
        //  urgente, y una fugada no se te lleva la letra que necesitabas para
        //  lo que tienes encima.
        let modelo = null
        let elegido = -1
        for (let i = 0; i < palabras.count; ++i) {
            if (palabras.get(i).esperado[0] === letra) {
                modelo = palabras
                elegido = i
                break
            }
        }
        if (elegido < 0) {
            for (let j = 0; j < fugadas.count; ++j) {
                if (fugadas.get(j).esperado[0] === letra) {
                    modelo = fugadas
                    elegido = j
                    break
                }
            }
        }

        if (elegido < 0) {
            _errar(letra)
            return false
        }

        //  Copiado antes de tocar el modelo, por lo mismo de arriba.
        const p = modelo.get(elegido)
        const pid = p.pid
        const largo = p.esperado.length
        const enFuga = modelo === fugadas
        objetivo = pid
        modelo.setProperty(elegido, "escrito", 1)
        if (largo === 1)
            _sellar(pid, enFuga)
        return true
    }

    function _sellar(pid, enFuga) {
        //  En sobrecarga cada palabra cuenta por dos: es lo que hace que
        //  merezca la pena arriesgarse a mantener la racha.
        selladas += sobrecarga ? 2 : 1
        combo += 1
        if (combo > mejorCombo)
            mejorCombo = combo

        if (enFuga) {
            //  Cazar lo que se te escapó es la única cura que hay.
            fisura = Math.max(0, fisura - 0.1)
            selladaEnFuga(pid)
        } else {
            sellada(pid)
        }

        //  Cada cinco selladas se cierra una capa. Sin ruta todavía: eso es la
        //  fase 4. Aquí sirve para que la dificultad suba y para que haya un
        //  instante que celebrar.
        const antes = capa
        capa = 1 + Math.floor(selladas / 5)
        if (capa > antes)
            capaCerrada(capa)

        _quitar(pid)
    }

    function _errar(letra) {
        fallos += 1
        combo = 0
        _corromper(letra)
        fallo(letra)
    }

    //  Se rinde el objetivo actual. Cuesta el combo, que es justo: cambiar de
    //  palabra a medias es una decisión, no un accidente.
    function soltar() {
        if (objetivo < 0)
            return
        const d = _buscar(objetivo)
        if (d)
            d.modelo.setProperty(d.i, "escrito", 0)
        combo = 0
        objetivo = -1
    }

    //  La llama la vista cuando una palabra termina su recorrido. No se
    //  destruye: SALE. Pasa al escritorio y se queda ahí, estorbando, hasta
    //  que la caces o hasta que la grieta te gane.
    function escapo(pid) {
        const d = _buscar(pid)
        if (d === null || d.enFuga)
            return

        const p = d.modelo.get(d.i)
        const suelta = {
            pid: p.pid, texto: p.texto, muestra: p.muestra,
            esperado: p.esperado, tipo: p.tipo, escrito: 0
        }

        combo = 0
        //  Abrir la grieta es el único daño que existe. Cinco fugas y se acabó
        //  — salvo que vayas a buscarlas, que es de lo que va esto.
        fisura = Math.min(1, fisura + 0.2)
        escapada(pid)
        d.modelo.remove(d.i)
        if (objetivo === pid)
            objetivo = -1
        fugadas.append(suelta)

        if (fisura >= 1) {
            jugando = false
            lento = false
            palabras.clear()
            objetivo = -1
            muerte()
        }
    }

    property Timer _brote: Timer {
        interval: sim.esperaMs
        repeat: true
        running: sim.jugando && !sim.pausada
        onTriggered: sim.brotar()
    }

    property Timer _cura: Timer {
        interval: 500
        repeat: true
        running: sim.jugando && !sim.pausada
        onTriggered: sim._curar()
    }
}
