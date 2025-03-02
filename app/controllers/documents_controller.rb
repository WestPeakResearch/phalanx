class DocumentsController < ApplicationController
  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)

    if @document.save
      # Parse the Excel file and insert the data into the User model
      skipped_rows, inserted_rows = parse_and_insert_data(@document.file)
      redirect_to "/", notice: "File uploaded and data inserted successfully! Inserted #{inserted_rows} rows, Skipped #{skipped_rows} rows"
    else
      render :new
    end
  end

  def destroy
    if params[:reset_all] == "true"
      # Delete all applications from the database
      Application.destroy_all
      redirect_to new_document_path, notice: "All applications have been successfully deleted."
    else
      # Handle single document deletion if needed
      @document = Document.find(params[:id])
      @document.destroy
      redirect_to new_document_path, notice: "Document was successfully deleted."
    end
  end

  def export
    # Create a new workbook
    workbook = RubyXL::Workbook.new

    # Get the first worksheet (created by default)
    worksheet = workbook.worksheets[0]
    worksheet.sheet_name = "Applications"

    # Define headers (excluding Rails internal columns)
    headers = [
      "Application Date", "Email", "First Name", "Last Name",
      "Student Number", "Faculty", "Major", "Year", "Graduation Year",
      "Position", "Resume", "Additional Info", "Source", "Group Preference",
      "Countries", "Careers", "Review Decisions", "Reviewers",
    ]

    # Add headers to the first row
    headers.each_with_index do |header, col_idx|
      worksheet.add_cell(0, col_idx, header)
    end

    # Define which columns are integers (based on schema)
    integer_columns = [4, 7] # student_number and year (0-indexed in our array)

    # Add data rows - sort applications alphabetically by last_name, then first_name
    Application.includes(:initial_reviews).order(:last_name, :first_name).each_with_index do |app, row_idx|
      row_data = [
        app.application_date, app.email, app.first_name, app.last_name,
        app.student_number, app.faculty, app.major, app.year, app.grad_year,
        app.position, app.resume, app.additional, app.source, app.group_preference,
        app.countries, app.careers,
      ]

      # Sort initial reviews alphabetically by reviewer
      sorted_reviews = app.initial_reviews.sort_by(&:reviewer)

      # Combine review decisions and reviewers
      decisions = sorted_reviews.map(&:decision).join(" ")
      reviewers = sorted_reviews.map(&:reviewer).join(", ")

      # Add review data (even if empty)
      row_data += [decisions, reviewers]

      # Add cells to the worksheet
      row_data.each_with_index do |value, col_idx|
        if integer_columns.include?(col_idx) && !value.nil?
          # For integer columns, add as a number
          worksheet.add_cell(row_idx + 1, col_idx, value.to_i)
        else
          # For other columns, add as a string
          worksheet.add_cell(row_idx + 1, col_idx, value.to_s)
        end
      end
    end

    # Generate the Excel file in memory
    excel_data = workbook.stream.read

    # Send the file to the user
    send_data excel_data,
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              filename: "applications_export_#{Date.today.strftime("%Y%m%d")}.xlsx"
  end

  private

  def document_params
    params.require(:document).permit(:file)
  end

  # Method to parse and insert data into ActiveRecord model
  def parse_and_insert_data(file)
    xlsx = RubyXL::Parser.parse_buffer(file.download)

    # Assuming the first worksheet contains the data
    worksheet = xlsx[0]

    # Track statistics
    skipped_rows = 0
    inserted_rows = 0

    # Start at row 1 (since row 0 is usually the header row)
    worksheet.each_with_index do |row, index|
      next if index == 0 # Skip the header row

      # Assuming columns are: Name, Email
      timestamp = row[0]&.value.to_s
      email = row[1]&.value.to_s
      first_name = row[2]&.value.to_s
      last_name = row[3]&.value.to_s
      student_number = row[4]&.value.to_s
      faculty = row[5]&.value.to_s
      major = row[6]&.value.to_s
      year = row[7]&.value.to_s
      graudation_year = row[8]&.value.to_s
      position = row[9]&.value.to_s
      resume = row[10]&.value.to_s
      additional_info = row[11]&.value.to_s
      origin = row[12]&.value.to_s
      preference = row[13]&.value.to_s
      location = row[14]&.value.to_s
      careers = row[15]&.value.to_s

      if first_name.blank? && last_name.blank?
        skipped_rows += 1
        next
      end

      # Create the application record
      Application.create!(
        application_date: timestamp,
        email: email,
        first_name: first_name,
        last_name: last_name,
        student_number: student_number,
        faculty: faculty,
        major: major,
        year: year,
        grad_year: graudation_year,
        position: position,
        resume: resume,
        additional: additional_info,
        source: origin,
        group_preference: preference,
        countries: location,
        careers: careers,
      )

      inserted_rows += 1
    end

    # Return statistics for the notice message
    return skipped_rows, inserted_rows
  end
end
