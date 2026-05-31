# SECURITY.md — Politica de securitate pentru credentiale

## Regula de bază
**Nici un fișier din acest repository nu trebuie să conțină credentiale reale** (utilizator, parolă, token, cheie API, etc.) în clar.

## Verificare obligatorie după fiecare modificare

Rulează această comandă înainte de orice commit:

```bash
# Caută orice șir care ar putea fi o parolă reală în fișiere trackabile
# Caută `SOLR_PASS=` urmat de un șir care nu e gol și nu e placeholder
grep -rn "SOLR_PASS=" /home/sebi/opencode-ai/peviitor_test_env/ \
  --include="*.sh" --include="*.yml" --include="*.md" --include="*.json" \
  --include="Dockerfile*" | grep -v 'SOLR_PASS=$'
```

**Rezultat așteptat:** nici o linie afișată (empty output).

Dacă apare vreun rezultat, oprește commit-ul și înlocuiește credentialele cu placeholder-e:
- parole reale → `${{ secrets.SOLR_PASS }}` sau `your_password_here`
- nume utilizator real (în context credential) → `${{ secrets.SOLR_USER }}`

## Fișiere în repo care NU conțin credentiale

| Fișier | Conținut |
|--------|----------|
| `api.env` | Template cu valori goale (`SOLR_USER=`, `SOLR_PASS=`) — completat local de utilizator |

Orice fișier `api.env` cu credentiale reale trebuie păstrat în afara acestui folder (ex: `/home/sebi/peviitor/config/api.env`) și referit în `docker-compose.yml` cu path absolut.

## Ce conțin credentiale

- **Plaintext:** orice parolă reală, token, sau cheie API
- **Hash-uri de parole** în `security.json` (considerate credentiale derivate)
- **Token-uri, chei API, chei SSH**

## Placeholder-e permise

| Context | Format |
|---------|--------|
| Fișiere markdown (documentație) | `${{ secrets.SOLR_USER }}`, `${{ secrets.SOLR_PASS }}` |
| Scripturi bash | `$SOLR_USER`, `$SOLR_PASS` (cu `change_me` ca default) |
| Fișiere exemplu (`*.example`) | `your_solr_password_here` |
