
variable "routing" {
  type = object({
    src_rt_ids = list(object({
      name = string,
      id   = string,
    })),
    dst_rt_ids = list(object({
      name = string,
      id   = string,
    })),
    src_cidr              = string,
    dst_cidr              = string,
    peering_connection_id = string,
    name                  = string
  })
}