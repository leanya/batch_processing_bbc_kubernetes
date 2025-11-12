FROM python:3.9-alpine

WORKDIR /app

COPY . .

RUN pip install -r requirements.txt

# RUN /usr/bin/crontab /app/crontab.txt

# CMD ["crond", "-f"]
# CMD python /app/data_prep_dag.py && crond -f -l 8
CMD python /app/data_prep_dag.py 
