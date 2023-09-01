FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ftp_downloader.py .

CMD ["python", "./ftp_downloader.py"]