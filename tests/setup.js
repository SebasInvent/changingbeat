/**
 * Setup global para tests
 */

// Configurar variables de entorno para tests
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret-key';
process.env.MONGODB_URI = 'mongodb://localhost:27017/autoregistro-test';

// Configurar timeout global
jest.setTimeout(10000);

// Cleanup después de cada test
afterEach(async () => {
  // Aquí puedes agregar limpieza de recursos si es necesario
});
