FROM python:3.8-slim-buster

CMD [ "python3", "-m" , "flask", "--app", "main.py", "run", "--host=0.0.0.0", "--port=5000"]
