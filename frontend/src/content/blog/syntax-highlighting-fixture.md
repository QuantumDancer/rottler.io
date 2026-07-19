---
title: "Syntax highlighting fixture"
description: "One realistic snippet per must-work language, used to judge SSG candidates."
publishDate: 2026-07-19
draft: true
tags: ["meta"]
---

This post exists to stress-test syntax highlighting. Every language below
must render with correct, complete token coverage. It also exercises
per-line highlighting, file-path labels, and the source-vs-terminal
distinction where the candidate supports them.

## YAML — Kubernetes Deployment

```yaml {6-8} ins={14} del={13} title="k8s/deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: view-counter
  labels:
    app.kubernetes.io/name: view-counter
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: view-counter
  template:
    spec:
      containers:
        - name: api
          image: ghcr.io/quantumdancer/view-counter:1.4.2
          ports:
            - containerPort: 8080
          env:
            - name: TABLE_NAME
              valueFrom:
                configMapKeyRef:
                  name: counter-config
                  key: tableName
          resources:
            limits:
              memory: "128Mi"
            requests:
              cpu: 50m
          livenessProbe:
            httpGet: { path: /healthz, port: 8080 }
            initialDelaySeconds: 5
```

## HCL / Terraform — CloudFront + cross-account DNS

```hcl title="infra/cloudfront.tf"
data "aws_iam_policy_document" "dns_updates" {
  statement {
    sid       = "AllowRecordChanges"
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = [aws_route53_zone.apex.arn]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsRecordTypes"
      values   = ["A", "AAAA", "CNAME"]
    }
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = [var.domain, "www.${var.domain}"]

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimized.id
  }

  # us-east-1 is mandatory for CloudFront certificates.
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.site.arn
    ssl_support_method  = "sni-only"
  }
}
```

## Bash — deploy helper

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly BUCKET="${1:?usage: deploy.sh <bucket> [distribution-id]}"
DIST_ID="${2:-}"

sync_site() {
  local dry_run=()
  [[ "${DRY_RUN:-0}" == "1" ]] && dry_run=(--dryrun)
  aws s3 sync dist/ "s3://${BUCKET}" --delete "${dry_run[@]}" \
    | tee -a deploy.log
}

if ! command -v aws >/dev/null 2>&1; then
  echo "aws cli missing" >&2
  exit 1
fi

sync_site
[[ -n "$DIST_ID" ]] && aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" --paths '/*'
echo "deployed $(date -u +%FT%TZ)"
```

## Dockerfile — multi-stage Go build

```dockerfile title="build/Dockerfile"
# syntax=docker/dockerfile:1
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /out/server ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
HEALTHCHECK --interval=30s CMD ["/server", "healthcheck"]
```

## Python — async DynamoDB counter

```python {13-16} title="app/counter.py"
import asyncio
from dataclasses import dataclass, field
from typing import Self

import aioboto3

@dataclass(slots=True)
class Counter:
    table_name: str
    _session: aioboto3.Session = field(default_factory=aioboto3.Session)

    async def increment(self, path: str, by: int = 1) -> int:
        """Atomically bump the view count for *path* and return the new value."""
        async with self._session.resource("dynamodb") as db:
            table = await db.Table(self.table_name)
            result = await table.update_item(
                Key={"path": path},
                UpdateExpression="SET viewCount = if_not_exists(viewCount, :z) + :n",
                ExpressionAttributeValues={":z": 0, ":n": by},
                ReturnValues="UPDATED_NEW",
            )
        return int(result["Attributes"]["viewCount"])

    @classmethod
    def from_env(cls) -> Self:
        import os
        return cls(table_name=os.environ["TABLE_NAME"])

if __name__ == "__main__":
    count = asyncio.run(Counter.from_env().increment("/"))
    print(f"views: {count:,}")
```

## Go — HTTP handler with generics

```go title="cmd/server/count.go"
package main

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"time"
)

type Store[T any] interface {
	Get(ctx context.Context, key string) (T, error)
}

type countResponse struct {
	ViewCount int64 `json:"viewCount"`
}

func handleCount(store Store[int64]) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()

		count, err := store.Get(ctx, r.URL.Path)
		switch {
		case errors.Is(err, context.DeadlineExceeded):
			http.Error(w, "store timeout", http.StatusGatewayTimeout)
			return
		case err != nil:
			slog.Error("store failure", "path", r.URL.Path, "err", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(countResponse{ViewCount: count})
	}
}
```

## Rust — Lambda handler

```rust
use std::sync::Arc;

use aws_sdk_dynamodb::{types::AttributeValue, Client};
use lambda_http::{run, service_fn, Body, Error, Request, Response};
use serde::Serialize;

#[derive(Serialize)]
struct CountResponse {
    view_count: u64,
}

async fn increment(client: &Client, table: &str, path: &str) -> Result<u64, Error> {
    let result = client
        .update_item()
        .table_name(table)
        .key("path", AttributeValue::S(path.to_owned()))
        .update_expression("SET viewCount = if_not_exists(viewCount, :z) + :n")
        .expression_attribute_values(":z", AttributeValue::N("0".into()))
        .expression_attribute_values(":n", AttributeValue::N("1".into()))
        .send()
        .await?;

    let count = result
        .attributes()
        .and_then(|attrs| attrs.get("viewCount"))
        .and_then(|v| v.as_n().ok())
        .map(|n| n.parse::<u64>())
        .transpose()?
        .unwrap_or_default();
    Ok(count)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    let config = aws_config::load_from_env().await;
    let client = Arc::new(Client::new(&config));
    run(service_fn(move |req: Request| {
        let client = Arc::clone(&client);
        async move {
            let count = increment(&client, "view_counter", req.uri().path()).await?;
            let body = serde_json::to_string(&CountResponse { view_count: count })?;
            Ok::<_, Error>(Response::builder().status(200).body(Body::from(body))?)
        }
    }))
    .await
}
```

## JSON — CloudFront function config

```json
{
  "name": "append-index-html",
  "runtime": "cloudfront-js-2.0",
  "comment": "Rewrite directory URIs to index.html",
  "keyValueStoreAssociations": [],
  "stage": "LIVE",
  "config": {
    "enabled": true,
    "priority": 1.5,
    "paths": ["/*"],
    "excludes": ["/api/*", "/assets/*"]
  }
}
```

## TOML — Rust workspace manifest

```toml
[workspace]
members = ["counter", "shared"]
resolver = "2"

[workspace.package]
edition = "2024"
license = "MIT"

[workspace.dependencies]
tokio = { version = "1.45", features = ["macros", "rt-multi-thread"] }
serde = { version = "1", features = ["derive"] }

[profile.release]
lto = "thin"
strip = true
opt-level = 3
```

## INI — AWS CLI profiles

```ini
; ~/.aws/config
[default]
region = eu-central-1
output = json

[profile shared-services]
role_arn = arn:aws:iam::111122223333:role/dns-updates
source_profile = default
duration_seconds = 3600

[profile prod]
sso_session = rottler
sso_account_id = 444455556666
sso_role_name = AdministratorAccess
```

## PowerShell — Azure resource cleanup

```powershell
#Requires -Modules Az.Resources
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroup,

    [int]$OlderThanDays = 30
)

$cutoff = (Get-Date).AddDays(-$OlderThanDays)

Get-AzResource -ResourceGroupName $ResourceGroup |
    Where-Object { $_.Tags?['ephemeral'] -eq 'true' } |
    ForEach-Object {
        $created = [datetime]$_.Tags['createdAt']
        if ($created -lt $cutoff -and $PSCmdlet.ShouldProcess($_.Name, 'Remove')) {
            Write-Warning "Removing $($_.ResourceType)/$($_.Name) (created $created)"
            Remove-AzResource -ResourceId $_.ResourceId -Force
        }
    }
```

## SQL — Athena over CloudFront logs

```sql
WITH daily_views AS (
    SELECT
        date_trunc('day', from_iso8601_timestamp(concat(date, 'T', time))) AS day,
        cs_uri_stem,
        COUNT(*) AS requests,
        SUM(CASE WHEN sc_status BETWEEN 200 AND 299 THEN 1 ELSE 0 END) AS ok
    FROM cloudfront_logs
    WHERE year = 2026 AND month = 7
    GROUP BY 1, 2
)
SELECT day, cs_uri_stem, requests,
       ROUND(100.0 * ok / requests, 1) AS success_pct
FROM daily_views
WHERE cs_uri_stem NOT LIKE '/assets/%'
ORDER BY day DESC, requests DESC
LIMIT 20;
```

## Diff — cache policy fix

```diff
 resource "aws_cloudfront_cache_policy" "api" {
   name        = "api-cache-policy"
-  default_ttl = 86400
-  max_ttl     = 86400
+  default_ttl = 0
+  max_ttl     = 0
   min_ttl     = 0

   parameters_in_cache_key_and_forwarded_to_origin {
-    enable_accept_encoding_gzip = false
+    enable_accept_encoding_gzip = true
     cookies_config {
       cookie_behavior = "none"
     }
   }
 }
```

## Word-level markers — string, regex, ins/del words

```python "viewCount" /if_not_exists\(\w+/ ins="ReturnValues" del="ConsistentRead" title="app/marks.py"
result = await table.update_item(
    Key={"path": path},
    UpdateExpression="SET viewCount = if_not_exists(viewCount, :z) + :n",
    ExpressionAttributeValues={":z": 0, ":n": by},
    ReturnValues="UPDATED_NEW",
    ConsistentRead=True,
)
return int(result["Attributes"]["viewCount"])
```

## Line numbers — per-block opt-in with offset

```go showLineNumbers startLineNumber=191 title="cmd/server/count.go"
func handleCount(store Store[int64]) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()

		count, err := store.Get(ctx, r.URL.Path)
		if err != nil {
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}
	}
}
```

## Long lines — soft wrap

```bash wrap
aws cloudfront create-invalidation --distribution-id E2EXAMPLE123 --paths '/index.html' '/writing/*' '/assets/*' --output json --query 'Invalidation.{Id:Id,Status:Status,CreateTime:CreateTime}' --profile prod
```

## Frameless block

```json frame="none"
{ "frame": "none", "chrome": false }
```

## Console output — titled terminal block

```console title="deploy session"
$ ./deploy.sh rottler-io-site E2EXAMPLE123
upload: dist/index.html to s3://rottler-io-site/index.html
deployed 2026-07-19T14:02:11Z
```

## Console output — terminal block

```console
$ terraform plan -var="environment=prod"
Terraform will perform the following actions:

  # aws_cloudfront_cache_policy.api will be updated in-place
  ~ resource "aws_cloudfront_cache_policy" "api" {
      ~ default_ttl = 86400 -> 0
        name        = "api-cache-policy"
    }

Plan: 0 to add, 1 to change, 0 to destroy.

$ terraform apply -auto-approve
aws_cloudfront_cache_policy.api: Modifying... [id=6d0757ea]
aws_cloudfront_cache_policy.api: Modifications complete after 2s

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```
