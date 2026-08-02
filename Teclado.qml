//  Tu teclado, dibujado y sufriendo.
//
//  Es la interfaz y es el espectáculo a la vez: se ve qué teclas tienes
//  despiertas, cuál acabas de pulsar y cuáles has roto tú mismo. Las
//  corruptas salen agrietadas y humeando, y esa mancha roja creciendo en tu
//  propia fila de teclas es la mejor manera de contarte que estás perdiendo.
//
//  Distribución española, que es la que hay debajo de los dedos: con la ñ.

import QtQuick
import K4 as K4

Item {
    id: teclado

    property string circulo: ""
    property var corruptas: ({})
    property string ultima: ""
    //  El Farolero lo apaga entero: se teclea a ciegas mientras esté delante.
    property bool aOscuras: false

    readonly property var filas: ["qwertyuiop", "asdfghjklñ", "zxcvbnm"]
    readonly property real lado: Math.max(14, Math.min(22, width / 13))

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
                        readonly property bool rota:
                            teclado.corruptas[letra] !== undefined
                        readonly property bool pulsada: teclado.ultima === letra

                        width: teclado.lado
                        height: teclado.lado
                        radius: 4

                        color: rota ? Qt.rgba(0.55, 0.12, 0.12, 0.85)
                            : pulsada ? K4.Tema.azul
                            : despierta ? K4.Tema.superficieAlta
                            : K4.Tema.superficie

                        opacity: despierta || rota ? 1 : 0.35

                        Behavior on color { ColorAnimation { duration: 90 } }

                        K4.Etiqueta {
                            anchors.centerIn: parent
                            text: tecla.letra
                            font.pixelSize: 10
                            font.weight: tecla.pulsada ? Font.Bold : Font.Normal
                            color: tecla.rota ? K4.Tema.rojo
                                : tecla.despierta ? K4.Tema.tinta : K4.Tema.tenue
                        }

                        //  La raja de la tecla, cruzándola.
                        Rectangle {
                            visible: tecla.rota
                            anchors.centerIn: parent
                            width: parent.width * 0.9
                            height: 1
                            rotation: 38
                            color: K4.Tema.rojo
                            opacity: 0.9
                        }

                        //  Y el humo, que es lo que la hace verse rota de lejos.
                        Rectangle {
                            visible: tecla.rota
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            width: 3
                            height: 7
                            radius: 2
                            color: K4.Tema.rojo

                            SequentialAnimation on opacity {
                                running: tecla.rota
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.55; to: 0; duration: 900 }
                                PauseAnimation { duration: 160 }
                            }
                        }
                    }
                }
            }
        }
    }
}
