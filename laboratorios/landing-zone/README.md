# Laboratorio Terraform de la arquitectura de Azure

Implementación de la arquitectura de referencia adjunta para INEO. Un proyecto raíz y un estado: red, servicios, cómputo e identidades en archivos separados. No modifica los despliegues anteriores de la clínica. Región inicial eastus; ajustar según políticas y cuota del tenant.

## Qué crea

- Grupo de recursos con nombres únicos y etiquetas; VNet 10.0.0.0/16.
- snet-app 10.0.1.0/24 delegada a Microsoft.Web/serverFarms; App Service Linux B1, HTTPS y TLS 1.2, integración VNet y MI de sistema.
- snet-db 10.0.2.0/24; Private Endpoint PostgreSQL 10.0.2.4.
- PostgreSQL Flexible Server 16 B_Standard_B1ms, base ineo y autenticación Entra únicamente. Sin acceso público ni reglas de firewall públicas.
- snet-vm 10.0.3.0/24; VM Ubuntu 24.04 Standard_B2ats_v2, 10.0.3.4, MI y SSH con clave, sin IP pública.
- snet-endpoints 10.0.4.0/24; Private Endpoint Blob 10.0.4.4; Storage Standard LRS privado, sin claves compartidas.
- AzureBastionSubnet 10.0.5.0/26; Bastion Basic e IP pública Standard.
- Cinco NSG, dos zonas DNS privadas y sus enlaces; RBAC Blob Data Contributor a las dos MI, limitado al contenedor jobs.
- NAT Gateway e IP pública para salida explícita de la VM, configurable con enable_vm_outbound. No habilita conexiones entrantes a la VM.

**Costo:** B1, PostgreSQL, VM, Bastion, Private Endpoints, DNS, discos, NAT e IP públicas pueden consumir crédito. El diagrama completo NO cabe en App Service F1. Revisa el costo en Azure antes de aplicar. Detener la VM no elimina Bastion, NAT, discos ni otros cargos. Destruir el proyecto al terminar evita mantener recursos innecesarios.

## Ajustes respecto al dibujo

1. Bastion exige /26 o mayor; se reemplaza el /27 del dibujo por 10.0.5.0/26.
2. PostgreSQL usa Private Link, NO una subred delegada al servidor. Solo snet-app está delegada. No mezclar ambos modelos de red de PostgreSQL.
3. La entrada web es el endpoint público de App Service, no una IP dentro de snet-app. VNet Integration es para salida a recursos privados.
4. Token MI no sustituye TLS. Blob usa RBAC; PostgreSQL requiere crear roles SQL para las identidades. Se entrega bootstrap_sql para esa fase.
5. NAT es una adición de soporte para APT y diagnósticos en la VM, que no tiene IP pública. Puede omitirse si la imagen ya contiene las herramientas y no necesita salida a Internet.
6. No se implementa un worker de producción ni el código de la web; se prepara su infraestructura y permisos. El script worker_probe.py verifica DNS, tokens, Blob y SQL desde la VM.

## Requisitos

Windows, PowerShell, Git, Terraform >=1.9 y <2, Azure CLI, OpenSSH, suscripción activa con cuota para los SKU, permisos Contributor más User Access Administrator (u Owner) para las asignaciones RBAC. El usuario de PostgreSQL debe pertenecer al tenant elegido.

Lee **docs/PASOS_WINDOWS.md** para desplegar. No copies variables de la práctica anterior: este entorno usa otra red y otros recursos.

## Archivos

versions.tf: proveedor y versiones. variables.tf y terraform.tfvars.example: entradas.
locals.tf: nombres, etiquetas y direcciones. network.tf: VNet, subredes, DNS y NAT.
security.tf: cinco NSG y asociaciones. services.tf: App Service, PostgreSQL, Blob y endpoints.
compute.tf: VM, NIC, Bastion e IP administrativa. identity.tf: permisos Blob.
outputs.tf: datos y SQL de inicialización. scripts/: herramientas de comprobación.

## Estado de comprobación

terraform init -backend=false: completado con AzureRM 4.81.0 y random 3.7.2.
terraform fmt -check -recursive: completado sin diferencias.
La validación local de proveedores quedó bloqueada por la prohibición de sockets Unix del entorno de preparación. No se ha hecho terraform plan ni apply con una cuenta de Azure. El workflow incluido ejecutará init y validate sin credenciales después de publicar el repositorio; consultar su ejecución en Actions. Consultar su resultado real antes de desplegar. Un validate correcto no verifica cuota, disponibilidad regional ni permisos de Azure.

## Git

Esta práctica se publica en laboratorios/landing-zone, rama feature/landing-zone-azure del repositorio JoelLara10/Terraform. El ZIP original también conserva un repositorio Git local. Los commits separan red y controles, servicios e identidades, y guía y validación. El bloqueo .terraform.lock.hcl se conserva. No subir terraform.tfvars, estados, planes, claves privadas ni tokens. El estado local requiere protección y respaldo; si varias personas aplican, migrar primero a un backend remoto compartido con bloqueo.

## Referencias oficiales

- https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
- https://learn.microsoft.com/en-us/azure/bastion/secure-bastion
- https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-networking-private-link
- https://learn.microsoft.com/en-us/azure/postgresql/security/security-manage-entra-users
- https://learn.microsoft.com/en-us/azure/postgresql/security/security-connect-with-managed-identity
