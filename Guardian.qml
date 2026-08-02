//  El guardián, asomando por encima de la isla.
//
//  Este es el fotograma que vende el juego: algo MÁS GRANDE QUE LA BARRA que
//  sale de detrás y se queda ahí mirándote mientras peleas. Por eso vive en
//  una `K4.Ventana` anclada a `K4.Isla.rect` y no dentro de la isla — dentro
//  cabría, y cabiendo no impresiona.
//
//  Sube al llegar, se queda respirando, y al caer se va hacia atrás
//  desvaneciéndose. Nunca captura el ratón: zona activa de tamaño cero.

import QtQuick
import K4 as K4

K4.Ventana {
    id: capa

    required property var datos          // del catálogo de guardianes
    property int vida: 0
    property int vidaMaxima: 1
    property bool cayendo: false

    nombre: "k4-grieta-guardian"

    zonaActiva: nada
    Item { id: nada; width: 0; height: 0 }

    readonly property var isla: K4.Isla.rect
    readonly property bool arriba: K4.Isla.posicion === "arriba"

    Item {
        id: figura

        width: 168
        height: 168

        x: capa.isla.x + capa.isla.ancho / 2 - width / 2
        //  Pegado al filo de la isla por su lado de dentro de la pantalla, y
        //  asomando por encima: se solapa con la barra a propósito, que es lo
        //  que hace que parezca que sale de ella y no que flota al lado.
        y: capa.arriba
            ? capa.isla.y + capa.isla.alto - height * 0.62
            : capa.isla.y - height * 0.38

        opacity: 0
        scale: 0.6

        Component.onCompleted: subir.start()

        ParallelAnimation {
            id: subir
            NumberAnimation {
                target: figura; property: "opacity"
                to: 1; duration: 520
            }
            NumberAnimation {
                target: figura; property: "scale"
                to: 1; duration: 620
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
        }

        ParallelAnimation {
            running: capa.cayendo
            NumberAnimation {
                target: figura; property: "opacity"
                to: 0; duration: 520
            }
            NumberAnimation {
                target: figura; property: "scale"
                to: 0.5; duration: 520
                easing.type: Easing.InCubic
            }
        }

        //  Respira: sin esto es una calcomanía pegada a la barra.
        SequentialAnimation on y {
            running: !capa.cayendo
            loops: Animation.Infinite
            NumberAnimation { to: figura.y - 6; duration: 1700; easing.type: Easing.InOutSine }
            NumberAnimation { to: figura.y + 6; duration: 1700; easing.type: Easing.InOutSine }
        }

        Image {
            id: retrato
            anchors.fill: parent
            source: Qt.resolvedUrl("assets/" + capa.datos.emblema)
            sourceSize.width: 168
            sourceSize.height: 168
            smooth: true
            mipmap: true
        }
    }

    //  El nombre y la regla, al lado de la isla y no encima: encima taparían
    //  justo las palabras que hay que leer.
    Column {
        x: capa.isla.x + capa.isla.ancho + 14
        y: capa.isla.y + capa.isla.alto / 2 - height / 2
        spacing: 3
        opacity: capa.cayendo ? 0 : 1
        visible: x + 240 < capa.width

        Behavior on opacity { NumberAnimation { duration: 320 } }

        K4.Etiqueta {
            text: capa.datos.nombre
            color: K4.Tema.rojo
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        K4.Etiqueta {
            text: K4.Idioma.t(capa.datos.regla)
            color: K4.Tema.apagado
            font.pixelSize: 10
            width: 220
            wrapMode: Text.WordWrap
        }

        //  La vida, en marcas y no en número: cuántas le quedan se cuenta de
        //  un vistazo sin dejar de mirar lo que cae.
        Row {
            spacing: 4
            topPadding: 4

            Repeater {
                model: capa.vidaMaxima

                delegate: Rectangle {
                    required property int index
                    width: 14
                    height: 4
                    radius: 2
                    color: index < capa.vida ? K4.Tema.rojo : K4.Tema.carril

                    Behavior on color { ColorAnimation { duration: 220 } }
                }
            }
        }
    }
}
