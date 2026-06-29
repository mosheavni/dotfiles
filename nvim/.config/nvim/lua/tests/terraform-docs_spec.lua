local terraform_docs = require 'user.terraform-docs'
local eq = assert.are.same

describe('user.terraform-docs', function()
  describe('doc_type_slug', function()
    it('strips provider prefix for HashiCorp-style providers', function()
      eq(terraform_docs.doc_type_slug('aws', 'aws_instance', 'instance'), 'instance')
    end)

    it('keeps full resource name for configured providers', function()
      eq(
        terraform_docs.doc_type_slug('confluent', 'confluent_private_link_attachment_connection', 'private_link_attachment_connection'),
        'confluent_private_link_attachment_connection'
      )
    end)
  end)

  describe('build_url', function()
    it('builds HashiCorp-style registry URLs', function()
      eq(
        terraform_docs.build_url {
          source = 'hashicorp',
          provider_prefix = 'aws',
          resource_id = 'aws_instance',
          type_suffix = 'instance',
          url_type = 'resources',
        },
        'https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance'
      )
    end)

    it('builds full-name registry URLs for configured providers', function()
      eq(
        terraform_docs.build_url {
          source = 'confluentinc',
          provider_prefix = 'confluent',
          resource_id = 'confluent_private_link_attachment_connection',
          type_suffix = 'private_link_attachment_connection',
          url_type = 'resources',
        },
        'https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_private_link_attachment_connection'
      )
    end)
  end)
end)
