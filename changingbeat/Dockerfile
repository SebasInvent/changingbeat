# Usar la imagen oficial de Node.js LTS
FROM node:18-alpine

# Instalar dependencias necesarias para compilar módulos nativos
RUN apk add --no-cache python3 make g++

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias en modo producción
RUN npm ci --only=production

# Copiar el código fuente
COPY . .

# Reconstruir módulos nativos (bcrypt) para la imagen
RUN npm rebuild bcrypt --build-from-source

# Crear directorios necesarios
RUN mkdir -p uploads logs

# Exponer el puerto de la aplicación
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["node", "src/server.js"]
