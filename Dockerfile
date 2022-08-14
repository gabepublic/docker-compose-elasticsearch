FROM ubuntu:18.04

# install system-wide deps for python and node
RUN apt-get -yqq update
RUN apt-get -yqq install python3-pip python3-dev curl gnupg

# copy our application code
ADD flaskapp /opt/flaskapp
WORKDIR /opt/flaskapp

# fetch app specific deps
RUN pip3 install -r requirements.txt

# expose port
EXPOSE 5000

# start app
CMD [ "python3", "./app.py" ]