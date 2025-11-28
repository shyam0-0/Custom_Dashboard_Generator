#  predictor: disk + cpu + memory (Prophet)
import os, time, logging, schedule
from datetime import datetime, timedelta, timezone
import pandas as pd
from prometheus_api_client import PrometheusConnect
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
from prophet import Prophet

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://prometheus:9090")
PUSHGATEWAY_URL = os.getenv("PUSHGATEWAY_URL", "http://pushgateway:9091")
JOB_NAME_PREFIX = os.getenv("PREDICTOR_JOB", "predictor")

time.sleep(10)

# connect
max_retries = 5
prom = None
for attempt in range(max_retries):
    try:
        prom = PrometheusConnect(url=PROMETHEUS_URL, disable_ssl=True)
        prom.custom_query("up")
        logger.info("Connected to Prometheus")
        break
    except Exception as e:
        logger.warning(f"Connection attempt {attempt+1}/{max_retries} failed: {e}")
        time.sleep(5)

# registry & gauges
registry = CollectorRegistry()
g_disk = Gauge('disk_percentage_predicted_in_15_min', 'Predicted disk usage % in next 15 minutes.', registry=registry)
g_cpu = Gauge('cpu_percentage_predicted_in_15_min', 'Predicted cpu usage % in next 15 minutes.', registry=registry)
g_mem = Gauge('memory_percentage_predicted_in_15_min', 'Predicted memory usage % in next 15 minutes.', registry=registry)

# PromQL queries
QUERIES = {
    "disk": '100 * (1 - (windows_logical_disk_free_bytes{volume="C:"} / windows_logical_disk_size_bytes{volume="C:"}))',
    "cpu":  '100 * (1 - avg(rate(windows_cpu_time_total{mode="idle"}[1m])))',  # overall cpu %
    "mem":  '100 * (1 - (windows_memory_available_bytes / windows_memory_physical_total_bytes))'
}

def query_and_prepare(prom, promql, start_time, end_time, step="60s"):
    res = prom.custom_query_range(query=promql, start_time=start_time, end_time=end_time, step=step)
    if not res or len(res) == 0 or len(res[0].get('values', [])) < 10:
        return None
    data = res[0]['values']
    df = pd.DataFrame(data, columns=['ds', 'y'])
    df['ds'] = pd.to_datetime(df['ds'], unit='s')
    df['y'] = pd.to_numeric(df['y'], errors='coerce')
    df = df.set_index('ds').resample('60s').mean().interpolate(limit_direction='both').reset_index()
    df = df.dropna()
    if len(df) < 10:
        return None
    return df

def predict_one(df):
    model = Prophet(daily_seasonality=False, weekly_seasonality=False, yearly_seasonality=False)
    model.fit(df)
    future = model.make_future_dataframe(periods=15, freq='min')
    forecast = model.predict(future)
    return float(forecast.iloc[-1]['yhat'])

def run_predictions():
    logger.info("Running multi-metric prediction cycle")
    end_time = datetime.now(timezone.utc)
    start_time = end_time - timedelta(hours=1)

    results = {}
    for name, q in QUERIES.items():
        try:
            df = query_and_prepare(prom, q, start_time, end_time)
            if df is None:
                logger.warning(f"{name}: not enough data — pushing 0")
                results[name] = 0.0
                continue
            pred = predict_one(df)
            pred = max(0.0, min(100.0, pred))
            results[name] = pred
            logger.info(f"{name} predicted: {pred:.2f}%")
        except Exception as e:
            logger.exception(f"Error predicting {name}: {e}")
            results[name] = 0.0

    # set and push metrics
    g_disk.set(results.get('disk', 0.0))
    g_cpu.set(results.get('cpu', 0.0))
    g_mem.set(results.get('mem', 0.0))
    try:
        push_to_gateway(PUSHGATEWAY_URL, job=JOB_NAME_PREFIX, registry=registry)
        logger.info("Pushed predictions to Pushgateway")
    except Exception as e:
        logger.exception(f"Failed to push to Pushgateway: {e}")


schedule.every(2).minutes.do(run_predictions)
run_predictions()
while True:
    schedule.run_pending()
    time.sleep(5)
