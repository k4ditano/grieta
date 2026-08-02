//  Los círculos: las clases con las que se empieza una partida.
//
//  La idea es que tu personaje ES tu teclado. Lo que cambia entre una partida
//  y otra no es una estadística: son las teclas que tienes y cómo se
//  comportan, así que dos runs se juegan distinto con los dedos, no en una
//  hoja de personaje.
//
//  Una lección medida y no supuesta: en castellano un círculo NO puede ser
//  media fila del teclado. Probé «la zurda» —la mitad izquierda, que en un
//  teclado español no tiene ni o, ni i, ni u— y dejaba 4 palabras de 40. Sin
//  `a e o s r n l t` no hay idioma. Así que las clases se distinguen por lo
//  que le hacen a la partida y solo una recorta letras de verdad.

import QtQuick

QtObject {
    id: circulos

    readonly property string completo: "abcdefghijklmnopqrstuvwxyzñ"

    //  `letras`      qué teclas tienes despiertas.
    //  `dano`        cuánto abre la fisura cada fuga (0.2 = cinco fugas).
    //  `ritmo`       multiplica la espera entre brotes; menos es más rápido.
    //  `tartamudo`   cada letra se teclea dos veces.
    //  `rotasAlNacer` teclas que empiezan ya corrompidas.
    //  `tinta`       con cuánta empiezas.
    readonly property var lista: [
        {
            id: "vocalista",
            nombre: "El Vocalista",
            desc: "Pocas letras y palabras cortas, pero salen sin descanso",
            letras: "aeiouslnrmtcd",
            dano: 0.2, ritmo: 0.72, tartamudo: false, rotasAlNacer: 0, tinta: 2,
            emblema: "circulos/s00.png"
        },
        {
            id: "escriba",
            nombre: "El Escriba",
            desc: "El alfabeto entero desde el principio, y la mitad de margen",
            letras: circulos.completo,
            dano: 0.4, ritmo: 1.0, tartamudo: false, rotasAlNacer: 0, tinta: 2,
            emblema: "circulos/s02.png"
        },
        {
            id: "tartamudo",
            nombre: "El Tartamudo",
            desc: "Cada letra, dos veces. El doble de pulsaciones por palabra",
            letras: "aeioustrnlmdcpbg",
            dano: 0.2, ritmo: 1.25, tartamudo: true, rotasAlNacer: 0, tinta: 2,
            emblema: "circulos/s03.png"
        },
        {
            id: "ceniza",
            nombre: "La Ceniza",
            desc: "Empiezas con tres teclas ya rotas, y con tinta de sobra",
            letras: "aeioustrnlmdcpbg",
            dano: 0.2, ritmo: 1.0, tartamudo: false, rotasAlNacer: 3, tinta: 5,
            //  Presta el montón de ceniza de la hoja de runas: es exactamente
            //  lo que la clase cuenta, y generar otro sprite igual sobraba.
            emblema: "runas/s02.png"
        }
    ]

    function porId(id) {
        for (let i = 0; i < lista.length; ++i)
            if (lista[i].id === id)
                return lista[i]
        return lista[0]
    }
}
