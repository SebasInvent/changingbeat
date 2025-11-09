/**
 * Script para simular accesos en tiempo real
 * Útil para probar el sistema WebSocket
 */

require('dotenv').config();
const axios = require('axios');

const API_BASE = 'http://localhost:3000/api/v1';

// Usuarios de prueba (deben existir en la BD)
const testUsers = [
  'juan.perez@example.com',
  'maria.gonzalez@example.com',
  'carlos.martinez@example.com',
  'ana.lopez@example.com'
];

// Terminales
const terminals = [
  '192.168.1.201',
  '192.168.1.202',
  '192.168.1.208'
];

// Tipos de registro
const recordTypes = ['entry', 'exit'];

/**
 * Generar temperatura aleatoria
 */
function randomTemperature() {
  // 80% normal, 20% elevada
  const isHigh = Math.random() > 0.8;
  if (isHigh) {
    return (37.6 + Math.random() * 1.5).toFixed(1); // 37.6 - 39.1
  }
  return (35.5 + Math.random() * 2).toFixed(1); // 35.5 - 37.5
}

/**
 * Simular un acceso
 */
async function simulateAccess() {
  try {
    const randomUser = testUsers[Math.floor(Math.random() * testUsers.length)];
    const randomTerminal = terminals[Math.floor(Math.random() * terminals.length)];
    const randomType = recordTypes[Math.floor(Math.random() * recordTypes.length)];
    const temperature = parseFloat(randomTemperature());

    // Obtener ID del usuario
    const usersResponse = await axios.get(`${API_BASE}/users/stats`);
    
    // Crear registro (esto disparará el WebSocket)
    const recordData = {
      userId: 'test-user-id', // En producción, usar ID real
      terminalIp: randomTerminal,
      recordType: randomType,
      temperature: temperature
    };

    console.log(`📤 Simulando acceso: ${randomType} en ${randomTerminal} - ${temperature}°C`);

    // Simular callback del terminal
    const callbackData = {
      personId: randomUser,
      ip: randomTerminal,
      temp: temperature,
      imgBase64: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
    };

    await axios.post(`${API_BASE}/terminals/identify-callback`, callbackData);

    console.log(`✅ Acceso simulado exitosamente`);

  } catch (error) {
    console.error(`❌ Error simulando acceso:`, error.message);
  }
}

/**
 * Iniciar simulación continua
 */
async function startSimulation(interval = 5000) {
  console.log('🎬 Iniciando simulación de accesos...');
  console.log(`⏱️  Intervalo: ${interval}ms (${interval/1000}s)`);
  console.log('📊 Abre el dashboard en: http://localhost:3000');
  console.log('🔴 Presiona Ctrl+C para detener\n');

  // Primer acceso inmediato
  await simulateAccess();

  // Continuar con intervalo
  setInterval(async () => {
    await simulateAccess();
  }, interval);
}

// Obtener intervalo de argumentos o usar 5 segundos por defecto
const interval = parseInt(process.argv[2]) || 5000;

// Iniciar
startSimulation(interval);
