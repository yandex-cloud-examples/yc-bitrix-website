variable "folder_id" {
  type = string
}

variable "vm_user" {
  type = string
}

variable "ssh_key_path" {
  type = string
}

variable "mysql_user" {
  type = string
}

variable "mysql_password" {
  type = string
  sensitive = true
}

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.47.0"
    }
  }
}

provider "yandex" {
  zone = var.folder_id
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}

resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.2.0/24"]
}

resource "yandex_vpc_subnet" "subnet-3" {
  name           = "subnet3"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.3.0/24"]
}

resource "yandex_vpc_security_group" "sg-vm" {
  name        = "bitrix-sg-vm"
  description = "Description for security group"
  network_id  = yandex_vpc_network.network-1.id

  egress {
    protocol       = "ANY"
    description    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    protocol       = "TCP"
    description    = "EXT-HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "EXT-SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "EXT-HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }
}

resource "yandex_vpc_security_group" "sg-mysql" {
  name        = "bitrix-sg"
  description = "Security group for mysql"
  network_id  = yandex_vpc_network.network-1.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-msql"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3306
  }
}

data "yandex_compute_image" "ubuntu-image" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_disk" "boot-disk" {
  name     = "bootdisk"
  type     = "network-ssd"
  zone     = "ru-central1-a"
  size     = "24"
  image_id = yandex_compute_image.ubuntu-image.id
}

resource "yandex_compute_instance" "vm-bitrix" {
  name        = "bitrixwebsite"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 4
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-1.id
    security_group_ids = ["${yandex_vpc_security_group.sg-vm.id}"]
    nat                = true
  }

  metadata = {
     user-data = "#cloud-config\nusers:\n  - name: ${var.vm_user}\n    groups: sudo\n    shell: /bin/bash\n    sudo: 'ALL=(ALL) NOPASSWD:ALL'\n    ssh-authorized-keys:\n      - ${file("${var.ssh_key_path}")}"
  }
}

resource "yandex_mdb_mysql_cluster" "bitrix-cluster" {
  name               = "BitrixMySQL"
  environment        = "PRESTABLE"
  network_id         = yandex_vpc_network.network-1.id
  version            = "8.0"
  security_group_ids = ["${yandex_vpc_security_group.sg-mysql.id}"]

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-hdd"
    disk_size          = "10"
  }

  host {
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.subnet-1.id
    assign_public_ip = false
  }

  host {
    zone             = "ru-central1-b"
    subnet_id        = yandex_vpc_subnet.subnet-2.id
    assign_public_ip = false
  }
}

resource "yandex_mdb_mysql_database" "bitrix-db" {
  cluster_id = yandex_mdb_mysql_cluster.bitrix-cluster.id
  name       = "db1"
}

resource "yandex_mdb_mysql_user" "bitrix-user" {
  cluster_id = yandex_mdb_mysql_cluster.bitrix-cluster.id
  name       = var.mysql_user
  password   = var.mysql_password
  permission {
    database_name = yandex_mdb_mysql_database.bitrix-db.name
    roles         = ["ALL"]
  }
}
