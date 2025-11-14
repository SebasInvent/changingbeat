/**
 * Test de Conectividad con Terminales Biométricos
 * Verifica el estado real de cada terminal
 */

const axios = require('axios');

const TERMINALS = [
  { ip: '192.168.1.201', name: 'Terminal 1' },
  { ip: '192.168.1.202', name: 'Terminal 2' },
  { ip: '192.168.1.208', name: 'Terminal 3' }
];

const TIMEOUT = 5000; // 5 segundos

console.log('═══════════════════════════════════════════════════════');
console.log('🔍 TEST DE TERMINALES BIOMÉTRICOS');
console.log('═══════════════════════════════════════════════════════\n');

/**
 * Probar conexión básica (ping HTTP)
 */
async function testBasicConnection(terminal) {
  const endpoints = [
    { path: '/', method: 'GET', name: 'Root' },
    { path: '/api/v2/device/status', method: 'GET', name: 'Status API' },
    { path: '/api/v1/device/status', method: 'GET', name: 'Status API v1' },
    { path: '/cgi-bin/AccessControl.cgi', method: 'GET', name: 'CGI Access Control' }
  ];

  console.log(`\n📡 ${terminal.name} (${terminal.ip})`);
  console.log('─────────────────────────────────────────');

  let connected = false;
  let workingEndpoint = null;

  for (const endpoint of endpoints) {
    try {
      const url = `http://${terminal.ip}:8090${endpoint.path}`;
      console.log(`   Probando: ${endpoint.name}...`);
      
      const response = await axios({
        method: endpoint.method,
        url: url,
        timeout: TIMEOUT,
        validateStatus: () => true // Aceptar cualquier código de estado
      });

      console.log(`   ✅ Respuesta: ${response.status} ${response.statusText}`);
      
      if (response.data) {
        console.log(`   📦 Datos recibidos: ${JSON.stringify(response.data).substring(0, 100)}...`);
      }

      connected = true;
      workingEndpoint = { ...endpoint, url };
      break;

    } catch (error) {
      if (error.code === 'ECONNREFUSED') {
        console.log(`   ❌ Conexión rechazada`);
      } else if (error.code === 'ETIMEDOUT') {
        console.log(`   ⏱️  Timeout`);
      } else if (error.code === 'ECONNRESET') {
        console.log(`   ⚠️  Conexión reseteada`);
      } else {
        console.log(`   ⚠️  Error: ${error.message}`);
      }
    }
  }

  if (!connected) {
    console.log(`\n   ❌ ${terminal.name} NO RESPONDE en ningún endpoint`);
    console.log(`   💡 Verifica:`);
    console.log(`      - ¿El terminal está encendido?`);
    console.log(`      - ¿La IP ${terminal.ip} es correcta?`);
    console.log(`      - ¿Hay firewall bloqueando?`);
  } else {
    console.log(`\n   ✅ ${terminal.name} ESTÁ ONLINE`);
    console.log(`   🔗 Endpoint funcional: ${workingEndpoint.url}`);
  }

  return { terminal, connected, workingEndpoint };
}

/**
 * Probar con diferentes puertos
 */
async function testDifferentPorts(terminal) {
  const ports = [8090, 80, 8080, 8000, 4370];
  
  console.log(`\n🔍 Escaneando puertos en ${terminal.ip}...`);
  
  for (const port of ports) {
    try {
      const url = `http://${terminal.ip}:${port}`;
      const response = await axios.get(url, { 
        timeout: 2000,
        validateStatus: () => true 
      });
      
      console.log(`   ✅ Puerto ${port}: ABIERTO (${response.status})`);
      return port;
      
    } catch (error) {
      console.log(`   ❌ Puerto ${port}: Cerrado`);
    }
  }
  
  return null;
}

/**
 * Ejecutar tests
 */
async function runTests() {
  const results = [];

  for (const terminal of TERMINALS) {
    const result = await testBasicConnection(terminal);
    results.push(result);

    if (!result.connected) {
      // Intentar con otros puertos
      const openPort = await testDifferentPorts(terminal);
      if (openPort) {
        console.log(`   💡 Prueba usar el puerto ${openPort} en lugar de 8090`);
      }
    }
  }

  // Resumen
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('📊 RESUMEN');
  console.log('═══════════════════════════════════════════════════════\n');

  const online = results.filter(r => r.connected);
  const offline = results.filter(r => !r.connected);

  console.log(`✅ Terminales ONLINE: ${online.length}/${TERMINALS.length}`);
  online.forEach(r => {
    console.log(`   • ${r.terminal.name} (${r.terminal.ip})`);
    if (r.workingEndpoint) {
      console.log(`     Endpoint: ${r.workingEndpoint.url}`);
    }
  });

  if (offline.length > 0) {
    console.log(`\n❌ Terminales OFFLINE: ${offline.length}/${TERMINALS.length}`);
    offline.forEach(r => {
      console.log(`   • ${r.terminal.name} (${r.terminal.ip})`);
    });
  }

  // Recomendaciones
  console.log('\n💡 PRÓXIMOS PASOS:');
  
  if (online.length > 0) {
    console.log('\n✅ Terminales detectadas! Puedes:');
    console.log('   1. Configurar callback URL en cada terminal');
    console.log('   2. Sincronizar usuarios (Eduardo Cuervo)');
    console.log('   3. Probar reconocimiento facial');
    console.log('\n   Callback URL a configurar:');
    console.log(`   http://192.168.1.39:3000/api/v1/terminals/identify-callback`);
  }

  if (offline.length > 0) {
    console.log('\n⚠️  Para terminales offline:');
    console.log('   1. Verifica que estén encendidas');
    console.log('   2. Confirma las IPs correctas');
    console.log('   3. Revisa configuración de red');
  }

  console.log('\n═══════════════════════════════════════════════════════\n');
}

// Ejecutar
runTests().catch(console.error);
