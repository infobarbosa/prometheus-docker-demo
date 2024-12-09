# Instalação do Grafana

```
cd ~
```{{exec}}

Criando um usuário de sistema operacional para o Grafana:
```
sudo useradd \
    --system \
    --no-create-home \
    --shell /bin/false grafana
```{{exec}}

Instalando dependências:
```
sudo apt install -y apt-transport-https software-properties-common

```{{exec}}

Importando a GPG key:
```
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

```{{exec}}

Adicionando o repositório do grafana:
```
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

```{{exec}}

Atualizando a lista de pacotes:
```
sudo apt update -y
```{{exec}}

Executando a instalação:
```
sudo apt -y install grafana
```{{exec}}

Ativando o serviço
```
sudo systemctl enable grafana-server

```{{exec}}

Inicializando o serviço
```
sudo systemctl start grafana-server

```{{exec}}

Verificando o status do serviço
```
sudo systemctl status grafana-server

```{{exec}}

Verificando os logs do serviço
```
sudo journalctl -u grafana-server -f --no-pager
```{{exec}}

### Interface gráfica
- Acesse o menu "Traffic / Ports"
- Em "Custom Ports" informe `3000` (porta padrão do Grafana) e clique em Access
- Na tela do Grafana procure o menu "Data Sources"
- No campo "URL" informe "http://localhost:9090"
- Clique em "Save & test"
