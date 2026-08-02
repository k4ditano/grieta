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
    property Circulos circulos: Circulos {}
    property Runas catalogoRunas: Runas {}
    property Salas catalogoSalas: Salas {}

    // ── lo que llevas ─────────────────────────────────────────────
    property var runas: []

    function tiene(id) { return runas.indexOf(id) >= 0 }

    //  Los modificadores, todos en un sitio. Están aquí y no repartidos por
    //  el código para que se pueda leer de un vistazo qué hace cada runa —y
    //  para que añadir la trece sea una línea.
    readonly property real multDano: (tiene("yunque") ? 0.6 : 1)
    readonly property real multCaida: (tiene("aliento") ? 1.15 : 1)
                                    * (salaActiva === "nido" ? 0.75 : 1)
    readonly property real multEspera: (tiene("faro") ? 1.15 : 1)
                                     * (salaActiva === "eco" ? 0.7 : 1)
    readonly property int porTinta: tiene("tintero") ? 2 : 3
    readonly property bool rotasEscriben: tiene("ceniza")
    readonly property bool sinEspejos: tiene("mordaza")
    readonly property int arranque: tiene("filo") ? 1 : 0
    readonly property int valorSellada: (salaActiva === "eco" ? 2 : 1)

    // ── el círculo ────────────────────────────────────────────────
    //
    //  Tu personaje es tu teclado: la clase decide qué letras tienes, cuánto
    //  te cuesta una fuga, a qué ritmo brota y si hay que teclear cada letra
    //  dos veces.
    property string claseId: "vocalista"
    readonly property var clase: circulos.porId(claseId)
    readonly property string circulo: clase.letras

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

    // ── la ruta ───────────────────────────────────────────────────
    //
    //  Entre capa y capa el juego SE PARA y hay que elegir por dónde bajas.
    //  Es la única pausa de la partida, y es a propósito: todo lo demás pasa
    //  con las manos en el teclado, así que el momento de pensar tiene que
    //  distinguirse del momento de teclear.
    property bool enRuta: false
    property string pasoRuta: ""          // "salas" | "runas"
    property var ofertaSalas: []
    property var ofertaRunas: []
    //  Cuál te tocó de las ofrecidas viene maldita: te la llevas rompiéndote
    //  una tecla. Es el índice dentro de `ofertaRunas`, o -1.
    property int maldita: -1

    //  La sala que manda en la capa que se está jugando.
    property string salaActiva: ""
    //  El Ancla perdona la primera fuga de cada capa.
    property bool perdonUsado: false
    //  La última letra sellada, para la Cadena.
    property string ultimaSellada: ""

    // ── la tinta ──────────────────────────────────────────────────
    //
    //  Lo que limpia una tecla rota, y lo único que las limpia: en la fase 1
    //  la corrupción se curaba sola con el tiempo, y eso convertía un fallo
    //  en un susto. Ahora una tecla rota se queda rota hasta que pagues, así
    //  que un error tuyo es una herida que arrastras el resto de la partida.
    //
    //  Se gana sellando —una cada tres— y cazando lo que se te escapó, que
    //  vale por una entera. Eso ata las tres cosas: fallas, te rompes, y para
    //  arreglarte tienes que ir a por lo que dejaste escapar.
    property int tinta: 0
    readonly property int selladasPorTinta: 3
    property int _haciaTinta: 0

    //  { letra: orden en que se rompió }, para poder limpiar la más vieja.
    property var corruptas: ({})
    property int _ordenRotura: 0

    signal sellada(int pid)
    signal selladaEnFuga(int pid)
    signal escapada(int pid)
    signal capaCerrada(int capa)
    signal fallo(string letra)
    signal limpiada(string letra)
    signal muerte()

    // ── el ritmo ──────────────────────────────────────────────────
    //
    //  Cada capa acorta la espera y alarga las palabras. Los números salen de
    //  querer que una partida de fase 1 dure sobre un minuto: lo justo para
    //  ver si esto se siente bien.
    readonly property int esperaMs: Math.round(
        Math.max(1100, 2600 - capa * 220) * clase.ritmo * multEspera)
    //  En sobrecarga cae todo un tercio más rápido: la recompensa por ir fino
    //  tiene que dar miedo, o no es una recompensa, es un regalo.
    readonly property int caidaMs: Math.round(
        Math.max(4200, 9000 - capa * 600) * (sobrecarga ? 0.68 : 1)
        * multCaida)

    function empezar(id) {
        if (id !== undefined && id.length > 0)
            claseId = id

        palabras.clear()
        fugadas.clear()
        objetivo = -1
        corruptas = ({})
        _ordenRotura = 0
        fisura = 0
        capa = 1
        selladas = 0
        combo = 0
        mejorCombo = 0
        fallos = 0
        tinta = clase.tinta
        _haciaTinta = 0
        runas = []
        salaActiva = ""
        perdonUsado = false
        ultimaSellada = ""
        enRuta = false
        pasoRuta = ""
        ofertaSalas = []
        ofertaRunas = []
        maldita = -1
        pausada = false
        jugando = true

        //  La Ceniza empieza con teclas ya rotas. Se sortean de su círculo,
        //  así que cada partida suya duele en otro sitio.
        const rotas = {}
        const bolsa = circulo.split("")
        for (let i = 0; i < clase.rotasAlNacer && bolsa.length; ++i) {
            const j = Math.floor(Math.random() * bolsa.length)
            rotas[bolsa[j]] = ++_ordenRotura
            bolsa.splice(j, 1)
        }
        corruptas = rotas

        brotar()
    }

    function parar() {
        jugando = false
        pausada = false
        lento = false
        enRuta = false
        pasoRuta = ""
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
        if (!jugando || pausada || enRuta)
            return

        const lista = _listaDeCapa()
        if (!lista.length)
            return

        const texto = lista[Math.floor(Math.random() * lista.length)]

        //  El espejo: se enseña del revés y se teclea tal como se ve. El reto
        //  es que la palabra deja de leerse sola — hay que MIRARLA. A partir
        //  de la segunda capa.
        const tipo = (!sinEspejos && capa >= 2 && Math.random() < 0.25)
            ? "espejo" : "llana"
        let muestra = tipo === "espejo"
            ? texto.split("").reverse().join("") : texto

        //  El Tartamudo ve —y teclea— cada letra dos veces. Se dobla la
        //  MUESTRA y no solo lo esperado: si vieras «casa» y hubiera que
        //  escribir «ccaassaa» sería una trampa, no una clase. Doblado a la
        //  vista, se lee como un tartamudeo y se entiende sin explicarlo.
        if (clase.tartamudo) {
            let doble = ""
            for (let k = 0; k < muestra.length; ++k)
                doble += muestra[k] + muestra[k]
            muestra = doble
        }

        let esperado = ""
        for (let i = 0; i < muestra.length; ++i)
            esperado += vocabulario.llana(muestra[i].toLowerCase())

        palabras.append({
            pid: _siguienteId++,
            texto: texto,
            muestra: muestra,
            esperado: esperado,
            tipo: tipo,
            escrito: Math.min(arranque, esperado.length - 1),
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
        d[letra] = ++_ordenRotura
        corruptas = d
    }

    readonly property int rotas: {
        let n = 0
        for (const l in corruptas)
            ++n
        return n
    }

    //  Limpia la tecla que lleva más tiempo rota. Se elige sola a propósito:
    //  con la lista entera para escoger, esto se convertía en un menú a media
    //  partida, y aquí no se para el tiempo. La más vieja es casi siempre la
    //  que más te ha estorbado ya.
    function limpiar() {
        if (tinta <= 0)
            return false

        let vieja = ""
        let mejor = Infinity
        for (const l in corruptas) {
            if (corruptas[l] < mejor) {
                mejor = corruptas[l]
                vieja = l
            }
        }
        if (!vieja.length)
            return false

        const d = {}
        for (const l in corruptas)
            if (l !== vieja)
                d[l] = corruptas[l]
        corruptas = d
        tinta -= 1
        limpiada(vieja)
        return true
    }

    //  Una tecla. Devuelve `true` si ha servido para algo.
    function teclear(bruta) {
        if (!jugando || pausada || !bruta.length)
            return false

        const letra = vocabulario.llana(bruta.toLowerCase())

        //  Una tecla corrompida no hace NADA. Ni acierta ni falla: está rota,
        //  y notarlo en los dedos es el castigo. Con la runa Ceniza vuelve a
        //  escribir, pero te corta la racha cada vez: la ruina deja de ser un
        //  muro y pasa a ser un peaje, que es una manera muy distinta de
        //  jugar con el mismo teclado roto.
        if (estaCorrupta(letra)) {
            if (!rotasEscriben)
                return false
            combo = 0
        }

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
        const d = _buscar(pid)
        const largoPalabra = d ? d.modelo.get(d.i).esperado.length : 0
        const inicial = d ? d.modelo.get(d.i).esperado[0] : ""

        selladas += (sobrecarga ? 2 : 1) * valorSellada
        combo += 1
        //  La Cadena: si enlazas por la última letra que sellaste, racha de
        //  más. Encadenar cinco seguidas es lo más bonito que se puede hacer
        //  aquí, y la runa existe para que compense buscarlo.
        if (tiene("cadena") && inicial.length > 0 && inicial === ultimaSellada)
            combo += 2
        ultimaSellada = largoPalabra > 0
            ? d.modelo.get(d.i).esperado[largoPalabra - 1] : ""
        if (combo > mejorCombo)
            mejorCombo = combo

        //  La Sanguijuela: lo largo cura.
        if (tiene("sanguijuela") && largoPalabra >= 7)
            fisura = Math.max(0, fisura - 0.05)

        if (enFuga) {
            //  Cazar lo que se te escapó cierra grieta Y da tinta entera: es
            //  lo que convierte una fuga en una deuda que merece la pena ir a
            //  pagar en vez de en un castigo y ya está.
            fisura = Math.max(0, fisura - 0.1)
            tinta += 1
            selladaEnFuga(pid)
        } else {
            sellada(pid)
        }

        //  Y la tinta que se gana sellando, a cuentagotas.
        _haciaTinta += 1
        if (_haciaTinta >= porTinta) {
            _haciaTinta = 0
            tinta += 1
        }

        //  Cada cinco selladas se cierra una capa. Sin ruta todavía: eso es la
        //  fase 4. Aquí sirve para que la dificultad suba y para que haya un
        //  instante que celebrar.
        const antes = capa
        capa = 1 + Math.floor(selladas / 5)
        if (capa > antes) {
            capaCerrada(capa)
            _abrirRuta()
        }

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
        if (tiene("ancla") && !perdonUsado) {
            //  El Ancla perdona la primera de cada capa: la fuga ocurre —la
            //  palabra sale al escritorio igual— pero no abre la grieta.
            perdonUsado = true
        } else {
            fisura = Math.min(1, fisura + clase.dano * multDano)
        }
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
        running: sim.jugando && !sim.pausada && !sim.enRuta
        onTriggered: sim.brotar()
    }

    //  Aquí vivía el timer que curaba las teclas solas. Se ha ido: ahora una
    //  tecla rota se queda rota hasta que gastes tinta, que es lo que hace que
    //  un fallo pese durante el resto de la partida en vez de durante ocho
    //  segundos.

    // ── la ruta ───────────────────────────────────────────────────

    function _abrirRuta() {
        //  Lo que la sala anterior prestaba se acaba aquí: cada sala manda
        //  durante UNA capa, no durante el resto de la partida.
        salaActiva = ""
        perdonUsado = false
        if (tiene("semilla"))
            tinta += 1
        if (tiene("eco"))
            tinta += 2

        ofertaSalas = catalogoSalas.ofrecer()
        pasoRuta = "salas"
        enRuta = true
    }

    function _ofrecerRunas(cuantas) {
        const rs = catalogoRunas.ofrecer(runas, cuantas)
        ofertaRunas = rs
        //  Una de las ofrecidas puede venir maldita: te la llevas rompiéndote
        //  una tecla. La decisión —¿vale esta runa una tecla?— es de las
        //  mejores que puede dar el juego, así que no sale siempre: si
        //  saliera, dejaría de ser una decisión y sería un impuesto.
        maldita = (rs.length > 1 && Math.random() < 0.45)
            ? Math.floor(Math.random() * rs.length) : -1
        pasoRuta = "runas"
    }

    function elegirSala(i) {
        if (!enRuta || pasoRuta !== "salas")
            return
        if (i < 0 || i >= ofertaSalas.length)
            return

        const sala = ofertaSalas[i]
        salaActiva = sala.id

        if (sala.id === "fragua") {
            //  Se lleva TODAS por delante. Media medida aquí no vale: la
            //  fragua compite con una runa, y «te limpio una» no compra a
            //  nadie.
            corruptas = ({})
            _cerrarRuta()
        } else if (sala.id === "mercado") {
            _ofrecerRunas(3)
        } else if (sala.id === "nido") {
            //  El nido paga al ENTRAR y cobra durante toda la capa: cae más
            //  deprisa. Se sabe lo que se compra antes de comprarlo.
            tinta += 3
            _ofrecerRunas(2)
        } else {
            _cerrarRuta()
        }
    }

    function elegirRuna(i) {
        if (!enRuta || pasoRuta !== "runas")
            return
        if (i < 0 || i >= ofertaRunas.length)
            return

        runas = runas.concat([ofertaRunas[i].id])

        if (i === maldita) {
            //  El precio de la maldita: una tecla de tu círculo, al azar y de
            //  las que todavía te funcionan.
            const sanas = []
            for (let k = 0; k < circulo.length; ++k)
                if (!estaCorrupta(circulo[k]))
                    sanas.push(circulo[k])
            if (sanas.length)
                _corromper(sanas[Math.floor(Math.random() * sanas.length)])
        }

        _cerrarRuta()
    }

    function _cerrarRuta() {
        ofertaSalas = []
        ofertaRunas = []
        maldita = -1
        pasoRuta = ""
        enRuta = false
        //  Con la capa nueva vacía, que empiece a salir algo enseguida y no
        //  al ritmo del temporizador.
        brotar()
    }
}
