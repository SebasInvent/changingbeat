const swaggerJsDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const config = require('../config/env');

/**
 * Configuración de Swagger/OpenAPI
 */
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Sistema de Control de Acceso Biométrico API',
      version: '2.0.0',
      description: 'API REST para control de acceso con reconocimiento facial, gestión de usuarios y registros de entrada/salida',
      contact: {
        name: 'Soporte Técnico',
        email: 'soporte@example.com'
      },
      license: {
        name: 'ISC',
        url: 'https://opensource.org/licenses/ISC'
      }
    },
    servers: [
      {
        url: `http://localhost:${config.server.port}/api/v1`,
        description: 'Servidor de Desarrollo'
      },
      {
        url: 'http://192.168.1.2:3000/api/v1',
        description: 'Servidor de Producción'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Ingresa el token JWT obtenido del login'
        }
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            _id: {
              type: 'string',
              format: 'uuid',
              description: 'ID único del usuario'
            },
            firstName: {
              type: 'string',
              description: 'Primer nombre'
            },
            lastName: {
              type: 'string',
              description: 'Primer apellido'
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'Correo electrónico'
            },
            role: {
              type: 'string',
              enum: ['user', 'admin', 'operator'],
              description: 'Rol del usuario'
            },
            isActive: {
              type: 'boolean',
              description: 'Estado del usuario'
            },
            createdAt: {
              type: 'string',
              format: 'date-time'
            }
          }
        },
        Record: {
          type: 'object',
          properties: {
            _id: {
              type: 'string',
              description: 'ID único del registro'
            },
            userId: {
              type: 'string',
              description: 'ID del usuario'
            },
            terminalIp: {
              type: 'string',
              format: 'ipv4',
              description: 'IP del terminal'
            },
            recordType: {
              type: 'string',
              enum: ['entry', 'exit', 'denied'],
              description: 'Tipo de registro'
            },
            temperature: {
              type: 'number',
              format: 'float',
              description: 'Temperatura en grados Celsius'
            },
            status: {
              type: 'string',
              enum: ['success', 'failed', 'pending']
            },
            createdAt: {
              type: 'string',
              format: 'date-time'
            }
          }
        },
        Error: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false
            },
            message: {
              type: 'string'
            },
            errors: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  field: { type: 'string' },
                  message: { type: 'string' }
                }
              }
            }
          }
        },
        SuccessResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true
            },
            message: {
              type: 'string'
            },
            data: {
              type: 'object'
            }
          }
        }
      }
    },
    security: [
      {
        bearerAuth: []
      }
    ],
    tags: [
      {
        name: 'Auth',
        description: 'Endpoints de autenticación'
      },
      {
        name: 'Users',
        description: 'Gestión de usuarios'
      },
      {
        name: 'Records',
        description: 'Registros de acceso'
      },
      {
        name: 'Terminals',
        description: 'Gestión de terminales biométricos'
      }
    ]
  },
  apis: [
    './src/routes/*.js',
    './src/models/*.js',
    './src/controllers/*.js'
  ]
};

const swaggerSpec = swaggerJsDoc(swaggerOptions);

/**
 * Configurar Swagger UI
 */
const setupSwagger = (app) => {
  app.use('/api-docs', swaggerUi.serve);
  app.get('/api-docs', swaggerUi.setup(swaggerSpec, {
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: 'Control de Acceso API Docs',
    customfavIcon: '/favicon.ico'
  }));

  // JSON endpoint
  app.get('/api-docs.json', (req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.send(swaggerSpec);
  });
};

module.exports = { setupSwagger, swaggerSpec };
