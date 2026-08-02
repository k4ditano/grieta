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
            cerrar()
    }

    //  El centro de aplicaciones llama a esto.
    function abrir() {
        if (!abierto)
            toggle()
    }

    function close() {
        abierto = false
        cerrar()
    }

    function cerrar() {
        sim.parar()
        ondaViva = false
        tragando = false
        guardianCayendo = false
        //  Y soltar lo que se le haya prestado a la barra: el tinte y el
        //  sitio de la isla. El host también barre por id al deshabilitar un
        //  plugin, pero cerrar el módulo no es deshabilitarlo — si no se
        //  suelta aquí, la barra se queda roja y torcida.
        K4.Tema.destintar("grieta")
        K4.Isla.soltar("grieta")
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

    // ── lo que sobrevive ──────────────────────────────────────────
    property var guardado: K4.Guardado {
        plugin: "grieta"
        onCargado: function (d) {
            if (d.mejorSelladas !== undefined)
                self.mejorSelladas = Number(d.mejorSelladas) || 0
            if (d.mejorCombo !== undefined)
                self.mejorCombo = Number(d.mejorCombo) || 0
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
            guardado.guardar({ mejorSelladas: mejorSelladas,
                               mejorCombo: mejorCombo })
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
