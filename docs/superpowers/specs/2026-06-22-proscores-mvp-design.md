# ProScores — App mobile de pronostics (MVP)

**Date :** 2026-06-22
**Statut :** Design validé
**Emplacement projet :** `C:\Users\lucas\Desktop\B3\DevMobile\ProScores`

## 1. Vision et périmètre

Application mobile Flutter affichant les matchs à venir de la **Coupe du Monde 2026**
(compétition en cours), leurs marchés de pronostics avec probabilités, et un générateur
de combinés personnalisés à partir d'une mise, d'un objectif de gain et d'un niveau de risque.

**Dans le périmètre du MVP :**
- 3 écrans : Accueil, Détail match, Crée ton prono.
- Données réelles via The Odds API (cotes) + API-Football (fixtures + prédictions),
  appels directs depuis l'app.
- Générateur de combinés en **force brute, 2-3 jambes**.
- Message de jeu responsable.

**Hors périmètre (étapes ultérieures, non traitées ici) :**
- Scores en direct / rafraîchissement temps réel.
- Modèle Poisson maison.
- Backend proxy pour protéger les clés API.
- Persistance, favoris, historique des pronos, authentification.
- Autres compétitions que la Coupe du Monde.

## 2. Contraintes et décisions

| Sujet | Décision |
|---|---|
| Framework | Flutter 3.32.4 / Dart 3.8.1 (déjà installé) |
| Gestion d'état | **Riverpod** |
| Accès API | Appels directs depuis Flutter (projet école/prototype, risque clé assumé) |
| Clés API | Fichier `lib/config/api_keys.dart` **git-ignoré**, avec template versionné |
| Compétition | Coupe du Monde 2026 (`league_id` API-Football à confirmer au branchement) |
| Générateur | Force brute, max 3 jambes |

## 3. Design visuel

- **Couleurs :** `#202322` (sombre/fond), `#F3F9F8` (clair/cartes), `#049F7C` (teal/accent).
- **Polices :** **Outfit** (titres, poids 600-800) + **DM Sans** (texte courant).
  Cotes et pourcentages en `font-variant-numeric: tabular-nums` (chiffres alignés).
- **Thème :** sombre dominant, accents teal, cartes contrastées selon l'écran.
- Polices chargées via le package `google_fonts` (ou bundlées en assets).

## 4. Écrans et navigation

Navigation : pile simple (Navigator). Accueil → Détail match (tap sur une ligne).
Accueil → Crée ton prono (bouton fixe en bas).

### 4.1 Accueil (`HomeScreen`)
- App bar avec logo « Prono. » et avatar (placeholder).
- Liste **compacte** des matchs à venir, groupés par jour (Aujourd'hui / Demain / date).
  Chaque ligne : heure + groupe, les deux équipes (drapeau + nom),
  et à droite le **% de l'issue la plus probable** avec son libellé.
- Bouton fixe en bas **« Crée ton prono ! »** (sous-titre : mise · objectif · niveau de risque).
- États : loading (skeleton), error (message + retry), data.

### 4.2 Détail match (`MatchDetailScreen`)
- En-tête dégradé teal : bouton retour, compétition + groupe, heure de coup d'envoi,
  les deux équipes (drapeau + nom).
- Liste de **marchés**, chacun dans une carte :
  - **Résultat (1X2)** : France / Nul / adversaire.
  - **BTTS** (les deux équipes marquent) : Oui / Non.
  - **Over/Under 2.5 buts** : +2.5 / −2.5.
  - **Double chance** : 1N / 12 / N2.
- Pour chaque issue : **barre de probabilité ajustée** (en %), **cote** à droite.
- Chaque marché porte un **tag de palier de risque** (Peu risqué / Modéré / Risqué / Très risqué).
- Note de bas de page : « Proba = moyenne pondérée cotes bookmaker + API-Football »
  + message **jeu responsable**.

### 4.3 Crée ton prono (`CreatePronoScreen`) — 2 étapes
**Étape 1 — Saisie :**
- Mise de départ (€).
- Objectif de gain (€), avec **multiplicateur visé calculé automatiquement** (`objectif / mise`).
- Sélecteur de **niveau de risque** : Peu risqué (≥70%) / Modéré (50-70%) / Risqué (30-50%).
- Bouton « Générer mes combinés ».
- Message jeu responsable.

**Étape 2 — Propositions :**
- 3 combinés générés, **triés par probabilité de réussite décroissante**.
- Chaque combiné : nom + nb de jambes, % de réussite, liste des jambes (pari + cote),
  **cote totale** et **gain potentiel** (= mise × cote totale). Le meilleur est mis en avant (bordure teal).

## 5. Architecture

```
UI (screens / widgets)
   ↕  providers (Riverpod : état loading/data/error, entrées utilisateur)
Services métier (logique pure, testable sans réseau)
   ├─ ProbabilityService   → probabilité ajustée par issue
   ├─ RiskClassifier       → palier de risque à partir d'une probabilité
   └─ ComboGenerator       → force brute 2-3 jambes
Repositories (interfaces + implémentations HTTP)
   ├─ OddsRepository       → The Odds API
   └─ FootballRepository   → API-Football (fixtures + /predictions)
Clients HTTP (package http ou dio) + modèles de données
```

### 5.1 Modèles de données (immutables)
- `MatchFixture` : id, compétition, groupe, dateKickoff, homeTeam, awayTeam.
- `Team` : id, nom, code/drapeau.
- `Market` : type (1X2, BTTS, OU25, DoubleChance), liste de `Selection`.
- `Selection` : libellé, cote (`odd`), probabilité ajustée (`adjustedProbability`), palier (`RiskLevel`).
- `Prediction` : probabilités API-Football par issue.
- `Combo` : liste de jambes (`Selection` + match), cote totale, probabilité, gain potentiel.

### 5.2 ProbabilityService
1. **Proba implicite bookmaker** = `1 / cote`, puis normalisation : diviser chaque proba
   du marché par la somme des probas du marché (retire la marge du bookmaker).
2. **Proba modèle** = API-Football `/predictions`.
3. **Proba affichée** = **moyenne pondérée** des deux, **démarrage 50/50** (poids configurable
   dans un fichier de constantes pour calibrage ultérieur).

### 5.3 RiskClassifier
Palier déterminé par la **probabilité ajustée** (pas la cote brute) :

| Niveau | Probabilité ajustée |
|---|---|
| Peu risqué | ≥ 70% |
| Modéré | 50% – 70% |
| Risqué | 30% – 50% |
| Très risqué | < 30% |

### 5.4 ComboGenerator (force brute, 2-3 jambes)
**Entrées :** mise (M), gain visé (G), niveau de risque (R).
1. Multiplicateur cible = `G / M`.
2. Filtrer le pool de sélections sur le palier R.
3. Énumérer les combinaisons de 2 puis 3 jambes dont le **produit des cotes** ≈ multiplicateur
   cible (tolérance **±10%**).
4. **Règles :**
   - **Jamais deux paris sur le même match** (évite les marchés corrélés / fausse la proba jointe).
   - Probabilité du combiné = **produit des probabilités** individuelles (indépendance entre matchs).
   - Renvoyer **3 propositions** distinctes (matchs variés), triées par probabilité décroissante.
5. Si moins de 3 combinés trouvés dans la tolérance : élargir progressivement la tolérance
   et/ou signaler à l'utilisateur qu'aucun combiné exact n'existe pour ces paramètres.

### 5.5 Gestion des erreurs
- Chaque appel réseau renvoie un état `loading / data / error` exposé par un provider.
- Écran/section d'erreur avec bouton **Réessayer**.
- Cas quota dépassé / pas de réseau / réponse vide gérés explicitement (message clair).

## 6. Stratégie de tests

- **TDD sur la logique pure** (priorité) :
  - `ProbabilityService` : normalisation de la marge, moyenne pondérée.
  - `RiskClassifier` : bornes des paliers (valeurs limites 30/50/70%).
  - `ComboGenerator` : produit des cotes ≈ cible dans la tolérance, exclusion de deux paris
    sur le même match, tri par probabilité, comportement quand le pool est insuffisant.
- **Repositories** : testés avec des réponses API mockées (fixtures JSON enregistrées).
- Widgets : tests légers sur les états loading/error/data des écrans principaux.

## 7. Configuration des clés API

- `lib/config/api_keys.dart` (git-ignoré) :
  ```dart
  const oddsApiKey = '...';
  const footballApiKey = '...';
  ```
- `lib/config/api_keys.example.dart` (versionné) : même structure, valeurs vides.
- Ajouter `lib/config/api_keys.dart` et `.superpowers/` au `.gitignore`.

## 8. Étapes ultérieures (rappel, hors MVP)

- Scores et cotes en direct (polling + cache).
- Modèle Poisson maison comme 2e source de probabilité (dont BTTS via λ_home / λ_away).
- DP sur les logarithmes pour combinés 5+ jambes / gros pool.
- Backend proxy pour sécuriser les clés.
- Persistance des préférences, favoris, historique des pronos suivis.
