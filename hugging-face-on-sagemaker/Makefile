build-deploy:
	docker buildx build \
		--file Dockerfile-deploy \
		--platform linux/amd64 \
		-t ${DEPLOY_IMG} .

build-run:
	docker buildx build \
		--file Dockerfile-run \
		--platform linux/amd64 \
		-t ${RUN_IMG} .

build-all: build-deploy build-run

push-deploy:
	docker push ${DEPLOY_IMG}

push-run:
	docker push ${RUN_IMG}

push-all: push-deploy push-run

load-deploy:
	kind load docker-image ${DEPLOY_IMG} --name kind

load-run:
	kind load docker-image ${RUN_IMG} --name kind

load-all: load-deploy load-run

install:
	./k8s-manifest.sh
	kubectl apply -f distilbert-app.yaml

uninstall:
	kubectl delete -f distilbert-app.yaml

dev-server:
	flask --app nlp run --debug

