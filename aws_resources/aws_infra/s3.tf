# S3 Bucket for MongoDB Backups
resource "aws_s3_bucket" "mongodb_backup" {
  bucket = "mongodb-backup-bucket-${random_id.bucket_id.hex}"

  tags = {
    Name = "mongodb-backup-bucket"
    Project = "wiz"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 8
}