# 📤 GUÍA PARA SUBIR A GITHUB

## ✅ ESTADO ACTUAL:

- ✅ Git inicializado
- ✅ .gitignore configurado
- ✅ README.md creado
- ✅ Primer commit realizado
- ✅ 86 archivos versionados

---

## 🚀 PASOS PARA SUBIR A GITHUB:

### **1. Crear repositorio en GitHub:**

1. Ve a: https://github.com/new
2. Nombre del repositorio: sistema-control-acceso (o el que prefieras)
3. Descripción: "Sistema de Control de Acceso Biométrico con Dashboard en Tiempo Real"
4. Privado o Público: **Privado** (recomendado)
5. **NO** inicialices con README, .gitignore o licencia
6. Click en "Create repository"

---

### **2. Conectar repositorio local con GitHub:**

Copia los comandos que GitHub te muestra, o usa estos:

\\\ash
# Agregar remote
git remote add origin https://github.com/TU_USUARIO/sistema-control-acceso.git

# Cambiar rama a main (opcional, si prefieres main en lugar de master)
git branch -M main

# Subir código
git push -u origin main
\\\

---

### **3. Verificar:**

1. Recarga la página de GitHub
2. Deberías ver todos los archivos
3. El README.md se mostrará automáticamente

---

## 📋 COMANDOS RÁPIDOS:

\\\ash
# Ver estado
git status

# Ver historial
git log --oneline

# Ver remotes
git remote -v
\\\

---

## 🔐 AUTENTICACIÓN:

Si GitHub te pide credenciales:

### **Opción 1: Personal Access Token (Recomendado)**

1. Ve a: https://github.com/settings/tokens
2. Click en "Generate new token (classic)"
3. Nombre: "Sistema Control Acceso"
4. Permisos: Selecciona "repo"
5. Click en "Generate token"
6. **COPIA EL TOKEN** (solo se muestra una vez)
7. Úsalo como contraseña cuando Git te lo pida

### **Opción 2: GitHub CLI**

\\\ash
# Instalar GitHub CLI
winget install GitHub.cli

# Autenticar
gh auth login
\\\

---

## 📝 WORKFLOW FUTURO:

### **Hacer cambios:**

\\\ash
# Ver cambios
git status

# Agregar archivos modificados
git add .

# Commit
git commit -m "Descripción del cambio"

# Subir a GitHub
git push
\\\

### **Ejemplo de commits:**

\\\ash
git commit -m "feat: Agregar endpoint de reportes"
git commit -m "fix: Corregir error en WebSocket"
git commit -m "docs: Actualizar README con nuevas instrucciones"
git commit -m "refactor: Mejorar estructura de controladores"
\\\

---

## 🌿 BRANCHES (Opcional):

Para trabajar en features sin afectar main:

\\\ash
# Crear nueva rama
git checkout -b feature/nueva-funcionalidad

# Hacer cambios y commits
git add .
git commit -m "feat: Nueva funcionalidad"

# Subir rama
git push -u origin feature/nueva-funcionalidad

# Volver a main
git checkout main

# Merge (después de aprobar)
git merge feature/nueva-funcionalidad
\\\

---

## 🎯 PRÓXIMOS PASOS:

1. **Crear repositorio en GitHub**
2. **Copiar la URL del repositorio**
3. **Ejecutar comandos de conexión**
4. **Hacer push**
5. **¡Listo!**

---

## 💡 TIPS:

- **Commits frecuentes:** Haz commits pequeños y descriptivos
- **Mensajes claros:** Usa prefijos como feat:, fix:, docs:, etc.
- **No subas secretos:** El .gitignore ya excluye archivos sensibles
- **Backup automático:** Cada push es un backup en la nube

---

## 🚨 ARCHIVOS EXCLUIDOS (por .gitignore):

- ✅ node_modules/
- ✅ logs/
- ✅ .env
- ✅ DataBase/
- ✅ Archivos temporales

**Estos NO se subirán a GitHub** (correcto para seguridad)

---

## 📞 COMANDOS PARA COPIAR:

Una vez que tengas la URL de tu repositorio en GitHub:

\\\ash
# Reemplaza TU_USUARIO y TU_REPO con los valores reales
git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
git branch -M main
git push -u origin main
\\\

---

**¡Tu código está listo para GitHub!** 🚀
