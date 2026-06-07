FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install PyTorch CPU and remaining requirements (excluding GPU torch)
RUN grep -v "torch" requirements.txt > req_no_torch.txt && \
    pip install --no-cache-dir torch==2.4.0+cpu --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r req_no_torch.txt

# Pre-download ML models into the image to eliminate cold start times on Cloud Run
RUN python -c "from transformers import pipeline, AutoModel, AutoTokenizer; \
    pipeline('sentiment-analysis', model='nlptown/bert-base-multilingual-uncased-sentiment'); \
    AutoTokenizer.from_pretrained('sentence-transformers/all-MiniLM-L6-v2'); \
    AutoModel.from_pretrained('sentence-transformers/all-MiniLM-L6-v2')"

# Copy application files
COPY . .

# Expose port 8080 (Cloud Run standard port)
EXPOSE 8080

# Run uvicorn on port 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
