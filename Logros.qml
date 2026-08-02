//  Los logros: lo único que sobrevive a una partida.
//
//  Sin objetos que elegir, lo que engancha a volver tiene que ser otra cosa,
//  y es ésta: una lista corta de cosas difíciles y concretas. Cortas y
//  concretas a propósito — «juega 100 partidas» no es un logro, es una
//  factura. Todos éstos se consiguen jugando BIEN, no jugando mucho.
//
//  Se guardan con K4.Guardado, en el directorio del propio plugin.

import QtQuick

QtObject {
    id: logros

    readonly property var lista: [
        { id: "primera",  nombre: "Primera sangre",
          desc: "Sella tu primera palabra" },
        { id: "racha",    nombre: "Sin respirar",
          desc: "Encadena quince sin fallar" },
        { id: "cazador",  nombre: "Cazador",
          desc: "Caza cinco fugadas en una partida" },
        { id: "impecable", nombre: "Impecable",
          desc: "Pasa una capa entera sin un solo fallo" },
        { id: "verdugo",  nombre: "Verdugo",
          desc: "Derrota a un guardián" },
        { id: "hondo",    nombre: "Hondo",
          desc: "Llega a la capa 6" },
        { id: "mil",      nombre: "Mil",
          desc: "Mil puntos en una partida" },
        { id: "deprisa",  nombre: "Contrarreloj",
          desc: "Pasa una capa con veinte segundos de sobra" },
        { id: "nemesis",  nombre: "Ajuste de cuentas",
          desc: "Sella a tu némesis" }
    ]

    function porId(id) {
        for (let i = 0; i < lista.length; ++i)
            if (lista[i].id === id)
                return lista[i]
        return null
    }
}
