> ⚠️ **Docker** est <ins>**obligatoire**</ins> pour lancer le webservice, car il dépend de PostgreSQL et pour des raisons de portabilité Docker est la meilleure installation ! Le webservice et ensuite accessible par [localhost:port_du_webservice].

Les commandes suivantes se dont dans le repertoire `/webservice/`.

#### Lancement du service

⚠️ Avant de lancer le service veillez bien a ce que les **variables d'environnement** soient correctes ! Il est donc impératif de vérifier les fichiers `.env` et `docker-compose.yml` avant la première execution.

```
$ docker compose up -d
```

Le port du webservice par défaut est **5000**

#### Couper le webservice:
```
$ docker compose down -v
```

#### 🗝️ Authentification:
L'authentification se fait dans l'entête des requêtes par JWT et Bearer, il y a donc un champ dans l'entête comme suit:
```
Authorization: Bearer <TOKEN>
```
⚠️ Le token de connexion est obtenu avec la requère correspondant en dessous (dans l'entête de la réponse) !

-------------------

#### 🛣️ Liste des routes du webservice:

| **METHOD** | **URL** | **Body** | **Description** |
|-----|----------------|----------------------|---------------------|
| ***GET*** | `/ping` | `...` | Permet de ping le webservice |
| ***POST*** | `/auth/login` | `{email: string, password: string}` | Connecte un utilisateur |
| ***POST*** | `/auth/register` | `{email: string, password: string}` | Enregistre un nouvel utilisateur |
| ***GET*** | `/me` | `...` | Donne les informations de l'utilisateur actuellement connecté |
| ***GET*** | `/user/:id` | `...` | Donne les informations de l'utilisateur de l'**id** donné en adresse |
| ***POST*** | `/channel/new` | `{name: string, members: array of int}` | Créer un salon et invite tous les membres dont les ID sont dans **members** |
| ***GET*** | `/channel/info/:id` | `...` | Donne les informations d'un salon |
| ***POST*** | `/channel/invite/:channel_id/:user_id` | `...` | Invite l'utilisateur avec l'ID **user_id** dans le salon avec l'ID **channel_id** |
| ***POST*** | `/channel/kick/:channel_id/:user_id` | `...` | Expule l'utilisateur **user_id** du salon **channel_id** a condition que l'utilisateur actuel ait les droits administrateurs du salon (créateur du salon) |
| ***POST*** | `/channel/leave/:channel_id` | `...` | Vous quittez le salon **channel_id**, si vous êtes son créateur (admin), le salon est alors supprimé pour tout ses membres ! |
| ***POST*** | `/channel/send/:channel_id` | `{content: string}` | Vous envoyez un message dans le salon **channel_id** avec les contenu **content** |
| ***GET*** | `/channel/messages/:channel_id` | `...` | Récupère les 15<sup>[1]</sup> derniers messages du salon **channel_id** |
| ***DELETE*** | `/channel/messages/:channel_id/:message_id` | `...` | Supprime le message **message_id** du salon **channel_id**, vous devez avoir envoyé ce message ! |

*[1]: Un argument sera rajouté pour selectionner le nombre de messages retournés ainsi que son décalage.*

-------------------

📬 **Utilisation de Postman pour tester les routes API:**

Dans ce dossier, il est aussi possible de retrouver un fichier `flutter_api.postman_collection.json` que vous pouvez importer dans Postman, il s'agit d'une collection de requètes prédéfinies qui représentent les routes courantes !