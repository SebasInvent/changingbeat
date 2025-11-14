const { SerialPort } = require('serialport')
const config = require('./configs/config')

const port = new SerialPort({
    path: config.puertocom,
    baudRate: 115200,
})

// Open errors will be emitted as an error event
port.on('error', function(err) {
    console.log('Error: ', err.message)
})

port.on('data', function (data) {
    // Decodificar datos MRZ al recibirlos
    let mrz_data = data.toString().trim();  // Asegúrate de que los datos estén limpios
    decodificaCedula(mrz_data);
})

port.on('open', function() {
    console.log("Puerto abierto")
})

function decodificaCedula(datos) {
    let cedula_data = datos;
    let no_cedula = '';
    let nombres = '';
    let chequeo = '';
    let offset = 0;
    let nombre1 = '';
    let nombre2 = '';
    let apellido1 = '';
    let apellido2 = '';

    // Detectar tipo de MRZ (TD1 o TD3)
    if (esMRZTipoTD1(cedula_data)) {
        console.log("MRZ de tipo TD1 detectado");
        // Procesar MRZ TD1
        procesarMRZ_TD1(cedula_data);
    } else if (esMRZTipoTD3(cedula_data)) {
        console.log("MRZ de tipo TD3 detectado");
        // Procesar MRZ TD3
        procesarMRZ_TD3(cedula_data);
    } else {
        console.log("MRZ no reconocido o inválido");
    }
}

// Función para verificar si el MRZ es de tipo TD1
function esMRZTipoTD1(datos) {
    let lines = datos.split('\n');
    return lines.length === 3 && lines.every(line => line.length === 30);
}

// Función para verificar si el MRZ es de tipo TD3
function esMRZTipoTD3(datos) {
    let lines = datos.split('\n');
    return lines.length === 2 && lines.every(line => line.length === 44);
}

// Función para procesar MRZ de tipo TD1
function procesarMRZ_TD1(cedula_data) {
    let no_cedula = '';
    let nombres = '';

    // Ejemplo de procesamiento de MRZ TD1
    for (let i = 0; i < 2; i++) {
        let chequeo = cedula_data[i];
    }

    for (let i = 48; i < 58; i++) {
        if (cedula_data[i] != '\x00' && cedula_data[i] != ' ') no_cedula = no_cedula.concat(cedula_data[i]);
    }

    for (let i = 104; i < 127; i++) {
        if (cedula_data[i] != '\x00' && cedula_data[i] != ' ') nombres = nombres.concat(cedula_data[i]);
    }

    nombres = nombres.concat(' ');

    for (let i = 58; i < 81; i++) {
        if (cedula_data[i] != '\x00' && cedula_data[i] != ' ') nombres = nombres.concat(cedula_data[i]);
    }

    console.log("Cédula:", no_cedula);
    console.log("Nombres:", nombres);
}

// Función para procesar MRZ de tipo TD3
function procesarMRZ_TD3(cedula_data) {
    let no_cedula = '';
    let nombres = '';

    // Ejemplo de procesamiento de MRZ TD3
    let lines = cedula_data.split('\n');
    no_cedula = lines[0].trim();  // Primer línea con el número de cédula

    nombres = lines[1].trim();    // Segunda línea con los nombres

    console.log("Cédula:", no_cedula);
    console.log("Nombres:", nombres);
}
