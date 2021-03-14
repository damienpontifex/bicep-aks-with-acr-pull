#!/bin/bash

function group-setup {
    az ad group show --group $1 \
        --query objectId \
        --output tsv
    if [[ $? -ne 0 ]]; then
        az ad group create \
            --display-name $ADMIN_GROUP_NAME \
            --mail-nickname $ADMIN_GROUP_NAME \
            --query objectId \
            --output tsv
    fi
}

ADMIN_GROUP_OID=$(group-setup MyClusterAdmins)
echo "Admin group ObjectId: ${ADMIN_GROUP_OID}"

DEVELOPER_GROUP_OID=$(group-setup MyClusterDeveloper)
echo "Developer group ObjectId: ${DEVELOPER_GROUP_OID}"

CURRENT_USER_OID=$(az ad signed-in-user show --query objectId --output tsv)
az ad group member add \
    --group $ADMIN_GROUP_OID \
    --member-id $CURRENT_USER_OID

az ad group member add \
    --group $DEVELOPER_GROUP_OID \
    --member-id $CURRENT_USER_OID
