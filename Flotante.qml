//  Un número que sale despedido y se apaga: «+24», «−5 s», «CAPA 4».
//
//  Es la gramática del arcade y no hay mucho más que decir: lo que ganas y lo
//  que pierdes tiene que SALTAR del sitio donde ha pasado, no aparecer en un
//  marcador de la esquina. Un contador que sube en silencio no se celebra;
//  un número que te salta en la cara, sí.
//
//  Se destruye solo al acabar, así que quien lo crea no tiene que acordarse.

import QtQuick
import K4 as K4

Item {
    id: flotante

    property string texto: ""
    property color tono: K4.Tema.verde
    property int tamano: 18
    //  Hacia dónde sale. Lo normal es hacia el filo de la pantalla, que es
    //  donde está la grieta: lo que ganas se lo lleva ella.
    property int haciaY: -46
    property int duracionMs: 900

    signal terminado()

    width: etiqueta.width
    height: etiqueta.height

    K4.Etiqueta {
        id: etiqueta
        text: flotante.texto
        color: flotante.tono
        font.pixelSize: flotante.tamano
        font.weight: Font.Bold
    }

    //  Sale con un golpe de escala y se va subiendo. El golpe es lo que hace
    //  que se lea como un impacto y no como una notificación.
    ParallelAnimation {
        running: true

        SequentialAnimation {
            NumberAnimation {
                target: flotante; property: "scale"
                from: 0.4; to: 1.25
                duration: Math.round(flotante.duracionMs * 0.18)
                easing.type: Easing.OutBack
                easing.overshoot: 3
            }
            NumberAnimation {
                target: flotante; property: "scale"
                to: 1
                duration: Math.round(flotante.duracionMs * 0.14)
            }
        }

        NumberAnimation {
            target: flotante; property: "y"
            to: flotante.y + flotante.haciaY
            duration: flotante.duracionMs
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            PauseAnimation { duration: Math.round(flotante.duracionMs * 0.45) }
            NumberAnimation {
                target: flotante; property: "opacity"
                to: 0
                duration: Math.round(flotante.duracionMs * 0.55)
            }
        }

        onFinished: flotante.terminado()
    }
}
