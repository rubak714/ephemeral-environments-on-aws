# 🧠 Phase 1: Technical Concepts

Core concepts behind the three AWS services used in Phase 1.

---

## 🏗️ How the three services connect

Build order matters. Each service depends on the one before it:

- 🗄️ **DynamoDB first**: no dependencies, must exist before Lambda
- ⚡ **Lambda second**: needs the DynamoDB table name at startup
- 🌐 **API Gateway last**: needs a Lambda function to forward requests to

```
curl / browser
      ↓
🌐 API Gateway      receives the HTTP request
      ↓
⚡ Lambda           runs the Python logic
      ↓
🗄️ DynamoDB         stores or retrieves the URL mapping
      ↓
curl / browser      gets the short ID or the 301 redirect
```

---

## 🌐 API Gateway

- A **managed AWS service**, not code
- Sits on the public internet and receives HTTP requests
- Forwards every request to Lambda, returns the response to the caller
- Generates a unique **Invoke URL** as the public address

```
https://uwwpqr4x6i.execute-api.eu-central-1.amazonaws.com
```

> Deleting API Gateway immediately kills that URL. Nothing else changes.

---

## ⚡ Lambda (handler.py)

Lambda is where all the logic runs. Two routes, one function:

**POST /shorten**
- Reads the long URL from the request body
- Generates a random 6-character ID (`OddhuL`)
- Saves `{id: OddhuL, url: https://example.com}` to DynamoDB
- Returns `{"short_id": "OddhuL"}` to the caller

**GET /{id}**
- Looks up the ID in DynamoDB
- Returns `301 Moved Permanently` with the original URL in the `Location` header

> DynamoDB never talks to the caller. Lambda handles everything end to end.

---

## 🗄️ DynamoDB

- A managed **key-value database** with no server to run or maintain
- Stores one thing: the mapping between short ID and original URL
- Completely passive: Lambda writes to it, Lambda reads from it

| id | url |
|----|-----|
| OddhuL | https://example.com |

---

## 📬 HTTP Methods

| Method | Meaning | Route |
|--------|---------|-------|
| `POST` | Send data, create something | `/shorten` |
| `GET` | Retrieve something, send no data | `/{id}` |

**Why `Content-Type: application/json`?**
- Declares the format of the request body
- Without it, the server cannot parse the JSON correctly

**Why `example.com`?**
- A safe, permanent testing domain, always available, never redirects unexpectedly
- In production, any long URL goes here

---

## 🔑 How the short ID is generated

```python
short_id = "".join(random.choices(string.ascii_letters + string.digits, k=6))
```

- 6 characters drawn from letters and digits
- 62⁶ = over **56 billion** possible combinations
- Generated fresh on every POST request, never sequential

---

## 💡 Honest limitation: the URL is not actually shorter

The full short URL produced by this project:
```
https://uwwpqr4x6i.execute-api.eu-central-1.amazonaws.com/OddhuL
```

This is longer than most original URLs. A real shortener like bit.ly fixes this
by owning a short custom domain pointed at their API via DNS. The fix here would be:

1. Register a short domain (e.g. `rk.sh`)
2. Point it at the Invoke URL using **Route 53** (AWS DNS)
3. Configure a custom domain in API Gateway

Out of scope for this project. The app is a demo vehicle for the automation pipeline,
not a production product.

---

## 📊 Phase 1 measured result

| Metric | Value |
|--------|-------|
| Total manual steps | 48 |
| Total time by hand | 39 minutes 1 second |
| Errors requiring a redo | 0 |

This is the **before** number. Phase 2 replaces all 48 steps with one Terraform command.
