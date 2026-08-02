//  Las runas: lo que te llevas de una partida y cambia cómo se juega.
//
//  Ninguna es un porcentaje escondido. Cada una hace algo que se NOTA en los
//  dedos —la palabra ya viene empezada, las teclas rotas vuelven a escribir,
//  lo que cae va más despacio— porque en un juego de tecleo un +7% de algo no
//  se siente, y lo que no se siente no se elige.
//
//  Los efectos son datos y no código: la simulación pregunta `tiene(id)` y
//  aplica. Añadir una runa es una entrada aquí y una línea allí, que es lo
//  que hace que la lista pueda crecer sin que nada se enrede.

import QtQuick

QtObject {
    id: runas

    //  El sorteo lo presta la simulación: con uno propio, la grieta del día
    //  dejaría de ser la misma para todos. El respaldo solo existe para que
    //  esto cargue suelto en una prueba.
    property var azar: function () { return Math.random() }

    readonly property var lista: [
        { id: "cadena", nombre: "Cadena",
          desc: "Encadenar por la última letra da racha de más",
          emblema: "runas/s00.png" },
        { id: "sanguijuela", nombre: "Sanguijuela",
          desc: "Las palabras largas cierran grieta",
          emblema: "runas/s01.png" },
        { id: "ceniza", nombre: "Ceniza",
          desc: "Tus fallos ya no manchan la palabra",
          emblema: "runas/s02.png" },
        { id: "tintero", nombre: "Tintero",
          desc: "Tinta cada dos selladas en vez de cada tres",
          emblema: "runas/s03.png" },
        { id: "aliento", nombre: "Aliento",
          desc: "Todo cae más despacio",
          emblema: "runas/s04.png" },
        { id: "filo", nombre: "Filo",
          desc: "Cada palabra sale con su primera letra ya escrita",
          emblema: "runas/s05.png" },
        { id: "eco", nombre: "Eco",
          desc: "Cerrar una capa da dos de tinta",
          emblema: "runas/s06.png" },
        { id: "ancla", nombre: "Ancla",
          desc: "La primera fuga de cada capa no abre la grieta",
          emblema: "runas/s07.png" },
        { id: "faro", nombre: "Faro",
          desc: "Sale menos por la grieta",
          emblema: "runas/s08.png" },
        { id: "mordaza", nombre: "Mordaza",
          desc: "Se acabaron los espejos",
          emblema: "runas/s09.png" },
        { id: "semilla", nombre: "Semilla",
          desc: "Cada capa empieza con una tinta de regalo",
          emblema: "runas/s10.png" },
        { id: "yunque", nombre: "Yunque",
          desc: "Cada fuga abre bastante menos grieta",
          emblema: "runas/s11.png" }
    ]

    function porId(id) {
        for (let i = 0; i < lista.length; ++i)
            if (lista[i].id === id)
                return lista[i]
        return null
    }

    //  Tres al azar de las que todavía no tengas. Si ya las tienes casi
    //  todas devuelve las que queden: quedarse sin oferta es mejor que
    //  ofrecer repetida, que se siente como una recompensa robada.
    function ofrecer(tenidas, cuantas) {
        const bolsa = []
        for (let i = 0; i < lista.length; ++i)
            if (tenidas.indexOf(lista[i].id) < 0)
                bolsa.push(lista[i])

        const salida = []
        while (salida.length < cuantas && bolsa.length > 0) {
            const j = Math.floor(azar() * bolsa.length)
            salida.push(bolsa[j])
            bolsa.splice(j, 1)
        }
        return salida
    }
}
