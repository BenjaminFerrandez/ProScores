# ProScores — serveur backend (proxy + cache)

Petit serveur Dart (`shelf`) qui se place **entre l'app et les APIs externes** :

- 🔑 **Les clés API ne sont plus dans l'app** — elles vivent uniquement ici (`lib/secrets.dart`, git-ignoré).
- 💾 **Cache SQLite** (`cache.db`) avec une durée de vie par type de donnée : ce qui ne bouge pas (id d'équipe, effectifs, drapeaux, confrontations) est servi depuis le cache → bien moins de requêtes payantes.
- 🛠️ Endroit idéal pour **traiter les données** côté serveur plus tard.

## Démarrer

```bash
cd server
cp lib/secrets.example.dart lib/secrets.dart   # puis colle tes clés dedans
dart pub get
dart run bin/server.dart
```

Le serveur écoute sur `http://localhost:8080`.

> **Windows** : `sqlite3.dll` est fourni dans ce dossier (chargé automatiquement).
> **Android emulator** : l'app doit viser `http://10.0.2.2:8080` (voir `kServerBaseUrl` dans l'app).

## Endpoints

| Route | Source | Cache (TTL) |
|---|---|---|
| `GET /health` | — | live |
| `GET /odds/worldcup` | The Odds API | 5 min |
| `GET /football/teams/search?name=` | API-Football | **∞** (l'id ne change jamais) |
| `GET /football/teams/:id/players?season=&page=` | API-Football | 1 jour |
| `GET /football/teams/:id/fixtures?season=` | API-Football | 6 h |
| `GET /football/h2h?home=&away=` | API-Football | 7 jours |
| `GET /football/fixtures/:id/prediction` | API-Football | 6 h |
| `GET /football/worldcup/fixtures?season=&league=` | API-Football | 1 h |

Chaque réponse renvoie un en-tête `X-Cache: HIT|MISS` (et `X-Cache-Age` en secondes sur un HIT).

## Comment ça marche

`server/bin/server.dart` définit les routes ; chaque route appelle `_cached(clé, ttl, fetch)` :
1. si une entrée fraîche existe en base → renvoyée directement (aucun appel externe) ;
2. sinon → appel à l'API externe (`lib/upstream.dart`, seul endroit avec les clés), mise en cache, réponse.

Le corps renvoyé est le **JSON brut** de l'API externe, pour que l'app garde son parsing existant.
