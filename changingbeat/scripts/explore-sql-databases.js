/**
 * Explorador de Bases de Datos SQL Server
 * Conecta y lista todas las bases de datos disponibles
 */

const sql = require('mssql');

// Intentar diferentes configuraciones
const configs = [
  {
    name: 'SQL Server (Windows Auth)',
    config: {
      server: 'localhost',
      database: 'master',
      options: {
        trustServerCertificate: true,
        enableArithAbort: true,
        encrypt: false
      },
      authentication: {
        type: 'default'
      }
    }
  },
  {
    name: 'SQL Server Express (Windows Auth)',
    config: {
      server: 'localhost\\SQLEXPRESS',
      database: 'master',
      options: {
        trustServerCertificate: true,
        enableArithAbort: true,
        encrypt: false
      },
      authentication: {
        type: 'default'
      }
    }
  }
];

async function testConnection(configObj) {
  console.log(`\n🔌 Probando: ${configObj.name}`);
  console.log('─────────────────────────────────────────');
  
  try {
    const pool = await sql.connect(configObj.config);
    console.log('✅ ¡CONEXIÓN EXITOSA!\n');
    
    // Listar bases de datos
    console.log('📊 BASES DE DATOS DISPONIBLES:');
    const result = await pool.request().query('SELECT name FROM sys.databases ORDER BY name');
    
    result.recordset.forEach(db => {
      console.log(`   • ${db.name}`);
    });
    
    // Buscar FaceOpen específicamente
    const faceOpenExists = result.recordset.find(db => 
      db.name.toLowerCase().includes('face') || 
      db.name.toLowerCase().includes('open')
    );
    
    if (faceOpenExists) {
      console.log(`\n✅ Base de datos relacionada encontrada: ${faceOpenExists.name}`);
      
      // Explorar tablas
      await pool.request().query(`USE [${faceOpenExists.name}]`);
      const tables = await pool.request().query(`
        SELECT TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_NAME
      `);
      
      console.log(`\n📋 TABLAS EN ${faceOpenExists.name}:`);
      tables.recordset.forEach(table => {
        console.log(`   • ${table.TABLE_NAME}`);
      });
    }
    
    await pool.close();
    return true;
    
  } catch (error) {
    console.log(`❌ Error: ${error.message}\n`);
    return false;
  }
}

async function explore() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('🔍 EXPLORADOR DE SQL SERVER');
  console.log('═══════════════════════════════════════════════════════');
  
  for (const configObj of configs) {
    const success = await testConnection(configObj);
    if (success) {
      console.log('\n✅ Configuración exitosa guardada.');
      break;
    }
  }
  
  console.log('\n═══════════════════════════════════════════════════════\n');
}

explore();
