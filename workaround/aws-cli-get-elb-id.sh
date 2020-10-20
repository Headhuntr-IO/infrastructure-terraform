##! /bin/bash
eval "$(jq -r '@sh "VPC=\(.vpc) REGION=\(.region)"')"
aws elbv2 describe-load-balancers --region $REGION --output json | jq --arg vpc $VPC -r '.LoadBalancers[] | select(.VpcId == $vpc) |  {"Result":.LoadBalancerArn}'