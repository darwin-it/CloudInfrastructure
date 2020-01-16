# darwin
tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaa6jjldfvjyf7sjmmnq6gltqetamqeizj5fkuxazlmaxh7mbmgrkpa"
# frank.brink@darwin-it.nl
user_ocid    = "ocid1.user.oc1..aaaaaaaa4ofrc45on4jgzvxjs6vugt4m4obfuaxlj62wgmdcbbjhctneibiq"
# mederck8s
compartment_ocid = "ocid1.compartment.oc1..aaaaaaaad2wnxlyd7j4pjx2i6i6osj5bkxkcbewqpzspqaymgjtujhqjpixq"
fingerprint  = "8c:dd:4f:4a:dd:7b:4b:25:40:96:39:fb:db:ce:67:0c"
private_key_path ="C:/Users/frank.brink/.oci/oci_api_key.pem"
region    = "eu-frankfurt-1"
profile   = "DEFAULT"
vcn_cidr_block = "10.90.0.0/16"
vcn_display_name = "fb_vcn"
vcn_dns_label = "medreck8sfb"
internet_gateway_display_name = "fb_igw"
internet_gateway_enabled = "true"
nat_gateway_display_name = "fb_ngw"
public_subnet_cidr_block = "10.90.0.0/24"
subnet_availability_domain_1 = "MUFn:EU-FRANKFURT-1-AD-1"
public_subnet_display_name = "fb_public_subnet"
public_subnet_dns_label = "bastionhost"
subnet_prohibit_public_ip_on_vnic = "false"
igw_route_table_display_name = "fb_igw_route_table"

key_name  = "fbkeypair" 
cidrs     = ["10.0.0.0/16", "10.1.0.0/16"]
az1a      = "eu-central-1a"
az1b      = "eu-central-1b"
az1c      = "eu-central-1c"
my_ip     = ["62.251.83.160/32"]
privsnas1_cidr = "10.90.1.0/24"
privsnas2_cidr = "10.90.2.0/24"
privsnrds1_cidr = "10.90.3.0/24"
privsnrds2_cidr = "10.90.4.0/24"
pre_fix = "fb_"