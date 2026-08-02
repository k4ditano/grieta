//  La raja de la isla, que es la barra de vida.
//
//  No hay número ni barra: lo que se enseña es lo ROTA que está la barra. Se
//  dibuja pegada al borde de la pantalla —arriba o abajo, lo que diga la
//  isla— y se abre con cada palabra que se escapa, hasta partirla.
//
//  Los dientes se sortean una vez y se quedan: una fisura que baila cada
//  fotograma parece un efecto, y esto tiene que parecer un daño.

import QtQuick
import K4 as K4

Item {
    id: fisura

    //  De 0 a 1.
    property real abierta: 0
    //  Hacia dónde crece: si la barra vive arriba, la grieta abre hacia abajo.
    property bool haciaAbajo: true
    property color tono: K4.Tema.rojo

    //  Cuántos dientes y cuánto muerden. El alto máximo es el de la banda.
    readonly property int dientes: 34
    readonly property real bocado: 4 + abierta * 22

    property var _semillas: []

    Component.onCompleted: {
        const s = []
        for (let i = 0; i < dientes; ++i)
            s.push(0.35 + Math.random() * 0.65)
        _semillas = s
    }

    Behavior on abierta {
        NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
    }

    //  El resplandor: tres capas cada vez más tenues en lugar de un desenfoque
    //  de verdad, que traería otro módulo de Qt encima. A este tamaño no se
    //  distingue, y lo que no se distingue no se paga.
    Repeater {
        model: 3

        delegate: Rectangle {
            required property int index
            width: fisura.width
            height: (3 + index * 7) * (0.4 + fisura.abierta)
            y: fisura.haciaAbajo ? 0 : fisura.height - height
            color: fisura.tono
            opacity: (0.30 - index * 0.09) * (0.35 + fisura.abierta * 0.65)
        }
    }

    //  La línea viva.
    Rectangle {
        width: fisura.width
        height: 1 + fisura.abierta * 2
        y: fisura.haciaAbajo ? 0 : fisura.height - height
        color: Qt.lighter(fisura.tono, 1.5)
        opacity: 0.5 + fisura.abierta * 0.5
    }

    //  Los dientes, que son lo que la hace parecer rota y no pintada.
    Repeater {
        model: fisura._semillas.length

        delegate: Rectangle {
            required property int index

            readonly property real semilla: fisura._semillas[index] || 0.5

            width: Math.max(1, fisura.width / fisura.dientes * 0.42)
            height: fisura.bocado * semilla
            x: index * (fisura.width / fisura.dientes)
                + (fisura.width / fisura.dientes) * 0.29
            y: fisura.haciaAbajo ? 0 : fisura.height - height
            color: fisura.tono
            opacity: 0.35 + fisura.abierta * 0.55

            Behavior on height {
                NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
            }
        }
    }
}
