variable "pm_api_url" {
  default = "https://pve.icinfra.cn:8006/api2/json"
}

variable "template_minimal" {
  default = "CentOS7-tmpl-cloudinit-minimal"
}

variable "template" {
  default = "CentOS7-tmpl-cloudinit-gui-5.4.258-firefox-and-chinese"
}

variable "domain" {
  default = "icinfra.cn"
}

variable "vm_ip_prefix" {
  default = "172.16.0"
}

variable "vm_id_4_squid" {
  default = 191
}

variable "vm_id_4_nfs" {
  default = 192
}

variable "vm_id_4_freeipa" {
  default = 193
}

variable "vm_id_start" {
  default = 194
}

variable "vm_count" {
  default = 5
}

variable "subnet_mask" {
  default = 24
}

variable "gateway" {
  default = "172.16.0.1"
}

variable "logfile" {
  default = "terraform-plugin-proxmox.log"
}

variable "sshkeys" {
  default = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDCvUUEDM+i9W+nI+l9m0Li1JlHDuj9HQAYiXjmKj+lawAi91sVp7N/29O+h31Go9w06goFpBIAysmQM2uFNGLjxGsmmb7EJ9ssoz4VEAaWWpRyATnMSqO4EVBqXDU6+kmnjuKtB+nb2PdQKlFyD9zPaDKPkxyPhWHCVu/RAQyPN+1rM9EyWe/m3a0+E/7My3pEcBByYmfFoy5kgVgMVhvw7bMwicAgHvYsR+s/xqOAkz0nUSQxpYjSl5miH2xiOvPSEPIm4Q/hCX0ULNIJvI4MXVF2ZyCXHis6irDBK4ZzHe9RYSwKPJ5+DPea8cZvDXELXBws2RlrW/Vlf2NbQUzfqj2+BNnJPRNd8w51s0W1qMeJt5SFIBomWFi8PV8jF3G6His92gptwJTTxMWypBxqtHOE42xIPJtFj+LE9mDFmq7A4UY6h0Q4ZBfumw0cHsUX9dW5x7r4SouIuUh8eqm3RqTEoJs7KZaxdeXldXOja6JXTIxi0wjw1CtVnrQkWfs= wanlinwang@pve
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDX8Pt9gNqRH+TwnnQSaM10GGJOeCy8wB4emrRdyvAoyhrpNvCcC5b+lXxf7XwYcEC27FUFMsgjkqp4MRbeV+YDqO0aO8w0Q60oSgHd6AaYz+svkOthl62jR8Taah9WYhAMfHoAH9aXICUE4xik5zDfJx9q+IixeZfdGilEclVuqyS9sspcegbS7IPqXdxDwQq5PGvE7Jc5QrGkUBwF2tFXen5MPdtpXMyt/rUAZMmUPG8xMpkbDbgljhLxyogIlkIvhV3qmxqQpZp3kTpHMFo2ot7OJ/jKmDxR3lrh+OAzxDPpiGAWoldu9i7NqYoxzyeCED5E+t6Q7epqlwg4nBDk2G3uAE7bFNQPqbjW4SKHyqqOogCVOFxVzN73ADQwrKB5RJ8ielE5Eyv7eVe2cYgchKcvZOt3ml0VOLKgIELOHE6p8638iq2+N4mjFtlKjLRe+jzpUTDLUxJ/Uxt80unodmJRShMbEUr1UhJ06cPnpn5p3PeQ6ScmYQH3s4Ph6qM= wanlinwang@MacBook-Pro.lan
EOF
}
