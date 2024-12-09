# Produzindo métricas customizadas

O objetivo desta sessão é produzir métricas customizadas como simulação de um cenário do mundo real onde queremos monitorar a evolução de vendas de produtos.

Voltando ao diretório `/home/ubuntu`:
```
cd ~
```{{exec}}

Analisando o conteúdo do script `pedidos1.sh`:
```
cat pedidos1.sh
```{{exec}}

O output será algo como:
```
#!/usr/bin/env bash
produtos=("TV" "GELADEIRA" "TV" "HOMETHEATER" "COMPUTADOR" "MONITOR" "TABLET" "SOUNDBAR" "CELULAR" "NOTEBOOK")
while(true)
do
    echo "Quantity ``${RANDOM:0:2}``" | curl --data-binary @- http://localhost:9091/metrics/job/pedidos/produto/${produtos[${RANDOM:0:1}]}

    sleep 0.05
done
```

Executando o script:
```
nohup ./pedidos1.sh &
```{{exec}}

Para verificar se o script está executando:
```
ps aux | grep -i pedidos1.sh
```{{exec}}
