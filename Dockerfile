FROM nginx:latest
EXPOSE 8380-8389:80
COPY index.html /usr/share/nginx/html
#docker run -it -d -p 8380-8389:80 nginxscale:1.0 
#이경우 여러개 같은 명령어를 수행하면 8380-8389 중 하나를 선택하면
