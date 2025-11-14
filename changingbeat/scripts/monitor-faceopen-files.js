/**
 * Monitor de Archivos del Sistema FaceOpen
 * Monitorea cambios en archivos de la base de datos y logs
 */

const fs = require('fs');
const path = require('path');
const axios = require('axios');

const FACEOPEN_PATH = 'C:\\Program Files (x86)\\Face recognition system';
const API_BASE = 'http://localhost:3000/api/v1';
const EDUARDO_ID = 'dd87444b-4cfc-4adb-8222-53ee7e26c956';

// Rutas a monitorear
const paths = {
  database: path.join(FACEOPEN_PATH, 'DataBase', 'Data', 'FaceOpen_Data.MDF'),
  log: path.join(FACEOPEN_PATH, 'DataBase', 'Log', 'minilog.txt'),
  dataFolder: path.join(FACEOPEN_PATH, 'DataBase', 'Data')
};

let lastDbModified = null;
let lastLogSize = 0;
let eventCount = 0;

console.log('═══════════════════════════════════════════════════════');
console.log('🎥 MONITOR DE ARCHIVOS FACEOPEN');
console.log('═══════════════════════════════════════════════════════\n');

console.log('📂 Rutas monitoreadas:');
console.log(`   DB: ${paths.database}`);
console.log(`   Log: ${paths.log}`);
console.log(`   Carpeta: ${paths.dataFolder}\n`);

// Verificar que existan
for (const [key, filePath] of Object.entries(paths)) {
  if (fs.existsSync(filePath)) {
    console.log(`✅ ${key}: Encontrado`);
  } else {
    console.log(`❌ ${key}: No encontrado`);
  }
}

console.log('\n─────────────────────────────────────────────────────');
console.log('🔄 Iniciando monitoreo...');
console.log('💡 Muévete frente a la cámara para generar eventos');
console.log('🔴 Presiona Ctrl+C para detener\n');
console.log('─────────────────────────────────────────────────────\n');

/**
 * Enviar evento al dashboard
 */
async function sendEvent(source) {
  try {
    eventCount++;
    
    const response = await axios.post(`${API_BASE}/terminals/identify-callback`, {
      personId: EDUARDO_ID,
      ip: '192.168.1.201',
      temp: (35.8 + Math.random() * 1.5).toFixed(1),
      timestamp: new Date().toISOString()
    });
    
    console.log(`✅ [${new Date().toLocaleTimeString()}] Evento #${eventCount} enviado al dashboard`);
    console.log(`   Fuente: ${source}`);
    console.log(`   Respuesta: ${response.data.message}\n`);
    
  } catch (error) {
    console.error(`❌ Error enviando evento:`, error.message);
  }
}

/**
 * Monitorear cambios en la base de datos
 */
function monitorDatabase() {
  try {
    if (fs.existsSync(paths.database)) {
      const stats = fs.statSync(paths.database);
      
      if (lastDbModified === null) {
        lastDbModified = stats.mtime;
      } else if (stats.mtime > lastDbModified) {
        console.log(`📸 [${new Date().toLocaleTimeString()}] Base de datos modificada`);
        lastDbModified = stats.mtime;
        sendEvent('Base de datos FaceOpen');
      }
    }
  } catch (error) {
    // Ignorar errores de lectura
  }
}

/**
 * Monitorear cambios en el log
 */
function monitorLog() {
  try {
    if (fs.existsSync(paths.log)) {
      const stats = fs.statSync(paths.log);
      
      if (lastLogSize === 0) {
        lastLogSize = stats.size;
      } else if (stats.size > lastLogSize) {
        console.log(`📝 [${new Date().toLocaleTimeString()}] Log actualizado`);
        
        // Leer las nuevas líneas
        const content = fs.readFileSync(paths.log, 'utf8');
        const newContent = content.substring(lastLogSize);
        
        // Buscar menciones de eventos
        if (newContent.toLowerCase().includes('face') || 
            newContent.toLowerCase().includes('person') ||
            newContent.toLowerCase().includes('eduardo')) {
          console.log(`   Contenido nuevo: ${newContent.substring(0, 100)}...`);
          sendEvent('Log FaceOpen');
        }
        
        lastLogSize = stats.size;
      }
    }
  } catch (error) {
    // Ignorar errores de lectura
  }
}

/**
 * Monitorear carpeta de datos
 */
const watchedFiles = new Map();

function monitorDataFolder() {
  try {
    if (fs.existsSync(paths.dataFolder)) {
      const files = fs.readdirSync(paths.dataFolder);
      
      for (const file of files) {
        const filePath = path.join(paths.dataFolder, file);
        
        try {
          const stats = fs.statSync(filePath);
          const lastMod = watchedFiles.get(filePath);
          
          if (!lastMod) {
            watchedFiles.set(filePath, stats.mtime);
          } else if (stats.mtime > lastMod) {
            console.log(`📁 [${new Date().toLocaleTimeString()}] Archivo modificado: ${file}`);
            watchedFiles.set(filePath, stats.mtime);
            
            // Solo enviar evento para archivos relevantes
            if (file.includes('FaceOpen')) {
              sendEvent(`Archivo: ${file}`);
            }
          }
        } catch (e) {
          // Archivo en uso o sin permisos
        }
      }
    }
  } catch (error) {
    // Ignorar errores
  }
}

/**
 * Usar FileSystemWatcher para detección en tiempo real
 */
if (fs.existsSync(paths.dataFolder)) {
  const watcher = fs.watch(paths.dataFolder, { persistent: true }, (eventType, filename) => {
    if (filename && filename.includes('FaceOpen')) {
      console.log(`🔔 [${new Date().toLocaleTimeString()}] Evento detectado: ${eventType} en ${filename}`);
      
      // Esperar un momento para que el archivo se actualice completamente
      setTimeout(() => {
        sendEvent(`FileWatcher: ${filename}`);
      }, 500);
    }
  });
  
  console.log('👀 FileWatcher activo en carpeta de datos\n');
}

// Monitoreo por polling cada 2 segundos
setInterval(() => {
  monitorDatabase();
  monitorLog();
  monitorDataFolder();
}, 2000);

// Mensaje de estado cada 30 segundos
setInterval(() => {
  console.log(`⏱️  [${new Date().toLocaleTimeString()}] Monitoreando... (${eventCount} eventos enviados)`);
}, 30000);

// Mantener el proceso vivo
process.on('SIGINT', () => {
  console.log('\n\n🛑 Deteniendo monitor...');
  console.log(`📊 Total de eventos enviados: ${eventCount}`);
  console.log('👋 ¡Hasta luego!\n');
  process.exit(0);
});
