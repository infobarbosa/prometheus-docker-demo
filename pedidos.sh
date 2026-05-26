#!/bin/sh
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-http://localhost:9091}"
JOB="${JOB:-pedidos}"

PRODUTOS="TV GELADEIRA HOMETHEATER COMPUTADOR MONITOR TABLET SOUNDBAR CELULAR NOTEBOOK"
PAISES="BR US AU"
N_PRODUTOS=9
N_PAISES=3

get_item() {
    echo "$1" | cut -d' ' -f$(( ($2 % $3) + 1 ))
}

echo "Iniciando produtor de pedidos -> ${PUSHGATEWAY_URL}/metrics/job/${JOB}"

i=0
while true; do
    produto=$(get_item "$PRODUTOS" $RANDOM $N_PRODUTOS)
    pais=$(get_item "$PAISES" $RANDOM $N_PAISES)
    quantidade=$(( (RANDOM % 10) + 1 ))
    preco=$(( (RANDOM % 9500) + 500 ))

    printf \
        '# HELP pedidos_quantidade Quantidade de itens no pedido\n# TYPE pedidos_quantidade gauge\npedidos_quantidade{produto="%s",pais="%s"} %d\n# HELP pedidos_preco Preco do pedido em reais\n# TYPE pedidos_preco gauge\npedidos_preco{produto="%s",pais="%s"} %d\n' \
        "$produto" "$pais" "$quantidade" "$produto" "$pais" "$preco" \
        | curl -sf --data-binary @- \
            "${PUSHGATEWAY_URL}/metrics/job/${JOB}/produto/${produto}/pais/${pais}" || true

    i=$(( i + 1 ))
    if [ $(( i % 20 )) -eq 0 ]; then
        printf '[%s] %d pedidos enviados (ultimo: produto=%s pais=%s quantidade=%d preco=%d)\n' \
            "$(date -u +%H:%M:%SZ)" "$i" "$produto" "$pais" "$quantidade" "$preco"
    fi

    sleep 1
done
