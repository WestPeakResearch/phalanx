class ApplicationsController < ApplicationController
  def index
    @applications = Application.where.not(year: nil)
      .order(:last_name, :first_name)  # Sort alphabetically by last name, then first name
    @visible_columns = params[:visible_columns] || Application.default_visible_columns

    # Find duplicate applications (same first and last name)
    @duplicate_ids = find_duplicate_applications
  end

  def show
    @application = Application.find(params[:id])
  end

  def raw
    @applications = Application.all.order(:last_name, :first_name)  # Sort alphabetically by last name, then first name
    @visible_columns = params[:visible_columns] || Application.default_visible_columns

    # Find duplicate applications (same first and last name)
    @duplicate_ids = find_duplicate_applications
  end

  def destroy
    @application = Application.find(params[:id])
    @application.destroy

    redirect_to applications_path, notice: "Application for #{@application.first_name} #{@application.last_name} was successfully deleted."
  end

  private

  # Find applications with duplicate first and last names
  def find_duplicate_applications
    # Group applications by first_name and last_name, then select groups with more than 1 application
    duplicates = Application.group(:first_name, :last_name)
      .having("COUNT(*) > 1")
      .pluck(:first_name, :last_name)

    # Get IDs of all applications that are part of duplicate groups
    duplicate_ids = []
    duplicates.each do |first_name, last_name|
      duplicate_ids.concat(Application.where(first_name: first_name, last_name: last_name).pluck(:id))
    end

    duplicate_ids
  end
end
