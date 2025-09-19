#!/bin/bash

# Script para probar la configuración de la Parte 2
# Este script debe ejecutarse desde tu máquina host (no desde la VM)

echo "=== Probando la configuración de IoT Parte 2 ==="
echo ""

# Obtener el NodePort actual de Traefik
echo "Obteniendo el NodePort de Traefik..."
NODEPORT=$(vagrant ssh nponchonS -c "sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get svc -n kube-system traefik -o jsonpath='{.spec.ports[0].nodePort}'" 2>/dev/null)

if [ -z "$NODEPORT" ]; then
    echo "❌ ERROR: No se pudo obtener el NodePort de Traefik"
    exit 1
fi

echo "NodePort de Traefik: $NODEPORT"
echo ""

# Función para hacer peticiones HTTP con diferentes HOST headers
test_host() {
    local host=$1
    local expected_content=$2
    local description=$3
    
    echo "Testing $description..."
    echo "HOST: $host -> 192.168.56.110:$NODEPORT"
    
    # Usar curl con el header Host
    response=$(curl -s -H "Host: $host" http://192.168.56.110:$NODEPORT 2>/dev/null)
    
    if [[ $response == *"$expected_content"* ]]; then
        echo "✅ SUCCESS: Respuesta contiene '$expected_content'"
    else
        echo "❌ FAIL: Respuesta no contiene '$expected_content'"
        echo "Respuesta recibida: $response"
    fi
    echo ""
}

echo "Esperando a que la VM esté lista..."
echo "Asegúrate de que la VM esté ejecutándose con 'vagrant up' en el directorio p2_2"
echo ""

# Verificar que la VM responde
if ! curl -s --connect-timeout 5 http://192.168.56.110:$NODEPORT >/dev/null 2>&1; then
    echo "❌ ERROR: No se puede conectar a 192.168.56.110:$NODEPORT"
    echo "Verifica que la VM esté ejecutándose con 'vagrant up'"
    exit 1
fi

echo "VM respondiendo en puerto $NODEPORT, ejecutando pruebas..."
echo ""

# Probar app1.com (debe mostrar nginx)
test_host "app1.com" "App 1" "app1.com debería mostrar la aplicación Nginx"

# Probar app2.com (debe mostrar apache)
test_host "app2.com" "App 2" "app2.com debería mostrar la aplicación Apache (3 replicas)"

# Probar default (cualquier otro host)
test_host "anything.com" "Default Application" "Cualquier otro host debería mostrar la aplicación por defecto"

# Probar sin HOST header (debería mostrar default)
echo "Testing sin HOST header específico..."
response=$(curl -s http://192.168.56.110:$NODEPORT 2>/dev/null)
if [[ $response == *"Default Application"* ]]; then
    echo "✅ SUCCESS: Sin HOST header muestra la aplicación por defecto"
else
    echo "❌ FAIL: Sin HOST header no muestra la aplicación por defecto"
    echo "Respuesta: $response"
fi
echo ""

echo "=== Pruebas completadas ==="
echo ""
echo "Para ver los pods y servicios en la VM:"
echo "  vagrant ssh nponchonS"
echo "  sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get pods,svc,ingress"
echo ""
echo "Para probar manualmente desde tu navegador:"
echo "  1. Agrega estas líneas a tu /etc/hosts:"
echo "     192.168.56.110 app1.com"
echo "     192.168.56.110 app2.com"
echo "  2. Visita http://app1.com:$NODEPORT y http://app2.com:$NODEPORT"
echo ""
echo "NOTA: Traefik está ejecutándose en el NodePort $NODEPORT en lugar del puerto 80 estándar."
echo "Esto es normal en entornos K3s locales."