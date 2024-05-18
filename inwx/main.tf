terraform {
  required_providers {
    inwx = {
      source  = "inwx/inwx"
      version = ">= 1.0.0"
    }
  }
}

locals {
  domain = "tomaskala.com"

  mx_records = [
    {
      content = "in1-smtp.messagingengine.com"
      prio    = 10
    },
    {
      content = "in2-smtp.messagingengine.com"
      prio    = 20
    },
  ]

  txt_records = [
    {
      name    = null
      content = "v=spf1 include:spf.messagingengine.com ?all"
    },
    {
      name    = "_dmarc"
      content = "v=DMARC1;p=none;ruf=mailto:postmaster@tomaskala.com"
    },
  ]

  cname_records = [
    {
      name    = "fm1._domainkey"
      content = "fm1.tomaskala.com.dkim.fmhosted.com"
    },
    {
      name    = "fm2._domainkey"
      content = "fm2.tomaskala.com.dkim.fmhosted.com"
    },
    {
      name    = "fm3._domainkey"
      content = "fm3.tomaskala.com.dkim.fmhosted.com"
    },
  ]
}

provider "inwx" {
  api_url  = "https://api.domrobot.com/jsonrpc/"
  username = var.username
  password = var.password
  tan      = var.tan
}

resource "inwx_domain_contact" "tomas_kala" {
  type             = "PERSON"
  name             = "Tomáš Kala"
  street_address   = var.street_address
  city             = var.city
  postal_code      = var.postal_code
  country_code     = var.country_code
  phone_number     = var.phone_number
  email            = var.email
  whois_protection = true
}

resource "inwx_domain" "tomaskala_com" {
  name          = local.domain
  nameservers   = ["ns.inwx.de", "ns2.inwx.de", "ns3.inwx.eu"]
  period        = "2Y"
  renewal_mode  = "AUTORENEW"
  transfer_lock = true
  contacts {
    registrant = inwx_domain_contact.tomas_kala.id
    admin      = inwx_domain_contact.tomas_kala.id
    tech       = inwx_domain_contact.tomas_kala.id
    billing    = inwx_domain_contact.tomas_kala.id
  }
  extra_data = {
    "WHOIS-PROTECTION" : true
  }
}

resource "inwx_nameserver_record" "tomaskala_com_a" {
  domain  = local.domain
  type    = "A"
  content = "37.205.9.85"
  ttl     = 3600
}

resource "inwx_nameserver_record" "tomaskala_com_aaaa" {
  domain  = local.domain
  type    = "AAAA"
  content = "2a03:3b40:fe:c7::1"
  ttl     = 3600
}

resource "inwx_nameserver_record" "tomaskala_com_caa" {
  domain  = local.domain
  type    = "CAA"
  content = "0 issue \"letsencrypt.org\""
  ttl     = 3600
}

resource "inwx_nameserver_record" "tomaskala_com_mx" {
  count = length(local.mx_records)

  domain  = local.domain
  type    = "MX"
  content = local.mx_records[count.index].content
  prio    = local.mx_records[count.index].prio
  ttl     = 3600
}

resource "inwx_nameserver_record" "tomaskala_com_txt" {
  count = length(local.txt_records)

  domain  = local.domain
  type    = "TXT"
  name    = local.txt_records[count.index].name
  content = local.txt_records[count.index].content
  ttl     = 3600
}

resource "inwx_nameserver_record" "tomaskala_com_cname" {
  count = length(local.cname_records)

  domain  = local.domain
  type    = "CNAME"
  name    = local.cname_records[count.index].name
  content = local.cname_records[count.index].content
  ttl     = 3600
}
