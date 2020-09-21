#! /bin/sh
# Initialization of Script
gcloud init --skip-diagnostics < a

docker run hello-world

mkdir test 

cd test
ID=$(gcloud info --format='value(config.project)')

cat > Dockerfile <<EOF
# Use an official Node runtime as the parent image
FROM node:6

# Set the working directory in the container to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

# Make the container's port 80 available to the outside world
EXPOSE 80

# Run app.js using node when the container launches
CMD ["node", "app.js"]
EOF

cat > app.js <<EOF
const http = require('http');

const hostname = '0.0.0.0';
const port = 80;

const server = http.createServer((req, res) => {
    res.statusCode = 200;
      res.setHeader('Content-Type', 'text/plain');
        res.end('Hello World\n');
});

server.listen(port, hostname, () => {
    console.log('Server running at http://%s:%s/', hostname, port);
});

process.on('SIGINT', function() {
    console.log('Caught interrupt signal and will exit');
    process.exit();
});
EOF

cat > app.js1 <<EOF
const http = require('http');

const hostname = '0.0.0.0';
const port = 80;

const server = http.createServer((req, res) => {
    res.statusCode = 200;
      res.setHeader('Content-Type', 'text/plain');
        res.end('Welcome to Cloud\n');
});

server.listen(port, hostname, () => {
    console.log('Server running at http://%s:%s/', hostname, port);
});

process.on('SIGINT', function() {
    console.log('Caught interrupt signal and will exit');
    process.exit();
});
EOF

docker build -t node-app:0.1 .

docker run -p 4000:80 --name my-app -d node-app:0.1 &

docker ps

mv app.js1 app.js
docker build -t node-app:0.2 .
docker run -p 8080:80 --name my-app-2 -d node-app:0.2 &
docker ps

#curl http://localhost:8080

#curl http://localhost:4000

#gcloud config list project


ID=$(gcloud info --format='value(config.project)')

docker tag node-app:0.2 gcr.io/$ID/node-app:0.2
#docker images
docker push gcr.io/$ID/node-app:0.2
docker stop $(docker ps -q)
docker rm $(docker ps -aq)
docker rmi node-app:0.2 gcr.io/$ID/node-app node-app:0.1
docker rmi node:6
docker rmi $(docker images -aq) # remove remaining images
docker images
docker pull gcr.io/$ID/node-app:0.2
docker run -p 4000:80 -d gcr.io/$ID/node-app:0.2
#curl http://localhost:4000

echo "End of the script"
gcloud auth revoke --all
