#!/usr/bin/env bash
produtos=("TV" "GELADEIRA" "TV" "HOMETHEATER" "COMPUTADOR" "MONITOR" "TABLET" "SOUNDBAR" "CELULAR" "NOTEBOOK")
while(true)
do
    if [ $(expr $i % 2 ) != "0" ]; then
        echo "Quantity ``${RANDOM:0:2}``" | curl --data-binary @- http://localhost:9090/metrics/job/pedidos/pais/BR/produto/${produtos[${RANDOM:0:1}]}
    else
        echo "Quantity ``${RANDOM:0:2}``" | curl --data-binary @- http://localhost:9090/metrics/job/pedidos/pais/US/produto/${produtos[${RANDOM:0:1}]}
    fi
    sleep 0.05
done
