variable "location" {}
variable "resource_group_name" {}
# Flow Logs Target (Just one for now in the module logic, or we can make it a list/dynamic? 
# The existing logic had single 'target_nsg_id'. 
# For multiple flow logs, it's better to instantiate the flow_log resource multiple times or use for_each. 
# SIMPLIFICATION: We will keep 'target_nsg_id' for the Hub WAF, and create SEPARATE flow logs in root logic or make this module handle a map.
# Let's add a new variable for Connection Monitor:
variable "target_nsg_id" {
  description = "Legacy single NSG target (WAF)"
}

variable "source_vm_id" {
  description = "Source VM ID for Connection Monitor"
}
