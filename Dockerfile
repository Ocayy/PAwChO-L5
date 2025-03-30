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