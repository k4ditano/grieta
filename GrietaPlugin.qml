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

    islandWidth: 900
    islandHeight: 320

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
        K4.Tema.destintar("grieta")
    }

    function empezar() {
        sim.empezar()
    }

    // ── el ambiente ───────────────────────────────────────────────
    //
    //  La barra ENTERA se tiñe con la partida: rojo que sube con lo abierta
    //  que está la grieta, y un latido de fuerza con la racha. El tope lo
    //  recorta el host en 0.45, así que pedir de más no rompe nada.
    function teñir() {
        if (!abierto || !sim.jugando) {
            K4.Tema.destintar("grieta")
            return
        }
        const base = 0.10 + sim.fisura * 0.26
        const racha = Math.min(0.10, sim.combo * 0.012)
        K4.Tema.tintar("grieta", "#5c1414", base + racha, 0)
    }

    onAbiertoChanged: teñir()

    Connections {
        target: self.sim
        function onFisuraChanged() { self.teñir() }
        function onComboChanged() { self.teñir() }
        function onJugandoChanged() { self.teñir() }
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

    Connections {
        target: self.sim
        function onMuerte() {
            let cambio = false
            if (self.sim.selladas > self.mejorSelladas) {
                self.mejorSelladas = self.sim.selladas
                cambio = true
            }
            if (self.sim.mejorCombo > self.mejorCombo) {
                self.mejorCombo = self.sim.mejorCombo
                cambio = true
            }
            if (cambio)
                self.guardado.guardar({ mejorSelladas: self.mejorSelladas,
                                        mejorCombo: self.mejorCombo })
        }
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
