class InterviewSelectionsController < ApplicationController
  require "rubyXL"
  require "rubyXL/convenience_methods"

  def index
    @applications_by_year = Application.includes(scorings: :user)
      .where.not(year: nil)
      .joins(:scorings)
      .where(scorings: { status: :completed })
      .group("applications.id")
      .select("applications.*, AVG(scorings.overall_score) as avg_score")
      .group_by(&:year)
      .transform_values { |apps| apps.sort_by(&:avg_score).reverse }
  end

  def details
    @application = Application.includes(scorings: :user).find(params[:id])
    render partial: "details", layout: false
  end

  def scoring_modal
    @application = Application.includes(scorings: :user).find(params[:id])

    respond_to do |format|
      format.html { render partial: "scoring_details", locals: { application: @application } }
      format.turbo_stream {
        render turbo_stream: turbo_stream.update("modal_content_#{@application.id}",
                                                 partial: "scoring_details",
                                                 locals: { application: @application })
      }
    end
  end

  def export_selected
    selected_apps = Application.includes(scorings: :user)
      .where(selected_for_interview: true)
      .joins(:scorings)
      .where(scorings: { status: :completed })
      .group("applications.id")
      .select("applications.*, AVG(scorings.overall_score) as avg_score")

    # Create a new workbook
    workbook = RubyXL::Workbook.new

    # Group applications by position
    apps_by_position = selected_apps.group_by(&:position)

    # Define headers
    headers = ["First Name", "Last Name", "Year", "Email", "Position", "Overall Score"]

    # Counter to track if we've already used the default sheet
    sheet_counter = 0

    # Create a sheet for each position
    apps_by_position.each do |position, apps|
      # Skip if position is blank
      next if position.blank?

      # Use the first sheet for the first position, add sheets for others
      if sheet_counter == 0
        worksheet = workbook[0]
        worksheet.sheet_name = position
      else
        worksheet = workbook.add_worksheet(position)
      end
      sheet_counter += 1

      # Add headers
      headers.each_with_index do |header, i|
        worksheet.add_cell(0, i, header)
      end

      # Group by year and sort by score within each year
      apps_by_year = apps.group_by(&:year).sort.to_h

      # Track the current row index
      current_row = 1

      # Process each year group
      apps_by_year.each do |year, year_apps|
        # Sort apps by score in descending order
        sorted_apps = year_apps.sort_by { |app| -app.avg_score }

        # Add applications for this year
        sorted_apps.each do |app|
          worksheet.add_cell(current_row, 0, app.first_name)
          worksheet.add_cell(current_row, 1, app.last_name)
          worksheet.add_cell(current_row, 2, app.year)
          worksheet.add_cell(current_row, 3, app.email)
          worksheet.add_cell(current_row, 4, app.position)
          worksheet.add_cell(current_row, 5, app.avg_score.round(2))
          current_row += 1
        end

        # Add an empty row after each year group (except the last one)
        if year != apps_by_year.keys.last
          current_row += 1
        end
      end
    end

    # Create an "All Applicants" sheet if there are multiple positions
    if apps_by_position.keys.length > 1
      all_worksheet = workbook.add_worksheet("All Applicants")

      # Add headers
      headers.each_with_index do |header, i|
        all_worksheet.add_cell(0, i, header)
      end

      # Group all applications by year and sort by score within each year
      all_apps_by_year = selected_apps.group_by(&:year).sort.to_h

      # Track the current row index
      current_row = 1

      # Process each year group
      all_apps_by_year.each do |year, year_apps|
        # Sort apps by score in descending order
        sorted_apps = year_apps.sort_by { |app| -app.avg_score }

        # Add applications for this year
        sorted_apps.each do |app|
          all_worksheet.add_cell(current_row, 0, app.first_name)
          all_worksheet.add_cell(current_row, 1, app.last_name)
          all_worksheet.add_cell(current_row, 2, app.year)
          all_worksheet.add_cell(current_row, 3, app.email)
          all_worksheet.add_cell(current_row, 4, app.position)
          all_worksheet.add_cell(current_row, 5, app.avg_score.round(2))
          current_row += 1
        end

        # Add an empty row after each year group (except the last one)
        if year != all_apps_by_year.keys.last
          current_row += 1
        end
      end
    end

    # Handle case where there are no applications with positions
    if sheet_counter == 0
      worksheet = workbook[0]
      worksheet.sheet_name = "Selected Applicants"

      # Add headers
      headers.each_with_index do |header, i|
        worksheet.add_cell(0, i, header)
      end

      # Group all applications by year and sort by score within each year
      all_apps_by_year = selected_apps.group_by(&:year).sort.to_h

      # Track the current row index
      current_row = 1

      # Process each year group
      all_apps_by_year.each do |year, year_apps|
        # Sort apps by score in descending order
        sorted_apps = year_apps.sort_by { |app| -app.avg_score }

        # Add applications for this year
        sorted_apps.each do |app|
          worksheet.add_cell(current_row, 0, app.first_name)
          worksheet.add_cell(current_row, 1, app.last_name)
          worksheet.add_cell(current_row, 2, app.year)
          worksheet.add_cell(current_row, 3, app.email)
          worksheet.add_cell(current_row, 4, app.position || "")
          worksheet.add_cell(current_row, 5, app.avg_score.round(2))
          current_row += 1
        end

        # Add an empty row after each year group (except the last one)
        if year != all_apps_by_year.keys.last
          current_row += 1
        end
      end
    end

    # Send the file
    send_data workbook.stream.string,
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment; filename=selected_applicants_#{Date.today.strftime("%Y%m%d")}.xlsx"
  end

  def update_interview_selection
    @application = Application.find(params[:id])
    success = @application.update(selected_for_interview: params[:selected] == "1")
    @selected_count = Application.where(selected_for_interview: true).count

    respond_to do |format|
      if success
        format.turbo_stream {
          render turbo_stream: turbo_stream.multi(
            turbo_stream.replace(
              "interview_selection_#{@application.id}",
              partial: "interview_checkbox",
              locals: { application: @application },
            ),
            turbo_stream.update(
              "selected_count",
              partial: "selected_count",
              locals: { selected_count: @selected_count },
            )
          )
        }
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "interview_selection_#{@application.id}",
            partial: "interview_checkbox",
            locals: { application: @application },
          )
        }
      end
    end
  end
end
