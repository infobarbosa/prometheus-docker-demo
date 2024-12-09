# Instalação do Pushgateway

```
cd ~
```{{exec}}

Criando um usuário de sistema operacional para o Pushgateway:
```
sudo useradd \
    --system \
    --no-create-home \
    --shell /bin/false pushgateway
```{{exec}}

Baixando o binário do Pushgateway:
```
wget https://github.com/prometheus/pushgateway/releases/download/v1.4.2/pushgateway-1.4.2.linux-amd64.tar.gz
```{{exec}}

Desempacotando:
```
tar -xvf pushgateway-1.4.2.linux-amd64.tar.gz

```{{exec}}

Movendo os binários para `/usr/local/bin`:
```
sudo mv pushgateway-1.4.2.linux-amd64/pushgateway /usr/local/bin/

```{{exec}}

Alterando o owner:
```
sudo chown pushgateway:pushgateway /usr/local/bin/pushgateway

```{{exec}}

Verificando a instalação:
```
pushgateway --version

```{{exec}}

#### Configurando o Pushgateway como um serviço

Verificando o conteúdo de `pushgateway.service`:
```
cd ~
cat pushgateway.service

```{{exec}}

O output será algo assim:
```
[Unit]
Description=Pushgateway
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=pushgateway
Group=pushgateway
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/pushgateway

[Install]
WantedBy=multi-user.target

```

Movendo o arquivo de configuração de serviço para `/etc/systemd/system/`:
```
sudo mv pushgateway.service /etc/systemd/system/pushgateway.service

```{{exec}}


Ativando o serviço:
```
sudo systemctl enable pushgateway

```{{exec}}

Inicializando o serviço:
```
sudo systemctl start pushgateway

```{{exec}}

Verificando o status do serviço:
```
sudo systemctl status pushgateway

```{{exec}}

Verificando os logs do serviço
```
sudo journalctl -u pushgateway -f --no-pager
```{{exec}}

### Configurando o Pushgateway
Nessa sessão vamos conectar o Pushgateway ao Prometheus

```
cd ~
```{{exec}}

```
mv ~/prometheus-com-pushgateway.yml /etc/prometheus/prometheus.yml
```{{exec}}

O novo arquivo apenas acrescenta o trecho a seguir às configurações do `Prometheus`:
```
  - job_name: pushgateway
    honor_labels: true
    static_configs:
      - targets: ["localhost:9091"]
```

Ao final o arquivo `prometheus.yml` fica assim:
```
...
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: pushgateway
    honor_labels: true
    static_configs:
      - targets: ["localhost:9091"]

```

Recarregando configurações:
```
promtool check config /etc/prometheus/prometheus.yml

```{{exec}}

```
curl -X POST http://localhost:9090/-/reload

```{{exec}}

### Interface gráfica
A partir desse ponto é possível acessar a interface gráfica do Pushgateway através da porta `9091`.
- Acesse o menu "Traffic / Ports"
- Em "Custom Ports" informe 9091 e clique em Access