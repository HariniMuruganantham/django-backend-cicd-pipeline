# 🧠 Django Backend CI/CD Pipeline

This repository demonstrates a **Django backend** project integrated with a **GitHub Actions CI/CD pipeline** for automated testing, code quality checks, and security scans.

---

## 🚀 Features

✅ Automated testing with **pytest**  
✅ Code quality checks using **flake8**, **black**, **isort**, and **mypy**  
✅ PostgreSQL service setup for database tests  
✅ Security scanning with **Trivy**  
✅ Test coverage reporting via **Codecov**  
✅ Docker image build and vulnerability scan  

---

## ⚙️ CI/CD Pipeline Workflow

The pipeline runs automatically on:
- Every **push** to the `main` branch  
- Every **pull request** targeting `main`

---

### 🧩 Pipeline Stages

1. **Code Quality Checks**
   - flake8 linting
   - black formatting
   - isort import order
   - mypy static type check

2. **Backend Tests**
   - PostgreSQL container setup
   - Django migrations
   - pytest unit tests
   - coverage report upload

3. **Security Scans**
   - Trivy filesystem scan
   - Trivy Docker image scan
   - Upload scan reports as GitHub artifacts

---

## 🧪 Run Locally

```bash
# 1. Activate your virtual environment
venv\Scripts\activate     # Windows
source venv/bin/activate  # macOS/Linux

# 2. Install dependencies
pip install -r requirements.txt

# 3. Apply migrations
python manage.py migrate

# 4. Run tests
pytest
