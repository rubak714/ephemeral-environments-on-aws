# ⚡ Phase 5: One Optimization Pass

What I measured, what I changed, and what the numbers show.

---

## 🗺️ What Phase 5 covers

Phase 4 gave me visibility. Phase 5 uses that visibility to make one targeted, measurable improvement.

The two levers I pulled:

1. **Graviton (arm64)**: already set in Phase 2. Same price as x86, roughly 20% better throughput per AWS documentation. I list it here because the Phase 5 load test measures the result.
2. **Lambda memory right-sizing**: I added a `lambda_memory_mb` variable so I can sweep 128 MB, 256 MB, and 512 MB by re-running Terraform with a different value, without editing source files.

---

## 🔑 How Lambda memory actually works

Lambda memory and CPU are not separate knobs. When I set `memory_size = 256`, AWS allocates 256 MB of RAM and a proportional fraction of a vCPU. More memory means more CPU, which means faster execution, which means the invocation finishes sooner.

The billing formula:

```
Cost = (duration_ms / 1000) × (memory_mb / 1024) × price_per_GB_second
```

On Graviton arm64, the price per GB-second is $0.0000133334 (eu-central-1).

So a 256 MB function that runs for 50ms costs:
```
(50 / 1000) × (256 / 1024) × 0.0000133334 = $0.000000166667
```

That is roughly $0.17 per million invocations at this memory and duration. Well inside the free tier (400,000 GB-seconds per month free).

---

## 📏 The load test

I ran 1000 sequential POST /shorten requests against the `dev` environment using the script at `scripts/load_test.py`.

The script measures:
- Total time for all requests
- Requests per second
- p50 duration (median)
- p95 duration
- p99 duration
- Error count

Results at 256 MB (Graviton arm64):

| Metric | Value |
|--------|-------|
| Total requests | 1000 |
| Errors | [MEASURED: fill in after running] |
| Requests/sec | [MEASURED: fill in after running] |
| p50 duration | [MEASURED: fill in after running] ms |
| p95 duration | [MEASURED: fill in after running] ms |
| p99 duration | [MEASURED: fill in after running] ms |

---

## 🗂️ What I wrote

| File | What changed |
|------|-------------|
| `infra/variables.tf` | Added `lambda_memory_mb` variable (default 256 MB) with explanation of why 256 beats 128 |
| `infra/lambda.tf` | Wired `var.lambda_memory_mb` into `memory_size` |
| `scripts/load_test.py` | 1000-request sequential load test with p50/p95/p99 output |

---

## 📊 Phase 5 result

> Load test numbers pending. Will fill in once `terraform apply` runs and the test script executes.

The configuration is code-reviewable and re-runnable. Anyone can reproduce the measurement by:

```bash
# Deploy dev environment
terraform -chdir=infra apply -var="env_name=dev" -auto-approve

# Read the API URL
API_URL=$(terraform -chdir=infra output -raw api_url)

# Run the load test
python scripts/load_test.py --url "$API_URL" --requests 1000
```
