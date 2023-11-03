terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = ">=2.9.14"
    }
  }
}

provider "proxmox" {
  pm_debug = true
  pm_log_enable = true
  pm_log_file = var.logfile
  pm_log_levels = {
    _default = "debug"
    _capturelog = ""
  }

  pm_api_url = var.pm_api_url
  pm_tls_insecure = false
}

resource "proxmox_vm_qemu" "squid_proxy" {
  vmid        = var.vm_id_4_squid
  name        = "online-vm-${var.vm_id_4_squid}-squid-proxy.${var.domain}"
  desc        = "IC vms"
  target_node = "pve"
  os_type     = "cloud-init"

  clone       = var.template_minimal

  pool        = "IC-computing-pool"
  cores       = 4
  sockets     = 1
  memory      = 8192
  scsihw      = "virtio-scsi-single"

  sshkeys     = var.sshkeys

  ipconfig0 = format("ip=%s.%d/%d,gw=%s", var.vm_ip_prefix, var.vm_id_4_squid, var.subnet_mask, var.gateway)
  
  network {
    model   = "virtio"
    bridge  = "vmbr0"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y squid",
      "sudo systemctl enable squid",
      // Squid配置命令使用EOF标记开始和结束
      "sudo bash -c 'cat <<EOF > /etc/squid/squid.conf",
      "acl SSL_ports port 443",
      "acl Safe_ports port 80",
      "acl Safe_ports port 21",
      "acl Safe_ports port 443",
      "acl Safe_ports port 70",
      "acl Safe_ports port 210",
      "acl Safe_ports port 1025-65535",
      "acl Safe_ports port 280",
      "acl Safe_ports port 488",
      "acl Safe_ports port 591",
      "acl Safe_ports port 777",
      "acl CONNECT method CONNECT",
      "http_access deny !Safe_ports",
      "http_access deny CONNECT !SSL_ports",
      "http_access allow localhost manager",
      "http_access deny manager",
      "#acl allowed_sites dstdomain debuginfo.centos.org download.example elrepo.org linux-mirrors.fnal.gov mirror.centos.org mirrorlist.centos.org mirror.rackspace.com mirrors.coreix.net mirrors.elrepo.org elrepo.org mirrors.fedoraproject.org sourceforge.net vault.centos.org",
      "#http_access allow allowed_sites",
      "#http_access allow localhost",
      "#http_access deny all",
      "http_port 3128",
      "EOF'",
      "sudo systemctl restart squid",
      "sudo firewall-cmd --add-port=3128/tcp --permanent",
      "sudo firewall-cmd --reload",
    ]
    connection {
      type     = "ssh"
      user     = "centos"
      private_key = file("~/.ssh/id_rsa")
      host = regex("ip=(.+)/[0-9]+,gw=.+", self.ipconfig0)[0]
      port     = "22"
    }
  }
}

// provision虚拟机
resource "proxmox_vm_qemu" "nfs" {
  depends_on = [proxmox_vm_qemu.squid_proxy]

  vmid        = var.vm_id_4_nfs
  name        = "offline-vm-${var.vm_id_4_nfs}-nfs.${var.domain}"
  desc        = "IC vms"
  target_node = "pve"

  clone       = var.template_minimal

  pool        = "IC-computing-pool"
  cores       = 4
  sockets     = 1
  memory      = 8192
  scsihw      = "virtio-scsi-single"

  sshkeys     = var.sshkeys

  ipconfig0 = format("ip=%s.%d/%d,gw=%s", var.vm_ip_prefix, var.vm_id_4_nfs, var.subnet_mask, var.gateway)
  
  network {
    model   = "virtio"
    bridge  = "vmbr0"
  }

  provisioner "remote-exec" {
    // 在${var.vm_ip_prefix}.${var.vm_id_4_nfs}安装nfs服务器
    inline = [
      "echo proxy=http://${var.vm_ip_prefix}.${var.vm_id_4_squid}:3128 | sudo tee -a /etc/yum.conf",
      "sudo chmod 0600 /etc/yum.conf",
      "sudo yum install nfs-utils -y",
      "sudo systemctl enable rpcbind nfs-server --now",
      "sudo mkdir -m 0755 /tools",
      "echo '/home  *(rw,no_root_squash)' |sudo tee -a /etc/exports",
      "echo '/tools *(rw,no_root_squash)' |sudo tee -a /etc/exports",
      "sudo exportfs -r",
      "sudo firewall-cmd --permanent --add-service=nfs",
      "sudo firewall-cmd --permanent --add-service=mountd",
      "sudo firewall-cmd --permanent --add-service=rpc-bind",
      "sudo firewall-cmd --reload",
    ]
    connection {
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_rsa")
      host        = regex("ip=(.+)/[0-9]+,gw=.+", self.ipconfig0)[0]
      port        = "22"
    }
  }
}

// provision freeipa
resource "proxmox_vm_qemu" "freeipa" {
  depends_on = [
    proxmox_vm_qemu.squid_proxy,
    proxmox_vm_qemu.nfs
  ]
  vmid        = var.vm_id_4_freeipa
  name        = "offline-vm-${var.vm_id_4_freeipa}-ipa-01.${var.domain}"
  desc        = "IC vms"
  target_node = "pve"

  clone       = var.template

  pool        = "IC-computing-pool"
  cores       = 4
  sockets     = 1
  memory      = 8192
  scsihw      = "virtio-scsi-single"

  sshkeys     = var.sshkeys

  ipconfig0 = format("ip=%s.%d/%d,gw=%s", var.vm_ip_prefix, var.vm_id_4_freeipa, var.subnet_mask, var.gateway)
  
  network {
    model   = "virtio"
    bridge  = "vmbr0"
  }

  provisioner "remote-exec" {
    // 在其它上挂载它。
    inline = [
      "echo proxy=http://${var.vm_ip_prefix}.${var.vm_id_4_squid}:3128 | sudo tee -a /etc/yum.conf",
      "sudo chmod 0600 /etc/yum.conf",
      "sudo yum install nfs-utils -y",
      "sudo sed -i 's#/dev/mapper/centos-home#\\#/dev/mapper/centos-home#' /etc/fstab",
      "echo '${var.vm_ip_prefix}.${var.vm_id_4_nfs}:/tools /tools nfs defaults 0 0' | sudo tee -a /etc/fstab",
      "echo '${var.vm_ip_prefix}.${var.vm_id_4_nfs}:/home  /home  nfs defaults 0 0' | sudo tee -a /etc/fstab",
      "sudo mkdir -m 0755 /tools",
      "sudo mount /tools",
      "sudo umount -l /home",
      "sudo mount /home",
      "echo '${var.vm_ip_prefix}.${var.vm_id_4_freeipa} ipa-server-01.${var.domain}' | sudo tee -a /etc/hosts",
      "cd",
      "sudo yum install -y ipa-server ipa-server-dns",
      "sudo ipa-server-install --setup-dns --allow-zone-overlap --hostname=ipa-server-01.${var.domain} --domain=${var.domain} --realm=ICINFRA.CN --ds-password=12345678 --admin-password=12345678 --no-forwarders --auto-reverse --unattended",
      "sudo systemctl enable firewalld --now",
      "sudo firewall-cmd --add-port=80/tcp --add-port=443/tcp --add-port=389/tcp --add-port=636/tcp --add-port=88/tcp --add-port=464/tcp --add-port=53/tcp --add-port=88/udp --add-port=464/udp --add-port=53/udp --add-port=123/udp --permanent",
      "sudo firewall-cmd --reload",
      "kinit admin <<EOF",
      "12345678",
      "EOF",
      "ipa user-add lsfadmin --first=lsf --last=admin",
    ]
    connection {
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_rsa")
      host        = regex("ip=(.+)/[0-9]+,gw=.+", self.ipconfig0)[0]
      port        = "22"
    }
  }
}

// provision computing server
resource "proxmox_vm_qemu" "computing" {
  depends_on = [
    proxmox_vm_qemu.squid_proxy,
    proxmox_vm_qemu.nfs,
    proxmox_vm_qemu.freeipa,
  ]
  vmid        = var.vm_id_start + count.index
  name        = "offline-vm-${var.vm_id_start + count.index}-computing.${var.domain}"
  desc        = "IC vms"
  target_node = "pve"

  count       = var.vm_count
  clone       = var.template

  pool        = "IC-computing-pool"
  cores       = 4
  sockets     = 1
  memory      = 8192
  scsihw      = "virtio-scsi-single"

  sshkeys     = var.sshkeys

  ipconfig0 = format("ip=%s.%d/%d,gw=%s", var.vm_ip_prefix, var.vm_id_start + count.index, var.subnet_mask, var.gateway)
  
  network {
    model   = "virtio"
    bridge  = "vmbr0"
  }

  provisioner "remote-exec" {
    // 在其它上挂载它。
    inline = [
      "sudo sed -i 's#^nameserver 172.16.0.1$#nameserver ${var.vm_ip_prefix}.${var.vm_id_4_freeipa}#g' /etc/resolv.conf",
      "echo proxy=http://${var.vm_ip_prefix}.${var.vm_id_4_squid}:3128 | sudo tee -a /etc/yum.conf",
      "sudo chmod 0600 /etc/yum.conf",
      "sudo yum install nfs-utils -y",
      "sudo sed -i 's#/dev/mapper/centos-home#\\#/dev/mapper/centos-home#' /etc/fstab",
      "echo '${var.vm_ip_prefix}.${var.vm_id_4_nfs}:/tools /tools nfs defaults 0 0' | sudo tee -a /etc/fstab",
      "echo '${var.vm_ip_prefix}.${var.vm_id_4_nfs}:/home  /home  nfs defaults 0 0' | sudo tee -a /etc/fstab",
      "sudo mkdir -m 0755 /tools",
      "sudo mount /tools",
      "sudo umount -l /home",
      "sudo mount /home",
      "echo '${var.vm_ip_prefix}.${var.vm_id_4_freeipa} ipa-server-01.${var.domain}' | sudo tee -a /etc/hosts",
      "cd",
      "sudo yum install -y ipa-client",
      "sudo ipa-client-install --server=ipa-server-01.${var.domain} --domain=${var.domain} --realm=ICINFRA.CN --principal=admin --password=12345678 --unattended",
    ]
    connection {
      type        = "ssh"
      user        = "centos"
      private_key = file("~/.ssh/id_rsa")
      host        = regex("ip=(.+)/[0-9]+,gw=.+", self.ipconfig0)[0]
      port        = "22"
    }
  }
}
