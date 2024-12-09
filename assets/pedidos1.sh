#!/usr/bin/env bash
produtos=("TV" "GELADEIRA" "TV" "HOMETHEATER" "COMPUTADOR" "MONITOR" "TABLET" "SOUNDBAR" "CELULAR" "NOTEBOOK")
while(true)
do
    echo "Quantity ``${RANDOM:0:2}``" | curl --data-binary @- http://localhost:9091/metrics/job/pedidos/produto/${produtos[${RANDOM:0:1}]}

    sleep 0.05
done
