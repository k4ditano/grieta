//  La elección entre capa y capa: por dónde bajas, y con qué.
//
//  Es la única pausa de la partida y por eso ocupa la isla entera: todo lo
//  demás pasa con las manos puestas en el teclado, así que el momento de
//  pensar tiene que distinguirse a la vista del momento de teclear.
//
//  Sirve para las dos pantallas —salas y runas— porque son la misma cosa:
//  fichas, una marcada, y flechas para moverse. Duplicarlo era pedir que se
//  desincronizaran dentro de dos semanas.

import QtQuick
import K4 as K4

Item {
    id: ruta

    property var opciones: []
    property int elegida: 0
    property string titulo: ""
    property string pie: ""
    //  Cuál de las ofrecidas cobra una tecla por llevártela, o -1.
    property int maldita: -1

    Column {
        anchors.centerIn: parent
        spacing: 10

        K4.Etiqueta {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ruta.titulo
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Repeater {
                model: ruta.opciones

                delegate: Rectangle {
                    id: ficha
                    required property var modelData
                    required property int index

                    readonly property bool puesta: ruta.elegida === index
                    readonly property bool cobra: ruta.maldita === index

                    width: 178
                    height: 104
                    radius: 11
                    color: puesta ? K4.Tema.superficieAlta : K4.Tema.superficie
                    border.width: puesta ? 1 : 0
                    //  La maldita se marca en rojo desde antes de tocarla:
                    //  una trampa que no se ve no es una decisión.
                    border.color: cobra ? K4.Tema.rojo : K4.Tema.azul
                    opacity: puesta ? 1 : 0.58

                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        width: parent.width - 18

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: Qt.resolvedUrl("assets/" + ficha.modelData.emblema)
                            sourceSize.width: 32
                            sourceSize.height: 32
                            width: 32
                            height: 32
                            smooth: true
                        }

                        K4.Etiqueta {
                            width: parent.width
                            text: ficha.modelData.nombre
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                        }

                        K4.Etiqueta {
                            width: parent.width
                            text: K4.Idioma.t(ficha.modelData.desc)
                            color: K4.Tema.apagado
                            font.pixelSize: 9
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        K4.Etiqueta {
                            width: parent.width
                            visible: ficha.cobra
                            text: K4.Idioma.t("maldita · te rompe una tecla")
                            color: K4.Tema.rojo
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }

        K4.Etiqueta {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ruta.pie
            color: K4.Tema.tenue
            font.pixelSize: 11
        }
    }
}
