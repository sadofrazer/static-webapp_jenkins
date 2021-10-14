FROM httpd
LABEL Name="Frazer"
LABEL Email="sadofrazer@yahoo.fr"
EXPOSE 80
COPY ./src/ /usr/local/apache2/htdocs/