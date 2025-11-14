/**
 * Script para simular detecciones de Eduardo Cuervo
 * Simula lo que haría el terminal biométrico
 */

const axios = require('axios');

const API_BASE = 'http://localhost:3000/api/v1';
const EDUARDO_ID = 'dd87444b-4cfc-4adb-8222-53ee7e26c956';

// Temperaturas aleatorias normales
function randomTemp() {
  return (35.8 + Math.random() * 1.5).toFixed(1); // 35.8 - 37.3
}

// Simular detección de Eduardo
async function detectEduardo() {
  try {
    const temp = parseFloat(randomTemp());
    
    const data = {
      personId: EDUARDO_ID,
      ip: '192.168.1.201',
      temp: temp,
      imgBase64: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
    };

    console.log(`📸 Detectando Eduardo Cuervo... Temp: ${temp}°C`);

    const response = await axios.post(
      `${API_BASE}/terminals/identify-callback`,
      data
    );

    console.log(`✅ Registro creado exitosamente`);
    console.log(`   Respuesta:`, response.data.message);

  } catch (error) {
    console.error(`❌ Error:`, error.response?.data || error.message);
  }
}

// Modo continuo
async function continuousDetection(intervalMs = 3000) {
  console.log('🎥 Simulando cámara detectando a Eduardo Cuervo...');
  console.log(`⏱️  Intervalo: cada ${intervalMs/1000} segundos`);
  console.log('📊 Abre el dashboard: http://localhost:3000');
  console.log('🔴 Presiona Ctrl+C para detener\n');

  // Primera detección inmediata
  await detectEduardo();

  // Continuar con intervalo
  setInterval(async () => {
    await detectEduardo();
  }, intervalMs);
}

// Modo único
async function singleDetection() {
  console.log('🎥 Simulando una detección de Eduardo Cuervo...\n');
  await detectEduardo();
  console.log('\n✅ Listo! Revisa el dashboard: http://localhost:3000');
  process.exit(0);
}

// Determinar modo
const mode = process.argv[2];
const interval = parseInt(process.argv[3]) || 3000;

if (mode === 'once') {
  singleDetection();
} else {
  continuousDetection(interval);
}
