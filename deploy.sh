#!/bin/bash

echo "Compilar projeto"
mvn -q clean package -DskipTests
wait

echo "Criar Imagem"
docker build --no-cache -t demo-primefaces:latest .
wait

#Docker
#echo "Declinar docker-compose ativo"
#docker-compose down -v --rmi all && echo 'container declinado' || echo 'container não encontrado'
#wait
#
#
#echo "Subir docker-compose"
#docker-compose up -d --build
#wait

#docker swarm
#echo "Declinar Servico"
#docker stack rm demo-primefaces
#wait

echo "Subir Servico"
docker stack deploy --compose-file docker-compose.yml demo-primefaces
wait
