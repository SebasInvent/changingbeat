/**
 * Script de Diagnóstico del Sistema de Cámaras
 * Ayuda a identificar cómo integrar el sistema existente
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🔍 DIAGNÓSTICO DEL SISTEMA DE CÁMARAS');
console.log('=====================================\n');

// 1. Buscar procesos relacionados con cámaras
console.log('1️⃣ PROCESOS EN EJECUCIÓN:');
console.log('─────────────────────────────');
try {
  const processes = execSync('tasklist', { encoding: 'utf8' });
  const cameraKeywords = ['camera', 'biometric', 'face', 'recognition', 'zkbio', 'hikvision', 'dahua'];
  
  const lines = processes.split('\n');
  let found = false;
  
  for (const line of lines) {
    const lower = line.toLowerCase();
    if (cameraKeywords.some(keyword => lower.includes(keyword))) {
      console.log(`   ✓ ${line.trim()}`);
      found = true;
    }
  }
  
  if (!found) {
    console.log('   ℹ️  No se encontraron procesos obvios de cámaras');
  }
} catch (error) {
  console.log('   ❌ Error listando procesos');
}

console.log('');

// 2. Buscar carpetas comunes de instalación
console.log('2️⃣ CARPETAS DE INSTALACIÓN:');
console.log('─────────────────────────────');
const commonPaths = [
  'C:\\Program Files\\',
  'C:\\Program Files (x86)\\',
  'C:\\ProgramData\\',
  'C:\\Users\\Public\\Documents\\'
];

const cameraFolders = [];

for (const basePath of commonPaths) {
  try {
    if (fs.existsSync(basePath)) {
      const folders = fs.readdirSync(basePath);
      for (const folder of folders) {
        const lower = folder.toLowerCase();
        if (lower.includes('camera') || lower.includes('biometric') || 
            lower.includes('face') || lower.includes('zkbio') ||
            lower.includes('hikvision') || lower.includes('recognition')) {
          const fullPath = path.join(basePath, folder);
          cameraFolders.push(fullPath);
          console.log(`   ✓ ${fullPath}`);
        }
      }
    }
  } catch (error) {
    // Ignorar errores de permisos
  }
}

if (cameraFolders.length === 0) {
  console.log('   ℹ️  No se encontraron carpetas obvias');
}

console.log('');

// 3. Buscar archivos de log
console.log('3️⃣ ARCHIVOS DE LOG RECIENTES:');
console.log('─────────────────────────────');
const logPaths = [
  ...cameraFolders.map(f => path.join(f, 'logs')),
  ...cameraFolders.map(f => path.join(f, 'log')),
  'C:\\Logs',
  'C:\\ProgramData\\Logs'
];

const logFiles = [];

for (const logPath of logPaths) {
  try {
    if (fs.existsSync(logPath)) {
      const files = fs.readdirSync(logPath);
      for (const file of files) {
        if (file.endsWith('.log') || file.endsWith('.txt')) {
          const fullPath = path.join(logPath, file);
          const stats = fs.statSync(fullPath);
          
          // Solo archivos modificados en las últimas 24 horas
          const hoursSinceModified = (Date.now() - stats.mtime.getTime()) / (1000 * 60 * 60);
          if (hoursSinceModified < 24) {
            logFiles.push({
              path: fullPath,
              size: stats.size,
              modified: stats.mtime
            });
          }
        }
      }
    }
  } catch (error) {
    // Ignorar errores
  }
}

if (logFiles.length > 0) {
  logFiles.sort((a, b) => b.modified - a.modified);
  logFiles.slice(0, 10).forEach(file => {
    const sizeKB = (file.size / 1024).toFixed(2);
    const time = file.modified.toLocaleString('es-ES');
    console.log(`   ✓ ${file.path}`);
    console.log(`     Tamaño: ${sizeKB} KB | Modificado: ${time}`);
  });
} else {
  console.log('   ℹ️  No se encontraron logs recientes');
}

console.log('');

// 4. Buscar bases de datos
console.log('4️⃣ BASES DE DATOS:');
console.log('─────────────────────────────');
const dbPaths = [
  ...cameraFolders.map(f => path.join(f, 'data')),
  ...cameraFolders.map(f => path.join(f, 'database')),
  ...cameraFolders.map(f => path.join(f, 'db'))
];

const dbFiles = [];

for (const dbPath of dbPaths) {
  try {
    if (fs.existsSync(dbPath)) {
      const files = fs.readdirSync(dbPath);
      for (const file of files) {
        if (file.endsWith('.db') || file.endsWith('.sqlite') || 
            file.endsWith('.mdb') || file.endsWith('.accdb')) {
          dbFiles.push(path.join(dbPath, file));
        }
      }
    }
  } catch (error) {
    // Ignorar
  }
}

if (dbFiles.length > 0) {
  dbFiles.forEach(file => console.log(`   ✓ ${file}`));
} else {
  console.log('   ℹ️  No se encontraron bases de datos locales');
}

console.log('');

// 5. Buscar servicios de Windows
console.log('5️⃣ SERVICIOS DE WINDOWS:');
console.log('─────────────────────────────');
try {
  const services = execSync('sc query type= service state= all', { encoding: 'utf8' });
  const lines = services.split('\n');
  let currentService = '';
  
  for (const line of lines) {
    if (line.includes('SERVICE_NAME:')) {
      currentService = line.split(':')[1].trim().toLowerCase();
    }
    if (line.includes('DISPLAY_NAME:')) {
      const displayName = line.split(':')[1].trim();
      if (currentService.includes('camera') || currentService.includes('biometric') ||
          currentService.includes('face') || currentService.includes('zkbio') ||
          displayName.toLowerCase().includes('camera') ||
          displayName.toLowerCase().includes('biometric')) {
        console.log(`   ✓ ${displayName} (${currentService})`);
      }
    }
  }
} catch (error) {
  console.log('   ℹ️  No se pudieron listar servicios');
}

console.log('');

// 6. Buscar puertos en uso
console.log('6️⃣ PUERTOS EN USO (posibles APIs):');
console.log('─────────────────────────────');
try {
  const netstat = execSync('netstat -ano | findstr LISTENING', { encoding: 'utf8' });
  const lines = netstat.split('\n');
  const ports = new Set();
  
  for (const line of lines) {
    const match = line.match(/:(\d+)\s/);
    if (match) {
      const port = parseInt(match[1]);
      // Puertos comunes de sistemas de cámaras
      if ([80, 8080, 8000, 8090, 8081, 9000, 5000, 3000].includes(port)) {
        ports.add(port);
      }
    }
  }
  
  if (ports.size > 0) {
    Array.from(ports).sort((a, b) => a - b).forEach(port => {
      console.log(`   ✓ Puerto ${port} - Prueba: http://localhost:${port}`);
    });
  }
} catch (error) {
  console.log('   ℹ️  No se pudieron listar puertos');
}

console.log('');
console.log('=====================================');
console.log('📋 RESUMEN Y RECOMENDACIONES:');
console.log('=====================================\n');

if (cameraFolders.length > 0) {
  console.log('✅ Se encontraron carpetas de sistema de cámaras');
  console.log('   Revisa estas carpetas para encontrar:');
  console.log('   - Archivos de configuración (.ini, .conf, .xml)');
  console.log('   - Documentación (README, manual)');
  console.log('   - Archivos ejecutables principales\n');
}

if (logFiles.length > 0) {
  console.log('✅ Se encontraron archivos de log activos');
  console.log('   Puedes monitorear estos archivos para detectar eventos');
  console.log(`   Archivo más reciente: ${logFiles[0].path}\n`);
  console.log('   Comando para ver en tiempo real:');
  console.log(`   Get-Content "${logFiles[0].path}" -Wait -Tail 20\n`);
}

if (dbFiles.length > 0) {
  console.log('✅ Se encontraron bases de datos');
  console.log('   Podrías consultar estas bases de datos para obtener eventos\n');
}

console.log('💡 PRÓXIMOS PASOS:');
console.log('─────────────────────────────');
console.log('1. Revisa la carpeta de instalación del sistema');
console.log('2. Busca archivos de configuración');
console.log('3. Verifica si hay una interfaz web (prueba los puertos listados)');
console.log('4. Revisa los logs cuando Eduardo sea detectado');
console.log('5. Comparte la información encontrada para crear la integración\n');

console.log('📞 ¿Necesitas ayuda?');
console.log('Comparte:');
console.log('- Nombre del software de cámaras');
console.log('- Contenido de un archivo de log cuando Eduardo es detectado');
console.log('- Capturas de pantalla de la interfaz del sistema\n');
