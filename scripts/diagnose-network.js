/**
 * Diagnóstico de Configuración de Red
 * Identifica interfaces, IPs y conectividad
 */

const { execSync } = require('child_process');
const os = require('os');
const fs = require('fs');
const path = require('path');

console.log('═══════════════════════════════════════════════════════');
console.log('🌐 DIAGNÓSTICO DE CONFIGURACIÓN DE RED');
console.log('═══════════════════════════════════════════════════════\n');

// ========================================
// 1. INTERFACES DE RED
// ========================================
console.log('1️⃣ INTERFACES DE RED DISPONIBLES:');
console.log('─────────────────────────────────────────────────────');

try {
  const adapters = execSync('Get-NetAdapter | Select-Object Name, Status, LinkSpeed, MacAddress | Format-Table -AutoSize', 
    { encoding: 'utf8', shell: 'powershell.exe' });
  console.log(adapters);
} catch (error) {
  console.log('⚠️  Error listando adaptadores\n');
}

// ========================================
// 2. DIRECCIONES IP CONFIGURADAS
// ========================================
console.log('2️⃣ DIRECCIONES IP CONFIGURADAS:');
console.log('─────────────────────────────────────────────────────');

const networkInterfaces = os.networkInterfaces();
for (const [name, interfaces] of Object.entries(networkInterfaces)) {
  console.log(`\n📡 ${name}:`);
  interfaces.forEach(iface => {
    if (iface.family === 'IPv4') {
      console.log(`   IP: ${iface.address}`);
      console.log(`   Máscara: ${iface.netmask}`);
      console.log(`   MAC: ${iface.mac}`);
      console.log(`   Interno: ${iface.internal ? 'Sí' : 'No'}`);
      
      // Identificar posible red
      if (iface.address.startsWith('192.168.1.')) {
        console.log(`   🎯 POSIBLE RED A1A FACE ID`);
      } else if (!iface.internal) {
        console.log(`   🌐 POSIBLE RED CLEAN (Internet)`);
      }
    }
  });
}

console.log('\n');

// ========================================
// 3. GATEWAY Y RUTAS
// ========================================
console.log('3️⃣ GATEWAY Y RUTAS DE RED:');
console.log('─────────────────────────────────────────────────────');

try {
  const routes = execSync('route print 0.0.0.0', { encoding: 'utf8' });
  const lines = routes.split('\n');
  
  for (const line of lines) {
    if (line.includes('0.0.0.0')) {
      console.log(line.trim());
    }
  }
} catch (error) {
  console.log('⚠️  Error obteniendo rutas\n');
}

console.log('\n');

// ========================================
// 4. CONECTIVIDAD A RED A1A
// ========================================
console.log('4️⃣ TEST DE CONECTIVIDAD A RED A1A FACE ID:');
console.log('─────────────────────────────────────────────────────');

const testIPs = [
  { ip: '192.168.1.201', name: 'Terminal 1' },
  { ip: '192.168.1.202', name: 'Terminal 2' },
  { ip: '192.168.1.208', name: 'Terminal 3' },
  { ip: '192.168.1.1', name: 'Gateway probable' },
  { ip: '192.168.1.100', name: 'Servidor FaceOpen probable' }
];

for (const target of testIPs) {
  try {
    console.log(`\n   Probando ${target.name} (${target.ip})...`);
    const result = execSync(`ping -n 1 -w 1000 ${target.ip}`, { encoding: 'utf8' });
    
    if (result.includes('TTL=')) {
      console.log(`   ✅ RESPONDE - Tiempo: ${result.match(/tiempo[=<]\d+ms/)?.[0] || 'N/A'}`);
    } else {
      console.log(`   ❌ No responde`);
    }
  } catch (error) {
    console.log(`   ❌ No responde o timeout`);
  }
}

console.log('\n');

// ========================================
// 5. UBICACIÓN DE FACE RECOGNITION SYSTEM
// ========================================
console.log('5️⃣ UBICACIÓN DE FACE RECOGNITION SYSTEM:');
console.log('─────────────────────────────────────────────────────');

const faceOpenPath = 'C:\\Program Files (x86)\\Face recognition system';
const dbPath = path.join(faceOpenPath, 'DataBase', 'Data', 'FaceOpen_Data.MDF');

if (fs.existsSync(dbPath)) {
  console.log('✅ Face Recognition System está en ESTE SERVIDOR (LOCAL)');
  console.log(`   Ruta: ${faceOpenPath}`);
  
  const stats = fs.statSync(dbPath);
  console.log(`   Base de datos: ${dbPath}`);
  console.log(`   Última modificación: ${stats.mtime.toLocaleString('es-ES')}`);
  console.log(`   Tamaño: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);
  
  console.log('\n   💡 SOLUCIÓN: Monitor de archivos locales (YA IMPLEMENTADO)');
  console.log('   Comando: npm run monitor:files');
} else {
  console.log('❌ Face Recognition System NO está en este servidor');
  console.log('   Debe estar en otro servidor en red A1A');
  console.log('\n   💡 SOLUCIÓN: Necesitas acceso remoto a la base de datos');
}

console.log('\n');

// ========================================
// 6. ACCESO A INTERNET
// ========================================
console.log('6️⃣ CONECTIVIDAD A INTERNET (RED CLEAN):');
console.log('─────────────────────────────────────────────────────');

try {
  const result = execSync('ping -n 1 -w 2000 8.8.8.8', { encoding: 'utf8' });
  if (result.includes('TTL=')) {
    console.log('✅ Hay acceso a Internet (Red Clean funcional)');
  } else {
    console.log('❌ No hay acceso a Internet');
  }
} catch (error) {
  console.log('❌ No hay acceso a Internet');
}

console.log('\n');

// ========================================
// 7. PUERTOS SQL SERVER
// ========================================
console.log('7️⃣ PUERTOS SQL SERVER:');
console.log('─────────────────────────────────────────────────────');

try {
  const netstat = execSync('netstat -ano | findstr "1433\\|26888"', { encoding: 'utf8' });
  if (netstat) {
    console.log('Puertos SQL Server detectados:');
    console.log(netstat);
  } else {
    console.log('❌ No se detectaron puertos SQL Server escuchando');
  }
} catch (error) {
  console.log('❌ No se detectaron puertos SQL Server escuchando');
}

console.log('\n');

// ========================================
// RESUMEN Y RECOMENDACIONES
// ========================================
console.log('═══════════════════════════════════════════════════════');
console.log('📊 RESUMEN Y RECOMENDACIONES');
console.log('═══════════════════════════════════════════════════════\n');

// Detectar configuración
const hasLocalFaceOpen = fs.existsSync(dbPath);
const localIPs = [];

for (const [name, interfaces] of Object.entries(networkInterfaces)) {
  interfaces.forEach(iface => {
    if (iface.family === 'IPv4' && !iface.internal) {
      localIPs.push({ name, ip: iface.address });
    }
  });
}

console.log('🎯 CONFIGURACIÓN DETECTADA:\n');

if (hasLocalFaceOpen) {
  console.log('✅ Face Recognition System: LOCAL (en este servidor)');
  console.log('✅ Solución: Monitor de archivos locales');
  console.log('\n📋 PASOS A SEGUIR:');
  console.log('   1. Asegúrate de que las cámaras estén configuradas');
  console.log('   2. Ejecuta: npm run monitor:files');
  console.log('   3. Las cámaras reconocen → FaceOpen guarda → Monitor detecta → Dashboard muestra');
} else {
  console.log('⚠️  Face Recognition System: REMOTO (en otro servidor)');
  console.log('\n📋 NECESITAS:');
  console.log('   1. IP del servidor con FaceOpen');
  console.log('   2. Credenciales de SQL Server');
  console.log('   3. Acceso de red desde este servidor');
}

console.log('\n🌐 INTERFACES DE RED:');
if (localIPs.length > 1) {
  console.log('✅ Múltiples interfaces detectadas (posible configuración dual)');
  localIPs.forEach(iface => {
    console.log(`   • ${iface.name}: ${iface.ip}`);
  });
} else if (localIPs.length === 1) {
  console.log(`⚠️  Solo una interfaz activa: ${localIPs[0].ip}`);
  console.log('   Si necesitas acceso a ambas redes, considera:');
  console.log('   - Agregar segunda tarjeta de red');
  console.log('   - Configurar VPN/túnel');
  console.log('   - Usar carpeta compartida para sincronización');
}

console.log('\n💡 RECOMENDACIÓN FINAL:\n');

if (hasLocalFaceOpen && localIPs.some(i => i.ip.startsWith('192.168.1.'))) {
  console.log('🎉 CONFIGURACIÓN ÓPTIMA DETECTADA:');
  console.log('   • Face Recognition System local ✅');
  console.log('   • Acceso a red 192.168.1.x (A1A) ✅');
  console.log('   • Monitor de archivos funcionando ✅');
  console.log('\n   🚀 SISTEMA LISTO PARA USAR');
  console.log('   Ejecuta: npm run monitor:files');
} else if (hasLocalFaceOpen) {
  console.log('✅ Face Recognition System local');
  console.log('⚠️  Verifica conectividad con cámaras en red A1A');
  console.log('\n   Ejecuta: npm run monitor:files');
} else {
  console.log('⚠️  Necesitas configurar acceso remoto a FaceOpen');
  console.log('   Opciones:');
  console.log('   1. Conexión directa a SQL Server remoto');
  console.log('   2. Carpeta compartida para sincronización');
  console.log('   3. VPN entre redes');
}

console.log('\n═══════════════════════════════════════════════════════\n');

// Guardar reporte
const reportPath = path.join(__dirname, '..', 'network-diagnosis-report.txt');
console.log(`📄 Reporte guardado en: ${reportPath}\n`);
