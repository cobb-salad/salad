#!/bin/sh

if [ "${PWD##*/}" = "create" ];then
    KUBECONFIG_FOLDER=${PWD}/../../kube-config
elif [ "${PWD##*/}" = "scripts" ];then
    KUBECONFIG_FOLDER=${PWD}/../kube-config
else
    echo "Please run the script from 'scripts' or 'scripts/create' folder"
fi

PROJECT_FOLDER=${PWD}/../../../../
echo $PROJECT_FOLDER
echo $KUBECONFIG_FOLDER


echo "Create Volume"
if [ "$(kubectl get pvc | grep shared-pvc | awk '{print $2}')" != "Bound" ]; then
    kubectl create -f ${KUBECONFIG_FOLDER}/createVolume.yaml

    if [ "kubectl get pvc | grep shared-pvc | awk '{print $3}'" != "shared-pv" ]; then
        echo "Success creating Persistant Volume"
    else
        echo "Failed to create Persistant Volume"
    fi
else
    echo "The Persistant Volume exists, not creating again"
fi 

echo "Create artifacts"
kubectl create -f ${KUBECONFIG_FOLDER}/createArtifactsJob.yaml

pod=$(kubectl get pods --selector=job-name=copyartifacts --output=jsonpath={.items..metadata.name})

podSTATUS=$(kubectl get pods --selector=job-name=copyartifacts --output=jsonpath={.items..phase})

while [ "${podSTATUS}" != "Running" ]; do
    echo "Wating for container of copy artifact pod to run. Current status of ${pod} is ${podSTATUS}"
    sleep 5;
    if [ "${podSTATUS}" = "Error" ]; then
        echo "There is an error in copyartifacts job. Please check logs."
        exit 1
    fi
    podSTATUS=$(kubectl get pods --selector=job-name=copyartifacts --output=jsonpath={.items..phase})
done

echo -e "${pod} is now ${podSTATUS}"
echo -e "\nStarting to copy artifacts in persistent volume."

ARTIFACTS_FOLDER=${PWD}/../../artifacts
echo $ARTIFACTS_FOLDER
mkdir $ARTIFACTS_FOLDER
cp -r ${PROJECT_FOLDER}/configtx.yaml ${PROJECT_FOLDER}/crypto-config.yaml ${PROJECT_FOLDER}/chaincode ${ARTIFACTS_FOLDER}/

echo ${KUBECONFIG_FOLDER}
kubectl cp ${KUBECONFIG_FOLDER}/../artifacts $pod:/shared/

echo "Waiting for 10 more seconds for copying artifacts to avoid any network delay"
sleep 10
#JOBSTATUS=$(kubectl get jobs |grep "copyartifacts" |awk '{print $3}')
JOBSTATUS=$(kubectl get jobs -l job-name=copyartifacts --output=jsonpath='{.items[0].status.succeeded}')
while [ "${JOBSTATUS}" != "1" ]; do
    echo "Waiting for copyartifacts job to complete"
    sleep 1;
    PODSTATUS=$(kubectl get pods | grep "copyartifacts" | awk '{print $3}')
        if [ "${PODSTATUS}" = "Error" ]; then
            echo "There is an error in copyartifacts job. Please check logs."
            exit 1
        fi
    JOBSTATUS=$(kubectl get jobs -l job-name=copyartifacts --output=jsonpath='{.items[0].status.succeeded}')
done
echo "Copy artifacts job completed"

echo "Generate artifacts"
kubectl create -f ${KUBECONFIG_FOLDER}/generateArtifactsJob.yaml

JOBSTATUS=$(kubectl get jobs -l job-name=utils --output=jsonpath='{.items[0].status.succeeded}')
while [ "${JOBSTATUS}" != "1" ]; do
    echo "Waiting for generateArtifacts job to complete"
    sleep 1;
    # UTILSLEFT=$(kubectl get pods | grep utils | awk '{print $2}')
    UTILSSTATUS=$(kubectl get pods | grep "utils" | awk '{print $3}')
    if [ "${UTILSSTATUS}" = "Error" ]; then
            echo "There is an error in utils job. Please check logs."
            exit 1
    fi
    # UTILSLEFT=$(kubectl get pods | grep utils | awk '{print $2}')
    JOBSTATUS=$(kubectl get jobs -l job-name=utils --output=jsonpath='{.items[0].status.succeeded}')
done


echo "Create service"
kubectl create -f ${KUBECONFIG_FOLDER}/blockchain-services.yaml
kubectl create -f ${KUBECONFIG_FOLDER}/kafka.yaml

echo "Create deployment"
kubectl create -f ${KUBECONFIG_FOLDER}/peersDeployment.yaml

NUMPENDING=$(kubectl get deployments | egrep 'store|mymarket'| awk '{print $5}' | grep 0 | wc -l | awk '{print $1}')
while [ "${NUMPENDING}" != "0" ]; do
    echo "Waiting on pending deployments. Deployments pending = ${NUMPENDING}"
    NUMPENDING=$(kubectl get deployments | egrep 'store|mymarket' | awk '{print $5}' | grep 0 | wc -l | awk '{print $1}')
    sleep 1
done

echo "Waiting for 15 seconds for peers and orderer to settle"
sleep 15

#
echo "Create Channel"
kubectl create -f ${KUBECONFIG_FOLDER}/create_channel.yaml

JOBSTATUS=$(kubectl get jobs -l job-name=createchanneltx --output=jsonpath='{.items[0].status.succeeded}')
while [ "${JOBSTATUS}" != "1" ]; do
    echo "Waiting for createchannel job to be completed"
    sleep 1;
    if [ "$(kubectl get pods | grep createchannel | awk '{print $3}')" = "Error" ]; then
        echo "Create Channel Failed"
        exit 1
    fi
    JOBSTATUS=$(kubectl get jobs -l job-name=createchanneltx --output=jsonpath='{.items[0].status.succeeded}')
done
echo "Create Channel Completed Successfully"
#
#
#echo "Join Channel"
#kubectl create -f ${KUBECONFIG_FOLDER}/join_channel.yaml
#
#JOBSTATUS=$(kubectl get jobs -l job-name=joinchannel --output=jsonpath='{.items[0].status.succeeded}')
#while [ "${JOBSTATUS}" != "1" ]; do
#    echo "Waiting for joinchannel job to be completed"
#    sleep 1;
#    if [ "$(kubectl get pods | grep joinchannel | awk '{print $3}')" = "Error" ]; then
#        echo "Join Channel Failed"
#        exit 1
#    fi
#    JOBSTATUS=$(kubectl get jobs -l job-name=joinchannel --output=jsonpath='{.items[0].status.succeeded}')
#done
#echo "Join Channel Completed Successfully"
#
## Install chaincode on each peer
#echo -e "\nCreating installchaincode job"
#kubectl create -f ${KUBECONFIG_FOLDER}/chaincode_install.yaml
#
#JOBSTATUS=$(kubectl get jobs -l job-name=chaincodeinstall --output=jsonpath='{.items[0].status.succeeded}')
#while [ "${JOBSTATUS}" != "1" ]; do
#    echo "Waiting for chaincodeinstall job to be completed"
#    sleep 1;
#    if [ "$(kubectl get pods | grep chaincodeinstall | awk '{print $3}')" = "Error" ]; then
#        echo "Chaincode Install Failed"
#        exit 1
#    fi
#    JOBSTATUS=$(kubectl get jobs -l job-name=chaincodeinstall --output=jsonpath='{.items[0].status.succeeded}')
#done
#echo "Chaincode Install Completed Successfully"
#
#
## Instantiate chaincode on channel
#echo -e "\nCreating chaincodeinstantiate job"
#kubectl create -f ${KUBECONFIG_FOLDER}/chaincode_instantiate.yaml
#
#JOBSTATUS=$(kubectl get jobs -l job-name=chaincodeinstantiate --output=jsonpath='{.items[0].status.succeeded}')
#while [ "${JOBSTATUS}" != "1" ]; do
#    echo "Waiting for chaincodeinstantiate job to be completed"
#    sleep 1;
#    if [ "$(kubectl get pods | grep chaincodeinstantiate | awk '{print $3}')" = "Error" ]; then
#        echo "Chaincode Instantiation Failed"
#        exit 1
#    fi
#    JOBSTATUS=$(kubectl get jobs -l job-name=chaincodeinstantiate --output=jsonpath='{.items[0].status.succeeded}')
#done
#echo "Chaincode Instantiation Completed Successfully"
#
#sleep 15
#echo -e "\nNetwork Setup Completed !!"
