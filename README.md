# Serverless URL Shortener on AWS

This is a fully serverless URL shortener built using **AWS Lambda**, **API Gateway**, **DynamoDB**, **S3**, **CloudFront**, and **Terraform**. It allows users to shorten any URL and receive a redirectable short link via a clean web interface.

---

## Features

- 🌐 Static web UI hosted on S3 + CloudFront (`https://ui.sctp-sandbox.com`)
- 🔗 Short links powered by API Gateway + Lambda (`https://short.sctp-sandbox.com`)
- Auto-generated 8-character short codes using UUID
- Fully serverless and scalable architecture
- Infrastructure provisioned entirely using Terraform
- CORS + OPTIONS Lambda support for frontend API calls

---

## Architecture Diagram

```text
                   ┌────────────────────────┐
                   │    Client (Browser)    │
                   └─────────┬──────────────┘
                             │
               ┌─────────────▼──────────────┐
               │  CloudFront (ui.sctp-sandbox.com)  │
               └─────────────┬──────────────┘
                             │
                     ┌───────▼────────────┐
                     │      S3 Bucket     │
                     │   Static Website   │
                     └────────┬───────────┘
                              │
            ┌─────────────────▼────────────────┐
            │     API Gateway (short.sctp...)  │
            └─────────────┬─────────────┬──────┘
                          │             │
                 ┌────────▼──┐    ┌─────▼────────┐
                 │ shorten.py│    │ redirect.py  │
                 └────┬──────┘    └────┬─────────┘
                      ▼               ▼
                ┌──────────────────────────────┐
                │      DynamoDB: UrlTable      │
                └──────────────────────────────┘
```

---

## Live Demo

- Frontend UI: [https://ui.sctp-sandbox.com](https://ui.sctp-sandbox.com)
- Backend API: [https://short.sctp-sandbox.com](https://short.sctp-sandbox.com)

Paste a long URL on the UI and click **Shorten** — you’ll receive a short redirectable link!

---

## Project Structure

```
serverless-url-shortener/
├── lambda/
│   ├── shorten.py        # Handles POST /shorten
│   ├── redirect.py       # Handles GET /{short_id}
│   ├── options.py        # Handles OPTIONS /shorten for CORS
│   ├── shorten.zip
│   ├── redirect.zip
│   └── options.zip
├── terraform/
│   ├── main.tf           # Full infrastructure
│   ├── variables.tf
│   └── outputs.tf
├── frontend/
│   └── index.html        # HTML + JS UI (calls short.sctp-sandbox.com)
└── README.md
```

---

## Deployment Guide

### 1. Clone the repo

```bash
git clone https://github.com/YeeFei93/serverless-url-shortener.git
cd serverless-url-shortener
```

### 2. Prepare Lambda Functions

```bash
cd lambda
zip shorten.zip shorten.py
zip redirect.zip redirect.py
zip options.zip options.py
```

### 3. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

### 4. Upload Frontend to S3

```bash
aws s3 cp ../frontend/index.html s3://yee-fei-url-shortener-frontend/ --acl public-read
```

---

## API Endpoints

### POST `/shorten`

**Request:**
```bash
curl -X POST https://short.sctp-sandbox.com/shorten \
-H "Content-Type: application/json" \
-d '{"url": "https://www.example.com"}'
```

**Response:**
```json
{
  "short_url": "https://short.sctp-sandbox.com/abc12345"
}
```

---

### GET `/{short_id}`

Redirects to the original URL.

```bash
curl -I https://short.sctp-sandbox.com/abc12345
```

**Response:**
```
HTTP/2 302
Location: https://www.example.com
```

---

## Deployment Highlights

- Custom domain names:
  - API: `https://short.sctp-sandbox.com`
  - Frontend: `https://ui.sctp-sandbox.com`
- SSL certificates issued via **AWS Certificate Manager (ACM)**
- DNS routing configured using **Amazon Route 53**
- Provisioned via **Terraform** for reproducibility and automation

---

## Built With

- [AWS Lambda](https://aws.amazon.com/lambda/)
- [Amazon API Gateway](https://aws.amazon.com/api-gateway/)
- [Amazon DynamoDB](https://aws.amazon.com/dynamodb/)
- [Amazon S3 + CloudFront](https://aws.amazon.com/cloudfront/)
- [Terraform](https://www.terraform.io/)
- [Python 3.9](https://www.python.org/)

---

## Future Improvements

- [ ] Custom analytics (click count)
- [ ] Link expiration support
- [ ] Admin dashboard for tracking
- [ ] Vanity URLs
- [ ] Short ID collision detection
