#!/bin/bash

# Run a batch job on the Kubernetes cluster.
#
# Before running, be sure that:
#    - the image is built and available at $IMAGE, below.
#    - you're authenticated to the cluster via
#      gcloud container clusters get-credentials <cluster_name> --zone us-east1-c
#
# Example usage:
# export JIANT_PATH="/nfs/jsalt/home/$USER/jiant"
# ./run_batch.sh <job_name> "python $JIANT_PATH/main.py \
#    --config_file $JIANT_PATH/config/demo.conf \
#    --notify <your_email_address>"
#
# You can specify additional arguments as flags:
#    -m <mode>     # mode is 'create', 'replace', 'delete'
#    -g <gpu_type>  # e.g. 'k80' or 'p100'
#    -p <project>   # project folder to group experiments
#
# For example:
# ./run_batch.sh -p demos -m k80 jiant-demo \
#     "python $JIANT_PATH/main.py --config_file $JIANT_PATH/config/demo.conf"
#
# will run as job name 'demos.jiant-demo' and write results to /nfs/jsalt/exp/demos
#
set -e

MODE="create"
GPU_TYPE="p100"
PROJECT="$USER"

# Handle flags.
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts ":m:g:p:" opt; do
    case "$opt" in
    m)	MODE=$OPTARG
        ;;
    g)  GPU_TYPE=$OPTARG
        ;;
    p)  PROJECT=$OPTARG
        ;;
    \? )
        echo "Invalid flag $opt."
        exit 1
        ;;
    esac
done
shift $((OPTIND-1))

# Remaining positional args.
NAME=$1
COMMAND=$2

JOB_NAME="${PROJECT}.${NAME}"
PROJECT_DIR="/nfs/jsalt/exp/$PROJECT"
if [ ! -d "${PROJECT_DIR}" ]; then
  echo "Creating project directory ${PROJECT_DIR}"
  mkdir ${PROJECT_DIR}
  chmod -R o+w ${PROJECT_DIR}
fi

GCP_PROJECT_ID="$(gcloud config get-value project -q)"
IMAGE="gcr.io/${GCP_PROJECT_ID}/jiant-sandbox:v2"

##
# Create custom config and create a Kubernetes job.
cat <<EOF | kubectl ${MODE} -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
spec:
  backoffLimit: 1
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: jiant-sandbox
        image: ${IMAGE}
        command: ["bash"]
        args: ["-l", "-c", "$COMMAND"]
        resources:
          limits:
           nvidia.com/gpu: 1
        volumeMounts:
        - mountPath: /nfs/jsalt
          name: nfs-jsalt
        env:
        - name: NFS_PROJECT_PREFIX
          value: ${PROJECT_DIR}
        - name: JIANT_PROJECT_PREFIX
          value: ${PROJECT_DIR}
      nodeSelector:
        cloud.google.com/gke-accelerator: nvidia-tesla-${GPU_TYPE}
      volumes:
      - name: nfs-jsalt
        persistentVolumeClaim:
          claimName: nfs-jsalt-claim
          readOnly: false
EOF

