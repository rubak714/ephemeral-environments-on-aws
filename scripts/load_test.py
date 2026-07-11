"""
Load test for the URL shortener API.

Sends N sequential POST /shorten requests and reports p50, p95, p99 latency.
Sequential (not concurrent) so the results reflect single-request latency
rather than parallelism effects. This keeps the measurement comparable across
memory tiers: I am measuring how fast each individual request is, not how
many the API can handle in parallel.

Usage:
    python scripts/load_test.py --url https://<api-id>.execute-api.eu-central-1.amazonaws.com
    python scripts/load_test.py --url https://<api-id>.execute-api.eu-central-1.amazonaws.com --requests 500
"""

import argparse
import json
import statistics
import sys
import time
import urllib.request
import urllib.error


def run(base_url: str, total: int) -> None:
    url = base_url.rstrip("/") + "/shorten"
    payload = json.dumps({"url": "https://example.com/test-target"}).encode()
    headers = {"Content-Type": "application/json"}

    durations: list[float] = []
    errors = 0

    print(f"Sending {total} requests to {url}")

    for i in range(1, total + 1):
        req = urllib.request.Request(url, data=payload, headers=headers, method="POST")
        start = time.perf_counter()
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                resp.read()
        except (urllib.error.URLError, urllib.error.HTTPError, OSError):
            errors += 1
        duration_ms = (time.perf_counter() - start) * 1000
        durations.append(duration_ms)

        if i % 100 == 0:
            print(f"  {i}/{total} complete")

    durations.sort()
    n = len(durations)

    def percentile(p: float) -> float:
        idx = int(n * p / 100)
        return round(durations[min(idx, n - 1)], 1)

    total_time_s = sum(durations) / 1000
    rps = round(n / total_time_s, 1)

    print()
    print("=== Results ===")
    print(f"Total requests : {total}")
    print(f"Errors         : {errors}")
    print(f"Elapsed        : {round(total_time_s, 1)}s")
    print(f"Req/sec        : {rps}")
    print(f"p50 duration   : {percentile(50)} ms")
    print(f"p95 duration   : {percentile(95)} ms")
    print(f"p99 duration   : {percentile(99)} ms")
    print(f"Max duration   : {round(durations[-1], 1)} ms")


def main() -> None:
    parser = argparse.ArgumentParser(description="URL shortener load test")
    parser.add_argument("--url", required=True, help="Base API URL (no trailing slash needed)")
    parser.add_argument("--requests", type=int, default=1000, help="Number of requests to send (default: 1000)")
    args = parser.parse_args()

    if args.requests < 1:
        print("--requests must be at least 1", file=sys.stderr)
        sys.exit(1)

    run(args.url, args.requests)


if __name__ == "__main__":
    main()
