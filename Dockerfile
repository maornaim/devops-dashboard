FROM python:3.12-slim

WORKDIR /app

COPY app/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .
COPY database.py .

EXPOSE 5000

CMD ["python", "app.py"]