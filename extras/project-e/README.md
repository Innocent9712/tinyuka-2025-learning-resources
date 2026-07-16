# Exercise: An Event-Driven Workflow in AWS

## What you're building

A small "upload → process → notify" pipeline, provisioned entirely with Terraform:

1. A CSV file is uploaded to an **S3 bucket**.
2. The upload triggers a **Lambda function** (S3 event notification).
3. The Lambda parses the CSV, validates each row, and writes valid rows to a **DynamoDB** table.
4. The Lambda publishes a summary ("N records processed, M succeeded, K failed") to an **SNS topic**, which emails you the result.

Nothing here is architecturally complex — the point is to see, hands-on, how a handful of managed AWS services react to each other's events instead of being called directly, and to provision that reactive wiring the same way you provisioned everything else this term: as code.

---

## Goal

Upload a CSV to your bucket and, within a minute or so, receive an email summarizing how many rows were processed successfully — with the valid rows sitting in DynamoDB and no manual step in between.

---

## Requirements

### 1. S3 bucket

- A bucket for uploads, provisioned in Terraform.
- An **event notification** configured to invoke your Lambda on `s3:ObjectCreated:*`, filtered to keys ending in `.csv` — don't trigger on every object type.

### 2. Lambda function

- Language is your choice (Python and Node are both fine — pick whichever you're faster in).
- On invocation: read the uploaded object from S3, parse it as CSV, and validate each row against a simple schema you define (e.g. require specific columns and non-empty values).
- Write all **valid** rows to DynamoDB using a batch write, not one `PutItem` call per row.
- Collect a reason for every **invalid** row (which column failed and why) rather than just a pass/fail count.

### 3. DynamoDB table

- One table, provisioned in Terraform, with a sensible partition key for your data (e.g. an order ID or row UUID).

### 4. SNS topic + email subscription

- A topic with an email subscription pointing at your own inbox (you'll need to confirm the subscription once, manually, the first time).
- After each Lambda run, publish a message summarizing: total rows, succeeded count, failed count, and — if any rows failed — the specific reasons collected above.

### 5. IAM — least privilege

- The Lambda's execution role should be scoped to exactly what it needs: read on the specific upload bucket, write on the specific DynamoDB table, publish on the specific SNS topic, plus CloudWatch Logs. Avoid `Resource: "*"` where a specific ARN will do.

### 6. Terraform project structure

- Follow the same file-separation convention as your earlier Terraform exercise: `versions.tf`, `providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`. No credentials or account-specific values hardcoded into resource blocks.

### 7. Outputs

- Expose at minimum: the bucket name, the Lambda function name, the DynamoDB table name, and the SNS topic ARN.

### 8. Prove it end-to-end

- Upload a CSV where every row is valid — confirm the DynamoDB items and the email summary match.
- Upload a second CSV with a few deliberately broken rows (missing column, empty value) — confirm the failed rows are excluded from DynamoDB and correctly explained in the notification email.

---

## Suggested workflow

1. Provision the S3 bucket, DynamoDB table, and SNS topic first, and confirm the subscription email arrives and gets confirmed — get the "dumb infrastructure" working before wiring anything reactive.
2. Write and test the Lambda's parsing/validation logic **locally**, against a sample CSV file on disk, before it ever touches AWS — it's much faster to debug a parsing bug in a local script than in CloudWatch Logs.
3. Package and deploy the Lambda via Terraform, granting it IAM access to the other resources.
4. Wire up the S3 event notification last, once you're confident the Lambda works when invoked manually (e.g. via a test event in the Lambda console) with a sample S3 key.
5. Run the two end-to-end tests (all-valid, some-invalid) and capture the CloudWatch log output and the email as your proof.

## Stretch goals (optional)

- Add a dead-letter queue (SQS) to catch Lambda invocations that fail outright (not row-level validation failures — actual function errors).
- Move processed files to an `archive/` prefix in the same bucket after handling them, so you can tell processed uploads apart from pending ones.

## Deliverable

A GitHub repo with the Terraform project and Lambda source, a README explaining the flow and how to test it, and screenshots or log excerpts proving a full run — S3 upload, CloudWatch log, the resulting DynamoDB item(s), and the summary email.

## Submitting your work for review

   Use Pull Requests (PRs) to present your changes incrementally. Follow this branching strategy:

   ```
   feature/name-of-the-feature -> review -> main
   ```

   - Create a **feature branch** for each piece of work (e.g. `feature/s3-lambda-trigger`, `feature/sns-notifications`).
   - When a feature is complete, merge it into a **`review`** branch.
   - Once you're ready for feedback, open a PR from `review` → `main` and request a review.
   - Reviews will be provided as comments on that PR. You can address feedback on new fix/feature branches, merge them into the open PR, and request another round of review — or merge directly to `main` if you prefer.

   When submitting, provide links to your PRs so the progression of changes is easy to follow.
