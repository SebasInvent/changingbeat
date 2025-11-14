/**
 * Script para crear el usuario Eduardo Cuervo
 */

require('dotenv').config();
const mongoose = require('mongoose');
const { User } = require('../src/models');
const config = require('../src/config/env');

async function createEduardo() {
  try {
    console.log('📦 Conectando a MongoDB...');
    await mongoose.connect(config.database.uri, config.database.options);
    console.log('✅ Conectado a MongoDB\n');

    // Verificar si ya existe
    const existing = await User.findOne({ email: 'eduardo.cuervo@example.com' });
    
    if (existing) {
      console.log('ℹ️  Eduardo Cuervo ya existe en la base de datos');
      console.log(`   ID: ${existing._id}`);
      console.log(`   Email: ${existing.email}`);
      console.log(`   Nombre: ${existing.firstName} ${existing.lastName}`);
      console.log(`   Activo: ${existing.isActive}`);
      
      await mongoose.disconnect();
      process.exit(0);
      return;
    }

    // Crear usuario Eduardo Cuervo
    const eduardo = new User({
      firstName: 'Eduardo',
      lastName: 'Cuervo',
      email: 'eduardo.cuervo@example.com',
      phone: '3001234567',
      password: 'Eduardo123',
      role: 'user',
      isActive: true,
      biometricId: 'eduardo-cuervo-001' // ID que usa el terminal
    });

    await eduardo.save();

    console.log('✅ Usuario Eduardo Cuervo creado exitosamente!\n');
    console.log('📋 INFORMACIÓN DEL USUARIO:');
    console.log('─────────────────────────────────');
    console.log(`   ID: ${eduardo._id}`);
    console.log(`   Nombre: ${eduardo.firstName} ${eduardo.lastName}`);
    console.log(`   Email: ${eduardo.email}`);
    console.log(`   Teléfono: ${eduardo.phone}`);
    console.log(`   Rol: ${eduardo.role}`);
    console.log(`   Biometric ID: ${eduardo.biometricId}`);
    console.log(`   Activo: ${eduardo.isActive}`);
    console.log('');
    console.log('💡 PRÓXIMOS PASOS:');
    console.log('   1. El terminal debe enviar este ID en el callback');
    console.log('   2. Verifica los logs del servidor para ver los eventos');
    console.log('   3. Abre el dashboard: http://localhost:3000');
    console.log('   4. Verás las identificaciones en tiempo real');
    console.log('');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('👋 Desconectado de MongoDB');
    process.exit(0);
  }
}

createEduardo();
