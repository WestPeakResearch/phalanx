class ApplicationsController < ApplicationController
  def index
    @applications = Application.where.not(year: nil)
      .order(:year)  # This ensures Year 1 shows first
    @visible_columns = params[:visible_columns] || Application.default_visible_columns
  end

  def show
    @application = Application.find(params[:id])
  end

  def raw
    @applications = Application.all  # Shows all applications, including those with nil year
    @visible_columns = params[:visible_columns] || Application.default_visible_columns
  end
end
