# frozen_string_literal: true

# app/services/ldap_service.rb

require 'net/ldap'

class LdapService
  attr_reader :error_message
  BASE_CONTEXT = 'ou=SPAMFILTER,o=DKI'.freeze
  def initialize(client_ou = nil)
    # Configure your connection to the OES server here.
    # By initializing this here, we ensure a fresh connection is prepped 
    # whenever the service is called.
    @ldap = Net::LDAP.new(
      host: 'mail.datakey.cc',
      port: 389, # Swap to 636 for LDAPS in production
      auth: {
        method: :simple,
        username: 'cn=admin,o=bbg',
        password: 'oftheproblem'
      }
    )
    @client_ou = client_ou
  end

  def add_record(dn:, attributes:)
    if @ldap.add(dn: dn, attributes: attributes)
      true
    else
      @error_message = @ldap.get_operation_result.message
      false
    end
  end

  def update_record(dn:, attribute_name:, attribute_value:)
    if @ldap.replace_attribute(dn, attribute_name, attribute_value)
      true
    else
      @error_message = @ldap.get_operation_result.message
      false
    end
  end

  def delete_record(dn:)
    if @ldap.delete(dn: dn)
      true
    else
      @error_message = @ldap.get_operation_result.message
      false
    end
  end
  # READ: Search for multiple records using a standard LDAP filter string
  def search(filter_string: '(objectClass=inetOrgPerson)')
    filter = Net::LDAP::Filter.construct(filter_string)
    records = []

    # The search method yields each entry it finds to the block
    @ldap.search(base: BASE_CONTEXT, filter: filter) do |entry|
      records << entry
    end

    if @ldap.get_operation_result.code == 0
      records
    else
      @error_message = @ldap.get_operation_result.message
      nil
    end
  end

  # READ: Find a single record by its Common Name (CN) within the base context
  def find_by_cn(cn:)
    filter = Net::LDAP::Filter.eq('cn', cn)
    records = []

    @ldap.search(base: BASE_CONTEXT, filter: filter) do |entry|
      records << entry
    end

    if @ldap.get_operation_result.code == 0
      records.first # Returns the single Net::LDAP::Entry object, or nil if none found
    else
      @error_message = @ldap.get_operation_result.message
      nil
    end
  end

  # READ: Find an exact record using its full Distinguished Name (DN)
  def find_by_dn(dn:)
    records = []

    # To search by an exact DN, we use the DN as the base and restrict the scope
    # to only that specific base object, rather than searching the whole tree.
    @ldap.search(base: dn, scope: Net::LDAP::SearchScope_BaseObject) do |entry|
      records << entry
    end

    if @ldap.get_operation_result.code == 0
      records.first
    else
      @error_message = @ldap.get_operation_result.message
      nil
    end
  end
end
