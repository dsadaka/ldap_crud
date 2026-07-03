# app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  before_action :set_ldap_service
  before_action :set_customer, only: [:edit, :update]

  def index
    @customers = fetch_all_customers
  end

  def new
    @customer = LdapCustomer.new
  end

  # app/controllers/customers_controller.rb
  # Just replace these two actions

  def create
    @customer = LdapCustomer.new(customer_params)

    if @customer.valid?
      attributes = @customer.build_create_attributes
      customer_dn = "ou=#{@customer.customer_id},#{LdapService::BASE_CONTEXT}"

      if @ldap_service.add_record(dn: customer_dn, attributes: attributes)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              # 1. Append the new row using your exact tbody ID
              turbo_stream.append("spam-users-table_body",
                                  partial: "spam_user_row",
                                  locals: { user: @user }),

              # 2. Reset the right-hand panel back to the placeholder text
              turbo_stream.update("user_form",
                                  html: "<p class='text-muted'>Click [Add User] or [Edit] to load the form.</p>")
            ]
          end
          format.html { redirect_to spam_user_records_path(customer_id: @user.customer_id) }
        end
      else
        # Attach the LDAP error directly to the model so it shows inline
        @customer.errors.add(:base, "LDAP Server Error: #{@ldap_service.error_message}")
        render :new, status: :unprocessable_entity
      end
    else
      # Removed the flash alert; errors will render naturally inside the form
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @customer.assign_attributes(customer_params)

    if @customer.valid?
      operations = @customer.build_update_operations

      if @ldap_service.update_record(dn: @customer.dn, operations: operations)
        flash.now[:notice] = "Customer was successfully updated."

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to customers_path }
        end
      else
        # Attach the LDAP error directly to the model
        @customer.errors.add(:base, "LDAP Server Error: #{@ldap_service.error_message}")
        render :edit, status: :unprocessable_entity
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def edit
    # @customer is already set by the before_action
  end

  def destroy
    # customer_id comes through params[:id] from the route mapping
    if @ldap_service.destroy_customer_and_users(params[:id])
      flash[:notice] = "Customer and all associated users were safely deleted."
    else
      flash[:alert] = "Failed to delete customer: #{@ldap_service.error_message}"
    end

    redirect_to customers_path
  end

  private

  def set_ldap_service
    @ldap_service = LdapService.new
  end

  def customer_params
    # Added :domain_name to the permitted list
    params.require(:ldap_customer).permit(
      :customer_id, :customer_name, :domain_name, :mx_record, :email, :phone,
      :street, :city, :state, :zipcode
    )
  end

  # Finds a single customer by their OU and initializes an LdapCustomer object
  def set_customer
    entry = @ldap_service.search_active_customers.find { |e| e.ou.first == params[:id] }

    if entry
      @customer = map_entry_to_customer(entry)
    else
      flash[:alert] = "Customer not found in the directory."
      redirect_to customers_path
    end
  end

  # Fetches all active customers and maps them to Ruby objects for the index view
  def fetch_all_customers
    entries = @ldap_service.search_active_customers || []
    entries.map { |entry| map_entry_to_customer(entry) }.sort_by { |c| c.customer_name.to_s.downcase }
  end

  # Safely extracts attributes from the Net::LDAP arrays into your ActiveModel
  # app/controllers/customers_controller.rb

  # app/controllers/customers_controller.rb
  # ... inside private methods ...

  def map_entry_to_customer(entry)
    LdapCustomer.new(
      dn: entry.dn,
      customer_id: entry.respond_to?(:ou) ? entry.ou.first : nil,
      customer_name: entry.respond_to?(:ou) && entry.ou.length > 1 ? entry.ou[1] : nil,

      # Read the status from the description attribute
      status: entry.respond_to?(:description) ? entry.description.first : "inactive",

      domain_name: entry.respond_to?(:businesscategory) ? entry.businesscategory.first : nil,
      mx_record: entry.respond_to?(:physicaldeliveryofficename) ? entry.physicaldeliveryofficename.first : nil,
      email: entry.respond_to?(:postaladdress) ? entry.postaladdress.first : nil,
      phone: entry.respond_to?(:postofficebox) ? entry.postofficebox.first : nil,
      street: entry.respond_to?(:street) ? entry.street.first : nil,
      city: entry.respond_to?(:l) ? entry.l.first : nil,
      state: entry.respond_to?(:st) ? entry.st.first : nil,
      zipcode: entry.respond_to?(:postalcode) ? entry.postalcode.first : nil
    )
  end
end