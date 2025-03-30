# Sprawozdanie z laboratorium 5 - Docker

### 1. Wprowadzenie

Celem zadania było utworzenie wieloetapowego pliku Dockerfile, który buduje prostą aplikację webową wyświetlającą podstawowe informacje o serwerze, a następnie konfiguruje serwer Nginx do jej serwowania. Proces budowy został podzielony na dwa etapy:
- Etap 1: Zbudowanie prostej aplikacji webowej z wykorzystaniem obrazu bazowego "scratch" i minimalnego systemu Alpine Linux
- Etap 2: Skonfigurowanie serwera Nginx do serwowania aplikacji z etapu pierwszego

### 2. Treść utworzonego pliku Dockerfile

```dockerfile
# Stage 1: Budowa aplikacji
FROM scratch AS stage1

# Dodanie minimalnego systemu Alpine Linux
ADD alpine-minirootfs-3.21.3-aarch64.tar.gz /

# Instalacja Node.js i npm
RUN apk add --update nodejs npm

# Ustawienie katalogu roboczego
WORKDIR /app

# Kopiowanie wszystkich plików aplikacji za jednym razem
COPY package.json app.js ./

# Instalacja zależności
RUN npm install

# Definicja argumentu VERSION z wartością domyślną
ARG VERSION=1.0.0
ENV VERSION=${VERSION}

# Stage 2: Nginx
FROM nginx:alpine

# Instalacja curl i Node.js za jednym razem
RUN apk add --update --no-cache curl nodejs npm

# Kopiowanie wszystkich plików konfiguracyjnych za jednym razem
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Kopiowanie plików z etapu pierwszego
COPY --from=stage1 /app /app

# Przekazanie wersji aplikacji
ARG VERSION=1.0.0
ENV VERSION=${VERSION}

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/ || exit 1

# Expose port 80
EXPOSE 80

# Uruchomienie skryptu startowego
CMD ["/start.sh"]
```

### 3. Pliki aplikacji

#### app.js
```javascript
const express = require('express');
const os = require('os');
const app = express();
const PORT = 3000;

const VERSION = process.env.VERSION || 'undefined';

function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
}

app.get('/', (req, res) => {
  const hostname = os.hostname();
  const ip = getLocalIP();
  
  res.send(`
    <html>
      <head>
        <title>Informacje o serwerze</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
          h1 { color: #333; }
          .info { background: #f5f5f5; padding: 20px; border-radius: 5px; }
        </style>
      </head>
      <body>
        <h1>Informacje o serwerze</h1>
        <div class="info">
          <p><strong>Adres IP serwera:</strong> ${ip}</p>
          <p><strong>Nazwa serwera (hostname):</strong> ${hostname}</p>
          <p><strong>Wersja aplikacji:</strong> ${VERSION}</p>
        </div>
      </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`Aplikacja działa na porcie ${PORT}`);
});
```

#### package.json
```json
{
  "name": "pawcho-l5-jakub-nowosad",
  "version": "1.0.0",
  "description": "Aplikacja do sprawozdania z PAwChO, Laboratorium 5",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### 4. Polecenia budowy i uruchomienia

#### 4.1 Zbudowanie obrazu z określoną wersją
```bash
docker build --build-arg VERSION=2.1.1 -t webapp:multistage .
```

Wynik działania:
```
[+] Building 11.4s (17/17) FINISHED                                                                                                   docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                  0.0s
 => => transferring dockerfile: 1.16kB                                                                                                                0.0s
 => [internal] load metadata for docker.io/library/nginx:alpine                                                                                       2.2s
 => [auth] library/nginx:pull token for registry-1.docker.io                                                                                          0.0s
 => [internal] load .dockerignore                                                                                                                     0.0s
 => => transferring context: 2B                                                                                                                       0.0s
 => [internal] load build context                                                                                                                     0.1s
 => => transferring context: 3.85MB                                                                                                                   0.1s
 => [stage-1 1/6] FROM docker.io/library/nginx:alpine@sha256:4ff102c5d78d254a6f0da062b3cf39eaf07f01eec0927fd21e219d0af8bc0591                         1.4s
 => => resolve docker.io/library/nginx:alpine@sha256:4ff102c5d78d254a6f0da062b3cf39eaf07f01eec0927fd21e219d0af8bc0591                                 0.0s
 => => sha256:0a329c61f9e1dc20260b65b0ef67440ced65fbf671c1e93df0a9710fbb42d536 15.88MB / 15.88MB                                                      0.6s
 => => sha256:3c5c25f3816a63c8239c4a853ae22036406ffbd4f55b16e29e01f941f2dea356 1.40kB / 1.40kB                                                        0.5s
 => => sha256:76f8ad18306ed8a7757d73f845d89b3aee98b4774af2b7c5c9a288bcf097036c 1.21kB / 1.21kB                                                        0.5s
 => => sha256:8ea77ffafa6ef989339c5c391fb30729e3f148240c0834f1db148158ab32f657 404B / 404B                                                            0.5s
 => => sha256:83f1386059fa17276f4f0e676f45370a63667006c4d8e514298f71c6639328ea 956B / 956B                                                            0.2s
 => => sha256:9e170776f94c97f95260908e78676599218d0247c22929326f7072689b832bbb 626B / 626B                                                            0.2s
 => => sha256:0be31969a6d1e1f2699d0fb5a48f1b4da62a3b2aefa8a9b0dfb548bc497bf321 1.78MB / 1.78MB                                                        0.3s
 => => sha256:6e771e15690e2fabf2332d3a3b744495411d6e0b00b2aea64419b58b0066cf81 3.99MB / 3.99MB                                                        0.4s
 => => extracting sha256:6e771e15690e2fabf2332d3a3b744495411d6e0b00b2aea64419b58b0066cf81                                                             0.1s
 => => extracting sha256:0be31969a6d1e1f2699d0fb5a48f1b4da62a3b2aefa8a9b0dfb548bc497bf321                                                             0.0s
 => => extracting sha256:9e170776f94c97f95260908e78676599218d0247c22929326f7072689b832bbb                                                             0.0s
 => => extracting sha256:83f1386059fa17276f4f0e676f45370a63667006c4d8e514298f71c6639328ea                                                             0.0s
 => => extracting sha256:8ea77ffafa6ef989339c5c391fb30729e3f148240c0834f1db148158ab32f657                                                             0.0s
 => => extracting sha256:76f8ad18306ed8a7757d73f845d89b3aee98b4774af2b7c5c9a288bcf097036c                                                             0.0s
 => => extracting sha256:3c5c25f3816a63c8239c4a853ae22036406ffbd4f55b16e29e01f941f2dea356                                                             0.0s
 => => extracting sha256:0a329c61f9e1dc20260b65b0ef67440ced65fbf671c1e93df0a9710fbb42d536                                                             0.2s
 => [stage1 1/5] ADD alpine-minirootfs-3.21.3-aarch64.tar.gz /                                                                                        0.1s
 => [stage1 2/5] RUN apk add --update nodejs npm                                                                                                      4.9s
 => [stage-1 2/6] RUN apk add --update --no-cache curl nodejs npm                                                                                     2.7s
 => [stage-1 3/6] COPY nginx.conf /etc/nginx/conf.d/default.conf                                                                                      0.0s
 => [stage-1 4/6] COPY start.sh /start.sh                                                                                                             0.0s
 => [stage-1 5/6] RUN chmod +x /start.sh                                                                                                              0.1s
 => [stage1 3/5] WORKDIR /app                                                                                                                         0.0s
 => [stage1 4/5] COPY package.json app.js ./                                                                                                          0.0s 
 => [stage1 5/5] RUN npm install                                                                                                                      1.7s 
 => [stage-1 6/6] COPY --from=stage1 /app /app                                                                                                        0.0s 
 => exporting to image                                                                                                                                2.2s 
 => => exporting layers                                                                                                                               1.8s 
 => => exporting manifest sha256:a95094d0aba547af8e38ed9af5fe75ff164d2305e14f0a7e8f3ed6cff5e74365                                                     0.0s 
 => => exporting config sha256:f72b0039ffeeb2e9a6dfa243d293e0ab1e3d62681cd710bf65f9e0af91ef62c3                                                       0.0s
 => => exporting attestation manifest sha256:63ecd90312c271105d4855f75e4d20a1eed8410065ea153b289ee872ca8454fb                                         0.0s
 => => exporting manifest list sha256:c332143d40ee2ff003204d75f559dc182ee4f846ee2b2c73917e57fec55a1299                                                0.0s
 => => naming to docker.io/library/webapp:multistage                                                                                                  0.0s
 => => unpacking to docker.io/library/webapp:multistage                                                                                               0.4s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/nymclc7m417qsfidnp9vicnxk

What's next:
    View a summary of image vulnerabilities and recommendations → docker scout quickview 
```

#### 4.3 Uruchomienie kontenera
```bash
docker run -d -p 8080:80 --name webserver webapp:multistage
```

Wynik działania:
```
61977e7f35af9d5995d44f3763f5e8e449dd297df4945a1b86e6590ed024469e
```

#### 4.4 Sprawdzenie działania kontenera i statusu
```bash
docker ps
```

Wynik działania:
```
CONTAINER ID   IMAGE               COMMAND                  CREATED         STATUS                            PORTS                  NAMES
61977e7f35af   webapp:multistage   "/docker-entrypoint.…"   3 seconds ago   Up 3 seconds (health: starting)   0.0.0.0:8080->80/tcp   webserver
```

### 5. Potwierdzenie działania aplikacji

Rezultat wywołania polecenia `curl http://localhost:8080`:

```
curl http://localhost:8080

<html>
  <head>
    <title>Informacje o serwerze</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
      h1 { color: #333; }
      .info { background: #f5f5f5; padding: 20px; border-radius: 5px; }
    </style>
  </head>
  <body>
    <h1>Informacje o serwerze</h1>
    <div class="info">
      <p><strong>Adres IP serwera:</strong> 172.17.0.2</p>
      <p><strong>Nazwa serwera (hostname):</strong> 61977e7f35af</p>
      <p><strong>Wersja aplikacji:</strong> 2.1.1</p>
    </div>
  </body>
```

Dodatkowo poniżej znajduje się zrzut ekranu z przeglądarki potwierdzający działanie aplikacji:

![Zrzut ekranu](https://github.com/Ocayy/PAwChO-L5/blob/main/img/3.png?raw=true)

### 6. Podsumowanie

W ramach laboratorium udało się stworzyć wieloetapowy proces budowy aplikacji przy użyciu Dockerfile. Pierwszy etap (stage1) wykorzystuje obraz "scratch" jako bazę i dodaje minimalny system Alpine Linux. Na tym etapie budowana jest prosta aplikacja Node.js wyświetlająca informacje o serwerze (adres IP, hostname, wersja). 

Drugi etap (stage2) wykorzystuje obraz Nginx jako serwer HTTP i konfiguruje go do przekierowywania żądań do aplikacji Node.js z pierwszego etapu. Dodatkowo skonfigurowano HEALTHCHECK do automatycznego sprawdzania poprawności działania aplikacji.

Proces budowy został zoptymalizowany dzięki wykorzystaniu mechanizmu wieloetapowego budowania obrazów, co pozwala na zmniejszenie rozmiaru końcowego obrazu oraz zapewnia lepszą organizację procesu budowy.

Aplikacja poprawnie wyświetla wymagane informacje (adres IP, hostname, wersja aplikacji), a wersja jest przekazywana podczas budowy obrazu za pomocą argumentu VERSION.
