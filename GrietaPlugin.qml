//  La Grieta — roguelike de tecleo en la barra.
//
//  Fase 1: el núcleo visual. Palabras que salen por la grieta, tecleo con
//  objetivo, corrupción de teclas, y la isla rajándose. Sin ruta, sin runas y
//  sin guardianes todavía — eso viene después; esto existe para ver si el
//  juego se SIENTE bien antes de construirle un sistema encima.
//
//  El estado vive aquí y la partida en `Simulacion`, que no sabe de píxeles.
//  Los procesos, timers e IPC cuelgan del plugin y no de la vista, porque la
//  vista se destruye cada vez que la isla cambia de dueño.

import QtQuick
import K4 as K4

K4.Plugin {
    id: self

    name: "grieta"
    title: K4.Idioma.t("La Grieta")
    priority: 64
    active: habilitado && abierto

    property bool abierto: false

    property Simulacion sim: Simulacion {}

    //  La isla CRECE en sobrecarga. Es el aviso más honesto que se puede dar
    //  de que has entrado en algo: no un cartel, la propia barra haciéndose
    //  más grande delante de ti.
    islandWidth: sim.sobrecarga ? 1040 : 900
    islandHeight: sim.sobrecarga ? 400 : 320

    //  El teclado entero mientras está abierto. En cualquier otro módulo esto
    //  sería de más; aquí es literalmente el mando. La vista se queda el ESC
    //  para pausar y lo suelta en pausa, y entonces cierra el de la barra.
    grabKeyboard: abierto

    //  No se cierra al salir el ratón: se está jugando con el teclado y el
    //  puntero puede estar en cualquier parte.
    closeOnHoverExit: false

    handlesBackgroundTap: true
    onBackgroundTapped: {}   // se traga el clic: aquí se juega, no se navega

    function toggle() {
        abierto = !abierto
        if (!abierto)
            close()
    }

    //  El centro de aplicaciones llama a esto.
    function abrir() {
        if (!abierto)
            toggle()
    }

    //  Cerrar el módulo NO mata la partida: la deja en pausa esperando, y la
    //  píldora lo cuenta. Antes se acababa la run al salir, así que atender
    //  una ventana un momento costaba la partida — y una partida que no
    //  puedes dejar a medias no cabe en una barra.
    function close() {
        abierto = false
        if (sim.jugando)
            sim.pausada = true
        soltarBarra()
    }

    function soltarBarra() {
        //  Lo que se le presta a la barra se devuelve al salir: el tinte y el
        //  sitio de la isla. El host barre por id al DESHABILITAR un plugin,
        //  pero cerrar el módulo no es deshabilitarlo, y sin esto la barra se
        //  queda roja y torcida.
        K4.Tema.destintar("grieta")
        K4.Isla.soltar("grieta")
    }

    function cerrar() {
        sim.parar()
        ondaViva = false
        tragando = false
        guardianCayendo = false
        soltarBarra()
    }

    function empezar(claseId) {
        sim.empezar(claseId)
    }

    // ── el ambiente ───────────────────────────────────────────────
    //
    //  La barra ENTERA se tiñe con la partida: rojo que sube con lo abierta
    //  que está la grieta, y un latido de fuerza con la racha. El tope lo
    //  recorta el host en 0.45, así que pedir de más no rompe nada.
    function teñir() {
        if (!abierto || (!sim.jugando && !tragando)) {
            K4.Tema.destintar("grieta")
            return
        }
        //  Al morir se desangra: el tinte se va al tope y luego se apaga
        //  entero. Es medio segundo de barra rota antes de volver a la
        //  normalidad, y vale más que cualquier cartel de «has perdido».
        if (tragando) {
            K4.Tema.tintar("grieta", "#7a0f0f", 0.45, 0)
            return
        }
        const base = 0.10 + sim.fisura * 0.26
        const racha = Math.min(0.10, sim.combo * 0.012)
        //  En sobrecarga el tinte vira a ámbar: el color dice en qué estado
        //  estás sin que haya que leer nada.
        K4.Tema.tintar("grieta", sim.sobrecarga ? "#6b3a08" : "#5c1414",
                       base + racha + (sim.sobrecarga ? 0.08 : 0), 0)
    }

    onAbiertoChanged: teñir()

    Connections {
        target: self.sim
        function onFisuraChanged() { self.teñir() }
        function onComboChanged() { self.teñir() }
        function onJugandoChanged() { self.teñir() }
        function onSobrecargaChanged() { self.teñir() }

        //  El instante de cerrar una capa: todo se para, la onda barre la
        //  pantalla y la isla se desplaza por el borde. Tres cosas a la vez
        //  durante menos de un segundo — el efecto raro impresiona porque la
        //  barra es sobria el resto del tiempo.
        function onCapaCerrada(capa) {
            self.sim.lento = true
            self.ondaViva = true
            respirar.restart()
            K4.Isla.colocar("grieta", capa % 2 === 0 ? 0.28 : 0.72, 1600)
        }

        function onGuardianLlego(id) {
            self.ultimoGuardian = self.sim.catalogoGuardianes.porId(id)
            self.guardianCayendo = false
            //  Llega dando un golpe: la isla lo acusa.
            K4.Isla.efecto("grieta", "empujon", 0.9)
        }

        function onGuardianCaido(id) {
            //  Se va con su onda, como el cierre de una capa pero suya.
            self.guardianCayendo = true
            self.ondaViva = true
            self.retirada.restart()
            K4.Isla.efecto("grieta", "sacudida", 1)
        }

        function onSellada(pid) {
            if (self.conSonido && self.golpe.listo)
                self.golpe.sonar()
        }

        function onFallo(letra) {
            if (self.conSonido && self.yerro.listo)
                self.yerro.sonar()
        }

        function onMuerte() {
            self.apuntarMarcas()
            self.tragando = true
            self.teñir()
            velatorio.restart()
        }
    }

    // ── lo que se pinta fuera de la isla ──────────────────────────
    property bool ondaViva: false
    property bool tragando: false

    //  Se levanta solo mientras hay algo suelto o mientras se lo traga la
    //  grieta: una ventana a pantalla completa viva todo el rato no se paga.
    property var capaFugadas: K4.Cargador {
        active: self.abierto && (self.sim.fugadas.count > 0 || self.tragando)
        Fugadas { sim: self.sim; tragando: self.tragando }
    }

    //  El guardián asoma por encima de la barra mientras esté vivo, y se
    //  queda un momento más mientras se desvanece al caer.
    property bool guardianCayendo: false

    property var capaGuardian: K4.Cargador {
        active: self.abierto
            && (self.sim.guardianActual !== null || self.guardianCayendo)
        Guardian {
            datos: self.sim.guardianActual !== null
                ? self.sim.guardianActual : self.ultimoGuardian
            vida: self.sim.guardianVida
            vidaMaxima: self.ultimoGuardian ? self.ultimoGuardian.vida : 1
            cayendo: self.guardianCayendo
        }
    }

    property var ultimoGuardian: null

    property Timer retirada: Timer {
        interval: 620
        onTriggered: self.guardianCayendo = false
    }

    property var capaOnda: K4.Cargador {
        active: self.ondaViva
        Onda {
            tono: self.sim.sobrecarga ? K4.Tema.amarillo : K4.Tema.verde
            onTerminado: self.ondaViva = false
        }
    }

    property Timer respirar: Timer {
        interval: 420
        onTriggered: self.sim.lento = false
    }

    property Timer velatorio: Timer {
        interval: 720
        onTriggered: {
            self.sim.fugadas.clear()
            self.tragando = false
            self.teñir()
        }
    }

    // ── la píldora ────────────────────────────────────────────────
    //
    //  Solo mientras haya una partida esperando y el módulo esté cerrado: es
    //  para acordarte de que la dejaste a medias, no para llevar la cuenta.
    //  Con el módulo abierto sobra, que ya lo estás mirando.
    readonly property bool avisando: sim.jugando && !abierto

    function pintarAviso() {
        if (!avisando) {
            if (_avisoPuesto) {
                K4.Pildora.quitar("grieta.partida")
                _avisoPuesto = false
            }
            return
        }
        K4.Pildora.registrar("grieta.partida",
                             K4.Idioma.t("capa ") + sim.capa,
                             0x0F140B,
                             sim.fisura >= 0.6 ? K4.Tema.rojo : K4.Tema.apagado,
                             72, true)
        _avisoPuesto = true
    }

    property bool _avisoPuesto: false

    onAvisandoChanged: pintarAviso()

    Connections {
        target: K4.Pildora
        function onInvocado(id) {
            if (id === "grieta.partida" && !self.abierto)
                self.toggle()
        }
    }

    // ── compartir ─────────────────────────────────────────────────
    //
    //  El resultado en emojis, al portapapeles. La grieta del día es la misma
    //  para todo el que tenga k4, así que un «capa 7» de hoy se puede
    //  comparar con el de otro — es lo único que hace que compartirlo
    //  signifique algo, y por eso el texto dice la fecha.
    function tarjeta() {
        const f = K4.Reloj.ahora
        const dia = f.getDate() + "/" + (f.getMonth() + 1)
        let barra = ""
        const rota = Math.round(sim.fisura * 5)
        for (let i = 0; i < 5; ++i)
            barra += i < rota ? "🟥" : "🟩"

        let texto = "La Grieta · " + (sim.diaria
            ? K4.Idioma.t("grieta del ") + dia : K4.Idioma.t("partida suelta"))
        texto += "\n" + sim.clase.nombre
        texto += "\ncapa " + sim.capa + " · " + sim.selladas
            + K4.Idioma.t(" selladas · racha ×") + sim.mejorCombo
        texto += "\n" + barra
        if (sim.nemesis.length)
            texto += "\n" + K4.Idioma.t("me pudo «") + sim.nemesis + "»"
        return texto
    }

    function copiarTarjeta() {
        K4.Sistema.copiar(tarjeta())
        copiado = true
        borrarAviso.restart()
    }

    property bool copiado: false

    property Timer borrarAviso: Timer {
        interval: 2200
        onTriggered: self.copiado = false
    }

    // ── el sonido ─────────────────────────────────────────────────
    //
    //  Del tema del sistema: sin embarcar ficheros, que un juego de barra no
    //  tiene por qué pesar por dos «tics».
    property bool conSonido: true

    property var golpe: K4.Sonido {
        fuente: K4.Sonido.delSistema("message")
        volumen: 0.25
    }

    property var yerro: K4.Sonido {
        fuente: K4.Sonido.delSistema("dialog-error")
        volumen: 0.2
    }

    // ── el atajo ──────────────────────────────────────────────────
    //
    //  El nombre se declara aquí; atarlo a una tecla es cosa de la
    //  configuración del compositor.
    property var atajo: K4.Atajo {
        name: "grieta"
        onPressed: self.toggle()
    }

    // ── lo que sobrevive ──────────────────────────────────────────
    property var guardado: K4.Guardado {
        plugin: "grieta"
        onCargado: function (d) {
            if (d.mejorSelladas !== undefined)
                self.mejorSelladas = Number(d.mejorSelladas) || 0
            if (d.mejorCombo !== undefined)
                self.mejorCombo = Number(d.mejorCombo) || 0
            if (d.diaria !== undefined)
                self.sim.diaria = d.diaria === true
            if (d.fuentesPropias !== undefined)
                self.sim.fuentesPropias = d.fuentesPropias === true
            if (d.conSonido !== undefined)
                self.conSonido = d.conSonido === true
        }
    }

    property int mejorSelladas: 0
    property int mejorCombo: 0

    //  Las marcas se apuntan al morir, en el mismo sitio donde se monta el
    //  velatorio: son dos cosas del mismo momento y separarlas en dos
    //  `Connections` al mismo objeto solo servía para tener que acordarse de
    //  las dos.
    function apuntarMarcas() {
        let cambio = false
        if (sim.selladas > mejorSelladas) {
            mejorSelladas = sim.selladas
            cambio = true
        }
        if (sim.mejorCombo > mejorCombo) {
            mejorCombo = sim.mejorCombo
            cambio = true
        }
        if (cambio)
            apuntar()
    }

    K4.Ajustes {
        plugin: "grieta"
        grupo: K4.Idioma.t("La Grieta")
        opciones: [
            { id: "diaria", nombre: K4.Idioma.t("La grieta del día"),
              desc: K4.Idioma.t("La misma partida para todo el que tenga k4 hoy, y comparable. Apagado, cada run es suya"),
              glifo: 0x0F0EDD },
            { id: "fuentesPropias", nombre: K4.Idioma.t("Palabras de tu máquina"),
              desc: K4.Idioma.t("Mezcla los nombres de tus aplicaciones instaladas con el vocabulario"),
              glifo: 0x0F003B },
            { id: "conSonido", nombre: K4.Idioma.t("Sonido"),
              desc: K4.Idioma.t("Un tic al sellar y otro al fallar, del tema del sistema"),
              glifo: 0x0F057E }
        ]
        valores: ({ diaria: self.sim.diaria,
                    fuentesPropias: self.sim.fuentesPropias,
                    conSonido: self.conSonido })
        onCambiado: function (id, valor) {
            if (id === "diaria")
                self.sim.diaria = valor === true
            else if (id === "fuentesPropias")
                self.sim.fuentesPropias = valor === true
            else if (id === "conSonido")
                self.conSonido = valor === true
            self.apuntar()
        }
    }

    function apuntar() {
        guardado.guardar({ mejorSelladas: mejorSelladas, mejorCombo: mejorCombo,
                           diaria: sim.diaria, fuentesPropias: sim.fuentesPropias,
                           conSonido: conSonido })
    }

    K4.Ipc {
        target: "k4.grieta"
        function toggle(): void { self.toggle() }
        function close(): void { self.close() }
        function jugar(): void {
            if (!self.abierto)
                self.toggle()
            self.empezar()
        }
    }

    view: Component {
        GrietaVista { plugin: self }
    }
}
