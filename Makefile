
all: build

build:
	docker build -t perftest .
	@echo "Try it with:"
	@echo "docker run -it  --entrypoint="/bin/bash" perftest" 

run: build
	$(eval MY_C=$(shell docker run -d perftest|cut -c 1-12))
	$(eval MY_IP=$(shell docker inspect -f "{{ .NetworkSettings.IPAddress }}" $(MY_C)))
	@echo "started docker container $(MY_C) $(MY_IP)"
	sleep 1
	curl http://$(MY_IP):8080/

clean:
	$(eval MY_C=$(shell docker ps |grep perftest| awk '{print $$1}'))
	docker rm -f $(MY_C)

test: run clean
