//  La isla convertida en grieta.
//
//  Reparto: la simulación sabe QUÉ hay y esto sabe DÓNDE está. El recorrido
//  de cada palabra lo lleva su propia animación, y cuando termina avisa hacia
//  dentro; aquí no hay ningún reloj moviendo cosas a mano.
//
//  La grieta se pega al borde de la PANTALLA, así que si la barra vive abajo
//  todo se da la vuelta: `K4.Isla.posicion` lo dice y es lo único que hay que
//  mirar para no dar por hecho que arriba es arriba.

import QtQuick
import K4 as K4

K4.Aparicion {
    id: vista

    required property var plugin

    readonly property var sim: plugin.sim
    readonly property bool arriba: K4.Isla.posicion === "arriba"

    readonly property int altoFisura: 30
    readonly property int altoTeclado: 78
    //  Por dónde salen y hasta dónde llegan. Cruzar la isla entera es el
    //  tiempo que tienes para escribir.
    readonly property real salida: arriba ? altoFisura : height - altoFisura
    //  Se para ANTES del teclado dibujado: llegando justo al borde, la
    //  palabra se montaba encima de las teclas y las dos cosas se volvían
    //  ilegibles en el momento en el que más falta hace leerlas.
    readonly property real final: arriba ? height - altoTeclado - 16
                                         : altoTeclado + 16

    property string ultimaTecla: ""

    readonly property var clases: sim.circulos.lista
    property int elegida: 0
    property int cursorRuta: 0

    // ── el teclado de verdad ──────────────────────────────────────
    //
    //  Con `grabKeyboard` la capa recibe TODAS las teclas mientras está
    //  abierta, que en un juego de tecleo no es un coste: es el juego.
    Item {
        anchors.fill: parent
        focus: true

        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: function (ev) {
            //  La repetición automática NO cuenta. Se vio jugando: al sellar
            //  una palabra, la última tecla seguía repitiéndose sola un
            //  instante, ya sin objetivo, y se corrompía esa misma letra —
            //  te castigaba por haber acertado. Y un jugador que deja el dedo
            //  puesto medio segundo dispararía diez letras.
            if (ev.isAutoRepeat) {
                ev.accepted = true
                return
            }

            //  ESC: jugando, PAUSA y se queda la tecla. En pausa se deja
            //  pasar, y entonces el ESC del host cierra el módulo. La misma
            //  tecla hace lo de dentro primero y lo de fuera después, que es
            //  el contrato de la barra.
            if (ev.key === Qt.Key_Escape) {
                if (vista.sim.jugando && !vista.sim.pausada) {
                    vista.sim.alternarPausa()
                    ev.accepted = true
                }
                return
            }

            if (ev.key === Qt.Key_Backspace) {
                vista.sim.soltar()
                ev.accepted = true
                return
            }

            //  El Tab limpia una tecla rota. Es la única tecla del teclado que
            //  no forma parte de ninguna palabra, así que puede tener una
            //  función sin robársela a nadie — y se alcanza con el meñique sin
            //  soltar la postura, que en un juego de tecleo importa.
            if (ev.key === Qt.Key_Tab || ev.key === Qt.Key_Backtab) {
                if (vista.sim.jugando && !vista.sim.pausada)
                    vista.sim.limpiar()
                ev.accepted = true
                return
            }

            //  La ruta se lleva las teclas antes que nadie: mientras se elige
            //  no se está tecleando palabras, y una letra suelta aquí no debe
            //  romperte una tecla por accidente.
            if (vista.sim.enRuta) {
                const n = vista.sim.pasoRuta === "salas"
                    ? vista.sim.ofertaSalas.length : vista.sim.ofertaRunas.length
                if (ev.key === Qt.Key_Left || ev.key === Qt.Key_Up) {
                    vista.cursorRuta = (vista.cursorRuta + n - 1) % n
                } else if (ev.key === Qt.Key_Right || ev.key === Qt.Key_Down) {
                    vista.cursorRuta = (vista.cursorRuta + 1) % n
                } else if (ev.key >= Qt.Key_1 && ev.key < Qt.Key_1 + n) {
                    vista.cursorRuta = ev.key - Qt.Key_1
                } else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter
                           || ev.key === Qt.Key_Space) {
                    const i = vista.cursorRuta
                    vista.cursorRuta = 0
                    if (vista.sim.pasoRuta === "salas")
                        vista.sim.elegirSala(i)
                    else
                        vista.sim.elegirRuna(i)
                }
                ev.accepted = true
                return
            }

            if (!vista.sim.jugando) {
                //  Copiar el resultado. Solo tras una partida, que copiar el
                //  marcador en blanco no le sirve a nadie.
                if ((ev.key === Qt.Key_C) && vista.sim.selladas > 0) {
                    vista.plugin.copiarTarjeta()
                    ev.accepted = true
                    return
                }
                //  El elegir clase: flechas o 1-4 para moverse, Enter empieza.
                if (ev.key === Qt.Key_Left || ev.key === Qt.Key_Up) {
                    vista.elegida = (vista.elegida + vista.clases.length - 1)
                        % vista.clases.length
                    ev.accepted = true
                } else if (ev.key === Qt.Key_Right || ev.key === Qt.Key_Down) {
                    vista.elegida = (vista.elegida + 1) % vista.clases.length
                    ev.accepted = true
                } else if (ev.key >= Qt.Key_1
                           && ev.key < Qt.Key_1 + vista.clases.length) {
                    vista.elegida = ev.key - Qt.Key_1
                    ev.accepted = true
                } else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter
                        || ev.key === Qt.Key_Space) {
                    vista.plugin.empezar(vista.clases[vista.elegida].id)
                    ev.accepted = true
                }
                return
            }

            if (vista.sim.pausada) {
                vista.sim.alternarPausa()
                ev.accepted = true
                return
            }

            //  `ev.text` llega ya COMPUESTO, que es lo que hace que las teclas
            //  muertas del teclado español funcionen: `´` y luego `a` entran
            //  aquí como una sola «á». Si esto fallara, las tildes se caerían
            //  del juego entero, así que es lo primero que se probó.
            const t = ev.text
            if (t.length === 1 && t.trim().length === 1) {
                vista.ultimaTecla = vista.sim.vocabulario.llana(t.toLowerCase())
                vista.sim.teclear(t)
                ev.accepted = true
            }
        }
    }

    Timer {
        interval: 140
        running: vista.ultimaTecla.length > 0
        onTriggered: vista.ultimaTecla = ""
    }

    // ── la grieta ─────────────────────────────────────────────────
    Fisura {
        width: parent.width
        height: vista.altoFisura
        y: vista.arriba ? 0 : parent.height - vista.altoFisura
        haciaAbajo: vista.arriba
        abierta: vista.sim.fisura
        //  En sobrecarga la grieta vira a ámbar: el mismo color que el tinte
        //  de la barra y que la onda, para que los tres digan lo mismo.
        tono: vista.sim.sobrecarga ? K4.Tema.amarillo : K4.Tema.rojo
    }

    //  El aviso de la sobrecarga, en el sitio donde ya se está mirando.
    K4.Etiqueta {
        anchors.horizontalCenter: parent.horizontalCenter
        y: vista.arriba ? vista.altoFisura + 6
                        : parent.height - vista.altoFisura - height - 6
        visible: vista.sim.sobrecarga
        text: K4.Idioma.t("SOBRECARGA")
        color: K4.Tema.amarillo
        font.pixelSize: 11
        font.weight: Font.Bold

        SequentialAnimation on opacity {
            running: vista.sim.sobrecarga
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 520; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 520; easing.type: Easing.InOutSine }
        }
    }

    // ── las palabras ──────────────────────────────────────────────
    Item {
        id: campo
        anchors.fill: parent

        Repeater {
            model: vista.sim.palabras

            delegate: Palabra {
                required property var model
                required property int index

                //  Para que las chispas y la pluma sepan cuál es cuál al
                //  recorrer los hijos del campo.
                property int pid: model.pid

                muestra: model.muestra
                escrito: model.escrito
                tipo: model.tipo

                duracionMs: vista.sim.caidaMs
                //  `lento` es el instante de cerrar capa: todo quieto mientras
                //  la onda cruza la pantalla. A esta escala, congelar medio
                //  segundo se lee como cámara lenta y cuesta una propiedad.
                detenida: vista.sim.pausada || vista.sim.lento
                    || vista.sim.enRuta || !vista.sim.jugando
                esObjetivo: vista.sim.objetivo === model.pid

                //  El carril lo reparte la simulación, que es quien sabe qué
                //  otras palabras hay: aquí solo se convierte a píxeles.
                x: 30 + model.carril * Math.max(1, campo.width - width - 60)
                y: vista.salida + (vista.final - vista.salida) * avance
                    - height / 2

                onEscapo: vista.sim.escapo(pid)
            }
        }
    }

    // ── las chispas de lo sellado ─────────────────────────────────
    Item {
        id: restos
        anchors.fill: parent
    }

    Component {
        id: molde
        Chispas {}
    }

    function _dondeEsta(pid) {
        for (let i = 0; i < campo.children.length; ++i) {
            const c = campo.children[i]
            if (c.pid !== undefined && c.pid === pid)
                return { x: c.x + c.width / 2, y: c.y + c.height / 2 }
        }
        return null
    }

    Connections {
        target: vista.sim

        function onSellada(pid) {
            //  Nacen donde estaba la palabra. Se busca el delegado en vez de
            //  guardar posiciones en la simulación, que no sabe de píxeles.
            const p = vista._dondeEsta(pid)
            const ch = molde.createObject(restos, {
                x: p ? p.x : campo.width / 2,
                y: p ? p.y : (vista.salida + vista.final) / 2,
                haciaArriba: vista.arriba,
                tono: K4.Tema.verde
            })
            if (ch)
                ch.terminado.connect(function () { ch.destroy() })
        }

        function onEscapada(pid) {
            //  Un golpe a la isla por cada fuga. La fisura ya lo cuenta, pero
            //  el golpe es lo que se siente.
            K4.Isla.efecto("grieta", "sacudida", 0.6)
        }

        function onMuerte() {
            K4.Isla.efecto("grieta", "empujon", 1)
        }
    }

    // ── el teclado dibujado ───────────────────────────────────────
    Teclado {
        width: parent.width
        height: vista.altoTeclado
        y: vista.arriba ? parent.height - vista.altoTeclado : 0
        circulo: vista.sim.circulo
        corruptas: vista.sim.corruptas
        ultima: vista.ultimaTecla
        aOscuras: vista.sim.guardian === "farolero"
    }

    // ── el marcador ───────────────────────────────────────────────
    //
    //  Va en la banda del teclado y no en el campo: ahí estorbaba a las
    //  palabras que acababan de brotar, y un marcador que tapa lo que tienes
    //  que leer es peor que no tenerlo.
    Row {
        spacing: 14
        x: 16
        y: vista.arriba
            ? parent.height - vista.altoTeclado / 2 - height / 2
            : vista.altoTeclado / 2 - height / 2

        K4.Etiqueta {
            text: K4.Idioma.t("capa ") + vista.sim.capa
            color: K4.Tema.apagado
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        K4.Etiqueta {
            text: vista.sim.selladas + K4.Idioma.t(" selladas")
            color: K4.Tema.tenue
            font.pixelSize: 11
        }

        K4.Etiqueta {
            visible: vista.sim.combo > 1
            text: "×" + vista.sim.combo
            color: vista.sim.combo >= 8 ? K4.Tema.amarillo : K4.Tema.verde
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        //  La tinta, y el aviso de para qué sirve solo cuando hace falta: con
        //  el teclado entero no hay nada que limpiar y decírtelo sería ruido.
        K4.Etiqueta {
            text: K4.Idioma.t("tinta ") + vista.sim.tinta
            color: vista.sim.tinta > 0 ? K4.Tema.azul : K4.Tema.tenue
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        K4.Etiqueta {
            visible: vista.sim.rotas > 0
            text: vista.sim.tinta > 0
                ? K4.Idioma.f("TAB limpia (%1 rotas)", vista.sim.rotas)
                : K4.Idioma.f("%1 rotas · sin tinta", vista.sim.rotas)
            color: vista.sim.tinta > 0 ? K4.Tema.apagado : K4.Tema.rojo
            font.pixelSize: 10
        }
    }

    //  El cursor de la casa, con su estela, sobre lo que estás escribiendo.
    K4.Estela {
        id: pluma
        visible: vista.sim.objetivo >= 0 && !vista.sim.pausada
        height: 22
        grosor: 2
        largo: 10
        color: K4.Tema.azul

        readonly property var sitio: vista.sim.objetivo >= 0
            ? vista._dondeEsta(vista.sim.objetivo) : null

        //  Se recoloca cuando se mueve el objetivo o cambia de objetivo. La
        //  estela se APUNTA sola al moverse: por eso no lleva Behavior.
        x: sitio ? sitio.x + 6 : 0
        y: sitio ? sitio.y - 11 : 0
    }

    // ── la ruta ───────────────────────────────────────────────────
    //
    //  Tapa la isla entera mientras se elige: es la única pausa del juego y
    //  tiene que verse como tal. El fondo casi opaco deja intuir las palabras
    //  detrás, congeladas, esperando.
    Rectangle {
        anchors.fill: parent
        visible: vista.sim.enRuta
        color: Qt.rgba(0, 0, 0, 0.9)

        Ruta {
            anchors.fill: parent
            opciones: vista.sim.pasoRuta === "salas"
                ? vista.sim.ofertaSalas : vista.sim.ofertaRunas
            elegida: vista.cursorRuta
            maldita: vista.sim.pasoRuta === "runas" ? vista.sim.maldita : -1
            titulo: vista.sim.pasoRuta === "salas"
                ? K4.Idioma.f("Capa %1 · ¿por dónde bajas?", vista.sim.capa)
                : K4.Idioma.t("¿Qué te llevas?")
            pie: K4.Idioma.t("← → para elegir · Enter para bajar")
        }
    }

    // ── los carteles ──────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing: 8
        visible: (!vista.sim.jugando || vista.sim.pausada) && !vista.sim.enRuta

        K4.Etiqueta {
            anchors.horizontalCenter: parent.horizontalCenter
            text: vista.sim.pausada ? K4.Idioma.t("En pausa")
                : vista.sim.fisura >= 1 ? K4.Idioma.t("La grieta se abrió")
                : K4.Idioma.t("La Grieta")
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }

        K4.Etiqueta {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: vista.sim.fisura >= 1
            text: K4.Idioma.f("%1 selladas · mejor racha ×%2",
                              vista.sim.selladas, vista.sim.mejorCombo)
            color: K4.Tema.apagado
            font.pixelSize: 12
        }

        K4.Etiqueta {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: vista.sim.selladas > 0
            text: vista.plugin.copiado
                ? K4.Idioma.t("copiado al portapapeles")
                : K4.Idioma.t("C para copiar el resultado")
            color: vista.plugin.copiado ? K4.Tema.verde : K4.Tema.tenue
            font.pixelSize: 10
        }

        //  Elegir con qué teclado peleas. Se enseña ANTES de cada partida y
        //  no en un menú aparte: es la decisión que define la run entera, así
        //  que tiene que estar donde se empieza.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !vista.sim.pausada
            spacing: 8

            Repeater {
                model: vista.clases

                delegate: Rectangle {
                    id: ficha
                    required property var modelData
                    required property int index

                    readonly property bool puesta: vista.elegida === index

                    width: 156
                    height: 92
                    radius: 10
                    color: puesta ? K4.Tema.superficieAlta : K4.Tema.superficie
                    border.width: puesta ? 1 : 0
                    border.color: K4.Tema.azul
                    opacity: puesta ? 1 : 0.6

                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        width: parent.width - 16

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: Qt.resolvedUrl("assets/" + ficha.modelData.emblema)
                            sourceSize.width: 30
                            sourceSize.height: 30
                            width: 30
                            height: 30
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
                    }
                }
            }
        }

        K4.Etiqueta {
            anchors.horizontalCenter: parent.horizontalCenter
            text: vista.sim.pausada
                ? K4.Idioma.t("cualquier tecla para seguir · ESC para salir")
                : K4.Idioma.t("← → o 1-4 para elegir · Enter para empezar")
            color: K4.Tema.tenue
            font.pixelSize: 11
        }
    }
}
