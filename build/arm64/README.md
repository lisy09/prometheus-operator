## Method to build arm64 images

```shell
git clone https://github.com/kubesphere/prometheus-operator.git

cd prometheus-operator

git checkout -b ks-v0.27.0 origin/ks-v0.27.0

docker buildx build -f build/arm64/operator/Dockerfile --output=type=registry --platform linux/amd64,linux/arm64  -t benjaminhuo/prometheus-operator:v0.27.1-arm64 .

docker buildx build -f build/arm64/prometheus-config-reloader/Dockerfile --output=type=registry --platform linux/amd64,linux/arm64  -t benjaminhuo/prometheus-config-reloader:v0.27.1-arm64 .
```
