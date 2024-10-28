#!/bin/bash

# Variables
POSTGRES_VERSION=15
ODOO12_DB="db_odoo12"
ODOO18_DB="db_odoo18"
ODOO12_PORT=8069
ODOO18_PORT=8070
ODOO12_DIR="odoo12"
ODOO18_DIR="odoo18"
USER="willy"
PWD_O12="odoo12"
PWD_O18="odoo18"

# Crear el archivo docker-compose.yaml
cat > docker-compose.yaml <<EOL
version: '3.8'

services:
  postgres:
    image: postgres:${POSTGRES_VERSION}
    environment:
      POSTGRES_USER: $USER
      POSTGRES_PASSWORD: $PWD_O12
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  odoo12:
    build: ./$ODOO12_DIR
    environment:
      HOST: postgres
      USER: $USER
      PASSWORD: $PWD_O12
      DB_NAME: $ODOO12_DB
    ports:
      - "$ODOO12_PORT:8069"
    depends_on:
      - postgres
    volumes:
      - ./$ODOO12_DIR:/mnt/odoo12

  odoo18:
    build: ./$ODOO18_DIR
    environment:
      HOST: postgres
      USER: $USER
      PASSWORD: $PWD_O18
      DB_NAME: $ODOO18_DB
    ports:
      - "$ODOO18_PORT:8069"
    depends_on:
      - postgres
    volumes:
      - ./$ODOO18_DIR:/mnt/odoo18

volumes:
  pgdata:
EOL

# Crear init-db.sh para odoo12
cat > $ODOO12_DIR/init-db.sh <<EOL
#!/bin/bash
set -e

psql -h postgres -U $USER -c "CREATE DATABASE $ODOO12_DB;"
psql -h postgres -U $USER -c "ALTER USER $USER WITH SUPERUSER;"
EOL

# Crear init-db.sh para odoo18
cat > $ODOO18_DIR/init-db.sh <<EOL
#!/bin/bash
set -e

psql -h postgres -U $USER -c "CREATE DATABASE $ODOO18_DB;"
psql -h postgres -U $USER -c "ALTER USER $USER WITH SUPERUSER;"
EOL

# Hacer ejecutables los scripts
chmod +x $ODOO12_DIR/init-db.sh
chmod +x $ODOO18_DIR/init-db.sh

# Levantar los contenedores
docker-compose up -d

# Ejecutar scripts de inicialización
docker exec -it $(docker-compose ps -q odoo12) bash -c "./init-db.sh"
docker exec -it $(docker-compose ps -q odoo18) bash -c "./init-db.sh"

# Crear entornos virtuales
python3 -m venv ./$ODOO12_DIR/venv
python3 -m venv ./$ODOO18_DIR/venv

# Activar y instalar dependencias para odoo12
source ./$ODOO12_DIR/venv/bin/activate
pip install -r ./$ODOO12_DIR/requirements.txt
deactivate

# Activar y instalar dependencias para odoo18
source ./$ODOO18_DIR/venv/bin/activate
pip install -r ./$ODOO18_DIR/requirements.txt
deactivate

echo "Odoo y PostgreSQL están configurados y corriendo."

