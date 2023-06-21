FROM python:3

MAINTAINER cronic@zensystem.io

COPY merge_to_address.py requirements.txt /root/

RUN pip install -r /root/requirements.txt

ENTRYPOINT ["python3", "/root/merge_to_address.py"]

CMD ["-h"]
