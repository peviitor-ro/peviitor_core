# TESTS.md — Verificare configurare test environment

## 1. Solr local

```bash
# Verifică disponibilitate
curl -s -u ${{ secrets.SOLR_USER }}:${{ secrets.SOLR_PASS }} "http://localhost:8983/solr/" | python3 -m json.tool

# Verifică core-ul job
curl -s -u ${{ secrets.SOLR_USER }}:${{ secrets.SOLR_PASS }} "http://localhost:8983/solr/job/select?q=*:*&wt=json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f'job core: {d[\"response\"][\"numFound\"]} documente')
"

# Verifică core-ul company
curl -s -u ${{ secrets.SOLR_USER }}:${{ secrets.SOLR_PASS }} "http://localhost:8983/solr/company/select?q=*:*&wt=json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f'company core: {d[\"response\"][\"numFound\"]} documente')
"

# Verifică suggest
curl -s -u ${{ secrets.SOLR_USER }}:${{ secrets.SOLR_PASS }} "http://localhost:8983/solr/job/suggest?suggest=true&suggest.build=true&suggest.dictionary=jobTitleSuggester&suggest.q=sofer&wt=json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
sug=d['suggest']['jobTitleSuggester']['sofer']
print(f'suggest: {sug[\"numFound\"]} rezultate')
for s in sug['suggestions']:
    print(f'  -> {s[\"term\"]}')
"
```

**Rezultat așteptat:** Fiecare comandă returnează `"status": 0` și date valide.

---

## 2. API local

```bash
# jobs
curl -s "http://localhost:8081/v1/jobs/" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f'/v1/jobs/: {d[\"response\"][\"numFound\"]} joburi')
"

# total
curl -s "http://localhost:8081/v1/total/"
# Așteptat: {"total":{"jobs":1,"companies":1}}

# search
curl -s "http://localhost:8081/v1/search/?q=sofer" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f'/v1/search/: {d[\"response\"][\"numFound\"]} rezultate')
"

# suggest
curl -s "http://localhost:8081/v1/suggest/?q=sofer" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f'/v1/suggest/: {len(d[\"suggestions\"])} sugestii')
for s in d['suggestions']:
    print(f'  -> {s[\"term\"]}')
"

# random
curl -s "http://localhost:8081/v1/random/" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f'/v1/random/: {d.get(\"job_title\",\"N/A\")}')
"

# company
curl -s "http://localhost:8081/v1/company/?cif=12477373" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f'/v1/company/: {d[\"company\"][\"company\"]}')
"

# v0 jobs
curl -s -o /dev/null -w "/v0/jobs/: HTTP %{http_code}" "http://localhost:8081/v0/jobs/"
echo

# v0 total
curl -s -o /dev/null -w "/v0/total/: HTTP %{http_code}" "http://localhost:8081/v0/total/"
echo
```

**Toate trebuie să returneze HTTP 200** și JSON valid.

---

## 3. Swagger UI local

```bash
# Pagina
curl -s -o /dev/null -w "HTTP %{http_code}" "http://localhost:8081/swagger-ui/"
echo

# Spec
curl -s -o /dev/null -w "HTTP %{http_code}" "http://localhost:8081/v1/swagger.json"
echo
```

**Așteptat:** ambele HTTP 200. Deschide `http://localhost:8081/swagger-ui/` în browser și verifică că:
- Se încarcă interfața Swagger
- Se vede spec-ul API (endpoint-urile listate)
- Apăsând "Try it out" pe un endpoint funcționează (ex: `/v1/total/`)

---

## 4. Test extern

```bash
# test.peviitor.ro
for ep in "v1/jobs/" "v1/total/" "v1/random/" "v1/suggest/?q=sofer" "v0/jobs/" "v0/total/" "swagger-ui/" "v1/swagger.json"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://test.peviitor.ro/$ep" 2>&1)
  echo "https://test.peviitor.ro/$ep -> HTTP $code"
done

# testsolr.peviitor.ro
curl -s -u ${{ secrets.SOLR_USER }}:${{ secrets.SOLR_PASS }} -o /dev/null -w "https://testsolr.peviitor.ro/solr/ -> HTTP %{http_code}\n" "https://testsolr.peviitor.ro/solr/"
curl -s -u ${{ secrets.SOLR_USER }}:${{ secrets.SOLR_PASS }} "https://testsolr.peviitor.ro/solr/job/select?q=*:*&rows=1&wt=json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f'Solr extern: {d[\"response\"][\"numFound\"]} documente in job')
"
```

**Așteptat:** toate endpoint-urile returnează HTTP 200.

---

## 5. Test CORS (pentru Swagger UI din browser)

```bash
# Verifică header-ele CORS
curl -s -D - "http://localhost:8081/v1/suggest/?q=sofer" 2>&1 | grep -i "access-control"
```

**Așteptat:** `Access-Control-Allow-Origin: *` prezent în răspuns.

---

## 6. Test container status

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep peviitor
```

**Așteptat:** ambele containere (`peviitor-solr`, `peviitor-api`) în stare `Up`.

---

## 7. Test securitate — credentiale în fișiere

```bash
# Rulează din rădăcina proiectului
repo_root="/home/sebi/opencode-ai/peviitor_test_env"

# Caută `SOLR_PASS=` urmat de un șir care nu e gol și nu e placeholder
echo "=== Scan credentiale ==="
matches=$(grep -rn "SOLR_PASS=" "$repo_root" \
  --include="*.sh" --include="*.yml" --include="*.md" --include="*.json" \
  --include="Dockerfile*" 2>/dev/null | grep -v 'SOLR_PASS=$' \
  | grep -v "SECURITY.md\|TESTS.md")

if [ -n "$matches" ]; then
  echo "FAILED — credentiale găsite:"
  echo "$matches"
  exit 1
else
  echo "PASSED — nici un credential în fișierele trackabile"
fi

# Verifică că api.env nu conține credentiale reale
echo ""
echo "=== Verificare api.env credentials ==="
if grep -q "SOLR_PASS=" "$repo_root/api.env" 2>/dev/null && \
   ! grep -q "SOLR_PASS=$" "$repo_root/api.env" 2>/dev/null; then
  echo "FAILED — api.env are credentiale completate!"
  exit 1
else
  echo "PASSED — api.env are valori goale sau nu există"
fi
```

**Așteptat:** ambele verificări afișează `PASSED`.

---

## Rezolvare probleme comune

| Problemă | Cauză posibilă | Soluție |
|----------|---------------|---------|
| API returnează 503 / "FETCH FAILED" | Containerul API nu ajunge la Solr | Verifică `api.env`: `PROD_SERVER=host.docker.internal:8983`; asigură-te că `extra_hosts` are `host.docker.internal:host-gateway` în docker-compose |
| API returnează 401 Unauthorized | Credențiale Solr greșite | Verifică `SOLR_USER` / `SOLR_PASS` în `api.env` |
| Solr suggest returnează 0 rezultate | Suggesterul nu e construit | Trimite `suggest.build=true` o dată (endpoint-ul PHP o face automat) |
| Swagger UI nu se încarcă | Cale greșită | Asigură-te că fișierele sunt în `api/swagger-ui/` (volume-mountate) |
| testsolr.peviitor.ro/swagger-ui/ 404 | Swagger UI nu mai e pe testsolr | Folosește `test.peviitor.ro/swagger-ui/` |
