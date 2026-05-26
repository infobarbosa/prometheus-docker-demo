# Monitoramento de Séries Temporais com Prometheus

Author: Prof. Barbosa<br>
Contact: infobarbosa@gmail.com<br>
Github: [infobarbosa](https://github.com/infobarbosa)

O objetivo deste laboratório é oferecer ao aluno um ambiente de familiarização com o modelo de monitoramento de séries temporais utilizando **Prometheus**.

## Introdução

[Prometheus](https://prometheus.io/docs/introduction/overview/) é um banco de dados de série temporal open source desenvolvido originalmente pelo SoundCloud e atualmente mantido pela Cloud Native Computing Foundation (CNCF). Ele coleta métricas em formato de texto a partir de endpoints HTTP expostos pelos serviços monitorados, armazena essas métricas localmente e oferece uma linguagem de consulta própria chamada **PromQL**.<br>
> Fonte: [Wikipedia](https://en.wikipedia.org/wiki/Prometheus_(software))

### Arquitetura básica

```
[Aplicação / Script]
        |
        v (HTTP POST)
  [Pushgateway :9091]   <--- scrape (HTTP GET) --- [Prometheus :9090]
                                                          |
                                              [Grafana :3000] (dashboard)
```

O **Pushgateway** é usado quando o sistema produtor de métricas não pode ser consultado diretamente pelo Prometheus (por exemplo, scripts de curta duração, batch jobs). A aplicação empurra (*push*) as métricas para o Pushgateway, que as disponibiliza para o Prometheus fazer o *scrape*.

---

## Exposition Format (Formato de Exposição)

O Prometheus define um formato de texto simples para exposição de métricas chamado **Exposition Format**. Qualquer serviço que exponha métricas nesse formato pode ser monitorado pelo Prometheus.

### Sintaxe

```
# HELP <metric_name> <descrição legível>
# TYPE <metric_name> <tipo>
<metric_name>{<label_key>="<label_value>"[,...]} <valor> [<timestamp_ms>]
```

Onde:

- `# HELP` (não obrigatório, mas recomendado) — descrição em texto livre da métrica.

- `# TYPE` (não obrigatório, mas recomendado) — tipo da métrica: `counter`, `gauge`, `histogram`, `summary` ou `untyped`.

- `<metric_name>` (obrigatório) — nome da métrica. Deve seguir a regex `[a-zA-Z_:][a-zA-Z0-9_:]*`. Convenção: `<namespace>_<subsistema>_<nome>_<unidade>`.

- `{<label_key>="<label_value>"}` (não obrigatório) — conjunto de rótulos (labels) no formato chave-valor que identificam a dimensão da métrica. Valores de labels são sempre strings entre aspas duplas.

- `<valor>` (obrigatório) — valor numérico em ponto flutuante (ex.: `1`, `3.14`, `NaN`, `+Inf`).

- `[<timestamp_ms>]` (não obrigatório) — timestamp em milissegundos desde Unix epoch. Quando omitido, o Prometheus usa o instante do scrape.

**Exemplo:**
```
# HELP pedidos_quantidade Quantidade de itens no pedido
# TYPE pedidos_quantidade gauge
pedidos_quantidade{produto="GELADEIRA",pais="BR"} 3
# HELP pedidos_preco Preco do pedido em reais
# TYPE pedidos_preco gauge
pedidos_preco{produto="GELADEIRA",pais="BR"} 4500
```

### Tipos de métricas

| Tipo | Descrição | Uso típico |
|---|---|---|
| **Counter** | Valor que só aumenta | Total de requisições, erros acumulados |
| **Gauge** | Valor que sobe e desce | Temperatura, tamanho de fila, quantidade em estoque |
| **Histogram** | Distribuição de valores em buckets | Latência de requisições, tamanho de respostas |
| **Summary** | Quantis calculados no cliente | Latência percentil (p50, p95, p99) |

---

## Laboratório

### 1. Ambiente

Este laboratório pode ser executado em qualquer estação de trabalho com Docker disponível.<br>
Recomendo a execução em Linux.<br>
Caso você não tenha um à sua disposição, utilize o serviço **AWS Cloud9**. As instruções podem ser encontradas [aqui](https://github.com/infobarbosa/data-engineering-cloud9).


### 2. Setup (APENAS PARA AWS CLOUD9)

Baixe e execute o script de setup

```bash
wget https://raw.githubusercontent.com/infobarbosa/prometheus-docker-demo/main/assets/cloud9.sh

```

```bash
bash ./cloud9.sh

```

**Atenção!**<br>
Ao final da execução do script serão disponibilizados os URLs de acesso. Copie e guarde-os porque vamos utilizá-los mais tarde neste laboratório.

Output esperado:
```
### Atualizando o sistema ###
...
Acesse o Prometheus em:   http://ec2-34-238-49-243.compute-1.amazonaws.com:9090
Acesse o Pushgateway em:  http://ec2-34-238-49-243.compute-1.amazonaws.com:9091
Acesse o Grafana em:      http://ec2-34-238-49-243.compute-1.amazonaws.com:3000
```

Caso precise recuperar o DNS público:
```bash
export CLOUD9_EC2_INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data//instance-id)
export CLOUD9_EC2_PUBLIC_DNS=$(aws ec2 describe-instances --instance-id $CLOUD9_EC2_INSTANCE_ID | jq -r .Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicDnsName)
echo "DNS público: $CLOUD9_EC2_PUBLIC_DNS"

```

### 3. Docker Compose

Por simplicidade, vamos utilizar Prometheus, Pushgateway e Grafana em containers baseados em *Docker*.

#### Baixe os arquivos necessários
```bash
wget https://raw.githubusercontent.com/infobarbosa/prometheus-docker-demo/main/compose.yaml
wget https://raw.githubusercontent.com/infobarbosa/prometheus-docker-demo/main/prometheus.yml
wget https://raw.githubusercontent.com/infobarbosa/prometheus-docker-demo/main/pedidos.sh
wget https://raw.githubusercontent.com/infobarbosa/prometheus-docker-demo/main/grafana-datasource.yaml

```

```bash
ls -la compose.yaml prometheus.yml pedidos.sh grafana-datasource.yaml

```

#### Inicialização
```bash
docker compose up -d

```

Este comando inicializa quatro serviços:
- **`prometheus-demo`**: o banco de dados Prometheus, acessível na porta `9090`. Faz scrape das métricas a cada 15 segundos.
- **`pushgateway-demo`**: gateway de recepção de métricas enviadas por push, acessível na porta `9091`.
- **`pedidos-producer`**: produtor de dados que gera pedidos simulados e os envia continuamente ao Pushgateway, permitindo visualizar dados em tempo real.
- **`grafana-demo`**: plataforma de visualização de dashboards, acessível na porta `3000`. Explorada na seção bônus ao final do laboratório.

#### Verificar status dos containers
```bash
docker compose ps

```

#### Acompanhar logs do produtor
```bash
docker compose logs -f pedidos-producer

```

---

### 4. Enviando métricas ao Pushgateway

O Pushgateway recebe métricas via HTTP POST no endpoint `/metrics/job/<job_name>`. O corpo da requisição deve estar no **Exposition Format** do Prometheus.

#### Sintaxe

```
POST /metrics/job/<job_name>[/<label_key>/<label_value>...]
Content-Type: text/plain

# HELP <metric_name> <descrição>
# TYPE <metric_name> <tipo>
<metric_name>{<labels>} <valor>
```

> **Nota:** As métricas enviadas ficam disponíveis no Pushgateway até serem substituídas por uma nova chamada ao mesmo job, ou explicitamente deletadas via DELETE.

---

#### Exemplo 1 — Métrica única (gauge)

> O segmento `/produto/GELADEIRA/pais/BR` na URL define o **grupo** desta métrica no Pushgateway. Cada grupo é independente — um POST a um grupo não afeta os outros.

```bash
cat <<'EOF' | curl -sf --data-binary @- http://localhost:9091/metrics/job/pedidos/produto/GELADEIRA/pais/BR
# HELP pedidos_quantidade Quantidade de itens no pedido
# TYPE pedidos_quantidade gauge
pedidos_quantidade{produto="GELADEIRA",pais="BR"} 1
# HELP pedidos_preco Preco do pedido em reais
# TYPE pedidos_preco gauge
pedidos_preco{produto="GELADEIRA",pais="BR"} 4500
EOF

```

---

#### Exemplo 2 — Múltiplas combinações produto/país (um POST por grupo)

```bash
cat <<'EOF' | curl -sf --data-binary @- http://localhost:9091/metrics/job/pedidos/produto/TV/pais/US
# HELP pedidos_quantidade Quantidade de itens no pedido
# TYPE pedidos_quantidade gauge
pedidos_quantidade{produto="TV",pais="US"} 2
# HELP pedidos_preco Preco do pedido em reais
# TYPE pedidos_preco gauge
pedidos_preco{produto="TV",pais="US"} 5000
EOF

cat <<'EOF' | curl -sf --data-binary @- http://localhost:9091/metrics/job/pedidos/produto/NOTEBOOK/pais/AU
# HELP pedidos_quantidade Quantidade de itens no pedido
# TYPE pedidos_quantidade gauge
pedidos_quantidade{produto="NOTEBOOK",pais="AU"} 1
# HELP pedidos_preco Preco do pedido em reais
# TYPE pedidos_preco gauge
pedidos_preco{produto="NOTEBOOK",pais="AU"} 8000
EOF

```

---

#### Exemplo 3 — Consultar métricas armazenadas no Pushgateway

```bash
curl -s http://localhost:9091/metrics | grep pedidos

```

---

### 5. PromQL — Consultas básicas

O Prometheus disponibiliza a linguagem de consulta **PromQL** (Prometheus Query Language). As consultas podem ser feitas pela UI web ou via HTTP API.

Para os exemplos abaixo, acesse a UI do Prometheus em `http://localhost:9090` e use o campo de expressão.

#### Sintaxe

```
<metric_name>{<label_filter>[,...]}
```

#### Exemplo 4 — Todas as amostras da métrica

```promql
pedidos_quantidade
```

---

#### Exemplo 5 — Filtrar por produto

```promql
pedidos_quantidade{produto="TV"}
```

---

#### Exemplo 6 — Filtrar por país

```promql
pedidos_quantidade{pais="BR"}
```

---

#### Exemplo 7 — Filtrar por produto E país

```promql
pedidos_quantidade{produto="GELADEIRA",pais="BR"}
```

---

#### Exemplo 8 — Filtro por expressão regular

```promql
pedidos_quantidade{produto=~"TV|NOTEBOOK|TABLET"}
```

---

### 6. Especificando o período

Em PromQL, o operador de intervalo `[<duração>]` seleciona um vetor de amostras dentro de uma janela de tempo relativa ao instante de avaliação.

#### Sintaxe

```
<metric_name>[<duration>]
```

Onde `<duration>` segue o formato `<número><unidade>`:  `s` (segundos), `m` (minutos), `h` (horas), `d` (dias).

#### Exemplo 9 — Amostras dos últimos 5 minutos

```promql
pedidos_quantidade[5m]
```

> **Atenção:** Vetores de intervalo (range vectors) não podem ser plotados diretamente como gráfico — são usados como entrada para funções como `rate()` e `increase()`.

---

#### Exemplo 10 — Variação do valor nos últimos 5 minutos

> `delta()` retorna a diferença entre o primeiro e o último valor dentro da janela. Correto para métricas do tipo **gauge**.

```promql
delta(pedidos_quantidade[5m])
```

---

#### Exemplo 11 — Média dos valores na última 1 hora

```promql
avg_over_time(pedidos_quantidade[1h])
```

---

### 7. Agregações PromQL

#### Exemplo 12 — Total de pedidos por produto

```promql
sum by (produto) (pedidos_quantidade)
```

---

#### Exemplo 13 — Total de pedidos por produto e país

```promql
sum by (produto, pais) (pedidos_quantidade)
```

---

#### Exemplo 14 — Top 3 produtos com maior quantidade

```promql
topk(3, sum by (produto) (pedidos_quantidade))
```

---

#### Exemplo 15 — Média de preço por produto

```promql
avg by (produto) (pedidos_preco)
```

---

#### Exemplo 16 — Total de receita por país

```promql
sum by (pais) (pedidos_preco)
```

---

#### Exemplo 17 — Média de quantidade por produto nos últimos 5 minutos

```promql
avg by (produto) (avg_over_time(pedidos_quantidade[5m]))
```

---

#### Exemplo 18 — Variação de quantidade do Brasil nos últimos 30 minutos

```promql
sum by (produto) (delta(pedidos_quantidade{pais="BR"}[30m]))
```

---

## HTTP API do Prometheus

O Prometheus disponibiliza uma API HTTP REST em `/api/v1/` para consultas programáticas.

### Consulta instantânea (`/api/v1/query`)

Retorna o valor das métricas no instante atual (ou em um instante específico via `time=`).

#### Sintaxe

```
GET /api/v1/query?query=<promql>&[time=<timestamp>]
```

#### Exemplo 19 — Todas as amostras de pedidos_quantidade

```bash
curl -s -G 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=pedidos_quantidade'

```

---

#### Exemplo 20 — Soma de pedidos por produto

```bash
curl -s -G 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=sum by (produto) (pedidos_quantidade)'

```

---

#### Exemplo 21 — Top 3 produtos

```bash
curl -s -G 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=topk(3, sum by (produto) (pedidos_quantidade))'

```

---

### Consulta por intervalo (`/api/v1/query_range`)

Retorna uma série de pontos para plotar gráficos.

#### Sintaxe

```
GET /api/v1/query_range?query=<promql>&start=<ts>&end=<ts>&step=<duration>
```

#### Exemplo 22 — Taxa de pedidos nos últimos 30 minutos (resolução de 1 minuto)

```bash
curl -s -G 'http://localhost:9090/api/v1/query_range' \
  --data-urlencode 'query=sum by (produto) (rate(pedidos_quantidade[5m]))' \
  --data-urlencode "start=$(date -u -d '30 minutes ago' +%s)" \
  --data-urlencode "end=$(date -u +%s)" \
  --data-urlencode 'step=60'

```

---

## Prometheus UI

O Prometheus disponibiliza uma interface web de exploração de dados e gráficos.

### Acessando a Prometheus UI

- Abra o navegador e acesse `http://localhost:9090` (ou o endereço do ambiente Cloud9).
- A interface não exige login (laboratório sem autenticação).

### Graph

- Acesse a aba **Graph**.
- No campo de expressão, insira uma query PromQL e clique em **Execute**.
- Alterne entre as abas **Table** (valores pontuais) e **Graph** (série temporal).

```promql
sum by (produto) (pedidos_quantidade)
```

```promql
sum by (pais) (rate(pedidos_quantidade[5m]))
```

### Status dos Targets

- Acesse **Status > Targets** para verificar se o Prometheus está fazendo scrape corretamente do Pushgateway.
- O target `pushgateway` deve aparecer com estado **UP**.

---

## Bônus: Grafana

O Grafana é uma plataforma open source de visualização amplamente usada para criar dashboards. Ele já está disponível como parte do ambiente deste laboratório.

### Acessando o Grafana

- Abra o navegador e acesse `http://localhost:3000` (ou substitua `localhost` pelo endereço do ambiente Cloud9).
- Usuário: `admin` | Senha: `admin`.

### Datasource já configurado

O datasource do Prometheus já está configurado automaticamente via provisionamento — o arquivo `grafana-datasource.yaml` é lido pelo Grafana na inicialização. Não é necessária nenhuma configuração manual na interface.

Para confirmar, acesse **Connections > Data Sources** e você verá o datasource **Prometheus** já listado e funcional.

### Criando um painel simples

1. Clique em **+** no menu lateral > **New Dashboard > Add visualization**.
2. Selecione o data source **Prometheus**.
3. No editor de query, insira:

```promql
sum by (produto) (pedidos_quantidade)
```

4. Em **Legend**, insira `{{produto}}` para nomear cada série pelo produto.
5. Clique em **Run queries** para visualizar o gráfico de pedidos por produto em tempo real.

#### Sugestões de painéis adicionais

```promql
# Receita total por país
sum by (pais) (pedidos_preco)
```

```promql
# Top 3 produtos mais vendidos
topk(3, sum by (produto) (pedidos_quantidade))
```

```promql
# Taxa de pedidos por produto (por segundo)
sum by (produto) (rate(pedidos_quantidade[5m]))
```

---

## Parabéns!

Parabéns por concluir o laboratório de Monitoramento de Séries Temporais com Prometheus! Você aprendeu como utilizar o Prometheus para coletar, armazenar e consultar métricas de séries temporais usando PromQL. Continue praticando e explorando as funcionalidades do Prometheus e do Grafana para aprimorar ainda mais seus conhecimentos.

Se tiver dúvidas ou sugestões, sinta-se à vontade para entrar em contato.

Bom trabalho e até a próxima!

Prof. Barbosa
