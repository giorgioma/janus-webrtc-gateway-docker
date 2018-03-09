TEMPLATE_NAME ?= janus-gateway-docker

image:
	@docker build -t giorgioma/$(TEMPLATE_NAME) .
