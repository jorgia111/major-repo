FROM nginx:12
WORKDIR /app
ADD . /app
EXPOSE 3000
CMD nginx index.html

