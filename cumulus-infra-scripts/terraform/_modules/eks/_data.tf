data "aws_partition" "current" {
  provider = aws.stack
}
data "aws_caller_identity" "current" {
  provider = aws.stack
}
data "aws_region" "current" {
  provider = aws.stack
}

