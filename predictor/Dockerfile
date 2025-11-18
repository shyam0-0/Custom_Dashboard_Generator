FROM python:3.9-slim

# Install only python packages (no apt-get)
RUN pip install --upgrade pip && \
    pip install pandas prophet prometheus-api-client prometheus_client schedule

# Copy predictor code
COPY predictor.py .

CMD ["python", "predictor.py"]
