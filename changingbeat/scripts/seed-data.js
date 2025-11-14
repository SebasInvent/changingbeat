/**
 * Script para poblar la base de datos con datos de prueba
 */

require('dotenv').config();
const mongoose = require('mongoose');
const { User, Record } = require('../src/models');
const config = require('../src/config/env');

// Datos de usuarios de prueba
const testUsers = [
  {
    firstName: 'Juan',
    lastName: 'Pérez',
    secondName: 'Carlos',
    secondLastName: 'García',
    email: 'juan.perez@example.com',
    phone: '3001234567',
    password: 'Password123',
    role: 'user',
    isActive: true
  },
  {
    firstName: 'María',
    lastName: 'González',
    secondName: 'Isabel',
    secondLastName: 'Rodríguez',
    email: 'maria.gonzalez@example.com',
    phone: '3009876543',
    password: 'Password123',
    role: 'user',
    isActive: true
  },
  {
    firstName: 'Carlos',
    lastName: 'Martínez',
    email: 'carlos.martinez@example.com',
    phone: '3005551234',
    password: 'Password123',
    role: 'user',
    isActive: true
  },
  {
    firstName: 'Ana',
    lastName: 'López',
    secondName: 'María',
    email: 'ana.lopez@example.com',
    phone: '3007778888',
    password: 'Password123',
    role: 'user',
    isActive: true
  },
  {
    firstName: 'Admin',
    lastName: 'Sistema',
    email: 'admin@sistema.com',
    phone: '3001111111',
    password: 'Admin123456',
    role: 'admin',
    isActive: true
  }
];

// Función para generar registros aleatorios
function generateRandomRecords(users, count = 50) {
  const records = [];
  const terminals = config.terminals.ips;
  const recordTypes = ['entry', 'exit', 'denied'];
  
  for (let i = 0; i < count; i++) {
    const randomUser = users[Math.floor(Math.random() * users.length)];
    const randomTerminal = terminals[Math.floor(Math.random() * terminals.length)];
    const randomType = recordTypes[Math.floor(Math.random() * recordTypes.length)];
    
    // Generar fecha aleatoria en los últimos 7 días
    const daysAgo = Math.floor(Math.random() * 7);
    const hoursAgo = Math.floor(Math.random() * 24);
    const date = new Date();
    date.setDate(date.getDate() - daysAgo);
    date.setHours(date.getHours() - hoursAgo);
    
    // Temperatura aleatoria entre 35.5 y 38.5
    const temperature = 35.5 + Math.random() * 3;
    
    records.push({
      userId: randomUser._id,
      terminalIp: randomTerminal,
      recordType: randomType,
      temperature: parseFloat(temperature.toFixed(1)),
      status: randomType === 'denied' ? 'failed' : 'success',
      denialReason: randomType === 'denied' ? 'Temperatura elevada' : undefined,
      createdAt: date
    });
  }
  
  return records;
}

// Función principal
async function seedDatabase() {
  try {
    console.log('🌱 Iniciando seed de base de datos...\n');
    
    // Conectar a MongoDB
    console.log('📦 Conectando a MongoDB...');
    await mongoose.connect(config.database.uri, config.database.options);
    console.log('✅ Conectado a MongoDB\n');
    
    // Limpiar datos existentes (opcional)
    console.log('🗑️  Limpiando datos existentes...');
    await User.deleteMany({});
    await Record.deleteMany({});
    console.log('✅ Datos limpiados\n');
    
    // Crear usuarios
    console.log('👥 Creando usuarios de prueba...');
    const createdUsers = [];
    for (const userData of testUsers) {
      const user = new User(userData);
      await user.save();
      createdUsers.push(user);
      console.log(`   ✓ ${user.firstName} ${user.lastName} (${user.email})`);
    }
    console.log(`✅ ${createdUsers.length} usuarios creados\n`);
    
    // Crear registros
    console.log('📋 Creando registros de acceso...');
    const records = generateRandomRecords(createdUsers, 50);
    await Record.insertMany(records);
    console.log(`✅ ${records.length} registros creados\n`);
    
    // Estadísticas
    console.log('📊 RESUMEN:');
    console.log('─────────────────────────────────');
    console.log(`Total Usuarios: ${createdUsers.length}`);
    console.log(`Total Registros: ${records.length}`);
    console.log('');
    console.log('👤 USUARIOS CREADOS:');
    console.log('─────────────────────────────────');
    createdUsers.forEach(user => {
      console.log(`   • ${user.firstName} ${user.lastName}`);
      console.log(`     Email: ${user.email}`);
      console.log(`     Password: ${testUsers.find(u => u.email === user.email).password}`);
      console.log(`     Rol: ${user.role}`);
      console.log('');
    });
    
    console.log('🎉 ¡Seed completado exitosamente!');
    console.log('');
    console.log('💡 PRÓXIMOS PASOS:');
    console.log('   1. Recarga el dashboard: http://localhost:3000');
    console.log('   2. Usa estas credenciales para login:');
    console.log('      Admin: admin@sistema.com / Admin123456');
    console.log('      Usuario: juan.perez@example.com / Password123');
    console.log('');
    
  } catch (error) {
    console.error('❌ Error durante el seed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('👋 Desconectado de MongoDB');
    process.exit(0);
  }
}

// Ejecutar
seedDatabase();
