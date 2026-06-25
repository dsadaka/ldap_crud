# frozen_string_literal: true

# app/models/ldap_record.rb

class LdapRecord
  include ActiveModel::Model

  USER_ATTRIBUTES = %i[mail uid givenName fullName sn ou customer_id].freeze
  FIXED_OBJECT_CLASSES = %w[inetOrgPerson organizationalPerson Person Top ndsLoginProperties].freeze

  attr_accessor :dn, *USER_ATTRIBUTES

  validates :mail, :ou, :customer_id, :sn, presence: true

  # Ensure the submitted 'ou' exactly matches one of the strings returned by service_levels
  validates :ou, inclusion: {
    in: ->(record) { record.service_levels },
    message: "must be a valid service level"
  }

  # Populates the select tag for Service Level
  def service_levels
    ['Basic', 'Full']
  end

  # Populates the select tag for Customer
  def customer_list
    LdapService.new.search_active_customers.map(&:ou).map {|c| c.reverse}
  end

  # Returns a unique, web-safe string for HTML attributes
  def to_param_id
    # If uid has spaces or odd characters, parameterize cleans them into 'first-last'
    dn.to_s.parameterize
  end

  # Dynamically construct the DN
  def dn
    if mail.present? && customer_id.present?
      "uid=#{mail},ou=#{customer_id},ou=SPAMFILTER,O=DKI"
    else
      @dn
    end
  end

  # Dynamically construct the multi-valued CN
  def cn
    return nil if mail.blank? || ou.blank?

    [mail, "Spamfilter #{ou} User"]
  end

  def objectClass
    FIXED_OBJECT_CLASSES
  end

  # Build the payload for creating a record
  def attributes_for_create
    attrs = {
      objectClass: objectClass,
      cn: cn
    }

    USER_ATTRIBUTES.each do |attr|
      next if attr == :customer_id

      value = send(attr)
      attrs[attr] = Array(value).reject(&:blank?) unless value.blank?
    end

    attrs
  end

  # Build the payload for updating a record
  def build_update_operations
    operations = []

    ldap_attributes = (USER_ATTRIBUTES - [:customer_id]) + [:objectClass, :cn]

    ldap_attributes.each do |attr|
      value = send(attr)
      next if value.nil?

      formatted_values = Array(value).reject(&:blank?)
      operations << [:replace, attr, formatted_values]
    end

    operations
  end

  # Factory method to populate a record from an LDAP entry
  def self.from_entry(entry)
    new(
      dn: entry.dn,
      mail: extract_first(entry, :mail),
      uid: extract_first(entry, :uid),
      givenName: extract_first(entry, :givenname),
      fullName: extract_first(entry, :fullname),
      sn: extract_first(entry, :sn),
      ou: extract_first(entry, :ou),
      customer_id: extract_customer_id(entry.dn)
    )
  end

  private

  def self.extract_first(entry, attribute)
    entry.respond_to?(attribute) ? entry.send(attribute).first : nil
  end

  def self.extract_customer_id(dn)
    match = dn.match(/ou=([^,]+),ou=SPAMFILTER/i)
    match ? match[1] : nil
  end
end