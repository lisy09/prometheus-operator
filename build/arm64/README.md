## Method to build arm64 images

```shell
git clone https://github.com/kubesphere/prometheus-operator.git

cd prometheus-operator

git checkout -b ks-v3.0 origin/ks-v3.0

docker buildx build -f build/arm64/operator/Dockerfile --output type=docker,dest=prometheus-operator:v0.38.3-arm64.tar --platform linux/arm64 -t kubesphere/prometheus-operator:v0.38.3-arm64 .

docker buildx build -f build/arm64/prometheus-config-reloader/Dockerfile --output type=docker,dest=prometheus-config-reloader:v0.38.3-arm64.tar --platform linux/arm64  -t kubesphere/prometheus-config-reloader:v0.38.3-arm64 .
```
