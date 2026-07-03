class SpamUserRecordsController < ApplicationController
  before_action :initialize_ldap_service

  def index
    @customer_id = params[:customer_id]

    if @customer_id.present?
      entries = @ldap_service.search_by_customer_id(customer_id: @customer_id)
      @records = entries.map { |entry| LdapRecord.from_entry(entry) }.sort_by { |user| user.mail.to_s.downcase }
    else
      @records = []
    end
  end

  def new
    @record = LdapRecord.new(customer_id: params[:customer_id])
  end

  def edit
    entry = @ldap_service.find_by_dn(dn: params[:dn])

    if entry
      @record = LdapRecord.from_entry(entry)
    else
      flash[:alert] = "Record not found in directory."
      redirect_to spam_user_records_path(customer_id: params[:customer_id])
    end
  end

  # app/controllers/spam_user_records_controller.rb

  # app/controllers/spam_user_records_controller.rb

  # app/controllers/spam_user_records_controller.rb

  def create
    @record = LdapRecord.new(record_params)

    # 1. Run local model validations first
    if @record.valid?
      # 2. If valid, attempt the LDAP directory write
      if @ldap_service.add_record(dn: @record.dn, attributes: @record.attributes_for_create)
        entries = @ldap_service.search_by_customer_id(customer_id: LdapRecord.extract_customer_id(@record.dn))
        @records = entries.map { |entry| LdapRecord.from_entry(entry) }
        flash.now[:notice] = "User was successfully created."

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to spam_user_records_path(customer_id: @record.customer_id) }
        end
      else
        # Captures LDAP-specific directory errors
        flash.now[:alert] = "LDAP Server Error: #{@ldap_service.error_message}"
        render :index, status: :unprocessable_entity
      end
    else
      # Captures your local model validation failure message
      flash.now[:alert] = "Record is invalid. Please check the highlighted fields."
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @record = LdapRecord.new(record_params)
    @record.dn = params[:id]

    # 1. Run local model validations first
    if @record.valid?
      # 2. If valid, attempt the LDAP directory modification
      if @ldap_service.update_record(dn: @record.dn, operations: @record.build_update_operations)
        entries = @ldap_service.search_by_customer_id(customer_id: LdapRecord.extract_customer_id(@record.dn))
        @records = entries.map { |entry| LdapRecord.from_entry(entry) }
        flash.now[:notice] = "User was successfully updated."

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to spam_user_records_path(customer_id: @record.customer_id) }
        end
      else
        # Captures LDAP-specific directory errors
        flash.now[:alert] = "LDAP Server Error: #{@ldap_service.error_message}"
        # CRITICAL: Force the :html format here
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    else
      # Captures your local model validation failure message
      flash.now[:alert] = "Record is invalid."
      # CRITICAL: Force the :html format here
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    dn = params[:dn]

    if @ldap_service.delete_record(dn: dn)
      flash[:notice] = "Record deleted successfully."
    else
      flash[:alert] = "Error: #{@ldap_service.error_message}"
    end

    redirect_to spam_user_records_path(customer_id: params[:customer_id])
  end

  private

  def record_params
    params.require(:ldap_record).permit(
      :dn, :mail, :uid, :givenName, :fullName, :sn, :ou, :cn, :customer_id
    )
  end

  def initialize_ldap_service
    @ldap_service = LdapService.new
  end
end