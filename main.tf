terraform {
      required_providers {
    aws = ">= 3.0.0"
  }
}
provider "aws" {
    profile = "dahaba"
    region = "us-east-1"
}

resource "aws_s3_bucket" "kbd_web_hosting" {
    bucket = "kbdwebhostingbucket"
    tags = {
      Name = "KBD bucket"
    }  
}


resource "aws_s3_bucket_website_configuration" "web_hosting" {
    bucket = aws_s3_bucket.kbd_web_hosting.id
    index_document {
      suffix = "index.html"
    }
}


resource "aws_s3_bucket_public_access_block" "web-hosting-public-access" {
    bucket = aws_s3_bucket.kbd_web_hosting.id
    block_public_acls = false
    block_public_policy = false
    restrict_public_buckets = false
    ignore_public_acls = false
}


resource "aws_s3_bucket_policy" "web-hosting-policy" {
    bucket = aws_s3_bucket.kbd_web_hosting.id
    policy = data.aws_iam_policy_document.policy.json
}


resource "aws_s3_bucket_ownership_controls" "bucket_owner" {
  bucket = aws_s3_bucket.kbd_web_hosting.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "s3_acl" {

  depends_on = [ 
    aws_s3_bucket_ownership_controls.bucket_owner,
    aws_s3_bucket_public_access_block.web-hosting-public-access ]
  bucket = aws_s3_bucket.kbd_web_hosting.id
  acl = "public-read" 
}


data "aws_iam_policy_document" "policy" {
    statement {
        principals {
            type = "*"
            identifiers = ["*"]
        }
        effect = "Allow"
        actions = [
            "s3:GetObject"
        ]
        resources = [
            "${aws_s3_bucket.kbd_web_hosting.arn}/*"
        ]
    }
}
module "template_files" {
  source = "hashicorp/dir/template"

  base_dir = "./web_site/"
  
}
resource "aws_s3_object" "my-web-site" {
    for_each =  module.template_files.files
    bucket = aws_s3_bucket.kbd_web_hosting.id
    key = each.key
    content_type = each.value.content_type
    source = each.value.source_path
    content = each.value.content
    
    # etag = filemd5(each.value)
}

# resource "aws_s3_object" "my-web-site" {
#     for_each = fileset("./web_site/", "**")
#     bucket = aws_s3_bucket.kbd_web_hosting.id
#     key = each.value 
#     content_type = "text/html"
#     source = "./web_site/${each.value}"  
#     # etag = filemd5(each.value)
# }

output "website_endpoint" {
  value = aws_s3_bucket.kbd_web_hosting.website_endpoint
}

output "bucket_domain_name" {
  value = aws_s3_bucket.kbd_web_hosting.bucket_domain_name
}
