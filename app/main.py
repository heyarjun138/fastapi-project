from fastapi import FastAPI, Request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time, random, logging, json, os
from starlette.responses import PlainTextResponse

# ----- logging to stdout (Promtail/Loki will read this) -----
class JsonFormatter(logging.Formatter):
    def format(self, record):
        base = {
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "time": int(time.time()),
        }
        # include extra dict if present
        if hasattr(record, "extra") and isinstance(record.extra, dict):
            base.update(record.extra)
        return json.dumps(base)

handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
log = logging.getLogger("app")
log.setLevel(os.getenv("LOG_LEVEL", "INFO"))
log.addHandler(handler)

# ----- metrics -----
REQUESTS = Counter(
    "demo_requests_total",
    "Total number of processed requests",
    ["endpoint", "method", "status"]
)
LATENCY = Histogram(
    "demo_request_duration_seconds",
    "Request latency in seconds",
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5)
)

app = FastAPI(title="demo-metrics-app")

@app.get("/healthz")
def healthz():
    log.info("healthz", extra={"extra": {"endpoint": "/healthz"}})
    return {"status": "ok"}

@app.get("/work")
def do_work(ms: int = 100):
    start = time.time()
    # simulate work
    time.sleep(max(ms, 0) / 1000.0)
    duration = time.time() - start
    LATENCY.observe(duration)
    REQUESTS.labels(endpoint="/work", method="GET", status="200").inc()
    log.info("work_done", extra={"extra": {"endpoint": "/work", "latency_s": round(duration, 4), "ms": ms}})
    return {"ok": True, "slept_ms": ms, "latency_s": duration}

@app.get("/random")
def random_value():
    val = random.random()
    REQUESTS.labels(endpoint="/random", method="GET", status="200").inc()
    log.info("random_value", extra={"extra": {"endpoint": "/random", "value": val}})
    return {"value": val}

@app.get("/metrics")
def metrics():
    return PlainTextResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)
