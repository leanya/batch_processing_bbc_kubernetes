# https://docs.streamlit.io/deploy/tutorials/docker

FROM python:3.9-slim

WORKDIR /app

COPY . .

RUN pip install -r requirements.txt

EXPOSE 8501

HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health

CMD [ "streamlit", "run", "app.py"]

# docker build -t streamlit .
# docker run -p 8501:8501 streamlit
# To view your app, users can browse to http://0.0.0.0:8501 or http://localhost:8501