# IoT Parte 2 - K3s y tres aplicaciones simples

Este directorio contiene la configuración para la Parte 2 del proyecto Inception-of-Things.

## Objetivo

Configurar una sola máquina virtual con K3s en modo servidor y desplegar 3 aplicaciones web que sean accesibles según el header HOST:

- `app1.com` → Aplicación Nginx (App 1)
- `app2.com` → Aplicación Apache con 3 réplicas (App 2)  
- Cualquier otro host → Aplicación por defecto (App 3)

## Archivos

- `Vagrantfile` - Configuración de la VM con K3s
- `nginx_app.yaml` - Deployment y Service para la aplicación Nginx
- `apache_app.yaml` - Deployment y Service para la aplicación Apache (3 réplicas)
- `default_app.yaml` - Deployment y Service para la aplicación por defecto
- `ingress.yaml` - Configuración del Ingress para el routing basado en HOST
- `test_config.sh` - Script para probar la configuración

## Instrucciones de uso

### 1. Iniciar la VM

```bash
vagrant up
```

### 2. Verificar el estado

```bash
vagrant ssh nponchonS
kubectl get pods,svc,ingress
kubectl get nodes
```

### 3. Probar la configuración

Desde tu máquina host (no desde la VM):

```bash
./test_config.sh
```

### 4. Prueba manual con navegador

Agrega estas líneas a tu `/etc/hosts`:

```
192.168.56.110 app1.com
192.168.56.110 app2.com
```

Luego visita:
- http://app1.com (debería mostrar la página de Nginx)
- http://app2.com (debería mostrar la página de Apache)
- http://192.168.56.110 (debería mostrar la página por defecto)

## Especificaciones técnicas

- **VM**: Ubuntu 24.04 LTS con 1 CPU y 1024 MB RAM
- **IP**: 192.168.56.110
- **K3s**: Modo servidor con Traefik habilitado
- **Aplicación 1**: Nginx (1 réplica)
- **Aplicación 2**: Apache (3 réplicas)
- **Aplicación 3**: Nginx con página por defecto (1 réplica)

## Troubleshooting

### La VM no responde
```bash
vagrant halt
vagrant up
```

### Los pods no están ejecutándose
```bash
vagrant ssh nponchonS
kubectl get pods -A
kubectl describe pod <pod-name>
```

### El Ingress no funciona
```bash
vagrant ssh nponchonS
kubectl get ingress
kubectl describe ingress main-ingress
```

### Comprobar logs de Traefik
```bash
vagrant ssh nponchonS
kubectl logs -n kube-system deployment/traefik
```

## Limpieza

Para eliminar la VM:

```bash
vagrant destroy -f
```