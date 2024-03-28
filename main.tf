resource "aws_s3_bucket" "brattin-test1-s3" {
   bucket = "brattin-test1-s3"

   tags = {
     Name        = "My first bucket"
     Environment = "Dev"
   }
}