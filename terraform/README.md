```terraform
terraform {
  backend "s3" {
    bucket         = "<bucket-name>"
    key            = "terraform.state"
    region         = var.aws_region
    dynamodb_table = "terraform-lock"
  }
}
```

```terraform
resource "aws_dynamodb_table" "terraform-lock" {
name = "terraform-lock"
hash_key = "LockID"
read_capacity = 20
write_capacity = 20

attribute {
name = "LockID"
type = "S"
}
}
```
