//  Tu teclado, dibujado y sufriendo.
//
//  Se ve qué teclas tienes despiertas —que es tu clase— y cuál acabas de
//  pulsar. Aquí vivían las teclas rotas, agrietadas y humeando; se fueron con
//  la mecánica que las rompía, porque quitarle letras a quien está tecleando
//  se pelea con el verbo del juego.
//
//  Distribución española, que es la que hay debajo de los dedos: con la ñ.

import QtQuick
import K4 as K4

Item {
    id: teclado

    property string circulo: ""
    property string ultima: ""
    //  El Farolero lo apaga entero: se teclea a ciegas mientras esté delante.
    property bool aOscuras: false

    readonly property var filas: ["qwertyuiop", "asdfghjklñ", "zxcvbnm"]
    readonly property real lado: Math.max(16, Math.min(28, width / 13))

    Column {
        anchors.centerIn: parent
        spacing: 3
        opacity: teclado.aOscuras ? 0.06 : 1

        Behavior on opacity { NumberAnimation { duration: 420 } }

        Repeater {
            model: teclado.filas

            delegate: Row {
                id: fila
                required property string modelData
                required property int index

                spacing: 3
                //  Escalonadas como un teclado de verdad: alineadas se leen
                //  como una tabla y dejan de parecer un teclado.
                leftPadding: index * (teclado.lado * 0.45)

                Repeater {
                    model: fila.modelData.length

                    delegate: Rectangle {
                        id: tecla
                        required property int index

                        readonly property string letra: fila.modelData[index]
                        readonly property bool despierta:
                            teclado.circulo.indexOf(letra) >= 0
                        readonly property bool pulsada: teclado.ultima === letra

                        width: teclado.lado
                        height: teclado.lado
                        radius: 4

                        color: pulsada ? K4.Tema.azul
                            : despierta ? K4.Tema.superficieAlta
                            : K4.Tema.superficie

                        opacity: despierta ? 1 : 0.35

                        Behavior on color { ColorAnimation { duration: 90 } }

                        K4.Etiqueta {
                            anchors.centerIn: parent
                            text: tecla.letra
                            font.pixelSize: 12
                            font.weight: tecla.pulsada ? Font.Bold : Font.Normal
                            color: tecla.despierta ? K4.Tema.tinta : K4.Tema.tenue
                        }

                    }
                }
            }
        }
    }
}
