# Despliegue desde tu laptop con Windows

## 1 Instalar y abrir el proyecto

Si no tienes las herramientas, en PowerShell:

```powershell
winget install --exact --id Hashicorp.Terraform
winget install --exact --id Microsoft.AzureCLI
winget install --exact --id Git.Git
```

Cierra y vuelve a abrir VS Code. Clona el repositorio, cambia a la rama feature/landing-zone-azure y abre la carpeta laboratorios/landing-zone (o extrae el ZIP y abre terraform-landing-zone) y Terminal > Nueva terminal > PowerShell. Todos los comandos de Terraform se ejecutan allí.

```powershell
terraform version
az version
git --version
az login
az account list --output table
az account set --subscription "TU-ID-DE-SUSCRIPCION"
az account show --query "{subscription:id,tenant:tenantId}" --output json
az ad signed-in-user show --query "{objectId:id,login:userPrincipalName}" --output json
```

Si falla el inicio interactivo, usar az login --use-device-code. Un usuario invitado debe confirmar que su objectId corresponde al tenant de la suscripción, no al tenant de origen.

## 2 Preparar clave y variables

```powershell
ssh-keygen -t ed25519 -f "$HOME/.ssh/ineo_lab"
Copy-Item terraform.tfvars.example terraform.tfvars
```

No sobrescribas una clave existente. Usa frase de paso si corresponde. Edita terraform.tfvars con tu suscripción, tenant, objectId y UPN. ssh_public_key_path apunta a ineo_lab.pub. La clave SIN .pub es privada y se utiliza después al conectar por Bastion; nunca se sube a Git.

Consulta los tamaños/regiones autorizados antes de aplicar; cambia location, vm_size o postgres_sku si la cuenta escolar no los permite. B2ats_v2 y B1ms dependen de cuota y región.

Registra los proveedores de recursos (requiere permisos sobre la suscripción):

```powershell
$providers = 'Microsoft.Network','Microsoft.Compute','Microsoft.Web','Microsoft.Storage','Microsoft.DBforPostgreSQL','Microsoft.ManagedIdentity'
foreach ($provider in $providers) { az provider register --namespace $provider }
foreach ($provider in $providers) { az provider show --namespace $provider --query "{name:namespace,state:registrationState}" --output table }
```

Espera a que figuren Registered antes del plan. Contributor puede crear recursos, pero asignar RBAC exige permisos adicionales de roleAssignments/write.

## 3 Inicializar y revisar el plan

```powershell
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=lab.tfplan
```

Revisa cada recurso y el costo, las dos IP de endpoints, la ausencia de IP pública en la NIC de la VM, PaaS con acceso público desactivado y la subred de Bastion /26. No se fija un conteo de recursos sin un plan real. Guarda capturas de los comandos completos y de su salida; no muestres tokens o claves.

```powershell
terraform apply lab.tfplan
terraform output
terraform plan
```

apply del plan guardado no solicita un segundo yes. La confirmación final y el segundo plan sin cambios constituyen evidencias de aprovisionamiento. Si un recurso falla por cuota/política no cambies al azar a un SKU caro: verifica disponibilidad, ajusta variables, vuelve a planear y aplica. Si Azure creó parcialmente recursos, conserva el estado y corrige; no borres terraform.tfstate.

## 4 Revisar desde Azure Portal

Abre el grupo indicado por terraform output -raw resource_group. Captura VNet y cinco subredes, NSG y reglas, Private Endpoints Approved con 10.0.2.4 y 10.0.4.4, zonas DNS y enlaces, App Service con VNet Integration e identidad, VM sin IP pública, PostgreSQL y Storage con acceso público desactivado y roles del contenedor jobs.

La dirección HTTPS del App Service muestra el alojamiento. El código de INEO se publica por separado; una página de bienvenida no prueba conexión de la aplicación con PostgreSQL.

## 5 Conectar a la VM por Bastion

Portal > VM > Conectar > Bastion. Usuario azureuser (o el configurado) y clave privada ineo_lab. No abras SSH al público. Espera a terminar cloud-init:

```bash
sudo cloud-init status --wait
command -v psql
command -v python3
```

Si enable_vm_outbound=false no se instalan herramientas automáticamente; usa una imagen que ya las tenga o habilita la salida explícita y aprovisiona las herramientas. NSG permite los puertos de plataforma de Bastion; no los elimines al reducir reglas.

## 6 Inicializar los roles SQL de las identidades

En la laptop:

```powershell
terraform output -raw bootstrap_sql | Set-Content -Encoding utf8 bootstrap.generated.sql
terraform output -raw postgres_host
```

El archivo SQL se ejecuta una sola vez sobre la base ineo. Si ya existen los roles, comprueba sus objectId y omite solo las dos llamadas de creación; no elimines datos. Azure RBAC de Blob NO crea usuarios de PostgreSQL.

Dentro de la VM, instala Azure CLI siguiendo la documentación oficial si no está disponible:
https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux
Inicia sesión COMO EL ADMINISTRADOR ENTRA de PostgreSQL con az login --use-device-code. No uses az login --identity para esta inicialización: el rol worker aún no existe.

```bash
az login --use-device-code
export PGHOST='NOMBRE-DEVUELTO-POR-TERRAFORM.postgres.database.azure.com'
export PGUSER='UPN-DEL-ADMINISTRADOR-ENTRA'
export PGDATABASE='ineo'
export PGSSLMODE='verify-full'
export PGSSLROOTCERT='/etc/ssl/certs/ca-certificates.crt'
export PGPASSWORD="$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)"
```

Transfiere el contenido de bootstrap.generated.sql a un archivo bootstrap.sql en la VM mediante el editor de la sesión Bastion, sin imprimir tokens. Ejecuta:

```bash
psql -v ON_ERROR_STOP=1 -f bootstrap.sql
unset PGPASSWORD
az logout
```

Las asignaciones RBAC pueden tardar en propagarse. El token SQL es temporal. El bootstrap no se hace desde la laptop directamente porque la base solo es accesible por red privada.

## 7 Comprobar rutas y autenticación de la VM

Copia scripts/worker_probe.py a la VM. Establece el hostname de PostgreSQL y el nombre de Storage que devuelven los outputs:

```bash
python3 worker_probe.py --postgres 'HOST-POSTGRES' --storage 'NOMBRE-STORAGE'
```

El script exige resolución 10.0.2.4 y 10.0.4.4, obtiene tokens MI sin imprimirlos, consulta Blob por HTTPS y consulta la tabla SQL usando TLS verify-full. No mantiene un worker productivo ni modifica jobs. La prueba desde la Web App requiere publicar código que obtenga tokens con su propia MI y conecte con el usuario ineo_app; la MI de la VM usa ineo_worker.

Pruebas negativas: desde la laptop intenta acceso de datos a PostgreSQL y Blob sin túnel; debe rechazarse. No confundas un listado de Azure Portal (plano de administración) con acceso de datos público. La VM debe carecer de IP pública y las conexiones SSH deben provenir de Bastion. Documenta resultados reales, no anticipados.

## 8 Evidencias y limpieza

Completa la sección de ejecución del Word con capturas reales: init, validate, plan, apply, outputs, segundo plan, recursos y pruebas anteriores. No se adjuntan capturas de despliegue que no se haya realizado.

```powershell
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

Revisa antes el plan: elimina base, datos Blob y VM del laboratorio. Respaldar antes si guardaste información. Conserva el estado hasta confirmar eliminación. Nunca usar datos clínicos reales en esta práctica.


## Recuperacion de un apply parcial

No borrar terraform.tfstate ni cambiar location globalmente. Descargar las correcciones de security.tf, versions.tf, variables.tf y services.tf desde la misma rama y conservar terraform.tfvars.

- NSG: un puerto unico o * usa destination_port_range; solo una lista de puertos usa destination_port_ranges.
- Storage: features.storage.data_plane_available=false evita comprobaciones de datos desde la laptop contra una cuenta privada. storage_use_azuread=true evita Shared Key en operaciones compatibles. La cuenta mantiene claves compartidas y red publica desactivadas.
- PostgreSQL Version should be in []: consultar capacidades, registro del proveedor y restricciones de la suscripcion antes de cambiar version o SKU. No asumir que cambiar 16 por 15 resuelve una lista vacia.

```powershell
az provider show --namespace Microsoft.DBforPostgreSQL --query registrationState -o tsv
az postgres flexible-server list-skus --location eastus --output table
terraform state list
terraform fmt
terraform validate
terraform plan "-out=lab.tfplan"
```

Si la region no permite el servicio, postgres_location permite elegir SOLO la region de PostgreSQL; revisar antes conectividad Private Link entre regiones, politicas y costo. postgres_version permite ajustar la version cuando las capacidades la admitan. No cambiar location de los recursos ya desplegados para probar suerte.

Un fallo puede dejar recursos existentes fuera del estado. Si el nuevo plan informa que la cuenta ya existe, primero comprobar su estado en Azure y que no figura en terraform state list; solo entonces importar azurerm_storage_account.blob con su resource ID. Si aparece en estado como tainted, revisar el plan de reemplazo y el contenido antes de decidir; no ejecutar untaint a ciegas. Aplicar solo el plan nuevo revisado, no reutilizar el archivo anterior al cambio de codigo.
