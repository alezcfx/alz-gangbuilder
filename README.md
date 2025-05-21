# ALZ Gang Builder

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)

## 📝 Description

ALZ Gang Builder est un script FiveM qui permet de créer et gérer des gangs directement en jeu via une interface RageUI. Compatible avec ox_target et ox_inventory, il offre une expérience utilisateur fluide et moderne pour la gestion complète des gangs sur votre serveur.

## 🔥 Caractéristiques Principales

### 👥 Création de Gangs
- Interface RageUI moderne et intuitive
- Création de gangs personnalisés en jeu
- Gestion des membres et des grades
- Attribution des permissions par grade
- Personnalisation complète des gangs

### 🏢 Gestion des Gangs
- Menu F7 pour accéder rapidement aux fonctions du gang
- Gestion des recrutements
- Système de grades personnalisables
- Gestion des salaires
- Actions de gang configurables

### 🚗 Système de Garage
- Garage personnalisé pour chaque gang
- Compatible avec ox_target (optionnel)
- Gestion des véhicules de gang
- Marqueurs personnalisables
- Système de clés de véhicules

### 📦 Système de Stockage
- Coffre de gang sécurisé
- Compatible avec ox_inventory (optionnel)
- Système de poids et d'emplacements configurables
- Logs des actions
- Système de permissions par grade

## 📋 Prérequis
- ESX Framework
- ox_inventory (optionnel)
- ox_target (optionnel)
- mysql-async

## 🛠️ Installation

1. Téléchargez les fichiers
2. Placez le dossier `alz-gangbuilder` dans votre dossier `resources`
3. Ajoutez `ensure alz-gangbuilder` à votre `server.cfg`
4. Configurez le fichier `config.lua` selon vos besoins
5. Redémarrez votre serveur

## ⚙️ Configuration

Le fichier `config.lua` permet de personnaliser :
- L'activation/désactivation de ox_target et ox_inventory
- Les permissions des grades
- Les marqueurs et leurs apparences
- Les options de stockage
- Les véhicules disponibles
- Et bien plus encore...

## 📚 Documentation

### Commandes Admin
- `/removegangadmin` : Supprimer un admin
- `/addgangadmin` : Ajouter un ID Admin pour ouvrir le menu
- `/setgang` : Définir le gang d'un joueur

### Touches
- `F9` : Ouvrir le menu gang

## 🤝 Support

Pour toute assistance ou question, rejoignez notre Discord : [discord.gg/VJEuqYkSWt](https://discord.gg/VJEuqYkSWt)

## 👨‍💻 Auteur

**BZRR - DEV**
Discord : [discord.gg/VJEuqYkSWt](https://discord.gg/VJEuqYkSWt)

## 📜 License

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails. 
