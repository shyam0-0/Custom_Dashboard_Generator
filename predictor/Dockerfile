FROM python:3.9-slim

# Install python packages 
RUN pip install --upgrade pip && \
    pip install pandas prophet prometheus-api-client prometheus_client schedule

COPY predictor.py .

CMD ["python", "predictor.py"]
