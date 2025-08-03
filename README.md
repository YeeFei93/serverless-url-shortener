# Serverless URL Shortener on AWS

This is a fully serverless URL shortener built using **AWS Lambda**, **API Gateway**, **DynamoDB**, **S3**, **CloudFront**, and **Terraform**. It allows users to shorten - ✅ **Infrastructure as Code** - provisioned via **Terraform** with organized structureny URL and receive a redirectable short link via a clean web interface.

---

## Features

### Core Functionality
- **Static web UI** hosted on S3 + CloudFront (`https://ui.sctp-sandbox.com`)
- **Short links** powered by API Gateway + Lambda (`https://short.sctp-sandbox.com`)
- **Auto-generated 8-character short codes** using UUID
- **Fully serverless and scalable** architecture
- **Infrastructure as Code** - provisioned entirely using Terraform
- **CORS support** - dedicated OPTIONS Lambda for frontend API calls
- **Custom domains** - SSL certificates via AWS Certificate Manager (ACM)
- **DNS routing** - Amazon Route 53 for domain management
- **Secure HTTPS** - TLS 1.2 enforced across all endpoints

### 🆕 Enhanced Monitoring & Analytics
- **CloudWatch Dashboards** - Real-time metrics for Lambda, API Gateway, and DynamoDB
- **CloudWatch Alarms** - Automated alerts for errors, high traffic, and performance issues
- **X-Ray Distributed Tracing** - End-to-end request tracing across all services
- **Kinesis Data Firehose** - Stream click analytics to S3 for long-term analysis
- **S3 Analytics Storage** - Organized data storage with compression and partitioning

### 🆕 Security & Protection
- **AWS WAF (Web Application Firewall)** - Rate limiting and attack protection
- **CloudFront Security** - DDoS protection and geographic restrictions
- **IAM Least Privilege** - Minimal required permissions for all services
- **VPC Security** - Network isolation where applicable

### 🆕 Operational Excellence  
- **SNS Notifications** - Alert system for operational issues
- **Automated Log Management** - Centralized logging with retention policies
- **Cost Optimization** - Free tier usage with efficient resource sizing
- **High Availability** - Multi-AZ deployment patterns

---

## Deployment Status

🟡 **DEPLOYED WITH DAILY MAINTENANCE REQUIRED**

- ✅ Infrastructure provisioned via Terraform
- ✅ Lambda functions deployed and tested  
- ✅ Custom domains configured with SSL certificates
- ✅ API endpoints active at `https://short.sctp-sandbox.com`
- ⚠️ **Student AWS Account Note**: Resources are automatically destroyed daily and require redeployment

### Daily Redeployment Required

**Important**: This project is deployed on a student AWS account where certain resources (primarily S3 buckets) are automatically destroyed each day for cost management. To restore full functionality:

```bash
cd terraform
terraform apply
```

This will recreate the destroyed resources. Most persistent resources (Lambda functions, API Gateway, DynamoDB, Route 53 records) typically remain intact, but the S3 bucket and CloudFront distribution may need to be recreated daily.

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
│   └── (*.zip files generated by build.sh)
├── terraform/            # Infrastructure as Code (organized by service)
│   ├── main.tf           # Entry point with documentation
│   ├── providers.tf      # AWS provider and data sources
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── database.tf       # DynamoDB table
│   ├── iam.tf            # IAM roles and policies
│   ├── lambda.tf         # Lambda functions
│   ├── api-gateway.tf    # API Gateway, routes, and integrations
│   ├── frontend.tf       # S3 bucket and CloudFront
│   └── dns.tf            # Route 53 records and SSL certificates
├── frontend/
│   └── index.html        # HTML + JS UI (calls short.sctp-sandbox.com)
├── build.sh              # Script to build Lambda deployment packages
└── README.md
```

**File Responsibilities:**
- **`providers.tf`** - Provider configuration and shared data sources
- **`database.tf`** - All DynamoDB-related resources
- **`iam.tf`** - IAM roles, policies, and permissions
- **`lambda.tf`** - Lambda functions with consistent naming and tagging
- **`api-gateway.tf`** - API Gateway, integrations, routes, and permissions
- **`frontend.tf`** - S3 bucket configuration and CloudFront distribution
- **`dns.tf`** - SSL certificates, DNS validation, and Route 53 records

---

## Deployment Guide

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed (v1.0+)
- Access to a Route 53 hosted zone for `sctp-sandbox.com`
- **Note**: Student AWS accounts have daily resource cleanup - see Deployment Status section

### 1. Clone the Repository

```bash
git clone https://github.com/YeeFei93/serverless-url-shortener.git
cd serverless-url-shortener
```

### 2. Build Lambda Deployment Packages

```bash
./build.sh
```

This script creates the necessary ZIP files for Lambda deployment:
- `lambda/shorten.zip` - URL shortening functionality
- `lambda/redirect.zip` - URL redirection functionality  
- `lambda/options.zip` - CORS preflight handling

### 3. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

**What happens during deployment:**
- **`providers.tf`** configures AWS provider and retrieves Route 53/IAM data
- **`database.tf`** creates DynamoDB table with proper configuration
- **`iam.tf`** attaches necessary policies to Lambda execution role
- **`lambda.tf`** deploys all three Lambda functions (shorten, redirect, options)
- **`api-gateway.tf`** sets up HTTP API with routes and integrations
- **`dns.tf`** provisions SSL certificates and configures DNS records
- **`frontend.tf`** creates S3 bucket, uploads files, and sets up CloudFront

The organized file structure makes it easy to understand and troubleshoot each deployment phase.

**Note**: The infrastructure deployment is automated and reproducible. Due to student AWS account limitations with daily resource cleanup, you may need to run `terraform apply` daily to restore any destroyed resources (primarily S3 buckets).

### 4. Frontend Deployment (Automated)

The frontend `index.html` is automatically uploaded to S3 via Terraform and served through CloudFront.

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

- **Custom domain names:**
  - API: `https://short.sctp-sandbox.com`  
  - Frontend: `https://ui.sctp-sandbox.com`
- **SSL certificates** issued and validated via **AWS Certificate Manager (ACM)**
- **DNS routing** configured using **Amazon Route 53**
- **Infrastructure as Code** - provisioned via **Terraform** with enterprise organization
- **Automated deployment** - single `terraform apply` deploys entire stack
- **Separate certificates** - dedicated SSL certs for each domain for security
- **Modular Terraform structure** - service-based files for maintainability and team collaboration
- **Production-ready practices** - consistent naming, tagging, and dependency management

---

## Built With

- [AWS Lambda](https://aws.amazon.com/lambda/)
- [Amazon API Gateway](https://aws.amazon.com/api-gateway/)
- [Amazon DynamoDB](https://aws.amazon.com/dynamodb/)
- [Amazon S3 + CloudFront](https://aws.amazon.com/cloudfront/)
- [Terraform](https://www.terraform.io/)
- [Python 3.9](https://www.python.org/)

---

## Implementation Status & Future Improvements

### Completed Features
- [x] **Basic URL shortening** - Core functionality implemented
- [x] **Custom domains** - Both frontend and API have custom domains
- [x] **SSL/TLS security** - HTTPS enforced with proper certificates
- [x] **CORS support** - Frontend can call API from different domain
- [x] **Infrastructure automation** - Complete Terraform deployment
- [x] **Static web UI** - Clean, functional frontend interface
- [x] **Organized Terraform structure** - Service-based file organization for maintainability

### Future Enhancements
- [ ] **Custom analytics** (click count tracking)
- [ ] **Link expiration** support with TTL
- [ ] **Admin dashboard** for URL management and analytics
- [ ] **Vanity URLs** (custom short codes)
- [ ] **Short ID collision detection** and retry logic
- [ ] **Rate limiting** to prevent abuse
- [ ] **Bulk URL shortening** via CSV upload
- [ ] **QR code generation** for shortened URLs
