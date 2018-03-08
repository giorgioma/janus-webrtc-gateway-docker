TEMPLATE_NAME ?= janus-webrtc-gateway-docker

image:
	@docker build -t giorgioma/$(TEMPLATE_NAME) .
