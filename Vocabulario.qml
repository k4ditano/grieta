//  Las palabras que salen por la grieta.
//
//  En castellano y comunes: lo que se teclea tiene que reconocerse de un
//  vistazo, porque el juego mide con qué velocidad las escribes, no cuánto
//  tardas en descifrarlas. Nada de tecnicismos ni de nombres propios.
//
//  Van por longitud porque la longitud es la dificultad: las capas de arriba
//  tiran de las cortas y las de abajo de las largas. `deCirculo` filtra por
//  las teclas que el jugador tiene despiertas — una palabra que no puedes
//  escribir no es un reto, es una trampa.

import QtQuick

QtObject {
    id: vocabulario

    //  Hay más de las que parecen necesarias a propósito: un círculo que
    //  recorta letras se queda sin material enseguida, y una clase con cuatro
    //  palabras no es una clase, es un error. Medido: con la lista corta, «El
    //  Vocalista» solo alcanzaba 21 palabras de 40.
    readonly property var cortas: [
        "casa", "mesa", "luna", "sopa", "pino", "nube", "tren", "gato",
        "mano", "pelo", "rama", "sal", "mar", "pan", "sol", "río",
        "dedo", "seta", "ala", "cama", "rana", "loro", "duna", "cola",
        "nido", "muro", "polo", "tela", "cera", "lima", "pato", "coro",
        "mora", "ruta", "tapa", "nota", "silla", "punta", "carta", "manta",
        "sala", "mula", "tina", "lata", "nata", "rata", "cana", "raso",
        "mote", "sota", "tono", "malo", "sano", "lento", "salto", "canto",
        "manto", "santo", "tanto", "suelo", "cielo", "molino", "camino",
        "marino", "cortina", "colina", "cadena", "cintura", "sirena",
        "arena", "aroma", "isla", "olmo", "lodo", "nudo", "mudo", "codo",
        "todo", "modo", "solo", "muela", "estela", "aldea", "mantel",
        "coral", "cauce", "trono", "surco", "traste", "ronda", "tarde"
    ]

    readonly property var medias: [
        "montaña", "cuaderno", "ventana", "camino", "sombra", "campana",
        "espada", "moneda", "cadena", "puerta", "estrella", "caverna",
        "linterna", "pantano", "ceniza", "raíces", "columna", "temblor",
        "murmullo", "cristal", "trueno", "abismo", "reliquia", "cántaro",
        "sendero", "penumbra", "carbón", "muralla", "corriente", "escama"
    ]

    readonly property var largas: [
        "murciélago", "relámpago", "laberinto", "crepúsculo", "terremoto",
        "constelación", "resplandor", "escalofrío", "manuscrito",
        "campanario", "arquitecto", "susurrante", "profundidad",
        "candelabro", "pergamino", "obsidiana", "catacumba", "mecanismo"
    ]

    //  Las que se pueden escribir con las teclas de un círculo. Se comparan
    //  sin tildes: la tilde es un desbloqueo tardío, y hasta que llegue una
    //  palabra acentuada se acepta con la vocal a secas.
    function deCirculo(lista, circulo) {
        const salida = []
        for (let i = 0; i < lista.length; ++i) {
            const p = lista[i]
            let vale = true
            for (let j = 0; j < p.length; ++j) {
                if (circulo.indexOf(llana(p[j])) < 0) {
                    vale = false
                    break
                }
            }
            if (vale)
                salida.push(p)
        }
        return salida
    }

    //  Una letra sin su tilde. Sirve para filtrar y para comparar lo tecleado.
    function llana(letra) {
        const i = "áéíóúü".indexOf(letra)
        return i < 0 ? letra : "aeiouu"[i]
    }
}
