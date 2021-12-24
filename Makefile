init: jb
	cd prometheus-pushgateway && jb install

jb:
	@echo -e "\033[1m>> Ensuring jb (jsonnet-bundler) is installed\033[0m"
	go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb

gojsontoyaml:
	@echo -e "\033[1m>> Ensuring gojsontoyaml is installed\033[0m"
	go get github.com/brancz/gojsontoyaml

createFolders:
	rm -rf manifests
	mkdir manifests

generateJson: init
	jsonnet -J prometheus-pushgateway/vendor -J . example.jsonnet

generateYaml: init gojsontoyaml createFolders
	jsonnet -J prometheus-pushgateway/vendor  -m manifests example.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml; rm -f {}' -- {}
	cat manifests/*

deploy: generateYaml
	kubectl apply -f manifests/
