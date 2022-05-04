ARG source_image
FROM ${source_image}

ARG default_port
ENV PORT=${default_port}
EXPOSE ${default_port}
