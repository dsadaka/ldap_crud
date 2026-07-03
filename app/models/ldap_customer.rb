# frozen_string_literal: true

# app/models/ldap_customer.rb
class LdapCustomer
  include ActiveModel::Model

  # Added :domain_name
  attr_accessor :customer_id, :customer_name, :domain_name, :mx_record, :email, :phone,
                :street, :city, :state, :zipcode, :status, :dn
  
  validates :customer_id, presence: true, format: {
    with: /\A[a-zA-Z0-9\-_]+\z/,
    message: "can only contain letters, numbers, hyphens, and underscores"
  }
  validates :customer_name, presence: true
  validates :domain_name, presence: true
  validates :mx_record, presence: true
  validates :email, presence: true
  validates :phone, presence: true
  
    def build_create_attributes
      attrs = {
        "objectClass" => ["top", "organizationalUnit"],
        "ou"          => [customer_id.to_s, customer_name.to_s]
      }

      # 2. Hardcode the default status to 'active' on new records
      attrs["description"]                = ["active"]

      # ... existing attributes ...
      attrs["businessCategory"]           = [domain_name.to_s] if domain_name.present?
      attrs["physicalDeliveryOfficeName"] = [mx_record.to_s]   if mx_record.present?
      attrs["postalAddress"]              = [email.to_s]       if email.present?
      attrs["postOfficeBox"]              = [phone.to_s]       if phone.present?
      attrs["street"]                     = [street.to_s]      if street.present?
      attrs["l"]                          = [city.to_s]        if city.present?
      attrs["st"]                         = [state.to_s]       if state.present?
      attrs["postalCode"]                 = [zipcode.to_s]     if zipcode.present?

      attrs
    end

    def build_update_operations
      ops = [
        [:replace, :objectClass, ["top", "organizationalUnit"]],
        [:replace, :ou, [customer_id.to_s, customer_name.to_s]]
      ]

      # 3. Allow updates to the status field (defaulting to active if blank)
      current_status = status.present? ? status.to_s : "active"
      ops << [:replace, :description, [current_status]]

      # ... existing operations ...
      ops << [:replace, :businessCategory, [domain_name.to_s]] if domain_name.present?
      ops << [:replace, :physicalDeliveryOfficeName, [mx_record.to_s]] if mx_record.present?
      ops << [:replace, :postalAddress, [email.to_s]]          if email.present?
      ops << [:replace, :postOfficeBox, [phone.to_s]]          if phone.present?
      ops << [:replace, :street, [street.to_s]]                if street.present?
      ops << [:replace, :l, [city.to_s]]                       if city.present?
      ops << [:replace, :st, [state.to_s]]                     if state.present?
      ops << [:replace, :postalCode, [zipcode.to_s]]           if zipcode.present?

      ops
    end


  def to_param_id
    customer_id.to_s.parameterize
  end

  # Override Rails' default _id stripping for error messages
  def self.human_attribute_name(attr, options = {})
    if attr.to_sym == :customer_id
      "Customer ID"
    else
      super
    end
  end
end