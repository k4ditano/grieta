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

    // ── el azar ───────────────────────────────────────────────────
    //
    //  Propio y no `Math.random`, para que exista la grieta del día: con la
    //  semilla puesta a la fecha, todo el que tenga k4 juega HOY la misma
    //  partida —las mismas palabras, las mismas salas, las mismas runas, el
    //  mismo guardián— y el resultado se puede comparar. Es lo que hace que
    //  compartirlo signifique algo.
    //
    //  Un xorshift de 32 bits: no es criptografía, es reproducibilidad, y
    //  para eso sobra. Lo importante es que TODO el sorteo pase por aquí —
    //  una sola llamada a Math.random suelta rompe el día entero.
    property bool diaria: true
    property int _estado: 1

    function sembrar(n) {
        //  El cero es punto fijo del xorshift: se quedaría clavado.
        _estado = (n | 0) || 1
    }

    function azar() {
        let x = _estado
        x ^= x << 13
        x ^= x >>> 17
        x ^= x << 5
        _estado = x | 0
        return ((x >>> 0) % 100000) / 100000
    }

    function _semillaDelDia(fecha) {
        return fecha.getFullYear() * 10000
             + (fecha.getMonth() + 1) * 100 + fecha.getDate()
    }

    property Vocabulario vocabulario: Vocabulario {}
    property Circulos circulos: Circulos {}
    property Runas catalogoRunas: Runas { azar: sim.azar }
    property Salas catalogoSalas: Salas { azar: sim.azar }
    property Guardianes catalogoGuardianes: Guardianes { azar: sim.azar }

    // ── el némesis ────────────────────────────────────────────────
    //
    //  La PRIMERA palabra que se te escapa en una partida se te queda
    //  pegada: vuelve al cerrar cada capa, y cada vez viene repetida una vez
    //  más —«duna», «dunaduna», «dunadunaduna»— hasta que la selles. No es
    //  una mecánica de daño: es para que salgas de la partida contando que
    //  moriste a manos de «murciélago», que es lo que la gente cuenta de un
    //  roguelike.
    property string nemesis: ""
    property int nemesisFuerza: 1
    property bool nemesisFuera: false

    // ── los guardianes ────────────────────────────────────────────
    //
    //  Cada tres capas. Mientras está delante cambia una regla del teclado,
    //  y se va cuando le sellas sus palabras.
    property string guardian: ""
    property int guardianVida: 0
    //  A qué capa toca el siguiente. Es un umbral y no un `capa % 3`, y la
    //  diferencia no es de estilo: con la Sala del Eco cada sellada cuenta
    //  DOBLE, así que se puede saltar de la capa 2 a la 4 y la 3 no llega a
    //  existir. Preguntando por la igualdad exacta, ese guardián no aparecía
    //  nunca y no había forma de saber por qué.
    property int proximoGuardian: 3
    property var guardianesVistos: []
    //  El de Dos Caras: { tecla que pulsas: letra que sale }.
    property var permuta: ({})

    readonly property var guardianActual:
        guardian.length ? catalogoGuardianes.porId(guardian) : null

    // ── lo que llevas ─────────────────────────────────────────────
    property var runas: []

    function tiene(id) { return runas.indexOf(id) >= 0 }

    //  Los modificadores, todos en un sitio. Están aquí y no repartidos por
    //  el código para que se pueda leer de un vistazo qué hace cada runa —y
    //  para que añadir la trece sea una línea.
    readonly property real multDano: (tiene("yunque") ? 0.6 : 1)
    readonly property real multCaida: (tiene("aliento") ? 1.15 : 1)
                                    * (salaActiva === "nido" ? 0.75 : 1)
                                    * (guardian === "ojo" ? 0.65 : 1)
    readonly property real multEspera: (tiene("faro") ? 1.15 : 1)
                                     * (salaActiva === "eco" ? 0.7 : 1)
                                     * (guardian === "dosbocas" ? 0.5 : 1)
    readonly property int porTinta: tiene("tintero") ? 2 : 3
    //  La runa Ceniza: los borrones no se pegan. Fallar sigue costándote la
    //  racha, pero la palabra ya no crece.
    readonly property bool sinManchas: tiene("ceniza")
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

    // ── que no haya dos a la misma altura ─────────────────────────
    //
    //  No es cosmética. Todo el juego se apoya en que la de más abajo es la
    //  que más corre: es el criterio con el que la letra elige a quién
    //  enganchar y es lo que lees para decidir a por cuál vas. Dos palabras a
    //  la misma altura rompen las dos cosas a la vez.
    //
    //  Se garantiza con dos reglas, y con las dos basta:
    //
    //    1. Nadie nace hasta que la anterior ha bajado un hueco mínimo.
    //    2. Nadie nace MÁS RÁPIDO que la que tiene debajo — así el hueco solo
    //       puede crecer, nunca cerrarse. Sin esto, una palabra nacida en
    //       sobrecarga (un tercio más rápida) alcanzaba a la de delante.
    //
    //  El reloj cuenta tiempo JUGADO y no de pared: con el de pared, una
    //  pausa de dos minutos hacía creer que todo había bajado ya, y al volver
    //  brotaba encima de lo que había.
    readonly property real hueco: 0.17
    property real reloj: 0

    property Timer _latido: Timer {
        interval: 100
        repeat: true
        running: sim.jugando && !sim.pausada && !sim.enRuta && !sim.lento
        onTriggered: sim.reloj += interval
    }

    //  Lo que le queda a la más nueva por recorrer, de 0 a 1.
    function _avanceDeLaUltima() {
        if (palabras.count === 0)
            return 1
        const u = palabras.get(palabras.count - 1)
        return Math.min(1, (reloj - u.nacido) / Math.max(1, u.duracion))
    }

    function _hayHueco() {
        return _avanceDeLaUltima() >= hueco
    }

    //  Ni más rápida que la que tiene delante.
    function _duracionSegura() {
        if (palabras.count === 0)
            return caidaMs
        return Math.max(caidaMs, palabras.get(palabras.count - 1).duracion)
    }

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
    //  Ya no limpia teclas: SELLA. Con TAB gastas una y la palabra más
    //  urgente —la de más abajo— se cierra sola. Es el botón de pánico que
    //  faltaba: cuando se te junta todo, tienes una salida que depende de
    //  algo que ganaste, no de la suerte.
    //
    //  Aquí vivía la corrupción de teclas, y se ha ido entera. Anular letras
    //  se peleaba con el verbo del juego: lo bonito de teclear es la
    //  fluidez, y una mecánica que te corta los dedos ataca justo eso. Peor
    //  aún, era un callejón sin salida — sin poder escribir no sellas, sin
    //  sellar no hay tinta, y sin tinta no se arreglaba. Lo que la sustituye
    //  está en `_errar`: fallar no te inutiliza, te MANCHA.
    property int tinta: 0
    property int _haciaTinta: 0

    signal sellada(int pid)
    signal selladaEnFuga(int pid)
    signal escapada(int pid)
    signal capaCerrada(int capa)
    signal fallo(string letra)
    signal limpiada(string letra)
    signal guardianLlego(string id)
    signal guardianCaido(string id)
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

    //  Palabras de TU máquina: los nombres de tus aplicaciones instaladas y
    //  lo que estés escuchando. Ninguna de las dos pide permiso —leerlas no
    //  le hace nada a nadie— y convierten la grieta en algo tuyo: sellar
    //  «firefox» no se parece a sellar «casa».
    property bool fuentesPropias: false

    function _delSistema() {
        const salida = []
        if (!fuentesPropias)
            return salida

        const apps = K4.Apps.lista || []
        for (let i = 0; i < apps.length && salida.length < 60; ++i) {
            const n = (apps[i].name || "").toLowerCase()
            //  Una sola palabra, de largo razonable y escribible con tu
            //  círculo: un «LibreOffice Calc» no es un enemigo, es un muro.
            if (n.length >= 3 && n.length <= 12 && n.indexOf(" ") < 0)
                salida.push(n)
        }
        return salida
    }

    function empezar(id) {
        if (id !== undefined && id.length > 0)
            claseId = id

        //  La grieta del día: misma fecha, misma partida para todo el mundo.
        //  Sin ella, la semilla la pone el reloj y cada run es suya.
        sembrar(diaria ? _semillaDelDia(K4.Reloj.ahora) : Date.now() & 0x7fffffff)

        palabras.clear()
        fugadas.clear()
        objetivo = -1
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
        nemesis = ""
        nemesisFuerza = 1
        nemesisFuera = false
        guardian = ""
        guardianVida = 0
        guardianesVistos = []
        proximoGuardian = 3
        permuta = ({})
        enRuta = false
        pasoRuta = ""
        ofertaSalas = []
        ofertaRunas = []
        maldita = -1
        pausada = false
        jugando = true
        reloj = 0

        //  La Ceniza empieza con la grieta ya medio abierta: sale cara y
        //  arranca con tinta de sobra para compensarlo.
        fisura = clase.fisuraAlNacer

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
        //  La Bestia solo trae palabras largas: es su regla entera.
        let fuente = v.cortas
        if (guardian === "bestia")
            fuente = v.largas.concat(v.medias)
        else if (capa >= 5)
            fuente = v.cortas.concat(v.medias, v.largas)
        else if (capa >= 3)
            fuente = v.cortas.concat(v.medias)

        //  Lo tuyo entra en la mezcla, no la sustituye: una capa entera de
        //  nombres de programas cansa enseguida.
        const propias = _delSistema()
        if (propias.length && guardian !== "bestia")
            fuente = fuente.concat(propias)

        const filtrada = v.deCirculo(fuente, circulo)

        //  Un círculo estrecho puede no tener ni una palabra larga. Antes que
        //  dejar la capa vacía, se cae a lo que haya.
        return filtrada.length ? filtrada : v.deCirculo(v.cortas, circulo)
    }

    //  Un carril libre. Se sortean unos cuantos y gana el que más lejos quede
    //  de lo que ya hay: dos palabras superpuestas no son más difíciles, son
    //  ilegibles, y eso no es dificultad sino mala letra.
    function _carrilLibre() {
        let mejor = azar()
        let mejorDistancia = -1
        for (let intento = 0; intento < 6; ++intento) {
            const c = 0.04 + azar() * 0.72
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
        //  Todavía no: la anterior no ha bajado lo suficiente. El temporizador
        //  volverá a intentarlo, así que esto retrasa, no se salta nada.
        if (!_hayHueco())
            return

        const lista = _listaDeCapa()
        if (!lista.length)
            return

        //  Mientras tu némesis esté fuera, esa palabra se saca de la bolsa:
        //  se vieron dos «río» a la vez, una con su borde rojo y otra sin él,
        //  y dejaba de entenderse cuál era la tuya. Se QUITA de la lista en
        //  vez de sortear otra vez —que es lo que hacía antes y fallaba con
        //  vocabularios cortos, donde el segundo intento repetía—, y así
        //  además el sorteo sigue siendo uno solo y la grieta del día no se
        //  descuadra.
        let bolsa = lista
        if (nemesisFuera && nemesis.length) {
            const limpia = lista.filter(function (w) { return w !== nemesis })
            if (limpia.length)
                bolsa = limpia
        }

        const texto = bolsa[Math.floor(azar() * bolsa.length)]

        //  El espejo: se enseña del revés y se teclea tal como se ve. El reto
        //  es que la palabra deja de leerse sola — hay que MIRARLA. A partir
        //  de la segunda capa.
        //  El Escriba Ciego lo pone TODO del revés; la Mordaza quita los
        //  espejos… salvo delante de él, que para eso es un guardián.
        const tipo = guardian === "ciego" ? "espejo"
            : (!sinEspejos && capa >= 2 && azar() < 0.25)
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
            manchas: 0,
            escrito: Math.min(arranque, esperado.length - 1),
            carril: _carrilLibre(),
            nacido: reloj,
            //  Congelada al nacer. Antes la vista leía `caidaMs` en un enlace
            //  vivo, así que al entrar en sobrecarga —o al llegar un
            //  guardián— cambiaba la duración de las animaciones EN VUELO:
            //  las palabras pegaban un salto y podían quedar emparejadas.
            duracion: _duracionSegura()
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

    //  Sella al instante la más urgente: la que lleva más tiempo cayendo, que
    //  es la de más abajo. Cuesta una tinta y no da racha —no es un acierto,
    //  es una salida— pero te saca del apuro y cuenta como sellada.
    function gastarTinta() {
        if (tinta <= 0 || palabras.count === 0)
            return false
        tinta -= 1
        const pid = palabras.get(0).pid
        _sellar(pid, false)
        return true
    }

    //  Una tecla. Devuelve `true` si ha servido para algo.
    function teclear(bruta) {
        if (!jugando || pausada || !bruta.length)
            return false

        let letra = vocabulario.llana(bruta.toLowerCase())

        //  El de Dos Caras se mete AQUÍ, en la puerta: pulsas una tecla y
        //  sale otra. Va antes que nada para que todo lo demás —el objetivo,
        //  la corrupción, el teclado dibujado— vea ya la letra cambiada y no
        //  haya que acordarse de la permuta en cinco sitios.
        if (permuta[letra] !== undefined)
            letra = permuta[letra]

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
                //  La letra no sigue a esta palabra. ANTES de dar el fallo
                //  por bueno, se mira si empieza OTRA: casi siempre eso es
                //  justo lo que estabas haciendo —dejar la de arriba e ir a
                //  por la de abajo, que corre más peligro—, y castigarlo era
                //  absurdo. Sin esto te quedabas clavado en una palabra que
                //  ya no querías y cambiar de objetivo costaba una tecla rota.
                objetivo = -1
                if (_engancharPorLetra(letra)) {
                    //  Te has ido a otra: la de antes vuelve a empezar, sin
                    //  castigo. Cambiar de objetivo es una decisión.
                    modelo.setProperty(i, "escrito", Math.min(arranque, largo - 1))
                    return true
                }

                //  Y si no empieza ninguna, entonces sí te has equivocado —y
                //  la mancha va a ESA palabra, la que estabas escribiendo, no
                //  a ninguna otra. Por eso se le pasa el pid: si se dejara
                //  que `_errar` mirara `objetivo`, ya estaría a -1 y la
                //  mancha no caería en ningún sitio.
                _errar(letra, pid)
                return false
            }
        }

        //  Sin objetivo, la letra elige: de las que empiezan por ella, la más
        //  vieja, que es la que está más cerca de escaparse. Perseguir la más
        //  urgente es lo que uno quiere hacer, así que que lo haga sola.
        //  Sin objetivo: si esa letra no empieza nada, se te ha ido el dedo
        //  y cae un borrón.
        if (_engancharPorLetra(letra))
            return true
        _errar(letra, -1)
        return false
    }

    //  Engancha la primera palabra que EMPIECE por esa letra. Las de la isla
    //  mandan sobre las fugadas —lo que está cayendo es lo urgente, y una
    //  fugada no debe robarte la letra que necesitabas para lo que tienes
    //  encima— y dentro de cada una gana la más vieja, que es la que está más
    //  abajo y más cerca de escaparse.
    function _engancharPorLetra(letra) {
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

        if (elegido < 0)
            return false

        //  Copiado antes de tocar el modelo: `get()` devuelve una referencia
        //  viva y después de `setProperty` ya valdría lo nuevo.
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
        const esNemesis = d ? d.modelo.get(d.i).tipo === "nemesis" : false

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

        //  El némesis: sellarlo cierra grieta de verdad y lo quita de en
        //  medio para siempre. Es la recompensa por haber ido a por él en vez
        //  de por lo fácil.
        if (esNemesis) {
            nemesis = ""
            nemesisFuera = false
            nemesisFuerza = 1
            fisura = Math.max(0, fisura - 0.25)
            tinta += 2
        }

        //  Y al guardián se le sella lo suyo hasta que se va.
        if (guardian.length && guardianVida > 0) {
            guardianVida -= 1
            if (guardianVida <= 0) {
                const caido = guardian
                guardian = ""
                permuta = ({})
                tinta += 3
                fisura = Math.max(0, fisura - 0.1)
                guardianCaido(caido)
            }
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

    //  Cuánto puede engordar una palabra por tus fallos. Sin tope, ensañarse
    //  con una la convertía en un muro, que es justo lo que se venía a quitar.
    readonly property int topeManchas: 3

    //  Fallar no te quita letras: te MANCHA.
    //
    //  Dentro de una palabra, la letra que tocaba se dobla ahí mismo y hay
    //  que escribirla otra vez: tu error se convierte en trabajo, inmediato y
    //  donde estás mirando. Cuanto más metido estabas, más escuece.
    //
    //  Y sin objetivo —una letra que no empieza nada— cae un borrón por la
    //  grieta, hecho con esa misma letra que te sobró.
    //
    //  Las dos cosas salen de lo que has tecleado y no de un sorteo, así que
    //  no gastan azar: la grieta del día sigue siendo la misma para todos por
    //  muchas veces que te equivoques.
    function _errar(letra, pidManchado) {
        fallos += 1
        combo = 0

        const destino = pidManchado === undefined ? objetivo : pidManchado
        if (destino >= 0 && !sinManchas) {
            const d = _buscar(destino)
            if (d) {
                const p = d.modelo.get(d.i)
                if ((p.manchas || 0) < topeManchas) {
                    const n = p.escrito
                    const doblada = p.esperado[n]
                    if (doblada !== undefined) {
                        d.modelo.setProperty(d.i, "muestra",
                            p.muestra.slice(0, n) + p.muestra[n] + p.muestra.slice(n))
                        d.modelo.setProperty(d.i, "esperado",
                            p.esperado.slice(0, n) + doblada + p.esperado.slice(n))
                        d.modelo.setProperty(d.i, "manchas", (p.manchas || 0) + 1)
                    }
                }
            }
        } else if (destino < 0) {
            _borron(letra)
        }

        fallo(letra)
    }

    //  Un borrón: tres veces la letra que te sobró, cayendo por la grieta.
    //  Corto a propósito — es un castigo, no una condena.
    function _borron(letra) {
        if (!_hayHueco() || circulo.indexOf(letra) < 0)
            return
        const muestra = letra + letra + letra
        palabras.append({
            pid: _siguienteId++, texto: muestra, muestra: muestra,
            esperado: muestra, tipo: "borron", escrito: 0, manchas: 0,
            carril: _carrilLibre(), nacido: reloj, duracion: _duracionSegura()
        })
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

        //  El primero que se escapa se te queda pegado para el resto de la
        //  partida. Y si el que se escapa ES el némesis, vuelve más largo.
        if (p.tipo === "nemesis") {
            nemesisFuera = false
            nemesisFuerza += 1
        } else if (!nemesis.length) {
            nemesis = p.texto
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
        //  El némesis NO se va al escritorio: vuelve por la grieta en la capa
        //  siguiente y más largo. Si hiciera las dos cosas habría dos bichos
        //  con el mismo nombre y dejaría de entenderse cuál es cuál.
        if (p.tipo !== "nemesis")
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
        onTriggered: {
            //  El némesis tiene preferencia sobre un brote nuevo: si está
            //  pendiente de volver, que vuelva él.
            if (sim.nemesis.length && !sim.nemesisFuera)
                sim._soltarNemesis()
            else
                sim.brotar()
        }
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
        maldita = (rs.length > 1 && azar() < 0.45)
            ? Math.floor(azar() * rs.length) : -1
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
            //  Barre la isla: todo lo que estaba cayendo se apaga. No cuenta
            //  como sellado —no es un acierto, es un respiro— pero te deja la
            //  capa nueva limpia. Compite con una runa, así que tiene que
            //  valer la pena de verdad.
            palabras.clear()
            objetivo = -1
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
            //  El precio: la grieta se abre. Directo, se ve en la barra al
            //  momento y no te quita capacidad — que era el problema del
            //  precio anterior, romperte una tecla.
            fisura = Math.min(0.95, fisura + 0.15)
        }

        _cerrarRuta()
    }

    //  El némesis, repetido una vez más de las que ya te ha visitado.
    function _soltarNemesis() {
        if (!nemesis.length || nemesisFuera)
            return

        let muestra = ""
        for (let i = 0; i < nemesisFuerza; ++i)
            muestra += nemesis

        let esperado = ""
        for (let j = 0; j < muestra.length; ++j)
            esperado += vocabulario.llana(muestra[j].toLowerCase())

        //  También espera su hueco: salía a la vez que el primer brote de la
        //  capa y los dos bajaban en paralelo, clavados a la misma altura
        //  toda la caída.
        if (!_hayHueco())
            return

        nemesisFuera = true
        palabras.append({
            pid: _siguienteId++, texto: nemesis, muestra: muestra,
            esperado: esperado, tipo: "nemesis", escrito: 0, manchas: 0,
            carril: _carrilLibre(),
            nacido: reloj, duracion: _duracionSegura()
        })
    }

    function _invocarGuardian() {
        const g = catalogoGuardianes.alAzar(guardianesVistos)
        guardian = g.id
        guardianVida = g.vida
        guardianesVistos = guardianesVistos.concat([g.id])

        //  El de Dos Caras te cambia dos teclas de sitio. Se sortean de tu
        //  círculo y de las que te funcionan: cambiarte una rota no se
        //  notaría, y un guardián que no se nota no es un guardián.
        permuta = ({})
        if (g.id === "doscaras") {
            const sanas = circulo.split("")
            if (sanas.length >= 2) {
                const a = sanas.splice(Math.floor(azar() * sanas.length), 1)[0]
                const b = sanas.splice(Math.floor(azar() * sanas.length), 1)[0]
                const d = {}
                d[a] = b
                d[b] = a
                permuta = d
            }
        }
        guardianLlego(g.id)
    }

    function _cerrarRuta() {
        ofertaSalas = []
        ofertaRunas = []
        maldita = -1
        pasoRuta = ""
        enRuta = false
        //  Cada tres capas, uno — contando por umbral, que las capas se
        //  saltan. Y el némesis vuelve siempre.
        if (capa >= proximoGuardian && !guardian.length) {
            proximoGuardian = capa + 3
            _invocarGuardian()
        }
        //  Se intenta ya; si no cabe todavía, lo reintenta el temporizador.
        _soltarNemesis()

        //  Con la capa nueva vacía, que empiece a salir algo enseguida y no
        //  al ritmo del temporizador.
        brotar()
    }
}
