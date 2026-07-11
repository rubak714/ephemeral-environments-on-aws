# 📊 Phase 4: Observability

What I added, why each piece matters, and what I can now see that I could not see before.

---

## 🗺️ What Phase 4 adds

Phase 3 gave me a fully automated deploy and destroy pipeline. But if something breaks inside a live environment, I had no way to see it. Phase 4 fixes that.

Three additions:

- **Structured JSON logs** in `handler.py` so CloudWatch Logs Insights can query specific fields
- **X-Ray active tracing** so I can see exactly how long each DynamoDB call takes per request
- **Two CloudWatch alarms** and a dashboard so I know when something is wrong without tailing logs manually

---

## 🔑 Key concepts

### Why structured JSON logs instead of plain text

Plain text log:
```
Request received: POST /shorten took 45ms
```

Structured JSON log (what I now emit):
```json
{"level": "INFO", "message": "short URL created", "short_id": "GQ9EEv", "durationMs": 45, "statusCode": 200}
```

With JSON, I can run CloudWatch Logs Insights queries like:

```sql
filter statusCode = 404
| stats count() by bin(5m)
```

That query tells me how many "not found" responses happened every 5 minutes, which is impossible to compute from free-form text without parsing.

---

### What X-Ray shows

X-Ray traces every request end to end and breaks it into segments.

For a `GET /{id}` request the trace shows:

```
Total: 52ms
  └─ handler.lambda_handler: 52ms
       └─ DynamoDB GetItem: 38ms
```

This tells me the DynamoDB call is taking 38 of the 52 milliseconds. Without X-Ray I only see the total. With it I know exactly where to look if latency spikes.

---

### The two alarms

| Alarm | Metric | Threshold | What it means |
|-------|--------|-----------|---------------|
| `url-shortener-dev-errors` | `AWS/Lambda Errors` sum | >= 1 in 60 sec | Lambda threw an unhandled exception |
| `url-shortener-dev-duration-p99` | `AWS/Lambda Duration` p99 | >= 2000ms in 60 sec | The slowest 1% of requests exceeded 2 seconds |

**Why p99 and not average?**

Average duration hides outliers. A function that responds in 50ms 99 times but 5000ms once shows an average of ~99ms. That looks fine. The p99 shows 5000ms, which reveals the problem.

---

### The dashboard

Four panels on one screen:

- Lambda errors (sum per minute)
- Lambda duration p99 (ms per minute)
- Lambda invocations (count per minute)
- DynamoDB consumed write capacity

This is the first place I look when a PR environment behaves unexpectedly.

**Cost note:** The dashboard costs $3/month. Everything else in Phase 4 is inside the AWS free tier.

---

## 🗂️ What I wrote

| File | What changed |
|------|-------------|
| `app/handler.py` | Added structured JSON `log()` helper, per-request duration timing, status code in every log line |
| `infra/iam.tf` | Added 4 X-Ray permissions: `PutTraceSegments`, `PutTelemetryRecords`, `GetSamplingRules`, `GetSamplingTargets` |
| `infra/lambda.tf` | Added `tracing_config { mode = "Active" }` |
| `infra/cloudwatch.tf` | New file: log group (14-day retention), 2 alarms, 1 dashboard |

---

## 📊 Phase 4 result

> Apply pending. Numbers will be filled in after `terraform apply` runs and a test load is sent.

| Metric | Value |
|--------|-------|
| Log retention | 14 days |
| Alarms | 2 (errors, p99 duration) |
| Dashboard panels | 4 |
| X-Ray traces per request | 1 (active mode) |
| Idle cost added | $3/month (dashboard only) |
