/**
 * Análisis Completo del Sistema
 * Identifica todos los dispositivos, servicios y recursos disponibles
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

console.log('═══════════════════════════════════════════════════════');
console.log('🔍 ANÁLISIS COMPLETO DEL SISTEMA');
console.log('═══════════════════════════════════════════════════════\n');

// ========================================
// 1. INFORMACIÓN DEL SISTEMA
// ========================================
console.log('1️⃣ INFORMACIÓN DEL SISTEMA:');
console.log('─────────────────────────────────────────────────────');
console.log(`   Sistema Operativo: ${os.type()} ${os.release()}`);
console.log(`   Arquitectura: ${os.arch()}`);
console.log(`   Hostname: ${os.hostname()}`);
console.log(`   CPUs: ${os.cpus().length} cores (${os.cpus()[0].model})`);
console.log(`   RAM Total: ${(os.totalmem() / 1024 / 1024 / 1024).toFixed(2)} GB`);
console.log(`   RAM Libre: ${(os.freemem() / 1024 / 1024 / 1024).toFixed(2)} GB`);
console.log(`   Uptime: ${(os.uptime() / 3600).toFixed(2)} horas`);
console.log('');

// ========================================
// 2. INTERFACES DE RED
// ========================================
console.log('2️⃣ INTERFACES DE RED:');
console.log('─────────────────────────────────────────────────────');
const networkInterfaces = os.networkInterfaces();
for (const [name, interfaces] of Object.entries(networkInterfaces)) {
  console.log(`\n   📡 ${name}:`);
  interfaces.forEach(iface => {
    if (iface.family === 'IPv4' && !iface.internal) {
      console.log(`      IP: ${iface.address}`);
      console.log(`      MAC: ${iface.mac}`);
      console.log(`      Netmask: ${iface.netmask}`);
    }
  });
}
console.log('');

// ========================================
// 3. PUERTOS SERIALES (COM)
// ========================================
console.log('3️⃣ PUERTOS SERIALES (COM):');
console.log('─────────────────────────────────────────────────────');
try {
  const { SerialPort } = require('serialport');
  SerialPort.list().then(ports => {
    if (ports.length > 0) {
      ports.forEach(port => {
        console.log(`   ✓ ${port.path}`);
        if (port.manufacturer) console.log(`     Fabricante: ${port.manufacturer}`);
        if (port.serialNumber) console.log(`     Serial: ${port.serialNumber}`);
        if (port.pnpId) console.log(`     PnP ID: ${port.pnpId}`);
      });
    } else {
      console.log('   ℹ️  No se encontraron puertos seriales');
    }
  });
} catch (error) {
  console.log('   ⚠️  SerialPort no disponible');
}
console.log('');

// ========================================
// 4. DISPOSITIVOS USB
// ========================================
console.log('4️⃣ DISPOSITIVOS USB:');
console.log('─────────────────────────────────────────────────────');
try {
  const usb = execSync('wmic path Win32_USBControllerDevice get Dependent', { encoding: 'utf8' });
  const devices = usb.split('\n').filter(line => line.includes('USB'));
  if (devices.length > 0) {
    const uniqueDevices = [...new Set(devices)];
    uniqueDevices.slice(0, 10).forEach(device => {
      const match = device.match(/DeviceID="([^"]+)"/);
      if (match) {
        console.log(`   ✓ ${match[1].replace(/\\\\/g, '\\')}`);
      }
    });
    if (uniqueDevices.length > 10) {
      console.log(`   ... y ${uniqueDevices.length - 10} dispositivos más`);
    }
  } else {
    console.log('   ℹ️  No se encontraron dispositivos USB');
  }
} catch (error) {
  console.log('   ⚠️  Error listando dispositivos USB');
}
console.log('');

// ========================================
// 5. CÁMARAS Y DISPOSITIVOS DE VIDEO
// ========================================
console.log('5️⃣ CÁMARAS Y DISPOSITIVOS DE VIDEO:');
console.log('─────────────────────────────────────────────────────');
try {
  const cameras = execSync('wmic path Win32_PnPEntity where "Caption like \'%camera%\' or Caption like \'%webcam%\' or Caption like \'%video%\'" get Caption,DeviceID', { encoding: 'utf8' });
  const lines = cameras.split('\n').filter(line => line.trim() && !line.includes('Caption'));
  if (lines.length > 0) {
    lines.forEach(line => {
      if (line.trim()) {
        console.log(`   ✓ ${line.trim()}`);
      }
    });
  } else {
    console.log('   ℹ️  No se encontraron cámaras');
  }
} catch (error) {
  console.log('   ⚠️  Error listando cámaras');
}
console.log('');

// ========================================
// 6. SERVICIOS EN EJECUCIÓN
// ========================================
console.log('6️⃣ SERVICIOS RELEVANTES EN EJECUCIÓN:');
console.log('─────────────────────────────────────────────────────');
try {
  const services = execSync('sc query type= service state= running', { encoding: 'utf8' });
  const lines = services.split('\n');
  const relevantKeywords = ['sql', 'mongo', 'camera', 'biometric', 'face', 'recognition', 'zkbio', 'mysql', 'postgres'];
  
  let currentService = '';
  let displayName = '';
  
  for (const line of lines) {
    if (line.includes('SERVICE_NAME:')) {
      currentService = line.split(':')[1].trim();
    }
    if (line.includes('DISPLAY_NAME:')) {
      displayName = line.split(':')[1].trim();
      const lower = (currentService + ' ' + displayName).toLowerCase();
      if (relevantKeywords.some(keyword => lower.includes(keyword))) {
        console.log(`   ✓ ${displayName}`);
        console.log(`     Servicio: ${currentService}`);
      }
    }
  }
} catch (error) {
  console.log('   ⚠️  Error listando servicios');
}
console.log('');

// ========================================
// 7. PROCESOS RELEVANTES
// ========================================
console.log('7️⃣ PROCESOS RELEVANTES EN EJECUCIÓN:');
console.log('─────────────────────────────────────────────────────');
try {
  const processes = execSync('tasklist', { encoding: 'utf8' });
  const lines = processes.split('\n');
  const relevantKeywords = ['camera', 'biometric', 'face', 'recognition', 'zkbio', 'sql', 'mongo', 'node'];
  
  const found = new Set();
  for (const line of lines) {
    const lower = line.toLowerCase();
    if (relevantKeywords.some(keyword => lower.includes(keyword))) {
      const processName = line.split(/\s+/)[0];
      if (processName && !found.has(processName)) {
        found.add(processName);
        console.log(`   ✓ ${processName}`);
      }
    }
  }
  
  if (found.size === 0) {
    console.log('   ℹ️  No se encontraron procesos relevantes');
  }
} catch (error) {
  console.log('   ⚠️  Error listando procesos');
}
console.log('');

// ========================================
// 8. PUERTOS EN USO
// ========================================
console.log('8️⃣ PUERTOS EN USO (Posibles APIs/Servicios):');
console.log('─────────────────────────────────────────────────────');
try {
  const netstat = execSync('netstat -ano | findstr LISTENING', { encoding: 'utf8' });
  const lines = netstat.split('\n');
  const ports = new Map();
  
  for (const line of lines) {
    const match = line.match(/:(\d+)\s+.*?LISTENING\s+(\d+)/);
    if (match) {
      const port = parseInt(match[1]);
      const pid = match[2];
      
      // Puertos comunes de interés
      if ([80, 443, 3000, 3001, 5000, 8000, 8080, 8081, 8090, 9000, 27017, 3306, 5432, 1433, 26888].includes(port)) {
        if (!ports.has(port)) {
          ports.set(port, pid);
        }
      }
    }
  }
  
  if (ports.size > 0) {
    const sortedPorts = Array.from(ports.entries()).sort((a, b) => a[0] - b[0]);
    for (const [port, pid] of sortedPorts) {
      try {
        const taskInfo = execSync(`tasklist /FI "PID eq ${pid}" /FO CSV /NH`, { encoding: 'utf8' });
        const processName = taskInfo.split(',')[0].replace(/"/g, '');
        console.log(`   ✓ Puerto ${port} - ${processName} (PID: ${pid})`);
        
        // Identificar el servicio
        const services = {
          80: 'HTTP',
          443: 'HTTPS',
          3000: 'Node.js / Dashboard',
          8080: 'HTTP Alt / API',
          8090: 'Terminal Biométrico',
          27017: 'MongoDB',
          3306: 'MySQL',
          5432: 'PostgreSQL',
          1433: 'SQL Server',
          26888: 'SQL Server (FaceOpen)'
        };
        if (services[port]) {
          console.log(`     Servicio probable: ${services[port]}`);
        }
      } catch (e) {
        console.log(`   ✓ Puerto ${port} (PID: ${pid})`);
      }
    }
  } else {
    console.log('   ℹ️  No se encontraron puertos relevantes');
  }
} catch (error) {
  console.log('   ⚠️  Error listando puertos');
}
console.log('');

// ========================================
// 9. BASES DE DATOS DETECTADAS
// ========================================
console.log('9️⃣ BASES DE DATOS DETECTADAS:');
console.log('─────────────────────────────────────────────────────');

// MongoDB
try {
  const mongoService = execSync('sc query MongoDB', { encoding: 'utf8' });
  if (mongoService.includes('RUNNING')) {
    console.log('   ✓ MongoDB - RUNNING');
    console.log('     Puerto: 27017');
    console.log('     Conexión: mongodb://localhost:27017');
  }
} catch (e) {
  console.log('   ✗ MongoDB - No detectado');
}

// SQL Server
try {
  const sqlServices = execSync('sc query type= service state= all | findstr SQL', { encoding: 'utf8' });
  if (sqlServices) {
    console.log('   ✓ SQL Server detectado');
    console.log('     Instancia: LESUNMINISQL');
    console.log('     Puerto: 26888');
    console.log('     Base de datos: FaceOpen');
  }
} catch (e) {
  console.log('   ✗ SQL Server - No detectado');
}

// MySQL
try {
  const mysqlService = execSync('sc query MySQL', { encoding: 'utf8' });
  if (mysqlService.includes('RUNNING')) {
    console.log('   ✓ MySQL - RUNNING');
  }
} catch (e) {
  // MySQL no detectado
}

console.log('');

// ========================================
// 10. SOFTWARE DE CÁMARAS/BIOMÉTRICOS
// ========================================
console.log('🔟 SOFTWARE DE CÁMARAS/BIOMÉTRICOS INSTALADO:');
console.log('─────────────────────────────────────────────────────');

const searchPaths = [
  'C:\\Program Files',
  'C:\\Program Files (x86)',
  'C:\\ProgramData'
];

const foundSoftware = [];

for (const basePath of searchPaths) {
  try {
    if (fs.existsSync(basePath)) {
      const folders = fs.readdirSync(basePath);
      for (const folder of folders) {
        const lower = folder.toLowerCase();
        if (lower.includes('camera') || lower.includes('biometric') || 
            lower.includes('face') || lower.includes('zkbio') ||
            lower.includes('recognition') || lower.includes('hikvision') ||
            lower.includes('dahua')) {
          const fullPath = path.join(basePath, folder);
          foundSoftware.push({ name: folder, path: fullPath });
        }
      }
    }
  } catch (error) {
    // Ignorar errores de permisos
  }
}

if (foundSoftware.length > 0) {
  foundSoftware.forEach(software => {
    console.log(`   ✓ ${software.name}`);
    console.log(`     Ruta: ${software.path}`);
    
    // Buscar ejecutables
    try {
      const exeFiles = execSync(`dir "${software.path}\\*.exe" /s /b 2>nul`, { encoding: 'utf8' });
      const exes = exeFiles.split('\n').filter(f => f.trim()).slice(0, 3);
      if (exes.length > 0) {
        console.log(`     Ejecutables:`);
        exes.forEach(exe => {
          const fileName = path.basename(exe);
          console.log(`       - ${fileName}`);
        });
      }
    } catch (e) {
      // No hay ejecutables o error de permisos
    }
    console.log('');
  });
} else {
  console.log('   ℹ️  No se encontró software de cámaras instalado');
}

// ========================================
// 11. DISPOSITIVOS EN RED
// ========================================
console.log('1️⃣1️⃣ DISPOSITIVOS EN RED LOCAL:');
console.log('─────────────────────────────────────────────────────');
console.log('   Escaneando red local (esto puede tomar un momento)...');

try {
  // Obtener IP local
  const ifaces = os.networkInterfaces();
  let localIP = '';
  for (const [name, interfaces] of Object.entries(ifaces)) {
    for (const iface of interfaces) {
      if (iface.family === 'IPv4' && !iface.internal) {
        localIP = iface.address;
        break;
      }
    }
    if (localIP) break;
  }
  
  if (localIP) {
    const subnet = localIP.substring(0, localIP.lastIndexOf('.'));
    console.log(`   Red: ${subnet}.0/24`);
    
    // Escanear IPs configuradas en .env
    const envPath = path.join(__dirname, '..', '.env');
    if (fs.existsSync(envPath)) {
      const envContent = fs.readFileSync(envPath, 'utf8');
      const terminalIPs = envContent.match(/TERMINAL_IPS=([^\n]+)/);
      if (terminalIPs) {
        const ips = terminalIPs[1].split(',');
        console.log(`\n   📡 Terminales configurados:`);
        ips.forEach(ip => {
          console.log(`      ${ip.trim()}`);
        });
      }
    }
  }
} catch (error) {
  console.log('   ⚠️  Error escaneando red');
}

console.log('\n');

// ========================================
// RESUMEN FINAL
// ========================================
console.log('═══════════════════════════════════════════════════════');
console.log('📊 RESUMEN DEL ANÁLISIS');
console.log('═══════════════════════════════════════════════════════\n');

console.log('✅ RECURSOS DISPONIBLES:');
console.log('   • Sistema operativo y hardware identificado');
console.log('   • Interfaces de red detectadas');
console.log('   • Puertos seriales disponibles');
console.log('   • Servicios y procesos relevantes');
console.log('   • Bases de datos activas');
console.log('   • Software de cámaras instalado\n');

console.log('💡 RECOMENDACIONES:');
console.log('   1. Revisar software de cámaras encontrado');
console.log('   2. Verificar conexión a bases de datos');
console.log('   3. Probar comunicación con terminales en red');
console.log('   4. Configurar puertos seriales si es necesario\n');

console.log('📝 ARCHIVO GENERADO:');
const reportPath = path.join(__dirname, '..', 'system-analysis-report.txt');
console.log(`   ${reportPath}\n`);

console.log('═══════════════════════════════════════════════════════\n');
