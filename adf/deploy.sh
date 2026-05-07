#!/usr/bin/env bash
# FILE: adf/deploy.sh
# PURPOSE: Deploy the ADF ARM template to Azure using Azure CLI
# REQUIRES: az cli installed and logged in (az login)
# USAGE: bash deploy.sh

set -euo pipefail

# ── CONFIG — update before running ──────────────────────────────────────────
RESOURCE_GROUP="rg-retail-etl"
LOCATION="eastus"
FACTORY_NAME="adf-retail-etl-$(date +%s)"   # unique name
SQL_CONN="Server=tcp:localhost,1433;Initial Catalog=RetailDB;User ID=sa;Password=YourPasswordHere;"
SF_CONN="host=<account>.snowflakecomputing.com;account=<account>;user=<user>;password=<password>;db=RETAIL_DW;schema=RAW;warehouse=COMPUTE_WH"
# ────────────────────────────────────────────────────────────────────────────

echo "Creating resource group …"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

echo "Creating Data Factory …"
az datafactory create \
  --resource-group "$RESOURCE_GROUP" \
  --factory-name   "$FACTORY_NAME" \
  --location       "$LOCATION"

echo "Deploying pipeline ARM template …"
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file  "arm_template.json" \
  --parameters \
    factoryName="$FACTORY_NAME" \
    sqlserver_connectionString="$SQL_CONN" \
    snowflake_connectionString="$SF_CONN"

echo ""
echo "✓ Deployed: $FACTORY_NAME in $RESOURCE_GROUP"
echo "  Open: https://adf.azure.com → select your subscription → $FACTORY_NAME"
