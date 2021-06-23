#!/bin/bash

RESSOURCEGRPNAME="tp1-gerald"
LOCATION="ukwest"
CIDR="10.77.0.0/16"
SUBNETPUB="10.77.87.0/24"
VMNAME="tp1gbvm"
DNSNAME="tp1gb"

#RAZ trace.log
echo "" > trace.log

#Creation de la cle ssh
#ssh-keygen -m PEM -t rsa -b 4096 -N '' -f $VMNAME-id_rsa
#echo "$VMNAME-id_rsa" >> .gitignore
#echo "$VMNAME-id_rsa.pub" >> .gitignore

# Creation groupe ressources
echo "---- creation groupe ressources -----" 1>>trace.log 2>&1
if [ $(az group exists --name $RESSOURCEGRPNAME) = false ]; then
    az group create --name $RESSOURCEGRPNAME --location $LOCATION 1>>trace.log 2>&1
fi
echo "" 1>>trace.log 2>&1

# creation virtual network et subnet
echo "---- creation virtual network et subnet -----" 1>>trace.log 2>&1
if [ $(az network vnet list --resource-group $RESSOURCEGRPNAME --query "[?name == '$RESSOURCEGRPNAME-vnet'] | length(@)") = 0 ]; then
  az network vnet create \
    --resource-group $RESSOURCEGRPNAME \
    --location $LOCATION \
    --name $RESSOURCEGRPNAME-vnet \
    --address-prefix $CIDR \
    --subnet-name $RESSOURCEGRPNAME-vnet-subnet-pub \
    --subnet-prefix $SUBNETPUB 1>>trace.log 2>&1
fi
echo "" 1>>trace.log 2>&1

# creation ip publique
echo "---- creation ip publique -----" 1>>trace.log 2>&1
if [ $(az network public-ip list --resource-group $RESSOURCEGRPNAME --query "[?contains(name, '$VMNAME-ip')]| length(@)") = 0 ]; then
az network public-ip create \
  --resource-group $RESSOURCEGRPNAME \
  --location $LOCATION \
  --name $VMNAME-ip \
  --dns-name $DNSNAME 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1
fi

# creation groupe de secu
echo "---- creation grp secu -----" 1>>trace.log 2>&1
if [ $(az network nsg list --resource-group $RESSOURCEGRPNAME --query "[?contains(name, '$VMNAME-nsg')]| length(@)") = 0 ]; then
  az network nsg create \
    --resource-group $RESSOURCEGRPNAME \
    --location $LOCATION \
    --name $VMNAME-nsg 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

# creation rule SSH
echo "---- creation rule ssh -----" 1>>trace.log 2>&1
az network nsg rule create \
  --resource-group $RESSOURCEGRPNAME \
  --nsg-name $VMNAME-nsg \
  --name allow-ssh-$VMNAME-nsg \
  --protocol tcp \
  --direction Inbound \
  --source-address-prefix "*" \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --priority 1000 \
  --destination-port-range 22 \
  --access allow 1>>trace.log 2>&1

echo "" 1>>trace.log 2>&1

# creation rule HTTP
echo "---- creation rule HTTP -----" 1>>trace.log 2>&1
az network nsg rule create \
  --resource-group $RESSOURCEGRPNAME \
  --nsg-name $VMNAME-nsg \
  --name allow-http-$VMNAME-nsg \
  --protocol tcp \
  --direction Inbound \
  --source-address-prefix "*" \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --priority 1010 \
  --destination-port-range 80 \
  --access allow 1>>trace.log 2>&1
fi
echo "" 1>>trace.log 2>&1

#creation VNIC
echo "---- CREATION VNIC -----" 1>>trace.log 2>&1
if [ $(az network nic list --query "[?name == '$VMNAME-nic'] | length(@)") = 0 ]; then
  az network nic create \
    --resource-group $RESSOURCEGRPNAME \
    --location $LOCATION \
    --name $VMNAME-nic \
    --vnet-name $RESSOURCEGRPNAME-vnet \
    --subnet $RESSOURCEGRPNAME-vnet-subnet-pub \
    --public-ip-address $VMNAME-ip \
    --network-security-group $VMNAME-nsg 1>>trace.log 2>&1
fi
echo "" 1>>trace.log 2>&1

#creation VM
echo "---- CREATION VM -----" 1>>trace.log 2>&1
if [ $(az vm list --query "[?name == $VMNAME] | length(@)") = 0 ]; then
az vm create --resource-group $RESSOURCEGRPNAME \
  --name $VMNAME \
  --image UbuntuLTS \
#  --custom-data cloud-init.sh \
  --admin-username azureuser \
  --generate-ssh-keys \
  --output json \
  --verbose 1>>/tmp/trace.log 2>&1
fi

