//  Lo que queda de una palabra sellada.
//
//  No desaparece: se desmorona. Las letras se rompen en chispas que salen
//  despedidas y caen HACIA la grieta, que es la que se las traga — la lectura
//  tiene que ser «esto vuelve dentro», no «esto se ha borrado».
//
//  Sin módulo de partículas: son doce rectángulos con su animación. A este
//  tamaño no se nota la diferencia, y así el plugin no importa nada más que
//  QtQuick y K4, que es el contrato de un plugin de fuera.

import QtQuick
import K4 as K4

Item {
    id: chispas

    property int cuantas: 18
    property color tono: K4.Tema.verde
    //  Hacia dónde se las lleva la grieta.
    property bool haciaArriba: true
    property int duracionMs: 620

    signal terminado()

    property var _semillas: []

    Component.onCompleted: {
        const s = []
        for (let i = 0; i < cuantas; ++i) {
            s.push({
                dx: (Math.random() - 0.5) * 120,
                dy: (28 + Math.random() * 70) * (haciaArriba ? -1 : 1),
                lado: 2.5 + Math.random() * 4,
                retraso: Math.random() * 90
            })
        }
        _semillas = s
        muerte.start()
    }

    Timer {
        id: muerte
        interval: chispas.duracionMs + 140
        onTriggered: chispas.terminado()
    }

    Repeater {
        model: chispas._semillas.length

        delegate: Rectangle {
            id: chispa
            required property int index

            readonly property var s: chispas._semillas[index]

            width: s.lado
            height: s.lado
            radius: 1
            color: chispas.tono
            x: 0
            y: 0

            ParallelAnimation {
                running: true

                NumberAnimation {
                    target: chispa; property: "x"
                    to: chispa.s.dx
                    duration: chispas.duracionMs
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: chispa; property: "y"
                    to: chispa.s.dy
                    duration: chispas.duracionMs
                    easing.type: Easing.InCubic
                }
                SequentialAnimation {
                    PauseAnimation { duration: chispa.s.retraso }
                    NumberAnimation {
                        target: chispa; property: "opacity"
                        from: 1; to: 0
                        duration: chispas.duracionMs - chispa.s.retraso
                        easing.type: Easing.InQuad
                    }
                }
            }
        }
    }
}
