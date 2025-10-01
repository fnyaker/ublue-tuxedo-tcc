#!/bin/bash

# Script de configuration Docker Hub pour GitLab CI/CD
# Ce script vous aide à configurer votre projet pour pousser vers Docker Hub

set -e

echo "=================================================="
echo "  Configuration Docker Hub pour GitLab CI/CD"
echo "=================================================="
echo ""

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier si le fichier .gitlab-ci.yml existe
if [ ! -f ".gitlab-ci.yml" ]; then
    echo -e "${RED}Erreur: .gitlab-ci.yml non trouvé!${NC}"
    echo "Assurez-vous d'être dans le répertoire racine du projet."
    exit 1
fi

echo "📝 Étape 1/3 : Informations Docker Hub"
echo "----------------------------------------"
echo ""

# Demander le nom d'utilisateur Docker Hub
read -p "Entrez votre nom d'utilisateur Docker Hub: " DOCKERHUB_USERNAME

if [ -z "$DOCKERHUB_USERNAME" ]; then
    echo -e "${RED}Erreur: Le nom d'utilisateur ne peut pas être vide${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Nom d'utilisateur: $DOCKERHUB_USERNAME${NC}"
echo ""

# Mettre à jour le fichier .gitlab-ci.yml
echo "🔧 Étape 2/3 : Mise à jour de .gitlab-ci.yml"
echo "----------------------------------------"
echo ""

# Backup du fichier original
cp .gitlab-ci.yml .gitlab-ci.yml.backup

# Remplacer VOTRE_USERNAME par le vrai nom d'utilisateur
sed -i "s|IMAGE_REGISTRY: \"docker.io/VOTRE_USERNAME\"|IMAGE_REGISTRY: \"docker.io/$DOCKERHUB_USERNAME\"|g" .gitlab-ci.yml

echo -e "${GREEN}✓ Fichier .gitlab-ci.yml mis à jour${NC}"
echo "  (Backup créé: .gitlab-ci.yml.backup)"
echo ""

# Instructions pour GitLab
echo "🔐 Étape 3/3 : Configuration des variables GitLab"
echo "----------------------------------------"
echo ""
echo "Vous devez maintenant configurer les variables secrètes dans GitLab:"
echo ""
echo "1. Allez sur: https://gitlab.com/VOTRE_NAMESPACE/VOTRE_PROJECT/-/settings/ci_cd"
echo "2. Trouvez la section 'Variables' et cliquez sur 'Expand'"
echo "3. Ajoutez les deux variables suivantes:"
echo ""
echo -e "${YELLOW}   Variable 1: DOCKERHUB_USERNAME${NC}"
echo "   - Key: DOCKERHUB_USERNAME"
echo "   - Value: $DOCKERHUB_USERNAME"
echo "   - Protect variable: ☑"
echo "   - Mask variable: ☑"
echo ""
echo -e "${YELLOW}   Variable 2: DOCKERHUB_TOKEN${NC}"
echo "   - Key: DOCKERHUB_TOKEN"
echo "   - Value: [Votre token Docker Hub]"
echo "   - Protect variable: ☑"
echo "   - Mask variable: ☑"
echo ""
echo "📖 Pour créer un token Docker Hub:"
echo "   1. Allez sur: https://hub.docker.com/settings/security"
echo "   2. Cliquez sur 'New Access Token'"
echo "   3. Nommez-le 'GitLab CI/CD'"
echo "   4. Sélectionnez 'Read, Write, Delete' (ou 'Read & Write')"
echo "   5. Copiez le token généré"
echo ""
echo "=================================================="
echo ""
echo -e "${GREEN}✓ Configuration locale terminée!${NC}"
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Configurez les variables dans GitLab (voir ci-dessus)"
echo "   2. Commitez les changements:"
echo "      git add .gitlab-ci.yml"
echo "      git commit -m 'Configure Docker Hub registry'"
echo "      git push origin main"
echo "   3. Le pipeline se déclenchera automatiquement"
echo ""
echo "📚 Documentation complète: DOCKER_HUB_SETUP.md"
echo ""
echo "=================================================="
