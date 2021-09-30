FROM alpine as tfserving

RUN apk add --no-cache git
RUN apk add --no-cache bash
RUN mkdir -p /tmp/tfserving
WORKDIR /tmp/tfserving
RUN git clone https://github.com/tensorflow/serving

FROM tensorflow/serving:latest-gpu
RUN mkdir -p /models
COPY --from=tfserving /tmp/tfserving/serving/tensorflow_serving/servables/tensorflow/testdata/saved_model_half_plus_two_gpu/ /models/model
RUN ls -lR /models

