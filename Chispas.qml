//  Lo que queda de una palabra sellada: sus propias LETRAS, reventadas.
//
//  Antes eran cuadraditos verdes, y era correcto y no era nada. En un juego
//  cuya materia son las letras, lo que tiene que estallar son las letras: se
//  desmoronan de donde estaban, salen despedidas y la grieta se las traga.
//  La lectura tiene que ser «esto vuelve dentro», no «esto se ha borrado».
//
//  Y revienta más cuanto más valía: con racha alta salen más lejos, más
//  grandes y en el color de la racha. Que sellar una palabra de nueve letras
//  con ×12 se vea distinto de sellar «sol» es la mitad del premio.
//
//  Sin módulo de partículas: son las letras con su animación. A este tamaño
//  no se nota la diferencia y el plugin no importa nada más que QtQuick y K4.

import QtQuick
import K4 as K4

Item {
    id: chispas

    property string palabra: ""
    property color tono: K4.Tema.verde
    property real fuerza: 1          // 1 normal, más con racha
    property bool haciaArriba: true
    property int duracionMs: 700

    signal terminado()

    property var _semillas: []

    Component.onCompleted: {
        const letras = palabra.length ? palabra.split("") : ["·"]
        const s = []
        for (let i = 0; i < letras.length; ++i) {
            //  Salen en abanico desde donde estaban, no al azar puro: se
            //  reconoce la palabra deshaciéndose en vez de un puñado de ruido.
            const reparto = letras.length > 1 ? (i / (letras.length - 1) - 0.5) : 0
            s.push({
                letra: letras[i],
                dx: reparto * 150 * chispas.fuerza + (Math.random() - 0.5) * 40,
                dy: (40 + Math.random() * 80) * chispas.fuerza
                    * (haciaArriba ? -1 : 1),
                giro: (Math.random() - 0.5) * 180 * chispas.fuerza,
                retraso: i * 22
            })
        }
        _semillas = s
        muerte.start()
    }

    Timer {
        id: muerte
        interval: chispas.duracionMs + 220
        onTriggered: chispas.terminado()
    }

    Repeater {
        model: chispas._semillas.length

        delegate: K4.Etiqueta {
            id: trozo
            required property int index

            readonly property var s: chispas._semillas[index]

            text: s.letra
            color: chispas.tono
            font.pixelSize: Math.round(17 * Math.min(1.8, chispas.fuerza))
            font.weight: Font.Bold
            x: 0
            y: 0

            ParallelAnimation {
                running: true

                SequentialAnimation {
                    PauseAnimation { duration: trozo.s.retraso }
                    ParallelAnimation {
                        NumberAnimation {
                            target: trozo; property: "x"
                            to: trozo.s.dx
                            duration: chispas.duracionMs
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: trozo; property: "y"
                            to: trozo.s.dy
                            duration: chispas.duracionMs
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: trozo; property: "rotation"
                            to: trozo.s.giro
                            duration: chispas.duracionMs
                        }
                        NumberAnimation {
                            target: trozo; property: "opacity"
                            from: 1; to: 0
                            duration: chispas.duracionMs
                            easing.type: Easing.InQuad
                        }
                    }
                }
            }
        }
    }
}
