# Supabase Backend – Everyday Monorepo

Questo backend utilizza **Supabase** per:

* Database (PostgreSQL)
* Auth
* Storage
* Edge Functions (Deno)
* Migrazioni SQL
* Test locale tramite Supabase CLI

---

## 📦 Struttura della cartella

```
backend/
  supabase/
    config.toml        # Configurazione Supabase
    migrations/        # Migrazioni SQL generate dal CLI
    functions/
      test/
        index.ts       # Esempio di funzione Edge funzionante
        deno.json      # Configurazione locale della funzione
    .temp/
      project-ref      # ID del progetto Supabase collegato
```

---

## ▶️ Avviare il backend in locale

Assicurati di avere Docker installato.

```
supabase start
```

Questo avvia:

* Database PostgreSQL
* Auth
* Storage
* Edge-functions runtime

---

## 🚀 Testare una funzione

Con il backend in esecuzione:

```
curl -i --request POST 'http://127.0.0.1:54321/functions/v1/test' \
  --header 'Authorization: Bearer <anon-key>' \
  --header 'Content-Type: application/json' \
  --data '{"name":"Functions"}'
```

---

## 📤 Deploy di una funzione

```
supabase functions deploy test
```

---

## 🔗 Collegare un progetto esistente

```
supabase link --project-ref <PROJECT_ID>
```

Il file `.temp/project-ref` indica che il progetto è già linkato.

---

## 🧱 Creare una nuova Edge Function

```
supabase functions new nome_funzione
```

---

## 🧪 Creare una nuova migration SQL

```
supabase migration new nome_migrazione
```

Le migrazioni saranno salvate in `/migrations`.

---

## ❗ Nota

Tutto ciò che riguarda Flutter è nella cartella `/app/everyday_app`.
Il backend è completamente isolato nel percorso `/backend/supabase`.

---

Happy building 🍃🚀
