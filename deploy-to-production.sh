#!/bin/bash

# Script pour transférer le contenu de partnersllc-app vers ../partnersllc (production)
# Usage: ./deploy-to-production.sh

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Chemins
SOURCE_DIR="partnersllc-app"
DEST_DIR="../partnersllc"

# Vérifier que le dossier source existe
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Erreur: Le dossier $SOURCE_DIR n'existe pas${NC}"
    exit 1
fi

# Créer le dossier de destination s'il n'existe pas
if [ ! -d "$DEST_DIR" ]; then
    echo -e "${YELLOW}Le dossier $DEST_DIR n'existe pas. Création...${NC}"
    mkdir -p "$DEST_DIR"
fi

echo -e "${GREEN}Début du transfert de $SOURCE_DIR vers $DEST_DIR${NC}"

# Utiliser rsync pour copier avec exclusions
# Exclure les fichiers/dossiers qui ne doivent pas être copiés
rsync -av --progress \
    --exclude='node_modules' \
    --exclude='.next' \
    --exclude='.pnpm-store' \
    --exclude='tsconfig.tsbuildinfo' \
    --exclude='.env' \
    --exclude='.env.local' \
    --exclude='.env.development.local' \
    --exclude='.env.test.local' \
    --exclude='.env.production.local' \
    --exclude='.git' \
    --exclude='.DS_Store' \
    --exclude='*.log' \
    "$SOURCE_DIR/" "$DEST_DIR/"

echo -e "${GREEN}Transfert terminé avec succès!${NC}"
echo -e "${YELLOW}Note: Les fichiers suivants ont été exclus:${NC}"
echo "  - node_modules"
echo "  - .next"
echo "  - .pnpm-store"
echo "  - .env*"
echo "  - .git"
echo "  - tsconfig.tsbuildinfo"
