# Manual Baseline Runbook

A step-by-step record of deploying the URL shortener by hand, before any
automation exists. I follow this with a stopwatch running and count every
click and command. The result is the "before" number that makes every later
metric honest.

---

## Before I start

- Start a stopwatch at Step 1. Stop it after the final teardown step.
- I count every numbered step as I go. If I make a mistake and have to
  redo a step, I count the redo as an extra step.
- Record any mistakes in the Mistakes section at the bottom.
- Region must be eu-central-1 (Frankfurt) for everything.

---

## Part 1: Deploy

### A. Create the DynamoDB table

1. Open the AWS Console. Navigate to **DynamoDB**.
2. Click **Create table**.
3. Table name: `urls-manual`
4. Partition key: `id`, type **String**.
5. Leave everything else as default (on-demand capacity mode is fine).
6. Click **Create table**. Wait for the status to show **Active**.

### B. Prepare the Lambda handler

7. The handler is already in the repository at `app/handler.py`. Copy that
   file to a convenient location on the local machine (the Desktop is fine),
   then zip it:

8. Zip the file. In the terminal:

```bash
cd ~/Desktop          # or wherever handler.py was saved
zip handler.zip handler.py
```

### C. Create the Lambda function

9. In the AWS Console, navigate to **Lambda**.
10. Click **Create function**.
11. Choose **Author from scratch**.
12. Function name: `url-shortener-manual`
13. Runtime: **Python 3.11**
14. Architecture: **arm64**
15. Click **Create function**.
16. On the function page, scroll to **Code source**. Click **Upload from**,
    choose **.zip file**, and upload `handler.zip`.
17. Click **Save**.
18. Scroll to **Runtime settings**, click **Edit**, confirm Handler is
    `handler.lambda_handler`. Save.

### D. Add the DynamoDB environment variable

19. Click the **Configuration** tab, then **Environment variables**, then **Edit**.
20. Click **Add environment variable**.
    - Key: `TABLE_NAME`
    - Value: `urls-manual`
21. Click **Save**.

### E. Grant the Lambda permission to read and write DynamoDB

22. Still on the **Configuration** tab, click **Permissions**.
23. Click the role name link (opens IAM in a new tab).
24. Click **Add permissions**, then **Attach policies**.
25. Search for `AmazonDynamoDBFullAccess`. Check the box next to it.
    (Note: in a real production setup I would write a least-privilege
    policy instead of using the managed full-access policy. For this
    manual baseline, the managed policy is acceptable because the
    environment is destroyed at the end.)
26. Click **Add permissions**.

### F. Create the API Gateway

27. In the AWS Console, navigate to **API Gateway**.
28. Click **Create API**.
29. Under **HTTP API**, click **Build**.
30. Click **Add integration**. Choose **Lambda**. Select the region
    `eu-central-1` and the function `url-shortener-manual`.
31. API name: `url-shortener-manual-api`
32. Click **Next**.
33. On the **Configure routes** screen, there will be a default route.
    Change it to:
    - Method: `POST`
    - Resource path: `/shorten`
    - Integration target: `url-shortener-manual`
34. Click **Add route** and add a second route:
    - Method: `GET`
    - Resource path: `/{id}`
    - Integration target: `url-shortener-manual`
35. Click **Next**, then **Next** again (default stage is fine).
36. Click **Create**. Copy the **Invoke URL** shown on the confirmation
    screen. It looks like:
    `https://xxxxxxxxxx.execute-api.eu-central-1.amazonaws.com`

### G. Test the deployment

37. Open a terminal. Run this command, replacing YOUR_API_URL with the invoke URL copied in Step 36:

```bash
curl -X POST https://YOUR_API_URL/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```

Expected response: `{"short_id": "xxxxxx"}`

38. Copy the `short_id` value. Run:

```bash
curl -v https://YOUR_API_URL/SHORT_ID
```

Expected: a `301` redirect with `Location: https://example.com` in the
headers.

**Stop the stopwatch here to record deployment time separately.**
Record the time and step count in the Results section below.

---

## Part 2: Teardown

Start the stopwatch again, or keep it running to time end to end.

39. In the AWS Console, navigate to **API Gateway**.
40. Select `url-shortener-manual-api`. Click **Delete**. Confirm.
41. Navigate to **Lambda**.
42. Select `url-shortener-manual`. Click **Actions**, then **Delete**.
    Confirm.
43. Navigate to **DynamoDB**.
44. Select `urls-manual`. Click **Delete**. Type the table name to confirm.
45. Navigate to **IAM**.
46. Click **Roles**. Search for the role that Lambda created (it will start
    with `url-shortener-manual-role-`). Select it and click **Delete**.
    Confirm.
47. Navigate to **CloudWatch**, then **Log groups**.
48. Find `/aws/lambda/url-shortener-manual`. Select it and click **Delete**.
    Confirm.

**Stop the stopwatch. Record the teardown time and step count below.**

---

## Results

I fill these in after the run. These numbers go into the final
README and the CV line.

| Metric | Value |
|--------|-------|
| Deployment steps (Steps 1 to 38) | [MEASURED: count after run] |
| Deployment time | [MEASURED: fill in after run] |
| Teardown steps (Steps 39 to 48) | [MEASURED: count after run] |
| Teardown time | [MEASURED: fill in after run] |
| Total steps | [MEASURED: fill in after run] |
| Total time | [MEASURED: fill in after run] |
| Mistakes made | [MEASURED: fill in after run] |

---

## Mistakes

I record any step where I made an error and had to redo it. Recording
real errors honestly is more credible than a runbook that claims
everything went perfectly the first time.

| Step # | What went wrong | How I fixed it |
|--------|----------------|----------------|
| | | |

---

## What this baseline proves

Once the automation exists, I will compare:
- Manual steps and time versus `terraform apply` time
- Manual error rate versus zero (Terraform either works or it fails cleanly)

That comparison is the first honest metric in this project.
