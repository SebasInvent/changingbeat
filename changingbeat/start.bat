@echo off
cls
echo =====================================
echo Sistema de Control de Acceso v2.0
echo =====================================
echo.

echo Verificando MongoDB...
sc query MongoDB | find "RUNNING" >nul
if errorlevel 1 (
    echo [ERROR] MongoDB no esta corriendo
    echo Iniciando MongoDB...
    net start MongoDB
    if errorlevel 1 (
        echo [ERROR] No se pudo iniciar MongoDB
        echo Por favor, inicia MongoDB manualmente
        pause
        exit /b 1
    )
) else (
    echo [OK] MongoDB esta corriendo
)

echo.
echo Iniciando servidor...
echo.

npm run dev

pause
