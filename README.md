# Создание сайта на базе «1С-Битрикс»

[«1С-Битрикс: Управление сайтом»](https://www.1c-bitrix.ru/products/cms/) — это система управления веб-проектами от компании «1С-Битрикс». С его помощью вы можете достаточно просто управлять структурой и содержимым вашего сайта, не обладая специальными знаниями программирования и верстки. Техническую часть работы за вас выполнит «1С-Битрикс: Управление сайтом».

Из этого руководства вы узнаете, как развернуть и настроить сайт, используя шаблон информационного портала на платформе «1С-Битрикс». В процессе настройки вы создадите [виртуальную машину](https://yandex.cloud/ru/docs/compute/concepts/vm) в инфраструктуре Yandex Cloud, на которой развернете [образ](https://yandex.cloud/ru/docs/compute/concepts/image) платформы «1С-Битрикс» и требуемые для нее сервисы. В качестве базы данных вами будет развернут кластер [Yandex Managed Service for MySQL®](https://yandex.cloud/ru/docs/managed-mysql) с возможностью обеспечения его отказоустойчивости.

Используемые ресурсы для правильной работы «1С-Битрикс»:
* ВМ на базе [Ubuntu 22.04 LTS](https://yandex.cloud/ru/marketplace/products/yc/ubuntu-22-04-lts) с доступом во внешнюю [сеть](https://yandex.cloud/ru/docs/vpc/concepts/network#network), на которой будет установлен «1С-Битрикс».
* Кластер Managed Service for MySQL®, являющийся БД для сайта «1С-Битрикс».

Создание инфраструктуры с помощью Terraform описано в [практическом руководстве](https://yandex.cloud/ru/docs/tutorials/web/bitrix-website/terraform), необходимые для настройки файлы `bitrix-website.tf` и `bitrix-website.auto.tfvars` расположены в этом репозитории.
