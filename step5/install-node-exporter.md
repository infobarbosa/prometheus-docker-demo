# Instalação do Node Exporter

```
cd ~
```{{exec}}

Criando um usuário de sistema operacional para o Node Exporter:
```
sudo useradd \
    --system \
    --no-create-home \
    --shell /bin/false node_exporter
```{{exec}}

Obtendo os binários do repositório:
```
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.0/node_exporter-1.6.0.linux-amd64.tar.gz
```{{exec}}

Desempacotando:
```
tar -xvf node_exporter-1.6.0.linux-amd64.tar.gz

```{{exec}}

Movendo os binários para `/usr/local/bin`:
```
sudo mv \
  node_exporter-1.6.0.linux-amd64/node_exporter \
  /usr/local/bin/

```{{exec}}

Alterando o owner:
```
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

```{{exec}}

Verificando a instalação:
```
node_exporter --version

```{{exec}}

#### Configurando o Node Exporter como um serviço

Verifique o conteúdo do arquivo node_exporter.service
```
cat node_exporter.service

```{{exec}}

O output será algo assim:
```
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter \
    --collector.logind

[Install]
WantedBy=multi-user.target

```

Movendo `node_exporter.service` para `/etc/systemd/system/`:
```
sudo mv node_exporter.service /etc/systemd/system/

```{{exec}}

Ativando o serviço
```
sudo systemctl enable node_exporter

```{{exec}}

Inicializando o serviço:
```
sudo systemctl start node_exporter

```{{exec}}

Verificando o status do serviço:
```
sudo systemctl status node_exporter

```{{exec}}

Verificando os logs do serviço:
```
sudo journalctl -u node_exporter -f --no-pager
```{{exec}}

### Interface gráfica
É possível verificar as métricas coletadas pelo Node Exporter acessando a porta `9100`.
- Acesse o menu "Traffic / Ports"
- Em "Custom Ports" informe 9100 e clique em Access
