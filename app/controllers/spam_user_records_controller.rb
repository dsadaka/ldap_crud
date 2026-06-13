class SpamUserRecordsController < ApplicationController
  before_action :initialize_ldap_service

  def index
    @customer_id = params[:customer_id]

    if @customer_id.present?
      entries = @ldap_service.search_by_customer(customer_id: @customer_id)
      @records = entries.map { |entry| LdapRecord.from_entry(entry) }
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

  def create
    @record = LdapRecord.new(record_params)

    unless @record.valid?
      flash[:alert] = "Validation Error: #{@record.errors.full_messages.join(', ')}"
      return render :index, status: :unprocessable_entity
    end

    if @ldap_service.add_record(dn: @record.dn, attributes: @record.attributes_for_create)
      flash[:notice] = "Record added successfully."
      redirect_to spam_user_records_path(customer_id: @record.customer_id)
    else
      flash[:alert] = "Error: #{@ldap_service.error_message}"
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @record = LdapRecord.new(record_params)

    unless @record.valid?
      flash[:alert] = "Validation Error: #{@record.errors.full_messages.join(', ')}"
      return render :index, status: :unprocessable_entity
    end

    if @ldap_service.update_record(dn: @record.dn, operations: @record.build_update_operations)
      flash[:notice] = "Record updated successfully."
      redirect_to spam_user_records_path(customer_id: @record.customer_id)
    else
      flash[:alert] = "Error: #{@ldap_service.error_message}"
      render :index, status: :unprocessable_entity
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