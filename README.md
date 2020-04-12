# ARM AKS with ACR pull roll assignment

Creating an Azure Kubernetes Service (AKS) cluster with managed identity and assigning pull RBAC permissions to the container registry.

```bash
az group create --location australiaeast --tags Environment=dev Client=self ApplicationName=aksroleassignment --name aksroleassignment-dev
az deployment group create --resource-group aksroleassignment-dev --template-file azuredeploy.json
```