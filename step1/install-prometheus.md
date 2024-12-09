# Instalação do Prometheus

Primeiro vamos criar o usuário de sistema `prometheus` e seus grupos.  

```plain
sudo useradd \
    --system \
    --no-create-home \
    --shell /bin/false prometheus
```{{exec}}

Download dos binários
```plain
wget https://github.com/prometheus/prometheus/releases/download/v2.44.0/prometheus-2.44.0.linux-amd64.tar.gz

```{{exec}}

Desempacotando:
```plain
tar -xvf prometheus-2.44.0.linux-amd64.tar.gz

```{{exec}}

Criando os diretórios de trabalho do Prometheus:
```plain
sudo mkdir -p /var/lib/prometheus/data 
sudo mkdir -p /etc/prometheus/console_libraries
sudo mkdir -p /etc/prometheus

```{{exec}}

Alterando o owner dos diretórios:
```
sudo chown -R prometheus:prometheus /var/lib/prometheus/data 
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown -R prometheus:prometheus /etc/prometheus

```{{exec}}

```plain
cd prometheus-2.44.0.linux-amd64

```{{exec}}

Movendo os binários para a pasta `/usr/local/bin`:
```plain
sudo mv prometheus promtool /usr/local/bin/

```{{exec}}

Alterando o owner dos binários:
```plain
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
```{{exec}}

Verificando o owner dos binários
```plain
ll /usr/local/bin/prom*
```{{exec}}

Output:
```
-rwxr-xr-x 1 prometheus prometheus 103070626 Dec 17  2021 /usr/local/bin/prometheus*
-rwxr-xr-x 1 prometheus prometheus  94996583 Dec 17  2021 /usr/local/bin/promtool*
```

Verifique se o Prometheus está disponível
```plain
prometheus --version

```{{exec}}

Movendo o template de arquivo de configuração para `/etc/prometheus`
```
sudo mv prometheus.yml /etc/prometheus/prometheus.yml
```{{exec}}


#### Configurando o prometheus com um serviço

Primeiro verifique o conteúdo do arquivo `prometheus.service`:
```
cd ~
cat prometheus.service
```{{exec}}

O output será algo assim:
```
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/data \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090 \
    --web.enable-lifecycle
   
[Install]
WantedBy=multi-user.target
```

Vamos mover esse arquivo para `/etc/systemd/system/`:
```
sudo mv prometheus.service /etc/systemd/system/
```{{exec}}

Ativando o serviço:
```
sudo systemctl enable prometheus

```{{exec}}

Inicializando o serviço:
```
sudo systemctl start prometheus

```{{exec}}

Verificando os logs do serviço:
```
journalctl -u prometheus -f --no-pager

```{{exec}}

### Interface gráfica
A partir desse ponto é possível acessar a interface gráfica do Prometheus através da porta `9090`.

- Acesse o menu "Traffic / Ports"
- Em "Custom Ports" informe 9090 e clique em Access