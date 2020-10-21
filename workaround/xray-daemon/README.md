# XRAY Daemon
Dont worry, you only have to do this one time

## Steps
- create a docker image
```
docker build -t startupbuilder/xray-daemon:latest .
```
- (optional for AWS ECR) create a repo
```
aws ecr create-repository --repository-name xray-daemon --region us-east-1
docker tag startupbuilder/xray-daemon:latest xxx-account-id-xxx.dkr.ecr.us-east-1.amazonaws.com/xray-daemon:latest
```
- push the image
```
docker push startupbuilder/xray-daemon:latest
```
- map a K8 service account to AWS IAM role
```
eksctl utils associate-iam-oidc-provider --cluster hhv2-eks --approve
eksctl create iamserviceaccount --cluster=hhv2-eks --name=xraydaemonserviceaccount --namespace=default --attach-policy-arn=arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --approve --override-existing-serviceaccounts --region=us-east-1
```
- deploy the xray daemon to each worker node as a daemonset
```
kubectl apply -f xray-daemon.yaml
```