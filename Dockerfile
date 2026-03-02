FROM openfang:base

# Non-root user (UID 1000 matches typical host user for bind mount compatibility)
RUN groupadd -r -g 1000 openfang && \
    useradd -r -u 1000 -g openfang -s /bin/false openfang && \
    mkdir -p /data && \
    chown openfang:openfang /data

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER openfang
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["start"]
