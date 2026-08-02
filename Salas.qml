//  Las salas: por dónde bajas a la capa siguiente.
//
//  Es la decisión que hace que una partida sea una RUTA y no una cuesta. Se
//  ofrecen dos y se elige una, así que nunca puedes tenerlo todo: coger la
//  fragua para arreglarte el teclado es renunciar a la runa, y eso —renunciar
//  a algo bueno por algo que necesitas más— es de lo que va el género.
//
//  Se enseñan con los emblemas que ya se generaron para ellas.

import QtQuick

QtObject {
    id: salas

    //  El sorteo lo presta la simulación: con uno propio, la grieta del día
    //  dejaría de ser la misma para todos. El respaldo solo existe para que
    //  esto cargue suelto en una prueba.
    property var azar: function () { return Math.random() }

    readonly property var lista: [
        { id: "fragua", nombre: "La Fragua",
          desc: "Barre de un golpe todo lo que está cayendo",
          emblema: "circulos/s04.png" },
        { id: "mercado", nombre: "El Mercado",
          desc: "Elige una runa de tres",
          emblema: "circulos/s05.png" },
        { id: "nido", nombre: "El Nido",
          desc: "La capa cae más deprisa; al cerrarla, runa y tinta",
          emblema: "circulos/s06.png" },
        { id: "eco", nombre: "La Sala del Eco",
          desc: "Todo vale doble durante la capa, y sale más a menudo",
          emblema: "circulos/s07.png" }
    ]

    function porId(id) {
        for (let i = 0; i < lista.length; ++i)
            if (lista[i].id === id)
                return lista[i]
        return null
    }

    //  Dos distintas al azar. Con las cuatro siempre delante no habría
    //  decisión, solo un orden de preferencia que se repite cada partida.
    function ofrecer() {
        const bolsa = lista.slice()
        const salida = []
        while (salida.length < 2 && bolsa.length > 0) {
            const j = Math.floor(azar() * bolsa.length)
            salida.push(bolsa[j])
            bolsa.splice(j, 1)
        }
        return salida
    }
}
