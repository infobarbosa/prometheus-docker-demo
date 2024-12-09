
import random
import time
import requests

produtos = ["TV", "GELADEIRA", "TV", "HOMETHEATER", "COMPUTADOR", "MONITOR", "TABLET", "SOUNDBAR", "CELULAR", "NOTEBOOK"]

while True:
    quantity = random.randint(0, 99)
    produto = produtos[random.randint(0, 9)]
    #requests.post(f'http://localhost:9091/metrics/job/pedidos/pais/BR/produto/{produto}', data=f'Quantity {quantity}')
    #requests.post(f'http://localhost:9091/metrics/job/pedidos/pais/US/produto/{produto}', data=f'Quantity {quantity}')
    response = requests.post(f'http://localhost:9091/metrics/job/pedidos/pais/AU/produto/{produto}', data=f'Quantity {quantity}')
    print(response.text)
    time.sleep(0.05)