<h1 style="display: flex; flex-direction: row; align-items: center;"> <img src="https://img.icons8.com/?size=512&id=7I3BjCqe9rjG&format=png"
  width="32"
  height="32"
  style="float:left;margin-right: 10px">
  Real-time Flutter chat application
</h1>

<div style="display: flex; flex-direction: row; gap: 5px">

![Windows Supported](https://img.shields.io/badge/-Windows%20supported-blue?logo=windows&style=flat)

![Android Supported](https://img.shields.io/badge/-Android%20supported-green%C3%B9?logo=android&style=flat&logoColor=white)

![Web supported](https://img.shields.io/badge/-Web%20supported-red?logo=google-chrome&style=flat&logoColor=white)

![ChatGPT](https://img.shields.io/badge/chatGPT%20Ready-74aa9c?style=flat&logo=openai&logoColor=white)

</div>

Ce projet vise a montrer une application développée en Flutter avec un back-end en Node.JS ne se reposant sur aucun service externe (~~Google Auth~~, ~~Firebase~~, ...).

Le back-end a été fait entièrement en se basant sur la librairie express.js ainsi que les drivers de la base de donnée ici postgres. De plus pour la communication en temps réel nous utilisons la librairie Socket.IO qui dispose d'un serveur dans le back-end ainsi qu'un client dans le front-end.

**La fonctionnalité la plus importante ici** est la possibilité de pouvoir communiquer en temps réel avec ChatGPT directement au sein de vos conversations avec d'autres personnes.

> ⚠️ **Mention Importante:** Toutes les conversations ne sont stocké que sur le webservice, lorsque vous souhaitez communiquer avec ChatGPT, uniquement le dernier message de la conversation est envoyé pour qu'il puisse répondre !

Il est possible d'utiliser des photos sur l'application notamment pour votre profil mais aussi en temps qu'illustration de conversation. Celles-ci sont compressés et supprimés une fois qu'elles ne sont plus utilisées pour des biens de place et de temps de réponse. Dans l'optique d'avoir une application avec le plus de fluidité possible.

|||
|--------------|---------------|
| **🗃️ Back-end** | <div style="display: flex; flex-direction: row; gap: 5px"> ![NodeJS](https://img.shields.io/badge/node.js-6DA55F?style=flat&logo=node.js&logoColor=white) ![Express.js](https://img.shields.io/badge/express.js-%23404d59.svg?style=flat&logo=express&logoColor=%2361DAFB) ![Docker](https://img.shields.io/badge/Dockerized-%230db7ed.svg?style=flat&logo=docker&logoColor=white) ![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=flat&logo=postgresql&logoColor=white) ![Socket.io](https://img.shields.io/badge/Socket.io-black?style=falt&logo=socket.io&badgeColor=010101) ![ChatGPT](https://img.shields.io/badge/OpenAI%20API-74aa9c?style=flat&logo=openai&logoColor=white)</div>  |
| **🤳 Front-end** | <div style="display: flex; flex-direction: row; gap: 5px;"> ![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white) ![Socket.io](https://img.shields.io/badge/Socket.io-black?style=falt&logo=socket.io&badgeColor=010101)</div> |
| **⚒️ Tools** | <div style="display: flex; flex-direction: row; gap: 5px;"> ![Visual Studio Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=flat&logo=visual-studio-code&logoColor=white) ![Android Studio](https://img.shields.io/badge/Android%20Studio-3DDC84.svg?style=flat&logo=android-studio&logoColor=white) ![Google Chrome](https://img.shields.io/badge/Google%20Chrome-4285F4?style=flat&logo=GoogleChrome&logoColor=white) ![Windows Terminal](https://img.shields.io/badge/Windows%20Terminal-%234D4D4D.svg?style=flat&logo=windows-terminal&logoColor=white)</div> |

### Setting Up !

Pour déployer cette application en environnement de développement, veuillez lire le fichier [README Webservice](/webservice/README.md) en premier afin de mettre en place le serveur web.

Puis il suffira de lancer un invité de commandes dans le répertoire du projet et de faire : ` flutter run `.
Il vous sera alors demandé sur quelle plateforme vous voulez compiler le client.

#### Utilisation d'un appareil Android
Pour que l'appareil Android puisse se connecter au webservice, il sera requis que votre appareil mobile soit sur le même réseau que votre webservice. Il vous suffira ensuite de trouver l'IP de votre webservice dans le réseau et de lancer Flutter avec cette commande au lieu de celle cité précédemment : 

` flutter run --dart-define=REMOTE_SERVER={ip_webservice} ` 

en remplaçant les éléments requis.
