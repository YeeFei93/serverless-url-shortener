# Serverless URL Shortener on AWS

This is a fully serverless URL shortener built using **AWS Lambda**, **API Gateway**, **DynamoDB**, and **Terraform**. It allows users to generate shortened URLs and automatically redirects to the original URLs when visited.

---

## Features

- Shorten any valid URL
- Auto-generated 8-character short codes
- Serverless and scalable architecture
- Infrastructure provisioned using Terraform
- Built with Python and AWS SDK (Boto3)

---

## Architecture

```text
          ┌──────────────┐
          │   Client     │
          └─────┬────────┘
                │
        ┌───────▼────────────────┐
        │ API Gateway (HTTP API) │
        └───────┬───────┬────────┘
                │       │
         ┌──────▼─┐ ┌───▼────────┐
         │ Lambda │ │  Lambda    │
         │Shorten │ │ Redirect   │
         └──┬─────┘ └────┬───────┘
            │            │
      ┌─────▼────────────▼─────┐
      │     DynamoDB Table     │
      │      (UrlTable)        │
      └────────────────────────┘
```

---

## Built With

- [AWS Lambda](https://aws.amazon.com/lambda/)
- [Amazon API Gateway](https://aws.amazon.com/api-gateway/)
- [Amazon DynamoDB](https://aws.amazon.com/dynamodb/)
- [Terraform](https://www.terraform.io/)
- [Python 3.9](https://www.python.org/)

---

## How It Works

### POST `/shorten`

**Request:**
```bash
curl -X POST https://<API-ID>.execute-api.<region>.amazonaws.com/shorten \
-H "Content-Type: application/json" \
-d '{"url": "https://www.example.com"}'
```

**Response:**
```json
{
  "short_url": "https://<API-ID>.execute-api.<region>.amazonaws.com/abc12345"
}
```

---

### GET `/{short_id}`

Visiting the short URL will automatically redirect to the original URL.

```bash
curl -I https://<API-ID>.execute-api.<region>.amazonaws.com/abc12345
```

**Response:**
```
HTTP/2 302
location: https://www.example.com
```

---

## Terraform Deployment

### 1. Clone the repo

```bash
git clone https://github.com/YeeFei93/serverless-url-shortener.git
cd aws-serverless-url-shortener
```

### 2. Zip the Lambda functions

```bash
cd lambda
zip shorten.zip shorten.py
zip redirect.zip redirect.py
```

### 3. Deploy with Terraform

```bash
cd terraform
terraform init
terraform apply
```

---

## Project Structure

```
aws-serverless-url-shortener/
├── lambda/
│   ├── shorten.py        # Short URL creator
│   ├── redirect.py       # Redirect logic
│   ├── shorten.zip
│   └── redirect.zip
├── terraform/
│   ├── main.tf           # Infra definition
│   ├── variables.tf
│   └── outputs.tf
└── README.md
```