//  Los guardianes: los que cambian las reglas del teclado.
//
//  Un jefe que solo tuviera más vida sería la misma capa pero más larga. Lo
//  que hacen estos es tocar el CONTRATO —qué sale, cómo se lee, qué tecla
//  produce qué— así que mientras están delante juegas a otra cosa con el
//  mismo teclado. Y se van en cuanto les sellas lo suyo: son un tramo, no un
//  muro.
//
//  Asoman por encima de la isla, más grandes que la barra, así que sus
//  sprites se generaron a 128 y no a 48. Es el fotograma que vende el juego.

import QtQuick

QtObject {
    id: guardianes

    //  `vida` son las palabras que hay que sellarle.
    readonly property var lista: [
        { id: "bestia", nombre: "La Bestia de Letras",
          regla: "Solo salen palabras largas",
          vida: 5, emblema: "guardianes/s00.png" },
        { id: "doscaras", nombre: "El de Dos Caras",
          regla: "Te ha cambiado dos teclas de sitio",
          vida: 4, emblema: "guardianes/s01.png" },
        { id: "farolero", nombre: "El Farolero",
          regla: "Ha apagado tu teclado: escribes a ciegas",
          vida: 4, emblema: "guardianes/s02.png" },
        { id: "dosbocas", nombre: "La Máscara de Dos Bocas",
          regla: "Sale el doble por la grieta",
          vida: 5, emblema: "guardianes/s03.png" },
        { id: "ciego", nombre: "El Escriba Ciego",
          regla: "Todo se lee del revés",
          vida: 4, emblema: "guardianes/s04.png" },
        { id: "ojo", nombre: "El Ojo de la Grieta",
          regla: "Todo cae mucho más deprisa",
          vida: 5, emblema: "guardianes/s05.png" }
    ]

    function porId(id) {
        for (let i = 0; i < lista.length; ++i)
            if (lista[i].id === id)
                return lista[i]
        return null
    }

    function alAzar(yaVistos) {
        const bolsa = []
        for (let i = 0; i < lista.length; ++i)
            if (yaVistos.indexOf(lista[i].id) < 0)
                bolsa.push(lista[i])
        //  Si ya los has visto todos, vuelve a empezar: mejor repetido que
        //  ninguno, porque una capa de guardián sin guardián es un anticlímax.
        const fuente = bolsa.length ? bolsa : lista
        return fuente[Math.floor(Math.random() * fuente.length)]
    }
}
