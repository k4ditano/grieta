//  El anillo que barre el escritorio al cerrar una capa.
//
//  Un fotograma de gloria cada pocas palabras: un aro de luz que sale de la
//  isla, cruza toda la pantalla y se apaga en menos de un segundo. Es caro de
//  mirar y baratísimo de hacer —un rectángulo con el radio a la mitad y dos
//  animaciones—, y es lo que convierte «has subido de nivel» en algo que se
//  siente en el escritorio entero y no en un número que cambia.
//
//  Se carga solo mientras dura y se destruye: una ventana a pantalla completa
//  viva todo el rato para enseñar algo que dura 700 ms no se paga.

import QtQuick
import K4 as K4

K4.Ventana {
    id: capa

    property color tono: K4.Tema.verde
    property int duracionMs: 720

    signal terminado()

    nombre: "k4-grieta-onda"

    //  Se ve, no se toca: con la zona a cero, el escritorio de debajo sigue
    //  recibiendo el ratón mientras el anillo lo cruza.
    zonaActiva: nada
    Item { id: nada; width: 0; height: 0 }

    readonly property var isla: K4.Isla.rect
    readonly property real centroX: isla.x + isla.ancho / 2
    readonly property real centroY: isla.y + isla.alto / 2
    //  Hasta la esquina más lejana, para que salga de la pantalla y no se
    //  quede a medias en un monitor ancho.
    readonly property real alcance: Math.max(
        Math.hypot(centroX, centroY),
        Math.hypot(capa.width - centroX, capa.height - centroY))

    Rectangle {
        id: aro
        property real radio: 0

        x: capa.centroX - radio
        y: capa.centroY - radio
        width: radio * 2
        height: radio * 2
        radius: radio
        color: "transparent"
        border.width: 3
        border.color: capa.tono
        opacity: 0

        Component.onCompleted: barrido.start()

        ParallelAnimation {
            id: barrido

            NumberAnimation {
                target: aro; property: "radio"
                from: Math.max(40, capa.isla.ancho / 2)
                to: capa.alcance
                duration: capa.duracionMs
                easing.type: Easing.OutQuad
            }

            SequentialAnimation {
                NumberAnimation {
                    target: aro; property: "opacity"
                    from: 0; to: 0.85
                    duration: Math.round(capa.duracionMs * 0.18)
                }
                NumberAnimation {
                    target: aro; property: "opacity"
                    to: 0
                    duration: Math.round(capa.duracionMs * 0.82)
                    easing.type: Easing.InQuad
                }
            }

            //  El trazo se afina según crece: un aro que se estira sin
            //  adelgazar parece un círculo dibujado, no una onda.
            NumberAnimation {
                target: aro; property: "border.width"
                from: 5; to: 1
                duration: capa.duracionMs
            }

            onFinished: capa.terminado()
        }
    }
}
