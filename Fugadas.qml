//  Lo que se te escapó, vagando por tu escritorio de verdad.
//
//  Esta es la pieza que hace que la isla te importe: una palabra que llega al
//  final no se borra con un «-1 vida», SALE de la barra y se pone a dar
//  vueltas por encima de tu código y de tu navegador, estorbando de verdad,
//  hasta que la caces escribiéndola. Cazarla cierra grieta, así que perseguir
//  lo que se te escapó es la única cura que hay.
//
//  Una `K4.Ventana` es transparente y a pantalla completa, y hay un detalle
//  que muerde: `zonaActiva: null` NO significa «no captures nada», significa
//  que la máscara se apaga y la ventana se traga TODO el ratón. Para una capa
//  que solo pinta hay que darle una zona de tamaño cero.

import QtQuick
import K4 as K4

K4.Ventana {
    id: capa

    required property var sim
    //  El instante en que todo vuelve a la grieta, al morir.
    property bool tragando: false

    nombre: "k4-grieta-fugadas"

    //  Cero píxeles de zona activa: se ve, no se toca. El escritorio de
    //  debajo sigue siendo tuyo mientras juegas.
    zonaActiva: nada
    Item { id: nada; width: 0; height: 0 }

    readonly property var isla: K4.Isla.rect

    Repeater {
        model: capa.sim.fugadas

        delegate: Item {
            id: suelta
            required property var model

            readonly property bool esObjetivo: capa.sim.objetivo === model.pid
            readonly property string hecho:
                model.muestra.substring(0, model.escrito)
            readonly property string resto:
                model.muestra.substring(model.escrito)

            width: caja.width
            height: caja.height

            //  Salen POR la grieta: nacen en el borde de la isla, en un punto
            //  al azar de su ancho, y de ahí se van hacia el escritorio.
            readonly property real nacimientoX:
                capa.isla.x + Math.random() * Math.max(1, capa.isla.ancho - 120)
            readonly property real nacimientoY:
                K4.Isla.posicion === "arriba"
                    ? capa.isla.y + capa.isla.alto - 10
                    : capa.isla.y - 10

            x: nacimientoX
            y: nacimientoY

            //  Deriva lenta y sin rumbo, como algo que no sabe dónde va. Lo
            //  lento importa: si corrieran serían un juego de reflejos, y lo
            //  que tienen que ser es una MOLESTIA que sigue ahí.
            NumberAnimation on x {
                running: !capa.tragando
                to: 60 + Math.random() * Math.max(1, capa.width - 260)
                duration: 26000 + Math.random() * 20000
                easing.type: Easing.InOutSine
                loops: Animation.Infinite
            }

            NumberAnimation on y {
                running: !capa.tragando
                to: capa.height * (0.25 + Math.random() * 0.55)
                duration: 30000 + Math.random() * 22000
                easing.type: Easing.InOutSine
                loops: Animation.Infinite
            }

            //  Al morir, todas vuelven corriendo a la grieta.
            ParallelAnimation {
                running: capa.tragando
                NumberAnimation {
                    target: suelta; property: "x"
                    to: capa.isla.x + capa.isla.ancho / 2
                    duration: 520; easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: suelta; property: "y"
                    to: capa.isla.y + capa.isla.alto / 2
                    duration: 520; easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: suelta; property: "opacity"
                    to: 0; duration: 520
                }
                NumberAnimation {
                    target: suelta; property: "scale"
                    to: 0.4; duration: 520
                }
            }

            Rectangle {
                id: caja
                width: linea.width + 18
                height: linea.height + 10
                radius: 8
                color: Qt.rgba(0, 0, 0, 0.72)
                border.width: 1
                border.color: suelta.esObjetivo ? K4.Tema.azul : K4.Tema.rojo
                opacity: suelta.esObjetivo ? 1 : 0.82

                Row {
                    id: linea
                    anchors.centerIn: parent
                    spacing: 0

                    K4.Etiqueta {
                        text: suelta.hecho
                        color: K4.Tema.verde
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    K4.Etiqueta {
                        text: suelta.resto
                        color: K4.Tema.rojo
                        font.pixelSize: 15
                    }
                }

                //  Late despacio: algo vivo que no se ha ido.
                SequentialAnimation on opacity {
                    running: !suelta.esObjetivo && !capa.tragando
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.5; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.85; duration: 1400; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}
