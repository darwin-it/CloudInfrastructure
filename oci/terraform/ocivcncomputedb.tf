/*
Issues
Issue 1
 creating an igw_route table requires a route table rule with destination
 Error: Service error:InvalidParameter. routeRules[0].destination size must be between 1 and 255. 
  http status code: 400. Opc request id: 1a07fc0e653f6c63b599cb2d7bc658e1/132B86250515E30D30043BEE00227B8F/A62FB312580EF51178B8445999952C29
  on ocivcncomputedb.tf line 82, in resource "oci_core_route_table" "fb_igw_route_table":
  82: resource "oci_core_route_table" "fb_igw_route_table" {
Links
. https://console.eu-frankfurt-1.oraclecloud.com/?tenant=darwin&provider=OracleIdentityCloudService
. https://www.terraform.io/docs/providers/oci/index.html
  can be repated for each oci resource
*/
# variable section
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "profile" {}
variable "vcn_cidr_block" {}
variable "vcn_display_name" {}
variable "compartment_ocid" {}
variable "vcn_dns_label" {}
variable "internet_gateway_display_name" {}
variable "internet_gateway_enabled" {}
variable "nat_gateway_display_name" {}
variable "public_subnet_cidr_block" {}
variable "subnet_availability_domain_1" {}
variable "public_subnet_display_name" {}
variable "public_subnet_dns_label" {}
variable "subnet_prohibit_public_ip_on_vnic" {}
variable "igw_route_table_display_name" {}

# Provider and aws credentials and region settings
provider "oci" {
  # compartment_ocid = var.compartment_ocid
  tenancy_ocid = var.tenancy_ocid
  user_ocid = var.user_ocid
  fingerprint = var.fingerprint
  private_key_path = var.private_key_path
  region = var.region
}
# Get a list of Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}
# Output the result
output "show-ads" {
  value = data.oci_identity_availability_domains.ads.availability_domains
}

# Create a new VCN
# https://www.terraform.io/docs/providers/oci/r/core_vcn.html
resource "oci_core_vcn" "fb_vcn" {
    #Required
    cidr_block = var.vcn_cidr_block
    compartment_id = var.compartment_ocid
    #Optional
    #defined_tags = {"IaC.Provider"= "TF"}
    display_name = var.vcn_display_name
    dns_label = var.vcn_dns_label
    freeform_tags = {"student"= "fb"}
}
# Create a new igw
# https://www.terraform.io/docs/providers/oci/r/core_internet_gateway.html
resource "oci_core_internet_gateway" "fb_internet_gateway" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.fb_vcn.id
    #Optional
    display_name = var.internet_gateway_display_name
    enabled = var.internet_gateway_enabled
    freeform_tags = {"student"= "fb"}
}
# Create a new ngw
# https://www.terraform.io/docs/providers/oci/r/core_nat_gateway.html
resource "oci_core_nat_gateway" "fb_nat_gateway" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.fb_vcn.id
    #Optional
    display_name = var.nat_gateway_display_name
    freeform_tags = {"student"= "fb"}
}

# Create a new igw_route table
# https://www.terraform.io/docs/providers/oci/r/core_route_table.html
resource "oci_core_route_table" "fb_igw_route_table" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.fb_vcn.id
    #Optional
    display_name = var.igw_route_table_display_name
    freeform_tags = {"student"= "fb"}
    route_rules {
        #Required
        network_entity_id = oci_core_internet_gateway.fb_internet_gateway.id
        # Optional
        # cidr_block = "${var.route_table_route_rules_cidr_block}"
        # description = "${var.route_table_route_rules_description}"
        # destination = "${var.route_table_route_rules_destination}"
        # destination_type = "${var.route_table_route_rules_destination_type}"
    }
}
# Create a new public subnet
# https://www.terraform.io/docs/providers/oci/r/core_subnet.html
resource "oci_core_subnet" "fb_public_subnet" {
    #Required
    cidr_block = var.public_subnet_cidr_block
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.fb_vcn.id
    #Optional
    #availability_domain = var.subnet_availability_domain_1 -- as in regional
    display_name = var.public_subnet_display_name
    dns_label = var.public_subnet_dns_label
    prohibit_public_ip_on_vnic = var.subnet_prohibit_public_ip_on_vnic
    route_table_id = oci_core_route_table.fb_igw_route_table.id
    #security_list_ids = "${var.subnet_security_list_ids}" - default seclist
}

