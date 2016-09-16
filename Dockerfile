FROM daocloud.io/library/ubuntu:16.04
MAINTAINER Minho <longfei@163.com>

RUN apt-get update && \
	apt-get install -y wget git openssl make

ENV NGROK_DOMAIN "ngrok.xuehuwang.com"
ENV HTTP_ADDR ":80"

WORKDIR /usr/local/src/

#COPY go1.7.linux-amd64.tar.gz /usr/local/src/
#下载golang
RUN wget -q  https://storage.googleapis.com/golang/go1.7.1.linux-amd64.tar.gz && \
	tar zxvf go1.7.linux-amd64.tar.gz -C /usr/local

RUN git clone https://github.com/inconshreveable/ngrok.git && \
	mkdir -p /usr/local/ngrok/ && \
	export GOPATH=/usr/local/src/ngrok/ && \
	export NGROK_DOMAIN="ngrok.xuehuwang.com" && \
	export PATH=$PATH:/usr/local/go/bin && \
	cd ngrok && \
	make release-server && \
	cp bin/ngrokd /usr/local/ngrok/
 
RUN openssl genrsa -out rootCA.key 2048 && \
	openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem && \
	openssl genrsa -out device.key 2048 && \
	openssl req -new -key device.key -subj "/CN=$NGROK_DOMAIN" -out device.csr && \
	openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000 && \
	mkdir -p /usr/local/ngrok/assets/client/tls && \
	mkdir -p /usr/local/ngrok/assets/server/tls && \
	cp rootCA.pem /usr/local/ngrok/assets/client/tls/ngrokroot.crt && \
	cp device.crt /usr/local/ngrok/assets/server/tls/snakeoil.crt  && \
	cp device.key /usr/local/ngrok/assets/server/tls/snakeoil.key

COPY run.sh /usr/local/ngrok/

RUN chmod -R 777 /usr/local/ngrok/
CMD ["/usr/local/ngrok/run.sh"]
