//  Los guardianes: los que cambian las reglas del teclado.
//
//  Un jefe que solo tuviera más vida sería la misma capa pero más larga. Lo
//  que hacen estos es tocar QUÉ SALE y CÓMO SE LEE, así que mientras están
//  delante juegas a otra cosa con los mismos dedos. Y se van en cuanto les
//  sellas lo suyo: son un tramo, no un muro.
//
//  Ninguno toca tu teclado, y es a propósito. El de Dos Caras te cambiaba dos
//  teclas de sitio y el Farolero te apagaba el teclado dibujado: lo primero
//  era la misma familia que la corrupción de teclas —pelearse con los dedos
//  de quien está tecleando— y lo segundo dejó de significar nada cuando el
//  teclado dibujado dejó de contar teclas rotas. Se atacan la lectura y la
//  vista, que es donde un juego de tecleo puede apretar sin quitarte el mando.
//
//  Asoman por encima de la isla, más grandes que la barra, así que sus
//  sprites se generaron a 128 y no a 48. Es el fotograma que vende el juego.

import QtQuick

QtObject {
    id: guardianes

    //  El sorteo lo presta la simulación: con uno propio, la grieta del día
    //  dejaría de ser la misma para todos. El respaldo solo existe para que
    //  esto cargue suelto en una prueba.
    property var azar: function () { return Math.random() }

    //  `vida` son las palabras que hay que sellarle.
    readonly property var lista: [
        { id: "bestia", nombre: "La Bestia de Letras",
          regla: "Solo salen palabras largas",
          vida: 5, emblema: "guardianes/s00.png" },
        { id: "doscaras", nombre: "El de Dos Caras",
          regla: "Las palabras no se están quietas: van y vienen",
          vida: 4, emblema: "guardianes/s01.png" },
        { id: "farolero", nombre: "El Farolero",
          regla: "Ha apagado media grieta: se leen a oscuras",
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
        return fuente[Math.floor(azar() * fuente.length)]
    }
}
