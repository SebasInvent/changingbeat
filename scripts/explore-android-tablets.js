/**
 * Explorador de Tabletas Android
 * Busca y analiza tabletas con APKs de reconocimiento facial
 */

const axios = require('axios');
const { execSync } = require('child_process');

const TABLET_IPS = [
  '192.168.1.201',
  '192.168.1.202',
  '192.168.1.208'
];

const COMMON_PORTS = [80, 8080, 8000, 8081, 4370, 3000, 5000, 9000];

const COMMON_ENDPOINTS = [
  '/',
  '/api',
  '/api/status',
  '/api/events',
  '/api/events/recent',
  '/api/v1/events',
  '/api/v2/events',
  '/status',
  '/health',
  '/config',
  '/settings'
];

console.log('═══════════════════════════════════════════════════════');
console.log('📱 EXPLORADOR DE TABLETAS ANDROID');
console.log('═══════════════════════════════════════════════════════\n');

/**
 * Probar conectividad básica
 */
async function testPing(ip) {
  try {
    const result = execSync(`ping -n 1 -w 1000 ${ip}`, { encoding: 'utf8' });
    return result.includes('TTL=');
  } catch (error) {
    return false;
  }
}

/**
 * Escanear puerto
 */
async function testPort(ip, port) {
  try {
    const url = `http://${ip}:${port}`;
    const response = await axios.get(url, {
      timeout: 2000,
      validateStatus: () => true
    });
    return {
      open: true,
      status: response.status,
      data: response.data
    };
  } catch (error) {
    if (error.code === 'ECONNREFUSED') {
      return { open: false, reason: 'Puerto cerrado' };
    } else if (error.code === 'ETIMEDOUT') {
      return { open: false, reason: 'Timeout' };
    } else {
      return { open: false, reason: error.code };
    }
  }
}

/**
 * Probar endpoints comunes
 */
async function testEndpoints(ip, port) {
  const results = [];
  
  for (const endpoint of COMMON_ENDPOINTS) {
    try {
      const url = `http://${ip}:${port}${endpoint}`;
      const response = await axios.get(url, {
        timeout: 2000,
        validateStatus: () => true
      });
      
      if (response.status < 500) {
        results.push({
          endpoint,
          status: response.status,
          contentType: response.headers['content-type'],
          dataPreview: JSON.stringify(response.data).substring(0, 100)
        });
      }
    } catch (error) {
      // Ignorar errores
    }
  }
  
  return results;
}

/**
 * Analizar tableta
 */
async function analyzeTablet(ip) {
  console.log(`\n📱 ANALIZANDO TABLETA: ${ip}`);
  console.log('─────────────────────────────────────────────────────');
  
  // 1. Ping
  console.log('   🔍 Probando conectividad...');
  const pingResult = await testPing(ip);
  
  if (!pingResult) {
    console.log('   ❌ No responde a ping');
    console.log('   💡 La tableta puede estar:');
    console.log('      - Apagada');
    console.log('      - En otra IP');
    console.log('      - Bloqueando ping (pero funcionando)');
    return { ip, online: false };
  }
  
  console.log('   ✅ Responde a ping');
  
  // 2. Escanear puertos
  console.log('\n   🔍 Escaneando puertos...');
  const openPorts = [];
  
  for (const port of COMMON_PORTS) {
    const result = await testPort(ip, port);
    if (result.open) {
      console.log(`   ✅ Puerto ${port}: ABIERTO (HTTP ${result.status})`);
      openPorts.push({ port, ...result });
    }
  }
  
  if (openPorts.length === 0) {
    console.log('   ⚠️  No se encontraron puertos HTTP abiertos');
    console.log('   💡 La tableta puede:');
    console.log('      - No tener servidor HTTP');
    console.log('      - Usar otros puertos');
    console.log('      - Solo guardar en base de datos central');
    return { ip, online: true, ports: [] };
  }
  
  // 3. Explorar endpoints
  console.log('\n   🔍 Explorando endpoints...');
  const allEndpoints = [];
  
  for (const portInfo of openPorts) {
    console.log(`\n   📡 Puerto ${portInfo.port}:`);
    const endpoints = await testEndpoints(ip, portInfo.port);
    
    if (endpoints.length > 0) {
      endpoints.forEach(ep => {
        console.log(`      ✅ ${ep.endpoint}`);
        console.log(`         Status: ${ep.status}`);
        console.log(`         Type: ${ep.contentType}`);
        if (ep.dataPreview) {
          console.log(`         Data: ${ep.dataPreview}...`);
        }
      });
      allEndpoints.push(...endpoints);
    } else {
      console.log('      ℹ️  No se encontraron endpoints conocidos');
    }
  }
  
  return {
    ip,
    online: true,
    ports: openPorts,
    endpoints: allEndpoints
  };
}

/**
 * Generar recomendaciones
 */
function generateRecommendations(results) {
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('📊 RESUMEN Y RECOMENDACIONES');
  console.log('═══════════════════════════════════════════════════════\n');
  
  const onlineTablets = results.filter(r => r.online);
  const tabletsWithAPI = results.filter(r => r.endpoints && r.endpoints.length > 0);
  
  console.log(`📱 Tabletas encontradas: ${onlineTablets.length}/${TABLET_IPS.length}`);
  console.log(`🌐 Tabletas con API: ${tabletsWithAPI.length}\n`);
  
  if (tabletsWithAPI.length > 0) {
    console.log('✅ SOLUCIÓN RECOMENDADA: API REST');
    console.log('─────────────────────────────────────────────────────');
    console.log('Las tabletas exponen APIs. Puedes:');
    console.log('1. Hacer polling periódico a sus endpoints');
    console.log('2. Obtener eventos recientes');
    console.log('3. Enviar al dashboard\n');
    
    console.log('📋 Endpoints encontrados:');
    tabletsWithAPI.forEach(tablet => {
      console.log(`\n   ${tablet.ip}:`);
      tablet.endpoints.forEach(ep => {
        const port = tablet.ports[0].port;
        console.log(`   - http://${tablet.ip}:${port}${ep.endpoint}`);
      });
    });
    
  } else if (onlineTablets.length > 0) {
    console.log('⚠️  TABLETAS SIN API DETECTADA');
    console.log('─────────────────────────────────────────────────────');
    console.log('Las tabletas responden pero no exponen API HTTP.\n');
    console.log('💡 OPCIONES:');
    console.log('1. Configurar webhook en las APKs');
    console.log('   - Abrir configuración de la APK');
    console.log('   - Buscar "Webhook URL" o "Callback URL"');
    console.log(`   - Configurar: http://192.168.1.39:3000/api/v1/terminals/identify-callback\n`);
    
    console.log('2. Conectar a base de datos central');
    console.log('   - Si las tabletas guardan en SQL Server');
    console.log('   - Monitorear esa base de datos\n');
    
    console.log('3. Revisar configuración de la APK');
    console.log('   - Puede tener opciones de servidor/API');
    console.log('   - Puede exportar logs/archivos\n');
    
  } else {
    console.log('❌ NO SE ENCONTRARON TABLETAS');
    console.log('─────────────────────────────────────────────────────');
    console.log('Ninguna tableta responde en las IPs configuradas.\n');
    console.log('💡 VERIFICA:');
    console.log('1. ¿Las tabletas están encendidas?');
    console.log('2. ¿Las IPs son correctas?');
    console.log('3. ¿Están en la misma red que tu servidor?\n');
    
    console.log('🔍 Para encontrar las IPs correctas:');
    console.log('   - Revisa la configuración de red en cada tableta');
    console.log('   - Busca en Ajustes → Wi-Fi → Información');
    console.log('   - O escanea toda la red con: npm run scan:network\n');
  }
  
  console.log('\n💡 PRÓXIMOS PASOS:');
  console.log('─────────────────────────────────────────────────────');
  
  if (tabletsWithAPI.length > 0) {
    console.log('1. Implementar polling a las APIs encontradas');
    console.log('2. Parsear respuestas y enviar al dashboard');
    console.log('3. Configurar intervalo de consulta (cada 3-5 seg)');
  } else {
    console.log('1. Revisar configuración de las APKs en las tabletas');
    console.log('2. Buscar opciones de webhook/callback');
    console.log('3. Identificar dónde guardan los datos');
    console.log('4. Compartir capturas de pantalla de la configuración');
  }
  
  console.log('\n═══════════════════════════════════════════════════════\n');
}

/**
 * Ejecutar análisis
 */
async function main() {
  const results = [];
  
  for (const ip of TABLET_IPS) {
    const result = await analyzeTablet(ip);
    results.push(result);
  }
  
  generateRecommendations(results);
}

main().catch(console.error);
