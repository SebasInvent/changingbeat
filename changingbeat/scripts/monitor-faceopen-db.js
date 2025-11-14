/**
 * Monitor de Base de Datos FaceOpen
 * Conecta a la BD del sistema de reconocimiento facial y envía eventos al dashboard
 */

const sql = require('mssql');
const axios = require('axios');

// Configuración de conexión a SQL Server
const config = {
  server: 'localhost',
  database: 'FaceOpen',
  options: {
    trustServerCertificate: true,
    enableArithAbort: true,
    encrypt: false
  },
  // Autenticación Windows
  authentication: {
    type: 'default'
  }
};

const API_BASE = 'http://localhost:3000/api/v1';
const EDUARDO_ID = 'dd87444b-4cfc-4adb-8222-53ee7e26c956';

let lastEventId = null;
let lastCheckTime = new Date();

/**
 * Conectar a la base de datos
 */
async function connectDB() {
  try {
    console.log('🔌 Conectando a base de datos FaceOpen...');
    const pool = await sql.connect(config);
    console.log('✅ Conectado a FaceOpen SQL Server\n');
    return pool;
  } catch (error) {
    console.error('❌ Error conectando a BD:', error.message);
    console.log('\n💡 Intenta con estas alternativas:');
    console.log('   1. Verifica que SQL Server esté corriendo');
    console.log('   2. Prueba con usuario/contraseña si es necesario');
    console.log('   3. Verifica el nombre de la instancia\n');
    throw error;
  }
}

/**
 * Explorar estructura de la base de datos
 */
async function exploreDatabase(pool) {
  try {
    console.log('🔍 Explorando estructura de la base de datos...\n');
    
    // Listar tablas
    const tablesResult = await pool.request().query(`
      SELECT TABLE_NAME 
      FROM INFORMATION_SCHEMA.TABLES 
      WHERE TABLE_TYPE = 'BASE TABLE'
      ORDER BY TABLE_NAME
    `);
    
    console.log('📋 TABLAS ENCONTRADAS:');
    console.log('─────────────────────────────');
    tablesResult.recordset.forEach(table => {
      console.log(`   • ${table.TABLE_NAME}`);
    });
    console.log('');
    
    // Buscar tablas relacionadas con eventos/registros
    const eventTables = tablesResult.recordset.filter(t => {
      const name = t.TABLE_NAME.toLowerCase();
      return name.includes('event') || name.includes('log') || 
             name.includes('record') || name.includes('access') ||
             name.includes('history') || name.includes('person');
    });
    
    if (eventTables.length > 0) {
      console.log('🎯 TABLAS RELEVANTES:');
      console.log('─────────────────────────────');
      
      for (const table of eventTables) {
        const tableName = table.TABLE_NAME;
        
        // Obtener columnas
        const columnsResult = await pool.request().query(`
          SELECT COLUMN_NAME, DATA_TYPE 
          FROM INFORMATION_SCHEMA.COLUMNS 
          WHERE TABLE_NAME = '${tableName}'
          ORDER BY ORDINAL_POSITION
        `);
        
        console.log(`\n   📊 ${tableName}:`);
        columnsResult.recordset.forEach(col => {
          console.log(`      - ${col.COLUMN_NAME} (${col.DATA_TYPE})`);
        });
        
        // Contar registros
        const countResult = await pool.request().query(`
          SELECT COUNT(*) as total FROM [${tableName}]
        `);
        console.log(`      Total registros: ${countResult.recordset[0].total}`);
        
        // Mostrar últimos 3 registros
        try {
          const sampleResult = await pool.request().query(`
            SELECT TOP 3 * FROM [${tableName}] ORDER BY 1 DESC
          `);
          if (sampleResult.recordset.length > 0) {
            console.log(`      Últimos registros:`);
            sampleResult.recordset.forEach((record, i) => {
              console.log(`         ${i+1}. ${JSON.stringify(record).substring(0, 100)}...`);
            });
          }
        } catch (e) {
          // Ignorar errores de consulta
        }
      }
    }
    
    return eventTables.map(t => t.TABLE_NAME);
    
  } catch (error) {
    console.error('❌ Error explorando BD:', error.message);
    return [];
  }
}

/**
 * Monitorear eventos nuevos
 */
async function monitorEvents(pool, tableName) {
  try {
    // Intentar encontrar la columna de tiempo
    const columnsResult = await pool.request().query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_NAME = '${tableName}' 
      AND (COLUMN_NAME LIKE '%time%' OR COLUMN_NAME LIKE '%date%' OR COLUMN_NAME LIKE '%created%')
    `);
    
    const timeColumn = columnsResult.recordset[0]?.COLUMN_NAME || 'ID';
    
    // Consultar eventos recientes
    const result = await pool.request().query(`
      SELECT TOP 10 * 
      FROM [${tableName}] 
      ORDER BY [${timeColumn}] DESC
    `);
    
    for (const record of result.recordset) {
      // Buscar si el registro menciona a Eduardo
      const recordStr = JSON.stringify(record).toLowerCase();
      
      if (recordStr.includes('eduardo') || recordStr.includes('cuervo')) {
        console.log('📸 ¡Evento de Eduardo Cuervo detectado!');
        console.log('   Datos:', record);
        
        // Enviar al dashboard
        await sendToDashboard(record);
      }
    }
    
  } catch (error) {
    console.error('❌ Error monitoreando eventos:', error.message);
  }
}

/**
 * Enviar evento al dashboard
 */
async function sendToDashboard(event) {
  try {
    const response = await axios.post(`${API_BASE}/terminals/identify-callback`, {
      personId: EDUARDO_ID,
      ip: '192.168.1.201',
      temp: event.temperature || event.temp || 36.5,
      timestamp: event.time || event.datetime || event.created_at || new Date()
    });
    
    console.log('✅ Evento enviado al dashboard');
    
  } catch (error) {
    console.error('❌ Error enviando al dashboard:', error.message);
  }
}

/**
 * Iniciar monitoreo continuo
 */
async function startMonitoring() {
  try {
    const pool = await connectDB();
    
    // Explorar BD primero
    const eventTables = await exploreDatabase(pool);
    
    if (eventTables.length === 0) {
      console.log('\n⚠️  No se encontraron tablas de eventos obvias');
      console.log('   Revisa manualmente la base de datos para identificar la tabla correcta\n');
      return;
    }
    
    console.log('\n🔄 Iniciando monitoreo continuo...');
    console.log(`   Tabla principal: ${eventTables[0]}`);
    console.log('   Presiona Ctrl+C para detener\n');
    
    // Monitorear cada 3 segundos
    setInterval(async () => {
      await monitorEvents(pool, eventTables[0]);
    }, 3000);
    
    // Primera ejecución inmediata
    await monitorEvents(pool, eventTables[0]);
    
  } catch (error) {
    console.error('❌ Error fatal:', error.message);
    process.exit(1);
  }
}

// Iniciar
console.log('🎥 MONITOR DE SISTEMA FACEOPEN');
console.log('================================\n');

startMonitoring();
