# Salesforce projet

P4 – Créez une organisation Salesforce pour votre entreprise

## Prérequis
Avoir un compte Salesforce avec les autorisations nécessaires pour créer et déployer des métadonnées.
Avoir installé la Salesforce CLI (`sf`) (ou faire une mise à jour du CLI existant) : https://salesforce.com

## Veuillez forker et cloner ce projet puis suivre les étapes ci-dessous

1. Importer les métadonnées avec les commandes `sf` :
Se connecter à votre org avec VS Code (ou autre) :

```bash
sf org login web
```

2. Se positionner à la racine du projet puis lancer les différentes commandes :

Cette commande va déployer toutes les métadonnées utiles au projet - remplacer "testusername@salesforce.org" par le username de votre utilisateur dans votre environnement :

```bash
sf project deploy start --source-dir force-app/main/default --target-org testusername@salesforce.org
```

Cette commande va exécuter du code Apex contenu dans la classe - remplacer "testusername@salesforce.org" par le username de votre utilisateur dans votre environnement :

```bash
sf apex run --target-org testusername@salesforce.org --file scripts/apex/DataCreationScript.apex
```

3. Vous pouvez commencer à coder votre projet !

---

## Architecture & Fonctionnalités clés
* **Profils & Sécurité :** Gestion stricte des droits (FLS) entre le profil `System Administrator` (lecture/écriture sur les stocks) et le profil `Commercial` (lecture seule).
* **Interface LWC adaptative :** Affichage dynamique des lignes d'opportunité avec détection visuelle des ruptures de stock et actions différenciées selon le profil.
* **Automatisation (Record-Triggered Flow) :** Vérification automatique des stocks et décrémentation lors du passage d'une opportunité au statut `Closed Won`.
* **Internationalisation :** Support natif Français / Anglais via des *Custom Labels* et le *Translation Workbench*.
