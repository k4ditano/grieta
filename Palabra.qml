//  Una palabra saliendo de la grieta.
//
//  El recorrido lo lleva una animación y no un Timer: un Timer de 16 ms no da
//  60 Hz y se ve el tirón. Cuando termina, avisa —`escapo()`— y es la
//  simulación quien decide lo que eso cuesta; aquí solo se sabe de píxeles.
//
//  Se pinta en dos trozos, lo ya tecleado y lo que falta, para saber por
//  dónde vas sin tener que contar letras.

import QtQuick
import K4 as K4

Item {
    id: palabra

    property string muestra: ""
    property int escrito: 0
    property string tipo: "llana"

    //  Cuánto tarda en cruzar. Lo pone la vista según la capa.
    property int duracionMs: 8000
    property bool detenida: false
    property bool esObjetivo: false

    signal escapo()

    property real avance: 0

    readonly property string hecho: muestra.substring(0, escrito)
    readonly property string resto: muestra.substring(escrito)
    readonly property bool espejo: tipo === "espejo"
    readonly property bool nemesis: tipo === "nemesis"
    //  Un borrón: lo que cae cuando fallas una letra que no empieza nada. Se
    //  distingue para que se lea como consecuencia de un error y no como un
    //  enemigo más, que si no parece que el juego hace trampas.
    readonly property bool borron: tipo === "borron"
    property int manchas: 0
    //  El aviso de que queda poco: pasado el 75% del recorrido, late.
    readonly property bool urgente: avance > 0.75

    width: fondo.width
    height: fondo.height

    //  `paused` y NO `running`, y la diferencia es todo.
    //
    //  Una animación de QML no se reanuda al volver a ponerle `running`: se
    //  REINICIA desde `from`. Parando con `running` —al pausar, al cerrar una
    //  capa, en la cámara lenta— todas las palabras volvían de golpe a
    //  `avance 0`: aparecían otra vez arriba, todas juntas y a la misma
    //  altura, en fila. Se veía a partir de la tercera o cuarta capa, que es
    //  cuando ya has cerrado unas cuantas, y tiraba por tierra la regla de
    //  que la de más abajo es la más urgente.
    //
    //  `paused` congela donde está y sigue por donde iba.
    NumberAnimation on avance {
        from: 0
        to: 1
        duration: palabra.duracionMs
        running: true
        paused: palabra.detenida
        onFinished: if (!palabra.detenida) palabra.escapo()
    }

    Rectangle {
        id: fondo
        width: fila.width + 26
        height: fila.height + 14
        radius: 9
        color: palabra.esObjetivo ? K4.Tema.superficieAlta : K4.Tema.superficie
        opacity: palabra.esObjetivo ? 0.97 : 0.78

        border.width: palabra.nemesis ? 2
            : (palabra.esObjetivo || palabra.borron) ? 1 : 0
        //  El némesis se distingue de todo lo demás: es TU palabra, la que
        //  dejaste escapar, y tiene que reconocerse desde la otra punta.
        border.color: palabra.nemesis ? K4.Tema.rojo
            : palabra.borron ? K4.Tema.apagado : K4.Tema.azul

        Behavior on color { ColorAnimation { duration: 130 } }

        //  El espejo se marca con un borde tenue: hay que poder saber que lo
        //  es ANTES de empezar a teclearlo, o es una emboscada y no un enemigo.
        Rectangle {
            visible: palabra.espejo
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: K4.Tema.amarillo
            opacity: 0.55
        }

        Row {
            id: fila
            anchors.centerIn: parent
            spacing: 0

            K4.Etiqueta {
                text: palabra.hecho
                color: K4.Tema.verde
                font.pixelSize: 21
                font.weight: Font.DemiBold
            }

            K4.Etiqueta {
                text: palabra.resto
                color: palabra.urgente ? K4.Tema.rojo
                    : palabra.nemesis ? K4.Tema.amarillo
                    //  Manchada por tus fallos: se tiñe, para que se vea que
                    //  ha crecido y por qué.
                    : palabra.manchas > 0 ? K4.Tema.amarillo
                    : palabra.borron ? K4.Tema.apagado : K4.Tema.tinta
                font.pixelSize: 21
                font.weight: palabra.esObjetivo ? Font.DemiBold : Font.Normal
            }
        }
    }

    //  El latido de lo que está a punto de escaparse.
    SequentialAnimation on scale {
        running: palabra.urgente && !palabra.detenida
        loops: Animation.Infinite
        NumberAnimation { to: 1.07; duration: 260; easing.type: Easing.OutQuad }
        NumberAnimation { to: 1.00; duration: 260; easing.type: Easing.InQuad }
    }
}
